// The listener's own shelves (§4.3's `category` and `book_category`).
//
// The rules worth pinning are the ones a screen would otherwise have to remember: a name is what
// identifies a category, because that is what a backup matches on; deleting a shelf is not deleting
// what was on it; and filing a book is one write, not a removal followed by an addition that could
// be seen in between.

// Drift exports a query helper called isNull that collides with the matcher of the same name.
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:kikuyomi_data/kikuyomi_data.dart';
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
            id: Value(7),
            key: Value('librivox'),
            name: Value('LibriVox'),
            lang: Value('multi'),
          ),
        );
  });

  Future<int> addBook({String key = 'a-book', bool inLibrary = true}) => db
      .into(db.books)
      .insert(
        BooksCompanion.insert(
          sourceId: 7,
          key: key,
          title: 'A Book',
          inLibrary: Value(inLibrary),
          createdAt: clock.now(),
          updatedAt: clock.now(),
        ),
      );

  Future<List<String>> names() async => [
    for (final row in await readCategories(db)) row.name,
  ];

  group('making one', () {
    test('goes last, where a thing just made belongs', () async {
      await createCategory(db, 'Fiction');
      await createCategory(db, 'History');

      expect(await names(), ['Fiction', 'History']);
    });

    test('trims what was typed', () async {
      final id = await createCategory(db, '  Fiction  ');

      final row = (await readCategories(db)).single;
      expect(row.id, id);
      expect(row.name, 'Fiction');
    });

    test('refuses a blank name', () async {
      await expectLater(
        createCategory(db, '   '),
        throwsA(isA<CategoryNameRefused>()),
      );
    });

    test('refuses a name already taken, whatever its case', () async {
      // A backup matches categories by name, so two called the same thing would make a restore
      // ambiguous. This is the only place that can be stopped.
      await createCategory(db, 'Fiction');

      await expectLater(
        createCategory(db, 'fiction'),
        throwsA(
          isA<CategoryNameRefused>().having(
            (e) => e.message,
            'message',
            contains('already a category'),
          ),
        ),
      );
    });
  });

  group('renaming one', () {
    test('keeps its place', () async {
      final first = await createCategory(db, 'Fiction');
      await createCategory(db, 'History');

      await renameCategory(db, first, 'Novels');

      expect(await names(), ['Novels', 'History']);
    });

    test('may keep its own name, in another case', () async {
      // Renaming "fiction" to "Fiction" is a listener fixing their capitals, not a clash.
      final id = await createCategory(db, 'fiction');

      await expectLater(renameCategory(db, id, 'Fiction'), completes);
      expect(await names(), ['Fiction']);
    });

    test("refuses another category's name", () async {
      await createCategory(db, 'Fiction');
      final second = await createCategory(db, 'History');

      await expectLater(
        renameCategory(db, second, 'Fiction'),
        throwsA(isA<CategoryNameRefused>()),
      );
    });
  });

  group('deleting one', () {
    test('leaves the books that were in it', () async {
      // A shelf is not a container. Emptying one has never meant throwing away what was on it.
      final book = await addBook();
      final category = await createCategory(db, 'Fiction');
      await setBookCategories(db, book, {category});

      await deleteCategory(db, category);

      expect(await readCategories(db), isEmpty);
      expect(
        await (db.select(db.books)..where((b) => b.id.equals(book))).get(),
        hasLength(1),
      );
      expect(await readBookCategories(db, book), isEmpty);
    });
  });

  group('putting them in order', () {
    test('follows the order given', () async {
      final a = await createCategory(db, 'A');
      final b = await createCategory(db, 'B');
      final c = await createCategory(db, 'C');

      await reorderCategories(db, [c, a, b]);

      expect(await names(), ['C', 'A', 'B']);
    });

    test('keeps the ones left out, after the ones named', () async {
      // A partial order must not lose a shelf.
      final a = await createCategory(db, 'A');
      final b = await createCategory(db, 'B');
      await createCategory(db, 'C');

      await reorderCategories(db, [b, a]);

      expect(await names(), ['B', 'A', 'C']);
    });

    test('ignores an id that is not a category', () async {
      final a = await createCategory(db, 'A');

      await expectLater(reorderCategories(db, [999, a]), completes);
      expect(await names(), ['A']);
    });
  });

  group('filing a book', () {
    test('puts it in the categories given and no others', () async {
      final book = await addBook();
      final fiction = await createCategory(db, 'Fiction');
      final history = await createCategory(db, 'History');

      await setBookCategories(db, book, {fiction, history});
      await setBookCategories(db, book, {history});

      expect(await readBookCategories(db, book), {history});
    });

    test('filing it under none takes it off every shelf', () async {
      final book = await addBook();
      final fiction = await createCategory(db, 'Fiction');
      await setBookCategories(db, book, {fiction});

      await setBookCategories(db, book, const {});

      expect(await readBookCategories(db, book), isEmpty);
    });

    test('a book may be on several shelves at once', () async {
      final book = await addBook();
      final fiction = await createCategory(db, 'Fiction');
      final favourites = await createCategory(db, 'Favourites');

      await setBookCategories(db, book, {fiction, favourites});

      expect(await readBookCategories(db, book), {fiction, favourites});
    });
  });

  group('what a shelf holds', () {
    test('names the books in it', () async {
      final one = await addBook(key: 'one');
      final two = await addBook(key: 'two');
      final fiction = await createCategory(db, 'Fiction');
      await setBookCategories(db, one, {fiction});

      expect(await watchBooksIn(db, fiction).first, {one});
      expect(await watchBooksIn(db, fiction).first, isNot(contains(two)));
    });

    test('counts only what is in the library', () async {
      // A book taken out of the library keeps its categories (§4.4 keeps what carries user data), so
      // a count that included it would say a shelf holds books the shelf does not show.
      final kept = await addBook(key: 'kept');
      final gone = await addBook(key: 'gone', inLibrary: false);
      final fiction = await createCategory(db, 'Fiction');
      await setBookCategories(db, kept, {fiction});
      await setBookCategories(db, gone, {fiction});

      expect(await watchCategoryCounts(db).first, {fiction: 1});
    });

    test('an empty shelf is absent rather than zero', () async {
      final fiction = await createCategory(db, 'Fiction');

      final counts = await watchCategoryCounts(db).first;

      expect(counts[fiction], isNull);
      expect(counts[fiction] ?? 0, 0, reason: 'which reads the same');
    });
  });

  test('a shelf answers again when a book joins it', () async {
    final book = await addBook();
    final fiction = await createCategory(db, 'Fiction');

    final seen = <Set<int>>[];
    final sub = watchBooksIn(db, fiction).listen(seen.add);
    addTearDown(sub.cancel);
    await pumpEventQueue();

    await setBookCategories(db, book, {fiction});
    await pumpEventQueue();

    expect(seen.first, isEmpty);
    expect(seen.last, {book});
  });
}
