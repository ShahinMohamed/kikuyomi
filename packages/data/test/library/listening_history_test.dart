// Reading back the listening sessions the coordinator has been recording all along.
//
// The case worth holding onto is the one the table was designed for: a session outlives the chapter
// it was in. §4.4's "keep while it carries user data" rule covers progress, bookmarks and downloads
// and not history, so `chapter_id` goes null when a chapter is purged — and an entry with no chapter
// must still come back, because it is the listener's record of an evening.

// Drift exports a query helper called isNull that collides with the matcher of the same name.
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:kikuyomi_data/kikuyomi_data.dart';
import 'package:kikuyomi_source_api/kikuyomi_source_api.dart' show SourceKind;
import 'package:kikuyomi_test_support/kikuyomi_test_support.dart';
import 'package:test/test.dart';

void main() {
  _reading();

  late KikuyomiDatabase db;
  late FakeClock clock;

  setUp(() {
    db = KikuyomiDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    clock = FakeClock(DateTime.utc(2026, 9, 25, 9));
  });

  Future<void> addSource(int id) => db
      .into(db.sources)
      .insert(
        SourcesCompanion(
          id: Value(id),
          key: Value('s$id'),
          name: Value('Source $id'),
          lang: const Value('en'),
        ),
      );

  Future<int> addBook(String title, {String? cover}) => db
      .into(db.books)
      .insert(
        BooksCompanion.insert(
          sourceId: 1,
          key: title,
          title: title,
          coverLocalPath: Value(cover),
          createdAt: clock.now(),
          updatedAt: clock.now(),
        ),
      );

  Future<int> addChapter(int bookId, String title) => db
      .into(db.chapters)
      .insert(
        ChaptersCompanion.insert(
          bookId: bookId,
          key: title,
          title: title,
          sourceIndex: 1,
          createdAt: clock.now(),
          updatedAt: clock.now(),
        ),
      );

  Future<int> addSession(
    int bookId, {
    int? chapterId,
    required DateTime startedAt,
    Duration listened = const Duration(minutes: 10),
    int startGlobalMs = 0,
    int endGlobalMs = 600000,
    double speed = 1,
  }) => db
      .into(db.listeningSessions)
      .insert(
        ListeningSessionsCompanion.insert(
          bookId: bookId,
          chapterId: Value(chapterId),
          startedAt: startedAt,
          endedAt: startedAt.add(listened),
          startGlobalMs: startGlobalMs,
          endGlobalMs: endGlobalMs,
          speed: speed,
          deviceId: 'this-device',
        ),
      );

  group('reading it back', () {
    test('carries the book, the chapter and the stretch', () async {
      await addSource(1);
      final book = await addBook('Moby-Dick', cover: 'covers/1.jpg');
      final chapter = await addChapter(book, 'Loomings');
      await addSession(
        book,
        chapterId: chapter,
        startedAt: clock.now(),
        listened: const Duration(minutes: 20),
        startGlobalMs: 1000,
        endGlobalMs: 61000,
        speed: 1.5,
      );

      final entry = (await watchListeningHistory(db).first).single;

      expect(entry.bookId, book);
      expect(entry.bookTitle, 'Moby-Dick');
      expect(entry.chapterTitle, 'Loomings');
      expect(entry.coverFileName, 'covers/1.jpg');
      expect(entry.speed, 1.5);
      expect(entry.spent, const Duration(minutes: 20));
      expect(
        entry.covered,
        const Duration(seconds: 60),
        reason: 'at 1.5x a stretch covers more of the book than it takes',
      );
    });

    test('an entry outlives the chapter it was in', () async {
      // The reason `chapter_id` is nullable. History is not user data §4.4 promises to keep a
      // chapter for, so the chapter goes and the evening stays.
      await addSource(1);
      final book = await addBook('Moby-Dick');
      final chapter = await addChapter(book, 'Loomings');
      await addSession(book, chapterId: chapter, startedAt: clock.now());

      await (db.delete(db.chapters)..where((c) => c.id.equals(chapter))).go();

      final entry = (await watchListeningHistory(db).first).single;
      expect(entry.chapterTitle, isNull);
      expect(entry.bookTitle, 'Moby-Dick');
    });

    test('newest first', () async {
      await addSource(1);
      final book = await addBook('Moby-Dick');
      await addSession(book, startedAt: DateTime.utc(2026, 9, 23));
      await addSession(book, startedAt: DateTime.utc(2026, 9, 25));
      await addSession(book, startedAt: DateTime.utc(2026, 9, 24));

      expect(
        [
          for (final e in await watchListeningHistory(db).first)
            e.startedAt.day,
        ],
        [25, 24, 23],
      );
    });

    test('takes no more than it was asked for', () async {
      await addSource(1);
      final book = await addBook('Moby-Dick');
      for (var day = 1; day <= 5; day++) {
        await addSession(book, startedAt: DateTime.utc(2026, 9, day));
      }

      expect(await watchListeningHistory(db, limit: 2).first, hasLength(2));
    });

    test('nothing heard is an empty list', () async {
      expect(await watchListeningHistory(db).first, isEmpty);
    });

    test('emits again when something is recorded', () async {
      await addSource(1);
      final book = await addBook('Moby-Dick');
      final emissions = watchListeningHistory(db).take(2).toList();

      await addSession(book, startedAt: clock.now());

      expect((await emissions).last, hasLength(1));
    });
  });

  group('forgetting', () {
    test('one entry', () async {
      await addSource(1);
      final book = await addBook('Moby-Dick');
      final one = await addSession(book, startedAt: DateTime.utc(2026, 9, 24));
      await addSession(book, startedAt: DateTime.utc(2026, 9, 25));

      final entry = (await watchListeningHistory(
        db,
      ).first).firstWhere((e) => e.sessionId == one);
      await deleteHistoryEntry(db, entry);

      expect(await watchListeningHistory(db).first, hasLength(1));
    });

    test('everything for one book, leaving the others', () async {
      await addSource(1);
      final mine = await addBook('Moby-Dick');
      final other = await addBook('The Whale');
      await addSession(mine, startedAt: DateTime.utc(2026, 9, 24));
      await addSession(mine, startedAt: DateTime.utc(2026, 9, 25));
      await addSession(other, startedAt: DateTime.utc(2026, 9, 25));

      expect(await deleteBookHistory(db, mine), 2);

      final left = await watchListeningHistory(db).first;
      expect(left, hasLength(1));
      expect(left.single.bookTitle, 'The Whale');
    });

    test('and it leaves the book and the place in it alone', () async {
      // The promise the dialog makes. History says when something was heard; it is not the record of
      // having heard it, which lives in playback_state and the listened flags.
      await addSource(1);
      final book = await addBook('Moby-Dick');
      final chapter = await addChapter(book, 'Loomings');
      await db
          .into(db.playbackStates)
          .insert(
            PlaybackStatesCompanion.insert(
              bookId: Value(book),
              chapterId: chapter,
              chapterPositionMs: 5000,
              globalPositionMs: 5000,
              updatedAt: clock.now(),
              deviceId: 'this-device',
            ),
          );
      await addSession(book, chapterId: chapter, startedAt: clock.now());

      await deleteBookHistory(db, book);

      expect(await db.select(db.books).get(), hasLength(1));
      expect(
        (await db.select(db.playbackStates).getSingle()).globalPositionMs,
        5000,
      );
    });

    test('all of it', () async {
      await addSource(1);
      final book = await addBook('Moby-Dick');
      await addSession(book, startedAt: DateTime.utc(2026, 9, 24));
      await addSession(book, startedAt: DateTime.utc(2026, 9, 25));

      expect(await clearListeningHistory(db), 2);
      expect(await watchListeningHistory(db).first, isEmpty);
    });

    test('clearing an empty history is not a failure', () async {
      expect(await clearListeningHistory(db), 0);
    });
  });
}

/// History covers reading as well as listening (ADR-0019).
void _reading() {
  late KikuyomiDatabase db;
  final at = DateTime.utc(2026, 9, 28, 20);

  setUp(() {
    db = KikuyomiDatabase(NativeDatabase.memory());
    addTearDown(db.close);
  });

  Future<int> addNovel() async {
    await db
        .into(db.sources)
        .insert(
          const SourcesCompanion(
            id: Value(1),
            key: Value('novels'),
            name: Value('Novels'),
            lang: Value('en'),
          ),
        );
    return db
        .into(db.books)
        .insert(
          BooksCompanion.insert(
            sourceId: 1,
            key: 'a-novel',
            title: 'A Novel',
            kind: const Value(SourceKind.text),
            createdAt: at,
            updatedAt: at,
          ),
        );
  }

  Future<int> addChapter(int bookId) => db
      .into(db.chapters)
      .insert(
        ChaptersCompanion.insert(
          bookId: bookId,
          key: 'chapter-1',
          title: 'Chapter One',
          sourceIndex: 0,
          createdAt: at,
          updatedAt: at,
        ),
      );

  Future<void> read(
    int bookId,
    int chapterId, {
    Duration length = const Duration(minutes: 30),
    DateTime? startedAt,
  }) => recordReadingSession(
    db,
    bookId: bookId,
    chapterId: chapterId,
    startedAt: startedAt ?? at,
    endedAt: (startedAt ?? at).add(length),
    deviceId: 'this-pc',
  );

  group('reading', () {
    test(
      'appears in History, with no speed and no stretch of a recording',
      () async {
        final book = await addNovel();
        await read(book, await addChapter(book));

        final entry = (await watchListeningHistory(db).first).single;

        expect(entry.kind, SourceKind.text);
        expect(entry.bookTitle, 'A Novel');
        expect(entry.chapterTitle, 'Chapter One');
        expect(entry.spent, const Duration(minutes: 30));
        expect(entry.speed, null);
        expect(entry.covered, null);
      },
    );

    test('is not recorded for a glance at a chapter', () async {
      // Opening a chapter while hunting for your place is not an entry in anyone's history.
      final book = await addNovel();
      await read(
        book,
        await addChapter(book),
        length: const Duration(seconds: 8),
      );

      expect(await watchListeningHistory(db).first, isEmpty);
    });

    test('outlives the chapter it was in', () async {
      final book = await addNovel();
      final chapter = await addChapter(book);
      await read(book, chapter);

      await (db.delete(db.chapters)..where((c) => c.id.equals(chapter))).go();

      final entry = (await watchListeningHistory(db).first).single;
      expect(entry.chapterTitle, null);
      expect(entry.bookTitle, 'A Novel');
    });

    test('sits among the evening it was read in, newest first', () async {
      // One record of time spent with books, not two: an evening of reading and listening is one
      // evening.
      final book = await addNovel();
      final chapter = await addChapter(book);
      await read(book, chapter, startedAt: DateTime.utc(2026, 9, 28, 19));
      await read(book, chapter, startedAt: DateTime.utc(2026, 9, 28, 21));
      await db
          .into(db.listeningSessions)
          .insert(
            ListeningSessionsCompanion.insert(
              bookId: book,
              chapterId: Value(chapter),
              startedAt: DateTime.utc(2026, 9, 28, 20),
              endedAt: DateTime.utc(2026, 9, 28, 20, 30),
              startGlobalMs: 0,
              endGlobalMs: 1800000,
              speed: 1,
              deviceId: 'this-pc',
            ),
          );

      final history = await watchListeningHistory(db).first;

      expect([for (final e in history) e.startedAt.hour], [21, 20, 19]);
      expect(
        [for (final e in history) e.kind],
        [SourceKind.text, SourceKind.audio, SourceKind.text],
      );
    });

    test('is forgotten one entry at a time, and with its book', () async {
      final book = await addNovel();
      final chapter = await addChapter(book);
      await read(book, chapter, startedAt: DateTime.utc(2026, 9, 28, 19));
      await read(book, chapter, startedAt: DateTime.utc(2026, 9, 28, 21));

      final history = await watchListeningHistory(db).first;
      await deleteHistoryEntry(db, history.first);
      expect(await watchListeningHistory(db).first, hasLength(1));

      expect(await deleteBookHistory(db, book), 1);
      expect(await watchListeningHistory(db).first, isEmpty);
    });
  });
}
