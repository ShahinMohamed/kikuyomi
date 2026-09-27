/// SourceAPI versions, and whether this app can run an extension written for one (§3.7).
///
/// An extension's manifest names the API version it targets. Minor versions only add, so an app
/// runs every extension that targets a major version it supports at the same or an older minor. An
/// extension that targets a newer minor, or a newer major, needs a newer app. One that targets an
/// older major the app no longer supports is obsolete.
library;

/// The SourceAPI version this app implements, as `host.apiVersion` reports it to extensions.
///
/// 1.1 adds text sources (ADR-0019): a source may declare `"kind": "text"` and implement
/// `getChapterContent`. Everything 1.0 had is unchanged, so every 1.0 extension still runs.
const apiVersion = '1.1';

/// The versions of SourceAPI this app runs extensions for.
const supportedApiVersions = SupportedApiVersions({1: 1});

/// A SourceAPI version: `MAJOR.MINOR`.
///
/// Ordered by major, then minor.
final class ApiVersion implements Comparable<ApiVersion> {
  const ApiVersion(this.major, this.minor)
    : assert(major >= 0, 'a major version is not negative'),
      assert(minor >= 0, 'a minor version is not negative');

  /// Reads [text], such as `"1.0"`, as SourceAPI 1.0 writes versions: two whole numbers without
  /// leading zeros, joined by a dot, and nothing else.
  ///
  /// Throws [FormatException] for anything else, including `"1"`, `"1.0.0"`, `"01.0"` and
  /// `" 1.0"`. A version that could be read more than one way is refused rather than guessed at.
  factory ApiVersion.parse(String text) =>
      tryParse(text) ??
      (throw FormatException('not a SourceAPI version (MAJOR.MINOR)', text));

  /// [ApiVersion.parse], returning null instead of throwing.
  static ApiVersion? tryParse(String text) {
    final match = _pattern.firstMatch(text);
    if (match == null) return null;
    return ApiVersion(int.parse(match[1]!), int.parse(match[2]!));
  }

  // Nine digits at most, so a version always fits in an int on every platform.
  static final _pattern = RegExp(r'^(0|[1-9][0-9]{0,8})\.(0|[1-9][0-9]{0,8})$');

  final int major;
  final int minor;

  @override
  int compareTo(ApiVersion other) => major != other.major
      ? major.compareTo(other.major)
      : minor.compareTo(other.minor);

  bool operator <(ApiVersion other) => compareTo(other) < 0;
  bool operator <=(ApiVersion other) => compareTo(other) <= 0;
  bool operator >(ApiVersion other) => compareTo(other) > 0;
  bool operator >=(ApiVersion other) => compareTo(other) >= 0;

  @override
  bool operator ==(Object other) =>
      other is ApiVersion && other.major == major && other.minor == minor;

  @override
  int get hashCode => Object.hash(major, minor);

  /// The version as manifests and `host.apiVersion` write it, such as `1.0`.
  @override
  String toString() => '$major.$minor';
}

/// Whether this app can run an extension that targets a given API version.
enum ApiCompatibility {
  /// The app implements that version, or a later minor of the same major.
  supported,

  /// The extension targets a newer minor, or a newer major, than the app implements. Updating the
  /// app runs it.
  needsNewerApp,

  /// The extension targets an older major version the app no longer supports. Only an update of the
  /// extension runs it again.
  obsolete,
}

/// The API versions an app runs extensions for: for each major version it supports, the newest
/// minor it implements.
///
/// A plain range cannot say this. During a deprecation window (§3.7) an app supports two majors,
/// say 1 up to 1.4 and 2 up to 2.1, and an extension targeting 1.7 then needs a newer app even
/// though 1.7 lies between 1.0 and 2.1.
final class SupportedApiVersions {
  /// [newestMinors] maps each supported major version to the newest minor implemented of it. It
  /// must name at least one major version.
  const SupportedApiVersions(this.newestMinors);

  final Map<int, int> newestMinors;

  /// The newest version supported: the one the app implements and reports as `host.apiVersion`.
  ApiVersion get newest {
    final major = newestMinors.keys.reduce((a, b) => a > b ? a : b);
    return ApiVersion(major, newestMinors[major]!);
  }

  /// Whether an extension that targets [target] can run.
  ApiCompatibility check(ApiVersion target) {
    final newestMinor = newestMinors[target.major];
    if (newestMinor != null) {
      return target.minor <= newestMinor
          ? ApiCompatibility.supported
          : ApiCompatibility.needsNewerApp;
    }
    return target.major > newest.major
        ? ApiCompatibility.needsNewerApp
        : ApiCompatibility.obsolete;
  }
}
