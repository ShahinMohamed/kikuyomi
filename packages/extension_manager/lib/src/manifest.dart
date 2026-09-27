/// `manifest.json`: what an extension says about itself before any of its code runs (§3.3).
///
/// "The `SourceRegistry` knows every installed source from manifests alone. App launch never
/// executes extension code, which is what keeps hundreds of installed sources cheap." (§3.6) So the
/// manifest is what the app reads to list sources, to show the permissions summary before install —
/// the domains, the content rating — and to decide whether this app can run the extension at all.
///
/// A manifest comes from the same third party the code does, so it is read exactly as strictly as a
/// result is: every field is checked, anything unreadable fails the whole manifest, and unknown
/// fields are ignored so that a later minor version still reads.
///
/// **What is not here.** Signatures, file hashes, repositories and installing (§3.8, §3.9). The
/// `files` map is kept as it was written, for the install step to verify against; nothing here
/// trusts it.
library;

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:kikuyomi_source_api/kikuyomi_source_api.dart';

/// A manifest that could not be read. The message names the field.
final class ManifestException implements Exception {
  const ManifestException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// How grown-up an extension's catalogue is (§3.3). Adult extensions are hidden unless the listener
/// opts in.
enum ExtensionContentRating { everyone, mature, adult }

/// A version of the app or of an extension: whole numbers separated by dots, as §3.3 writes them.
///
/// Not the API version, which is `ApiVersion` in `source_api` and always `MAJOR.MINOR`. This one is
/// what `version` and `minAppVersion` hold, and its only job is to be compared.
final class SoftwareVersion implements Comparable<SoftwareVersion> {
  const SoftwareVersion(this.parts);

  /// Reads `1`, `1.4` or `1.4.0`, and nothing else: no leading zeros, no suffixes, at most four
  /// parts. A version people compare has to mean one thing.
  factory SoftwareVersion.parse(String text) {
    final parts = text.split('.');
    if (parts.isEmpty || parts.length > 4) {
      throw FormatException('a version is one to four numbers: "$text"');
    }
    final numbers = <int>[];
    for (final part in parts) {
      if (part.isEmpty ||
          (part.length > 1 && part.startsWith('0')) ||
          part.codeUnits.any((unit) => unit < 0x30 || unit > 0x39)) {
        throw FormatException('a version is whole numbers: "$text"');
      }
      final number = int.tryParse(part);
      if (number == null) {
        throw FormatException('"$text" is not a version');
      }
      numbers.add(number);
    }
    return SoftwareVersion(List.unmodifiable(numbers));
  }

  final List<int> parts;

  @override
  int compareTo(SoftwareVersion other) {
    for (var i = 0; i < parts.length || i < other.parts.length; i++) {
      final mine = i < parts.length ? parts[i] : 0;
      final theirs = i < other.parts.length ? other.parts[i] : 0;
      if (mine != theirs) return mine.compareTo(theirs);
    }
    return 0;
  }

  bool operator <(SoftwareVersion other) => compareTo(other) < 0;
  bool operator <=(SoftwareVersion other) => compareTo(other) <= 0;
  bool operator >(SoftwareVersion other) => compareTo(other) > 0;
  bool operator >=(SoftwareVersion other) => compareTo(other) >= 0;

  @override
  bool operator ==(Object other) =>
      other is SoftwareVersion && compareTo(other) == 0;

  @override
  int get hashCode => Object.hashAll(parts);

  @override
  String toString() => parts.join('.');
}

/// One source an extension declares.
final class ManifestSource {
  const ManifestSource({
    required this.key,
    required this.name,
    required this.lang,
    required this.versionId,
    this.kind = SourceKind.audio,
  });

  /// The key the extension exports this source under, and the app identifies it by.
  final String key;

  /// What a listener sees in the source list.
  final String name;

  /// The catalogue's language, as a BCP 47 tag, or `multi` for a source that is not one language.
  final String lang;

  /// Bumped by the author only when this source's book and chapter keys stop being compatible
  /// (§3.7), which is what makes the source's id change and triggers a migration.
  final int versionId;

  /// Books to listen to or books to read (1.1, ADR-0019). Absent means audio, which is every
  /// source written against 1.0.
  final SourceKind kind;

  /// The id §3.7 gives this source: the first 8 bytes of SHA-256 over
  /// `{extensionId}/{sourceKey}/{lang}/{versionId}`.
  ///
  /// The extension's id is part of it, unlike Mihon, so that two repositories can never collide by
  /// choosing the same display name.
  int idWithin(String extensionId) {
    final digest = sha256.convert(
      utf8.encode('$extensionId/$key/$lang/$versionId'),
    );
    var id = 0;
    for (final byte in digest.bytes.take(8)) {
      id = (id << 8) | byte;
    }
    return id;
  }

  @override
  String toString() => '$key ($lang)';
}

/// What an extension says about itself.
final class ExtensionManifest {
  const ExtensionManifest({
    required this.id,
    required this.name,
    required this.version,
    required this.versionCode,
    required this.apiVersion,
    required this.minAppVersion,
    required this.author,
    required this.contentRating,
    required this.domains,
    required this.capabilities,
    required this.sources,
    required this.files,
  });

  /// Reads `manifest.json`.
  ///
  /// Throws [ManifestException] naming the first field that cannot be read.
  factory ExtensionManifest.parse(String json) {
    final Object? decoded;
    try {
      decoded = jsonDecode(json);
    } on FormatException catch (error) {
      throw ManifestException('the manifest is not JSON: ${error.message}');
    }
    if (decoded is! Map<String, Object?>) {
      throw const ManifestException('the manifest is an object');
    }
    return ExtensionManifest.fromPlainData(decoded);
  }

  /// Reads a manifest that has already been decoded, such as one from a repository index (§3.3).
  factory ExtensionManifest.fromPlainData(Map<String, Object?> data) {
    final id = _id(data);
    return ExtensionManifest(
      id: id,
      name: _text(data, 'name'),
      version: _version(data, 'version'),
      versionCode: _versionCode(data),
      apiVersion: _apiVersion(data),
      minAppVersion: _version(data, 'minAppVersion'),
      author: _text(data, 'author', required: false),
      contentRating: _contentRating(data),
      domains: _domains(data),
      capabilities: _capabilities(data),
      sources: _sources(data, apiVersion: _apiVersion(data)),
      files: _files(data),
    );
  }

  /// The extension's id, which never changes: `org.example.librivox`.
  final String id;

  /// Its name, as the listener sees it.
  final String name;

  /// Its own version, shown to the listener.
  final SoftwareVersion version;

  /// The number that orders versions. An update is a higher [versionCode], whatever [version] says.
  final int versionCode;

  /// The contract version it was written against (§3.7).
  final ApiVersion apiVersion;

  /// The oldest app that may run it.
  final SoftwareVersion minAppVersion;

  /// Who wrote it, for the permissions screen. Empty when the manifest does not say.
  final String author;

  final ExtensionContentRating contentRating;

  /// Every host it may contact, as the permissions screen lists them and the http bridge enforces
  /// them.
  final DomainAllowlist domains;

  /// The optional things it says it does, such as `latest` and `filters`. Kept as written: a
  /// capability a later minor version adds is not one this app must understand (§3.7).
  final Set<String> capabilities;

  /// Its sources, in the order the manifest lists them.
  final List<ManifestSource> sources;

  /// The SHA-256 of every other file in the package, as `"main.js": "sha256-…"`. Kept for the
  /// install step to verify; nothing here trusts it.
  final Map<String, String> files;

  /// The capabilities of [ContentSource] this extension claims, leaving out any this app does not
  /// know.
  Set<SourceCapability> get declaredCapabilities => {
    if (capabilities.contains('latest')) SourceCapability.latest,
    if (capabilities.contains('filters')) SourceCapability.filters,
    if (capabilities.contains('imageRequest')) SourceCapability.imageRequest,
  };

  /// Whether this app's contract version can run this extension (§3.7).
  ApiCompatibility compatibility([
    SupportedApiVersions supported = supportedApiVersions,
  ]) => supported.check(apiVersion);

  /// Whether this app is new enough for it, which is a separate question from the contract version:
  /// an extension may need a feature of the app rather than of the API.
  bool runsOn(SoftwareVersion appVersion) => appVersion >= minAppVersion;

  @override
  String toString() => '$id $version (API $apiVersion)';

  // ----------------------------------------------------------------------------------- reading

  static String _id(Map<String, Object?> data) {
    final id = _text(data, 'id');
    if (id.length > 128) {
      throw const ManifestException('id: longer than 128 characters');
    }
    if (!_idShape.hasMatch(id)) {
      throw ManifestException(
        'id: "$id" is not an identifier; it reads like a reversed domain name, '
        'as in "org.example.librivox"',
      );
    }
    return id;
  }

  static final _idShape = RegExp(
    r'^[a-z0-9]+([._-][a-z0-9]+)*\.[a-z0-9]+([._-][a-z0-9]+)*$',
  );

  static String _text(
    Map<String, Object?> data,
    String field, {
    bool required = true,
  }) {
    final value = data[field];
    if (value == null && !required) return '';
    if (value is! String) {
      throw ManifestException('$field: ${_describe(value)}, and it is text');
    }
    final text = value.trim();
    if (text.isEmpty && required) {
      throw ManifestException('$field: empty');
    }
    if (text.length > SourceLimits.maxShortTextLength) {
      throw ManifestException(
        '$field: longer than ${SourceLimits.maxShortTextLength} characters',
      );
    }
    for (var i = 0; i < text.length; i++) {
      final unit = text.codeUnitAt(i);
      if (unit < 0x20 || unit == 0x7f) {
        throw ManifestException('$field: holds a control character');
      }
    }
    return text;
  }

  static SoftwareVersion _version(Map<String, Object?> data, String field) {
    final value = data[field];
    if (value is! String) {
      throw ManifestException(
        '$field: ${_describe(value)}, and it is a version',
      );
    }
    try {
      return SoftwareVersion.parse(value.trim());
    } on FormatException catch (error) {
      throw ManifestException('$field: ${error.message}');
    }
  }

  static int _versionCode(Map<String, Object?> data) {
    final value = data['versionCode'];
    if (value is! int || value < 1) {
      throw ManifestException(
        'versionCode: ${_describe(value)}, and it is a whole number of 1 or more',
      );
    }
    return value;
  }

  static ApiVersion _apiVersion(Map<String, Object?> data) {
    final value = data['apiVersion'];
    if (value is! String) {
      throw ManifestException(
        'apiVersion: ${_describe(value)}, and it is "MAJOR.MINOR"',
      );
    }
    try {
      return ApiVersion.parse(value.trim());
    } on FormatException catch (error) {
      throw ManifestException('apiVersion: ${error.message}');
    }
  }

  static ExtensionContentRating _contentRating(Map<String, Object?> data) {
    final value = data['contentRating'];
    return switch (value) {
      null || 'everyone' => ExtensionContentRating.everyone,
      'mature' => ExtensionContentRating.mature,
      // Anything this app does not know is read as the most restrictive value there is, never a
      // laxer one, which is the rule SourceAPI 1.0 applies to a book's own rating.
      _ => ExtensionContentRating.adult,
    };
  }

  static DomainAllowlist _domains(Map<String, Object?> data) {
    final value = data['domains'];
    if (value is! List) {
      throw ManifestException(
        'domains: ${_describe(value)}, and it is a list of domain names',
      );
    }
    if (value.length > 100) {
      throw const ManifestException('domains: more than 100 of them');
    }
    final entries = <String>[];
    for (final entry in value) {
      if (entry is! String) {
        throw ManifestException('domains: ${_describe(entry)} is not a domain');
      }
      entries.add(entry.trim());
    }
    try {
      return DomainAllowlist(entries);
    } on FormatException catch (error) {
      throw ManifestException('domains: ${error.message}');
    }
  }

  static Set<String> _capabilities(Map<String, Object?> data) {
    final value = data['capabilities'];
    if (value == null) return const {};
    if (value is! List) {
      throw ManifestException(
        'capabilities: ${_describe(value)}, and it is a list of names',
      );
    }
    final names = <String>{};
    for (final entry in value) {
      if (entry is! String || entry.trim().isEmpty) {
        throw ManifestException(
          'capabilities: ${_describe(entry)} is not the name of one',
        );
      }
      names.add(entry.trim());
    }
    return Set.unmodifiable(names);
  }

  static List<ManifestSource> _sources(
    Map<String, Object?> data, {
    required ApiVersion apiVersion,
  }) {
    final value = data['sources'];
    if (value is! List || value.isEmpty) {
      throw ManifestException(
        'sources: ${_describe(value)}, and an extension declares at least one',
      );
    }
    if (value.length > 100) {
      throw const ManifestException('sources: more than 100 of them');
    }
    final sources = <ManifestSource>[];
    final keys = <String>{};
    for (var i = 0; i < value.length; i++) {
      final entry = value[i];
      if (entry is! Map<String, Object?>) {
        throw ManifestException('sources[$i]: ${_describe(entry)}');
      }
      final key = _text(entry, 'key');
      if (key.length > SourceLimits.maxKeyLength) {
        throw ManifestException(
          'sources[$i].key: longer than ${SourceLimits.maxKeyLength} characters',
        );
      }
      if (!keys.add(key)) {
        // Two sources under one key would be one source to the extension's own export, and the app
        // would call whichever the extension happened to write last.
        throw ManifestException('sources[$i].key: "$key" is declared twice');
      }
      final lang = _text(entry, 'lang');
      if (!_langShape.hasMatch(lang)) {
        throw ManifestException(
          'sources[$i].lang: "$lang" is not a language tag; use "en", "pt-BR" or "multi"',
        );
      }
      final versionId = entry['versionId'];
      if (versionId is! int || versionId < 1) {
        throw ManifestException(
          'sources[$i].versionId: ${_describe(versionId)}, and it is a whole number of 1 or more',
        );
      }
      sources.add(
        ManifestSource(
          key: key,
          name: _text(entry, 'name'),
          lang: lang,
          versionId: versionId,
          kind: _kind(entry, i, apiVersion),
        ),
      );
    }
    return List.unmodifiable(sources);
  }

  /// A source's kind (1.1), refusing one this manifest's contract version cannot promise.
  ///
  /// `"text"` needs 1.1, and that is a rule rather than a formality. A 1.0 app ignores fields it does
  /// not know, so it would read a text source as audio and call `resolveMedia` on something that
  /// has none. Requiring 1.1 means such a source can never reach that app: the app refuses 1.1 as
  /// needing a newer version before it reads a single source.
  ///
  /// A kind this build does not know is refused too, rather than read as audio. A later minor
  /// version may add one, and an extension written for it should be told it needs a newer app, not
  /// have its source played as something it is not.
  static SourceKind _kind(
    Map<String, Object?> entry,
    int index,
    ApiVersion apiVersion,
  ) {
    final value = entry['kind'];
    if (value == null) return SourceKind.audio;
    final kind = switch (value) {
      'audio' => SourceKind.audio,
      'text' => SourceKind.text,
      _ => throw ManifestException(
        'sources[$index].kind: ${_describe(value)}, and it is "audio" or "text"',
      ),
    };
    if (kind == SourceKind.text && apiVersion < const ApiVersion(1, 1)) {
      throw ManifestException(
        'sources[$index].kind: "text" needs apiVersion "1.1" or later, and this '
        'manifest targets "$apiVersion"',
      );
    }
    return kind;
  }

  /// A BCP 47 tag, or `multi` for a catalogue that is not one language, as Mihon's `all` is.
  static final _langShape = RegExp(
    r'^([A-Za-z]{2,3}(-[A-Za-z0-9]{1,8})*|multi)$',
  );

  static Map<String, String> _files(Map<String, Object?> data) {
    final value = data['files'];
    if (value == null) return const {};
    if (value is! Map) {
      throw ManifestException(
        'files: ${_describe(value)}, and it is an object of file names and hashes',
      );
    }
    final files = <String, String>{};
    for (final entry in value.entries) {
      final name = entry.key;
      final hash = entry.value;
      if (name is! String || name.isEmpty || hash is! String) {
        throw ManifestException('files: ${_describe(name)} is not a file name');
      }
      files[name] = hash;
    }
    return Map.unmodifiable(files);
  }

  static String _describe(Object? value) => switch (value) {
    null => 'missing',
    final String text =>
      '"${text.length > 40 ? '${text.substring(0, 40)}…' : text}"',
    final List<Object?> list => 'a list of ${list.length}',
    final Map<Object?, Object?> map => 'an object of ${map.length}',
    _ => '$value',
  };
}
