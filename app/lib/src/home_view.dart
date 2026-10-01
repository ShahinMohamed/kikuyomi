import 'dart:math' as math;

import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show CustomSemanticsAction;
import 'package:kikuyomi_data/kikuyomi_data.dart'
    show BookRow, ContinueListeningBook, ContinueReadingBook, CoverFiles;
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
    this.continueListening = const [],
    this.continueReading = const [],
    required this.library,
    required this.covers,
    required this.emptyMessage,
    required this.onResume,
    required this.onShowDetails,
    this.onHideFromContinue,
    this.header,
    this.searchQuery = '',
  });

  final List<ContinueListeningBook> continueListening;

  /// The books being read, for the Read tab, which shows them where the Listen tab shows the books
  /// being listened to (ADR-0019). A tab passes one list or the other.
  final List<ContinueReadingBook> continueReading;
  final List<BookRow> library;

  /// Where the covers the books name are found.
  final CoverFiles covers;

  /// Shown in place of everything else while there are no books at all.
  final String emptyMessage;

  /// A book to continue was tapped: resume it.
  final ValueChanged<int> onResume;

  /// A book in the library was tapped: show its details.
  final ValueChanged<int> onShowDetails;

  /// The listener asked to take a book off the Continue shelf, or null where that is not offered.
  /// It keeps its place, and comes back when it is next played or read.
  final ValueChanged<int>? onHideFromContinue;

  /// Shown above everything else, books or none, such as the reminder to choose a backup folder.
  final Widget? header;

  /// What the library has been narrowed to, for saying what found nothing. The narrowing itself is
  /// already done: [library] is what to show.
  final String searchQuery;

  bool get _searching => searchQuery.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final header = this.header;
    final continuing = [
      for (final book in continueListening)
        (
          bookId: book.bookId,
          card: (VoidCallback onTap) =>
              ContinueListeningCard(book: book, covers: covers, onTap: onTap),
        ),
      for (final book in continueReading)
        (
          bookId: book.bookId,
          card: (VoidCallback onTap) =>
              ContinueReadingCard(book: book, covers: covers, onTap: onTap),
        ),
    ];
    if (continuing.isEmpty && library.isEmpty) {
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
        if (continuing.isNotEmpty && !_searching) ...[
          _SectionHeading(
            continueReading.isNotEmpty
                ? 'Continue reading'
                : 'Continue listening',
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _Shelf(
                books: continuing,
                onResume: onResume,
                onHide: onHideFromContinue,
                hideLabel: continueReading.isNotEmpty
                    ? 'Remove from Continue reading'
                    : 'Remove from Continue listening',
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

/// A book on the Continue Reading shelf: where the reader is, and how far through the book.
class ContinueReadingCard extends StatelessWidget {
  const ContinueReadingCard({
    super.key,
    required this.book,
    required this.covers,
    required this.onTap,
  });

  final ContinueReadingBook book;

  /// Where the book's cover is found.
  final CoverFiles covers;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final byline = [?book.author, book.chapterTitle].join(' · ');
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
                    Text(
                      byline,
                      style: theme.textTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(value: book.bookProgress),
                    const SizedBox(height: 4),
                    Text(
                      'Chapter ${book.chapterIndex + 1} of ${book.chapterCount}',
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

/// The books to continue.
///
/// On a wide window, one row of cards, with the rest a press away — never a sideways scroll, which
/// a mouse cannot do by dragging. On a phone, where a row is one card, a row the reader swipes
/// along instead, with the next card showing at the edge so it is plain there is more. That used to
/// be a stack of three cards with a button for the rest: a third of a phone's screen spent on a list
/// someone was scrolling past to reach their library.
///
/// Stateful only to remember whether the wide row has been opened up, which nothing above it needs
/// to know -- the same reason the chapter list holds its own selection. `HomeView` stays a pure
/// function of the library.
class _Shelf extends StatefulWidget {
  const _Shelf({
    required this.books,
    required this.onResume,
    required this.onHide,
    required this.hideLabel,
  });

  /// Each book on the go, with how to draw its card: a listening card or a reading one.
  final List<({int bookId, Widget Function(VoidCallback onTap) card})> books;
  final ValueChanged<int> onResume;

  /// Takes a book off the shelf, or null where that is not offered.
  final ValueChanged<int>? onHide;

  /// What taking a book off is called here: "Remove from Continue listening", or reading.
  final String hideLabel;

  @override
  State<_Shelf> createState() => _ShelfState();
}

class _ShelfState extends State<_Shelf> {
  /// Whether every book on the go is shown, rather than the one row that fits.
  var _expanded = false;

  static const _minCardWidth = 320.0;
  static const _gap = 8.0;

  /// [card] for book [bookId], with the way to take it off the shelf: a long press on a phone, a
  /// right click on a desktop, and a named action for a screen reader, which can do neither.
  Widget _removable(int bookId, Widget card) {
    final onHide = widget.onHide;
    if (onHide == null) return card;
    Future<void> menuAt(Offset at) async {
      final overlay =
          Overlay.of(context).context.findRenderObject()! as RenderBox;
      final chosen = await showMenu<bool>(
        context: context,
        position: RelativeRect.fromRect(
          at & const Size(1, 1),
          Offset.zero & overlay.size,
        ),
        items: [PopupMenuItem(value: true, child: Text(widget.hideLabel))],
      );
      if (chosen ?? false) onHide(bookId);
    }

    // Merged, so the action is on the node a screen reader actually focuses — the card itself. Left
    // on a node of its own around the card, it would be somewhere nobody using one ever arrives.
    return MergeSemantics(
      child: Semantics(
        customSemanticsActions: {
          CustomSemanticsAction(label: widget.hideLabel): () => onHide(bookId),
        },
        child: GestureDetector(
          onLongPressStart: (details) => menuAt(details.globalPosition),
          onSecondaryTapUp: (details) => menuAt(details.globalPosition),
          child: card,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth;
      final columns = math.max(
        1,
        ((width + _gap) / (_minCardWidth + _gap)).floor(),
      );
      final books = widget.books;
      if (columns == 1 && books.length > 1) {
        return _swipeAlong(width, books);
      }
      // Rounded down, so rounding never pushes the last card of a row onto the next.
      final cardWidth = ((width - _gap * (columns - 1)) / columns)
          .floorToDouble();
      // One row unless asked otherwise. A listener with ten books on the go had three rows of
      // cards above their library, which is most of a window spent on a list they were scrolling
      // past. How many fit is not known until here, so the decision is made here too.
      final shown = _expanded ? books.length : math.min(columns, books.length);
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
                  child: _removable(
                    book.bookId,
                    book.card(() => widget.onResume(book.bookId)),
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

  /// One card's height whatever the number of books, swiped along.
  ///
  /// Each card is a little narrower than the screen, so the next one shows at the edge: a row that
  /// fitted exactly would give no sign there was anything to swipe to. Not a lazy list, because a
  /// row of cards whose heights follow the text size cannot be given one fixed height, and the books
  /// someone is in the middle of are a handful, not hundreds.
  Widget _swipeAlong(
    double width,
    List<({int bookId, Widget Function(VoidCallback onTap) card})> books,
  ) {
    final cardWidth = (width * 0.86).floorToDouble();
    return ScrollConfiguration(
      // A narrow desktop window gets this row too, and a mouse has to be able to drag it.
      behavior: ScrollConfiguration.of(context)
          .copyWith(dragDevices: PointerDeviceKind.values.toSet()),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (index, book) in books.indexed) ...[
                if (index > 0) const SizedBox(width: _gap),
                SizedBox(
                  width: cardWidth,
                  child: _removable(
                    book.bookId,
                    book.card(() => widget.onResume(book.bookId)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
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
