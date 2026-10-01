import 'package:kikuyomi_data/kikuyomi_data.dart';
import 'package:kikuyomi_domain/kikuyomi_domain.dart';
import 'package:kikuyomi_test_support/kikuyomi_test_support.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

void main() {
  late KikuyomiDatabase db;
  late FakeClock clock;

  setUp(() {
    db = openDatabase();
    clock = FakeClock(start);
  });

  tearDown(() => db.close());

  test('takes the book out of the library', () async {
    final id = await addFolderBook(db, clock);
    clock.advance(const Duration(days: 1));
    await removeBookFromLibrary(db, id, clock: clock);

    final book = await (db.select(
      db.books,
    )..where((b) => b.id.equals(id))).getSingle();
    expect(book.inLibrary, isFalse);
    expect(book.updatedAt.isAtSameMomentAs(clock.now()), isTrue);
    expect((await watchBookOverview(db, id).first)!.inLibrary, isFalse);
  });

  test('keeps the progress, credits, chapters and files', () async {
    final id = await addFolderBook(db, clock);
    await listen(db, clock, id, 1, 60000);
    await removeBookFromLibrary(db, id, clock: clock);

    expect(await db.select(db.playbackStates).get(), hasLength(1));
    expect(await db.select(db.bookPeople).get(), hasLength(3));
    expect(await db.select(db.chapters).get(), hasLength(3));
    expect(await db.select(db.chapterSegments).get(), hasLength(3));
    expect(await db.select(db.mediaFiles).get(), hasLength(3));
  });

  test('adding the book again resumes where the listener left off', () async {
    final id = await addFolderBook(db, clock);
    await listen(db, clock, id, 1, 60000);
    await removeBookFromLibrary(db, id, clock: clock);

    expect(await addFolderBook(db, clock), id);
    expect(
      (await loadStoredPlayback(db, id)).resumeFrom,
      ChapterPosition(
        chapterId: (await chapterIdsOf(db, id))[1],
        offsetMs: 60000,
      ),
    );
    expect(
      [
        for (final book in await watchContinueListening(db, clock: clock).first)
          book.bookId,
      ],
      [id],
    );
  });

  test('does nothing for a book that does not exist', () async {
    await removeBookFromLibrary(db, 999, clock: clock);
    expect(await db.select(db.books).get(), isEmpty);
  });
}
