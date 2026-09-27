// The Internet Archive extension, checked without running it.
//
// It is not bundled in the app — it ships through the repository, which is what having one is for —
// so this reads it from disk rather than from the asset bundle. Nothing here runs the JavaScript:
// `flutter test` does not build the engine's native library. What is checked is everything before
// the engine, which is what decides whether the extension is offered at all.

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikuyomi_extension_manager/kikuyomi_extension_manager.dart';
import 'package:kikuyomi_source_api/kikuyomi_source_api.dart';

final _folder = Directory('assets/extensions/internetarchive');

ExtensionManifest readManifest() => ExtensionManifest.parse(
  File('${_folder.path}/manifest.json').readAsStringSync(),
);

void main() {
  test('its manifest names the code that is actually there', () {
    // Fails when main.js has been edited and the manifest's hash has not, which is the mistake a
    // package can actually make — and the one the install path refuses a repository package for,
    // since a package is assembled as one piece and its hashes are checked.
    final manifest = readManifest();
    final code = File('${_folder.path}/main.js').readAsBytesSync();

    expect(
      manifest.files['main.js'],
      'sha256-${base64Encode(sha256.convert(code).bytes)}',
      reason:
          'regenerate the manifest hash from the SHA-256 of '
          'assets/extensions/internetarchive/main.js',
    );
  });

  test('it targets a contract version this app implements', () {
    final manifest = readManifest();

    expect(manifest.id, 'org.kikuyomi.internetarchive');
    expect(manifest.apiVersion.toString(), apiVersion);
    expect(manifest.compatibility(), ApiCompatibility.supported);
    expect(manifest.runsOn(SoftwareVersion.parse('1.0.0')), isTrue);
  });

  test('it declares every host it will make the app contact', () {
    // The permissions screen's promise. The Archive answers from archive.org and serves files from
    // numbered subdomains, which is what the wildcard is for.
    final domains = readManifest().domains;

    for (final url in [
      'https://archive.org/advancedsearch.php?q=collection%3Aaudio_bookspoetry',
      'https://archive.org/metadata/some_item',
      'https://archive.org/download/some_item/track.mp3',
      'https://archive.org/services/img/some_item',
      'https://ia800207.us.archive.org/1/items/some_item/track.mp3',
    ]) {
      expect(
        domains.problemWith(Uri.parse(url)),
        isNull,
        reason: '$url should be allowed',
      );
    }
    expect(domains.problemWith(Uri.parse('https://example.org/')), isNotNull);
  });

  test('it declares only the optional methods it really has', () {
    // Filters, for which part of the Archive to look in. No getLatest: the Archive can order by
    // date added, but a newest-first list of a five-million-item audio collection is not a thing
    // anybody wants to browse. No getImageRequest: its thumbnails need no headers.
    expect(readManifest().declaredCapabilities, {SourceCapability.filters});
  });

  test('its source has the id §3.7 gives it', () {
    final manifest = readManifest();
    final source = manifest.sources.single;

    expect(source.key, 'internetarchive');
    expect(source.lang, 'multi');
    // Stable for as long as versionId is: the id is what every book in the library points at, and
    // changing it triggers a migration (§3.7).
    expect(
      source.idWithin(manifest.id),
      isNot(source.idWithin('org.kikuyomi.librivox')),
    );
  });

  test('it is published in the repository, at the version it says', () {
    // The extension and the repository are built from the same folder, so an extension edited
    // without rebuilding the repository would ship the old code to anyone who installs it.
    final index = RepositoryIndex.parse(
      File('../repository/index.json').readAsStringSync(),
    );
    final entry = index.entryFor('org.kikuyomi.internetarchive');
    final manifest = readManifest();

    expect(entry, isNotNull, reason: 'run tool/build_repository.dart');
    expect(entry!.manifest.versionCode, manifest.versionCode);
    expect(entry.package.url, endsWith('.zip'));
    expect(entry.revoked, isFalse);
  });

  test('the probe runs the same code the app publishes', () {
    // The probe is a Flutter package of its own and can only bundle assets inside itself, so its
    // copy of main.js is a copy. This is what stops the two drifting: the probe is the only thing
    // that runs the extension on the real engine, and a stale copy would prove nothing.
    final published = File('${_folder.path}/main.js');
    final probe = File(
      '../spikes/quickjs_binding/qjs_probe/assets/internetarchive/main.js',
    );

    expect(probe.existsSync(), isTrue, reason: '${probe.path} is missing');
    expect(
      probe.readAsBytesSync(),
      published.readAsBytesSync(),
      reason:
          'copy assets/extensions/internetarchive/main.js over '
          'spikes/quickjs_binding/qjs_probe/assets/internetarchive/main.js',
    );
  });
}
