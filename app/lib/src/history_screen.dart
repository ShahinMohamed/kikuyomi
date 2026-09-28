import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikuyomi_data/kikuyomi_data.dart';

import 'app_shell.dart';
import 'history_view.dart';
import 'providers.dart';
import 'routes.dart';
import 'snack_bars.dart';

/// History: what has been listened to and when (§6.4).
///
/// A tab of its own. It was reached through the library's app bar, which is the wrong place for it
/// twice over: it is not about the library, and an app bar changes as you move around, so a button
/// in one is somewhere to be found rather than somewhere known. What a listener has been listening
/// to is something they come back to directly.
///
/// Everything is watched, so a stretch recorded while the screen is open appears without a refresh
/// (§2.5). Deleting is the only thing it does besides show, and it offers the two scopes a listener
/// actually wants: this one, or everything for this book.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(listeningHistoryProvider);
    final covers = ref.watch(servicesProvider).covers;

    return AppShell(
      tab: AppTab.history,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('History'),
        actions: [
          if ((history.value ?? const []).isNotEmpty)
            PopupMenuButton<VoidCallback>(
              tooltip: 'What to do with the history',
              onSelected: (action) => action(),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: () => _clearAll(context, ref),
                  child: const Text('Clear all history'),
                ),
              ],
            ),
        ],
      ),
      body: history.when(
        data: (days) => HistoryView(
          days: days,
          coverOf: covers.fileOf,
          onOpenBook: (entry) =>
              BookRoute(bookId: entry.bookId).push<void>(context),
          onRemove: (entry) => _remove(context, ref, entry),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('The history could not be read: $error'),
          ),
        ),
      ),
    );
  }

  /// Offers the two scopes worth offering, which is how Mihon asks the same question.
  ///
  /// One entry is the common case, and "everything for this book" is what a listener wants after
  /// scrubbing through something and leaving a dozen rows behind. Neither touches the book, and
  /// neither touches progress: history is a record of when something was heard, not of having heard
  /// it, and that distinction is worth saying out loud in the dialog.
  Future<void> _remove(
    BuildContext context,
    WidgetRef ref,
    HistoryEntry entry,
  ) async {
    final scope = await showDialog<_RemoveScope>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove from history?'),
        content: Text(
          'This does not remove ${entry.bookTitle} or lose your place in it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(_RemoveScope.book),
            child: const Text('All of this book'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(_RemoveScope.entry),
            child: const Text('This entry'),
          ),
        ],
      ),
    );
    if (scope == null || !context.mounted) return;

    final database = ref.read(servicesProvider).database;
    final messenger = ScaffoldMessenger.of(context);
    switch (scope) {
      case _RemoveScope.entry:
        await deleteHistoryEntry(database, entry.sessionId);
      case _RemoveScope.book:
        final gone = await deleteBookHistory(database, entry.bookId);
        tellInSnackBar(
          messenger,
          gone == 1
              ? 'Removed one entry for ${entry.bookTitle}.'
              : 'Removed $gone entries for ${entry.bookTitle}.',
        );
    }
  }

  Future<void> _clearAll(BuildContext context, WidgetRef ref) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Clear all history?'),
            content: const Text(
              'Every entry goes. Your books, your places in them and what you '
              'have marked as listened all stay.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Keep it'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Clear'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final gone = await clearListeningHistory(
      ref.read(servicesProvider).database,
    );
    tellInSnackBar(messenger, 'Cleared $gone entries.');
  }
}

/// How much to forget.
enum _RemoveScope { entry, book }
