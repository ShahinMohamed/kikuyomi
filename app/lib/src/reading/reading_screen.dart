import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikuyomi_domain/kikuyomi_domain.dart';
import 'package:kikuyomi_source_api/kikuyomi_source_api.dart' show SourceKind;

import '../app_shell.dart';
import '../book_files.dart';
import '../home_view.dart';
import '../library/library_shelf.dart';
import '../providers.dart';
import '../routes.dart';
import '../snack_bars.dart';

/// The files "Add ebook" offers. iOS goes by type identifier, and org.idpf.epub-container is the
/// one Apple declares for EPUB.
const _ebooks = XTypeGroup(
  label: 'EPUB books',
  extensions: ['epub'],
  uniformTypeIdentifiers: ['org.idpf.epub-container'],
);

/// The Read tab (ADR-0019): the books being read, above the books to read in the library, and where
/// an EPUB is added.
///
/// The Listen tab's counterpart, laid out the same way on purpose: the same shelf, the same order,
/// the same cards, so moving between the two is moving between shelves rather than between apps.
class ReadingScreen extends ConsumerStatefulWidget {
  const ReadingScreen({super.key});

  @override
  ConsumerState<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends ConsumerState<ReadingScreen> {
  final _search = TextEditingController();
  var _searching = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shelf = ref.watch(shelfProvider(SourceKind.text));
    final sort = ref.watch(librarySortProvider).value ?? LibrarySort.fallback;
    final services = ref.watch(servicesProvider);
    return AppShell(
      tab: AppTab.reading,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: _searching
            ? TextField(
                controller: _search,
                autofocus: true,
                textInputAction: TextInputAction.search,
                decoration: const InputDecoration(
                  hintText: 'Search your books',
                  border: InputBorder.none,
                ),
                onChanged: (_) => setState(() {}),
              )
            : const Text('Read'),
        leading: _searching
            ? IconButton(
                tooltip: 'Stop searching',
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  _search.clear();
                  setState(() => _searching = false);
                },
              )
            : null,
        actions: [
          if (!_searching)
            IconButton(
              tooltip: 'Search your books',
              icon: const Icon(Icons.search),
              onPressed: () => setState(() => _searching = true),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addEbook(context),
        icon: const Icon(Icons.add),
        label: const Text('Add ebook'),
      ),
      body: shelf.when(
        data: (books) => HomeView(
          continueReading: ref.watch(continueReadingProvider).value ?? const [],
          library: arrangeLibrary(books, query: _search.text, sort: sort),
          searchQuery: _search.text,
          covers: services.covers,
          emptyMessage: services.locations.importFolderIsVisible
              ? 'No books to read yet. Add an EPUB, or copy one into the Import '
                    'folder under Kikuyomi in the Files app.'
              : 'No books to read yet. Add an EPUB to start reading.',
          onResume: (bookId) => ReaderRoute(bookId: bookId).push<void>(context),
          onShowDetails: (bookId) =>
              BookRoute(bookId: bookId).push<void>(context),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('Could not load your books: $error')),
      ),
    );
  }

  Future<void> _addEbook(BuildContext context) async {
    final services = ref.read(servicesProvider);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final file = await openFile(acceptedTypeGroups: [_ebooks]);
      if (file == null) return;
      final bookId = await services.addPickedEbook(file.path);
      tellInSnackBar(messenger, 'Added ${await services.bookTitle(bookId)}');
    } catch (error) {
      tellInSnackBar(
        messenger,
        'Could not add the book: ${describeAddError(error)}',
      );
    }
  }
}
