/// Installing an extension: the app's own copy of its files (§3.9).
///
/// "Installing downloads the package, verifies it, unpacks it into a versioned directory, and
/// registers its sources." This is the unpacking. Verifying is `readExtensionPackage`, and
/// registering is the app's, since only the app has a database.
///
/// The copy matters. An extension installed from a folder must still be there at the next start,
/// after the listener has moved the folder, revoked the app's access to it or — on Android, where a
/// chosen folder is a Storage Access Framework tree rather than a path — plugged the phone into a
/// computer and reorganised it. So the files are read once, at install, and kept in storage the app
/// owns. Where the extension came from is remembered separately, by the database, so that an author
/// can reload an edited folder on demand (§3.11's live reload, by hand until the repository door
/// arrives).
library;

import 'dart:io';

import 'package:kikuyomi_domain/kikuyomi_domain.dart';

import 'package.dart';

/// Where installed extensions' code is kept: one folder per extension, one folder per version.
///
/// Inside the app's own data, so it is private, it survives a restart, and it is never a path the
/// listener can edit under the app's feet. §3.9's "versioned directory" is the reason for the second
/// level: an update is installed beside the version in use, and nothing has to be deleted before the
/// new version is known to read.
final class ExtensionInstallFolder {
  const ExtensionInstallFolder(this.root);

  /// The folder every install path is relative to.
  final Directory root;

  /// Writes [package] into its own versioned folder and returns its install path: `<id>/<code>`,
  /// relative to [root].
  ///
  /// Relative, because a book's cover path is relative for the same reason: on iOS the app's
  /// container moves when the app is updated or reinstalled, and an absolute path recorded today is
  /// wrong tomorrow.
  ///
  /// The files are written under a partial name and the folder takes its real name only once both
  /// are there, so an install cut short — by the app being killed, or the disk filling — never leaves
  /// a folder that looks installed but holds half an extension. Installing a version already there
  /// replaces it, which is what reloading an edited folder does.
  Future<String> write(ExtensionPackage package) async {
    final installPath = installPathFor(
      package.manifest.id,
      package.manifest.versionCode,
    );
    final target = _folderAt(installPath);
    final partial = Directory('${target.path}$partialFileSuffix');
    if (await partial.exists()) await partial.delete(recursive: true);
    await partial.create(recursive: true);
    // Both files are written back exactly as they were read. A manifest re-encoded from the fields
    // this app understood would quietly drop the fields a later minor version adds (§3.7), and the
    // manifest's own hash of main.js would stop describing the file beside it.
    await File('${partial.path}$_slash$extensionManifestFileName')
        .writeAsString(package.manifestJson);
    await File('${partial.path}$_slash$extensionCodeFileName')
        .writeAsString(package.code);
    // Kept beside the code so that a list can show it with no network and no unpacking. An
    // extension without one simply has no file here, and the list shows a placeholder.
    if (package.icon case final icon?) {
      await File('${partial.path}$_slash$extensionIconFileName')
          .writeAsBytes(icon);
    }
    if (await target.exists()) await target.delete(recursive: true);
    await partial.rename(target.path);
    return installPath;
  }

  /// The icon of the extension installed at [installPath], or null when it has none.
  ///
  /// A path rather than bytes: a widget wants an image file, and reading one into memory to hand it
  /// over would be the list holding every icon it has ever drawn.
  File? iconAt(String installPath) {
    final file = File(
      '${_folderAt(installPath).path}$_slash$extensionIconFileName',
    );
    return file.existsSync() ? file : null;
  }

  /// The files of the extension installed at [installPath], to read its package back.
  ExtensionFiles filesAt(String installPath) =>
      DirectoryExtensionFiles(_folderAt(installPath));

  /// The folder [installPath] names on this platform. An install path is recorded with forward
  /// slashes, as a path relative to the app's own storage always is here, so that a database written
  /// on one platform does not name folders no other platform can open.
  Directory _folderAt(String installPath) =>
      Directory('${root.path}$_slash${installPath.replaceAll('/', _slash)}');

  /// Every version of [extensionId] kept on disk, newest first.
  ///
  /// This is what §3.9's "versioned directory" was for. An update is written beside the version in
  /// use rather than over it, so the one that worked yesterday is still there, and rolling back is
  /// reading a folder rather than downloading anything -- which matters exactly when it is needed,
  /// since an extension is most often rolled back because something has stopped working and a
  /// listener may well be offline.
  ///
  /// Folders left behind by an install that was cut short are skipped: they carry
  /// [partialFileSuffix] and hold half an extension. So is anything whose name is not a version
  /// code, because this folder belongs to the app and a name that is not one did not come from here.
  Future<List<int>> versionsOf(String extensionId) async {
    final folder = Directory('${root.path}$_slash$extensionId');
    if (!await folder.exists()) return const [];
    final versions = <int>[];
    await for (final entry in folder.list(followLinks: false)) {
      if (entry is! Directory) continue;
      final name = entry.path.split(RegExp(r'[\\/]')).last;
      if (name.endsWith(partialFileSuffix)) continue;
      final version = int.tryParse(name);
      if (version != null) versions.add(version);
    }
    versions.sort((a, b) => b.compareTo(a));
    return versions;
  }

  /// Deletes every version of [extensionId]: what uninstalling removes.
  ///
  /// §3.9: uninstalling removes the code, and nothing else. The listener's data — the library books
  /// that came from its sources, their progress and its stored preferences — outlives it, so none of
  /// that is here.
  Future<void> deleteAll(String extensionId) async {
    final folder = Directory('${root.path}$_slash$extensionId');
    if (await folder.exists()) await folder.delete(recursive: true);
  }

  /// The install path of one version: `<id>/<versionCode>`.
  ///
  /// An extension's id is safe as a folder name without being escaped: the manifest reads an id only
  /// if it is lower-case letters, digits, dots, dashes and underscores, so it holds no separator and
  /// can never be `..`.
  static String installPathFor(String extensionId, int versionCode) =>
      '$extensionId/$versionCode';
}

/// The separator this platform's paths use.
final _slash = Platform.pathSeparator;
