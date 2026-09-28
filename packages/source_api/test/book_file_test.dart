// Reading `resolveBook` (SourceAPI 1.2): where the whole book is, for a source that publishes one
// file rather than chapters to fetch (ADR-0021).

import 'package:kikuyomi_source_api/kikuyomi_source_api.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  test('reads where the file is', () {
    final file = decoder.decodeBookFile({
      'request': {'url': 'https://example.org/books/leviathan.epub'},
      'format': 'epub',
      'sizeBytes': 480000,
    });

    expect(
      file.request.url.toString(),
      'https://example.org/books/leviathan.epub',
    );
    expect(file.format, BookFileFormat.epub);
    expect(file.sizeBytes, 480000);
  });

  test('takes EPUB as what a source means when it does not say', () {
    // The only format the contract has, so leaving it out is not ambiguous.
    final file = decoder.decodeBookFile({
      'request': {'url': 'https://example.org/a.epub'},
    });

    expect(file.format, BookFileFormat.epub);
    expect(file.sizeBytes, isNull);
  });

  test('a format this build does not know is not read as an EPUB', () {
    // A later version may add one. Reading it as an EPUB would hand the reader a file it cannot
    // open and say nothing about why.
    final file = decoder.decodeBookFile({
      'request': {'url': 'https://example.org/a.pdf'},
      'format': 'pdf',
    });

    expect(file.format, BookFileFormat.unknown);
  });

  group('is refused', () {
    test('with no request at all', () {
      expect(
        () => decoder.decodeBookFile(<String, Object?>{}),
        throwsA(isA<ParseException>()),
      );
    });

    test('when the file is on a host the manifest never declared', () {
      // A book file is a URL an extension handed over, held to the rule every other one is.
      expect(
        () => decoder.decodeBookFile({
          'request': {'url': 'https://elsewhere.test/a.epub'},
        }),
        throwsA(isA<ParseException>()),
      );
    });

    test('with a size that is not a size', () {
      expect(
        () => decoder.decodeBookFile({
          'request': {'url': 'https://example.org/a.epub'},
          'sizeBytes': -1,
        }),
        rejects('sizeBytes', ''),
      );
    });
  });
}
