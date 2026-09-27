import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikuyomi_domain/kikuyomi_domain.dart';
import 'package:kikuyomi_sources_builtin/kikuyomi_sources_builtin.dart'
    show audioExtensions;

import 'app_shell.dart';
import 'backup_actions.dart';
import 'backup_reminder.dart';
import 'book_drop_zone.dart';
import 'book_files.dart';
import 'dropped_books.dart';
import 'home_view.dart';
import 'library/category_bar.dart';
import 'library/library_shelf.dart';
import 'open_book.dart';
import 'providers.dart';
import 'routes.dart';
import 'snack_bars.dart';

/// The files "Add book" offers: every extension a book is read from, whether or not this device
/// can play it, so that a book it cannot play is refused with its format named rather than hidden
/// in the dialog without a word.
///
/// Each platform's picker filters by its own kind of type. Windows and Android go by extension.
/// iOS goes by uniform type identifier, and refuses a group that lists none. Apple types the .m4b
/// extension as com.apple.protected-mpeg-4-audio, a name it gives audiobooks in general whether or
/// not a file is protected, so that type is listed beside audio and MPEG-4 files at large. FLAC is
/// org.xiph.flac, which Apple declares as audio, so public.audio covers it already; it is listed
/// so that FLAC stays offered should that ever change. Apple declares no type for Ogg files, which
/// AVFoundation cannot play, so on iOS the dialog offers them only where another app has declared
/// one as audio. Picking one then, or copying one into the Import folder, is refused with its format
/// named.
final _audiobooks = XTypeGroup(
  label: 'Audiobooks',
  extensions: [...audioExtensions],
  uniformTypeIdentifiers: const [
    'public.audio',
    'public.mpeg-4',
    'com.apple.protected-mpeg-4-audio',
    'org.xiph.flac',
  ],
);

enum _Adding { file, folder }

/// The app's home: the books to continue listening to, above the library, and where books are
/// added, with the "Add book" button or, on desktop, by dropping them onto the window.
///
/// The first tab of §2.6's shell. That section splits this into Home and Library tabs of their own;
/// until it does, this one screen is both, and Browse is the other tab.
class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  /// The category being shown, or null for all of them.
  ///
  /// Not kept in settings: which shelf you were last on is a place in a session, not a preference,
  /// and opening the app to find it filtered to something chosen days ago would look like books
  /// going missing.
  int? _category;

  /// What the shelf has been narrowed to. Kept in memory rather than in settings: a search is about
  /// the next ten seconds, and a library that opened still filtered from yesterday would look empty
  /// for no reason anyone could see.
  final _search = TextEditingController();
  var _searching = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _stopSearching() {
    _search.clear();
    setState(() => _searching = false);
  }

  @override
  Widget build(BuildContext context) {
    final library = ref.watch(libraryProvider);
    final sort = ref.watch(librarySortProvider).value ?? LibrarySort.fallback;
    final query = _search.text;
    final continueListening = ref.watch(continueListeningProvider);
    final services = ref.watch(servicesProvider);
    final locations = services.locations;
    final backupFolder = ref.watch(backupFolderProvider);
    // Until a folder is chosen, where one can be; not before the setting has been read, so the
    // reminder never flashes up for a library that has a folder.
    final remindToBackUp =
        services.backups.canChooseFolder &&
        backupFolder.hasValue &&
        backupFolder.value == null &&
        !ref.watch(backupReminderPutOffProvider);
    return BookDropZone(
      enabled: locations.acceptsDroppedFiles,
      onDropped: (paths) => _addDropped(context, ref, paths),
      child: AppShell(
        tab: AppTab.library,
        appBar: AppBar(
          title: _searching
              ? TextField(
                  controller: _search,
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                  decoration: const InputDecoration(
                    hintText: 'Search your library',
                    border: InputBorder.none,
                  ),
                  onChanged: (_) => setState(() {}),
                )
              : const Text('Kikuyomi'),
          leading: _searching
              ? IconButton(
                  tooltip: 'Stop searching',
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _stopSearching,
                )
              : null,
          // Downloads keeps an icon of its own because it is the one that means something at a
          // glance while a book is coming down. The rest go behind the overflow, which is where
          // Mihon puts them and what keeps a phone's app bar from filling with four icons.
          actions: [
            if (_searching)
              IconButton(
                tooltip: 'Clear',
                icon: const Icon(Icons.close),
                onPressed: () {
                  _search.clear();
                  setState(() {});
                },
              )
            else ...[
              IconButton(
                tooltip: 'Search your library',
                icon: const Icon(Icons.search),
                onPressed: () => setState(() => _searching = true),
              ),
              PopupMenuButton<LibrarySort>(
                tooltip: 'Order the shelf',
                icon: const Icon(Icons.sort),
                initialValue: sort,
                onSelected: (chosen) =>
                    services.settings.write(AppSettings.librarySort, chosen),
                itemBuilder: (context) => [
                  for (final order in LibrarySort.values)
                    PopupMenuItem(value: order, child: Text(order.label)),
                ],
              ),
            ],
            // Downloads, History and Settings have left this bar: the first two are tabs of their
            // own and the third is under More. What is left is the one action that belongs to the
            // library itself, and it only appears where there is a folder to look in.
            if (locations.importFolderIsVisible)
              PopupMenuButton<VoidCallback>(
                tooltip: 'More',
                onSelected: (action) => action(),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: () => _lookForNewBooks(context, ref),
                    child: const Text('Look for new books'),
                  ),
                ],
              ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _addBook(context, ref),
          icon: const Icon(Icons.add),
          label: const Text('Add book'),
        ),
        body: library.when(
          data: (books) => Column(
            children: [
              CategoryBar(
                categories: ref.watch(categoriesProvider).value ?? const [],
                counts: ref.watch(categoryCountsProvider).value ?? const {},
                selected: _category,
                onSelected: (id) => setState(() => _category = id),
              ),
              Expanded(
                child: HomeView(
                  // The library does not wait for Continue Listening; the shelf fills in when it arrives.
                  continueListening: continueListening.value ?? const [],
                  // A category with nothing in it reads as an empty set rather than as no filter, so an
                  // empty shelf says so instead of quietly showing the whole library.
                  library: arrangeLibrary(
                    books,
                    query: query,
                    sort: sort,
                    onlyBookIds: _category == null
                        ? null
                        : ref
                                  .watch(booksInCategoryProvider(_category!))
                                  .value ??
                              const <int>{},
                  ),
                  searchQuery: query,
                  covers: services.covers,
                  emptyMessage: locations.importFolderIsVisible
                      ? 'No books yet. Add an audiobook file, or copy books into the '
                            'Import folder under Kikuyomi in the Files app.'
                      : locations.acceptsDroppedFiles
                      ? 'No books yet. Add an audiobook file or a folder of audio '
                            'files, or drop them here, to start listening.'
                      : locations.canPickFolders
                      ? 'No books yet. Add an audiobook file, or a folder of audio '
                            'files, to start listening.'
                      : 'No books yet. Add an audiobook file to start listening.',
                  onResume: (bookId) => openBookInPlayer(context, ref, bookId),
                  onShowDetails: (bookId) =>
                      BookRoute(bookId: bookId).push<void>(context),
                  header: remindToBackUp
                      ? BackupReminderCard(
                          onChooseFolder: () => chooseBackupFolder(
                            context,
                            ref,
                            backUpAfter: books.isNotEmpty,
                          ),
                          onNotNow: () => ref
                              .read(backupReminderPutOffProvider.notifier)
                              .putOff(),
                        )
                      : null,
                ),
              ),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) =>
              Center(child: Text('Could not load the library: $error')),
        ),
      ),
    );
  }

  Future<void> _addBook(BuildContext context, WidgetRef ref) async {
    final services = ref.read(servicesProvider);
    final adding = services.locations.canPickFolders
        ? await _askWhatToAdd(context)
        : _Adding.file;
    if (adding == null || !context.mounted) return;
    // The pickers themselves can fail, as the iOS one did before its type group had type
    // identifiers, so they sit inside the handler too. Otherwise the button would silently do
    // nothing.
    try {
      switch (adding) {
        case _Adding.file:
          final file = await openFile(acceptedTypeGroups: [_audiobooks]);
          if (file == null) return;
          await services.addPickedBook(file.path);
        case _Adding.folder:
          final path = await getDirectoryPath();
          if (path == null) return;
          final added = await services.addFolderBook(path);
          if (!added.leftOut.isEmpty && context.mounted) {
            _tell(context, 'Added, leaving out ${added.leftOut.describe()}');
          }
      }
    } catch (error) {
      if (context.mounted) {
        _tell(context, 'Could not add the book: ${describeAddError(error)}');
      }
    }
  }

  /// Adds the audiobook files and folders dropped onto the window, each where it is, as a file or
  /// folder picked with "Add book" is added on desktop. Then one message says what became of them
  /// all, so that a pile of books dropped together is not reported one snack bar at a time.
  Future<void> _addDropped(
    BuildContext context,
    WidgetRef ref,
    List<String> paths,
  ) async {
    final services = ref.read(servicesProvider);
    try {
      final outcomes = await addDropped(
        await sortDropped(paths),
        addFile: (path) async => (
          title: await services.bookTitle(await services.addBookInPlace(path)),
          leftOut: LeftOut.none,
        ),
        addFolder: (path) async {
          final added = await services.addFolderBook(path);
          return (
            title: await services.bookTitle(added.bookId),
            leftOut: added.leftOut,
          );
        },
      );
      if (context.mounted) _tell(context, summarizeDrop(outcomes));
    } catch (error) {
      if (context.mounted) {
        _tell(context, 'Could not add what was dropped: $error');
      }
    }
  }

  Future<_Adding?> _askWhatToAdd(BuildContext context) =>
      showModalBottomSheet<_Adding>(
        context: context,
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.audio_file_outlined),
                title: const Text('An audiobook file'),
                subtitle: const Text('An M4B, MP3, FLAC or Ogg file'),
                onTap: () => Navigator.pop(context, _Adding.file),
              ),
              ListTile(
                leading: const Icon(Icons.folder_outlined),
                title: const Text('A folder of audio files'),
                subtitle: const Text('Each file becomes a chapter'),
                onTap: () => Navigator.pop(context, _Adding.folder),
              ),
            ],
          ),
        ),
      );

  Future<void> _lookForNewBooks(BuildContext context, WidgetRef ref) async {
    try {
      final scan = await ref.read(servicesProvider).scanImportFolder();
      if (context.mounted) _tell(context, summarizeImportScan(scan));
    } catch (error) {
      if (context.mounted) {
        _tell(context, 'Could not look for new books: $error');
      }
    }
  }
}

void _tell(BuildContext context, String message) =>
    tellInSnackBar(ScaffoldMessenger.of(context), message);
