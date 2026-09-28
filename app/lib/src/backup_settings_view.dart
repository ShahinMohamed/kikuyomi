import 'package:flutter/material.dart';

import 'backup_text.dart';

/// Where backups go, as Settings shows it.
sealed class BackupFolderState {
  const BackupFolderState();
}

/// This device cannot keep access to a folder it chooses yet, so it cannot back up to one.
final class BackupFoldersUnsupported extends BackupFolderState {
  const BackupFoldersUnsupported();
}

/// No backup folder has been chosen.
final class NoBackupFolder extends BackupFolderState {
  const NoBackupFolder();
}

/// A folder is chosen, and whether it can still be reached is being checked.
final class BackupFolderChecking extends BackupFolderState {
  const BackupFolderChecking(this.name);

  final String name;
}

/// A folder is chosen, and can be reached.
final class BackupFolderReady extends BackupFolderState {
  const BackupFolderReady(this.name);

  final String name;
}

/// A folder is chosen, but can no longer be reached, for [reason]. Choosing it again fixes this.
final class BackupFolderLost extends BackupFolderState {
  const BackupFolderLost(this.name, this.reason);

  final String name;
  final String reason;
}

/// Settings' Backup section: the folder backups go to, when the last one was written, and backing up
/// or restoring by hand.
///
/// Fed with data rather than watching providers, so it can be tested without a database.
class BackupSettingsView extends StatelessWidget {
  const BackupSettingsView({
    super.key,
    required this.folder,
    required this.lastBackupAt,
    this.lastProblem,
    this.backingUp = false,
    required this.libraryIsEmpty,
    required this.onChooseFolder,
    required this.onBackUpNow,
    required this.onRestore,
    this.sections = const [],
  });

  final BackupFolderState folder;

  /// When the last backup was written, or null for never.
  final DateTime? lastBackupAt;

  /// What went wrong with the last backup, if it failed.
  final String? lastProblem;

  /// Whether a backup asked for by hand is being written.
  final bool backingUp;

  /// Whether the library is empty, in which case a restore has nothing to merge with and needs no
  /// warning.
  final bool libraryIsEmpty;

  final VoidCallback onChooseFolder;
  final VoidCallback onBackUpNow;

  /// Called once the listener has confirmed they want to restore, where confirming is needed.
  final VoidCallback onRestore;

  /// What Settings holds besides backups, shown under it. The screen owns one scrolling list, and
  /// this is how the rest of it gets in without every section having to know about the others.
  final List<Widget> sections;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final folder = this.folder;
    final lastBackupAt = this.lastBackupAt;
    final canBackUp =
        !backingUp &&
        (folder is BackupFolderReady || folder is BackupFolderChecking);
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        const _Heading('Backup'),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            'Kikuyomi backs up your library and listening progress to a '
            'folder you choose, a few minutes after changes and whenever you '
            'leave the app, so they survive reinstalling it.',
            style: theme.textTheme.bodyMedium,
          ),
        ),
        if (folder is BackupFoldersUnsupported)
          const ListTile(
            leading: Icon(Icons.cloud_off_outlined),
            title: Text('Not available on this device yet'),
            subtitle: Text(
              'Keeping access to a folder you choose is not supported here '
              'yet, so backups cannot be written.',
            ),
          )
        else ...[
          ListTile(
            leading: const Icon(Icons.folder_outlined),
            title: const Text('Backup folder'),
            subtitle: Text(switch (folder) {
              BackupFolderChecking(:final name) ||
              BackupFolderReady(:final name) ||
              BackupFolderLost(:final name) => name,
              _ => 'Not chosen yet',
            }),
            trailing: TextButton(
              onPressed: onChooseFolder,
              child: Text(
                folder is NoBackupFolder ? 'Choose folder' : 'Change folder',
              ),
            ),
          ),
          if (folder case BackupFolderLost(:final reason))
            _Problem(
              message:
                  'The backup folder can no longer be reached: $reason. Choose '
                  'it again, or another folder, to keep backing up.',
              action: FilledButton.tonal(
                onPressed: onChooseFolder,
                child: const Text('Choose it again'),
              ),
            ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Last backup'),
            subtitle: Text(
              lastBackupAt == null
                  ? 'Never'
                  : formatBackupTime(context, lastBackupAt),
            ),
          ),
          if (lastProblem case final problem? when folder is! BackupFolderLost)
            _Problem(message: problem),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: canBackUp ? onBackUpNow : null,
                  icon: backingUp
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.backup_outlined),
                  label: const Text('Back up now'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _restore(context),
                  icon: const Icon(Icons.restore),
                  label: const Text('Restore from a backup'),
                ),
              ],
            ),
          ),
        ],
        ...sections,
      ],
    );
  }

  /// Restoring merges into the library. Into one in use, the listener is told first what that means.
  Future<void> _restore(BuildContext context) async {
    if (libraryIsEmpty) {
      onRestore();
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore from a backup?'),
        content: const Text(
          'A restore never removes anything from your library, and keeps '
          'whichever progress is newer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) onRestore();
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        text,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

/// Something wrong with backing up, set apart so it is not missed.
class _Problem extends StatelessWidget {
  const _Problem({required this.message, this.action});

  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final action = this.action;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message, style: TextStyle(color: colors.onErrorContainer)),
          if (action != null) ...[const SizedBox(height: 8), action],
        ],
      ),
    );
  }
}
