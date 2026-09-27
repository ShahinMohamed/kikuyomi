/// An EPUB read as a book (ADR-0019).
///
/// An EPUB is a zip. `META-INF/container.xml` names the package document, an OPF file, which holds
/// the book's details, a manifest of every file in it, and a spine: the documents a reader reads, in
/// order. This reads all of that into what an import needs, and a chapter's document into blocks when
/// it is read, through the same converter a text extension's HTML goes through, so a local book is
/// held to the same rules as anything a source sends.
///
/// Each document in the spine becomes one chapter. Its title comes from the book's own table of
/// contents, the EPUB 3 navigation document or the EPUB 2 NCX, and failing both from the document's
/// first heading. A document the table of contents leaves out, such as a title page, still gets a
/// chapter: skipping it would skip what is in it.
///
/// A book locked with DRM is refused, never opened: [EpubProtectedException]. Kikuyomi does not
/// remove DRM, and a reader that showed a locked book's scrambled bytes as text would be worse than
/// one that said what the lock is. Font obfuscation, which scrambles an embedded font so it cannot
/// be lifted out, is not DRM and does not lock the text, so a book with only that opens.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:html/parser.dart' as html;
import 'package:kikuyomi_source_api/kikuyomi_source_api.dart';
import 'package:xml/xml.dart';

import 'embedded_picture.dart';

/// The algorithms that obfuscate embedded fonts: IDPF's and Adobe's. A file encrypted with either
/// is a font, scrambled so it cannot be lifted out of the book, and the text is not locked at all.
const _fontObfuscation = {
  'http://www.idpf.org/2008/embedding',
  'http://ns.adobe.com/pdf/enc#RC',
};

/// An EPUB that cannot be read at all: not a zip, or a zip with no package document in it.
final class EpubFormatException implements Exception {
  const EpubFormatException(this.message);

  /// What is wrong, for a person to read.
  final String message;

  @override
  String toString() => 'EpubFormatException: $message';
}

/// An EPUB locked with DRM, which Kikuyomi does not open.
final class EpubProtectedException implements Exception {
  const EpubProtectedException(this.scheme);

  /// The lock, named as its owner names it, such as "Adobe DRM", for a person to read: what they
  /// would need to read the book is the app the lock was made for.
  final String scheme;

  @override
  String toString() => 'EpubProtectedException: locked with $scheme';
}

/// One document of an EPUB's spine, which is one chapter of the book.
final class EpubChapter {
  const EpubChapter({required this.path, required this.title});

  /// Where the document is in the zip. The chapter's identity within its book.
  final String path;
  final String title;

  @override
  bool operator ==(Object other) =>
      other is EpubChapter && other.path == path && other.title == title;

  @override
  int get hashCode => Object.hash(path, title);

  @override
  String toString() => 'EpubChapter($path, $title)';
}

/// An EPUB, read.
final class EpubBook {
  EpubBook._({
    required Archive archive,
    required this.title,
    required this.authors,
    required this.chapters,
    this.language,
    this.description,
    this.publisher,
    this.cover,
  }) : _archive = archive;

  /// Reads the EPUB in [bytes].
  ///
  /// Throws [EpubProtectedException] for a book locked with DRM, and [EpubFormatException] for
  /// anything that is not an EPUB it can read.
  factory EpubBook.read(List<int> bytes) {
    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes);
    } on FormatException catch (error) {
      throw EpubFormatException('not a zip file: ${error.message}');
    } on RangeError {
      throw const EpubFormatException('not a zip file, or one cut short');
    }
    _refuseDrm(archive);

    final packagePath = _packagePath(archive);
    final package = _xml(archive, packagePath);
    final packageDir = _directoryOf(packagePath);

    final manifest = <String, _Item>{};
    for (final item in package.findAllElements('item', namespaceUri: '*')) {
      final id = item.getAttribute('id');
      final href = item.getAttribute('href');
      if (id == null || href == null) continue;
      manifest[id] = _Item(
        path: _resolve(packageDir, href),
        mediaType: item.getAttribute('media-type') ?? '',
        properties: (item.getAttribute('properties') ?? '')
            .split(' ')
            .where((p) => p.isNotEmpty)
            .toSet(),
      );
    }

    final metadata = package.findAllElements('metadata', namespaceUri: '*');
    String? dc(String name) {
      for (final meta in metadata) {
        for (final element in meta.findElements(name, namespaceUri: '*')) {
          final text = _collapse(element.innerText);
          if (text.isNotEmpty) return text;
        }
      }
      return null;
    }

    final authors = <String>[];
    for (final meta in metadata) {
      for (final creator in meta.findElements('creator', namespaceUri: '*')) {
        // EPUB 2 puts the role on the element, EPUB 3 in a refining meta. A creator with no role is
        // an author, which is what nearly every one is; one marked as something else is not.
        final role = creator.attributes
            .where((a) => a.name.local == 'role')
            .map((a) => a.value)
            .firstOrNull;
        final refined = _refinedRole(meta, creator.getAttribute('id'));
        final effective = role ?? refined;
        if (effective != null && effective != 'aut') continue;
        final name = _collapse(creator.innerText);
        if (name.isNotEmpty && !authors.contains(name)) authors.add(name);
      }
    }

    final spine = package
        .findAllElements('spine', namespaceUri: '*')
        .firstOrNull;
    if (spine == null) {
      throw const EpubFormatException('the package document has no spine');
    }
    final titles = _tableOfContents(archive, manifest, spine);

    final chapters = <EpubChapter>[];
    final seen = <String>{};
    for (final ref in spine.findElements('itemref', namespaceUri: '*')) {
      final item = manifest[ref.getAttribute('idref')];
      // A spine entry the manifest does not list, or lists as something other than a document, has
      // nothing to read. `linear="no"` marks a document read only when linked to, like a footnote
      // page; it is left out of the chapter list for that reason.
      if (item == null || !_isDocument(item.mediaType)) continue;
      if (ref.getAttribute('linear') == 'no') continue;
      if (_fileOf(archive, item.path) == null) continue;
      if (!seen.add(item.path)) continue;
      chapters.add(
        EpubChapter(
          path: item.path,
          title:
              titles[item.path] ??
              _firstHeading(archive, item.path) ??
              'Section ${chapters.length + 1}',
        ),
      );
    }
    if (chapters.isEmpty) {
      throw const EpubFormatException('the book has nothing in it to read');
    }

    return EpubBook._(
      archive: archive,
      title: dc('title') ?? 'Untitled',
      authors: List.unmodifiable(authors),
      language: dc('language'),
      description: dc('description'),
      publisher: dc('publisher'),
      chapters: List.unmodifiable(chapters),
      cover: _cover(archive, package, manifest),
    );
  }

  final Archive _archive;

  final String title;

  /// Credited authors, in the order the book lists them. Contributors credited as anything else,
  /// such as an editor or illustrator, are left out.
  final List<String> authors;

  final String? language;

  /// The book's own description. It may hold markup, as publishers write it.
  final String? description;
  final String? publisher;

  /// In reading order.
  final List<EpubChapter> chapters;

  /// The cover image, or null for a book that names none.
  final EmbeddedPicture? cover;

  /// What the chapter at [path] says, as blocks.
  ///
  /// An image in it is given as a relative [Uri] naming the image's own path in the zip, for
  /// [resource] to read. It never leaves the book, so there is no host to check it against, and an
  /// image the book does not hold is left out, as one on an undeclared host is from a source.
  ///
  /// Throws [ArgumentError] for a path that is not one of [chapters].
  ChapterContent chapterContent(String path) {
    if (!chapters.any((chapter) => chapter.path == path)) {
      throw ArgumentError.value(path, 'path', 'is not a chapter of this book');
    }
    final directory = _directoryOf(path);
    return contentFromHtml(
      _text(_archive, path),
      resolveImage: (src) {
        if (src.startsWith('data:') || Uri.tryParse(src)?.hasScheme == true) {
          return null;
        }
        final target = _resolve(directory, src);
        return _fileOf(_archive, target) == null ? null : Uri(path: target);
      },
    );
  }

  /// The bytes of the file at [path] in the book, such as an image a chapter shows, or null if the
  /// book has no such file.
  Uint8List? resource(String path) => _fileOf(_archive, path)?.readBytes();
}

final class _Item {
  const _Item({
    required this.path,
    required this.mediaType,
    required this.properties,
  });

  final String path;
  final String mediaType;
  final Set<String> properties;
}

/// Refuses a book locked with DRM, naming the lock.
///
/// Each scheme leaves a file of its own in `META-INF`, which is where readers look to know which
/// app can open the book. Anything else encrypted, other than obfuscated fonts, is refused as well,
/// since whatever the scheme, the text is not there to read.
void _refuseDrm(Archive archive) {
  if (_fileOf(archive, 'META-INF/license.lcpl') != null) {
    throw const EpubProtectedException('Readium LCP');
  }
  if (_fileOf(archive, 'META-INF/sinf.xml') != null) {
    throw const EpubProtectedException('Apple FairPlay');
  }
  if (_fileOf(archive, 'META-INF/rights.xml') != null) {
    throw const EpubProtectedException('Adobe DRM');
  }
  if (_fileOf(archive, 'META-INF/encryption.xml') == null) return;
  final XmlDocument encryption;
  try {
    encryption = XmlDocument.parse(_text(archive, 'META-INF/encryption.xml'));
  } on XmlException {
    // An encryption manifest that cannot be read might be hiding anything.
    throw const EpubProtectedException('an unknown lock');
  }
  for (final data in encryption.findAllElements(
    'EncryptedData',
    namespaceUri: '*',
  )) {
    final method = data
        .findElements('EncryptionMethod', namespaceUri: '*')
        .firstOrNull
        ?.getAttribute('Algorithm');
    if (method == null || !_fontObfuscation.contains(method)) {
      throw const EpubProtectedException('an unknown lock');
    }
  }
}

/// Where the package document is, from `META-INF/container.xml`.
String _packagePath(Archive archive) {
  if (_fileOf(archive, 'META-INF/container.xml') == null) {
    throw const EpubFormatException(
      'there is no META-INF/container.xml, so this is not an EPUB',
    );
  }
  final container = _xml(archive, 'META-INF/container.xml');
  for (final rootfile in container.findAllElements(
    'rootfile',
    namespaceUri: '*',
  )) {
    final path = rootfile.getAttribute('full-path');
    final type = rootfile.getAttribute('media-type');
    if (path != null &&
        (type == null || type == 'application/oebps-package+xml')) {
      final normalised = _resolve('', path);
      if (_fileOf(archive, normalised) != null) return normalised;
    }
  }
  throw const EpubFormatException(
    'the container names no package document the book holds',
  );
}

/// Chapter titles by document path, from the table of contents: the EPUB 3 navigation document when
/// there is one, the EPUB 2 NCX otherwise. The first entry pointing into a document names it, since
/// entries further in point at sections within the same chapter.
Map<String, String> _tableOfContents(
  Archive archive,
  Map<String, _Item> manifest,
  XmlElement spine,
) {
  final titles = <String, String>{};
  void name(String directory, String href, String title) {
    final path = _resolve(directory, href.split('#').first);
    final text = _collapse(title);
    if (text.isNotEmpty) titles.putIfAbsent(path, () => text);
  }

  final nav = manifest.values
      .where((item) => item.properties.contains('nav'))
      .firstOrNull;
  if (nav != null && _fileOf(archive, nav.path) != null) {
    final document = html.parse(_text(archive, nav.path));
    final directory = _directoryOf(nav.path);
    final navs = document.getElementsByTagName('nav');
    final toc =
        navs
            .where(
              (n) => n.attributes.entries.any(
                (a) => '${a.key}'.endsWith('type') && a.value == 'toc',
              ),
            )
            .firstOrNull ??
        navs.firstOrNull;
    for (final link in toc?.getElementsByTagName('a') ?? const []) {
      final href = link.attributes['href'];
      if (href != null) name(directory, href, link.text);
    }
    if (titles.isNotEmpty) return titles;
  }

  final ncx =
      manifest[spine.getAttribute('toc')] ??
      manifest.values
          .where((item) => item.mediaType == 'application/x-dtbncx+xml')
          .firstOrNull;
  if (ncx != null && _fileOf(archive, ncx.path) != null) {
    final XmlDocument document;
    try {
      document = XmlDocument.parse(_text(archive, ncx.path));
    } on XmlException {
      return titles;
    }
    final directory = _directoryOf(ncx.path);
    for (final point in document.findAllElements(
      'navPoint',
      namespaceUri: '*',
    )) {
      final label = point
          .findElements('navLabel', namespaceUri: '*')
          .firstOrNull
          ?.findElements('text', namespaceUri: '*')
          .firstOrNull
          ?.innerText;
      final src = point
          .findElements('content', namespaceUri: '*')
          .firstOrNull
          ?.getAttribute('src');
      if (label != null && src != null) name(directory, src, label);
    }
  }
  return titles;
}

/// The text of the first heading in the document at [path], or null if it has none.
String? _firstHeading(Archive archive, String path) {
  final document = html.parse(_text(archive, path));
  for (final tag in const ['h1', 'h2', 'h3']) {
    for (final heading in document.getElementsByTagName(tag)) {
      final text = _collapse(heading.text);
      if (text.isNotEmpty) return text;
    }
  }
  return null;
}

/// The cover image: EPUB 3 marks it with the `cover-image` property, EPUB 2 with a
/// `<meta name="cover">` naming its manifest id.
EmbeddedPicture? _cover(
  Archive archive,
  XmlDocument package,
  Map<String, _Item> manifest,
) {
  final item =
      manifest.values
          .where((item) => item.properties.contains('cover-image'))
          .firstOrNull ??
      manifest[package
          .findAllElements('meta', namespaceUri: '*')
          .where((meta) => meta.getAttribute('name') == 'cover')
          .firstOrNull
          ?.getAttribute('content')];
  if (item == null) return null;
  final bytes = _fileOf(archive, item.path)?.readBytes();
  if (bytes == null || bytes.isEmpty || bytes.length > maxPictureBytes) {
    return null;
  }
  final type = pictureMimeType(bytes, declared: item.mediaType);
  if (type == null || !type.startsWith('image/')) return null;
  return EmbeddedPicture(mimeType: type, bytes: bytes);
}

/// The role an EPUB 3 `<meta refines="#id" property="role">` gives the creator with [id].
String? _refinedRole(XmlElement metadata, String? id) {
  if (id == null) return null;
  for (final meta in metadata.findElements('meta', namespaceUri: '*')) {
    if (meta.getAttribute('refines') == '#$id' &&
        meta.getAttribute('property') == 'role') {
      return _collapse(meta.innerText);
    }
  }
  return null;
}

bool _isDocument(String mediaType) =>
    mediaType == 'application/xhtml+xml' || mediaType == 'text/html';

XmlDocument _xml(Archive archive, String path) {
  try {
    return XmlDocument.parse(_text(archive, path));
  } on XmlException catch (error) {
    throw EpubFormatException('$path cannot be read: ${error.message}');
  }
}

String _text(Archive archive, String path) {
  final bytes = _fileOf(archive, path)?.readBytes();
  if (bytes == null) throw EpubFormatException('$path is missing');
  return utf8.decode(bytes, allowMalformed: true);
}

/// The file at [path], or null for none. Zips from careless tools sometimes store a name with a
/// leading slash or backslashes, so those are tried too.
ArchiveFile? _fileOf(Archive archive, String path) {
  final file =
      archive.findFile(path) ??
      archive.findFile('/$path') ??
      archive.findFile(path.replaceAll('/', r'\'));
  return file != null && file.isFile ? file : null;
}

/// The folder part of a path in the zip, with its trailing slash, or empty at the top.
String _directoryOf(String path) {
  final slash = path.lastIndexOf('/');
  return slash < 0 ? '' : path.substring(0, slash + 1);
}

/// [href], relative to [directory], as a path in the zip: percent escapes decoded, `.` and `..`
/// resolved, and never climbing above the top of the zip.
String _resolve(String directory, String href) {
  final String decoded;
  try {
    decoded = Uri.decodeFull(href);
  } on ArgumentError {
    return href;
  }
  final parts = <String>[];
  final start = decoded.startsWith('/') ? decoded : '$directory$decoded';
  for (final part in start.split('/')) {
    if (part.isEmpty || part == '.') continue;
    if (part == '..') {
      if (parts.isNotEmpty) parts.removeLast();
    } else {
      parts.add(part);
    }
  }
  return parts.join('/');
}

String _collapse(String text) => text.replaceAll(RegExp(r'\s+'), ' ').trim();
