// Where a reader is in a book, and the shelves that show books being read (ADR-0019).
//
// The rules worth pinning are the ones that keep listening and reading apart where they should be
// apart — each tab's shelf is its own kind — and together where they should be together: a
// finished chapter is `is_listened` whichever way it was finished, so Continue Reading and Continue
// Listening follow the same rule for when a book leaves them.

// Drift exports a query helper called isNull that collides with the matcher of the same name.
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:kikuyomi_data/kikuyomi_data.dart';
import 'package:kikuyomi_source_api/kikuyomi_source_api.dart' show SourceKind;
import 'package:kikuyomi_test_support/kikuyomi_test_support.dart';
import 'package:test/test.dart';

void main() {
  late KikuyomiDatabase db;
  late FakeClock clock;

  setUp(() async {
    db = KikuyomiDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    clock = FakeClock(DateTime.utc(2026, 9, 28, 9));
    await db
        .into(db.sources)
        .insert(
          const SourcesCompanion(
            id: Value(9),
            key: Value('novels'),
            name: Value('Novels'),
            lang: Value('en'),
          ),
        );
  });

  Future<int> addBook({
    String key = 'a-book',
    SourceKind kind = SourceKind.text,
    bool inLibrary = true,
  }) => db
      .into(db.books)
      .insert(
        BooksCompanion.insert(
          sourceId: 9,
          key: key,
          title: 'Book $key',
          kind: Value(kind),
          inLibrary: Value(inLibrary),
          dateAdded: Value(clock.now()),
          createdAt: clock.now(),
          updatedAt: clock.now(),
        ),
      );

  Future<List<int>> addChapters(int bookId, int count) async => [
    for (var i = 0; i < count; i++)
      await db
          .into(db.chapters)
          .insert(
            ChaptersCompanion.insert(
              bookId: bookId,
              key: 'c$i',
              title: 'Chapter ${i + 1}',
              sourceIndex: i,
              createdAt: clock.now(),
              updatedAt: clock.now(),
            ),
          ),
  ];

  group('a reading position', () {
    test('is where it was left', () async {
      final book = await addBook();
      final chapters = await addChapters(book, 3);

      await saveReadingPosition(
        db,
        bookId: book,
        chapterId: chapters[1],
        progress: 0.25,
        clock: clock,
      );

      final place = await readReadingPosition(db, book);
      expect(place!.chapterId, chapters[1]);
      expect(place.progress, 0.25);
    });

    test('is replaced, not added to, by the next one', () async {
      final book = await addBook();
      final chapters = await addChapters(book, 3);

      await saveReadingPosition(
        db,
        bookId: book,
        chapterId: chapters[0],
        progress: 0.5,
        clock: clock,
      );
      await saveReadingPosition(
        db,
        bookId: book,
        chapterId: chapters[2],
        progress: 0.1,
        clock: clock,
      );

      expect(await db.select(db.readingStates).get(), hasLength(1));
      expect((await readReadingPosition(db, book))!.chapterId, chapters[2]);
    });

    test('is kept between 0 and 1', () async {
      // A scroll position read a frame late lands a hair outside, and 1.0000003 would read as past
      // the end of the chapter.
      final book = await addBook();
      final chapters = await addChapters(book, 1);

      await saveReadingPosition(
        db,
        bookId: book,
        chapterId: chapters[0],
        progress: 1.0000003,
        clock: clock,
      );
      expect((await readReadingPosition(db, book))!.progress, 1.0);

      await saveReadingPosition(
        db,
        bookId: book,
        chapterId: chapters[0],
        progress: -0.2,
        clock: clock,
      );
      expect((await readReadingPosition(db, book))!.progress, 0.0);
    });

    test('is not there for a book never opened', () async {
      final book = await addBook();

      expect(await readReadingPosition(db, book), isNull);
    });
  });

  group("a tab's shelf", () {
    test('holds only books of its own kind', () async {
      // Listening and reading are separate tabs, and a novel on the audiobook shelf would be a novel
      // the player cannot play.
      final novel = await addBook(key: 'novel');
      final audiobook = await addBook(key: 'audio', kind: SourceKind.audio);

      final reading = await watchShelf(db, SourceKind.text).first;
      final listening = await watchShelf(db, SourceKind.audio).first;

      expect([for (final b in reading) b.id], [novel]);
      expect([for (final b in listening) b.id], [audiobook]);
    });

    test('holds only what is in the library', () async {
      await addBook(key: 'out', inLibrary: false);

      expect(await watchShelf(db, SourceKind.text).first, isEmpty);
    });
  });

  group('Continue Reading', () {
    test('shows a book once it has been opened', () async {
      final book = await addBook();
      final chapters = await addChapters(book, 4);
      await saveReadingPosition(
        db,
        bookId: book,
        chapterId: chapters[1],
        progress: 0.5,
        clock: clock,
      );

      final shelf = await watchContinueReading(db).first;

      final card = shelf.single;
      expect(card.bookId, book);
      expect(card.chapterTitle, 'Chapter 2');
      expect(card.chapterIndex, 1);
      expect(card.chapterCount, 4);
      // A chapter and a half of four, counting chapters as equal.
      expect(card.bookProgress, closeTo(1.5 / 4, 1e-9));
    });

    test('does not show a book never opened', () async {
      final book = await addBook();
      await addChapters(book, 2);

      expect(await watchContinueReading(db).first, isEmpty);
    });

    test('lets a book go once its last chapter is finished', () async {
      // The same rule Continue Listening follows, on the same column: finished however it was
      // consumed.
      final book = await addBook();
      final chapters = await addChapters(book, 2);
      await saveReadingPosition(
        db,
        bookId: book,
        chapterId: chapters[1],
        progress: 1,
        clock: clock,
      );
      await (db.update(db.chapters)..where((c) => c.id.equals(chapters[1])))
          .write(const ChaptersCompanion(isListened: Value(true)));

      expect(await watchContinueReading(db).first, isEmpty);
    });

    test('never shows an audiobook', () async {
      // An audiobook has no reading position to begin with. This holds even if one were written,
      // because the shelf asks for the kind rather than trusting that it cannot happen.
      final audiobook = await addBook(key: 'audio', kind: SourceKind.audio);
      final chapters = await addChapters(audiobook, 1);
      await saveReadingPosition(
        db,
        bookId: audiobook,
        chapterId: chapters[0],
        progress: 0.5,
        clock: clock,
      );

      expect(await watchContinueReading(db).first, isEmpty);
    });

    test('puts the book read most recently first', () async {
      final first = await addBook(key: 'first');
      final second = await addBook(key: 'second');
      final firstChapters = await addChapters(first, 2);
      final secondChapters = await addChapters(second, 2);
      await saveReadingPosition(
        db,
        bookId: first,
        chapterId: firstChapters[0],
        progress: 0.1,
        clock: clock,
      );
      clock.advance(const Duration(minutes: 5));
      await saveReadingPosition(
        db,
        bookId: second,
        chapterId: secondChapters[0],
        progress: 0.1,
        clock: clock,
      );

      final shelf = await watchContinueReading(db).first;
      expect([for (final c in shelf) c.bookId], [second, first]);
    });
  });
}
