import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../drop/file_drop_target.dart';

/// §5.1's single adapter for storage paths, so that no feature builds a platform path itself.
final class StorageLocations {
  const StorageLocations._({
    required this.appData,
    required this.covers,
    required this.bookFiles,
    required this.installedExtensions,
    required this.extensionDrop,
    required this.downloads,
    required this.streamCache,
    required this.mediaRoot,
    required this.pickerHandsOverCopies,
    required this.importFolderIsVisible,
    required this.canPickFolders,
    required this.acceptsDroppedFiles,
  });

  /// The locations on this device. Asynchronous because `path_provider` asks the platform.
  static Future<StorageLocations> forThisDevice() async {
    final appData = await getApplicationSupportDirectory();
    await appData.create(recursive: true);
    final streamCache = Directory(
      '${(await getApplicationCacheDirectory()).path}'
      '${Platform.pathSeparator}streams',
    );
    // §5.1 keeps library covers in internal storage on every platform. Application Support is that
    // on iOS too, where Documents would show them in the Files app beside the imported books.
    final covers = Directory('${appData.path}${Platform.pathSeparator}covers');
    // A book downloaded whole from a source (ADR-0021). Internal storage, like covers: it is the
    // app's copy of the book, not something the reader put there or should have to tidy up.
    final bookFiles = Directory(
      '${appData.path}${Platform.pathSeparator}book_files',
    );
    final installedExtensions = Directory(
      '${appData.path}${Platform.pathSeparator}installed_extensions',
    );
    final downloads = Directory(
      '${appData.path}${Platform.pathSeparator}downloads',
    );
    if (Platform.isIOS) {
      final documents = await getApplicationDocumentsDirectory();
      return StorageLocations._(
        appData: appData,
        covers: covers,
        bookFiles: bookFiles,
        installedExtensions: installedExtensions,
        extensionDrop: Directory(
          '${documents.path}${Platform.pathSeparator}Extensions',
        ),
        downloads: downloads,
        streamCache: streamCache,
        // §5.1 keeps iOS imports in a folder the Files app shows, and Documents is the folder it
        // shows, given UIFileSharingEnabled in Info.plist.
        mediaRoot: documents,
        pickerHandsOverCopies: true,
        importFolderIsVisible: true,
        canPickFolders: false,
        acceptsDroppedFiles: platformReportsDroppedPaths,
      );
    }
    final android = Platform.isAndroid;
    return StorageLocations._(
      appData: appData,
      covers: covers,
      bookFiles: bookFiles,
      installedExtensions: installedExtensions,
      extensionDrop: Directory(
        '${appData.path}${Platform.pathSeparator}Extensions',
      ),
      downloads: downloads,
      streamCache: streamCache,
      mediaRoot: appData,
      pickerHandsOverCopies: android,
      importFolderIsVisible: false,
      canPickFolders: !android,
      acceptsDroppedFiles: platformReportsDroppedPaths,
    );
  }

  /// App-internal data: the database and the device id.
  final Directory appData;

  /// The files of books downloaded whole from a source (ADR-0021), inside [appData]. It may not
  /// exist yet: whatever writes the first book creates it.
  ///
  /// Book rows record the file by its name in this folder, never by an absolute path, for the
  /// reason covers are recorded that way: on iOS the app's container moves when the app is updated.
  final Directory bookFiles;

  /// The covers of books in the library (§5.1), inside [appData]. It may not exist yet: whatever
  /// writes the first cover creates it.
  ///
  /// Book rows record a cover by its name in this folder, never by an absolute path, since on iOS
  /// the app's container can move when the app is updated or reinstalled.
  final Directory covers;

  /// The app's own copy of every installed extension, one folder per extension and one per version
  /// (§3.9), inside [appData].
  ///
  /// Extensions are code, so they are kept where only the app can write: not in [mediaRoot], where a
  /// listener drops books, and never in a cache the OS may empty. The folder may not exist yet;
  /// installing the first extension creates it.
  final Directory installedExtensions;

  /// The folder an extension can be copied into to install it, inside [mediaRoot].
  ///
  /// Only worth offering where [importFolderIsVisible] says the listener can see it, which is iOS:
  /// there no folder outside the app can be kept, so the Files app is the only door an extension has.
  /// Elsewhere the folder picker is the way in. It may not exist yet; the Extensions screen creates it
  /// when it offers it.
  final Directory extensionDrop;

  /// The audiobook files the listener asked to keep (§5.2), inside [appData].
  ///
  /// App-private, like the covers, and on the same volume as the folder the transport writes into,
  /// so a finished download is moved into place with a rename rather than copied (§5.2's atomic
  /// move). Not the stream cache: nobody asked for those bytes and the OS may take them back,
  /// whereas these were asked for and must survive until the listener says otherwise.
  final Directory downloads;

  /// Where the bytes of a streamed book are kept while they are worth keeping.
  ///
  /// In the platform's cache folder, not in app data and never in the downloads folder §5.2 gives
  /// the listener: nobody asked for these files, nothing in the database refers to them, and an OS
  /// that wants the space back is welcome to it. It may not exist yet; the cache makes it.
  final Directory streamCache;

  /// What paths to media in the app's own storage are stored relative to.
  final Directory mediaRoot;

  /// Whether a file the user picks arrives as a temporary copy rather than as the file itself.
  ///
  /// The iOS picker copies the chosen file into the app's temporary folder, and the Android picker
  /// copies it into the app's cache, and the system may clear either. Such a copy has to be moved
  /// into app storage to be kept. A desktop picker returns the user's own file, which stays where
  /// the user keeps it.
  final bool pickerHandsOverCopies;

  /// Whether the user can see the import folder and copy books into it themselves, as they can on
  /// iOS through the Files app.
  ///
  /// The folder is looked in for new books wherever it is; this says only whether it is worth
  /// telling the user about.
  final bool importFolderIsVisible;

  /// Whether a folder the user picks can be read where it is, as a book of several files.
  ///
  /// Only on desktop for now. Android hands over a picked folder as a content address that plain
  /// file access cannot open, and iOS has no folder picker; both wait for §3.10's folder access
  /// through the Storage Access Framework and security-scoped bookmarks.
  final bool canPickFolders;

  /// Whether files and folders dropped onto the window arrive as paths that can be read where they
  /// are, so that a `FileDropTarget` can add them as a picked file or folder is added.
  ///
  /// Only on desktop. Android reports a drop from another app as content addresses, for the reason
  /// [canPickFolders] gives, and iOS reports none to the app at all.
  final bool acceptsDroppedFiles;
}
