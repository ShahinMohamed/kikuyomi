// Reading `getChapterContent` (SourceAPI 1.1): what a text source says a chapter says.
//
// The converter has its own tests. These are about the door into it — that a result is exactly one
// of HTML or text, that it is held to its size limits, and that an image obeys the domain rule every
// other URL an extension hands over obeys.

import 'package:kikuyomi_source_api/kikuyomi_source_api.dart';
import 'package:test/test.dart';

import 'support.dart';

List<ContentBlock> blocksOf(Map<String, Object?> result) =>
    decoder.decodeChapterContent(result).blocks;

void main() {
  test('reads HTML into blocks', () {
    expect(blocksOf({'html': '<p>Once upon a time.</p>'}), [
      const ParagraphBlock([TextRun('Once upon a time.')]),
    ]);
  });

  test('reads plain text into blocks', () {
    expect(blocksOf({'text': 'One.\n\nTwo.'}), [
      const ParagraphBlock([TextRun('One.')]),
      const ParagraphBlock([TextRun('Two.')]),
    ]);
  });

  test('a chapter with nothing in it is an empty chapter, not an error', () {
    // A source that has not published a chapter's text yet is saying so, not breaking.
    expect(blocksOf({'html': ''}), isEmpty);
  });

  group('is refused', () {
    test('with neither html nor text', () {
      expect(
        () => decoder.decodeChapterContent(<String, Object?>{}),
        throwsA(
          isA<ParseException>().having(
            (e) => e.message,
            'message',
            contains('exactly one of html and text'),
          ),
        ),
      );
    });

    test('with both', () {
      // Which one did the author mean? The contract does not guess.
      expect(
        () => decoder.decodeChapterContent({'html': '<p>a</p>', 'text': 'a'}),
        throwsA(isA<ParseException>()),
      );
    });

    test('when the html is not a string', () {
      expect(
        () => decoder.decodeChapterContent({'html': 42}),
        rejects('html', 'expected a string'),
      );
    });

    test('past the length limit', () {
      expect(
        () => decoder.decodeChapterContent({
          'text': text(SourceLimits.maxChapterContentLength + 1),
        }),
        rejects('text', 'at most'),
      );
    });

    test('at the limit, it is not', () {
      expect(
        () => decoder.decodeChapterContent({
          'text': text(SourceLimits.maxChapterContentLength),
        }),
        returnsNormally,
      );
    });
  });

  group('images', () {
    test('on a declared host are kept', () {
      expect(blocksOf({'html': '<img src="https://example.org/map.png">'}), [
        ImageBlock(Uri.parse('https://example.org/map.png')),
      ]);
    });

    test('on a declared wildcard host are kept', () {
      expect(
        blocksOf({'html': '<img src="https://img.cdn.example.org/a.jpg">'}),
        hasLength(1),
      );
    });

    test('on any other host are left out, and the words around them kept', () {
      // One picture on a CDN the author forgot to declare should cost that picture, not the chapter.
      expect(
        blocksOf({
          'html': '<p>Before.</p><img src="https://tracker.test/pixel.gif"><p>After.</p>',
        }),
        [
          const ParagraphBlock([TextRun('Before.')]),
          const ParagraphBlock([TextRun('After.')]),
        ],
      );
    });

    test('with a relative address resolve against the page', () {
      expect(
        blocksOf({
          'html': '<img src="/images/map.png">',
          'baseUrl': 'https://example.org/novel/chapter-1',
        }),
        [ImageBlock(Uri.parse('https://example.org/images/map.png'))],
      );
    });

    test('with a relative address and no page are left out', () {
      // A relative address with nothing to resolve it against names nothing at all.
      expect(blocksOf({'html': '<img src="images/map.png">'}), isEmpty);
    });

    test('that resolve off the declared hosts are left out', () {
      expect(
        blocksOf({
          'html': '<img src="//tracker.test/pixel.gif">',
          'baseUrl': 'https://example.org/chapter',
        }),
        isEmpty,
      );
    });

    test('a baseUrl off the declared hosts refuses the chapter', () {
      // It is a URL the extension handed over, like any other, and held to the same rule.
      expect(
        () => decoder.decodeChapterContent({
          'html': '<p>a</p>',
          'baseUrl': 'https://elsewhere.test/',
        }),
        throwsA(isA<ParseException>()),
      );
    });

    test('with a script address are left out', () {
      expect(blocksOf({'html': '<img src="javascript:steal()">'}), isEmpty);
    });
  });
}
