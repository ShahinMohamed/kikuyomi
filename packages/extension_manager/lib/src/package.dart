/// An extension package: its files, wherever they are, and reading one out of them (§3.3).
///
/// §3.3's package is a `manifest.json`, one bundled `main.js`, an icon and a signature. Three places
/// hold one today, and each reads it exactly the same way:
///
/// - the app's own assets, for the extension that ships inside the app (§3.10);
/// - a folder on this device, which is the door this step opens;
/// - the app's own storage, where an installed extension's copy is kept.
///
/// Where the bytes come from is therefore behind [ExtensionFiles], and everything that decides
/// whether a package is readable — the strict manifest read, the `files` hashes, the code — is here
/// and happens once. Signatures and repositories (§3.8) come later.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import 'manifest.dart';

/// The manifest's name inside a package, as §3.3 writes it.
const extensionManifestFileName = 'manifest.json';

/// The bundled code's name inside a package.
const extensionCodeFileName = 'main.js';

/// The icon's name inside a package, as §3.3 lists one among a package's files.
///
/// Optional, and an extension without one is not refused: an author working in a folder has code
/// long before they have artwork, and a list that shows a placeholder beside such an extension is
/// better than one that will not install it.
const extensionIconFileName = 'icon.png';

/// The files of one extension package. What holds them is the caller's business.
abstract interface class ExtensionFiles {
  /// What to call this package in a message meant for a person: a folder's path, or
  /// `assets/extensions/librivox`.
  String get description;

  /// The bytes of [name], a file directly inside the package.
  ///
  /// Throws [ExtensionPackageException] when there is no such file, and may throw anything the
  /// underlying store throws for a read that fails for another reason.
  Future<Uint8List> read(String name);
}

/// A package that is not the extension its manifest says it is, or that is missing a file.
///
/// Distinct from [ManifestException], which means the manifest itself could not be read. This one
/// means the manifest read but the package around it did not match: `main.js` missing, or its bytes
/// not the ones the manifest names.
final class ExtensionPackageException implements Exception {
  const ExtensionPackageException(this.where, this.message);

  /// Which package: an [ExtensionFiles.description].
  final String where;

  final String message;

  @override
  String toString() => 'the extension at $where could not be read: $message';
}

/// One extension package, read and ready to run.
final class ExtensionPackage {
  const ExtensionPackage({
    required this.manifest,
    required this.manifestJson,
    required this.code,
    required this.hashesChecked,
    this.icon,
  });

  final ExtensionManifest manifest;

  /// `manifest.json` as it was written, so that installing keeps the author's own file rather than
  /// this app's reading of it.
  final String manifestJson;

  /// `main.js`, decoded as UTF-8.
  final String code;

  /// The icon's bytes, when the package has one.
  ///
  /// Held rather than decoded: what reads it is a widget, and what writes it is an install. Neither
  /// needs this code to know what a PNG is.
  final Uint8List? icon;

  /// Whether [code] was held to the hash the manifest names.
  ///
  /// False for a folder install, which is why `ExtensionStatus.untrusted` exists: the app says so
  /// rather than pretending to a check it did not make.
  final bool hashesChecked;
}

/// Reads the package [files] hold.
///
/// With [checkHashes], `main.js` is held to the SHA-256 the manifest names, which is what §3.8 calls
/// verifying at install and re-checking at load. Without it, the code is read as it is and
/// [ExtensionPackage.hashesChecked] says so.
///
/// Throws [ManifestException] for a manifest that cannot be read, and [ExtensionPackageException]
/// for a package whose files do not match it.
Future<ExtensionPackage> readExtensionPackage(
  ExtensionFiles files, {
  required bool checkHashes,
}) async {
  final manifestJson = utf8.decode(await files.read(extensionManifestFileName));
  final manifest = ExtensionManifest.parse(manifestJson);
  final bytes = await files.read(extensionCodeFileName);
  if (checkHashes) {
    final declared = manifest.files[extensionCodeFileName];
    if (declared == null) {
      throw ExtensionPackageException(
        files.description,
        'its manifest does not list $extensionCodeFileName',
      );
    }
    final actual = sha256OfExtensionFile(bytes);
    if (declared != actual) {
      throw ExtensionPackageException(
        files.description,
        '$extensionCodeFileName is $actual, and its manifest says $declared',
      );
    }
  }
  return ExtensionPackage(
    manifest: manifest,
    manifestJson: manifestJson,
    code: utf8.decode(bytes),
    hashesChecked: checkHashes,
    icon: await _readIcon(files, manifest, checkHashes: checkHashes),
  );
}

/// The package's icon, or null when it has none.
///
/// A missing icon is not a failure. A *wrong* one is, when the manifest named it and hashes are
/// being checked: at that point the package is claiming to contain a file it does not, which is the
/// same claim about `main.js` that would be refused.
Future<Uint8List?> _readIcon(
  ExtensionFiles files,
  ExtensionManifest manifest, {
  required bool checkHashes,
}) async {
  final declared = manifest.files[extensionIconFileName];
  final Uint8List bytes;
  try {
    bytes = await files.read(extensionIconFileName);
  } on ExtensionPackageException {
    if (checkHashes && declared != null) {
      throw ExtensionPackageException(
        files.description,
        'its manifest lists $extensionIconFileName and the package has none',
      );
    }
    return null;
  }
  if (checkHashes && declared != null) {
    final actual = sha256OfExtensionFile(bytes);
    if (declared != actual) {
      throw ExtensionPackageException(
        files.description,
        '$extensionIconFileName is $actual, and its manifest says $declared',
      );
    }
  }
  return bytes;
}

/// [bytes] as a manifest's `files` map spells a hash: `sha256-` and then base64.
String sha256OfExtensionFile(List<int> bytes) =>
    'sha256-${base64.encode(sha256.convert(bytes).bytes)}';

/// The files of a package in a folder this process can open by path.
///
/// Every platform's own storage is a real path, so this reads an installed extension everywhere. A
/// folder the listener chose is only a path on desktop; on Android it is a Storage Access Framework
/// tree, which the app reads through `UserFolder` instead.
final class DirectoryExtensionFiles implements ExtensionFiles {
  const DirectoryExtensionFiles(this.folder);

  final Directory folder;

  @override
  String get description => folder.path;

  @override
  Future<Uint8List> read(String name) async {
    final file = File('${folder.path}${Platform.pathSeparator}$name');
    if (!await file.exists()) {
      throw ExtensionPackageException(description, 'it has no $name');
    }
    return file.readAsBytes();
  }

  /// Whether [folder] looks like an extension package at all: it has a manifest.
  ///
  /// For listing candidates in a folder the listener can see, where anything at all may have been
  /// copied, so that only folders worth trying are offered.
  static Future<bool> looksLikeOne(Directory folder) =>
      File('${folder.path}${Platform.pathSeparator}$extensionManifestFileName')
          .exists();
}
