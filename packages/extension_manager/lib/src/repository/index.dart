/// What a repository publishes about itself and what it offers (§3.2, §3.8, §3.9; ADR-0018).
///
/// A repository is an HTTPS location serving a `repo.json` — its name, its website and its signing
/// key — an `index.json` listing what it offers, and the packages and icons those entries point at.
///
/// **The point of the index is that browsing runs no code.** §3.9: it "repeats the essential
/// metadata so that the app can present and filter available extensions without downloading any
/// code". So an entry carries everything the permissions summary and the filters need — the domains
/// it will contact, its content rating, its sources, the contract version it needs — and the app
/// fetches one JSON file to show a whole repository.
///
/// **It is read as strictly as an extension's own output.** A repository is the same third party
/// the code is, over the same network. Every field is checked, anything unreadable fails the whole
/// document rather than half of it, and unknown fields are ignored so a later minor version still
/// reads. An entry's manifest fields go through the manifest's own decoder, so a field the two share
/// cannot drift apart.
///
/// **Signatures are read here and checked in `signature.dart`.** This file decodes them and says
/// nothing about whether they are good: an index carrying a signature the repository's key did not
/// make is a readable document that happens to be untrustworthy, and the two are worth keeping
/// apart. `RepositoryFetcher` does both, in that order, so nothing above it ever holds a listing
/// that has not been verified (§3.8, ADR-0018).
library;

import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../manifest.dart';

/// A repository document that could not be read. The message names the field.
final class RepositoryException implements Exception {
  const RepositoryException(this.message);

  final String message;

  @override
  String toString() => 'RepositoryException: $message';
}

/// The format version this build writes and reads.
///
/// Its own number rather than the contract's: a repository's shape and the extension contract change
/// for different reasons and at different times, and tying them would make a new `SourceAPI` minor
/// version invalidate every published index.
const repositoryFormatVersion = 1;

/// `repo.json`: who a repository is, and the key it signs with.
final class RepositoryInfo {
  const RepositoryInfo({
    required this.name,
    required this.publicKey,
    this.website,
  });

  /// Reads a `repo.json`.
  ///
  /// Throws [RepositoryException] naming the first field that cannot be read.
  factory RepositoryInfo.parse(String json) {
    final data = _object(json, 'repo.json');
    _checkFormatVersion(data, 'repo.json');
    return RepositoryInfo(
      name: _text(data, 'name'),
      website: _optionalText(data, 'website'),
      publicKey: _publicKey(data),
    );
  }

  /// What the repository calls itself, as the listener sees it in their list.
  final String name;

  /// Where to read about it, when it says. Not where its files are: that is the URL the listener
  /// added, and a repository does not get to redirect itself somewhere else.
  final String? website;

  /// Its Ed25519 signing key, as the base64 the document carried.
  ///
  /// Kept as written rather than decoded, because what is pinned and compared later has to be
  /// exactly what was published. What verifies with it is `repositorySigned`.
  final String publicKey;

  /// The key as §3.8's fingerprint: what the app shows when a repository is added, and what a
  /// listener compares against what its operator published.
  ///
  /// The SHA-256 of the key's bytes, in the colon-separated hex every other tool shows a fingerprint
  /// in. The whole digest, not a prefix: a fingerprint is only worth showing if matching it means
  /// something, and a short one can be forged into.
  String get fingerprint {
    final digest = sha256.convert(base64Decode(publicKey));
    return [
      for (final byte in digest.bytes)
        byte.toRadixString(16).padLeft(2, '0').toUpperCase(),
    ].join(':');
  }

  @override
  String toString() => 'RepositoryInfo($name)';
}

/// Where a package is, and what it must hash to.
final class PackageLocation {
  const PackageLocation({
    required this.url,
    required this.sha256,
    this.sizeBytes,
  });

  /// Over HTTPS, always. A plain-HTTP package is a downgrade on a document fetched over HTTPS, and
  /// there is no reason to take one.
  final String url;

  /// The SHA-256 of the package, lowercase hex.
  ///
  /// Verified at install whatever else is true, because it is what catches a truncated or corrupted
  /// download. On its own it proves the bytes are the bytes the index named and nothing about who
  /// wrote the index; it is the entry's signature over this hash that carries that (ADR-0018).
  final String sha256;

  /// How big it is, when the index says, so a download can be sized before it starts.
  final int? sizeBytes;

  @override
  String toString() => 'PackageLocation($url)';
}

/// One extension, as a repository offers it.
final class RepositoryEntry {
  const RepositoryEntry({
    required this.manifest,
    required this.package,
    required this.signature,
    this.iconUrl,
    this.revoked = false,
  });

  /// Everything the extension says about itself, decoded by the manifest's own decoder.
  ///
  /// An index entry has no `files`: those hashes describe a package's contents and are checked when
  /// the package is unpacked, not from a listing. The manifest decoder already treats them as
  /// optional, which is what lets one decoder serve both.
  final ExtensionManifest manifest;

  final PackageLocation package;

  /// The repository's Ed25519 signature over [PackageLocation.sha256], as the base64 the index
  /// carried. Checked against the repository's key by `repositorySigned` (ADR-0018).
  final String signature;

  /// An icon to show beside it, when the index says.
  final String? iconUrl;

  /// §3.8: an index may mark a version revoked, which disables it at the next refresh. A revoked
  /// entry is still read and still listed, because "this version was withdrawn" is something the
  /// listener needs told rather than something to hide.
  final bool revoked;

  String get id => manifest.id;

  @override
  String toString() => 'RepositoryEntry(${manifest.id} ${manifest.version})';
}

/// `index.json`: everything a repository offers.
final class RepositoryIndex {
  const RepositoryIndex({required this.entries});

  /// Reads an `index.json`.
  ///
  /// Throws [RepositoryException] naming the first entry and field that cannot be read. One bad
  /// entry fails the whole index rather than being skipped: a listing that quietly dropped an
  /// extension would look like a repository that no longer offers it.
  factory RepositoryIndex.parse(String json) {
    final data = _object(json, 'index.json');
    _checkFormatVersion(data, 'index.json');
    final listed = data['extensions'];
    if (listed is! List) {
      throw RepositoryException(
        'extensions: ${_describe(listed)}, and it is a list',
      );
    }

    final entries = <RepositoryEntry>[];
    final seen = <String>{};
    for (var i = 0; i < listed.length; i++) {
      final entry = _entry(listed[i], i);
      // Two entries for one id leave the app to guess which version a repository is offering, and a
      // guess is exactly what a trust boundary must not do.
      if (!seen.add(entry.id)) {
        throw RepositoryException(
          'extensions[$i]: ${entry.id} is listed more than once',
        );
      }
      entries.add(entry);
    }
    return RepositoryIndex(entries: entries);
  }

  /// What it offers, in the order it listed them.
  final List<RepositoryEntry> entries;

  /// The entries a listener may install: everything not withdrawn.
  List<RepositoryEntry> get offered => [
    for (final entry in entries)
      if (!entry.revoked) entry,
  ];

  /// The entry for [id], or null when this repository does not offer it.
  RepositoryEntry? entryFor(String id) {
    for (final entry in entries) {
      if (entry.id == id) return entry;
    }
    return null;
  }

  @override
  String toString() => 'RepositoryIndex(${entries.length} extensions)';
}

RepositoryEntry _entry(Object? value, int index) {
  if (value is! Map<String, Object?>) {
    throw RepositoryException(
      'extensions[$index]: ${_describe(value)}, and it is an object',
    );
  }
  final ExtensionManifest manifest;
  try {
    manifest = ExtensionManifest.fromPlainData(value);
  } on ManifestException catch (error) {
    throw RepositoryException('extensions[$index]: ${error.message}');
  }
  return RepositoryEntry(
    manifest: manifest,
    package: _package(value, index),
    signature: _base64(value, 'signature', 'extensions[$index]'),
    iconUrl: _optionalUrl(value, 'iconUrl', 'extensions[$index]'),
    revoked: _flag(value, 'revoked', 'extensions[$index]'),
  );
}

PackageLocation _package(Map<String, Object?> data, int index) {
  final where = 'extensions[$index].package';
  final value = data['package'];
  if (value is! Map<String, Object?>) {
    throw RepositoryException(
      '$where: ${_describe(value)}, and it is an object',
    );
  }
  return PackageLocation(
    url: _httpsUrl(value, 'url', where),
    sha256: _hash(value, where),
    sizeBytes: _optionalSize(value, where),
  );
}

Map<String, Object?> _object(String json, String what) {
  final Object? decoded;
  try {
    decoded = jsonDecode(json);
  } on FormatException catch (error) {
    throw RepositoryException('$what is not JSON: ${error.message}');
  }
  if (decoded is! Map<String, Object?>) {
    throw RepositoryException('$what is an object');
  }
  return decoded;
}

/// Refuses a document this build is too old to read.
///
/// A missing version reads as version 1, so the first indexes published without the field still
/// work. A higher one is refused outright rather than read hopefully: the whole reason for a version
/// is that a newer format may mean something different by a field of the same name.
void _checkFormatVersion(Map<String, Object?> data, String what) {
  final value = data['formatVersion'];
  if (value == null) return;
  if (value is! int) {
    throw RepositoryException(
      '$what formatVersion: ${_describe(value)}, and it is a whole number',
    );
  }
  if (value > repositoryFormatVersion) {
    throw RepositoryException(
      '$what is version $value, and this app reads version '
      '$repositoryFormatVersion. Update Kikuyomi to use this repository.',
    );
  }
}

String _text(Map<String, Object?> data, String field) {
  final value = data[field];
  if (value is! String || value.trim().isEmpty) {
    throw RepositoryException('$field: ${_describe(value)}, and it is a name');
  }
  return value.trim();
}

String? _optionalText(Map<String, Object?> data, String field) {
  final value = data[field];
  if (value == null) return null;
  if (value is! String || value.trim().isEmpty) {
    throw RepositoryException('$field: ${_describe(value)}, and it is text');
  }
  return value.trim();
}

String _publicKey(Map<String, Object?> data) {
  final key = _base64(data, 'publicKey', 'repo.json');
  // Ed25519 public keys are 32 bytes. Anything else is not one, and finding that out now is better
  // than finding it out when the first signature fails to verify.
  if (base64Decode(key).length != 32) {
    throw const RepositoryException(
      'publicKey: not an Ed25519 key, which is 32 bytes',
    );
  }
  return key;
}

String _base64(Map<String, Object?> data, String field, String where) {
  final value = data[field];
  if (value is! String || value.trim().isEmpty) {
    throw RepositoryException(
      '$where $field: ${_describe(value)}, and it is base64',
    );
  }
  try {
    base64Decode(value.trim());
  } on FormatException {
    throw RepositoryException('$where $field: not base64');
  }
  return value.trim();
}

String _httpsUrl(Map<String, Object?> data, String field, String where) {
  final value = data[field];
  if (value is! String) {
    throw RepositoryException(
      '$where $field: ${_describe(value)}, and it is a URL',
    );
  }
  final url = Uri.tryParse(value.trim());
  if (url == null || !url.isAbsolute || url.host.isEmpty) {
    throw RepositoryException('$where $field: "$value" is not a URL');
  }
  if (url.scheme != 'https') {
    throw RepositoryException(
      '$where $field: ${url.scheme} is not https, and a package is fetched over https',
    );
  }
  return url.toString();
}

String? _optionalUrl(Map<String, Object?> data, String field, String where) {
  if (data[field] == null) return null;
  return _httpsUrl(data, field, where);
}

String _hash(Map<String, Object?> data, String where) {
  final value = data['sha256'];
  if (value is! String) {
    throw RepositoryException(
      '$where sha256: ${_describe(value)}, and it is a hash',
    );
  }
  final hash = value.trim().toLowerCase();
  // 64 hex characters, and nothing else. A hash that is nearly right is a hash that will fail at
  // install with a far worse message than this one.
  if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(hash)) {
    throw RepositoryException(
      '$where sha256: "$value" is not a SHA-256, which is 64 hex characters',
    );
  }
  return hash;
}

int? _optionalSize(Map<String, Object?> data, String where) {
  final value = data['size'];
  if (value == null) return null;
  if (value is! int || value <= 0) {
    throw RepositoryException(
      '$where size: ${_describe(value)}, and it is a count of bytes',
    );
  }
  return value;
}

bool _flag(Map<String, Object?> data, String field, String where) {
  final value = data[field];
  if (value == null) return false;
  if (value is! bool) {
    throw RepositoryException(
      '$where $field: ${_describe(value)}, and it is true or false',
    );
  }
  return value;
}

/// What was there instead, for a message that says what is wrong rather than that something is.
String _describe(Object? value) => switch (value) {
  null => 'missing',
  String() => 'the text "$value"',
  num() => '$value',
  bool() => '$value',
  List() => 'a list',
  Map() => 'an object',
  _ => 'not readable',
};
