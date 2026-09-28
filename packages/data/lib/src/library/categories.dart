/// The listener's own shelves: §4.3's `category` and `book_category` (Phase 4).
///
/// A category is a name and a place in an order, and a book may be in any number of them. The tables
/// have been here since the schema was written and nothing ever read or wrote them; backups have
/// carried categories all along, so a restore could put back shelves the app could not show.
///
/// **A name identifies a category.** Not the row id: a backup written on one device and restored on
/// another matches categories by name, because a name is how a listener tells them apart and an
/// autoincrement id means nothing across two databases. That makes uniqueness a rule rather than a
/// nicety — two categories called "Fiction" would make a restore ambiguous — so it is enforced here,
/// ignoring case and surrounding space, which is how a person tells them apart too.
///
/// **Uncategorised is not a category.** A book in none belongs to no shelf, and the library's "All"
/// is not a row: it is the absence of a filter. Giving uncategorised books a real category would
/// mean every book joining one on import and leaving it on being filed, which is a great deal of
/// writing to express "nothing has been decided about this book".
library;

import 'package:drift/drift.dart';
import 'package:kikuyomi_source_api/kikuyomi_source_api.dart' show SourceKind;

import '../database/database.dart';
import 'watch_tables.dart';

/// A name that cannot be used, and why, in a sentence a screen can show.
final class CategoryNameRefused implements Exception {
  const CategoryNameRefused(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Every category, in the order the listener put them in.
Stream<List<CategoryRow>> watchCategories(KikuyomiDatabase db) =>
    (db.select(db.categories)..orderBy([
          (c) => OrderingTerm.asc(c.sortOrder),
          // Two rows can share a sort order while one is being moved. The id breaks the tie so the
          // list never flickers between two orders that are both "correct".
          (c) => OrderingTerm.asc(c.id),
        ]))
        .watch();

/// Every category, once.
Future<List<CategoryRow>> readCategories(KikuyomiDatabase db) =>
    (db.select(db.categories)..orderBy([
          (c) => OrderingTerm.asc(c.sortOrder),
          (c) => OrderingTerm.asc(c.id),
        ]))
        .get();

/// Makes a category called [name] and gives its id.
///
/// It goes last, which is where a thing just made belongs until it is moved.
///
/// Throws [CategoryNameRefused] for a blank name or one already taken.
Future<int> createCategory(KikuyomiDatabase db, String name) async {
  final tidy = name.trim();
  await _refuseBadName(db, tidy);
  final last = await (db.selectOnly(
    db.categories,
  )..addColumns([db.categories.sortOrder.max()])).getSingleOrNull();
  final after = last?.read(db.categories.sortOrder.max()) ?? -1;
  return db
      .into(db.categories)
      .insert(CategoriesCompanion.insert(name: tidy, sortOrder: after + 1));
}

/// Renames [categoryId].
///
/// Throws [CategoryNameRefused] for a blank name or one another category already has.
Future<void> renameCategory(
  KikuyomiDatabase db,
  int categoryId,
  String name,
) async {
  final tidy = name.trim();
  await _refuseBadName(db, tidy, except: categoryId);
  await (db.update(db.categories)..where((c) => c.id.equals(categoryId))).write(
    CategoriesCompanion(name: Value(tidy)),
  );
}

/// Deletes [categoryId].
///
/// The books in it are untouched: a shelf is not a container, and emptying one has never meant
/// throwing away what was on it. They simply stop being in that category, which the cascade on
/// `book_category` does.
Future<void> deleteCategory(KikuyomiDatabase db, int categoryId) async {
  await (db.delete(db.categories)..where((c) => c.id.equals(categoryId))).go();
}

/// Puts the categories in the order [orderedIds] gives.
///
/// Ids that are not categories are ignored, and categories left out keep their places after the
/// ones named, so a caller passing a partial order cannot silently lose a shelf.
Future<void> reorderCategories(
  KikuyomiDatabase db,
  List<int> orderedIds,
) async {
  await db.transaction(() async {
    final known = {for (final row in await readCategories(db)) row.id};
    final wanted = [
      for (final id in orderedIds)
        if (known.contains(id)) id,
    ];
    final rest = [
      for (final id in known)
        if (!wanted.contains(id)) id,
    ];
    for (final (rank, id) in [...wanted, ...rest].indexed) {
      await (db.update(db.categories)..where((c) => c.id.equals(id))).write(
        CategoriesCompanion(sortOrder: Value(rank)),
      );
    }
  });
}

/// The categories book [bookId] is in, watched.
Stream<Set<int>> watchBookCategories(KikuyomiDatabase db, int bookId) =>
    watchTables(db, [db.bookCategories], () => readBookCategories(db, bookId));

/// The categories book [bookId] is in, once.
Future<Set<int>> readBookCategories(KikuyomiDatabase db, int bookId) async {
  final rows = await (db.select(
    db.bookCategories,
  )..where((b) => b.bookId.equals(bookId))).get();
  return {for (final row in rows) row.categoryId};
}

/// Files book [bookId] under exactly [categoryIds] and no others.
///
/// One transaction, because a book half-filed is a book that appears under a shelf it was being
/// moved off and not under the one it was moved to.
Future<void> setBookCategories(
  KikuyomiDatabase db,
  int bookId,
  Set<int> categoryIds,
) async {
  await db.transaction(() async {
    await (db.delete(
      db.bookCategories,
    )..where((b) => b.bookId.equals(bookId))).go();
    for (final categoryId in categoryIds) {
      await db
          .into(db.bookCategories)
          .insert(
            BookCategoriesCompanion.insert(
              bookId: bookId,
              categoryId: categoryId,
            ),
            mode: InsertMode.insertOrIgnore,
          );
    }
  });
}

/// The ids of the books in [categoryId], watched.
Stream<Set<int>> watchBooksIn(KikuyomiDatabase db, int categoryId) =>
    watchTables(db, [db.bookCategories], () async {
      final rows = await (db.select(
        db.bookCategories,
      )..where((b) => b.categoryId.equals(categoryId))).get();
      return {for (final row in rows) row.bookId};
    });

/// How many books are in each category, by category id, watched.
///
/// For a screen that says what a shelf holds before it is opened. Categories with nothing in them
/// are absent rather than zero, because a caller reading `?? 0` says the same thing with less
/// counting.
///
/// [kind] counts only books of one kind, which is what each tab's bar wants: a category holding
/// eleven audiobooks and one novel says "1" above the reading shelf, because one is what opening it
/// there would show.
Stream<Map<int, int>> watchCategoryCounts(
  KikuyomiDatabase db, {
  SourceKind? kind,
}) => watchTables(db, [db.bookCategories, db.books], () async {
  final count = db.bookCategories.bookId.count();
  final rows =
      await (db.selectOnly(db.bookCategories).join([
              innerJoin(
                db.books,
                db.books.id.equalsExp(db.bookCategories.bookId),
              ),
            ])
            ..addColumns([db.bookCategories.categoryId, count])
            ..where(
              db.books.inLibrary.equals(true) &
                  (kind == null
                      ? const CustomExpression<bool>('1')
                      : db.books.kind.equalsValue(kind)),
            )
            ..groupBy([db.bookCategories.categoryId]))
          .get();
  return {
    for (final row in rows)
      row.read(db.bookCategories.categoryId)!: row.read(count)!,
  };
});

/// Throws when [name] cannot be a category's, ignoring [except] when renaming one.
Future<void> _refuseBadName(
  KikuyomiDatabase db,
  String name, {
  int? except,
}) async {
  if (name.isEmpty) {
    throw const CategoryNameRefused('A category needs a name.');
  }
  final taken = await readCategories(db);
  for (final row in taken) {
    if (row.id == except) continue;
    if (row.name.trim().toLowerCase() == name.toLowerCase()) {
      throw CategoryNameRefused('There is already a category called $name.');
    }
  }
}
