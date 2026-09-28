import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:kikuyomi_backup/kikuyomi_backup.dart';
import 'package:kikuyomi_data/kikuyomi_data.dart';
// Named apart, because AppServices has methods of the same names that also tell the player.
import 'package:kikuyomi_data/kikuyomi_data.dart'
    as data
    show markBookFinished, markBookNotFinished;
import 'package:kikuyomi_domain/kikuyomi_domain.dart';
import 'package:kikuyomi_downloads/kikuyomi_downloads.dart';
import 'package:kikuyomi_extension_manager/kikuyomi_extension_manager.dart';
import 'package:kikuyomi_networking/kikuyomi_networking.dart' as net;
import 'package:kikuyomi_platform_adapters/kikuyomi_platform_adapters.dart';
import 'package:kikuyomi_playback/kikuyomi_playback.dart';
// Named apart: the app's own BookDetails and the contract's are different model layers (§4.1).
import 'package:kikuyomi_source_api/kikuyomi_source_api.dart' as api;
import 'package:kikuyomi_source_runtime/kikuyomi_source_runtime.dart';
import 'package:kikuyomi_sources_builtin/kikuyomi_sources_builtin.dart';

import 'app_version.dart';
import 'book_files.dart';
import 'reading/chapter_texts.dart';
import 'sources/drift_extension_store.dart';
import 'sources/extension_console.dart';
import 'sources/extension_library.dart';
import 'sources/first_run.dart';
import 'sources/repository_library.dart';
import 'sources/source_registry.dart';

/// The composition root (§2.8): the one place concrete implementations are chosen and wired
/// together. Everything below the app works against interfaces.
final class AppServices {
  AppServices._({
    required this.database,
    required this.coordinator,
    required this.clock,
    required this.locations,
    required this.settings,
    required this.backups,
    required this.backupScheduler,
    required this.playable,
    required this.extensions,
    required this.repositories,
    required this.streamCache,
    required this.downloads,
    required this.downloadFiles,
    required this.deviceId,
  }) : covers = CoverFiles(locations.covers),
       _importFolder = ImportFolder(mediaRoot: locations.mediaRoot);

  static Future<AppServices> open() async {
    final locations = await StorageLocations.forThisDevice();
    final settings = await SharedPreferencesSettingsStore.open();
    final database = KikuyomiDatabase(
      // §2.7: the database runs in a background isolate, so queries never block a frame.
      NativeDatabase.createInBackground(
        File(_join(locations.appData.path, 'kikuyomi.sqlite')),
      ),
    );
    const clock = SystemClock();
    await _backfillListened(database, settings);
    final deviceId = await _deviceId(locations.appData);
    final audioFocus = await AudioFocus.configure();
    // §2.7's one NetworkService, which owns the cookie jars and the rate limiters, and decides the
    // User-Agent no extension may change.
    final userAgent = 'Kikuyomi/${_plainVersion()}';
    final network = net.NetworkService(
      policy: net.NetworkPolicy(userAgent: userAgent),
    );
    // Where extensions write, and where the app writes about them. Kept for as long as the app runs,
    // and shown on the console screen (§3.5, §3.11).
    final console = ExtensionConsole(clock: clock);
    final installs = ExtensionInstallFolder(locations.installedExtensions);
    final sources = await SourceRegistry.start(
      database: database,
      network: network,
      // §4.3's extension_preference table, so that what a source keeps — a chosen catalogue, a
      // token — is still there at the next start. It was in memory until schema version 2.
      store: DriftExtensionStore(database),
      log: console,
      host: const HostFacts(appVersion: appVersion),
      engineFactory: const QuickJsScriptEngineFactory(),
      appVersion: appVersion,
      extensions: await readExtensionsAtStart(
        database: database,
        installs: installs,
        console: console,
        clock: clock,
      ),
      onError: (extensionId, error, stack) {
        console.report(extensionId, error);
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: error,
            stack: stack,
            library: 'kikuyomi',
            context: ErrorDescription('while reading an extension'),
          ),
        );
      },
    );
    final extensions = ExtensionLibrary(
      sources: sources,
      console: console,
      database: database,
      installs: installs,
      folders: DeviceFolders.forThisDevice(),
      dropFolder: locations.extensionDrop,
      clock: clock,
      canInstallFromDropFolder: locations.importFolderIsVisible,
    );
    // Everything the app ships with, put in place before anything asks for a source. It has to be
    // here rather than in `SourceRegistry.start`: installing goes through `ExtensionLibrary`, which
    // needs the registry that is now built, and the installs adopt themselves into it.
    await seedOfficialRepository(
      database: database,
      settings: settings,
      extensions: extensions,
      console: console,
    );

    // §3.8's door for a listener, beside ADR-0017's door for an author. Its fetches go through the
    // same transport everything else uses, under a client of their own, so a repository is rate
    // limited per host like a source and its cookies are nobody else's.
    final repositories = RepositoryLibrary(
      database: database,
      fetcher: RepositoryFetcher(
        network.clientFor('org.kikuyomi.repositories'),
      ),
      clock: clock,
    );
    // What a streamed book's bytes are kept in, so that a skip, a chapter played again and the
    // book opened tomorrow are reads from this device. Pruned once at start, off the critical path.
    final streamCache = StreamAudioCache(locations.streamCache);
    unawaited(streamCache.prune());
    // One resolver for the whole library: files on the device go to the local one, and a book that
    // streams is resolved through its source, just in time (§6.3). Downloads share it, so a chapter
    // the listener is playing and the same chapter being fetched do not ask the source twice.
    final resolver = SourceMediaResolver(
      database,
      openSource: sources.open,
      onDevice: LocalMediaResolver(
        database,
        mediaRoot: locations.mediaRoot,
        downloadRoot: locations.downloads,
      ),
      clock: clock,
      onTiming: _timings,
    );
    final coordinator = PlaybackCoordinator(
      engine: JustAudioEngine(
        cache: streamCache,
        userAgent: userAgent,
        // Into the extension console, because a streamed book's bytes are an extension's URL being
        // fetched, and whoever is looking at why it will not play is looking there. The player only
        // ever reports its own platform's word for a failed fetch.
        onStreamFailure: (error, uri) => console.report(
          playbackConsoleId,
          uri == null ? error : 'fetching $uri: $error',
        ),
      ),
      resolver: resolver,
      store: DriftPlaybackStore(database, deviceId: deviceId, clock: clock),
      clock: clock,
      onTiming: _timings,
    );
    // §5.2's queue. The table is the source of truth; the transport only moves bytes (ADR-0007).
    // Resolution goes through the same resolver playback uses, with `refresh` on, because a download
    // is about to use the address for real and a cached one may have expired (§5.4).
    final downloadFiles = DownloadedFiles(locations.downloads);
    final deviceConditions = DeviceConditionsSource();
    final downloads = DownloadDriver(
      store: DriftDownloadStore(database, clock: clock),
      transport: BackgroundTransport(),
      resolve: (fileId) => resolver.resolve(fileId, refresh: true),
      conditions: deviceConditions.read,
      postProcess: downloadFiles.keep,
      clock: clock,
    )..start();
    // Pumped when something changed rather than on a clock alone: a listener who walks into Wi-Fi
    // expects the book they queued on the train to start, not to wait out a tick. The tick is the
    // backstop that picks up retries whose backoff has elapsed (§5.5), and an idle pass is two reads.
    deviceConditions.changes.listen((_) => unawaited(downloads.pump()));
    Timer.periodic(_downloadTick, (_) => unawaited(downloads.pump()));
    // Anything left running when the app was last killed is still in the table, and the transport may
    // even still be carrying it. Reconciling first is what settles which of those it is, because a row
    // stuck in flight holds one of §5.2's slots against the source for as long as the app runs.
    unawaited(downloads.reconcile().then((_) => downloads.pump()));

    // §5.1: automatic backups to the folder the user chose, which outlives an Android uninstall and
    // an iOS re-sign.
    final backupStore = DriftBackupStore(database);
    final backups = BackupService(
      library: backupStore,
      restorer: backupStore,
      folders: DeviceFolders.forThisDevice(),
      settings: settings,
      clock: clock,
      appVersion: appVersion,
      deviceId: deviceId,
    );
    // Starting it only subscribes to the database's change notifications. Nothing is read or written
    // until changes have settled, so it costs the first frame nothing.
    final backupScheduler = BackupScheduler(
      backUp: backups.backUp,
      changes: backedUpChanges(database),
      settings: settings,
      clock: clock,
    )..start();
    // Calls, navigation prompts and unplugged headphones go to the coordinator, which decides what
    // each means for the book (§6.5). The subscription lasts as long as the app.
    audioFocus.events.listen(
      (event) => unawaited(coordinator.onSystemAudio(event)),
    );
    // The lock screen, the notification and headset buttons, or on Windows the media keys and the
    // volume flyout (§6.5). Its subscriptions keep it alive for as long as the app runs.
    MediaSessionSync(
      coordinator: coordinator,
      bridge: await SystemMediaControls.start(skipInterval: _skipInterval),
      describe: (bookId) => _describeBook(database, bookId),
      clock: clock,
      skipInterval: _skipInterval,
    ).start();
    return AppServices._(
      database: database,
      coordinator: coordinator,
      clock: clock,
      locations: locations,
      settings: settings,
      backups: backups,
      backupScheduler: backupScheduler,
      playable: EngineFormats.forThisDevice(),
      extensions: extensions,
      repositories: repositories,
      streamCache: streamCache,
      downloads: downloads,
      downloadFiles: downloadFiles,
      deviceId: deviceId,
    );
  }

  final KikuyomiDatabase database;
  final PlaybackCoordinator coordinator;
  final Clock clock;
  final StorageLocations locations;

  /// App preferences (§4.3).
  final SettingsStore settings;

  /// The backup folder, writing backups to it, and restoring from them.
  final BackupService backups;

  /// When automatic backups run.
  final BackupScheduler backupScheduler;

  /// The audio formats the player can play on this device (§7.3). A book in any other is refused
  /// as it is added, rather than added to fail when it is opened.
  final PlayableFormats playable;

  /// Where the covers of books in the library are kept, and how the names book rows record for them
  /// are found.
  final CoverFiles covers;

  /// The extensions the app has installed: installing, removing and reloading them (§3.9).
  final ExtensionLibrary extensions;

  /// The repositories the listener has added, and what they offer (§3.8).
  final RepositoryLibrary repositories;

  /// Every source the app offers, and the extension runtimes behind them (§3.6).
  SourceRegistry get sources => extensions.sources;

  /// What extensions have written to the in-app console, and what the app has written about them
  /// (§3.5, §3.11).
  ExtensionConsole get extensionConsole => extensions.console;

  /// §5.2's download queue: what the listener asked to keep, and the thing that fetches it.
  final DownloadDriver downloads;

  /// Where downloaded files live, and what they come to (§5.6).
  final DownloadedFiles downloadFiles;

  /// This installation, as progress and history record it.
  final String deviceId;

  /// The bytes of streamed books kept on this device, so that moving about in one is instant. Not
  /// a download (§5.2): it is bounded, it is emptied when it grows past its bound, and
  /// [StreamAudioCache.clear] throws all of it away.
  final StreamAudioCache streamCache;

  final ImportFolder _importFolder;

  /// What the chapters of books to read say (ADR-0019), from their EPUBs or their sources.
  late final chapterTexts = ChapterTexts(
    database,
    mediaRoot: locations.mediaRoot,
    openSource: openSource,
  );

  /// Records a stretch of reading for History.
  Future<void> recordReading({
    required int bookId,
    required int chapterId,
    required DateTime startedAt,
    required DateTime endedAt,
  }) => recordReadingSession(
    database,
    bookId: bookId,
    chapterId: chapterId,
    startedAt: startedAt,
    endedAt: endedAt,
    deviceId: deviceId,
  );

  /// Records how many words chapter [chapterId] holds, the first time its text is fetched.
  Future<void> saveChapterWords(int chapterId, int words) =>
      saveChapterWordCount(database, chapterId, words);

  /// Records that the reader of [bookId] is [progress] of the way through [chapterId].
  Future<void> saveReadingPlace({
    required int bookId,
    required int chapterId,
    required double progress,
  }) => saveReadingPosition(
    database,
    bookId: bookId,
    chapterId: chapterId,
    progress: progress,
    clock: clock,
  );

  /// The scan of the import folder under way, so that a second request joins it instead of racing
  /// it to add the same books.
  Future<ImportScan>? _scan;

  /// The search for covers never looked for, while one is under way.
  Future<void>? _coverSearch;

  /// The end of the queue of background work on the library: scans of the import folder, and
  /// looking for one book's cover. They run one at a time, so the two never overlap.
  Future<void> _libraryWork = Future.value();

  /// Adds an audiobook file the user picked in a file dialog, returning the book's id.
  ///
  /// Where the picker hands over only a temporary copy, as on iOS and Android, the copy is moved
  /// into the app's import folder and the book refers to it there. Elsewhere the book refers to the
  /// user's own file.
  ///
  /// A file this device cannot play is refused with an [UnplayableFormatException] naming its
  /// format, as [probeBookFile] describes.
  Future<int> addPickedBook(String path) async {
    final picked = File(path).absolute;
    // Read before it is moved, so a file that is not a book, or one that will not play here, never
    // enters the import folder.
    final probe = await probeBookFile(picked, playable);
    final storedPath = locations.pickerHandsOverCopies
        ? await _importFolder.adoptCopy(picked)
        : picked.path;
    return _add(probe, storedPath);
  }

  /// Adds the audiobook file at [path] where it is, returning the book's id. For a path given on
  /// the command line, which is always the user's own file.
  Future<int> addBookInPlace(String path) async {
    final file = File(path).absolute;
    return _add(await probeBookFile(file, playable), file.path);
  }

  /// Adds an EPUB the user picked in a file dialog as a book to read, returning the book's id.
  ///
  /// Kept as [addPickedBook] keeps an audiobook file: moved into the import folder where the picker
  /// hands over only a copy, referred to where it is elsewhere. A book locked with DRM is refused
  /// with an [EpubProtectedException] before anything is moved.
  Future<int> addPickedEbook(String path) async {
    final picked = File(path).absolute;
    final read = await readEpubFile(picked);
    final storedPath = locations.pickerHandsOverCopies
        ? await _importFolder.adoptCopy(picked)
        : picked.path;
    return _addEbook(read, storedPath);
  }

  /// Adds the EPUB at [path] where it is, returning the book's id. For a path given on the command
  /// line, which is always the user's own file.
  Future<int> addEbookInPlace(String path) async {
    final file = File(path).absolute;
    return _addEbook(await readEpubFile(file), file.path);
  }

  /// Adds a folder of audio files as one book, referring to the files where they are. Returns the
  /// book's id, and the audio files in the folder that were left out: those that could not be read,
  /// and those in a format this device cannot play. For a folder picked on desktop, or given on the
  /// command line.
  ///
  /// A folder with no audio this device can play is refused, with an [UnplayableFormatException]
  /// naming the formats when it holds audio in others, as [readPlayableFolder] describes.
  Future<({int bookId, LeftOut leftOut})> addFolderBook(String path) async {
    final folder = Directory(path).absolute;
    final book = await readPlayableFolder(folder, playable);
    if (book == null) {
      throw FormatException('${folder.path} holds no audio this app can read');
    }
    final bookId = await _addFolder(
      book,
      folder: folder,
      key: folder.path,
      pathOf: (name) => _join(folder.path, name),
    );
    return (bookId: bookId, leftOut: LeftOut.of(book));
  }

  /// The title of book [bookId], as the library shows it: for telling the listener which book was
  /// added, when that was read from the book's own tags rather than chosen by name.
  Future<String> bookTitle(int bookId) async {
    final book = await (database.select(
      database.books,
    )..where((b) => b.id.equals(bookId))).getSingle();
    return book.title;
  }

  /// Adds the books copied into the import folder since it was last looked in, and returns how many
  /// were added, and which files and folders were not because this device cannot play them.
  ///
  /// On iOS the folder is visible in the Files app, so this is how a book copied there, as a folder
  /// of files or as a single file, reaches the library (§5.1). Elsewhere the folder holds only books
  /// already added through the file picker. A book already known is recognised by its path and not
  /// read again. A folder still being copied when this runs is added with the files that had
  /// arrived by then. What cannot be added stays in the folder, untouched, and is looked at again
  /// the next time.
  Future<ImportScan> scanImportFolder() =>
      _scan ??= _oneAtATime(_scanImportFolder).whenComplete(() => _scan = null);

  Future<ImportScan> _scanImportFolder() async {
    final name = _importFolder.name;
    final folder = Directory('${locations.mediaRoot.path}/$name');
    final unplayable = <({String name, UnplayableFormatException reason})>[];
    if (!await folder.exists()) return (added: 0, unplayable: unplayable);
    var added = 0;
    await for (final entry in folder.list(followLinks: false)) {
      final entryName = _lastSegment(entry.path);
      final key = '$name/$entryName';
      if (entryName.startsWith('.') || await _isKnown(key)) continue;
      try {
        if (entry is Directory) {
          final book = await readPlayableFolder(entry, playable);
          if (book == null) continue;
          await _addFolder(
            book,
            folder: entry,
            key: key,
            pathOf: (file) => '$key/$file',
          );
          added++;
        } else if (entry is File &&
            audioExtensions.contains(_extension(entryName))) {
          await _add(await probeBookFile(entry, playable), key);
          added++;
        } else if (entry is File && isEpubPath(entryName)) {
          await _addEbook(await readEpubFile(entry), key);
          added++;
        }
      } on FormatException {
        // Not audio this app can read.
      } on EpubFormatException {
        // Not an EPUB this app can read.
      } on EpubProtectedException {
        // Locked. It stays in the folder, as anything else that cannot be added does.
      } on UnplayableFormatException catch (reason) {
        unplayable.add((name: entryName, reason: reason));
      }
    }
    return (added: added, unplayable: unplayable);
  }

  /// Looks for the covers of books in the library whose cover has never been looked for: books
  /// added before covers were kept, and any whose cover could not be written when they were added.
  ///
  /// A book looked at once is not looked at again, so after the search at start another finds only
  /// books that arrived since without a cover, as a restore brings them. A call while a search is
  /// under way joins it. Books take their turn one at a time with scans of the import folder, so the
  /// two never overlap and a scan asked for meanwhile waits for one book rather than for all of
  /// them. A book whose files are missing is skipped quietly, for another start. Any other failure
  /// for one book goes to [onError], and the rest carry on.
  Future<void> lookForMissingCovers({
    required void Function(Object error, StackTrace stack) onError,
  }) =>
      _coverSearch ??= _lookForMissingCovers(onError)
          .whenComplete(() => _coverSearch = null);

  /// Whether the library holds no books at all: what a fresh install looks like.
  Future<bool> libraryIsEmpty() async =>
      await (database.select(database.books)
            ..where((b) => b.inLibrary.equals(true))
            ..limit(1))
          .getSingleOrNull() ==
      null;

  /// Does for a library just restored what start does for the library there was: adds the books
  /// copied into the import folder, and looks for the covers of books without one, since a backup
  /// carries no cover images. Failures go to [onError].
  Future<void> settleRestoredLibrary({
    required void Function(Object error, StackTrace stack) onError,
  }) async {
    try {
      await scanImportFolder();
    } catch (error, stack) {
      onError(error, stack);
    }
    await lookForMissingCovers(onError: onError);
  }

  Future<void> _lookForMissingCovers(
    void Function(Object error, StackTrace stack) onError,
  ) async {
    for (final book in await localBooksAwaitingCover(database)) {
      try {
        await _oneAtATime(
          () => lookForLocalCover(
            database,
            book,
            mediaRoot: locations.mediaRoot,
            read: _readCover,
            covers: covers,
            clock: clock,
          ),
        );
      } catch (error, stack) {
        onError(error, stack);
      }
    }
    // Then the books that stream, whose covers are a URL rather than a picture in a file. A book
    // whose cover cannot be fetched is left to be looked for again, exactly as a local one is.
    for (final book in await booksAwaitingSourceCover(database)) {
      try {
        await _oneAtATime(() async {
          final image = await fetchSourceCover(book);
          if (image == null) return;
          await keepBookCover(
            database,
            book.bookId,
            image,
            covers: covers,
            clock: clock,
          );
        });
      } catch (error, stack) {
        onError(error, stack);
      }
    }
  }

  /// Opens the source with [sourceId], starting its extension's runtime on first use (§3.6).
  ///
  /// Fails with an [ExtensionLoadException] for an extension that will not load, which is what a
  /// Browse screen shows rather than an empty grid.
  Future<api.ContentSource> openSource(int sourceId) => sources.open(sourceId);

  /// What a source says about one of its books, and what is in it.
  ///
  /// Both in one call because the screen that asks shows both, and because adding the book writes
  /// both. Fails with a [SourceException], whose kind the screen reacts to.
  Future<({api.BookDetails details, List<api.ChapterInfo> chapters})>
  previewSourceBook(int sourceId, String bookKey) async {
    final source = await openSource(sourceId);
    final details = await source.getBookDetails(bookKey);
    final chapters = await source.getChapters(bookKey);
    return (details: details, chapters: chapters);
  }

  /// Puts a book from a source in the library and returns its id.
  ///
  /// From here on it is a book like any other: the library shows it, its details screen reads the
  /// same rows, and the player opens it through the same Timeline. Its cover is fetched in the
  /// background, as a local book's is looked for, because a book should appear the moment it is
  /// added rather than when its picture arrives.
  Future<int> addSourceBook({
    required int sourceId,
    required api.BookDetails details,
    required List<api.ChapterInfo> chapters,
  }) async {
    final saved = await saveSourceBook(
      database,
      sourceId: sourceId,
      details: details,
      chapters: chapters,
      clock: clock,
      addToLibrary: true,
      // The source's kind, which is what puts a novel on the Reading shelf rather than beside the
      // audiobooks. A stub has no manifest to say, and every stub predates reading, so audio.
      kind: sources.describe(sourceId)?.kind ?? api.SourceKind.audio,
    );
    unawaited(
      lookForMissingCovers(
        onError: (error, stack) => FlutterError.reportError(
          FlutterErrorDetails(
            exception: error,
            stack: stack,
            library: 'kikuyomi',
            context: ErrorDescription("while fetching a book's cover"),
          ),
        ),
      ),
    );
    return saved.bookId;
  }

  /// Fetches the cover of [book] through its source, or null when there is nothing to show.
  ///
  /// The request comes from the source when it declares `getImageRequest`, because §6.3's referers,
  /// tokens and cookies are real; otherwise it is a plain GET, and the extension is not called at
  /// all. Either way the URL is held to the extension's declared domains, on the first request and
  /// on every redirect, because those domains are the promise the permissions screen makes.
  Future<CoverImage?> fetchSourceCover(BookAwaitingCover book) async {
    final extensionId = sources.extensionIdOf(book.sourceId);
    final domains = sources.domainsOf(book.sourceId);
    if (extensionId == null || domains == null) return null;
    final problem = domains.problemWith(book.coverUrl);
    if (problem != null) return null;
    final request = await sources.imageRequestFor(book.sourceId, book.coverUrl);
    final response = await sources
        .httpClientFor(extensionId)
        .send(
          net.NetworkRequest(url: request.url, headers: request.headers),
          check: (url) {
            final problem = domains.problemWith(url);
            if (problem != null) throw FormatException('$url: $problem');
          },
        );
    if (response.status != 200 || response.body.isEmpty) return null;
    final contentType = response.headers['content-type']
        ?.split(';')
        .first
        .trim()
        .toLowerCase();
    return CoverImage(
      mimeType: contentType ?? 'image/jpeg',
      bytes: response.body,
    );
  }

  /// Queues every file of book [bookId] that is not already on the device, and sets the queue going.
  ///
  /// §5.2 counts in physical files, so a thirty-chapter M4B is one download however it was asked for,
  /// and asking twice adds nothing. What comes back says what happened, because "nothing to do" and
  /// "four files queued" should not look the same to the listener.
  Future<EnqueuedDownloads> downloadBook(int bookId) async {
    final asked = await enqueueBookDownload(database, bookId, clock: clock);
    unawaited(downloads.pump());
    return asked;
  }

  /// Queues the files chapter [chapterId] is made of.
  ///
  /// [priority] raises it above the rest of its book, which is what the chapter about to be played
  /// wants.
  Future<EnqueuedDownloads> downloadChapter(
    int chapterId, {
    int priority = 0,
  }) async {
    final asked = await enqueueChapterDownload(
      database,
      chapterId,
      clock: clock,
      priority: priority,
    );
    unawaited(downloads.pump());
    return asked;
  }

  /// Queues the files behind [chapterIds], in the order given, and sets the queue going.
  ///
  /// One pump for the lot rather than one per chapter: asking for ten chapters is one action, and
  /// ten pumps would have the scheduler start, find its slots full, and stop again nine times.
  ///
  /// Chapters sharing a file queue it once, which is why what comes back is counted in files and
  /// not in chapters. "Ten chapters, two files" is the truthful answer for an M4B and the one worth
  /// showing.
  Future<EnqueuedDownloads> downloadChapters(List<int> chapterIds) async {
    var added = 0;
    var alreadyQueued = 0;
    var alreadyOnDevice = 0;
    for (final chapterId in chapterIds) {
      final asked = await enqueueChapterDownload(
        database,
        chapterId,
        clock: clock,
      );
      added += asked.added;
      alreadyQueued += asked.alreadyQueued;
      alreadyOnDevice += asked.alreadyOnDevice;
    }
    unawaited(downloads.pump());
    return EnqueuedDownloads(
      added: added,
      alreadyQueued: alreadyQueued,
      alreadyOnDevice: alreadyOnDevice,
    );
  }

  /// Asks the source for book [bookId] again, and returns how many chapters that added.
  ///
  /// This is the whole of the app's answer to a serial that keeps publishing. §4.4's merge does the
  /// work: a book already known is refreshed rather than replaced, so the listener's edits, their
  /// progress and their bookmarks survive, and chapters they already have keep their listened state
  /// and their files.
  ///
  /// Only on demand, from the book's own page. A background job that swept the whole library was
  /// the other way to do this, and it is a great deal more machinery for something a listener can
  /// ask for in the one place they are already looking.
  ///
  /// Throws [StateError] for a book with no source to ask -- one added off this device -- and
  /// whatever the extension throws for one whose source will not answer.
  Future<int> refreshBookFromSource(int bookId) async {
    final book = await (database.select(
      database.books,
    )..where((b) => b.id.equals(bookId))).getSingleOrNull();
    if (book == null) throw StateError('That book is no longer here.');
    if (book.sourceId == localSourceId) {
      throw StateError(
        'This book was added from this device, so there is no source to ask.',
      );
    }

    final before = await _chapterCount(bookId);
    final fetched = await previewSourceBook(book.sourceId, book.key);
    await saveSourceBook(
      database,
      sourceId: book.sourceId,
      details: fetched.details,
      chapters: fetched.chapters,
      clock: clock,
    );
    return await _chapterCount(bookId) - before;
  }

  Future<int> _chapterCount(int bookId) async {
    final rows = await (database.select(
      database.chapters,
    )..where((c) => c.bookId.equals(bookId))).get();
    return rows.length;
  }

  /// Stops download [taskId], keeping what has arrived.
  Future<void> pauseDownload(int taskId) => downloads.pause(taskId);

  /// Carries on with download [taskId], from where it paused if the platform can.
  Future<void> resumeDownload(int taskId) => downloads.resume(taskId);

  /// Gives up on download [taskId] and throws away what has arrived.
  Future<void> cancelDownload(int taskId) => downloads.cancel(taskId);

  /// Puts download [taskId] back in the queue with its attempts forgiven (§5.5).
  Future<void> retryDownload(int taskId) async {
    await retryDownloadTask(database, taskId, clock: clock);
    unawaited(downloads.pump());
  }

  /// Deletes the downloaded file [mediaFileId] and forgets it (§5.6).
  ///
  /// The file goes first and the row second, so a delete the system refuses — a file the player still
  /// has open, which is how Windows behaves — leaves the row saying the file is here, which it is.
  /// The other order would show the listener a book they could no longer play and no longer delete.
  ///
  /// Nothing happens for a file the download system is not holding. A local book's path is the
  /// listener's own file and is not this app's to delete; `readDownloadedPath` is what refuses it, and
  /// it refuses by answering null rather than by throwing, because asking about a file that is not a
  /// download is ordinary rather than wrong.
  Future<bool> deleteDownloadedFile(int mediaFileId) async {
    final path = await readDownloadedPath(database, mediaFileId);
    if (path == null) return false;
    await downloadFiles.discard(path);
    await forgetDownloadedFile(database, mediaFileId);
    return true;
  }

  /// Takes file [mediaFileId] off the Downloads screen entirely (§5.6).
  ///
  /// The one action that applies in every state, which is why it is three: whatever is still going is
  /// stopped, whatever arrived is deleted, and the row goes last. A file that refuses to be deleted
  /// keeps its row, because a row is the only thing that shows the file at all and the only thing that
  /// can offer to try again.
  Future<void> removeDownload(int mediaFileId) async {
    final task = await readDownloadTask(database, mediaFileId);
    // Cancelling something already finished would write `cancelled` over a completed row for the sake
    // of a job the transport let go of long ago.
    if (task != null && !task.state.isFinished) {
      await downloads.cancel(task.id);
    }
    await deleteDownloadedFile(mediaFileId);
    if (task != null) await forgetDownloadTask(database, task.id);
  }

  /// Takes every download of book [bookId] off the screen, and says what became of its files (§5.6).
  ///
  /// [kept] is what could not be deleted — a file the player still has open, which is how Windows
  /// behaves. Those keep their rows so they can be tried again; everything else goes.
  Future<({int deleted, int kept})> removeBookDownloads(int bookId) async {
    // Stopped before anything is deleted, so the transport is not still writing into a file that is
    // about to go.
    for (final task in await readBookDownloadTasks(database, bookId)) {
      if (!task.state.isFinished) await downloads.cancel(task.id);
    }
    final onDevice = (await readDownloadedPathsOfBook(database, bookId)).length;
    final deleted = await deleteBookDownloads(bookId);
    await forgetUnheldDownloads(database, bookId);
    return (deleted: deleted, kept: onDevice - deleted);
  }

  /// Deletes every downloaded file of book [bookId], and says how many went (§5.6).
  ///
  /// Carries on past one it could not delete, so a single file the player has open does not leave the
  /// rest of a finished book taking up room. What it returns is what really went.
  Future<int> deleteBookDownloads(int bookId) async {
    final paths = await readDownloadedPathsOfBook(database, bookId);
    var deleted = 0;
    for (final fileId in paths.keys) {
      try {
        if (await deleteDownloadedFile(fileId)) deleted++;
      } on FileSystemException {
        continue;
      }
    }
    return deleted;
  }

  /// Opens a book in the player, resuming where it was left with smart rewind applied.
  Future<void> openBook(int bookId) async {
    final watch = _timings == null ? null : (Stopwatch()..start());
    final stored = await loadStoredPlayback(database, bookId);
    if (watch != null) _timings?.call('openBook.timeline', watch.elapsed);
    final lastPlayedAt = stored.lastPlayedAt;
    await coordinator.open(
      PlaybackRequest(
        bookId: bookId,
        timeline: stored.timeline,
        resumeFrom: stored.resumeFrom,
        pausedFor: lastPlayedAt == null
            ? Duration.zero
            : clock.now().difference(lastPlayedAt),
        speed: stored.speed ?? 1.0,
        finished: stored.finished,
      ),
    );
  }

  /// Marks chapters [chapterIds] of book [bookId] listened, or not, by hand (§4.5), and returns
  /// those it changed.
  ///
  /// The player is told as well, in case the book is open there, so that what it says about the
  /// book being finished stays the same as what the book's details and Continue Listening say.
  Future<Set<int>> markChaptersListened(
    int bookId,
    Iterable<int> chapterIds, {
    required bool listened,
  }) async {
    final changed = await setChaptersListened(
      database,
      bookId: bookId,
      chapterIds: chapterIds,
      listened: listened,
      clock: clock,
    );
    await coordinator.onListenedChanged(
      bookId: bookId,
      chapterIds: changed,
      listened: listened,
    );
    return changed;
  }

  /// Marks book [bookId] finished by hand, every chapter listened, and returns the chapters that
  /// were not, which are the ones to mark not listened again to undo it. The player is told, as
  /// for [markChaptersListened].
  Future<Set<int>> markBookFinished(int bookId) async {
    final changed = await data.markBookFinished(database, bookId, clock: clock);
    await coordinator.onListenedChanged(
      bookId: bookId,
      chapterIds: changed,
      listened: true,
    );
    return changed;
  }

  /// Marks book [bookId] not finished by hand, its last chapter not listened. The player is told,
  /// as for [markChaptersListened].
  Future<void> markBookNotFinished(int bookId) async {
    final changed = await data.markBookNotFinished(
      database,
      bookId,
      clock: clock,
    );
    await coordinator.onListenedChanged(
      bookId: bookId,
      chapterIds: changed,
      listened: false,
    );
  }

  /// Runs [work] once the background work queued before it has finished, failed or not.
  Future<T> _oneAtATime<T>(Future<T> Function() work) {
    final result = _libraryWork.then((_) => work());
    _libraryWork = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return result;
  }

  Future<bool> _isKnown(String key) async =>
      await (database.select(
            database.books,
          )..where((b) => b.sourceId.equals(localSourceId) & b.key.equals(key)))
          .getSingleOrNull() !=
      null;

  /// Adds the probed file as a book, stored at [storedPath]: absolute, or relative to the media
  /// root.
  Future<int> _add(ProbedBook probe, String storedPath) => importLocalBook(
    database,
    LocalBookImport(
      file: LocalBookFile(
        path: storedPath,
        durationMs: probe.durationMs,
        durationIsEstimate: probe.durationIsEstimate,
        sizeBytes: probe.sizeBytes,
        format: _extension(storedPath),
        markers: probe.markers,
      ),
      title: probe.bookTitle ?? _stem(storedPath),
      authors: [?probe.author],
      narrators: [?probe.narrator],
      cover: probe.cover,
    ),
    clock: clock,
    covers: covers,
  );

  /// Adds the EPUB [read] as a book to read, stored at [storedPath]: absolute, or relative to the
  /// media root.
  Future<int> _addEbook(LocalEpubImport read, String storedPath) =>
      importLocalEpub(
        database,
        LocalEpubImport(
          path: storedPath,
          title: read.title,
          chapters: read.chapters,
          authors: read.authors,
          language: read.language,
          description: read.description,
          publisher: read.publisher,
          cover: read.cover,
        ),
        clock: clock,
        covers: covers,
      );

  /// Adds a folder read as a book under [key], with each file stored at the path [pathOf] gives
  /// its name. [folder] is where the folder is, to read its cover from.
  Future<int> _addFolder(
    FolderBook book, {
    required Directory folder,
    required String key,
    required String Function(String fileName) pathOf,
  }) async {
    CoverImage? cover;
    var coverRead = true;
    try {
      final image = book.coverFileName;
      cover = _coverImage(
        await readLocalCover(
          File(_join(folder.path, book.tracks.first.fileName)),
          image: image == null ? null : File(_join(folder.path, image)),
        ),
      );
    } on FileSystemException {
      // The first track went missing since the folder was read. Adding the book does not wait on
      // its cover, which is left to be looked for later.
      coverRead = false;
    }
    return importLocalFolderBook(
      database,
      LocalFolderImport(
        key: key,
        title: book.title,
        authors: book.authors,
        narrators: book.narrators,
        cover: cover,
        tracks: [
          for (final track in book.tracks)
            LocalTrackImport(
              file: LocalBookFile(
                path: pathOf(track.fileName),
                durationMs: track.durationMs,
                durationIsEstimate: track.durationIsEstimate,
                sizeBytes: track.sizeBytes,
                format: track.format,
              ),
              title: track.title,
            ),
        ],
      ),
      clock: clock,
      covers: coverRead ? covers : null,
    );
  }
}

/// §4.5: records as listened the chapters listened to before listened state was recorded, from the
/// positions saved in them, once for this installation.
///
/// It runs as the app opens, before any screen reads listened state and before the player can record
/// any, so nothing is ever shown unlistened that was shown listened before, and no chapter the
/// listener has since marked by hand is touched. A failure is reported the way Flutter reports
/// errors and does not stop the app: the backfill is not recorded as done, so it is tried again at
/// the next start.
Future<void> _backfillListened(
  KikuyomiDatabase database,
  SettingsStore settings,
) async {
  try {
    await backfillListenedChaptersOnce(database, settings);
  } catch (error, stack) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stack,
        library: 'kikuyomi',
        context: ErrorDescription(
          'while recording chapters listened before listened state was recorded',
        ),
      ),
    );
  }
}

/// Whether the console is told how long each step of opening and playing a book took.
///
/// On in a debug build, which is what `flutter run` produces, so that a listener saying "pressing
/// play is slow" becomes numbers without anyone having to rebuild. A release build measures
/// nothing at all: the sink is null, and the stopwatches are never made.
/// Turn it off in a debug build with `--dart-define=kikuyomi.timings=false`.
const _reportTimings =
    kDebugMode && bool.fromEnvironment('kikuyomi.timings', defaultValue: true);

/// Where [PlaybackCoordinator] and [SourceMediaResolver] report what each step cost.
///
/// One line per step, so that the console shows what a slow "press play" was really waiting on:
///
///     kikuyomi timing resolve.source 1843 ms
///     kikuyomi timing open.resolve 1871 ms
///     kikuyomi timing open.load 402 ms
const TimingSink? _timings = _reportTimings ? _printTiming : null;

void _printTiming(String step, Duration took) =>
    debugPrint('kikuyomi timing $step ${took.inMilliseconds} ms');

String _join(String directory, String name) =>
    '$directory${Platform.pathSeparator}$name';

/// How far the system controls' skip buttons move: the same as the player screen's.
const _skipInterval = Duration(seconds: 30);

/// How often the download queue is looked at when nothing has happened to prompt it.
///
/// The prompts — a book queued, the network changing — are what actually move the queue along. This
/// is only so that a retry whose backoff elapsed is picked up without waiting for one, and an idle
/// pass costs two reads.
const _downloadTick = Duration(seconds: 30);

/// The app's version without its build number, for a User-Agent and for comparing against an
/// extension's `minAppVersion`.
String _plainVersion() => appVersion.split('+').first;

/// Reads the cover of a book already in the library: for a book in a folder, the image there named
/// as its cover, or failing that the picture in its first file; for a book in one file, the picture
/// in it.
Future<CoverImage?> _readCover(File audio, Directory? folder) async {
  final image = folder == null ? null : await findFolderCoverImage(folder);
  return _coverImage(await readLocalCover(audio, image: image));
}

CoverImage? _coverImage(EmbeddedPicture? picture) => picture == null
    ? null
    : CoverImage(mimeType: picture.mimeType, bytes: picture.bytes);

/// A book's title and first author, as the system's media controls name it.
Future<BookDescription> _describeBook(KikuyomiDatabase db, int bookId) async {
  final book = await (db.select(
    db.books,
  )..where((b) => b.id.equals(bookId))).getSingle();
  final credit =
      await (db.select(db.bookPeople)
            ..where(
              (c) =>
                  c.bookId.equals(bookId) &
                  c.role.equalsValue(ContributorRole.author),
            )
            ..orderBy([(c) => OrderingTerm.asc(c.ordinal)])
            ..limit(1))
          .getSingleOrNull();
  final author = credit == null
      ? null
      : await (db.select(
          db.people,
        )..where((p) => p.id.equals(credit.personId))).getSingle();
  return BookDescription(title: book.title, author: author?.name);
}

String _lastSegment(String path) {
  final segments = path.split(RegExp(r'[\\/]'))
    ..removeWhere((segment) => segment.isEmpty);
  return segments.isEmpty ? path : segments.last;
}

String _stem(String path) {
  final name = _lastSegment(path);
  final dot = name.lastIndexOf('.');
  return dot > 0 ? name.substring(0, dot) : name;
}

String? _extension(String path) {
  final dot = path.lastIndexOf('.');
  return dot < 0 ? null : path.substring(dot + 1).toLowerCase();
}

/// A random id for this installation, created once and kept beside the database. §4.3 stores it
/// with progress and listening sessions, so that sync can later tell devices apart.
Future<String> _deviceId(Directory directory) async {
  final file = File(_join(directory.path, 'device_id'));
  if (await file.exists()) return (await file.readAsString()).trim();
  final random = Random.secure();
  final id = [
    for (var i = 0; i < 16; i++)
      random.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ].join();
  await file.writeAsString(id);
  return id;
}
