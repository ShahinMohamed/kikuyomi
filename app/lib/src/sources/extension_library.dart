/// Installing, removing and reloading extensions: the extension side of §3.9's lifecycle.
///
/// The repository door (§3.8) is not built yet, so the one way in is a folder: one holding a
/// `manifest.json` and a `main.js`, which is exactly what §3.3's package is before it is zipped and
/// signed. That is also what an author has open in an editor, which makes it the door worth having
/// first.
///
/// Three ways to reach such a folder, one per platform's habits:
///
/// - the platform's folder picker, which `UserFolders` already provides as a path on desktop and a
///   Storage Access Framework tree on Android;
/// - a path on the command line, for an edit-and-reload loop on a desktop;
/// - the app's own Extensions folder, which on iOS the Files app shows, since iOS can keep no folder
///   the listener picks elsewhere.
///
/// Whichever it is, the files are copied into storage the app owns (`ExtensionInstallFolder`) and the
/// install is recorded in the database, so the extension is still there after a restart. Where it came
/// from is recorded too, which is what [ExtensionLibrary.reload] reads to pick up an edit.
library;

import 'dart:io';

import 'package:kikuyomi_data/kikuyomi_data.dart';
import 'package:kikuyomi_domain/kikuyomi_domain.dart';
import 'package:kikuyomi_extension_manager/kikuyomi_extension_manager.dart';

import 'extension_console.dart';
import 'extension_packages.dart';
import 'source_registry.dart';

/// What an extension the app knows about looks like on the Extensions screen.
///
/// A row of §4.3's `extension` table, and whether the app could read its files this run. An extension
/// that is installed but unreadable is still listed, with the reason in the console: quietly hiding it
/// would leave a listener with a source that is gone and no way to see why.
final class ExtensionSummary {
  const ExtensionSummary({
    required this.row,
    required this.isRunnable,
    this.earlierVersions = const [],
  });

  final ExtensionRow row;

  /// Whether the app has this extension's code in hand and will start a runtime for it.
  final bool isRunnable;

  String get id => row.id;
  String get name => row.name;
  bool get isBundled => row.origin == ExtensionOrigin.bundled;

  /// Whether nothing proved this code is what its author published (§3.8).
  bool get isUnverified => row.status == ExtensionStatus.untrusted;

  /// The other versions of it still on disk, newest first (§3.9).
  ///
  /// An update is installed beside the version in use rather than over it, so what is here is every
  /// version that ever installed and has not been uninstalled since. It is read from disk rather
  /// than from the database, because the database holds the one version in use and the folders are
  /// the only record of the rest.
  final List<int> earlierVersions;

  /// Whether there is a version to go back to.
  bool get canRollBack => !isBundled && earlierVersions.isNotEmpty;

  /// Whether this extension can be reloaded from where it came from.
  bool get canReload =>
      row.origin == ExtensionOrigin.folder && row.originHandle != null;
}

/// An extension the app refused, with a sentence saying why.
///
/// Thrown rather than swallowed, so that every way in — the picker, the command line, the Extensions
/// screen — says the same thing about the same folder.
final class ExtensionInstallException implements Exception {
  const ExtensionInstallException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Reads every extension the app has, for the registry to start from.
///
/// The bundled ones first, whose hashes are checked, and then those installed, whose hashes are
/// checked only if something ever verified them: a folder install is `untrusted` on purpose, because
/// an author's manifest names the hash of the `main.js` they had before the last edit (§3.8).
///
/// One that cannot be read is left out rather than stopping the app, and the reason goes to the
/// console, where the Extensions screen shows it. The row stays: the extension is installed, it just
/// did not read today, and telling the listener that is the whole point of having a console.
Future<List<LoadedExtension>> readExtensionsAtStart({
  required KikuyomiDatabase database,
  required ExtensionInstallFolder installs,
  required ExtensionConsole console,
  required Clock clock,
}) async {
  final extensions = await loadBundledExtensions(
    onError: (name, error, stack) => console.report(name, error),
  );
  // The bundled extensions get a row of their own, so that one list shows everything the app runs and
  // so an extension's stored preferences always have an extension to belong to. Recorded only when it
  // is new or has changed, so `installed_at` keeps saying when this copy arrived rather than when the
  // app last started.
  for (final extension in extensions) {
    final known = await readInstalledExtension(database, extension.id);
    if (known != null &&
        known.versionCode == extension.manifest.versionCode &&
        known.origin == ExtensionOrigin.bundled) {
      continue;
    }
    await recordInstalledExtension(
      database,
      id: extension.id,
      name: extension.manifest.name,
      version: '${extension.manifest.version}',
      versionCode: extension.manifest.versionCode,
      apiVersion: '${extension.manifest.apiVersion}',
      status: ExtensionStatus.active,
      origin: ExtensionOrigin.bundled,
      clock: clock,
    );
  }
  for (final row in await readInstalledExtensions(database)) {
    final installPath = row.installPath;
    if (row.origin == ExtensionOrigin.bundled || installPath == null) continue;
    try {
      extensions.add(
        LoadedExtension(
          package: await readExtensionPackage(
            installs.filesAt(installPath),
            checkHashes: row.status == ExtensionStatus.active,
          ),
          origin: row.origin,
          status: row.status,
          originHandle: row.originHandle,
          originName: row.originName,
          installPath: installPath,
          installedAt: row.installedAt,
        ),
      );
    } catch (error) {
      console.report(row.id, error);
    }
  }
  return extensions;
}

/// What the app can do with the extensions it has installed (§3.9).
final class ExtensionLibrary {
  ExtensionLibrary({
    required this.sources,
    required this.console,
    required this._database,
    required this._installs,
    required this._folders,
    required this._dropFolder,
    required this._clock,
    required this.canInstallFromDropFolder,
  });

  /// The sources every installed extension provides, and the runtimes behind them.
  final SourceRegistry sources;

  /// What extensions have written, and what the app has to say about them (§3.5, §3.11).
  final ExtensionConsole console;

  /// Whether the listener can put an extension in a folder of the app's own and install it from
  /// there.
  ///
  /// True where that folder is one the listener can see, which today is iOS, where the Files app shows
  /// the app's Documents folder and no folder outside it can be kept (§5.1, Appendix A). Elsewhere the
  /// folder picker is the way in and this folder is not worth mentioning.
  final bool canInstallFromDropFolder;

  final KikuyomiDatabase _database;
  final ExtensionInstallFolder _installs;
  final UserFolders _folders;
  final Directory _dropFolder;
  final Clock _clock;

  /// Whether this device can show a folder picker at all.
  bool get canChooseFolder => _folders.canChoose;

  /// What to call the folder extensions may be copied into, for a sentence telling the listener where
  /// to put one.
  String get dropFolderName => _lastSegment(_dropFolder.path);

  /// Every extension the app knows about, watched, so a screen follows an install or a removal (§2.5).
  Stream<List<ExtensionSummary>> watch() =>
      watchInstalledExtensions(_database).asyncMap(_summarise);

  /// Every extension the app knows about, once.
  Future<List<ExtensionSummary>> read() async =>
      _summarise(await readInstalledExtensions(_database));

  /// Installs the extension in the folder the listener picks, and returns it, or null if they picked
  /// nothing.
  ///
  /// Throws [FolderUnsupportedException] where no folder can be picked, and
  /// [ExtensionInstallException] for a folder that is not an extension.
  Future<ExtensionSummary?> installFromPickedFolder() async {
    final folder = await _folders.choose();
    if (folder == null) return null;
    return _install(
      UserFolderExtensionFiles(folder),
      handle: folder.handle,
      name: folder.displayName,
    );
  }

  /// Installs the extension in the folder at [path]: a path given on the command line, or one of
  /// [dropFolderCandidates].
  Future<ExtensionSummary> installFromPath(String path) {
    final folder = Directory(path);
    return _install(
      DirectoryExtensionFiles(folder),
      handle: folder.absolute.path,
      name: folder.absolute.path,
    );
  }

  /// The folders in the app's own Extensions folder that hold a manifest, and so are worth offering as
  /// something to install.
  ///
  /// Anything at all may have been copied in through the Files app, so a folder with no manifest is
  /// left out rather than offered and then refused.
  Future<List<Directory>> dropFolderCandidates() async {
    if (!await _dropFolder.exists()) return const [];
    final folders = <Directory>[];
    await for (final entry in _dropFolder.list(followLinks: false)) {
      if (entry is Directory &&
          await DirectoryExtensionFiles.looksLikeOne(entry)) {
        folders.add(entry);
      }
    }
    folders.sort((a, b) => a.path.compareTo(b.path));
    return folders;
  }

  /// Makes the folder extensions may be copied into, so that it is there to be found in the Files app
  /// before anything has been put in it.
  Future<Directory> prepareDropFolder() => _dropFolder.create(recursive: true);

  /// Reads the extension [id] again from the folder it was installed from, and replaces the app's copy
  /// with what is there now.
  ///
  /// §3.11's live reload, by hand: an author edits `main.js`, presses this, and the next use of the
  /// source runs the new code. The runtime is stopped as part of adopting it, so nothing keeps running
  /// the old bundle.
  ///
  /// Throws [ExtensionInstallException] when this extension did not come from a folder, or the folder
  /// can no longer be read.
  Future<ExtensionSummary> reload(String id) async {
    final row = await readInstalledExtension(_database, id);
    if (row == null) {
      throw ExtensionInstallException('$id is not installed.');
    }
    final handle = row.originHandle;
    if (row.origin != ExtensionOrigin.folder || handle == null) {
      throw ExtensionInstallException(
        '${row.name} did not come from a folder, so there is nothing to read '
        'again.',
      );
    }
    return _install(
      _filesAt(handle),
      handle: handle,
      name: row.originName ?? handle,
    );
  }

  /// Removes the extension [id]: its code, and the app's record of it.
  ///
  /// §3.9: "Uninstalling removes the code but not the user's data: library books from that source keep
  /// their metadata, progress, and downloads, and point to a stub source until the extension returns or
  /// the books are migrated." So the library is untouched, the `source` rows stay as stubs, and
  /// whatever the extension had stored is still there if it comes back.
  ///
  /// Throws [ExtensionInstallException] for the extension that ships inside the app, which is part of
  /// the app and cannot be removed.
  Future<void> remove(String id) async {
    final row = await readInstalledExtension(_database, id);
    if (row == null) return;
    if (row.origin == ExtensionOrigin.bundled) {
      throw ExtensionInstallException(
        '${row.name} ships inside Kikuyomi and cannot be removed.',
      );
    }
    await sources.forget(id);
    await forgetInstalledExtension(_database, id);
    await _installs.deleteAll(id);
    console.note(id, 'Removed. Your books, progress and settings were kept.');
  }

  /// Installs the package a repository served, recording where it came from (§3.8, §3.9).
  ///
  /// Hashes are checked here, unlike a folder install: a package is assembled as one piece, so its
  /// manifest's `files` map proves the manifest and the code were published together. That is worth
  /// something for a package and worth nothing for a folder somebody is editing.
  ///
  /// It is recorded `active`, and that word is earned by three checks that have already happened by
  /// the time [files] gets here. The repository's pinned key signed the hash the index listed; the
  /// bytes that arrived hash to it; and the manifest inside those bytes names the hash of the code
  /// beside it. So the app can say who published this code, and that it is unaltered, which is as
  /// far as `active` ever claims to go — it is not a statement that the code is any good, only that
  /// it is the code the repository the listener trusted actually published.
  ///
  /// It also means the hashes are re-checked at every start, which a folder install skips: from here
  /// on, code that no longer matches its manifest is something to notice rather than something an
  /// author is in the middle of doing.
  Future<ExtensionSummary> installFromRepository(
    ExtensionFiles files, {
    required String repositoryUrl,
    required String repositoryName,
  }) => _install(
    files,
    handle: repositoryUrl,
    name: repositoryName,
    origin: ExtensionOrigin.repository,
    checkHashes: true,
    status: ExtensionStatus.active,
  );

  /// Reads the package [files] hold and takes it in, replacing any version of it already installed.
  /// Stops [id] running, because the repository it came from withdrew the version installed (§3.8).
  ///
  /// The code is left on disk and the row is left in place. §3.9 is clear about what uninstalling
  /// does and this is not that: a withdrawal is the publisher saying this version should not be
  /// used, not the listener saying they are done with it. The library books, their progress and the
  /// extension's stored settings all stay, so reinstating it or installing the next version puts
  /// everything back.
  ///
  /// Saying so in the console matters more here than elsewhere, because a source disappearing from
  /// Browse with no explanation is indistinguishable from a bug.
  Future<void> withdraw(String id) async {
    await setExtensionStatus(_database, id, ExtensionStatus.revoked);
    await sources.forget(id);
    console.note(
      id,
      'Withdrawn by the repository it came from, so it has stopped running. '
      'Your books, progress and settings were kept.',
    );
  }

  /// Lets [id] run again, because its repository is offering the installed version once more.
  ///
  /// Reads the package back off disk rather than trusting the row: the status says what the app
  /// believed last time, and what decides whether an extension can run today is whether its files
  /// are still there and still readable. This is the same path a restart takes, which is what makes
  /// reinstating equivalent to restarting the app without having to.
  ///
  /// Hashes are checked, because this only ever applies to a repository install, whose manifest and
  /// code were published together.
  Future<ExtensionSummary> reinstate(String id) async {
    final row = await readInstalledExtension(_database, id);
    final installPath = row?.installPath;
    if (row == null || installPath == null) {
      throw ExtensionInstallException(
        'There is nothing installed under $id to reinstate.',
      );
    }

    final LoadedExtension read;
    try {
      read = LoadedExtension(
        package: await readExtensionPackage(
          _installs.filesAt(installPath),
          checkHashes: true,
        ),
        origin: row.origin,
        status: ExtensionStatus.active,
        originHandle: row.originHandle,
        originName: row.originName,
        installPath: installPath,
        installedAt: row.installedAt,
      );
    } on ExtensionPackageException catch (error) {
      throw ExtensionInstallException(
        '${row.name} could not be read back: ${error.message}',
      );
    } on ManifestException catch (error) {
      throw ExtensionInstallException(
        '${row.name} could not be read back: ${error.message}',
      );
    }

    await setExtensionStatus(_database, id, ExtensionStatus.active);
    await sources.adopt(read);
    console.note(
      id,
      'Offered again by its repository, so it is running again.',
    );
    final updated = await readInstalledExtension(_database, id);
    return ExtensionSummary(row: updated!, isRunnable: true);
  }

  /// The versions of [id] still on disk, newest first, for offering a way back.
  Future<List<int>> versionsOf(String id) => _installs.versionsOf(id);

  /// Puts [id] back to [versionCode], which an earlier install left on disk (§3.9).
  ///
  /// Nothing is downloaded. An extension is rolled back because the version in use has stopped
  /// working, and that is exactly the moment to need no network: the files are already there,
  /// beside the ones in use, because an update is written into a folder of its own rather than over
  /// the last one.
  ///
  /// The row is rewritten rather than a second one added. One extension is one row holding the
  /// version in use, so after this the app, the Extensions screen and the next update check all
  /// agree about which version that is -- and a repository offering something newer will offer it
  /// again, because the installed version code is lower once more. That is the point: rolling back
  /// is not pinning, and a listener who rolls back and then updates gets the new one.
  ///
  /// Throws [ExtensionInstallException] when that version is not on disk or no longer reads.
  Future<ExtensionSummary> rollBackTo(String id, int versionCode) async {
    final row = await readInstalledExtension(_database, id);
    if (row == null) {
      throw ExtensionInstallException('There is nothing installed under $id.');
    }
    if (row.origin == ExtensionOrigin.bundled) {
      throw ExtensionInstallException(
        '${row.name} ships inside Kikuyomi, so there is no earlier version to '
        'go back to.',
      );
    }
    if (versionCode == row.versionCode) {
      throw ExtensionInstallException(
        '${row.name} ${row.version} is the version already in use.',
      );
    }

    final installPath = ExtensionInstallFolder.installPathFor(id, versionCode);
    final LoadedExtension read;
    try {
      read = LoadedExtension(
        // Checked for a package and not for a folder, exactly as installing does: what makes a
        // manifest's hashes worth checking is that the manifest and the code were published
        // together, which is true of what a repository served and not of a folder being edited.
        package: await readExtensionPackage(
          _installs.filesAt(installPath),
          checkHashes: row.origin == ExtensionOrigin.repository,
        ),
        origin: row.origin,
        // The status the version being restored deserves, which is the status its origin earns:
        // a repository install was verified when it arrived and its hashes are checked again here,
        // a folder install never was.
        status: row.origin == ExtensionOrigin.repository
            ? ExtensionStatus.active
            : ExtensionStatus.untrusted,
        originHandle: row.originHandle,
        originName: row.originName,
        installPath: installPath,
        installedAt: row.installedAt,
      );
    } on ExtensionPackageException catch (error) {
      throw ExtensionInstallException(
        '${row.name} $versionCode could not be read back: ${error.message}',
      );
    } on ManifestException catch (error) {
      throw ExtensionInstallException(
        '${row.name} $versionCode could not be read back: ${error.message}',
      );
    }

    final refusal = SourceRegistry.refusalFor(read, sources.appVersion);
    if (refusal != null) {
      throw ExtensionInstallException(
        'Kikuyomi cannot run ${read.manifest.name} ${read.manifest.version}: '
        '${refusal.message}',
      );
    }

    await recordInstalledExtension(
      _database,
      id: id,
      name: read.manifest.name,
      version: '${read.manifest.version}',
      versionCode: read.manifest.versionCode,
      apiVersion: '${read.manifest.apiVersion}',
      status: read.status,
      origin: read.origin,
      originHandle: row.originHandle,
      originName: row.originName,
      installPath: installPath,
      clock: _clock,
    );
    await sources.adopt(read);
    console.note(id, 'Went back to ${read.manifest.version}.');
    final updated = await readInstalledExtension(_database, id);
    return ExtensionSummary(row: updated!, isRunnable: true);
  }

  Future<ExtensionSummary> _install(
    ExtensionFiles files, {
    required String handle,
    required String name,
    ExtensionOrigin origin = ExtensionOrigin.folder,
    bool checkHashes = false,
    ExtensionStatus status = ExtensionStatus.untrusted,
  }) async {
    final LoadedExtension read;
    try {
      read = LoadedExtension(
        // A folder's hashes are not checked. A manifest's `files` map proves that the manifest and
        // the code were published together; in a folder an author is working in, it proves only which
        // version of main.js they last took a hash of. The install is marked `untrusted` instead, and
        // the Extensions screen says so, rather than refusing the one install an author makes most.
        // A package from a repository is a different case and is checked.
        package: await readExtensionPackage(files, checkHashes: checkHashes),
        origin: origin,
        status: status,
        originHandle: handle,
        originName: name,
      );
    } on ManifestException catch (error) {
      throw ExtensionInstallException(
        'The manifest in $name could not be read: ${error.message}',
      );
    } on ExtensionPackageException catch (error) {
      throw ExtensionInstallException(
        '$name is not an extension: ${error.message}',
      );
    }
    final refusal = SourceRegistry.refusalFor(read, sources.appVersion);
    if (refusal != null) {
      throw ExtensionInstallException(
        'Kikuyomi cannot run ${read.manifest.name}: ${refusal.message}',
      );
    }
    final installPath = await _installs.write(read.package);
    final installed = LoadedExtension(
      package: read.package,
      origin: read.origin,
      status: read.status,
      originHandle: handle,
      originName: name,
      installPath: installPath,
      installedAt: _clock.now(),
    );
    await recordInstalledExtension(
      _database,
      id: installed.id,
      name: installed.manifest.name,
      version: '${installed.manifest.version}',
      versionCode: installed.manifest.versionCode,
      apiVersion: '${installed.manifest.apiVersion}',
      status: installed.status,
      origin: installed.origin,
      originHandle: handle,
      originName: name,
      installPath: installPath,
      clock: _clock,
    );
    await sources.adopt(installed);
    console.note(
      installed.id,
      'Installed ${installed.manifest.version} from $name.',
    );
    final row = await readInstalledExtension(_database, installed.id);
    return ExtensionSummary(row: row!, isRunnable: true);
  }

  /// The files of the folder [handle] names.
  ///
  /// A handle this process can open as a folder is opened directly; anything else is a handle only the
  /// platform understands, such as Android's Storage Access Framework tree, and goes back through
  /// [UserFolders]. Not a platform check: the question is whether this handle names a folder that can
  /// be read here, and on Android the answer for a tree is no.
  ExtensionFiles _filesAt(String handle) {
    final folder = Directory(handle);
    return folder.existsSync()
        ? DirectoryExtensionFiles(folder)
        : UserFolderExtensionFiles(_folders.open(handle));
  }

  /// The rows, with what only disk can answer: which other versions are still there.
  ///
  /// One directory listing per extension, on a list that changes when something is installed or
  /// removed. That is a few stat calls for a handful of folders, and the alternative is a menu that
  /// offers a way back without knowing whether there is one.
  Future<List<ExtensionSummary>> _summarise(List<ExtensionRow> rows) async {
    final runnable = {for (final e in sources.extensions) e.id};
    return [
      for (final row in rows)
        ExtensionSummary(
          row: row,
          isRunnable: runnable.contains(row.id),
          earlierVersions: row.origin == ExtensionOrigin.bundled
              ? const []
              : [
                  for (final version in await _installs.versionsOf(row.id))
                    if (version != row.versionCode) version,
                ],
        ),
    ];
  }
}

String _lastSegment(String path) {
  final segments = path.split(RegExp(r'[\\/]'))
    ..removeWhere((segment) => segment.isEmpty);
  return segments.isEmpty ? path : segments.last;
}
