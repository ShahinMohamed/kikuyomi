import 'dart:io';

import 'package:flutter/material.dart';
import 'package:kikuyomi_domain/kikuyomi_domain.dart';

import 'sources/extension_library.dart';

/// What the Extensions screen shows, fed with data rather than reading it, so it can be tested
/// without a database, an engine or a folder (§2.10).
///
/// §3.9 decides most of what is here. An extension is installed, reloaded from where it came from, or
/// removed — and removing one takes its code and nothing else, which the screen says out loud, because
/// "will I lose my books?" is the question a listener has at that moment.
class ExtensionsView extends StatelessWidget {
  const ExtensionsView({
    super.key,
    required this.extensions,
    required this.problems,
    required this.updates,
    required this.canChooseFolder,
    required this.dropFolderName,
    required this.busyWith,
    required this.onInstallFromFolder,
    required this.onInstallFromDropFolder,
    required this.onReload,
    required this.onRemove,
    required this.onUpdate,
    required this.onRollBack,
    required this.onOpenConsole,
    required this.onCheckForUpdates,
    required this.checking,
  });

  /// Every extension the app knows about, bundled and installed.
  final List<ExtensionSummary> extensions;

  /// How many failures the console holds about each extension, by id.
  final Map<String, int> problems;

  /// The version a repository is offering, by extension id, for the ones a check found something
  /// newer for. Empty until a check has been run: this screen never asks the network on its own,
  /// because opening Extensions should not cost a listener a dozen requests.
  final Map<String, String> updates;

  /// Whether this device can show a folder picker (§5.1: not iOS).
  final bool canChooseFolder;

  /// The name of the folder an extension can be copied into, or null where that folder is not one the
  /// listener can see.
  final String? dropFolderName;

  /// The id of the extension being installed, reloaded or removed, or the empty string while a folder
  /// is being picked. Null when nothing is under way.
  final String? busyWith;

  final VoidCallback onInstallFromFolder;
  final VoidCallback onInstallFromDropFolder;
  final ValueChanged<ExtensionSummary> onReload;
  final ValueChanged<ExtensionSummary> onRemove;
  final ValueChanged<ExtensionSummary> onUpdate;
  final ValueChanged<ExtensionSummary> onRollBack;

  /// Opens the console, for every extension or for one.
  final ValueChanged<String?> onOpenConsole;

  /// Asks every repository what it is offering now. Null while a check is already running.
  final VoidCallback? onCheckForUpdates;

  /// Whether one is running, so the row can say so rather than looking unpressed.
  final bool checking;

  bool get _busy => busyWith != null;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.only(bottom: 24),
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: _InstallCard(
          canChooseFolder: canChooseFolder,
          dropFolderName: dropFolderName,
          busy: _busy,
          onInstallFromFolder: onInstallFromFolder,
          onInstallFromDropFolder: onInstallFromDropFolder,
        ),
      ),
      ListTile(
        leading: checking
            ? const SizedBox.square(
                dimension: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.update),
        title: const Text('Check for updates'),
        subtitle: const Text('Asks every repository what it is offering now'),
        enabled: onCheckForUpdates != null,
        onTap: onCheckForUpdates,
      ),
      const Divider(height: 1),
      for (final extension in extensions)
        _ExtensionTile(
          extension: extension,
          problems: problems[extension.id] ?? 0,
          offered: updates[extension.id],
          busy: busyWith == extension.id,
          anyBusy: _busy,
          onReload: () => onReload(extension),
          onRemove: () => onRemove(extension),
          onUpdate: () => onUpdate(extension),
          onRollBack: () => onRollBack(extension),
          onOpenConsole: () => onOpenConsole(extension.id),
        ),
    ],
  );
}

/// The ways an extension can get in, and a word about what an extension folder is.
class _InstallCard extends StatelessWidget {
  const _InstallCard({
    required this.canChooseFolder,
    required this.dropFolderName,
    required this.busy,
    required this.onInstallFromFolder,
    required this.onInstallFromDropFolder,
  });

  final bool canChooseFolder;
  final String? dropFolderName;
  final bool busy;
  final VoidCallback onInstallFromFolder;
  final VoidCallback onInstallFromDropFolder;

  @override
  Widget build(BuildContext context) {
    final folder = dropFolderName;
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'An extension is a folder holding a manifest.json and a main.js.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            if (canChooseFolder)
              FilledButton.icon(
                onPressed: busy ? null : onInstallFromFolder,
                icon: const Icon(Icons.folder_open),
                label: const Text('Install from a folder'),
              ),
            if (folder != null) ...[
              if (canChooseFolder) const SizedBox(height: 12),
              Text(
                'Or copy the folder into Kikuyomi’s $folder folder in the '
                'Files app, then:',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: busy ? null : onInstallFromDropFolder,
                icon: const Icon(Icons.download_for_offline_outlined),
                label: Text('Install from $folder'),
              ),
            ],
            if (!canChooseFolder && folder == null)
              Text(
                'This device cannot install an extension from a folder yet.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
          ],
        ),
      ),
    );
  }
}

class _ExtensionTile extends StatelessWidget {
  const _ExtensionTile({
    required this.extension,
    required this.problems,
    required this.offered,
    required this.busy,
    required this.anyBusy,
    required this.onReload,
    required this.onRemove,
    required this.onUpdate,
    required this.onRollBack,
    required this.onOpenConsole,
  });

  final ExtensionSummary extension;
  final int problems;

  /// The newer version waiting for it, or null when there is none.
  final String? offered;
  final bool busy;
  final bool anyBusy;
  final VoidCallback onReload;
  final VoidCallback onRemove;
  final VoidCallback onUpdate;
  final VoidCallback onRollBack;
  final VoidCallback onOpenConsole;

  @override
  Widget build(BuildContext context) {
    final row = extension.row;
    return ListTile(
      isThreeLine: true,
      leading: busy
          ? const SizedBox.square(
              dimension: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : ExtensionIcon(extension: extension),
      title: Text('${row.name}  ${row.version}'),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(row.id),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final label in _labels(extension, problems, offered))
                _Chip(label: label.text, warn: label.warn),
            ],
          ),
        ],
      ),
      trailing: _Menu(
        extension: extension,
        offered: offered,
        enabled: !anyBusy,
        onReload: onReload,
        onRemove: onRemove,
        onUpdate: onUpdate,
        onRollBack: onRollBack,
        onOpenConsole: onOpenConsole,
      ),
      onTap: onOpenConsole,
    );
  }

  /// What is worth saying about an extension at a glance, worst first.
  static List<({String text, bool warn})> _labels(
    ExtensionSummary extension,
    int problems,
    String? offered,
  ) => [
    if (!extension.isRunnable)
      (text: 'Could not be read', warn: true)
    else if (extension.row.status == ExtensionStatus.obsolete)
      (text: 'Too old for this app', warn: true),
    // A withdrawal is the publisher saying this version should not be used, which is the most
    // important thing on the tile when it is true.
    if (extension.row.status == ExtensionStatus.revoked)
      (text: 'Withdrawn by its repository', warn: true),
    if (offered != null) (text: 'Update to $offered', warn: false),
    if (problems > 0)
      (text: problems == 1 ? '1 problem' : '$problems problems', warn: true),
    if (extension.isBundled)
      (text: 'Ships with Kikuyomi', warn: false)
    else if (extension.isUnverified)
      (text: 'Unverified', warn: false),
    if (extension.row.originName case final origin?)
      (text: origin, warn: false),
  ];
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.warn});

  final String label;
  final bool warn;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: warn ? colors.errorContainer : colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: warn ? colors.onErrorContainer : colors.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _Menu extends StatelessWidget {
  const _Menu({
    required this.extension,
    required this.offered,
    required this.enabled,
    required this.onReload,
    required this.onRemove,
    required this.onUpdate,
    required this.onRollBack,
    required this.onOpenConsole,
  });

  final ExtensionSummary extension;
  final String? offered;
  final bool enabled;
  final VoidCallback onReload;
  final VoidCallback onRemove;
  final VoidCallback onUpdate;
  final VoidCallback onRollBack;
  final VoidCallback onOpenConsole;

  @override
  Widget build(BuildContext context) => PopupMenuButton<VoidCallback>(
    enabled: enabled,
    tooltip: 'More',
    onSelected: (action) => action(),
    itemBuilder: (context) => [
      if (offered != null)
        PopupMenuItem(value: onUpdate, child: Text('Update to $offered')),
      PopupMenuItem(value: onOpenConsole, child: const Text('What it logged')),
      if (extension.canReload)
        PopupMenuItem(
          value: onReload,
          child: const Text('Reload from its folder'),
        ),
      if (extension.canRollBack)
        PopupMenuItem(
          value: onRollBack,
          child: const Text('Go back to an earlier version'),
        ),
      if (!extension.isBundled)
        PopupMenuItem(value: onRemove, child: const Text('Remove')),
    ],
  );
}

/// Which earlier version to go back to, or null if the listener changed their mind.
///
/// Every version still on disk is offered rather than only the one before, because "the last one"
/// is not always the one that worked: an extension can be broken for two releases running, and a
/// listener who has updated twice since it last worked needs to reach past the middle one.
Future<int?> chooseEarlierVersion(
  BuildContext context,
  ExtensionSummary extension,
) => showDialog<int>(
  context: context,
  builder: (context) => SimpleDialog(
    title: Text('Go back to which version of ${extension.row.name}?'),
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
        child: Text(
          'Nothing is downloaded: these are still on this device from when '
          'they were installed. Your books and progress are not touched.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
      for (final version in extension.earlierVersions)
        SimpleDialogOption(
          onPressed: () => Navigator.of(context).pop(version),
          child: Text('Version code $version'),
        ),
    ],
  ),
);

/// An extension's own icon, or a stand-in for one that has none (§3.3).
///
/// Three cases, and the order matters. An installed extension's icon is a file the install wrote
/// beside its code, so it draws with no network and no unpacking. The one bundled with the app is
/// never installed, so its icon is an app asset. Anything else — an extension published before
/// icons, or a folder an author has not drawn one for yet — gets the puzzle piece, which also says
/// whether the app can run it.
class ExtensionIcon extends StatelessWidget {
  const ExtensionIcon({super.key, required this.extension, this.size = 32});

  final ExtensionSummary extension;
  final double size;

  @override
  Widget build(BuildContext context) {
    final path = extension.iconPath;
    final asset = extension.bundledIconAsset;
    final Widget image;
    if (path != null) {
      image = Image.file(
        File(path),
        width: size,
        height: size,
        // A file that is there but will not decode is a broken icon, not a broken screen.
        errorBuilder: (context, _, _) => _fallback(context),
      );
    } else if (asset != null) {
      image = Image.asset(
        asset,
        width: size,
        height: size,
        errorBuilder: (context, _, _) => _fallback(context),
      );
    } else {
      image = _fallback(context);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(size / 5),
      child: SizedBox.square(dimension: size, child: image),
    );
  }

  Widget _fallback(BuildContext context) => Icon(
    extension.isRunnable
        ? Icons.extension_outlined
        : Icons.extension_off_outlined,
    size: size * 0.75,
  );
}

/// What removing an extension asks first.
///
/// §3.9 keeps the listener's data, and a listener about to remove an extension does not know that. The
/// question says so, so that Remove is not a leap.
Future<bool> confirmRemoveExtension(
  BuildContext context,
  ExtensionSummary extension,
) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove ${extension.row.name}?'),
        content: const Text(
          'Its code is deleted. The books you added from it stay in your '
          'library with their progress, and come back to life if you install '
          'it again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    ) ??
    false;
