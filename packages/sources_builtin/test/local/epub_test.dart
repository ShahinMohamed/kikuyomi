// Reading an EPUB into a book (ADR-0019): its details, its chapters in reading order with their
// titles, its cover, a chapter's text as blocks, and refusing a book locked with DRM.

import 'package:kikuyomi_source_api/kikuyomi_source_api.dart';
import 'package:kikuyomi_sources_builtin/kikuyomi_sources_builtin.dart';
import 'package:test/test.dart';

import 'support/epub_bytes.dart';
import 'support/image_bytes.dart';

/// An EPUB of one package document with [metadata], [manifest] and [spine], and [files] beside it.
List<int> epub({
  String metadata = '<dc:title>A Book</dc:title>',
  required String manifest,
  required String spine,
  String spineAttributes = '',
  Map<String, Object> files = const {},
}) => zip({
  'mimetype': 'application/epub+zip',
  'META-INF/container.xml': containerXml,
  'OEBPS/content.opf': opf(
    metadata: metadata,
    manifest: manifest,
    spine: spine,
    spineAttributes: spineAttributes,
  ),
  ...files,
});

String doc(String id, String href) =>
    '<item id="$id" href="$href" media-type="application/xhtml+xml"/>';

void main() {
  _wordCounts();

  group('details', () {
    test('are read from the package document', () {
      final book = EpubBook.read(
        epub(
          metadata: '''
            <dc:title>  The   Long Road </dc:title>
            <dc:creator>An Author</dc:creator>
            <dc:language>en</dc:language>
            <dc:publisher>A Publisher</dc:publisher>
            <dc:description>A description.</dc:description>''',
          manifest: doc('c1', 'one.xhtml'),
          spine: '<itemref idref="c1"/>',
          files: {'OEBPS/one.xhtml': xhtml('<p>a</p>')},
        ),
      );
      expect(book.title, 'The Long Road');
      expect(book.authors, ['An Author']);
      expect(book.language, 'en');
      expect(book.publisher, 'A Publisher');
      expect(book.description, 'A description.');
    });

    test('credit authors only, in either version of the format', () {
      // An editor or illustrator is not the author a shelf shows. EPUB 2 says so on the element,
      // EPUB 3 in a meta that refines it.
      final book = EpubBook.read(
        epub(
          metadata: '''
            <dc:title>A Book</dc:title>
            <dc:creator opf:role="aut">First Author</dc:creator>
            <dc:creator opf:role="edt">An Editor</dc:creator>
            <dc:creator id="c3">Second Author</dc:creator>
            <meta refines="#c3" property="role" scheme="marc:relators">aut</meta>
            <dc:creator id="c4">An Illustrator</dc:creator>
            <meta refines="#c4" property="role" scheme="marc:relators">ill</meta>
            <dc:creator>Unmarked Author</dc:creator>''',
          manifest: doc('c1', 'one.xhtml'),
          spine: '<itemref idref="c1"/>',
          files: {'OEBPS/one.xhtml': xhtml('<p>a</p>')},
        ),
      );
      expect(book.authors, [
        'First Author',
        'Second Author',
        'Unmarked Author',
      ]);
    });

    test('a book with no title is called Untitled rather than refused', () {
      final book = EpubBook.read(
        epub(
          metadata: '',
          manifest: doc('c1', 'one.xhtml'),
          spine: '<itemref idref="c1"/>',
          files: {'OEBPS/one.xhtml': xhtml('<p>a</p>')},
        ),
      );
      expect(book.title, 'Untitled');
    });
  });

  group('chapters', () {
    test('follow the spine, titled by the navigation document', () {
      final book = EpubBook.read(simpleEpub());
      expect(book.chapters, const [
        EpubChapter(path: 'OEBPS/text/one.xhtml', title: 'Chapter One'),
        EpubChapter(path: 'OEBPS/text/two.xhtml', title: 'Chapter Two'),
      ]);
    });

    test('are titled by the NCX in an EPUB 2', () {
      final book = EpubBook.read(
        epub(
          manifest:
              '${doc('c1', 'one.xhtml')}'
              '<item id="ncx" href="toc.ncx" media-type="application/x-dtbncx+xml"/>',
          spine: '<itemref idref="c1"/>',
          spineAttributes: ' toc="ncx"',
          files: {
            'OEBPS/one.xhtml': xhtml('<p>a</p>'),
            'OEBPS/toc.ncx': '''<?xml version="1.0"?>
<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
  <navMap>
    <navPoint id="p1" playOrder="1">
      <navLabel><text>The First</text></navLabel>
      <content src="one.xhtml"/>
    </navPoint>
  </navMap>
</ncx>''',
          },
        ),
      );
      expect(book.chapters.single.title, 'The First');
    });

    test('left out of the table of contents keep their place, titled by their first heading', () {
      // A title page or a foreword is often missing from the contents. Skipping it would skip what
      // is in it.
      final book = EpubBook.read(
        epub(
          manifest:
              '<item id="nav" href="nav.xhtml" media-type="application/xhtml+xml" properties="nav"/>'
              '${doc('title', 'title.xhtml')}${doc('c1', 'one.xhtml')}${doc('blank', 'blank.xhtml')}',
          spine: '<itemref idref="title"/><itemref idref="c1"/><itemref idref="blank"/>',
          files: {
            'OEBPS/nav.xhtml': xhtml(
              '<nav epub:type="toc"><ol><li><a href="one.xhtml">One</a></li></ol></nav>',
            ),
            'OEBPS/title.xhtml': xhtml('<h2>  A Foreword </h2><p>Hello.</p>'),
            'OEBPS/one.xhtml': xhtml('<p>a</p>'),
            'OEBPS/blank.xhtml': xhtml('<p>Nothing to call it by.</p>'),
          },
        ),
      );
      expect(
        [for (final c in book.chapters) c.title],
        ['A Foreword', 'One', 'Section 3'],
      );
    });

    test('are named by the first entry pointing into them', () {
      // Entries with a fragment point at sections of the same document, which is one chapter.
      final book = EpubBook.read(
        epub(
          manifest:
              '<item id="nav" href="nav.xhtml" media-type="application/xhtml+xml" properties="nav"/>'
              '${doc('c1', 'one.xhtml')}',
          spine: '<itemref idref="c1"/>',
          files: {
            'OEBPS/nav.xhtml': xhtml('''<nav epub:type="toc"><ol>
              <li><a href="one.xhtml#start">Part One</a></li>
              <li><a href="one.xhtml#later">A Section</a></li></ol></nav>'''),
            'OEBPS/one.xhtml': xhtml('<p>a</p>'),
          },
        ),
      );
      expect(book.chapters.single.title, 'Part One');
    });

    test('leave out what the spine marks as not read in order', () {
      final book = EpubBook.read(
        epub(
          manifest: '${doc('c1', 'one.xhtml')}${doc('notes', 'notes.xhtml')}',
          spine: '<itemref idref="c1"/><itemref idref="notes" linear="no"/>',
          files: {
            'OEBPS/one.xhtml': xhtml('<h1>One</h1>'),
            'OEBPS/notes.xhtml': xhtml('<h1>Notes</h1>'),
          },
        ),
      );
      expect([for (final c in book.chapters) c.title], ['One']);
    });

    test('are found through escaped and relative paths', () {
      final book = EpubBook.read(
        epub(
          manifest: doc('c1', '../Text/Chapter%20One.xhtml'),
          spine: '<itemref idref="c1"/>',
          files: {'Text/Chapter One.xhtml': xhtml('<h1>One</h1>')},
        ),
      );
      expect(book.chapters.single.path, 'Text/Chapter One.xhtml');
    });

    test('that the book does not hold, or lists twice, are left out', () {
      final book = EpubBook.read(
        epub(
          manifest: '${doc('c1', 'one.xhtml')}${doc('gone', 'gone.xhtml')}',
          spine:
              '<itemref idref="c1"/><itemref idref="gone"/><itemref idref="c1"/>'
              '<itemref idref="unlisted"/>',
          files: {'OEBPS/one.xhtml': xhtml('<h1>One</h1>')},
        ),
      );
      expect(book.chapters, hasLength(1));
    });
  });

  group('the cover', () {
    test('is the image EPUB 3 marks as the cover', () {
      final book = EpubBook.read(
        epub(
          manifest:
              '${doc('c1', 'one.xhtml')}'
              '<item id="img" href="images/cover.png" media-type="image/png" properties="cover-image"/>',
          spine: '<itemref idref="c1"/>',
          files: {
            'OEBPS/one.xhtml': xhtml('<p>a</p>'),
            'OEBPS/images/cover.png': pngBytes(),
          },
        ),
      );
      expect(book.cover?.mimeType, 'image/png');
      expect(book.cover?.bytes, pngBytes());
    });

    test('is the image an EPUB 2 names in its metadata', () {
      final book = EpubBook.read(
        epub(
          metadata:
              '<dc:title>A Book</dc:title><meta name="cover" content="img"/>',
          manifest:
              '${doc('c1', 'one.xhtml')}'
              '<item id="img" href="cover.jpg" media-type="image/jpeg"/>',
          spine: '<itemref idref="c1"/>',
          files: {
            'OEBPS/one.xhtml': xhtml('<p>a</p>'),
            'OEBPS/cover.jpg': jpegBytes(),
          },
        ),
      );
      expect(book.cover?.mimeType, 'image/jpeg');
    });

    test('is absent when the book names none', () {
      expect(EpubBook.read(simpleEpub()).cover, isNull);
    });
  });

  group('a chapter', () {
    test('reads as blocks', () {
      final book = EpubBook.read(
        simpleEpub(
          extra: {
            'OEBPS/text/one.xhtml': xhtml(
              '<h1>Chapter One</h1><p>It <em>begins</em>.</p>',
            ),
          },
        ),
      );
      expect(book.chapterContent('OEBPS/text/one.xhtml').blocks, const [
        HeadingBlock(1, [TextRun('Chapter One')]),
        ParagraphBlock([
          TextRun('It '),
          TextRun('begins', italic: true),
          TextRun('.'),
        ]),
      ]);
    });

    test('shows images the book holds, by their path in it', () {
      final book = EpubBook.read(
        simpleEpub(
          extra: {
            'OEBPS/text/one.xhtml': xhtml(
              '<img src="../images/map.png" alt="A map"/>'
              '<img src="../images/missing.png"/>'
              '<img src="https://tracker.test/pixel.gif"/>',
            ),
            'OEBPS/images/map.png': pngBytes(),
          },
        ),
      );
      final blocks = book.chapterContent('OEBPS/text/one.xhtml').blocks;
      expect(blocks, [
        ImageBlock(Uri(path: 'OEBPS/images/map.png'), alt: 'A map'),
      ]);
      expect(book.resource('OEBPS/images/map.png'), pngBytes());
    });

    test('that is not in the book is an error', () {
      final book = EpubBook.read(simpleEpub());
      expect(
        () => book.chapterContent('OEBPS/content.opf'),
        throwsArgumentError,
      );
    });
  });

  group('a book locked with DRM is refused, naming the lock', () {
    for (final (file, scheme) in const [
      ('META-INF/rights.xml', 'Adobe DRM'),
      ('META-INF/license.lcpl', 'Readium LCP'),
      ('META-INF/sinf.xml', 'Apple FairPlay'),
    ]) {
      test(scheme, () {
        expect(
          () => EpubBook.read(simpleEpub(extra: {file: '<x/>'})),
          throwsA(
            isA<EpubProtectedException>().having(
              (e) => e.scheme,
              'scheme',
              scheme,
            ),
          ),
        );
      });
    }

    test('and so is any encrypted chapter, whatever the lock', () {
      expect(
        () => EpubBook.read(
          simpleEpub(
            extra: {
              'META-INF/encryption.xml': encryption(
                'http://www.w3.org/2001/04/xmlenc#aes256-cbc',
              ),
            },
          ),
        ),
        throwsA(isA<EpubProtectedException>()),
      );
    });

    test('but obfuscated fonts are not a lock, and the book opens', () {
      for (final algorithm in const [
        'http://www.idpf.org/2008/embedding',
        'http://ns.adobe.com/pdf/enc#RC',
      ]) {
        final book = EpubBook.read(
          simpleEpub(extra: {'META-INF/encryption.xml': encryption(algorithm)}),
        );
        expect(book.chapters, hasLength(2), reason: algorithm);
      }
    });
  });

  group('what is not an EPUB is refused', () {
    test('when it is not a zip', () {
      expect(
        () => EpubBook.read(const [1, 2, 3, 4, 5]),
        throwsA(isA<EpubFormatException>()),
      );
    });

    test('when it has no container', () {
      expect(
        () => EpubBook.read(zip({'hello.txt': 'hi'})),
        throwsA(isA<EpubFormatException>()),
      );
    });

    test('when it has nothing to read', () {
      expect(
        () => EpubBook.read(epub(manifest: '', spine: '')),
        throwsA(isA<EpubFormatException>()),
      );
    });
  });
}

String encryption(String algorithm) =>
    '''<?xml version="1.0"?>
<encryption xmlns="urn:oasis:names:tc:opendocument:xmlns:container"
    xmlns:enc="http://www.w3.org/2001/04/xmlenc#">
  <enc:EncryptedData>
    <enc:EncryptionMethod Algorithm="$algorithm"/>
    <enc:CipherData><enc:CipherReference URI="OEBPS/fonts/font.otf"/></enc:CipherData>
  </enc:EncryptedData>
</encryption>''';

void _wordCounts() {
  group('word counts', () {
    test('count the words a chapter holds, and nothing else', () {
      final book = EpubBook.read(
        simpleEpub(
          extra: {
            'OEBPS/text/one.xhtml': xhtml(
              '<style>p { color: red; }</style>'
              '<script>var hidden = "one two three four five";</script>'
              '<h1>Chapter One</h1>'
              '<p>It began on a <em>cold</em> morning &mdash; the coldest yet.</p>'
              '<img src="x.png" alt="a picture of nothing"/>',
            ),
          },
        ),
      );

      // "Chapter One" is two, and the sentence is ten: It began on a cold morning x the coldest
      // yet. The alt text, the style and the script are not words anyone reads.
      expect(book.wordCounts()['OEBPS/text/one.xhtml'], 12);
    });

    test('are given for every chapter of the book', () {
      final counts = EpubBook.read(simpleEpub()).wordCounts();

      expect(counts.keys, ['OEBPS/text/one.xhtml', 'OEBPS/text/two.xhtml']);
      expect(counts.values, everyElement(greaterThan(0)));
    });
  });
}
