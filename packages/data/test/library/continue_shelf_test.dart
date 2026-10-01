// Which started books belong on a Continue shelf.
//
// The reported problem was a shelf that only ever grew: every book started and not finished stayed
// on it for good. These hold the two rules that keep it to what someone is in the middle of, and
// the promise that goes with them — that a book leaving the shelf loses nothing, and comes back the
// moment it is used.

import 'package:drift/drift.dart' hide isNull;
import 'package:kikuyomi_data/kikuyomi_data.dart';
import 'package:kikuyomi_source_api/kikuyomi_source_api.dart' show SourceKind;
import 'package:kikuyomi_test_support/kikuyomi_test_support.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

void main() {
  group('the rule', () {
    final now = DateTime.utc(2026, 10, 1, 12);

    test('a book used this month belongs', () {
      expect(
        belongsOnContinueShelf(
          lastActive: now.subtract(const Duration(days: 29)),
          hiddenAt: null,
          now: now,
        ),
        isTrue,
      );
    });

    test('a book left alone for longer does not', () {
      expect(
        belongsOnContinueShelf(
          lastActive: now.subtract(const Duration(days: 31)),
          hiddenAt: null,
          now: now,
        ),
        isFalse,
      );
    });

    test('a book taken off stays off until it is used again', () {
      final used = now.subtract(const Duration(days: 2));
      final hidden = now.subtract(const Duration(days: 1));
      expect(
        belongsOnContinueShelf(lastActive: used, hiddenAt: hidden, now: now),
        isFalse,
      );
      // Played again after being taken off: the listener changed their mind, and that is all it
      // should take.
      expect(
        belongsOnContinueShelf(lastActive: now, hiddenAt: hidden, now: now),
        isTrue,
      );
    });
  });

  group('Continue Listening', () {
    late KikuyomiDatabase db;
    late FakeClock clock;

    setUp(() {
      db = openDatabase();
      clock = FakeClock(start);
    });

    tearDown(() => db.close());

    Future<List<int>> shelf() async => [
      for (final book in await watchContinueListening(db, clock: clock).first)
        book.bookId,
    ];

    test('lets a book go once it has been left alone for a month', () async {
      final id = await addFolderBook(db, clock);
      await listen(db, clock, id, 0, 60000);
      expect(await shelf(), [id]);

      clock.advance(continueShelfRecency + const Duration(days: 1));
      expect(await shelf(), isEmpty);

      // Nothing about the book was lost: playing it again puts it straight back.
      await listen(db, clock, id, 0, 61000);
      expect(await shelf(), [id]);
    });

    test('a book taken off by hand comes back when it is played', () async {
      final kept = await addFolderBook(db, clock, title: 'Kept');
      final taken = await addFolderBook(db, clock, title: 'Taken');
      await listen(db, clock, kept, 0, 1000);
      await listen(db, clock, taken, 0, 1000);

      clock.advance(const Duration(minutes: 1));
      await hideFromContinueShelf(db, taken, at: clock.now());
      expect(await shelf(), [kept]);

      clock.advance(const Duration(minutes: 1));
      await listen(db, clock, taken, 0, 2000);
      expect(await shelf(), containsAll([kept, taken]));
    });

    test('taking a book off keeps its place in it', () async {
      final id = await addFolderBook(db, clock);
      await listen(db, clock, id, 0, 90000);
      await hideFromContinueShelf(db, id, at: clock.now());

      final state = await (db.select(
        db.playbackStates,
      )..where((s) => s.bookId.equals(id))).getSingle();
      expect(state.chapterPositionMs, 90000);
    });

    test('an undo puts back exactly what was there', () async {
      final id = await addFolderBook(db, clock);
      await listen(db, clock, id, 0, 1000);
      clock.advance(const Duration(seconds: 5));

      final before = await hideFromContinueShelf(db, id, at: clock.now());
      expect(before, isNull);
      expect(await shelf(), isEmpty);

      await unhideFromContinueShelf(db, id, restoring: before);
      expect(await shelf(), [id]);
    });
  });

  group('Continue Reading', () {
    late KikuyomiDatabase db;
    late FakeClock clock;

    setUp(() {
      db = openDatabase();
      clock = FakeClock(start);
    });

    tearDown(() => db.close());

    /// A novel of three chapters, opened at the first.
    Future<int> startReading() async {
      await db
          .into(db.sources)
          .insertOnConflictUpdate(
            const SourcesCompanion(
              id: Value(9),
              key: Value('novels'),
              name: Value('Novels'),
              lang: Value('en'),
            ),
          );
      final bookId = await db
          .into(db.books)
          .insert(
            BooksCompanion.insert(
              sourceId: 9,
              key: 'a-novel',
              title: 'A Novel',
              kind: const Value(SourceKind.text),
              inLibrary: const Value(true),
              createdAt: clock.now(),
              updatedAt: clock.now(),
            ),
          );
      final chapters = [
        for (var i = 0; i < 3; i++)
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
      await saveReadingPosition(
        db,
        bookId: bookId,
        chapterId: chapters.first,
        progress: 0.3,
        clock: clock,
      );
      return bookId;
    }

    Future<List<int>> shelf() async => [
      for (final book in await watchContinueReading(db, clock: clock).first)
        book.bookId,
    ];

    test('follows the same month', () async {
      final id = await startReading();
      expect(await shelf(), [id]);
      clock.advance(continueShelfRecency + const Duration(days: 1));
      expect(await shelf(), isEmpty);
    });

    test('and the same hand', () async {
      final id = await startReading();
      clock.advance(const Duration(minutes: 1));
      await hideFromContinueShelf(db, id, at: clock.now());
      expect(await shelf(), isEmpty);
    });
  });
}
