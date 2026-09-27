// The Standard Ebooks extension, checked without running it: the first source of books to read
// (ADR-0019). The probe runs it on the real engine against recorded pages.

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikuyomi_extension_manager/kikuyomi_extension_manager.dart';
import 'package:kikuyomi_source_api/kikuyomi_source_api.dart';

final _folder = Directory('assets/extensions/standardebooks');

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

  test('it targets 1.1, the first version with text sources', () {
    final manifest = readManifest();

    expect(manifest.id, 'org.kikuyomi.standardebooks');
    expect(manifest.apiVersion.toString(), '1.1');
    expect(manifest.compatibility(), ApiCompatibility.supported);
  });

  test('its one source is a source of books to read, in English', () {
    final source = readManifest().sources.single;

    expect(source.key, 'standardebooks');
    expect(source.kind, SourceKind.text);
    expect(source.lang, 'en');
  });

  test('it declares the one host it contacts, and nothing else', () {
    final domains = readManifest().domains;

    for (final url in [
      'https://standardebooks.org/ebooks?page=1',
      'https://standardebooks.org/images/covers/a_b/1/cover.jpg',
    ]) {
      expect(domains.problemWith(Uri.parse(url)), isNull, reason: url);
    }
    expect(domains.problemWith(Uri.parse('https://example.org/')), isNotNull);
  });

  test('it is published in the repository, at the version it says', () {
    final index = RepositoryIndex.parse(
      File('../repository/index.json').readAsStringSync(),
    );
    final entry = index.entryFor('org.kikuyomi.standardebooks');

    expect(entry, isNotNull, reason: 'run tool/build_repository.dart');
    expect(entry!.manifest.versionCode, readManifest().versionCode);
    expect(entry.revoked, isFalse);
  });

  test('the probe runs the same code the app publishes', () {
    final probe = File(
      '../spikes/quickjs_binding/qjs_probe/assets/standardebooks/main.js',
    );

    expect(probe.existsSync(), isTrue, reason: '${probe.path} is missing');
    expect(
      probe.readAsBytesSync(),
      File('${_folder.path}/main.js').readAsBytesSync(),
      reason: 'copy main.js over the probe\'s copy',
    );
  });
}
