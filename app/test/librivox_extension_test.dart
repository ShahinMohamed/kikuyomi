import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikuyomi/src/sources/extension_packages.dart';
import 'package:kikuyomi_extension_manager/kikuyomi_extension_manager.dart';
import 'package:kikuyomi_source_api/kikuyomi_source_api.dart';

/// The extension that ships inside the app, read from the app's own assets.
///
/// Nothing here runs the JavaScript: `flutter test` does not build the engine's native library, so
/// what the extension does is checked by the probe in `spikes/quickjs_binding` against recorded
/// LibriVox responses. What is checked here is everything before the engine — the manifest, the
/// hash, the domains and the id — which is what decides whether the extension is offered at all.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the LibriVox extension is the one its manifest describes', () async {
    // Fails when main.js has been edited and the manifest's hash has not, which is the mistake a
    // bundled package can actually make. Regenerate with the SHA-256 of app/assets/extensions/
    // librivox/main.js, written as "sha256-<base64>".
    final extension = await loadBundledExtension('librivox');

    expect(extension.manifest.id, 'org.kikuyomi.librivox');
    expect(extension.code, contains('module.exports'));
  });

  test('it targets a contract version this app implements', () async {
    final extension = await loadBundledExtension('librivox');

    // 1.0, not whatever the app implements. An audio source needs nothing 1.1 added, and
    // targeting the oldest version that has what it needs is what lets it run on every app
    // that could play it.
    expect(extension.manifest.apiVersion.toString(), '1.0');
    expect(extension.manifest.compatibility(), ApiCompatibility.supported);
    expect(extension.manifest.runsOn(SoftwareVersion.parse('1.0.0')), isTrue);
  });

  test('it declares every host it will make the app contact', () async {
    // The permissions screen's promise: these are every domain the source can reach, media and
    // covers included. LibriVox's API is on librivox.org and its audio and art on the Internet
    // Archive, which serves downloads from numbered subdomains.
    final domains = (await loadBundledExtension('librivox')).manifest.domains;

    for (final url in [
      'https://librivox.org/api/feed/audiobooks/?format=json',
      'https://www.archive.org/download/moby/moby_001.mp3',
      'https://archive.org/services/img/moby_dick_librivox',
      'https://ia800207.us.archive.org/1/items/moby/moby_001.mp3',
    ]) {
      expect(
        domains.problemWith(Uri.parse(url)),
        isNull,
        reason: '$url should be allowed',
      );
    }
    expect(domains.problemWith(Uri.parse('https://example.org/')), isNotNull);
  });

  test('it declares only the optional methods it really has', () async {
    // It has filters, for what a search looks in. It has no getLatest, because LibriVox's API
    // offers no newest-first order, and no getImageRequest, because the Archive needs no headers.
    final manifest = (await loadBundledExtension('librivox')).manifest;

    expect(manifest.declaredCapabilities, {SourceCapability.filters});
  });

  test('its source has the id §3.7 gives it', () async {
    final manifest = (await loadBundledExtension('librivox')).manifest;
    final source = manifest.sources.single;

    expect(source.key, 'librivox');
    expect(source.lang, 'multi');
    // Stable for as long as versionId is: the id is what every book in the library points at, and
    // changing it triggers a migration (§3.7).
    expect(source.idWithin(manifest.id), source.idWithin(manifest.id));
    expect(
      source.idWithin(manifest.id),
      isNot(source.idWithin('org.example.other')),
    );
  });

  test('the probe runs the same code the app ships', () {
    // The probe is a Flutter package of its own, and a package can only bundle assets inside
    // itself, so its copy of main.js is a copy. This is what stops the two drifting apart: the
    // probe is the only thing that runs the extension on the real engine, and a stale copy would
    // prove nothing about what the app ships.
    final shipped = File('assets/extensions/librivox/main.js');
    final probe = File(
      '../spikes/quickjs_binding/qjs_probe/assets/librivox/main.js',
    );

    expect(probe.existsSync(), isTrue, reason: '${probe.path} is missing');
    expect(
      probe.readAsBytesSync(),
      shipped.readAsBytesSync(),
      reason:
          'copy app/assets/extensions/librivox/main.js over '
          'spikes/quickjs_binding/qjs_probe/assets/librivox/main.js',
    );
  });

  test(
    'an extension whose code does not match its manifest is refused',
    () async {
      await expectLater(
        loadBundledExtension('librivox', bundle: _WrongCodeBundle()),
        throwsA(isA<ExtensionPackageException>()),
      );
    },
  );
}

/// A bundle that serves the real manifest with somebody else's code.
class _WrongCodeBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    if (key.endsWith('main.js')) {
      return ByteData.sublistView(
        Uint8List.fromList('module.exports = {};'.codeUnits),
      );
    }
    return rootBundle.load(key);
  }
}
