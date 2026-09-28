import 'dart:async';
import 'dart:io';
import 'dart:ui' show AppExitResponse;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kikuyomi_backup/kikuyomi_backup.dart';

import 'back_gesture.dart';
import 'book_files.dart';
import 'providers.dart';
import 'routes.dart';
import 'setup_gate.dart';
import 'snack_bars.dart';

class KikuyomiApp extends ConsumerStatefulWidget {
  const KikuyomiApp({
    super.key,
    this.openOnLaunch,
    this.installExtensionsFrom = const [],
  });

  /// A book file or folder passed on the command line, to import and open at start. Also how the
  /// app is driven by automated checks, since a file dialog cannot be scripted.
  final String? openOnLaunch;

  /// Folders passed with `--extension`, to install an extension from at start (§3.11).
  ///
  /// For an author's edit-and-reload loop on a desktop: rebuild the bundle, start the app, and the
  /// source runs the new code without anyone tapping through a picker.
  final List<String> installExtensionsFrom;

  @override
  ConsumerState<KikuyomiApp> createState() => _KikuyomiAppState();
}

class _KikuyomiAppState extends ConsumerState<KikuyomiApp> {
  final _navigator = GlobalKey<NavigatorState>();

  /// Made once and kept for the life of the app, so rebuilding the app never loses the screens the
  /// listener has open.
  late final GoRouter _router = createRouter(
    navigatorKey: _navigator,
    setupGate: ref.read(setupGateProvider),
  );
  late final AppLifecycleListener _lifecycle;
  late final StreamSubscription<BackupOutcome> _backupOutcomes;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onHide: _leaving,
      // Books may have been copied into the import folder while the app was away.
      onResume: _lookForNewBooks,
      // Closing a desktop window ends the app without hiding it first.
      onExitRequested: _closing,
    );
    _backupOutcomes = ref
        .read(servicesProvider)
        .backupScheduler
        .outcomes
        .listen(_reportFailedBackup);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_decideSetup());
      if (widget.installExtensionsFrom.isNotEmpty) {
        unawaited(_installExtensions());
      }
      // Covers for books added before covers were kept wait for the first look in the import
      // folder, whose new books bring their own, so start-up does the one thing at a time.
      unawaited(_lookForNewBooks().then((_) => _lookForMissingCovers()));
      final path = widget.openOnLaunch;
      if (path != null) unawaited(_open(path));
    });
  }

  @override
  void dispose() {
    unawaited(_backupOutcomes.cancel());
    _lifecycle.dispose();
    _router.dispose();
    super.dispose();
  }

  /// The app left the screen, where the system may end it without warning. §6.4 saves progress
  /// there, and a backup due is written there for the same reason. Playback carries on.
  void _leaving() {
    final services = ref.read(servicesProvider);
    unawaited(
      services.coordinator.onBackgrounded().whenComplete(
        services.backupScheduler.appLeaving,
      ),
    );
  }

  /// Before a desktop window closes: saves progress and writes any backup due, waiting no more than
  /// a few seconds, so that a backup folder on a slow network drive never holds the window open.
  Future<AppExitResponse> _closing() async {
    final services = ref.read(servicesProvider);
    try {
      await services.coordinator.onBackgrounded().timeout(_closingWait);
      await services.backupScheduler.appLeaving().timeout(_closingWait);
    } catch (error, stack) {
      _report(error, stack, 'while saving before the app closed');
    }
    return AppExitResponse.exit;
  }

  static const _closingWait = Duration(seconds: 10);

  /// Decides whether to offer backup setup (§5.1: restore on a fresh install), which the router then
  /// follows. Not for a book opened from the command line, which was asked for by name.
  Future<void> _decideSetup() async {
    final services = ref.read(servicesProvider);
    try {
      await ref
          .read(setupGateProvider)
          .decide(
            () async =>
                widget.openOnLaunch == null &&
                await shouldOfferSetup(
                  settings: services.settings,
                  canChooseFolder: services.backups.canChooseFolder,
                  libraryIsEmpty: services.libraryIsEmpty,
                ),
          );
    } catch (error, stack) {
      _report(error, stack, 'while deciding whether to offer backup setup');
    }
  }

  /// A backup that failed is shown in Settings; this reports it the way Flutter reports errors too,
  /// for whoever is developing the app.
  void _reportFailedBackup(BackupOutcome outcome) {
    if (outcome case BackupFailed(:final error, :final stackTrace)) {
      _report(error, stackTrace, 'while backing up automatically');
    }
  }

  void _report(Object error, StackTrace stack, String context) =>
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'kikuyomi',
          context: ErrorDescription(context),
        ),
      );

  /// Installs the extensions named with `--extension`, one at a time, and says how each went.
  ///
  /// A folder that is not an extension is reported and the rest are still installed: the point of the
  /// flag is a loop an author runs over and over, and one wrong path should cost one message.
  Future<void> _installExtensions() async {
    final library = ref.read(servicesProvider).extensions;
    for (final folder in widget.installExtensionsFrom) {
      try {
        final installed = await library.installFromPath(folder);
        _tell('Installed ${installed.name} ${installed.row.version}');
      } catch (error) {
        _tell('Could not install the extension in $folder: $error');
      }
    }
  }

  Future<void> _open(String path) async {
    final services = ref.read(servicesProvider);
    try {
      if (isEpubPath(path)) {
        // A book to read. There is no player to open it in, so it is added and named.
        final bookId = await services.addEbookInPlace(path);
        _tell('Added ${await services.bookTitle(bookId)}');
        return;
      }
      final bookId = await FileSystemEntity.isDirectory(path)
          ? (await services.addFolderBook(path)).bookId
          : await services.addBookInPlace(path);
      await services.openBook(bookId);
      await _router.push<void>(const PlayerRoute().location);
    } catch (error) {
      _tell('Could not open $path: ${describeAddError(error)}');
    }
  }

  /// Adds any books copied into the import folder (§5.1), and says so when there were some.
  ///
  /// Books this device cannot play are not mentioned here, since they stay in the folder and would
  /// be mentioned again every time the app comes back to the foreground. Looking for new books from
  /// the library's button names them.
  Future<void> _lookForNewBooks() async {
    try {
      final (:added, unplayable: _) = await ref
          .read(servicesProvider)
          .scanImportFolder();
      if (added > 0) {
        _tell(
          added == 1
              ? 'Added a book from the Import folder'
              : 'Added $added books from the Import folder',
        );
      }
    } catch (error) {
      _tell('Could not look for new books: $error');
    }
  }

  /// Looks, in the background, for the covers of books whose cover was never looked for. Quietly:
  /// a book shown without its cover is not worth interrupting the listener over, so a failure is
  /// only reported the way Flutter reports errors, for whoever is developing the app.
  Future<void> _lookForMissingCovers() async {
    void report(Object error, StackTrace stack) => FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stack,
        library: 'kikuyomi',
        context: ErrorDescription("while looking for a book's cover"),
      ),
    );
    try {
      await ref.read(servicesProvider).lookForMissingCovers(onError: report);
    } catch (error, stack) {
      report(error, stack);
    }
  }

  void _tell(String message) {
    final context = _navigator.currentContext;
    if (context != null && context.mounted) {
      tellInSnackBar(ScaffoldMessenger.of(context), message);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Warm peach, the accent Mihon and Tachiyomi are recognised by, and the family this app is
    // meant to read as part of. Material 3 derives the rest of the scheme from it, so the pills,
    // the selected tab and the floating button all come out of this one figure.
    const seed = Color(0xFFF0A868);
    return MaterialApp.router(
      title: 'Kikuyomi',
      routerConfig: _router,
      theme: ThemeData(
        colorSchemeSeed: seed,
        snackBarTheme: kikuyomiSnackBarTheme,
        pageTransitionsTheme: kikuyomiPageTransitions,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: seed,
        brightness: Brightness.dark,
        snackBarTheme: kikuyomiSnackBarTheme,
        pageTransitionsTheme: kikuyomiPageTransitions,
      ),
    );
  }
}
