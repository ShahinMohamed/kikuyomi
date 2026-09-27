import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:kikuyomi_data/kikuyomi_data.dart'
    show BookRow, ContinueListeningBook, CoverFiles;
import 'package:kikuyomi_design_system/kikuyomi_design_system.dart';

import 'format.dart';

/// The home: the books to continue listening to, above the library.
///
/// §2.6 gives Home and Library tabs of their own inside an adaptive shell. Until that shell exists
/// one screen holds both, with Continue Listening first because §1.5 calls it the most important
/// screen in the app.
///
/// Fed with data rather than watching providers, so it can be tested without a database.
class HomeView extends StatelessWidget {
  const HomeView({
    super.key,
    required this.continueListening,
    required this.library,
    required this.covers,
    required this.emptyMessage,
    required this.onResume,
    required this.onShowDetails,
    this.header,
    this.searchQuery = '',
  });

  final List<ContinueListeningBook> continueListening;
  final List<BookRow> library;

  /// Where the covers the books name are found.
  final CoverFiles covers;

  /// Shown in place of everything else while there are no books at all.
  final String emptyMessage;

  /// A book to continue was tapped: resume it.
  final ValueChanged<int> onResume;

  /// A book in the library was tapped: show its details.
  final ValueChanged<int> onShowDetails;

  /// Shown above everything else, books or none, such as the reminder to choose a backup folder.
  final Widget? header;

  /// What the library has been narrowed to, for saying what found nothing. The narrowing itself is
  /// already done: [library] is what to show.
  final String searchQuery;

  bool get _searching => searchQuery.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final header = this.header;
    if (continueListening.isEmpty && library.isEmpty) {
      final message = Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(emptyMessage, textAlign: TextAlign.center),
        ),
      );
      return header == null
          ? message
          : Column(
              children: [
                header,
                Expanded(child: message),
              ],
            );
    }
    return CustomScrollView(
      slivers: [
        if (header != null) SliverToBoxAdapter(child: header),
        if (continueListening.isNotEmpty && !_searching) ...[
          const _SectionHeading('Continue listening'),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _Shelf(
                books: continueListening,
                covers: covers,
                onResume: onResume,
              ),
            ),
          ),
        ],
        if (!_searching) const _SectionHeading('Library'),
        if (library.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
              child: Text(
                _searching
                    ? 'No book in your library matches ${'\u201c'}${searchQuery.trim()}${'\u201d'}.'
                    : emptyMessage,
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid.builder(
              // A covers grid rather than a list of rows: a cover is how anyone recognises a book
              // they own, and a shelf of them shows a dozen where rows showed four.
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                // Wide enough for a cover to be recognised, narrow enough that a phone fits
                // three across and a desktop window fills with them rather than stretching six.
                maxCrossAxisExtent: 150,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                // The cover is square; the rest is the two lines of title beneath it.
                childAspectRatio: 0.72,
              ),
              itemCount: library.length,
              itemBuilder: (context, index) => _ShelfBook(
                book: library[index],
                covers: covers,
                onTap: () => onShowDetails(library[index].id),
              ),
            ),
          ),
        // Room below the last book, so the "Add book" button never covers it.
        const SliverToBoxAdapter(child: SizedBox(height: 88)),
      ],
    );
  }
}

/// A book on the Continue Listening shelf: where the listener is, and how much is left.
class ContinueListeningCard extends StatelessWidget {
  const ContinueListeningCard({
    super.key,
    required this.book,
    required this.covers,
    required this.onTap,
  });

  final ContinueListeningBook book;

  /// Where the book's cover is found.
  final CoverFiles covers;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = book.totalDurationMs;
    final byline = [
      ?book.author,
      // A file without chapter markers has one chapter named after the book; saying so twice tells
      // the listener nothing.
      if (book.chapterTitle != book.title) book.chapterTitle,
    ].join(' · ');
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              BookCover(
                file: covers.fileOf(book.coverFileName),
                size: 64,
                semanticLabel: 'Cover of ${book.title}',
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: theme.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (byline.isNotEmpty)
                      Text(
                        byline,
                        style: theme.textTheme.bodyMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 8),
                    if (total != null && total > 0)
                      LinearProgressIndicator(
                        value: (book.globalPositionMs / total).clamp(0.0, 1.0),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      total == null
                          ? '${formatClock(book.globalPositionMs)} listened'
                          : '${formatClock(total - book.globalPositionMs)} left',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The books to continue, one to a row on a phone and several to a row on a wide window, so the
/// shelf never needs scrolling sideways, which a mouse cannot do by dragging.
/// Continue listening, one row of it.
///
/// Stateful only to remember whether it has been opened up, which nothing above it needs to know --
/// the same reason the chapter list holds its own selection. `HomeView` stays a pure function of
/// the library.
class _Shelf extends StatefulWidget {
  const _Shelf({
    required this.books,
    required this.covers,
    required this.onResume,
  });

  final List<ContinueListeningBook> books;
  final CoverFiles covers;
  final ValueChanged<int> onResume;

  @override
  State<_Shelf> createState() => _ShelfState();
}

class _ShelfState extends State<_Shelf> {
  /// Whether every book on the go is shown, rather than the one row that fits.
  var _expanded = false;

  static const _minCardWidth = 320.0;
  static const _gap = 8.0;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth;
      final columns = math.max(
        1,
        ((width + _gap) / (_minCardWidth + _gap)).floor(),
      );
      // Rounded down, so rounding never pushes the last card of a row onto the next.
      final cardWidth = ((width - _gap * (columns - 1)) / columns)
          .floorToDouble();
      // One row unless asked otherwise. A listener with ten books on the go had three rows of
      // cards above their library, which is most of a window spent on a list they were scrolling
      // past. How many fit is not known until here, so the decision is made here too.
      final books = widget.books;
      // One row, but never fewer than three cards. On a wide window a row is five and the cap does
      // nothing; on a phone a row is one, and collapsing ten books to a single card would hide two
      // that used to be in plain sight for no gain worth having.
      final shown = _expanded
          ? books.length
          : math.min(math.max(columns, 3), books.length);
      final hidden = books.length - shown;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: _gap,
            runSpacing: _gap,
            children: [
              for (final book in books.take(shown))
                SizedBox(
                  width: cardWidth,
                  child: ContinueListeningCard(
                    book: book,
                    covers: widget.covers,
                    onTap: () => widget.onResume(book.bookId),
                  ),
                ),
            ],
          ),
          // Nothing is hidden for good: the rest are a press away, and they are in the library and
          // in History besides.
          if (hidden > 0 || _expanded)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => setState(() => _expanded = !_expanded),
                child: Text(_expanded ? 'Show fewer' : 'Show $hidden more'),
              ),
            ),
        ],
      );
    },
  );
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Text(
          text,
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

/// One book on the shelf: its cover, with its title under it.
class _ShelfBook extends StatelessWidget {
  const _ShelfBook({
    required this.book,
    required this.covers,
    required this.onTap,
  });

  final BookRow book;
  final CoverFiles covers;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) => BookCover(
                file: covers.fileOf(book.coverLocalPath),
                size: constraints.maxWidth,
                semanticLabel: 'Cover of ${book.title}',
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            book.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
