// Turning HTML or text into a chapter's blocks (SourceAPI 1.1, ADR-0019).
//
// Two jobs, and the tests split along them. One is reading prose correctly: paragraphs, emphasis,
// whitespace the way a browser would have collapsed it, the scene breaks web novels use. The other
// is the reason this converter exists at all instead of a general HTML renderer — that a stranger's
// markup cannot do anything on a listener's screen. Nearly every test in the second half is a way
// markup might try to, and what it turns into instead.

import 'package:kikuyomi_source_api/kikuyomi_source_api.dart';
import 'package:test/test.dart';

/// Converts [markup] with every image allowed, unchanged.
ChapterContent read(String markup) =>
    contentFromHtml(markup, resolveImage: Uri.tryParse);

/// The text of each block, for tests that care about content and not emphasis.
List<String> texts(ChapterContent content) => [
  for (final block in content.blocks)
    switch (block) {
      ParagraphBlock(:final runs) ||
      HeadingBlock(:final runs) ||
      QuoteBlock(:final runs) ||
      ListItemBlock(:final runs) => runs.map((r) => r.text).join(),
      PreformattedBlock(:final text) => text,
      ImageBlock(:final url) => 'image $url',
      RuleBlock() => '---',
    },
];

void main() {
  group('prose', () {
    test('a paragraph is a paragraph', () {
      expect(read('<p>It was a dark and stormy night.</p>').blocks, [
        const ParagraphBlock([TextRun('It was a dark and stormy night.')]),
      ]);
    });

    test('whitespace collapses as a browser collapses it', () {
      // Across element boundaries too: the space between "a" and "dark" is in the source only once.
      expect(texts(read('<p>\n  It   was <b>a</b>\n\n  dark  night.  </p>')), [
        'It was a dark night.',
      ]);
    });

    test('emphasis is kept, and merged where it runs on', () {
      expect(
        read('<p>A <b>bold</b> and <i>quiet</i> <em>word</em>.</p>').blocks,
        [
          const ParagraphBlock([
            TextRun('A '),
            TextRun('bold', bold: true),
            TextRun(' and '),
            TextRun('quiet', italic: true),
            TextRun(' '),
            TextRun('word', italic: true),
            TextRun('.'),
          ]),
        ],
      );
    });

    test('bold inside italic is both', () {
      final block = read('<p><i>very <b>much</b></i></p>').blocks.single;
      expect(
        (block as ParagraphBlock).runs.last,
        const TextRun('much', bold: true, italic: true),
      );
    });

    test('a line break stays a line break', () {
      expect(texts(read('<p>One line<br>and the next</p>')), [
        'One line\nand the next',
      ]);
    });

    test('text outside any paragraph is still read', () {
      // Web-novel sites put chapter text straight into a div, separated by line breaks.
      expect(texts(read('<div>First.<br><br>Second.</div>')), [
        'First.\n\nSecond.',
      ]);
    });

    test('empty paragraphs are not blocks', () {
      expect(read('<p> </p><p>Words.</p><p>&nbsp;</p>').blocks, hasLength(1));
    });

    test('entities are decoded', () {
      expect(texts(read('<p>Fish &amp; chips &mdash; &#8220;yes&#8221;</p>')), [
        'Fish & chips — “yes”',
      ]);
    });

    test('headings keep their level', () {
      expect(
        read('<h2>Chapter One</h2><p>Text.</p>').blocks.first,
        const HeadingBlock(2, [TextRun('Chapter One')]),
      );
    });

    test('a quotation is quoted, a paragraph at a time', () {
      expect(read('<blockquote><p>One.</p><p>Two.</p></blockquote>').blocks, [
        const QuoteBlock([TextRun('One.')]),
        const QuoteBlock([TextRun('Two.')]),
      ]);
    });

    test('an ordered list is numbered, from its start', () {
      expect(read('<ol start="3"><li>Three</li><li>Four</li></ol>').blocks, [
        const ListItemBlock([TextRun('Three')], number: 3),
        const ListItemBlock([TextRun('Four')], number: 4),
      ]);
    });

    test('a nested list is indented', () {
      final blocks = read('<ul><li>Outer<ul><li>Inner</li></ul></li></ul>')
          .blocks;
      expect(blocks, [
        const ListItemBlock([TextRun('Outer')]),
        const ListItemBlock([TextRun('Inner')], depth: 1),
      ]);
    });

    test('preformatted text keeps its spacing', () {
      expect(
        read('<pre>  a\n    b</pre>').blocks.single,
        const PreformattedBlock('  a\n    b'),
      );
    });

    test('a rule is a scene break', () {
      expect(texts(read('<p>Before.</p><hr><p>After.</p>')), [
        'Before.',
        '---',
        'After.',
      ]);
    });

    for (final mark in ['* * *', '***', '#', '~ ~ ~', '◇◇◇']) {
      test('"$mark" on its own is a scene break', () {
        expect(read('<p>$mark</p>').blocks.single, const RuleBlock());
      });
    }

    test('a lone dash is not a scene break', () {
      // Sometimes dialogue broken off. Reading it as a break would throw words away.
      expect(read('<p>—</p>').blocks.single, isA<ParagraphBlock>());
    });

    test('a table reads as its cells, in order', () {
      expect(texts(read('<table><tr><td>Name</td><td>Age</td></tr></table>')), [
        'Name',
        'Age',
      ]);
    });
  });

  group('images', () {
    test('become blocks of their own, even mid-sentence', () {
      // A picture cannot flow inside a line of text on a phone.
      expect(
        texts(read('<p>Look: <img src="https://a.test/x.png"> there.</p>')),
        ['Look:', 'image https://a.test/x.png', 'there.'],
      );
    });

    test('keep their description', () {
      final block = read('<img src="https://a.test/x.png" alt="A map">')
          .blocks
          .single;
      expect((block as ImageBlock).alt, 'A map');
    });

    test('are read from data-src, where a site loads them lazily', () {
      expect(
        (read('<img data-src="https://a.test/lazy.png">').blocks.single
                as ImageBlock)
            .url,
        Uri.parse('https://a.test/lazy.png'),
      );
    });

    test('are left out when the resolver says no', () {
      final content = contentFromHtml(
        '<p>Words.</p><img src="https://elsewhere.test/x.png">',
        resolveImage: (_) => null,
      );
      expect(texts(content), ['Words.']);
    });
  });

  group('markup that must not do anything', () {
    // Each of these is a way a stranger's HTML might try to act on the screen. What comes out is
    // text, or nothing — never behaviour.

    test('a script contributes nothing, not even its text', () {
      expect(texts(read('<p>Hi</p><script>alert("x")</script>')), ['Hi']);
    });

    test('a style contributes nothing', () {
      expect(texts(read('<style>p{display:none}</style><p>Seen</p>')), [
        'Seen',
      ]);
    });

    test('a frame, an object and an embed contribute nothing', () {
      expect(
        texts(
          read(
            '<iframe src="https://evil.test"></iframe>'
            '<object data="x"></object><embed src="y"><p>Safe</p>',
          ),
        ),
        ['Safe'],
      );
    });

    test('a form contributes nothing, including its labels', () {
      expect(
        texts(
          read(
            '<form><label>Password</label><input type="password">'
            '<button>Go</button></form><p>Text</p>',
          ),
        ),
        ['Text'],
      );
    });

    test('an event handler is never read', () {
      // Only src, data-src, alt and start are ever looked at. There is no attribute here to fire.
      expect(read('<p onclick="steal()">Click</p>').blocks, [
        const ParagraphBlock([TextRun('Click')]),
      ]);
    });

    test('a link is its words, with nowhere to go', () {
      expect(read('<p><a href="javascript:steal()">Read on</a></p>').blocks, [
        const ParagraphBlock([TextRun('Read on')]),
      ]);
    });

    test('inline styling is ignored, hidden text included', () {
      // Hidden text is still text in the source. It is shown rather than obeyed: nothing here reads
      // a style attribute, which is the point.
      expect(texts(read('<p style="color:red">Red</p>')), ['Red']);
    });

    test('an svg contributes nothing', () {
      expect(texts(read('<svg><text>Drawn</text></svg><p>Written</p>')), [
        'Written',
      ]);
    });

    test('site navigation is not prose', () {
      expect(texts(read('<nav>Prev | Next</nav><p>Chapter text.</p>')), [
        'Chapter text.',
      ]);
    });

    test('malformed markup still reads', () {
      expect(texts(read('<p>Unclosed <b>bold<p>Next')), [
        'Unclosed bold',
        'Next',
      ]);
    });
  });

  group('plain text', () {
    test(
      'blank lines separate paragraphs, and single newlines are wrapping',
      () {
        // A Project Gutenberg file: hard wrapped at 70 columns, paragraphs a blank line apart.
        expect(
          texts(
            contentFromText('It was the best\nof times.\n\nIt was the worst.'),
          ),
          ['It was the best of times.', 'It was the worst.'],
        );
      },
    );

    test('with no blank lines, every line is a paragraph', () {
      expect(texts(contentFromText('One.\nTwo.\nThree.')), [
        'One.',
        'Two.',
        'Three.',
      ]);
    });

    test('Windows line endings read the same', () {
      expect(texts(contentFromText('One.\r\n\r\nTwo.')), ['One.', 'Two.']);
    });

    test('scene breaks are recognised here too', () {
      expect(texts(contentFromText('Before.\n\n* * *\n\nAfter.')), [
        'Before.',
        '---',
        'After.',
      ]);
    });
  });

  test('plain text of a whole chapter reads its words in order', () {
    final content = read(
      '<h1>One</h1><p>First <b>para</b>.</p><hr><p>Second.</p>',
    );
    expect(content.plainText, 'One\n\nFirst para.\n\nSecond.');
  });
}
