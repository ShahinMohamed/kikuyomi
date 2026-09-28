import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikuyomi_data/kikuyomi_data.dart';
import 'package:kikuyomi_domain/kikuyomi_domain.dart';

import 'app_shell.dart';
import 'downloads/downloads_overview.dart';
import 'downloads_view.dart';
import 'providers.dart';
import 'routes.dart';
import 'snack_bars.dart';

/// Downloads: what is on this device and what is being fetched (§5.6).
///
/// A tab of its own rather than a button on the library's app bar. A listener who has queued twenty
/// chapters comes back to this screen repeatedly while they arrive, and that is what a tab is for.
///
/// Everything it shows is watched, so a file that finishes while the screen is open moves by itself
/// (§2.5). The screen's own state is one book id — whichever is being worked on — because deleting a
/// book's files is the one thing here that must not be started twice.
class DownloadsScreen extends ConsumerStatefulWidget {
  const DownloadsScreen({super.key});

  @override
  ConsumerState<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends ConsumerState<DownloadsScreen> {
  int? _busyWith;

  @override
  Widget build(BuildContext context) {
    final downloads = ref.watch(downloadsProvider);
    final rates = ref.watch(downloadRatesProvider).value ?? const {};
    return AppShell(
      tab: AppTab.downloads,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Downloads'),
      ),
      body: downloads.when(
        data: (books) => DownloadsView(
          books: books,
          rates: rates,
          busyWith: _busyWith,
          onOpenBook: (bookId) => BookRoute(bookId: bookId).push<void>(context),
          onPauseBook: _pauseBook,
          onResumeBook: _resumeBook,
          onCancelBook: _cancelBook,
          onRetryBook: _retryBook,
          onRemoveBook: _removeBook,
          onRemoveFile: _removeFile,
          onRetryFile: _retryFile,
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('The downloads could not be read: $error'),
          ),
        ),
      ),
    );
  }

  Future<void> _pauseBook(DownloadedBook book) => _work(book, () async {
    final services = ref.read(servicesProvider);
    for (final task in _tasksOf(book, _pausable)) {
      await services.pauseDownload(task);
    }
  });

  Future<void> _resumeBook(DownloadedBook book) => _work(book, () async {
    final services = ref.read(servicesProvider);
    for (final task in _tasksOf(book, {DownloadState.paused})) {
      await services.resumeDownload(task);
    }
  });

  Future<void> _cancelBook(DownloadedBook book) => _work(book, () async {
    final services = ref.read(servicesProvider);
    for (final task in _tasksOf(book, _stoppable)) {
      await services.cancelDownload(task);
    }
  });

  Future<void> _retryBook(DownloadedBook book) => _work(book, () async {
    final services = ref.read(servicesProvider);
    for (final task in _tasksOf(book, _failed)) {
      await services.retryDownload(task);
    }
  });

  /// Takes a book off the screen entirely: stops what is going, deletes what arrived, clears the rows.
  ///
  /// Asked about only when there is something to lose. Throwing away files the listener waited for is
  /// worth a question, and the message says how much room it frees, which is the number they are
  /// deciding on; clearing away rows for files that were cancelled or never arrived is not, and a
  /// dialog there would be a question with one sensible answer.
  Future<void> _removeBook(DownloadedBook book) async {
    if (book.hasFilesOnDevice) {
      final confirmed = await _confirm(
        title: 'Delete the downloaded files?',
        message:
            '${book.title} will be removed from this device and will need the '
            'network again. ${_freed(book.bytesOnDevice)}',
      );
      if (!confirmed) return;
    }
    await _work(book, () async {
      final gone = await ref
          .read(servicesProvider)
          .removeBookDownloads(book.bookId);
      if (gone.kept > 0) {
        _tell(
          '${gone.kept} of ${book.filesOnDevice} files are in use — stop '
          'playing the book and try again.',
        );
      } else if (gone.deleted > 0) {
        _tell('Deleted ${book.title}.');
      }
    });
  }

  /// The same for one file. No question asked: it is one file, and asking for it again is a tap.
  Future<void> _removeFile(DownloadEntry entry) => _work(
    entry,
    () => ref.read(servicesProvider).removeDownload(entry.mediaFileId),
    bookId: entry.bookId,
  );

  Future<void> _retryFile(DownloadEntry entry) => _work(
    entry,
    () => ref.read(servicesProvider).retryDownload(entry.task.id),
    bookId: entry.bookId,
  );

  /// Runs [action] with the book marked busy, and turns whatever it throws into a sentence.
  ///
  /// A file the player still has open is the failure worth naming: Windows refuses to delete it, and
  /// "stop playing it first" is something the listener can act on, where the system's own message is
  /// a path and an error number.
  Future<void> _work(
    Object owner,
    Future<void> Function() action, {
    int? bookId,
  }) async {
    final id = bookId ?? (owner as DownloadedBook).bookId;
    if (_busyWith != null) return;
    setState(() => _busyWith = id);
    try {
      await action();
    } on PathAccessException {
      _tell('That file is in use. Stop playing the book and try again.');
    } on FileSystemException catch (error) {
      _tell(error.message);
    } catch (error) {
      _tell('$error');
    } finally {
      if (mounted) setState(() => _busyWith = null);
    }
  }

  Future<bool> _confirm({
    required String title,
    required String message,
  }) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Keep them'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        ),
      ) ??
      false;

  String _freed(int bytes) =>
      bytes == 0 ? '' : 'That frees ${formatBytes(bytes)}.';

  void _tell(String message) {
    if (!mounted) return;
    tellInSnackBar(ScaffoldMessenger.of(context), message);
  }
}

/// The tasks of [book] in any of [states], which is how a per-book action reaches the files under it.
List<int> _tasksOf(DownloadedBook book, Set<DownloadState> states) => [
  for (final file in book.files)
    if (states.contains(file.task.state)) file.task.id,
];

/// What §5.3 lets the listener pause: everything on its way that has not finished arriving.
const _pausable = {
  DownloadState.downloading,
  DownloadState.waiting,
  DownloadState.queued,
};

/// What is worth telling to stop. Cancelling from anywhere unfinished is allowed (§5.3), and a task
/// already cancelled or finished has nothing to stop.
const _stoppable = {
  DownloadState.queued,
  DownloadState.needsResolve,
  DownloadState.resolving,
  DownloadState.downloading,
  DownloadState.processing,
  DownloadState.waiting,
  DownloadState.paused,
};

const _failed = {DownloadState.failedRetryable, DownloadState.failedPermanent};
