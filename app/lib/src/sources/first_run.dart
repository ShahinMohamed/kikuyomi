/// What a fresh install starts with: the official repository, and the extensions it publishes
/// (§3.8, §3.9).
///
/// Kikuyomi is useless until a source exists, and until now the answer was one extension bundled
/// inside the app. A bundled extension has a flaw that only shows up later: it can never be updated
/// without shipping a new app, because the update check looks at the repository an extension came
/// from and a bundled one came from nowhere.
///
/// So the app ships the packages **as assets** and installs them on first run, recording them as
/// having come from the official repository. Afterwards they are ordinary repository installs: the
/// update check finds them, a newer version replaces them, and rolling back works. What the assets
/// buy is that none of this needs a network on the first run.
///
/// **The repository is added without the listener accepting its fingerprint**, which is where this
/// departs from §3.8's trust on first use, and it is worth being plain about. Trust on first use
/// exists so a listener decides whether a *stranger's* repository is worth trusting. This one is not
/// a stranger: it ships inside the app, in the same release, and an app that meant to do something
/// untoward would not need a repository to do it. A listener who disagrees can remove it on the
/// Repositories screen, and the extensions stay installed, as §3.9 says they must.
///
/// Every failure is survivable: a package that will not read costs its own source and nothing else,
/// which is the rule §3.9 gives an installed extension.
library;

import 'package:flutter/services.dart';
import 'package:kikuyomi_data/kikuyomi_data.dart';
import 'package:kikuyomi_domain/kikuyomi_domain.dart';
import 'package:kikuyomi_extension_manager/kikuyomi_extension_manager.dart';

import 'extension_console.dart';
import 'extension_library.dart';
import 'extension_packages.dart';

/// Where the official repository is served from.
///
/// The same address `packages/extension_manager/tool/build_repository.dart` writes into every
/// package URL it publishes. `app/test/official_repository_test.dart` holds the two together, so
/// this cannot drift from what is actually published.
const officialRepositoryUrl =
    'https://raw.githubusercontent.com/kikuyomiapp/kikuyomi/HEAD/repository/';

/// The extensions shipped as assets, each a folder under `assets/extensions/`.
///
/// Adding one means listing it here and in `pubspec.yaml`'s assets.
const shippedExtensionNames = [
  'librivox',
  'internetarchive',
  'storynory',
  'podcasts',
  'standardebooks',
];

/// What an install seeded before [AppSettings.shippedExtensionsOffered] was recorded had been
/// offered: the four the app first shipped.
const _offeredBeforeRecording = [
  'librivox',
  'internetarchive',
  'storynory',
  'podcasts',
];

/// Adds the official repository and installs what it publishes, once.
///
/// Run at every start, and does nothing after the first except one thing: an extension still
/// recorded as `bundled` is installed over, which moves an install from before this existed onto
/// the repository so that it can be updated at all.
///
/// **What it never does is put back an extension the listener removed.** A fresh install and a
/// removal look identical in the extensions table -- a row that is not there -- so the difference
/// has to be remembered, and [AppSettings.shippedExtensionsSeeded] is where. Without it, removing an
/// extension would be undone by the next restart, which is not a removal at all.
Future<void> seedOfficialRepository({
  required KikuyomiDatabase database,
  required SettingsStore settings,
  required ExtensionLibrary extensions,
  required ExtensionConsole console,
  AssetBundle? bundle,
}) async {
  final seededBefore =
      settings.read(AppSettings.shippedExtensionsSeeded) ?? false;
  // Offered once is offered: an extension the listener removed is never put back, and one shipped
  // since the last start is installed now.
  final offered = {
    ...settings.read(AppSettings.shippedExtensionsOffered) ??
        (seededBefore ? _offeredBeforeRecording : const <String>[]),
  };

  final RepositoryInfo info;
  try {
    info = RepositoryInfo.parse(
      await (bundle ?? rootBundle).loadString('assets/repository/repo.json'),
    );
  } catch (error) {
    // Without the repository's own document there is no key to pin, and guessing one would be the
    // app asserting something it cannot check.
    console.report('org.kikuyomi', error);
    return;
  }

  if (!seededBefore &&
      await readRepositoryAt(database, officialRepositoryUrl) == null) {
    await addRepository(
      database,
      url: officialRepositoryUrl,
      name: info.name,
      publicKey: info.publicKey,
      fingerprint: info.fingerprint,
    );
  }

  final installed = {
    for (final row in await readInstalledExtensions(database)) row.id: row,
  };
  for (final name in shippedExtensionNames) {
    try {
      final files = AssetExtensionFiles(name, bundle: bundle);
      // Read first, to learn which extension the folder holds without trusting its name.
      final package = await readExtensionPackage(files, checkHashes: true);
      final row = installed[package.manifest.id];
      final wanted = row == null
          ? !offered.contains(name)
          : row.origin == ExtensionOrigin.bundled;
      if (wanted) {
        await extensions.installFromRepository(
          files,
          repositoryUrl: officialRepositoryUrl,
          repositoryName: info.name,
        );
      }
      // Only once it is in, or was already: one that failed to install is tried again next start.
      offered.add(name);
    } catch (error) {
      console.report(name, error);
    }
  }

  if (!seededBefore) {
    await settings.write(AppSettings.shippedExtensionsSeeded, true);
  }
  await settings.write(AppSettings.shippedExtensionsOffered, [...offered]);
}
