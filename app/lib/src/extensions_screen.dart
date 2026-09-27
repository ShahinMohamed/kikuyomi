import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikuyomi_extension_manager/kikuyomi_extension_manager.dart'
    show PackageRefused, RepositoryException;
import 'package:kikuyomi_domain/kikuyomi_domain.dart';
import 'package:kikuyomi_source_api/kikuyomi_source_api.dart' show SourceKind;
import 'package:kikuyomi_source_runtime/kikuyomi_source_runtime.dart';

import 'extensions_view.dart';
import 'providers.dart';
import 'routes.dart';
import 'snack_bars.dart';
import 'sources/extension_library.dart';
import 'sources/repository_library.dart';
import 'sources/source_registry.dart';

/// The [installed] extensions offering a source of [kind], by what [sources] says each offers.
///
/// One offering both kinds is in both lists. One with no source in [sources], because its code could
/// not be read this run, is in both as well, so the reason it cannot run is never out of sight.
List<ExtensionSummary> extensionsOfKind(
  List<ExtensionSummary> installed,
  List<SourceDescription> sources,
  SourceKind kind,
) {
  final kinds = <String, Set<SourceKind>>{};
  for (final source in sources) {
    final id = source.extensionId;
    if (id != null) (kinds[id] ??= {}).add(source.kind);
  }
  return [
    for (final extension in installed)
      if (kinds[extension.id]?.contains(kind) ?? true) extension,
  ];
}

/// Extensions on a screen of its own, reached from More.
///
/// Browse's Extensions tab is where a listener normally finds this; the screen exists so that More
/// has somewhere to point, and so a deep link to [ExtensionsRoute] still lands somewhere. Both show
/// the same [ExtensionsPanel].
class ExtensionsScreen extends StatelessWidget {
  const ExtensionsScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Extensions')),
    body: const ExtensionsPanel(),
  );
}

/// The extensions list and everything that can be done with it (§3.9).
///
/// A panel rather than a screen, because it is shown in two places: Browse's Extensions tab, which
/// is where a listener looks for one, and the standalone Extensions screen reached from More. Both
/// need the same state -- which extension is being worked on, and what the last update check found
/// -- so there is one implementation of it and not two that drift.
///
/// Checking for updates is an action inside the list rather than an icon in an app bar. It reads
/// every repository the listener has added, so it must not happen because a screen opened; and the
/// app bar above it belongs to whichever of the two places is showing the panel, which would mean
/// the same button living in two bars.
class ExtensionsPanel extends ConsumerStatefulWidget {
  const ExtensionsPanel({super.key, this.kind});

  /// Only the extensions offering sources of this kind (ADR-0019), or every one when null.
  ///
  /// An extension offering both kinds is listed under both. One whose sources are not known this
  /// run, because its code could not be read, is listed under both too: hiding it would hide the
  /// console line that says what is wrong with it.
  final SourceKind? kind;

  @override
  ConsumerState<ExtensionsPanel> createState() => _ExtensionsPanelState();
}

class _ExtensionsPanelState extends ConsumerState<ExtensionsPanel> {
  /// Which extension is being worked on, so that two taps cannot install the same folder twice. The
  /// empty string while a folder is being picked, when no extension is known yet.
  String? _busyWith;

  /// What the last check found, by extension id.
  ///
  /// Held here and not in the database, and not fetched when the screen opens. A check reads every
  /// repository the listener has added, which is a handful of requests, and doing that because
  /// somebody opened a screen would make opening it expensive and make the number of requests
  /// depend on how often they looked. So it is an action, and what it found lasts as long as the
  /// screen does.
  Map<String, ExtensionUpdate> _updates = const {};

  bool _checking = false;

  @override
  Widget build(BuildContext context) {
    final installed = ref.watch(extensionsProvider).value ?? const [];
    final kind = widget.kind;
    final extensions = kind == null
        ? installed
        : extensionsOfKind(
            installed,
            ref.watch(sourceListProvider).value ?? const [],
            kind,
          );
    final library = ref.watch(servicesProvider).extensions;
    // The console is watched, not read, so a failure logged while this screen is open is counted here
    // the moment it happens.
    final problems = <String, int>{};
    for (final line in ref.watch(extensionConsoleProvider).value ?? const []) {
      if (line.level == ExtensionLogLevel.error) {
        problems.update(line.extensionId, (n) => n + 1, ifAbsent: () => 1);
      }
    }

    return ExtensionsView(
      extensions: extensions,
      problems: problems,
      updates: {
        for (final update in _updates.values) update.id: update.offeredVersion,
      },
      canChooseFolder: library.canChooseFolder,
      dropFolderName: library.canInstallFromDropFolder
          ? library.dropFolderName
          : null,
      busyWith: _busyWith,
      onInstallFromFolder: _installFromPickedFolder,
      onInstallFromDropFolder: _installFromDropFolder,
      onReload: _reload,
      onRemove: _remove,
      onUpdate: _update,
      onRollBack: _rollBack,
      onOpenConsole: (extensionId) =>
          ExtensionConsoleRoute(extensionId: extensionId).push<void>(context),
      onCheckForUpdates: _checking ? null : _checkForUpdates,
      checking: _checking,
    );
  }

  Future<void> _installFromPickedFolder() => _work('', () async {
    final installed = await ref
        .read(servicesProvider)
        .extensions
        .installFromPickedFolder();
    if (installed != null) _tell(_installed(installed));
  });

  /// Installs from the app's own Extensions folder: the way in on iOS, where no folder outside the app
  /// can be kept. One folder is installed without asking; several are offered as a list, since the
  /// listener may have copied in more than one.
  Future<void> _installFromDropFolder() => _work('', () async {
    final library = ref.read(servicesProvider).extensions;
    await library.prepareDropFolder();
    final candidates = await library.dropFolderCandidates();
    if (candidates.isEmpty) {
      _tell(
        'Nothing in the ${library.dropFolderName} folder yet. Copy an '
        'extension folder into it, then try again.',
      );
      return;
    }
    final chosen = candidates.length == 1
        ? candidates.single
        : await _chooseFolder(candidates);
    if (chosen == null) return;
    _tell(_installed(await library.installFromPath(chosen.path)));
  });

  Future<Directory?> _chooseFolder(List<Directory> candidates) =>
      showDialog<Directory>(
        context: context,
        builder: (context) => SimpleDialog(
          title: const Text('Which one?'),
          children: [
            for (final folder in candidates)
              SimpleDialogOption(
                onPressed: () => Navigator.of(context).pop(folder),
                child: Text(folder.path.split(RegExp(r'[\\/]')).last),
              ),
          ],
        ),
      );

  /// Asks every repository what it is offering now, and acts on the parts that are not a download
  /// (§3.8).
  ///
  /// Withdrawals and reinstatements are applied here rather than offered, because neither is a
  /// choice. A version its publisher has pulled should stop running whether or not the listener
  /// happens to press something, and one that has been put back should run again for the same
  /// reason. An actual update is different: it is new code, and it waits to be asked for.
  Future<void> _checkForUpdates() async {
    if (_checking || _busyWith != null) return;
    setState(() => _checking = true);
    final services = ref.read(servicesProvider);
    try {
      final check = await services.repositories.checkForUpdates();

      for (final one in check.withdrawn) {
        await services.extensions.withdraw(one.id);
      }
      for (final one in check.restored) {
        try {
          await services.extensions.reinstate(one.id);
        } on ExtensionInstallException catch (error) {
          // Its files are gone or no longer read. Saying so beats leaving it disabled with no
          // reason given, and the rest of the check is still worth finishing.
          _tell(error.message);
        }
      }

      if (!mounted) return;
      setState(() {
        _updates = {for (final one in check.updates) one.id: one};
      });
      _sayWhatWasFound(check);
    } on RepositoryException catch (error) {
      _tell(error.message);
    } catch (error) {
      _tell('$error');
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  /// One sentence for the whole check, and an offer when there is something to do.
  void _sayWhatWasFound(UpdateCheck check) {
    if (!mounted) return;
    final parts = <String>[];
    if (check.updates.isEmpty) {
      parts.add('Nothing to update');
    } else {
      parts.add(
        check.updates.length == 1
            ? '1 update available'
            : '${check.updates.length} updates available',
      );
    }
    if (check.withdrawn.isNotEmpty) {
      parts.add('${check.withdrawn.length} withdrawn and stopped');
    }
    if (check.restored.isNotEmpty) {
      parts.add('${check.restored.length} offered again');
    }
    if (check.unreachable.isNotEmpty) {
      // Named, because "some repositories could not be read" leaves a listener with nothing to fix.
      parts.add('could not reach ${check.unreachable.keys.join(', ')}');
    }
    final message = '${parts.join('. ')}.';

    if (check.updates.isEmpty) {
      _tell(message);
      return;
    }
    offerInSnackBar(
      context,
      ScaffoldMessenger.of(context),
      message: message,
      action: check.updates.length == 1 ? 'Update' : 'Update all',
      onPressed: _updateAll,
    );
  }

  Future<void> _updateAll() async {
    // A copy, because installing each one takes it out of `_updates`.
    for (final one in List.of(_updates.values)) {
      await _install(one);
    }
  }

  Future<void> _update(ExtensionSummary extension) async {
    final waiting = _updates[extension.id];
    if (waiting == null) return;
    await _install(waiting);
  }

  /// Downloads and installs what [update] is offering, over the version in use.
  ///
  /// The same path an install from the Repositories screen takes, signature and all: an update is an
  /// install of a newer version, and a second path to it would be a second place for the checks to
  /// be forgotten.
  Future<void> _install(ExtensionUpdate update) => _work(update.id, () async {
    final services = ref.read(servicesProvider);
    final files = await services.repositories.fetchPackage(
      update.repository,
      update.entry,
    );
    final installed = await services.extensions.installFromRepository(
      files,
      repositoryUrl: update.repository.url,
      repositoryName: update.repository.name,
    );
    if (mounted) {
      setState(() => _updates = {..._updates}..remove(update.id));
    }
    _tell(
      'Updated ${installed.name} to ${installed.row.version}, signed by '
      '${update.repository.name}.',
    );
  });

  Future<void> _reload(ExtensionSummary extension) =>
      _work(extension.id, () async {
        final reloaded = await ref
            .read(servicesProvider)
            .extensions
            .reload(extension.id);
        _tell('Reloaded ${reloaded.name} ${reloaded.row.version}.');
      });

  Future<void> _rollBack(ExtensionSummary extension) async {
    final version = await chooseEarlierVersion(context, extension);
    if (version == null || !mounted) return;
    await _work(extension.id, () async {
      final back = await ref
          .read(servicesProvider)
          .extensions
          .rollBackTo(extension.id, version);
      _tell('${back.name} is back on ${back.row.version}.');
    });
  }

  Future<void> _remove(ExtensionSummary extension) async {
    if (!await confirmRemoveExtension(context, extension)) return;
    await _work(extension.id, () async {
      await ref.read(servicesProvider).extensions.remove(extension.id);
      _tell('Removed ${extension.name}.');
    });
  }

  /// Runs [action] with the screen marked busy, and turns whatever it throws into a sentence.
  ///
  /// Every failure here is one a listener can act on — a folder that is not an extension, a folder that
  /// can no longer be read, an extension this app is too old for — so each is shown rather than only
  /// logged.
  Future<void> _work(String id, Future<void> Function() action) async {
    if (_busyWith != null) return;
    setState(() => _busyWith = id);
    try {
      await action();
    } on ExtensionInstallException catch (error) {
      _tell(error.message);
    } on FolderException catch (error) {
      _tell(error.message);
    } on PackageRefused catch (error) {
      _tell(error.message);
    } on RepositoryException catch (error) {
      _tell(error.message);
    } catch (error) {
      _tell('$error');
    } finally {
      if (mounted) setState(() => _busyWith = null);
    }
  }

  String _installed(ExtensionSummary extension) =>
      'Installed ${extension.name} ${extension.row.version}. '
              '${extension.isUnverified ? 'Unverified: nothing checked its code.' : ''}'
          .trimRight();

  void _tell(String message) {
    if (!mounted) return;
    tellInSnackBar(ScaffoldMessenger.of(context), message);
  }
}
