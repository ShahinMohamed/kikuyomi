// Reading an EPUB file from disk into what adding it to the library needs, and the words that say
// why one could not be added. The reader's own tests cover the format; these cover the handover.

import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikuyomi/src/book_files.dart';
import 'package:kikuyomi_sources_builtin/kikuyomi_sources_builtin.dart';

List<int> zip(Map<String, String> files) {
  final archive = Archive();
  for (final MapEntry(key: path, value: text) in files.entries) {
    final bytes = utf8.encode(text);
    archive.addFile(ArchiveFile(path, bytes.length, bytes));
  }
  return ZipEncoder().encode(archive);
}

Map<String, String> anEpub() => {
  'mimetype': 'application/epub+zip',
  'META-INF/container.xml':
      '<container xmlns="urn:oasis:names:tc:opendocument:xmlns:container"><rootfiles>'
      '<rootfile full-path="content.opf" media-type="application/oebps-package+xml"/>'
      '</rootfiles></container>',
  'content.opf':
      '<package xmlns="http://www.idpf.org/2007/opf" version="3.0">'
      '<metadata xmlns:dc="http://purl.org/dc/elements/1.1/">'
      '<dc:title>A Novel</dc:title><dc:creator>An Author</dc:creator></metadata>'
      '<manifest><item id="c1" href="one.xhtml" media-type="application/xhtml+xml"/></manifest>'
      '<spine><itemref idref="c1"/></spine></package>',
  'one.xhtml': '<html><body><h1>The Start</h1><p>Once.</p></body></html>',
};

void main() {
  late Directory folder;

  setUp(() async {
    folder = await Directory.systemTemp.createTemp('kikuyomi-epub-');
  });

  tearDown(() => folder.delete(recursive: true));

  test('an EPUB is read into a book keyed by its own path', () async {
    final file = File('${folder.path}/A Novel.epub');
    await file.writeAsBytes(zip(anEpub()));

    final read = await readEpubFile(file);
    expect(read.path, file.path);
    expect(read.title, 'A Novel');
    expect(read.authors, ['An Author']);
    expect(
      [for (final c in read.chapters) (c.key, c.title)],
      [('one.xhtml', 'The Start')],
    );
  });

  test(
    'a locked EPUB is refused, and the words say which lock and why',
    () async {
      final file = File('${folder.path}/Locked.epub');
      await file.writeAsBytes(
        zip({...anEpub(), 'META-INF/rights.xml': '<rights/>'}),
      );

      Object? error;
      try {
        await readEpubFile(file);
      } catch (caught) {
        error = caught;
      }
      expect(error, isA<EpubProtectedException>());
      expect(describeAddError(error!), contains('locked with Adobe DRM'));
    },
  );

  test('a file that is not an EPUB is refused as one', () async {
    final file = File('${folder.path}/Not.epub');
    await file.writeAsString('hello');

    Object? error;
    try {
      await readEpubFile(file);
    } catch (caught) {
      error = caught;
    }
    expect(error, isA<EpubFormatException>());
    expect(describeAddError(error!), startsWith('it is not an EPUB'));
  });

  test('EPUBs are told apart by their extension, whatever its case', () {
    expect(isEpubPath(r'C:\Books\A Novel.EPUB'), isTrue);
    expect(isEpubPath('a/book.m4b'), isFalse);
  });
}
