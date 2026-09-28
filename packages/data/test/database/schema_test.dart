// What the schema promises, checked against a real SQLite database in memory.
//
// Most of these are guarantees that live in the schema rather than in Dart code — foreign keys,
// uniqueness, cascades, restrictions — so they can only be verified by running statements.

// Drift exports a query helper called isNull that collides with the matcher of the same name.
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:kikuyomi_data/kikuyomi_data.dart';
import 'package:kikuyomi_domain/kikuyomi_domain.dart';
import 'package:test/test.dart';

Matcher throwsConstraint(String kind) => throwsA(
  predicate(
    (Object? e) => e.toString().contains('$kind constraint failed'),
    'a $kind constraint failure',
  ),
);

void main() {
  late KikuyomiDatabase db;
  final now = DateTime.utc(2026, 9, 13, 12, 30, 45, 123);

  setUp(() async {
    db = KikuyomiDatabase(NativeDatabase.memory());
    await db
        .into(db.sources)
        .insert(
          const SourcesCompanion(
            id: Value(7),
            key: Value('local'),
            name: Value('Local files'),
            lang: Value('und'),
          ),
        );
  });

  tearDown(() => db.close());

  Future<int> insertBook({String key = 'book-1'}) => db
      .into(db.books)
      .insert(
        BooksCompanion(
          sourceId: const Value(7),
          key: Value(key),
          title: const Value('A Book'),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );

  Future<int> insertChapter(int bookId, {String key = 'ch-1'}) => db
      .into(db.chapters)
      .insert(
        ChaptersCompanion(
          bookId: Value(bookId),
          key: Value(key),
          title: const Value('Chapter'),
          sourceIndex: const Value(0),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );

  Future<int> insertFile(int bookId) => db
      .into(db.mediaFiles)
      .insert(
        MediaFilesCompanion(
          bookId: Value(bookId),
          fileKey: const Value('part1.mp3'),
          durationMs: const Value(60000),
        ),
      );

  Future<int> insertSession(int bookId, int? chapterId) => db
      .into(db.listeningSessions)
      .insert(
        ListeningSessionsCompanion(
          bookId: Value(bookId),
          chapterId: Value(chapterId),
          startedAt: Value(now),
          endedAt: Value(now.add(const Duration(minutes: 5))),
          startGlobalMs: const Value(0),
          endGlobalMs: const Value(300000),
          speed: const Value(1.0),
          deviceId: const Value('test-device'),
        ),
      );

  test('creates exactly the tables of version 7', () {
    expect(
      {for (final table in db.allTables) table.actualTableName},
      {
        'sources',
        'books',
        'people',
        'book_people',
        'chapters',
        'media_files',
        'chapter_segments',
        'playback_states',
        'reading_states',
        'listening_sessions',
        'reading_sessions',
        'bookmarks',
        'categories',
        'book_categories',
        'repositories',
        'extensions',
        'extension_preferences',
        'download_tasks',
      },
    );
  });

  test('foreign keys are switched on for the connection', () async {
    final row = await db.customSelect('PRAGMA foreign_keys').getSingle();
    expect(row.data.values.single, 1);
  });

  group('integrity', () {
    test('a chapter cannot belong to a book that does not exist', () async {
      expect(insertChapter(999), throwsConstraint('FOREIGN KEY'));
    });

    test("a book's identity is its source and key (§4.4)", () async {
      await insertBook(key: 'same');
      expect(insertBook(key: 'same'), throwsConstraint('UNIQUE'));
    });

    test('a chapter key is unique within its book, not across books', () async {
      final a = await insertBook(key: 'a');
      final b = await insertBook(key: 'b');
      await insertChapter(a, key: 'ch');
      await insertChapter(b, key: 'ch');
      expect(insertChapter(a, key: 'ch'), throwsConstraint('UNIQUE'));
    });
  });

  group('deletion', () {
    test('deleting a book removes everything that belongs to it', () async {
      final book = await insertBook();
      final chapter = await insertChapter(book);
      final file = await insertFile(book);
      await db
          .into(db.chapterSegments)
          .insert(
            ChapterSegmentsCompanion(
              chapterId: Value(chapter),
              ordinal: const Value(0),
              mediaFileId: Value(file),
            ),
          );
      await insertSession(book, chapter);
      final category = await db
          .into(db.categories)
          .insert(
            const CategoriesCompanion(
              name: Value('Next up'),
              sortOrder: Value(0),
            ),
          );
      await db
          .into(db.bookCategories)
          .insert(
            BookCategoriesCompanion(
              bookId: Value(book),
              categoryId: Value(category),
            ),
          );

      await (db.delete(db.books)..where((b) => b.id.equals(book))).go();

      expect(await db.select(db.chapters).get(), isEmpty);
      expect(await db.select(db.mediaFiles).get(), isEmpty);
      expect(await db.select(db.chapterSegments).get(), isEmpty);
      expect(await db.select(db.listeningSessions).get(), isEmpty);
      expect(await db.select(db.bookCategories).get(), isEmpty);
      expect(
        await db.select(db.categories).get(),
        hasLength(1),
        reason: 'the category itself outlives the books in it',
      );
    });

    test('the database refuses to delete a chapter holding progress', () async {
      final book = await insertBook();
      final chapter = await insertChapter(book);
      await db
          .into(db.playbackStates)
          .insert(
            PlaybackStatesCompanion(
              bookId: Value(book),
              chapterId: Value(chapter),
              chapterPositionMs: const Value(42000),
              globalPositionMs: const Value(42000),
              updatedAt: Value(now),
              deviceId: const Value('test-device'),
            ),
          );
      expect(
        (db.delete(db.chapters)..where((c) => c.id.equals(chapter))).go(),
        throwsConstraint('FOREIGN KEY'),
      );
    });

    test(
      'the database refuses to delete a chapter holding a bookmark',
      () async {
        final book = await insertBook();
        final chapter = await insertChapter(book);
        await db
            .into(db.bookmarks)
            .insert(
              BookmarksCompanion(
                bookId: Value(book),
                chapterId: Value(chapter),
                positionMs: const Value(1000),
                createdAt: Value(now),
              ),
            );
        expect(
          (db.delete(db.chapters)..where((c) => c.id.equals(chapter))).go(),
          throwsConstraint('FOREIGN KEY'),
        );
      },
    );

    test('purging a chapter keeps its listening history', () async {
      final book = await insertBook();
      final chapter = await insertChapter(book);
      await insertSession(book, chapter);

      await (db.delete(db.chapters)..where((c) => c.id.equals(chapter))).go();

      final session = await db.select(db.listeningSessions).getSingle();
      expect(session.chapterId, isNull);
      expect(session.endGlobalMs, 300000);
    });

    test('a file cannot be deleted out from under a chapter layout', () async {
      final book = await insertBook();
      final chapter = await insertChapter(book);
      final file = await insertFile(book);
      await db
          .into(db.chapterSegments)
          .insert(
            ChapterSegmentsCompanion(
              chapterId: Value(chapter),
              ordinal: const Value(0),
              mediaFileId: Value(file),
            ),
          );
      expect(
        (db.delete(db.mediaFiles)..where((f) => f.id.equals(file))).go(),
        throwsConstraint('FOREIGN KEY'),
      );
    });
  });

  group('values', () {
    test('defaults are what a freshly discovered book should have', () async {
      final book = await insertBook();
      await insertFile(book);
      await insertChapter(book);
      final row = await db.select(db.books).getSingle();
      final file = await db.select(db.mediaFiles).getSingle();
      final chapter = await db.select(db.chapters).getSingle();

      expect(row.genres, isEmpty);
      expect(row.userOverrides, isEmpty);
      expect(row.inLibrary, isFalse);
      expect(file.durationIsEstimate, isTrue);
      expect(chapter.lastPositionMs, 0);
      expect(chapter.removedFromSource, isFalse);
    });

    test('structured columns round-trip through their converters', () async {
      final book = await db
          .into(db.books)
          .insert(
            BooksCompanion(
              sourceId: const Value(7),
              key: const Value('structured'),
              title: const Value('Structured'),
              genres: const Value(['Fiction', 'Mystery']),
              userOverrides: const Value({BookField.title, BookField.coverUrl}),
              createdAt: Value(now),
              updatedAt: Value(now),
            ),
          );
      await db
          .into(db.mediaFiles)
          .insert(
            MediaFilesCompanion(
              bookId: Value(book),
              fileKey: const Value('book.m4b'),
              embeddedMarkers: const Value([
                TimelineMarker(title: 'Opening', startMs: 0),
                TimelineMarker(title: 'Préface', startMs: 4000),
              ]),
            ),
          );
      final person = await db
          .into(db.people)
          .insert(const PeopleCompanion(name: Value('A Narrator')));
      await db
          .into(db.bookPeople)
          .insert(
            BookPeopleCompanion(
              bookId: Value(book),
              personId: Value(person),
              role: const Value(ContributorRole.narrator),
              ordinal: const Value(0),
            ),
          );

      final row = await db.select(db.books).getSingle();
      final file = await db.select(db.mediaFiles).getSingle();
      final credit = await db.select(db.bookPeople).getSingle();

      expect(row.genres, ['Fiction', 'Mystery']);
      expect(row.userOverrides, {BookField.title, BookField.coverUrl});
      expect(
        [for (final m in file.embeddedMarkers!) (m.startMs, m.title)],
        [(0, 'Opening'), (4000, 'Préface')],
      );
      expect(credit.role, ContributorRole.narrator);
    });

    test('a segment with no end runs to the end of its file', () async {
      final book = await insertBook();
      final chapter = await insertChapter(book);
      final file = await insertFile(book);
      await db
          .into(db.chapterSegments)
          .insert(
            ChapterSegmentsCompanion(
              chapterId: Value(chapter),
              ordinal: const Value(0),
              mediaFileId: Value(file),
            ),
          );
      final segment = await db.select(db.chapterSegments).getSingle();
      expect(segment.startMs, 0);
      expect(segment.endMs, isNull);
    });

    test('timestamps keep their milliseconds', () async {
      // Stored as whole seconds, which is drift's default, this would silently read back 123 ms
      // early, and progress and listening sessions are timestamped to the millisecond.
      await insertBook();
      final row = await db.select(db.books).getSingle();
      expect(
        row.createdAt.isAtSameMomentAs(now),
        isTrue,
        reason: '${row.createdAt}',
      );
    });
  });

  test(
    'the bundled SQLite has the FTS5 and JSON support later versions rely on',
    () async {
      await db.customStatement(
        'CREATE VIRTUAL TABLE temp.fts_probe USING fts5(title)',
      );
      final json = await db
          .customSelect("SELECT json_array_length('[1, 2, 3]') AS n")
          .getSingle();
      expect(json.read<int>('n'), 3);
    },
  );
}
