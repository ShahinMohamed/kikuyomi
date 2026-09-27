// Searching and ordering the library, without a database.
//
// The interesting cases are the absent ones: a book with no date added, a book whose length nothing
// has said. Both sort last rather than first, because "recently added" and "longest" putting an
// unknown at the top says something untrue about it.

import 'package:kikuyomi_source_api/kikuyomi_source_api.dart' show SourceKind;
import 'package:flutter_test/flutter_test.dart';
import 'package:kikuyomi/src/library/library_shelf.dart';
import 'package:kikuyomi_data/kikuyomi_data.dart';
import 'package:kikuyomi_domain/kikuyomi_domain.dart';

final _at = DateTime.utc(2026, 9, 26, 9);

var _nextId = 0;

BookRow book({
  String title = 'A Book',
  String? subtitle,
  String? seriesName,
  DateTime? dateAdded,
  int? totalDurationMs,
  int? id,
}) {
  final rowId = id ?? ++_nextId;
  return BookRow(
    kind: SourceKind.audio,
    id: rowId,
    sourceId: 1,
    key: 'key-$rowId',
    title: title,
    subtitle: subtitle,
    seriesName: seriesName,
    genres: const [],
    inLibrary: true,
    dateAdded: dateAdded,
    totalDurationMs: totalDurationMs,
    detailsFetched: false,
    userOverrides: const {},
    createdAt: _at,
    updatedAt: _at,
  );
}

List<String> titles(List<BookRow> books) => [for (final b in books) b.title];

void main() {
  setUp(() => _nextId = 0);

  group('searching', () {
    test('matches a title, whatever case it is typed in', () {
      final books = [book(title: 'Moby-Dick'), book(title: 'The Hobbit')];

      expect(titles(arrangeLibrary(books, query: 'moby')), ['Moby-Dick']);
      expect(titles(arrangeLibrary(books, query: 'HOBB')), ['The Hobbit']);
    });

    test('matches part of a word, not only the start', () {
      expect(
        titles(arrangeLibrary([book(title: 'Moby-Dick')], query: 'dick')),
        ['Moby-Dick'],
      );
    });

    test('matches a subtitle and a series', () {
      final books = [
        book(title: 'One', subtitle: 'The Whale'),
        book(title: 'Two', seriesName: 'Stormlight'),
        book(title: 'Three'),
      ];

      expect(titles(arrangeLibrary(books, query: 'whale')), ['One']);
      expect(titles(arrangeLibrary(books, query: 'stormlight')), ['Two']);
    });

    test('an empty or blank query is the whole shelf', () {
      // A cleared search box must not read as an empty library.
      final books = [book(title: 'One'), book(title: 'Two')];

      expect(arrangeLibrary(books), hasLength(2));
      expect(arrangeLibrary(books, query: ''), hasLength(2));
      expect(arrangeLibrary(books, query: '   '), hasLength(2));
    });

    test('a query nothing answers to is empty', () {
      expect(arrangeLibrary([book(title: 'One')], query: 'zzz'), isEmpty);
    });
  });

  group('ordering', () {
    test('by title, ignoring case', () {
      final books = [
        book(title: 'zoology'),
        book(title: 'Anatomy'),
        book(title: 'botany'),
      ];

      expect(titles(arrangeLibrary(books)), ['Anatomy', 'botany', 'zoology']);
    });

    test('by what was added last', () {
      final books = [
        book(title: 'Old', dateAdded: DateTime.utc(2026, 1, 1)),
        book(title: 'New', dateAdded: DateTime.utc(2026, 9, 1)),
        book(title: 'Middle', dateAdded: DateTime.utc(2026, 5, 1)),
      ];

      expect(titles(arrangeLibrary(books, sort: LibrarySort.recentlyAdded)), [
        'New',
        'Middle',
        'Old',
      ]);
    });

    test('by length, longest first', () {
      final books = [
        book(title: 'Short', totalDurationMs: 1000),
        book(title: 'Long', totalDurationMs: 9000),
        book(title: 'Middling', totalDurationMs: 5000),
      ];

      expect(titles(arrangeLibrary(books, sort: LibrarySort.longest)), [
        'Long',
        'Middling',
        'Short',
      ]);
    });

    test('a book with no date added goes last, not first', () {
      // It was imported before the column existed. Putting the oldest thing in the library at the
      // top of "recently added" would be a lie.
      final books = [
        book(title: 'Undated'),
        book(title: 'Dated', dateAdded: DateTime.utc(2026, 1, 1)),
      ];

      expect(titles(arrangeLibrary(books, sort: LibrarySort.recentlyAdded)), [
        'Dated',
        'Undated',
      ]);
    });

    test('a book of unknown length goes last, not first', () {
      // It is not short, it is unknown.
      final books = [
        book(title: 'Unknown'),
        book(title: 'Known', totalDurationMs: 1000),
      ];

      expect(titles(arrangeLibrary(books, sort: LibrarySort.longest)), [
        'Known',
        'Unknown',
      ]);
    });

    test('two books alike order the same way every time', () {
      // Without a last tiebreak the shelf would reorder itself under the listener's finger.
      for (var run = 0; run < 5; run++) {
        final books = [book(title: 'Same', id: 9), book(title: 'Same', id: 3)];
        expect([for (final b in arrangeLibrary(books)) b.id], [3, 9]);
      }
    });

    test('an unknown length falls back to the title, not to chance', () {
      final books = [book(title: 'Beta'), book(title: 'Alpha')];

      expect(titles(arrangeLibrary(books, sort: LibrarySort.longest)), [
        'Alpha',
        'Beta',
      ]);
    });
  });

  test('searching narrows before ordering', () {
    final books = [
      book(title: 'Whale Two', totalDurationMs: 1000),
      book(title: 'Hobbit', totalDurationMs: 9000),
      book(title: 'Whale One', totalDurationMs: 5000),
    ];

    expect(
      titles(arrangeLibrary(books, query: 'whale', sort: LibrarySort.longest)),
      ['Whale One', 'Whale Two'],
    );
  });

  test('the fallback order is by title', () {
    expect(LibrarySort.fallback, LibrarySort.title);
  });

  group('the stored name of an order', () {
    test('reads back', () {
      for (final sort in LibrarySort.values) {
        expect(LibrarySort.byName(sort.name), sort);
      }
    });

    test('one this build does not know is not set rather than a failure', () {
      // A library ordered by a newer build must still open in an older one.
      expect(LibrarySort.byName('byNarratorsBirthday'), isNull);
    });
  });

  group('narrowing to a category', () {
    test('shows only the books in it', () {
      final shelf = arrangeLibrary(
        [
          book(id: 1, title: 'One'),
          book(id: 2, title: 'Two'),
          book(id: 3, title: 'Three'),
        ],
        onlyBookIds: {1, 3},
      );

      expect([for (final b in shelf) b.id], [1, 3]);
    });

    test('a category with nothing in it is an empty shelf', () {
      // Not the whole library. An empty set is a real answer -- a shelf that holds nothing -- and
      // treating it as "no filter" would show every book under a category that has none.
      final shelf = arrangeLibrary([
        book(id: 1, title: 'One'),
        book(id: 2, title: 'Two'),
      ], onlyBookIds: const {});

      expect(shelf, isEmpty);
    });

    test('no category chosen shows everything', () {
      final shelf = arrangeLibrary([
        book(id: 1, title: 'One'),
        book(id: 2, title: 'Two'),
      ]);

      expect(shelf, hasLength(2));
    });

    test('the search still applies inside a category', () {
      final shelf = arrangeLibrary(
        [
          book(id: 1, title: 'Dune'),
          book(id: 2, title: 'Dracula'),
          book(id: 3, title: 'Emma'),
        ],
        query: 'dun',
        onlyBookIds: {1, 2},
      );

      expect([for (final b in shelf) b.id], [1]);
    });
  });
}
