// The repository this project publishes, checked with the code that will read it.
//
// `tool/build_repository.dart` signs the index; the app verifies it. Nothing held those two
// together, and they are the two halves of one format: a change to either that the other does not
// follow would be found by the first listener to open the Repositories screen, and by nobody
// before them. So this reads the committed `repository/` the same way the app reads a fetched one.
//
// It is also the check that a rebuild was actually committed. Rebuilding writes new bytes into
// `repository/packages/` and new hashes into `index.json`; committing one without the other
// publishes an index nobody can install from.

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikuyomi/src/sources/first_run.dart';
import 'package:kikuyomi_extension_manager/kikuyomi_extension_manager.dart';

final _repository = Directory('../repository');

RepositoryInfo readInfo() => RepositoryInfo.parse(
  File('${_repository.path}/repo.json').readAsStringSync(),
);

RepositoryIndex readIndex() => RepositoryIndex.parse(
  File('${_repository.path}/index.json').readAsStringSync(),
);

/// The file an entry's package URL names, inside the committed repository.
File packageFor(RepositoryEntry entry) =>
    File('${_repository.path}/packages/${entry.package.url.split('/').last}');

void main() {
  test('it offers the extensions this app publishes', () {
    // A repository that lost an extension still verifies perfectly, so the count is worth its own
    // assertion: a build run against the wrong folder produces a valid, emptier repository.
    final offered = {for (final entry in readIndex().offered) entry.id};

    expect(offered, {
      'org.kikuyomi.internetarchive',
      'org.kikuyomi.librivox',
      'org.kikuyomi.podcasts',
      'org.kikuyomi.standardebooks',
      'org.kikuyomi.storynory',
    });
  });

  test('every entry is signed by the key it publishes', () async {
    final info = readInfo();

    await expectLater(
      checkIndexSignatures(
        readIndex(),
        publicKey: info.publicKey,
        repositoryName: info.name,
      ),
      completes,
      reason:
          'run tool/build_repository.dart and commit repository/ -- an index '
          'the app refuses is one nobody can install from',
    );
  });

  test('a key that is not its own is refused', () async {
    // Without this the test above would pass against a verifier that said yes to everything.
    await expectLater(
      checkIndexSignatures(
        readIndex(),
        publicKey: base64Encode(List.filled(32, 4)),
        repositoryName: readInfo().name,
      ),
      throwsA(isA<RepositoryException>()),
    );
  });

  test('every package on disk is the one the index names', () {
    for (final entry in readIndex().entries) {
      final file = packageFor(entry);
      expect(file.existsSync(), isTrue, reason: '${file.path} is missing');

      final bytes = file.readAsBytesSync();
      expect(
        sha256.convert(bytes).toString(),
        entry.package.sha256,
        reason:
            '${entry.id}: the package was rebuilt without the index, or the '
            'index without the package',
      );
      expect(entry.package.sizeBytes, bytes.length);
    }
  });

  test('it is published where the app looks for it', () {
    // `officialRepositoryUrl` is what a fresh install pins, and the builder writes the same address
    // into every package URL. Nothing else holds them together, and a repository built for
    // somewhere else would be pinned under this one's name.
    for (final entry in readIndex().entries) {
      expect(
        entry.package.url,
        startsWith(officialRepositoryUrl),
        reason: '${entry.id} is served from somewhere else',
      );
    }
  });

  test('the copy the app ships is the one that is published', () {
    // The app pins the key from its own asset so that it is not written into the code twice. That
    // only works while the asset is the published document -- a rebuild that rotated the key and
    // left the asset behind would pin a key nothing signs with.
    expect(
      File('assets/repository/repo.json').readAsStringSync(),
      File('${_repository.path}/repo.json').readAsStringSync(),
      reason: 'copy repository/repo.json over app/assets/repository/repo.json',
    );
  });

  test('nothing is published revoked', () {
    for (final entry in readIndex().entries) {
      expect(entry.revoked, isFalse, reason: '${entry.id} is withdrawn');
    }
  });
}
