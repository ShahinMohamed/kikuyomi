// The Podcasts extension, checked without running it.
//
// Like the Internet Archive and Storynory ones it ships through the repository rather than in the
// app, so this reads it from disk. Nothing here runs the JavaScript: `flutter test` does not build
// the engine's native library. What runs it is the probe, and the last test here is what stops the
// probe's copy drifting from the published one.
//
// The test worth reading is the one about the two host lists. This source is the only one whose
// feeds belong to strangers, so it carries its own copy of the allowlist in order to refuse a feed
// with a sentence naming the host rather than letting the bridge refuse it with a sentence about
// the extension. Two lists that must agree are two lists that will not, so a test holds them
// together.

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikuyomi_extension_manager/kikuyomi_extension_manager.dart';
import 'package:kikuyomi_source_api/kikuyomi_source_api.dart';

final _folder = Directory('assets/extensions/podcasts');

ExtensionManifest readManifest() => ExtensionManifest.parse(
  File('${_folder.path}/manifest.json').readAsStringSync(),
);

/// The domains the JavaScript's own `HOSTS` array names, in the order it names them.
List<String> hostsInCode() {
  final code = File('${_folder.path}/main.js').readAsStringSync();
  final block = RegExp(
    r'var HOSTS = \[(.*?)\];',
    dotAll: true,
  ).firstMatch(code);
  expect(block, isNotNull, reason: 'main.js no longer has a HOSTS array');
  return [
    for (final match in RegExp("'([^']+)'").allMatches(block!.group(1)!))
      match.group(1)!,
  ];
}

void main() {
  test('its manifest names the code that is actually there', () {
    final manifest = readManifest();
    final code = File('${_folder.path}/main.js').readAsBytesSync();

    expect(
      manifest.files['main.js'],
      'sha256-${base64Encode(sha256.convert(code).bytes)}',
      reason:
          'regenerate the manifest hash from the SHA-256 of '
          'assets/extensions/podcasts/main.js',
    );
  });

  test('it targets a contract version this app implements', () {
    final manifest = readManifest();

    expect(manifest.id, 'org.kikuyomi.podcasts');
    // 1.0, not whatever the app implements. An audio source needs nothing 1.1 added, and
    // targeting the oldest version that has what it needs is what lets it run on every app
    // that could play it.
    expect(manifest.apiVersion.toString(), '1.0');
    expect(manifest.compatibility(), ApiCompatibility.supported);
  });

  test('the code and the manifest name the same hosts', () {
    // Not "the same set": the same list, in the same order. Keeping the order means a diff of one
    // file reads against a diff of the other, and there is nowhere for a quiet divergence to hide.
    expect(
      hostsInCode(),
      readManifest().domains.domains,
      reason:
          'HOSTS in main.js and "domains" in manifest.json have to be the '
          'same list, because main.js uses its copy to refuse a feed before '
          'the host bridge does',
    );
  });

  test('it can reach the hosts a podcast is actually served from', () {
    // Every one of these is a hop something real needs. The feed is on a host, the audio is
    // usually on another, and a measurement service often sits between them as a redirect the
    // publisher put there. The app checks every hop, so a missing one fails at the moment an
    // episode is played rather than when it is added.
    final domains = readManifest().domains;

    for (final url in [
      // The feed, and the CloudFront address Anchor actually serves its audio from.
      'https://anchor.fm/s/100622f90/podcast/rss',
      'https://d3ctxlq1ktw2nl.cloudfront.net/staging/2025-0-25/an-episode.mp3',
      // Apple's index, which is how a show is found by name or by link, and its artwork.
      'https://itunes.apple.com/search?media=podcast&term=audiobook',
      'https://is1-ssl.mzstatic.com/image/thumb/artwork.jpg/600x600bb.jpg',
      // A Spotify show page, read for the show's name and nothing else.
      'https://open.spotify.com/show/7sRS4Y7wK8gS4Emp7qXskL',
      // The other large hosts.
      'https://rss.libsyn.com/a-show',
      'https://feeds.megaphone.fm/a-show',
      'https://www.spreaker.com/show/a-show/episodes/feed',
      'https://rss.buzzsprout.com/1/feed.xml',
      // The measurement prefixes publishers redirect their audio through.
      'https://dts.podtrac.com/redirect.mp3/pdst.fm/e/an-episode.mp3',
      'https://pdst.fm/e/chrt.fm/track/AAAA/an-episode.mp3',
      'https://pscrb.fm/rss/p/an-episode.mp3',
    ]) {
      expect(
        domains.problemWith(Uri.parse(url)),
        isNull,
        reason: '$url should be allowed',
      );
    }

    // And the point of having a list at all: somewhere else is refused.
    expect(
      domains.problemWith(Uri.parse('https://example.org/feed.xml')),
      isNotNull,
    );
  });

  test('it claims no optional methods, because it has none', () {
    // No filters: what a listener narrows here is which show, and that is what search does. No
    // latest: a shelf of the shows you opened has no "newest" that means anything.
    expect(readManifest().declaredCapabilities, isEmpty);
  });

  test('its one source is not tied to a language', () {
    // `multi`, and honestly so: the feed belongs to whoever wrote it, and this source has no idea
    // what language the next one will be in.
    final source = readManifest().sources.single;

    expect(source.key, 'podcasts');
    expect(source.lang, 'multi');
  });

  test('it is published in the repository, at the version it says', () {
    final index = RepositoryIndex.parse(
      File('../repository/index.json').readAsStringSync(),
    );
    final entry = index.entryFor('org.kikuyomi.podcasts');

    expect(entry, isNotNull, reason: 'run tool/build_repository.dart');
    expect(entry!.manifest.versionCode, readManifest().versionCode);
    expect(entry.revoked, isFalse);
  });

  test('the probe runs the same code the app publishes', () {
    final published = File('${_folder.path}/main.js');
    final probe = File(
      '../spikes/quickjs_binding/qjs_probe/assets/podcasts/main.js',
    );

    expect(probe.existsSync(), isTrue, reason: '${probe.path} is missing');
    expect(
      probe.readAsBytesSync(),
      published.readAsBytesSync(),
      reason:
          'copy assets/extensions/podcasts/main.js over '
          'spikes/quickjs_binding/qjs_probe/assets/podcasts/main.js',
    );
  });
}
