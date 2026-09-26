/// Where the app finds extension packages: its own assets, and folders on this device (§3.3).
///
/// One reader serves all of them (`readExtensionPackage`); these are only the places the bytes come
/// from. A package read here is a [LoadedExtension], which is everything the app needs to run the
/// extension and everything it needs to say where the extension came from.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:kikuyomi_domain/kikuyomi_domain.dart';
import 'package:kikuyomi_extension_manager/kikuyomi_extension_manager.dart';

/// The extensions that ship inside the app (§3.10).
///
/// "An official repository hosts JavaScript extensions. It proves the whole extension pipeline end
/// to end, serves as the reference implementation extension authors copy from, and gives new users
/// something to listen to on first launch."
///
/// The repository and installing from it (§3.8) come later. Until then the same extension ships as an
/// asset, in exactly the package format §3.3 describes, so it is read by the same reader an installed
/// one is and its manifest is read as strictly as a downloaded one would be.
///
/// Each name is a folder under `assets/extensions/`. Adding one means listing it here and in
/// `pubspec.yaml`'s assets.
// Only LibriVox. `assets/extensions/` holds the extensions this project publishes, and the app
// bundles the one that makes it useful before the listener has added a repository; the rest ship
// through the repository, which is what having one is for. An extension bundled in the app cannot be
// updated without shipping a new app.
const bundledExtensionNames = ['librivox'];

/// An extension the app has read and can run.
///
/// The package is the extension; the rest is what the app knows about it — where it came from, and
/// whether anything proved its code is what its author published. The Extensions screen shows those,
/// and `SourceRegistry` decides from [status] whether to start a runtime at all.
final class LoadedExtension {
  const LoadedExtension({
    required this.package,
    required this.origin,
    required this.status,
    this.originHandle,
    this.originName,
    this.installPath,
    this.installedAt,
  });

  final ExtensionPackage package;

  /// Where it came from, which is also how it is read again.
  final ExtensionOrigin origin;

  /// Whether it may run, and if not why (§3.8).
  final ExtensionStatus status;

  /// How to reach its origin again: a folder's handle, as `UserFolders.open` takes one. Null for the
  /// extension that ships inside the app.
  final String? originHandle;

  /// What to call that origin to the listener.
  final String? originName;

  /// Where the app's copy of the files is, relative to the installed-extensions folder. Null for a
  /// bundled extension, whose files are assets.
  final String? installPath;

  /// When it was installed, for a listener who wants to know which copy is the newer.
  final DateTime? installedAt;

  ExtensionManifest get manifest => package.manifest;
  String get id => package.manifest.id;
  String get code => package.code;
}

/// The files of a package in the app's own asset bundle.
final class AssetExtensionFiles implements ExtensionFiles {
  AssetExtensionFiles(this.name, {AssetBundle? bundle})
    : _bundle = bundle ?? rootBundle;

  /// The folder's name under `assets/extensions/`.
  final String name;

  final AssetBundle _bundle;

  @override
  String get description => 'assets/extensions/$name';

  @override
  Future<Uint8List> read(String fileName) async {
    final ByteData data;
    try {
      data = await _bundle.load('$description/$fileName');
    } on FlutterError {
      // An asset that is not in the bundle: a build that went wrong, or a name missing from
      // pubspec.yaml.
      throw ExtensionPackageException(description, 'it has no $fileName');
    }
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  }
}

/// The files of a package in a folder the listener chose, through the platform's own way of keeping
/// access to one.
///
/// A folder is a path on desktop and a Storage Access Framework tree on Android, which is why this
/// goes through [UserFolder] rather than opening files itself. Whatever the platform says went wrong
/// is turned into the one failure the screens above know how to explain.
final class UserFolderExtensionFiles implements ExtensionFiles {
  const UserFolderExtensionFiles(this.folder);

  final UserFolder folder;

  @override
  String get description => folder.displayName;

  @override
  Future<Uint8List> read(String fileName) async {
    try {
      return await folder.read(fileName);
    } on FolderException catch (error) {
      throw ExtensionPackageException(description, error.message);
    }
  }
}

/// Reads every extension in [bundledExtensionNames].
///
/// One that cannot be read is left out rather than stopping the app, and reported through [onError]:
/// a broken extension should cost its own source and nothing else, which is the same rule §3.9 gives
/// an installed one.
Future<List<LoadedExtension>> loadBundledExtensions({
  AssetBundle? bundle,
  void Function(String name, Object error, StackTrace stack)? onError,
}) async {
  final extensions = <LoadedExtension>[];
  for (final name in bundledExtensionNames) {
    try {
      extensions.add(await loadBundledExtension(name, bundle: bundle));
    } catch (error, stack) {
      onError?.call(name, error, stack);
    }
  }
  return extensions;
}

/// Reads the extension in `assets/extensions/[name]/`.
///
/// Its `files` hashes are checked before the code is ever handed to a runtime, which is what §3.8
/// calls re-checking at load. For a bundled extension the check cannot catch tampering — an attacker
/// who can change the asset can change the manifest beside it — but it does catch the mistake that
/// will actually happen: a `main.js` edited and a manifest left behind.
///
/// Throws [ManifestException] for a manifest that cannot be read, and [ExtensionPackageException] for
/// one whose files do not match it.
Future<LoadedExtension> loadBundledExtension(
  String name, {
  AssetBundle? bundle,
}) async => LoadedExtension(
  package: await readExtensionPackage(
    AssetExtensionFiles(name, bundle: bundle),
    checkHashes: true,
  ),
  origin: ExtensionOrigin.bundled,
  status: ExtensionStatus.active,
);
