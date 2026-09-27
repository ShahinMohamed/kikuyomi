// The Storynory extension, checked without running it.
//
// Like the Internet Archive one it ships through the repository rather than in the app, so this
// reads it from disk. Nothing here runs the JavaScript: `flutter test` does not build the engine's
// native library.

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikuyomi_extension_manager/kikuyomi_extension_manager.dart';
import 'package:kikuyomi_source_api/kikuyomi_source_api.dart';

final _folder = Directory('assets/extensions/storynory');

ExtensionManifest readManifest() => ExtensionManifest.parse(
  File('${_folder.path}/manifest.json').readAsStringSync(),
);

void main() {
  test('its manifest names the code that is actually there', () {
    final manifest = readManifest();
    final code = File('${_folder.path}/main.js').readAsBytesSync();

    expect(
      manifest.files['main.js'],
      'sha256-${base64Encode(sha256.convert(code).bytes)}',
      reason:
          'regenerate the manifest hash from the SHA-256 of '
          'assets/extensions/storynory/main.js',
    );
  });

  test('it targets a contract version this app implements', () {
    final manifest = readManifest();

    expect(manifest.id, 'org.kikuyomi.storynory');
    expect(manifest.apiVersion.toString(), apiVersion);
    expect(manifest.compatibility(), ApiCompatibility.supported);
  });

  test('it declares every host it will make the app contact', () {
    // The three this source really touches, and the reason the libsyn wildcard is there: the feed
    // is on storynory.com, its enclosures point at traffic.libsyn.com, those redirect to
    // delivery-edge.libsyn.com, and the artwork is on static.libsyn.com. The app checks every hop
    // of a redirect, so missing one would fail at the moment a story was played.
    final domains = readManifest().domains;

    for (final url in [
      'https://www.storynory.com/feeds/stories',
      'https://traffic.libsyn.com/secure/blogrelations/a-story.mp3',
      'https://delivery-edge.libsyn.com/shows/1/items/2/a-story.mp3',
      'https://static.libsyn.com/p/assets/artwork.jpg',
    ]) {
      expect(
        domains.problemWith(Uri.parse(url)),
        isNull,
        reason: '$url should be allowed',
      );
    }
    expect(domains.problemWith(Uri.parse('https://example.org/')), isNotNull);
  });

  test('it claims no optional methods, because it has none', () {
    // No filters: one feed has nothing to narrow by that searching its titles does not already do.
    expect(readManifest().declaredCapabilities, isEmpty);
  });

  test('its source is one English source', () {
    final source = readManifest().sources.single;

    expect(source.key, 'storynory');
    expect(source.lang, 'en');
  });

  test('it is published in the repository, at the version it says', () {
    final index = RepositoryIndex.parse(
      File('../repository/index.json').readAsStringSync(),
    );
    final entry = index.entryFor('org.kikuyomi.storynory');

    expect(entry, isNotNull, reason: 'run tool/build_repository.dart');
    expect(entry!.manifest.versionCode, readManifest().versionCode);
    expect(entry.revoked, isFalse);
  });

  test('the probe runs the same code the app publishes', () {
    // The probe is a Flutter package of its own and can only bundle assets inside itself, so its
    // copy of main.js is a copy. This is what stops the two drifting: the probe is the only thing
    // that runs the extension on the real engine, and a stale copy would prove nothing.
    final published = File('${_folder.path}/main.js');
    final probe = File(
      '../spikes/quickjs_binding/qjs_probe/assets/storynory/main.js',
    );

    expect(probe.existsSync(), isTrue, reason: '${probe.path} is missing');
    expect(
      probe.readAsBytesSync(),
      published.readAsBytesSync(),
      reason:
          'copy assets/extensions/storynory/main.js over '
          'spikes/quickjs_binding/qjs_probe/assets/storynory/main.js',
    );
  });
}
