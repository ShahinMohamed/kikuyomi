// The Project Gutenberg extension, checked without running it. The probe runs it on the real
// engine against recorded pages.

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikuyomi_extension_manager/kikuyomi_extension_manager.dart';
import 'package:kikuyomi_source_api/kikuyomi_source_api.dart';

final _folder = Directory('assets/extensions/gutenberg');

ExtensionManifest readManifest() => ExtensionManifest.parse(
  File('${_folder.path}/manifest.json').readAsStringSync(),
);

void main() {
  test('its manifest names the code and icon that are actually there', () {
    final manifest = readManifest();
    for (final name in const ['main.js', 'icon.png']) {
      final bytes = File('${_folder.path}/$name').readAsBytesSync();
      expect(
        manifest.files[name],
        'sha256-${base64Encode(sha256.convert(bytes).bytes)}',
        reason: 'regenerate the manifest hash of $name',
      );
    }
  });

  test('it offers one source of books to read', () {
    final manifest = readManifest();

    expect(manifest.id, 'org.kikuyomi.gutenberg');
    expect(manifest.apiVersion.toString(), '1.1');
    expect(manifest.compatibility(), ApiCompatibility.supported);

    final source = manifest.sources.single;
    expect(source.key, 'gutenberg');
    expect(source.kind, SourceKind.text);
    // Project Gutenberg publishes in seventy-odd languages, so no one of them is its language.
    expect(source.lang, 'multi');
  });

  test('it declares both hosts it reads from, and nothing else', () {
    // Two, and both load-bearing: the catalogue is Gutendex, and the books are Gutenberg's own.
    final domains = readManifest().domains;

    for (final url in [
      'https://gutendex.com/books/?sort=popular&page=1',
      'https://www.gutenberg.org/ebooks/84.html.images',
      'https://www.gutenberg.org/cache/epub/84/pg84.cover.medium.jpg',
    ]) {
      expect(domains.problemWith(Uri.parse(url)), isNull, reason: url);
    }
    expect(domains.problemWith(Uri.parse('https://example.org/')), isNotNull);
  });

  test('it is published in the repository, at the version it says', () {
    final index = RepositoryIndex.parse(
      File('../repository/index.json').readAsStringSync(),
    );
    final entry = index.entryFor('org.kikuyomi.gutenberg');

    expect(entry, isNotNull, reason: 'run tool/build_repository.dart');
    expect(entry!.manifest.versionCode, readManifest().versionCode);
    expect(entry.revoked, isFalse);
  });

  test('the probe runs the same code the app publishes', () {
    final probe = File(
      '../spikes/quickjs_binding/qjs_probe/assets/gutenberg/main.js',
    );

    expect(probe.existsSync(), isTrue, reason: '${probe.path} is missing');
    expect(
      probe.readAsBytesSync(),
      File('${_folder.path}/main.js').readAsBytesSync(),
      reason: "copy main.js over the probe's copy",
    );
  });
}
