// The trust boundary itself: does `repositorySigned` say yes only when the repository's own key
// signed exactly the package the entry names (§3.8, ADR-0018).
//
// `repository_fetch_test.dart` proves the fetcher and the install path ask this question in the
// right places. This file proves the answer, and it is worth its own file because a verifier that
// says yes too readily fails silently: nothing throws, nothing looks wrong, and every check above it
// becomes decoration. So the cases here are mostly the ways of being almost right — a good signature
// over a different hash, the right bytes by the wrong key, a key of the wrong length — rather than
// the obvious garbage.

import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:kikuyomi_extension_manager/kikuyomi_extension_manager.dart';
import 'package:test/test.dart';

const _hash =
    'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855';
const _otherHash =
    '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';

final _manifest = ExtensionManifest.fromPlainData(const {
  'id': 'org.example.librivox',
  'name': 'LibriVox',
  'version': '1.4.0',
  'versionCode': 14,
  'apiVersion': '1.0',
  'minAppVersion': '1.0.0',
  'contentRating': 'everyone',
  'domains': ['librivox.org'],
  'sources': [
    {'key': 'librivox', 'name': 'LibriVox', 'lang': 'en', 'versionId': 1},
  ],
});

RepositoryEntry entryWith({required String signature, String hash = _hash}) =>
    RepositoryEntry(
      manifest: _manifest,
      package: PackageLocation(url: 'https://example.org/a.zip', sha256: hash),
      signature: signature,
    );

void main() {
  late SimpleKeyPair theirs;
  late SimpleKeyPair somebodyElses;
  late String theirKey;

  Future<String> signedBy(SimpleKeyPair key, String hash) async => base64Encode(
    (await Ed25519().sign(utf8.encode(hash), keyPair: key)).bytes,
  );

  setUpAll(() async {
    theirs = await Ed25519().newKeyPairFromSeed(List.filled(32, 1));
    somebodyElses = await Ed25519().newKeyPairFromSeed(List.filled(32, 2));
    theirKey = base64Encode((await theirs.extractPublicKey()).bytes);
  });

  test('says yes to what the repository actually signed', () async {
    final entry = entryWith(signature: await signedBy(theirs, _hash));

    expect(await repositorySigned(entry, publicKey: theirKey), isTrue);
  });

  test('says no when another key made the signature', () async {
    // The whole point. Somebody standing between the listener and the repository has a perfectly
    // good key of their own; what they do not have is the one that was pinned.
    final entry = entryWith(signature: await signedBy(somebodyElses, _hash));

    expect(await repositorySigned(entry, publicKey: theirKey), isFalse);
  });

  test('says no when the signature is over a different hash', () async {
    // A real signature by the real key, lifted from another entry and pasted beside these bytes.
    final entry = entryWith(
      signature: await signedBy(theirs, _otherHash),
      hash: _hash,
    );

    expect(await repositorySigned(entry, publicKey: theirKey), isFalse);
  });

  test('says no to a signature of the wrong length', () async {
    final good = await signedBy(theirs, _hash);
    final truncated = base64Encode(base64Decode(good).sublist(0, 32));

    expect(
      await repositorySigned(
        entryWith(signature: truncated),
        publicKey: theirKey,
      ),
      isFalse,
    );
  });

  test('says no rather than throwing when nothing decodes', () async {
    // Every one of these reaches a trust boundary meaning the same thing, so none of them is an
    // exception a caller has to remember to catch.
    final good = await signedBy(theirs, _hash);

    expect(
      await repositorySigned(
        entryWith(signature: 'not base64!'),
        publicKey: theirKey,
      ),
      isFalse,
      reason: 'a signature that is not base64',
    );
    expect(
      await repositorySigned(
        entryWith(signature: good),
        publicKey: 'not base64!',
      ),
      isFalse,
      reason: 'a key that is not base64',
    );
    expect(
      await repositorySigned(
        entryWith(signature: good),
        publicKey: base64Encode(List.filled(16, 0)),
      ),
      isFalse,
      reason: 'a key that is not 32 bytes',
    );
    expect(
      await repositorySigned(entryWith(signature: ''), publicKey: theirKey),
      isFalse,
      reason: 'no signature at all',
    );
  });

  group('checking a whole index', () {
    test('passes one where every entry checks out', () async {
      final index = RepositoryIndex(
        entries: [entryWith(signature: await signedBy(theirs, _hash))],
      );

      await expectLater(
        checkIndexSignatures(
          index,
          publicKey: theirKey,
          repositoryName: 'Kikuyomi official',
        ),
        completes,
      );
    });

    test('names the repository and the entry that failed', () async {
      // The listener is being told to distrust something they chose to trust, so the sentence has
      // to say which repository and which extension rather than that a check failed.
      final index = RepositoryIndex(
        entries: [
          entryWith(signature: await signedBy(theirs, _hash)),
          entryWith(signature: await signedBy(somebodyElses, _hash)),
        ],
      );

      await expectLater(
        checkIndexSignatures(
          index,
          publicKey: theirKey,
          repositoryName: 'Kikuyomi official',
        ),
        throwsA(
          isA<RepositoryException>().having(
            (e) => e.message,
            'message',
            allOf(contains('Kikuyomi official'), contains('LibriVox')),
          ),
        ),
      );
    });
  });
}
