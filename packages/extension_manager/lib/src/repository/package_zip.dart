/// An extension package as a repository serves it: one zip (§3.2).
///
/// ADR-0017's `ExtensionFiles` is two questions — what is this called, and what are the bytes of a
/// file in it — so a zip answers them as readily as a folder does, and everything above the
/// interface is shared between the author's door and the listener's.
///
/// **It is read once, into memory.** An extension is a manifest, a bundled `main.js` and an icon:
/// tens of kilobytes, occasionally hundreds. Holding one while it installs costs nothing worth
/// streaming for, and reading it once means a package whose bytes were tampered with between the
/// hash check and the read is not a thing that can happen.
///
/// **Folders in the archive are flattened away, and only the top level is kept.** §3.3 puts every
/// file directly inside the package, so `main.js` is `main.js`. A zip that wraps its contents in a
/// folder — which is what every archive tool produces when someone zips the folder rather than its
/// contents — is the most likely mistake an author makes, and unwrapping one level is the
/// difference between that working and a message about a missing manifest.
library;

import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';

import '../package.dart';
import 'index.dart';

/// A package the app will not install: one the repository's key did not sign, one whose bytes are
/// not the ones the index named, or one that is not a readable zip.
final class PackageRefused implements Exception {
  const PackageRefused(this.message);

  final String message;

  @override
  String toString() => 'PackageRefused: $message';
}

/// The files of a downloaded package.
final class ZipExtensionFiles implements ExtensionFiles {
  ZipExtensionFiles._(this.description, this._files);

  /// Reads [bytes] as a package called [description].
  ///
  /// Throws [PackageRefused] when the bytes are not a zip that could hold an extension.
  factory ZipExtensionFiles.read(
    Uint8List bytes, {
    required String description,
  }) {
    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes);
    } on Object catch (error) {
      throw PackageRefused('$description is not a readable zip: $error');
    }

    final files = <String, Uint8List>{};
    for (final entry in archive) {
      if (!entry.isFile) continue;
      final name = _plainName(entry.name);
      // A name that climbs out of the package, or that has no name left once its folders are
      // stripped, is not a file this will ever be asked for — and an archive is a place where a
      // path like that is somebody trying something rather than a mistake.
      if (name == null) continue;
      files[name] = entry.content;
    }
    // An archive with nothing usable in it is not a package, and saying so beats letting the caller
    // discover it as a missing manifest. It is also how bytes that are not a zip at all arrive
    // here: the decoder does not throw on them, it simply finds no entries — so a repository
    // serving a web page where a package should be lands exactly here.
    if (files.isEmpty) {
      throw PackageRefused(
        '$description is not a readable zip, or holds nothing',
      );
    }
    return ZipExtensionFiles._(description, files);
  }

  /// Reads [bytes], having first checked they are what [expected] said (§3.8).
  ///
  /// The hash is checked before the archive is opened: a package that is not the one the index named
  /// should not have its contents read at all, whatever they turn out to be.
  factory ZipExtensionFiles.verified(
    Uint8List bytes, {
    required PackageLocation expected,
    required String description,
  }) {
    final got = sha256.convert(bytes).toString();
    if (got != expected.sha256) {
      throw PackageRefused(
        '$description is not the package the repository listed. It should '
        'hash to ${expected.sha256} and hashes to $got.',
      );
    }
    return ZipExtensionFiles.read(bytes, description: description);
  }

  @override
  final String description;

  final Map<String, Uint8List> _files;

  /// Every file in the package, by name. For a test, and for saying what was there instead when
  /// something expected is missing.
  Iterable<String> get names => _files.keys;

  @override
  Future<Uint8List> read(String name) async {
    final bytes = _files[name];
    if (bytes == null) {
      throw ExtensionPackageException(
        description,
        'there is no $name in it${_alsoHere()}',
      );
    }
    return bytes;
  }

  String _alsoHere() {
    if (_files.isEmpty) return ', and nothing else either';
    final listed = _files.keys.take(5).join(', ');
    return _files.length > 5 ? ', only $listed and more' : ', only $listed';
  }
}

/// The name a file goes by inside the package, or null for one that cannot be used.
///
/// Zip entries carry paths. §3.3's package is flat, so what matters is the last segment — except
/// that flattening blindly would let `a/main.js` and `b/main.js` overwrite each other. In practice a
/// package either is flat or has one wrapping folder, and both of those give the same answer.
String? _plainName(String entryName) {
  final segments = [
    // Backslashes as well as slashes, because a zip written on Windows by the wrong tool carries
    // them and the name inside is still a path.
    for (final part in entryName.replaceAll(r'\', '/').split('/'))
      if (part.isNotEmpty && part != '.') part,
  ];
  // `..` anywhere means the archive is trying to name something outside itself.
  if (segments.isEmpty || segments.contains('..')) return null;
  return segments.last;
}
