/// Which started books belong on Continue Listening and Continue Reading, and taking one off.
///
/// Both shelves used to hold every book ever started and not finished, for as long as it stayed
/// unfinished. A book sampled once and abandoned sat there for good, above the library, and the
/// shelf only ever grew. Two rules now keep it to the books someone is actually in the middle of,
/// and they are the same rule for both shelves, written once so the two cannot drift apart.
library;

import 'package:drift/drift.dart';

import '../database/database.dart';

/// How long a book stays on a Continue shelf after it was last played or read.
///
/// A month: long enough for a book read at weekends, or set aside for a busy fortnight, to still be
/// there on return, and short enough that one tried and abandoned in the spring is not still
/// asking to be continued in the autumn. A book that leaves keeps its place and stays in the
/// library, and is back on the shelf the moment it is played or read again.
const continueShelfRecency = Duration(days: 30);

/// Whether a book last played or read at [lastActive] belongs on its Continue shelf at [now].
///
/// [hiddenAt] is when its listener took it off by hand, if they did. It stays off only until it is
/// used again: activity newer than that is the listener changing their mind, and needs nothing
/// more than playing or reading it.
bool belongsOnContinueShelf({
  required DateTime lastActive,
  required DateTime? hiddenAt,
  required DateTime now,
  Duration recency = continueShelfRecency,
}) {
  if (now.difference(lastActive) > recency) return false;
  return hiddenAt == null || lastActive.isAfter(hiddenAt);
}

/// Takes book [bookId] off whichever Continue shelf it is on, until it is next played or read.
///
/// Its place in the book is untouched, and so is everything else about it; this is a tidy-up of a
/// shelf, not a decision about the book. Returns what was there before, so an Undo can put it back
/// exactly.
Future<DateTime?> hideFromContinueShelf(
  KikuyomiDatabase db,
  int bookId, {
  required DateTime at,
}) => db.transaction(() async {
  final before = await (db.select(
    db.books,
  )..where((b) => b.id.equals(bookId))).getSingleOrNull();
  await (db.update(db.books)..where((b) => b.id.equals(bookId))).write(
    BooksCompanion(continueHiddenAt: Value(at)),
  );
  return before?.continueHiddenAt;
});

/// Puts back what [hideFromContinueShelf] replaced, for an Undo.
Future<void> unhideFromContinueShelf(
  KikuyomiDatabase db,
  int bookId, {
  DateTime? restoring,
}) async {
  await (db.update(db.books)..where((b) => b.id.equals(bookId))).write(
    BooksCompanion(continueHiddenAt: Value(restoring)),
  );
}
