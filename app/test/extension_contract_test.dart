// Every extension this project publishes answers `getBookDetails` with the fields the contract
// demands.
//
// A stopgap, and it says so. The right check is the probe, which runs an extension on the real
// QuickJS engine; `flutter test` cannot, because it does not build the engine's native library. So
// this reads the source and looks at which keys the details object is built from.
//
// It exists because the omission it checks for actually shipped. Two extensions went into the
// official repository without `narrators`, and one without `genres` as well, and both failed the
// moment a book was opened — after a Node harness, a static manifest test and a green CI run had
// all passed them. Reading a field list is a poor substitute for running the code, and it is a
// great deal better than nothing.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// What `decodeBookDetails` refuses to do without (`packages/source_api/.../decoder.dart`).
///
/// `authors`, `narrators` and `genres` are `required: true` — a list may be empty but must be
/// there — and `key`, `title` and `status` are read outright.
const requiredDetailFields = {
  'key',
  'title',
  'authors',
  'narrators',
  'genres',
  'status',
};

final _extensions = Directory('assets/extensions');

/// The keys the object returned from `getBookDetails` is built from.
///
/// Read from the method's own text: everything of the form `name:` at the indentation a field of
/// the returned object sits at. Nested objects are indented further and so are not mistaken for
/// fields of the book.
Set<String> detailFieldsOf(File code) {
  final source = code.readAsStringSync();
  final start = source.indexOf('async getBookDetails');
  expect(start, greaterThan(-1), reason: '${code.path} has no getBookDetails');
  final end = source.indexOf('\n  },', start);
  expect(
    end,
    greaterThan(start),
    reason: '${code.path}: getBookDetails does not end',
  );

  final body = source.substring(start, end);
  return {
    for (final match in RegExp(
      r'^      ([a-zA-Z]+):',
      multiLine: true,
    ).allMatches(body))
      match.group(1)!,
  };
}

void main() {
  final folders =
      _extensions
          .listSync()
          .whereType<Directory>()
          .where((d) => File('${d.path}/main.js').existsSync())
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  test('there are extensions to check', () {
    // A test that silently checks nothing is worse than no test.
    expect(folders, isNotEmpty);
  });

  for (final folder in folders) {
    final name = folder.path.split(RegExp(r'[\\/]')).last;

    test('$name answers getBookDetails with every required field', () {
      final fields = detailFieldsOf(File('${folder.path}/main.js'));

      expect(
        requiredDetailFields.difference(fields),
        isEmpty,
        reason:
            '$name would throw when a book is opened. A list with nothing in '
            'it is fine; leaving the field out is not.',
      );
    });
  }
}
