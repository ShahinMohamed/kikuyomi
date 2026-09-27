// EPUBs built in memory, so each test says exactly what is in the book it reads.

import 'dart:convert';

import 'package:archive/archive.dart';

const containerXml = '''<?xml version="1.0" encoding="UTF-8"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>''';

/// A package document with [metadata], [manifest] and [spine] as its inner XML.
String opf({
  String metadata = '<dc:title>A Book</dc:title>',
  required String manifest,
  required String spine,
  String spineAttributes = '',
}) =>
    '''<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="3.0" unique-identifier="id"
    xmlns:opf="http://www.idpf.org/2007/opf">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">$metadata</metadata>
  <manifest>$manifest</manifest>
  <spine$spineAttributes>$spine</spine>
</package>''';

/// An XHTML document with [body] as its body.
String xhtml(String body, {String title = 'A page'}) =>
    '''<?xml version="1.0" encoding="UTF-8"?>
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops">
<head><title>$title</title></head>
<body>$body</body>
</html>''';

/// A zip of [files], by path. A string is stored as UTF-8, a list of ints as it is.
List<int> zip(Map<String, Object> files) {
  final archive = Archive();
  for (final MapEntry(key: path, value: content) in files.entries) {
    final bytes = switch (content) {
      final String text => utf8.encode(text),
      final List<int> data => data,
      _ => throw ArgumentError.value(content, path),
    };
    archive.addFile(ArchiveFile(path, bytes.length, bytes));
  }
  return ZipEncoder().encode(archive);
}

/// A plain EPUB 3 of two chapters, with [extra] files added or replacing its own.
List<int> simpleEpub({Map<String, Object> extra = const {}}) => zip({
  'mimetype': 'application/epub+zip',
  'META-INF/container.xml': containerXml,
  'OEBPS/content.opf': opf(
    manifest: '''
      <item id="nav" href="nav.xhtml" media-type="application/xhtml+xml" properties="nav"/>
      <item id="c1" href="text/one.xhtml" media-type="application/xhtml+xml"/>
      <item id="c2" href="text/two.xhtml" media-type="application/xhtml+xml"/>''',
    spine: '<itemref idref="c1"/><itemref idref="c2"/>',
  ),
  'OEBPS/nav.xhtml': xhtml('''
    <nav epub:type="toc"><ol>
      <li><a href="text/one.xhtml">Chapter One</a></li>
      <li><a href="text/two.xhtml">Chapter Two</a></li>
    </ol></nav>'''),
  'OEBPS/text/one.xhtml': xhtml('<p>It begins.</p>'),
  'OEBPS/text/two.xhtml': xhtml('<p>It ends.</p>'),
  ...extra,
});
