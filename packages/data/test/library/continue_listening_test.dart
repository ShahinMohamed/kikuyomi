import 'package:drift/drift.dart' hide isNull;
import 'package:kikuyomi_data/kikuyomi_data.dart';
import 'package:kikuyomi_test_support/kikuyomi_test_support.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

List<String> titles(List<ContinueListeningBook> books) => [
  for (final book in books) book.title,
];

void main() {
  late KikuyomiDatabase db;
  late FakeClock clock;

  setUp(() {
    db = openDatabase();
    clock = FakeClock(start);
  });

  tearDown(() => db.close());

  Future<List<ContinueListeningBook>> shelf() =>
      watchContinueListening(db, clock: clock).first;

  test('holds no book that has not been started', () async {
    await addFolderBook(db, clock);
    expect(await shelf(), isEmpty);
  });

  test(
    'shows a started book with its author, length, place and chapter',
    () async {
      final id = await addFolderBook(db, clock);
      await listen(db, clock, id, 1, 60000);

      final book = (await shelf()).single;
      expect(book.bookId, id);
      expect(book.title, 'A Book');
      expect(book.author, 'An Author');
      expect(book.totalDurationMs, 2100000);
      expect(book.globalPositionMs, 660000);
      expect(book.chapterTitle, 'Middle');
      expect(book.lastPlayedAt.isAtSameMomentAs(start), isTrue);
    },
  );

  test('has no author for a book credited with none', () async {
    final id = await addFolderBook(db, clock, authors: const []);
    await listen(db, clock, id, 0, 1000);
    expect((await shelf()).single.author, isNull);
  });

  test("names the book's cover, once it has one", () async {
    final id = await addFolderBook(db, clock);
    await listen(db, clock, id, 0, 1000);
    expect((await shelf()).single.coverFileName, isNull);

    await (db.update(db.books)..where((b) => b.id.equals(id))).write(
      BooksCompanion(coverLocalPath: Value('$id.jpg')),
    );
    expect((await shelf()).single.coverFileName, '$id.jpg');
  });

  test(
    'names the embedded chapter being listened to in a single file',
    () async {
      final id = await addM4b(db, clock);
      await listen(db, clock, id, 0, 1500000);
      expect((await shelf()).single.chapterTitle, 'Chapter Two');
    },
  );

  test('puts the most recently played book first', () async {
    final first = await addFolderBook(db, clock, title: 'First');
    final second = await addFolderBook(db, clock, title: 'Second');
    await listen(db, clock, first, 0, 1000);
    await listen(db, clock, second, 0, 1000);
    expect(titles(await shelf()), ['Second', 'First']);

    await listen(db, clock, first, 0, 2000);
    expect(titles(await shelf()), ['First', 'Second']);
  });

  test('leaves out a book taken out of the library', () async {
    final id = await addFolderBook(db, clock);
    await listen(db, clock, id, 0, 1000);
    await removeBookFromLibrary(db, id, clock: clock);
    expect(await shelf(), isEmpty);
  });

  group('a finished book', () {
    test('is left out once its last chapter is listened', () async {
      final id = await addFolderBook(db, clock);
      // End lasts 5 minutes, so it is listened from 4:30.
      await listen(db, clock, id, 2, 270000);
      expect(await shelf(), isEmpty);
    });

    test('is not finished while the last chapter is short of that', () async {
      final id = await addFolderBook(db, clock);
      await listen(db, clock, id, 2, 269999);
      expect(titles(await shelf()), ['A Book']);
    });

    test('is not finished by an earlier chapter played to its end', () async {
      final id = await addFolderBook(db, clock);
      await listen(db, clock, id, 0, 600000);
      expect(titles(await shelf()), ['A Book']);
    });

    test('stays out while the listener only moves back through it', () async {
      final id = await addFolderBook(db, clock);
      await listen(db, clock, id, 2, 300000);
      await listen(db, clock, id, 0, 5000);
      expect(await shelf(), isEmpty);
    });

    test('comes back once started again', () async {
      final id = await addFolderBook(db, clock);
      await listen(db, clock, id, 2, 300000);
      final last = (await chapterIdsOf(db, id)).last;

      // What the player does when a finished book is started again.
      await listen(db, clock, id, 0, 0);
      await DriftPlaybackStore(
        db,
        deviceId: 'test-device',
        clock: clock,
      ).saveChapterListened(bookId: id, chapterId: last, listened: false);

      final book = (await shelf()).single;
      expect(book.chapterTitle, 'Opening');
      expect(book.globalPositionMs, 0);
    });

    test(
      'is left out once marked finished, wherever its listener is',
      () async {
        final id = await addFolderBook(db, clock);
        await listen(db, clock, id, 1, 60000);
        await markBookFinished(db, id, clock: clock);
        expect(await shelf(), isEmpty);
      },
    );

    test('comes back once marked not finished, though its place is past the threshold', () async {
      final id = await addFolderBook(db, clock);
      await listen(db, clock, id, 2, 300000);
      await markBookNotFinished(db, id, clock: clock);

      final book = (await shelf()).single;
      expect(book.globalPositionMs, 2100000, reason: 'the place is kept');
    });

    test('is a single file listened to near its end', () async {
      final id = await addM4b(db, clock);
      // An hour less 3 percent is 58:12.
      await listen(db, clock, id, 0, 3492000);
      expect(await shelf(), isEmpty);
    });

    test('is judged by the last chapter the source still reports', () async {
      final id = await addFolderBook(db, clock);
      final chapters = await chapterIdsOf(db, id);
      await (db.update(db.chapters)..where((c) => c.id.equals(chapters[2])))
          .write(const ChaptersCompanion(removedFromSource: Value(true)));

      await listen(db, clock, id, 1, 1200000);
      expect(await shelf(), isEmpty);
    });

    test('is judged by the last chapter that can be played', () async {
      final id = await addFolderBook(db, clock);
      await db
          .into(db.chapters)
          .insert(
            ChaptersCompanion.insert(
              bookId: id,
              key: 'not laid out yet',
              title: 'Epilogue',
              sourceIndex: 3,
              createdAt: start,
              updatedAt: start,
            ),
          );

      await listen(db, clock, id, 2, 300000);
      expect(await shelf(), isEmpty);
    });
  });

  group('updates by itself', () {
    test('when progress is saved', () async {
      final id = await addFolderBook(db, clock);
      final shown = expectLater(
        watchContinueListening(db, clock: clock).map(titles),
        emitsThrough(['A Book']),
      );
      await listen(db, clock, id, 0, 1000);
      await shown;
    });

    test('when an author is renamed', () async {
      final id = await addFolderBook(db, clock);
      await listen(db, clock, id, 0, 1000);
      final shown = expectLater(
        watchContinueListening(
          db,
          clock: clock,
        ).map((books) => [for (final book in books) book.author]),
        emitsThrough(['A. N. Author']),
      );
      await (db.update(db.people)..where((p) => p.name.equals('An Author')))
          .write(const PeopleCompanion(name: Value('A. N. Author')));
      await shown;
    });
  });
}
