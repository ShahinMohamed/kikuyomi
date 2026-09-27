import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikuyomi_backup/kikuyomi_backup.dart';
import 'package:kikuyomi_data/kikuyomi_data.dart';
import 'package:kikuyomi_domain/kikuyomi_domain.dart';
import 'package:kikuyomi_playback/kikuyomi_playback.dart';

import 'downloads/book_downloads.dart';
import 'history/listening_history_days.dart';
import 'downloads/downloads_overview.dart';
import 'services.dart';
import 'setup_gate.dart';
import 'sources/extension_console.dart';
import 'sources/extension_library.dart';
import 'sources/source_gateway.dart';
import 'sources/source_registry.dart';

/// Supplied by `main()` once the database and engine are open.
final servicesProvider = Provider<AppServices>(
  (ref) => throw UnimplementedError('AppServices is provided by main()'),
);

/// Every source the app offers, from manifests alone (§3.6). Reading it runs no extension code.
final sourceRegistryProvider = Provider<SourceRegistry>(
  (ref) => ref.watch(servicesProvider).sources,
);

/// Every source the app offers, and the list again after every install and removal.
///
/// A [Provider] would not do: installing an extension adds sources while a screen is open, and §2.5
/// has screens follow what changes rather than hold a copy of it. The current list comes first, so a
/// screen shows the sources in its first frame.
final sourceListProvider = StreamProvider<List<SourceDescription>>((ref) {
  final gateway = ref.watch(sourceGatewayProvider);
  return Stream<List<SourceDescription>>.multi((controller) {
    controller.add(gateway.sources);
    final subscription = gateway.sourceChanges.listen(
      controller.add,
      onError: controller.addError,
    );
    controller.onCancel = subscription.cancel;
  });
});

/// Every extension the app knows about, watched, for the Extensions screen (§3.9).
final extensionsProvider = StreamProvider<List<ExtensionSummary>>(
  (ref) => ref.watch(servicesProvider).extensions.watch(),
);

/// What is in the extension console (§3.5), and its contents again after every line.
///
/// The console keeps its lines in memory rather than in the database, so this reads them on every
/// signal rather than watching a query.
final extensionConsoleProvider = StreamProvider<List<ExtensionLogLine>>((ref) {
  final console = ref.watch(servicesProvider).extensionConsole;
  return Stream<List<ExtensionLogLine>>.multi((controller) {
    controller.add(console.lines);
    final subscription = console.changes.listen(
      (_) => controller.add(console.lines),
      onError: controller.addError,
    );
    controller.onCancel = subscription.cancel;
  });
});

/// What the Browse screens reach the sources through. Overridden in a widget test with a fake
/// source, which is how those screens are tested without a database, an engine or a network.
final sourceGatewayProvider = Provider<SourceGateway>(
  (ref) => AppSourceGateway(ref.watch(servicesProvider)),
);

/// The library, straight from the database. §2.6: screens watch Drift streams rather than holding
/// copies, so an import appears without anything being refreshed.
final libraryProvider = StreamProvider<List<BookRow>>((ref) {
  final db = ref.watch(servicesProvider).database;
  return (db.select(db.books)
        ..where((b) => b.inLibrary.equals(true))
        ..orderBy([(b) => OrderingTerm.desc(b.dateAdded)]))
      .watch();
});

final bookProvider = StreamProvider.family<BookRow?, int>((ref, bookId) {
  final db = ref.watch(servicesProvider).database;
  return (db.select(
    db.books,
  )..where((b) => b.id.equals(bookId))).watchSingleOrNull();
});

/// The coordinator's state, starting from its current value so a screen opened mid-playback does not
/// wait for the next change to show anything.
final playerStateProvider = StreamProvider<PlayerState>((ref) {
  final coordinator = ref.watch(servicesProvider).coordinator;
  return Stream<PlayerState>.multi((controller) {
    controller.add(coordinator.state);
    final subscription = coordinator.states.listen(
      controller.add,
      onError: controller.addError,
    );
    controller.onCancel = subscription.cancel;
  });
});

/// Continue Listening, straight from the database: the started, unfinished books in the library,
/// most recently played first. It emits again on every progress save, so a book's place on the
/// shelf keeps up while it plays.
final continueListeningProvider = StreamProvider<List<ContinueListeningBook>>(
  (ref) => watchContinueListening(ref.watch(servicesProvider).database),
);

/// Whether backup setup is offered at start. The router redirects by it.
final setupGateProvider = Provider<SetupGate>((ref) {
  final gate = SetupGate();
  ref.onDispose(gate.dispose);
  return gate;
});

/// Whether the reminder to choose a backup folder was put off with "Not now". Kept only in memory,
/// so the reminder comes back at the next start: it stays on the home until a folder is chosen.
final backupReminderPutOffProvider =
    NotifierProvider<BackupReminderPutOff, bool>(BackupReminderPutOff.new);

class BackupReminderPutOff extends Notifier<bool> {
  @override
  bool build() => false;

  void putOff() => state = true;
}

/// The folder backups go to, or null before one is chosen, from settings.
final backupFolderProvider = StreamProvider<UserFolder?>(
  (ref) => ref.watch(servicesProvider).backups.watchFolder(),
);

/// Whether the backup folder can still be reached, or null while none is chosen. Checked afresh
/// whenever a screen that shows it opens.
final backupFolderStatusProvider = FutureProvider.autoDispose<FolderStatus?>((
  ref,
) async {
  final folder = await ref.watch(backupFolderProvider.future);
  return folder?.checkAccess();
});

/// When the last backup was written, or null for never.
final lastBackupProvider = StreamProvider<DateTime?>(
  (ref) => ref.watch(servicesProvider).backups.watchLastBackup(),
);

/// How the last backup went, since the app started, and each one after.
final lastBackupOutcomeProvider = StreamProvider<BackupOutcome?>((ref) {
  final scheduler = ref.watch(servicesProvider).backupScheduler;
  return Stream<BackupOutcome?>.multi((controller) {
    controller.add(scheduler.lastOutcome);
    final subscription = scheduler.outcomes.listen(controller.add);
    controller.onCancel = subscription.cancel;
  });
});

/// What the source a book came from is called, for a message about a failure at it.
///
/// A streamed book fails with one of the contract's error kinds, and those messages are written
/// around the source's name (§3.4). Disposed once nothing shows it.
final bookSourceNameProvider = FutureProvider.autoDispose.family<String, int>((
  ref,
  bookId,
) async {
  final db = ref.watch(servicesProvider).database;
  final book = await (db.select(
    db.books,
  )..where((b) => b.id.equals(bookId))).getSingleOrNull();
  if (book == null) return 'This source';
  return ref.watch(sourceGatewayProvider).nameOf(book.sourceId);
});

/// A book's details, straight from the database. Disposed once no screen shows the book, so a
/// details screen visited once does not keep its queries running for the life of the app.
final bookOverviewProvider = StreamProvider.autoDispose
    .family<BookOverview?, int>(
      (ref, bookId) =>
          watchBookOverview(ref.watch(servicesProvider).database, bookId),
    );

/// How far a book's download has got, watched, so a progress bar follows the queue without anything
/// being refreshed (§2.5). Disposed once no screen shows the book.
/// Where each chapter of a book stands, for the arrows on its details screen (§5.2).
///
/// Its own provider rather than part of `bookOverviewProvider`: the overview changes when the book
/// does, and this changes on every byte of progress, so joining them would rebuild the header,
/// the description and the credits a few times a second while something downloads.
final chapterDownloadsProvider = StreamProvider.autoDispose
    .family<Map<int, ChapterDownload>, int>(
      (ref, bookId) =>
          watchChapterDownloads(ref.watch(servicesProvider).database, bookId),
    );

final bookDownloadsProvider = StreamProvider.autoDispose
    .family<BookDownloads, int>(
      (ref, bookId) => watchBookDownloads(
        ref.watch(servicesProvider).database,
        bookId,
      ).map(summariseDownloads),
    );

/// Everything the download system is holding or fetching, grouped by book, watched (§5.6).
///
/// Not disposed with the screen: the same stream answers whether there is anything to show at all,
/// and it is one query over a table that is nearly always small.
final downloadsProvider = StreamProvider<List<DownloadedBook>>(
  (ref) =>
      watchDownloads(ref.watch(servicesProvider).database).map(groupDownloads),
);

/// How fast each download is moving, by task id, sampled once a second (§5.2).
///
/// A stream on a timer rather than a watched query, because a speed is not written down: it is a
/// property of the last few seconds and putting it in the database would churn a table every open
/// screen is watching. Disposed with the last screen that shows one, so nothing ticks when nobody is
/// looking.
final downloadRatesProvider = StreamProvider.autoDispose<Map<int, double>>((
  ref,
) {
  final services = ref.watch(servicesProvider);
  return Stream<Map<int, double>>.multi((controller) {
    void emit() =>
        controller.add(services.downloads.rates.snapshot(services.clock.now()));
    emit();
    final timer = Timer.periodic(const Duration(seconds: 1), (_) => emit());
    controller.onCancel = timer.cancel;
  });
});

/// What has been listened to, grouped by day, newest first (§6.4).
///
/// `listening_session` has been recorded since the coordinator learned to, and nothing ever read it
/// back until the History screen. The grouping is done here rather than in the view so the view takes
/// finished data, and `now` is read once per emission so "Today" is right for the day the listener is
/// actually having.
final listeningHistoryProvider = StreamProvider<List<HistoryDay>>((ref) {
  final services = ref.watch(servicesProvider);
  return watchListeningHistory(services.database)
      .map((entries) => groupHistoryByDay(entries, now: services.clock.now()));
});

/// The order the library is shown in, so a shelf stays as the listener left it (§2.6).
///
/// Straight from the settings store, which reads it now and again after every write, so choosing an
/// order redraws the shelf without anything being refreshed. A value this build does not know reads
/// as not set, which is what lets an older build open a library a newer one ordered some way it has
/// never heard of.
final librarySortProvider = StreamProvider<LibrarySort>(
  (ref) => ref
      .watch(servicesProvider)
      .settings
      .watch(AppSettings.librarySort)
      .map((sort) => sort ?? LibrarySort.fallback),
);

/// The sources pinned to the top of Browse, watched, so pinning one moves it at once.
final pinnedSourcesProvider = StreamProvider<List<int>>(
  (ref) => ref
      .watch(servicesProvider)
      .settings
      .watch(AppSettings.pinnedSources)
      .map((ids) => ids ?? const []),
);

/// The sources most recently browsed, most recent first.
final recentSourcesProvider = StreamProvider<List<int>>(
  (ref) => ref
      .watch(servicesProvider)
      .settings
      .watch(AppSettings.recentSources)
      .map((ids) => ids ?? const []),
);

/// Every installed extension by its id, so a source's row can find the one it came from (§3.3).
///
/// Summaries rather than icon paths: the extension bundled with the app has no install path, and so
/// no icon file, but it does have an icon -- an app asset. `ExtensionIcon` already knows how to
/// choose between the two, and handing it the summary is what lets the sources list reuse that
/// instead of a second, worse copy that only understood files.
final extensionsByIdProvider = Provider<Map<String, ExtensionSummary>>((ref) {
  final extensions = ref.watch(extensionsProvider).value ?? const [];
  return {for (final extension in extensions) extension.id: extension};
});

/// The repositories the listener has added, watched, so the screen follows an add or a removal
/// (§3.8). What each one offers is not here: a listing is fetched rather than stored.
final repositoriesProvider = StreamProvider<List<RepositoryRow>>(
  (ref) => ref.watch(servicesProvider).repositories.watch(),
);

/// A book's bookmarks in playing order, straight from the database, so one added, changed or
/// deleted shows at once. Disposed once no screen shows them.
final bookmarksProvider = StreamProvider.autoDispose
    .family<List<BookmarkOverview>, int>(
      (ref, bookId) =>
          watchBookmarks(ref.watch(servicesProvider).database, bookId),
    );
