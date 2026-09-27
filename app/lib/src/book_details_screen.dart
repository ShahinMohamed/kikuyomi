import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kikuyomi_data/kikuyomi_data.dart'
    show removeBookFromLibrary, watchBookDownloads;

import 'book_details_view.dart';
import 'downloads/book_downloads.dart';
import 'listened_commands.dart';
import 'open_book.dart';
import 'providers.dart';
import 'routes.dart';
import 'services.dart';
import 'snack_bars.dart';

/// A book's details, watched from the database, so progress saved while the book plays shows here
/// on returning from the player without anything being refreshed. Reached through [BookRoute].
class BookDetailsScreen extends ConsumerWidget {
  const BookDetailsScreen({super.key, required this.bookId});

  final int bookId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overview = ref.watch(bookOverviewProvider(bookId));
    final downloads =
        ref.watch(bookDownloadsProvider(bookId)).value ?? BookDownloads.none;
    final chapterDownloads =
        ref.watch(chapterDownloadsProvider(bookId)).value ?? const {};
    final book = overview.value;
    return Scaffold(
      appBar: AppBar(),
      // The one thing every visit is for, kept where a thumb reaches it rather than in a row of
      // outlined buttons where it looked like one option among four.
      floatingActionButton: book == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => openBookInPlayer(
                context,
                ref,
                bookId,
                fromStart: playButtonFrom(book) == PlayFrom.start,
              ),
              icon: const Icon(Icons.play_arrow),
              label: Text(playButtonLabel(book)),
            ),
      body: overview.when(
        data: (book) => book == null
            ? const Center(child: Text('This book is no longer available'))
            : BookDetailsView(
                book: book,
                covers: ref.watch(servicesProvider).covers,
                onRemove: () => _remove(context, ref, book.title),
                onOpenAtSource: book.webUrl == null
                    ? null
                    : () => _openAtSource(context, book.webUrl!),
                listenedCommands: _listenedCommands(
                  ref.watch(servicesProvider),
                ),
                downloads: downloads,
                chapterDownloads: chapterDownloads,
                onDownload: () => _download(context, ref),
                onStopDownloading: () => _stopDownloading(ref),
                onPlayChapter: (chapterId) =>
                    _playFrom(context, ref, chapterId),
                onDownloadChapters: (chapterIds) =>
                    _downloadChapters(context, ref, chapterIds),
                onRefresh: book.canRefresh
                    ? () => _refresh(context, ref)
                    : null,
                onOpenDownloadQueue: () =>
                    const DownloadsRoute().push<void>(context),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('Could not load the book: $error')),
      ),
    );
  }

  /// Opens the book and starts it at the beginning of [chapterId].
  ///
  /// Opening first and moving afterwards, rather than opening at a position: the book has to be
  /// loaded before anything knows where that chapter begins, and the Timeline that answers is the
  /// coordinator's own.
  Future<void> _playFrom(
    BuildContext context,
    WidgetRef ref,
    int chapterId,
  ) async {
    final services = ref.read(servicesProvider);
    try {
      await services.openBook(bookId);
      await services.coordinator.goToChapter(chapterId);
      if (context.mounted) await const PlayerRoute().push<void>(context);
    } catch (error) {
      if (context.mounted) {
        tellInSnackBar(
          ScaffoldMessenger.of(context),
          'Could not open the book: $error',
        );
      }
    }
  }

  /// Queues [chapterIds], and says what that came to in files.
  ///
  /// Files, not chapters, because that is what was queued: ten chapters of an M4B are one file, and
  /// telling a listener ten downloads had started would have nine of them never appear.
  Future<void> _downloadChapters(
    BuildContext context,
    WidgetRef ref,
    List<int> chapterIds,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    if (chapterIds.isEmpty) {
      tellInSnackBar(messenger, 'Nothing left to download');
      return;
    }
    try {
      final asked = await ref
          .read(servicesProvider)
          .downloadChapters(chapterIds);
      if (asked.added > 0) {
        tellInSnackBar(
          messenger,
          asked.added == 1
              ? 'Downloading one file'
              : 'Downloading ${asked.added} files',
        );
      } else if (asked.alreadyOnDevice > 0 && asked.alreadyQueued == 0) {
        tellInSnackBar(messenger, 'Already on this device');
      } else {
        tellInSnackBar(messenger, 'Already downloading');
      }
    } catch (error) {
      tellInSnackBar(messenger, 'Could not start the download: $error');
    }
  }

  /// Asks the source for the book again, and says what changed.
  ///
  /// Pulled down on the book's own page, which is where a listener wonders whether a serial has
  /// published since they last looked. Saying "no new chapters" matters as much as saying there
  /// are: a refresh that answers nothing looks like a refresh that did not happen.
  Future<void> _refresh(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final added = await ref
          .read(servicesProvider)
          .refreshBookFromSource(bookId);
      tellInSnackBar(messenger, switch (added) {
        0 => 'No new chapters',
        1 => '1 new chapter',
        _ => '$added new chapters',
      });
    } on StateError catch (error) {
      tellInSnackBar(messenger, error.message);
    } catch (error) {
      tellInSnackBar(messenger, 'Could not refresh: $error');
    }
  }

  /// Opens the book's page at its source in a browser.
  ///
  /// Outside the app rather than in a view of our own: §3.4 lets a source hand back any page it
  /// likes, and the browser is where a listener already trusts their sign-ins and their blocker.
  Future<void> _openAtSource(BuildContext context, String webUrl) async {
    final messenger = ScaffoldMessenger.of(context);
    final url = Uri.tryParse(webUrl);
    if (url == null ||
        !await launchUrl(url, mode: LaunchMode.externalApplication)) {
      tellInSnackBar(messenger, 'That page could not be opened.');
    }
  }

  /// Asks for every file of the book that is not already here, and says what that came to.
  ///
  /// A book whose files are all on the device already — a local one, or one downloaded before — is
  /// worth saying so about rather than leaving the button to do nothing.
  Future<void> _download(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final asked = await ref.read(servicesProvider).downloadBook(bookId);
      if (asked.added > 0) {
        tellInSnackBar(
          messenger,
          asked.added == 1
              ? 'Downloading one file'
              : 'Downloading ${asked.added} files',
        );
      } else if (asked.alreadyOnDevice == asked.total && asked.total > 0) {
        tellInSnackBar(messenger, 'Every file is already on this device');
      } else {
        tellInSnackBar(messenger, 'Already downloading');
      }
    } catch (error) {
      tellInSnackBar(messenger, 'Could not start the download: $error');
    }
  }

  /// Gives up on whatever of this book is queued or running.
  Future<void> _stopDownloading(WidgetRef ref) async {
    final services = ref.read(servicesProvider);
    final tasks = await watchBookDownloads(services.database, bookId).first;
    for (final task in tasks) {
      if (!task.state.isFinished) await services.cancelDownload(task.id);
    }
  }

  /// Marks made in the database through [AppServices], which tells the player too, so a book open
  /// there agrees about being finished. The details update by themselves, since they watch the
  /// database.
  ListenedCommands _listenedCommands(AppServices services) => ListenedCommands(
    markChapters: (chapterIds, listened) =>
        services.markChaptersListened(bookId, chapterIds, listened: listened),
    markFinished: () => services.markBookFinished(bookId),
    markNotFinished: () => services.markBookNotFinished(bookId),
  );

  /// Takes the book out of the library and leaves its details, since there is nothing more to do
  /// with it here. A book that is playing carries on playing.
  Future<void> _remove(
    BuildContext context,
    WidgetRef ref,
    String title,
  ) async {
    final services = ref.read(servicesProvider);
    // The app's messenger outlives this screen, so the message survives leaving it.
    final messenger = ScaffoldMessenger.of(context);
    try {
      await removeBookFromLibrary(
        services.database,
        bookId,
        clock: services.clock,
      );
      tellInSnackBar(messenger, 'Removed $title from the library');
      if (context.mounted) {
        // A screen opened straight at its location may have nothing beneath it to return to.
        if (context.canPop()) {
          context.pop();
        } else {
          const HomeRoute().go(context);
        }
      }
    } catch (error) {
      tellInSnackBar(messenger, 'Could not remove the book: $error');
    }
  }
}
