/// Checking that a repository vouched for what it offers (§3.8, ADR-0018).
///
/// ADR-0018 settled what a signature covers: the SHA-256 of a package, as the lowercase hex the
/// index lists it in, signed with the repository's Ed25519 key. Signing the hash rather than the
/// whole listing is deliberate. What an extension is allowed to do — the domains it may contact, the
/// contract version it needs, the sources it registers — is read from the manifest inside the
/// package once that package's bytes are known to be the signed ones, never from the listing beside
/// it. The listing is a listing.
///
/// **What a good signature proves.** That the repository holding the key the listener pinned
/// published these exact bytes. It is not a review and not a safety rating: §3.8's trust on first
/// use puts the decision that a repository is worth trusting with the listener, and this only holds
/// the repository to that decision afterwards, so that a repository which is later taken over, or a
/// mirror of it, cannot ship code the real operator never signed.
///
/// **What it does not prove.** An entry is signed on its own, so a repository under someone else's
/// control can re-offer an older version its key genuinely did sign, or drop an entry and claim it
/// was withdrawn. Catching either needs the index itself signed as one document, with a time in it,
/// and that is a change to a published format — a version 2 matter, recorded in ADR-0018 rather than
/// half-built here.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import 'index.dart';

/// Ed25519 is stateless, so one of these serves the whole app.
final _ed25519 = Ed25519();

/// Whether [publicKey] signed the package [entry] lists.
///
/// False rather than throwing for every way this can fail — a signature that is the wrong length, a
/// key that is not a key, a verifier that refuses the input — because at a trust boundary every one
/// of them means the same thing, and a caller that has to tell them apart will eventually get one of
/// them wrong.
Future<bool> repositorySigned(
  RepositoryEntry entry, {
  required String publicKey,
}) async {
  final Uint8List key;
  final Uint8List signature;
  try {
    key = base64Decode(publicKey);
    signature = base64Decode(entry.signature);
  } on FormatException {
    return false;
  }
  // Ed25519's sizes. The index decoder already insists on a 32-byte key; a signature's length is
  // checked here, where it is used, rather than being one more thing the parser knows about crypto.
  if (key.length != 32 || signature.length != 64) return false;

  try {
    return await _ed25519.verify(
      // Exactly the bytes the signing tool put in: the hex digest as text. Not the digest's bytes —
      // the two are different messages, and a verifier that guessed would accept neither.
      utf8.encode(entry.package.sha256),
      signature: Signature(
        signature,
        publicKey: SimplePublicKey(key, type: KeyPairType.ed25519),
      ),
    );
  } on Object {
    return false;
  }
}

/// Checks every entry of [index] against [publicKey], and refuses the lot if one fails.
///
/// One bad signature fails the whole index, the way one unreadable field does. A repository is
/// trusted as a whole — the listener accepted one key, not an extension at a time — so an index
/// carrying something that key did not sign is an index this app has no way to reason about, and
/// picking the good entries out of it would be the app deciding which parts of a tampered document
/// to believe.
///
/// Withdrawn entries are checked too: `revoked` is set beside a signature rather than inside it, so
/// withdrawing a version does not change what was signed, and skipping them would leave a corner of
/// the document nobody looks at.
///
/// Throws [RepositoryException] naming the first entry that fails.
Future<void> checkIndexSignatures(
  RepositoryIndex index, {
  required String publicKey,
  required String repositoryName,
}) async {
  for (final entry in index.entries) {
    if (await repositorySigned(entry, publicKey: publicKey)) continue;
    throw RepositoryException(
      '$repositoryName lists ${entry.manifest.name} ${entry.manifest.version} '
      'with a signature its own key did not make. Nothing from this '
      'repository can be trusted until that is fixed.',
    );
  }
}
