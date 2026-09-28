import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikuyomi_backup/kikuyomi_backup.dart';
import 'package:kikuyomi_domain/kikuyomi_domain.dart';

import 'backup_actions.dart';
import 'backup_settings_view.dart';
import 'backup_text.dart';
import 'providers.dart';
import 'reading/reading_settings_section.dart';
import 'routes.dart';

/// Settings, reached from More through [SettingsRoute]: backups, and how fast you read.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  var _backingUp = false;

  @override
  Widget build(BuildContext context) {
    // A backup that failed may be why the folder can no longer be reached, so it is checked again.
    ref.listen(
      lastBackupOutcomeProvider,
      (_, _) => ref.invalidate(backupFolderStatusProvider),
    );
    final services = ref.watch(servicesProvider);
    final folder = ref.watch(backupFolderProvider).value;
    final status = ref.watch(backupFolderStatusProvider);
    final outcome = ref.watch(lastBackupOutcomeProvider).value;
    final libraryIsEmpty = ref.watch(libraryProvider).value?.isEmpty ?? true;

    final BackupFolderState folderState;
    if (!services.backups.canChooseFolder) {
      folderState = const BackupFoldersUnsupported();
    } else if (folder == null) {
      folderState = const NoBackupFolder();
    } else {
      folderState = switch (status.value) {
        FolderReachable() => BackupFolderReady(folder.displayName),
        FolderUnreachable(:final reason) => BackupFolderLost(
          folder.displayName,
          reason,
        ),
        null => BackupFolderChecking(folder.displayName),
      };
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: BackupSettingsView(
        folder: folderState,
        lastBackupAt: ref.watch(lastBackupProvider).value,
        lastProblem: switch (outcome) {
          null || BackupWritten() || BackupNotConfigured() => null,
          final failed => describeBackupOutcome(failed),
        },
        backingUp: _backingUp,
        libraryIsEmpty: libraryIsEmpty,
        onChooseFolder: () =>
            chooseBackupFolder(context, ref, backUpAfter: !libraryIsEmpty),
        onBackUpNow: _backUpNow,
        onRestore: () => const RestoreRoute().push<void>(context),
        sections: [
          ReadingSettingsSection(
            wordsPerMinute:
                ref.watch(readingWordsPerMinuteProvider).value ??
                defaultReadingWordsPerMinute,
            onChanged: (rate) => ref
                .read(servicesProvider)
                .settings
                .write(AppSettings.readingWordsPerMinute, rate),
          ),
        ],
      ),
    );
  }

  Future<void> _backUpNow() async {
    setState(() => _backingUp = true);
    try {
      await backUpNow(
        ref.read(servicesProvider),
        ScaffoldMessenger.of(context),
      );
    } finally {
      if (mounted) setState(() => _backingUp = false);
    }
  }
}
