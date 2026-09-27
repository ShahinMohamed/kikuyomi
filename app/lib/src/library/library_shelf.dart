/// Putting the library in the order and the shape the shelf shows it in (§2.6).
///
/// A pure function over the rows the database already gives, rather than a query per order. A
/// library is hundreds of books, not hundreds of thousands, and sorting them in memory costs less
/// than re-running a watched query every time the listener changes their mind — and it keeps the
/// ordering somewhere a test can reach without a database.
library;

import 'package:kikuyomi_data/kikuyomi_data.dart' show BookRow;
import 'package:kikuyomi_domain/kikuyomi_domain.dart';

/// [books] narrowed to [onlyBookIds], searched by [query] and put in [sort] order.
///
/// The narrowing and the search run first, so the order is the order of what is actually shown.
///
/// [onlyBookIds] is the category the listener has chosen, or null for all of them. Null rather than
/// every id, because "no category chosen" and "a category that happens to hold every book" are
/// different things, and only one of them should keep showing a book that has just been filed
/// elsewhere.
List<BookRow> arrangeLibrary(
  List<BookRow> books, {
  String query = '',
  LibrarySort sort = LibrarySort.fallback,
  Set<int>? onlyBookIds,
}) {
  final found = [
    for (final book in books)
      if ((onlyBookIds?.contains(book.id) ?? true) &&
          matchesLibrarySearch(book, query))
        book,
  ];
  found.sort(_comparatorFor(sort));
  return found;
}

/// Whether [book] answers to [query].
///
/// Case-insensitive, and across the three things a listener types when they are looking for a book
/// they already own: its title, its subtitle, and the series it belongs to. Not the author, which
/// lives in another table and would cost the shelf a join it does not otherwise need.
///
/// An empty or blank query matches everything, so a cleared search box is not an empty shelf.
bool matchesLibrarySearch(BookRow book, String query) {
  final wanted = query.trim().toLowerCase();
  if (wanted.isEmpty) return true;
  for (final field in [book.title, book.subtitle, book.seriesName]) {
    if (field != null && field.toLowerCase().contains(wanted)) return true;
  }
  return false;
}

int Function(BookRow, BookRow) _comparatorFor(LibrarySort sort) =>
    switch (sort) {
      LibrarySort.title => _byTitle,
      LibrarySort.recentlyAdded => _byRecentlyAdded,
      LibrarySort.longest => _byLongest,
    };

int _byTitle(BookRow a, BookRow b) {
  final byTitle = a.title.toLowerCase().compareTo(b.title.toLowerCase());
  // Two books of the same name are two rows, and which comes first has to be the same every time or
  // the shelf reorders itself under the listener's finger.
  return byTitle != 0 ? byTitle : a.id.compareTo(b.id);
}

int _byRecentlyAdded(BookRow a, BookRow b) {
  final theirs = b.dateAdded;
  final mine = a.dateAdded;
  // A book with no date was imported before the column existed. It goes last rather than first,
  // because "recently added" putting the oldest thing in the library at the top would be a lie.
  if (mine == null && theirs == null) return _byTitle(a, b);
  if (mine == null) return 1;
  if (theirs == null) return -1;
  final byDate = theirs.compareTo(mine);
  return byDate != 0 ? byDate : _byTitle(a, b);
}

int _byLongest(BookRow a, BookRow b) {
  final theirs = b.totalDurationMs;
  final mine = a.totalDurationMs;
  // A book whose length nothing has said goes last, for the same reason: it is not short, it is
  // unknown, and putting it at the top of "longest" would say the wrong thing.
  if (mine == null && theirs == null) return _byTitle(a, b);
  if (mine == null) return 1;
  if (theirs == null) return -1;
  final byLength = theirs.compareTo(mine);
  return byLength != 0 ? byLength : _byTitle(a, b);
}
