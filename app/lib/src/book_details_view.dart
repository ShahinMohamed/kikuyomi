import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:kikuyomi_data/kikuyomi_data.dart'
    show BookOverview, ChapterDownload, CoverFiles;
import 'package:kikuyomi_design_system/kikuyomi_design_system.dart';

import 'downloads/book_downloads.dart';
import 'format.dart';
import 'listened_commands.dart';

/// Where the play button starts a book.
enum PlayFrom {
  /// Where it was left, or the beginning of a book never started.
  savedPosition,

  /// The beginning, for a finished book played again.
  start,
}

/// A book's details: its credits and length, where the listener is, its chapters, and what can be
/// done with it.
///
/// Each chapter can be marked listened or not from a menu on its row, and the whole book marked
/// finished or not (§4.5). What is marked is what the book's details, Continue Listening and the
/// player all read, so a mark wins over wherever the listener has been. A single file's embedded
/// markers have no menu: §4.5 records listened state for the file's one chapter, not for a marker,
/// so marking the book finished or not is how it is set.
///
/// A chapter row does three things, and which of them a tap means is decided by where it lands.
/// Tapping the row plays from that chapter; tapping the arrow on the right downloads it; the menu
/// marks it listened. Playing is the one a listener does most, so it gets the whole row, and the
/// other two get targets of their own rather than sharing it through a long press -- a long press
/// is not reachable by keyboard, and a screen reader cannot announce one.
///
/// Fed with data rather than watching providers, so it can be tested without a database.
class BookDetailsView extends StatelessWidget {
  const BookDetailsView({
    super.key,
    required this.book,
    required this.covers,
    required this.onRemove,
    required this.listenedCommands,
    this.downloads = BookDownloads.none,
    this.chapterDownloads = const {},
    this.onDownload,
    this.onStopDownloading,
    this.onAddToLibrary,
    this.onOpenAtSource,
    this.onPlayChapter,
    this.onPlayFrom,
    this.onDownloadChapters,
    this.onRefresh,
    this.onOpenDownloadQueue,
  });

  final BookOverview book;

  /// Where the book's cover is found.
  final CoverFiles covers;

  /// Called once the listener has confirmed they want the book out of the library.
  final VoidCallback onRemove;

  /// Marking chapters, and the whole book, listened or not.
  final ListenedCommands listenedCommands;

  /// How far this book's download has got (§5.2).
  final BookDownloads downloads;

  /// Asks for every file of the book that is not already here. Null where downloading makes no
  /// sense, as it does not for a book whose files are already on this device.
  final VoidCallback? onDownload;

  /// Gives up on what is queued or running.
  final VoidCallback? onStopDownloading;

  /// Puts a book that has been taken out back in. Null while nothing offers to, which leaves the
  /// action showing what is true and doing nothing.
  final VoidCallback? onAddToLibrary;

  /// Opens the book's page at its source in a browser. Null for a book with no page, which a local
  /// import has none of.
  final VoidCallback? onOpenAtSource;

  /// Where each chapter's audio is, by chapter id (§5.2). Chapters missing from the map read as
  /// [ChapterDownload.absent].
  final Map<int, ChapterDownload> chapterDownloads;

  /// Plays the book from the start of a chapter.
  final ValueChanged<int>? onPlayChapter;

  /// Plays the book from a position in it, in milliseconds from the start.
  ///
  /// What an embedded marker needs. A marker is not a chapter and has no id: §4.5 presents the
  /// markers of a single-file book as its chapters, and what identifies one is where it begins.
  final ValueChanged<int>? onPlayFrom;

  /// Queues the files behind these chapters, in the order given.
  final ValueChanged<List<int>>? onDownloadChapters;

  /// Asks the source for the book again. Null for a book with no source to ask.
  final Future<void> Function()? onRefresh;

  /// Opens the downloads screen, from the chapter list's own menu, where a listener who has just
  /// queued twenty chapters is looking.
  final VoidCallback? onOpenDownloadQueue;

  /// The chapters a "download the next few" action would take, in order: those not listened to and
  /// not already here, starting at where the listener is.
  ///
  /// Listened chapters are skipped rather than counted, so "next 5" after finishing ten means the
  /// five after those ten, not five of them again. Chapters already downloaded are skipped for the
  /// same reason: a listener asking for five wants five more, not five rows that were already
  /// green.
  List<int> _nextChapters([int? count]) {
    final wanted = <int>[];
    for (final chapter in book.chapters) {
      if (chapter.listened) continue;
      if (chapterDownloads[chapter.chapterId] == ChapterDownload.here) continue;
      wanted.add(chapter.chapterId);
      if (count != null && wanted.length >= count) break;
    }
    return wanted;
  }

  /// Wider than this, the content stays at a readable measure in the middle of the window.
  static const _maxContentWidth = 720.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = book.progress;
    final finished = book.finished;
    final total = book.totalDurationMs;
    final description = book.description;
    return LayoutBuilder(
      builder: (context, constraints) {
        // Padding rather than a narrower list, so the whole window still scrolls it.
        final side = math.max(
          16.0,
          (constraints.maxWidth - _maxContentWidth) / 2,
        );
        // Slivers, not a `ListView` of children. Everything above the chapters is one block, and
        // the chapters build a row as it is about to be seen. Before this, a four-hundred-chapter
        // podcast built every row on every frame, and rebuilt all of them whenever anything on the
        // page changed -- which, while a download runs, is several times a second.
        final list = CustomScrollView(
          // Always scrollable, so that a short book can still be pulled down to refresh.
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(side, 16, side, 0),
              sliver: SliverList.list(
                children: [
                  _Header(book: book, covers: covers),
                  const SizedBox(height: 16),
                  _ActionStrip(
                    inLibrary: book.inLibrary,
                    finished: finished,
                    downloads: downloads,
                    onLibrary: book.inLibrary
                        ? () => _confirmRemoval(context)
                        : onAddToLibrary,
                    onDownload: onDownload,
                    onStopDownloading: onStopDownloading,
                    nextChapters: _nextChapters,
                    allChapters: [
                      for (final chapter in book.chapters) chapter.chapterId,
                    ],
                    onDownloadChapters: onDownloadChapters,
                    onOpenDownloadQueue: onOpenDownloadQueue,
                    onFinished: () => finished
                        ? markBookNotFinished(context, listenedCommands)
                        : markBookFinishedWithUndo(context, listenedCommands),
                    onOpenAtSource: onOpenAtSource,
                  ),
                  // Nothing here for a finished book: the strip's lit "Finished" says it, and a book
                  // marked finished by hand may never have been started, so there is no progress to draw.
                  if (!finished && progress != null) ...[
                    const SizedBox(height: 16),
                    if (total != null && total > 0)
                      LinearProgressIndicator(
                        value: (progress.globalPositionMs / total).clamp(
                          0.0,
                          1.0,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      total == null
                          ? '${formatClock(progress.globalPositionMs)} listened'
                          : '${formatClock(total - progress.globalPositionMs)} left',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                  if (!downloads.isEmpty && !downloads.isComplete) ...[
                    const SizedBox(height: 16),
                    _DownloadProgress(downloads: downloads),
                  ],
                  if (description != null && description.trim().isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _Description(text: description.trim()),
                  ],
                  if (book.genres.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final genre in book.genres)
                          Chip(
                            label: Text(genre),
                            visualDensity: VisualDensity.compact,
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
            _ChapterList(
              book: book,
              finished: finished,
              side: side,
              chapterDownloads: chapterDownloads,
              listenedCommands: listenedCommands,
              onPlayChapter: onPlayChapter,
              onPlayFrom: onPlayFrom,
              onDownloadChapters: onDownloadChapters,
            ),
            // Room at the foot for the floating button, which would otherwise sit on the last row.
            const SliverToBoxAdapter(child: SizedBox(height: 96)),
          ],
        );
        // Pull to refresh, where there is a source to ask. This is the whole of the app's answer to
        // a serial that keeps publishing: a listener who wonders whether there is a new chapter
        // pulls the page they are already looking at, rather than the app sweeping the library on a
        // schedule to answer a question nobody asked.
        final refresh = onRefresh;
        return refresh == null
            ? list
            : RefreshIndicator(onRefresh: refresh, child: list);
      },
    );
  }

  Future<void> _confirmRemoval(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove from library?'),
        content: Text(
          '${book.title} will no longer be in your library. Your progress '
          'is kept and no files are deleted, so adding the book again '
          'brings it back where you left off.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) onRemove();
  }
}

/// A book's entries, and picking some of them out.
///
/// A sliver, so that a book with four hundred chapters builds the dozen rows on screen rather than
/// all of them. That is not a micro-optimisation: as a `Column` of every row inside a `ListView` it
/// dropped a phone to about five frames a second whenever anything on the page changed.
///
/// Stateful for one reason: holding a row selects it, and what is selected is nobody else's
/// business. The screen above does not need to know, and keeping it here means the rest of the
/// details page stays a pure function of the book.
///
/// §4.5: a single file's embedded markers are its chapters as far as the listener is concerned.
/// A marker can be played from and cannot be downloaded or selected -- there is one file, and it is
/// either here or it is not -- so those rows are plainer, deliberately.
class _ChapterList extends StatefulWidget {
  const _ChapterList({
    required this.book,
    required this.finished,
    required this.side,
    required this.chapterDownloads,
    required this.listenedCommands,
    required this.onPlayChapter,
    required this.onPlayFrom,
    required this.onDownloadChapters,
  });

  final BookOverview book;
  final bool finished;

  /// How far the page is inset, which this has to apply itself: it is a sliver of its own, so the
  /// padding around the block above it does not reach here.
  final double side;
  final Map<int, ChapterDownload> chapterDownloads;
  final ListenedCommands listenedCommands;
  final ValueChanged<int>? onPlayChapter;
  final ValueChanged<int>? onPlayFrom;
  final ValueChanged<List<int>>? onDownloadChapters;

  @override
  State<_ChapterList> createState() => _ChapterListState();
}

class _ChapterListState extends State<_ChapterList> {
  final _selected = <int>{};

  /// Whether the listener is picking chapters out rather than reading the list.
  bool get _selecting => _selected.isNotEmpty;

  void _toggle(int chapterId) => setState(() {
    if (!_selected.remove(chapterId)) _selected.add(chapterId);
  });

  void _clear() => setState(_selected.clear);

  void _selectAll() => setState(() {
    _selected.addAll([
      for (final chapter in widget.book.chapters) chapter.chapterId,
    ]);
  });

  /// Queues what is selected, in the book's own order rather than the order they were tapped.
  void _downloadSelected() {
    final wanted = [
      for (final chapter in widget.book.chapters)
        if (_selected.contains(chapter.chapterId)) chapter.chapterId,
    ];
    _clear();
    widget.onDownloadChapters?.call(wanted);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final book = widget.book;
    final markers = book.markers;
    final rows = markers.isNotEmpty ? markers.length : book.chapters.length;
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: widget.side),
      sliver: SliverMainAxisGroup(
        slivers: [
          SliverToBoxAdapter(
            child: _selecting
                ? _SelectionBar(
                    count: _selected.length,
                    onDownload: widget.onDownloadChapters == null
                        ? null
                        : _downloadSelected,
                    onSelectAll: _selectAll,
                    onClear: _clear,
                  )
                : Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _countLabel(),
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
          // One row built as it is about to be seen, rather than four hundred built every frame.
          SliverList.builder(
            itemCount: rows,
            itemBuilder: (context, index) =>
                markers.isNotEmpty ? _marker(index) : _chapter(index),
          ),
        ],
      ),
    );
  }

  /// One embedded marker (§4.5).
  ///
  /// Playable, like a chapter row. Before it was, a single-file book's rows did nothing at all when
  /// tapped, which looked exactly like the app being broken. It cannot be downloaded or selected:
  /// there is one file, and it is either here or it is not.
  Widget _marker(int index) {
    final marker = widget.book.markers[index];
    return _EntryTile(
      title: marker.title,
      durationMs: marker.durationMs,
      listened: marker.listened,
      current: marker.current && !widget.finished,
      onPlay: widget.onPlayFrom == null
          ? null
          : () => widget.onPlayFrom!(marker.startMs),
    );
  }

  Widget _chapter(int index) {
    final chapter = widget.book.chapters[index];
    return _EntryTile(
      title: chapter.title,
      durationMs: chapter.durationMs,
      listened: chapter.listened,
      current: chapter.current && !widget.finished,
      download:
          widget.chapterDownloads[chapter.chapterId] ?? ChapterDownload.absent,
      selected: _selected.contains(chapter.chapterId),
      // While something is selected a tap adds to the selection instead of playing. Once you are
      // choosing, you are choosing, and a stray tap must not start playback.
      onPlay: _selecting
          ? () => _toggle(chapter.chapterId)
          : widget.onPlayChapter == null
          ? null
          : () => widget.onPlayChapter!(chapter.chapterId),
      onSelect: widget.onDownloadChapters == null
          ? null
          : () => _toggle(chapter.chapterId),
      onDownload: widget.onDownloadChapters == null
          ? null
          : () => widget.onDownloadChapters!([chapter.chapterId]),
      onMark: (listened) => markChapterListened(
        context,
        widget.listenedCommands,
        chapterId: chapter.chapterId,
        listened: listened,
      ),
    );
  }

  /// How many entries the list below holds, as a heading rather than a bare word.
  ///
  /// The count is the useful part -- it is how a listener judges at a glance whether a book is three
  /// hours or sixty chapters -- and it is what the heading in Mihon says too.
  String _countLabel() {
    final count = widget.book.markers.isNotEmpty
        ? widget.book.markers.length
        : widget.book.chapters.length;
    return count == 1 ? '1 chapter' : '$count chapters';
  }
}

/// What the chapter count turns into while chapters are picked out.
class _SelectionBar extends StatelessWidget {
  const _SelectionBar({
    required this.count,
    required this.onDownload,
    required this.onSelectAll,
    required this.onClear,
  });

  final int count;
  final VoidCallback? onDownload;
  final VoidCallback onSelectAll;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      IconButton(
        icon: const Icon(Icons.close),
        tooltip: 'Stop selecting',
        onPressed: onClear,
      ),
      Expanded(
        child: Text(
          count == 1 ? '1 selected' : '$count selected',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
      IconButton(
        icon: const Icon(Icons.select_all),
        tooltip: 'Select every chapter',
        onPressed: onSelectAll,
      ),
      IconButton(
        icon: const Icon(Icons.download_outlined),
        tooltip: count == 1 ? 'Download 1 chapter' : 'Download $count chapters',
        onPressed: onDownload,
      ),
    ],
  );
}

/// One chapter, or embedded marker, in the list.
class _EntryTile extends StatelessWidget {
  const _EntryTile({
    required this.title,
    required this.durationMs,
    required this.listened,
    required this.current,
    this.download = ChapterDownload.absent,
    this.selected = false,
    this.onPlay,
    this.onSelect,
    this.onDownload,
    this.onMark,
  });

  final String title;
  final int? durationMs;
  final bool listened;

  /// Where this chapter's audio is (§5.2).
  final ChapterDownload download;

  /// Whether this row is one of the chapters picked out for a bulk action.
  final bool selected;

  /// Plays the book from here, or adds this row to the selection while one is running. Null for a
  /// row that cannot be played from.
  final VoidCallback? onPlay;

  /// Starts or extends a selection, on a long press. Null where there is nothing to select for.
  final VoidCallback? onSelect;

  /// Queues this chapter's files. Null where there is nothing to fetch.
  final VoidCallback? onDownload;

  /// Where the listener is. Not shown for a finished book, where it would only point at the end.
  final bool current;

  /// Marks the chapter listened, or with false not listened, from the row's menu. Null for a row
  /// with no listened state of its own to set, which has no menu.
  final ValueChanged<bool>? onMark;

  @override
  Widget build(BuildContext context) {
    final duration = durationMs;
    final onMark = this.onMark;
    final length = duration == null ? null : Text(formatClock(duration));
    return ListTile(
      contentPadding: EdgeInsets.zero,
      // A picked row is marked by its tile, the way the row being played is. The two cannot be
      // confused: only one row is ever current, and a selection has its own bar above the list.
      selected: current || selected,
      selectedTileColor: selected
          ? Theme.of(context).colorScheme.primaryContainer
          : null,
      onTap: onPlay,
      onLongPress: onSelect,
      leading: SizedBox.square(
        dimension: 24,
        child: selected
            ? const Icon(Icons.check_circle, semanticLabel: 'Selected')
            : current
            ? const Icon(Icons.graphic_eq, semanticLabel: 'Where you are')
            : listened
            ? Icon(
                Icons.check,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                semanticLabel: 'Listened',
              )
            : null,
      ),
      title: Text(title),
      trailing: onMark == null
          ? length
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ?length,
                if (onDownload != null)
                  _ChapterDownloadButton(
                    title: title,
                    state: download,
                    onDownload: onDownload!,
                  ),
                // A button of its own, rather than a long press on the row, so the menu is found and
                // reached the same way by mouse, touch and keyboard, and a screen reader names it.
                PopupMenuButton<bool>(
                  tooltip: 'Options for $title',
                  onSelected: onMark,
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: !listened,
                      child: Text(
                        listened ? 'Mark as not listened' : 'Mark as listened',
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

/// The arrow on a chapter row, and what it is doing.
///
/// One control with four faces rather than four controls: a listener looks at a row to find out
/// whether that chapter is on the device, and the answer belongs where the action is.
class _ChapterDownloadButton extends StatelessWidget {
  const _ChapterDownloadButton({
    required this.title,
    required this.state,
    required this.onDownload,
  });

  final String title;
  final ChapterDownload state;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return switch (state) {
      // The three states with nothing to press are drawn rather than disabled, and they absorb
      // their own taps. A disabled button does not stop a tap: without absorbing, it falls through
      // to the row, which plays the book from here -- so a listener aiming at an inert tick, or a
      // screen reader activating one, would start playback instead of nothing.
      ChapterDownload.here => _inert(
        tooltip: '$title is downloaded',
        child: Icon(Icons.download_done, color: colors.primary),
      ),
      ChapterDownload.working => _inert(
        tooltip: 'Downloading $title',
        child: const SizedBox.square(
          dimension: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      ChapterDownload.queued => _inert(
        tooltip: '$title is waiting to download',
        child: const Icon(Icons.hourglass_empty),
      ),
      ChapterDownload.failed => IconButton(
        icon: const Icon(Icons.error_outline),
        color: colors.error,
        onPressed: onDownload,
        tooltip: '$title did not download. Try again',
      ),
      ChapterDownload.absent => IconButton(
        icon: const Icon(Icons.arrow_circle_down_outlined),
        onPressed: onDownload,
        tooltip: 'Download $title',
      ),
    };
  }

  /// A state with nothing to press, sized and placed like the buttons beside it so that the column
  /// of arrows stays a column.
  ///
  /// The empty `onTap` is doing real work and is not a placeholder. A tap here must not reach the
  /// row underneath, which plays the book from this chapter, and neither a disabled button nor an
  /// `AbsorbPointer` stops that: absorbing keeps events from a widget's own descendants, while the
  /// row's ink well is its *ancestor* and still wins the gesture arena. A recognizer of its own,
  /// deeper in the tree, is what beats it.
  Widget _inert({required String tooltip, required Widget child}) =>
      GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {},
        child: Tooltip(
          message: tooltip,
          child: Semantics(
            label: tooltip,
            child: SizedBox.square(dimension: 48, child: Center(child: child)),
          ),
        ),
      );
}

/// Downloading several chapters at once, hung off the strip's Download cell.
///
/// The counts are what a listener actually wants: enough for the commute, enough for the flight, or
/// the lot. Each skips what is listened and what is already here, so "next 5" is five more rather
/// than five it already had.
///
/// It lives on the Download button rather than beside the chapter count, because "download" is the
/// word a listener is looking for and there should be one of it. An arrow above the list was a
/// second control that did the same job and said less about what it was for.
class _DownloadMenu extends StatelessWidget {
  const _DownloadMenu({
    required this.next,
    required this.all,
    required this.onDownloadChapters,
    required this.onOpenDownloadQueue,
    required this.child,
  });

  final List<int> Function([int? count]) next;

  /// Every chapter of the book, listened or not, for the one item that does not mean "next".
  final List<int> all;

  final ValueChanged<List<int>> onDownloadChapters;
  final VoidCallback? onOpenDownloadQueue;

  /// What the menu hangs off: the strip's Download cell.
  final Widget child;

  @override
  Widget build(BuildContext context) => PopupMenuButton<VoidCallback>(
    tooltip: 'Download chapters',
    // No padding and no splash of its own: the cell it wraps draws all of that, and a menu button
    // with its own ink would put a second ripple inside the first.
    padding: EdgeInsets.zero,
    onSelected: (action) => action(),
    itemBuilder: (context) => [
      PopupMenuItem(
        value: () => onDownloadChapters(next(1)),
        child: const Text('Next chapter'),
      ),
      PopupMenuItem(
        value: () => onDownloadChapters(next(5)),
        child: const Text('Next 5 chapters'),
      ),
      PopupMenuItem(
        value: () => onDownloadChapters(next(10)),
        child: const Text('Next 10 chapters'),
      ),
      PopupMenuItem(
        value: () => onDownloadChapters(next()),
        child: const Text('All unlistened chapters'),
      ),
      PopupMenuItem(
        value: () => onDownloadChapters(all),
        child: const Text('All chapters'),
      ),
      if (onOpenDownloadQueue != null) ...[
        const PopupMenuDivider(),
        PopupMenuItem(
          value: onOpenDownloadQueue!,
          child: const Text('Download queue'),
        ),
      ],
    ],
    // The strip's own cell. Without this, `PopupMenuButton` falls back to its default overflow
    // glyph, and the Download button silently became three dots -- which is exactly what happened,
    // because the tests reached the menu by its tooltip and never looked at what it drew.
    child: child,
  );
}

/// What a book's download is doing, under the buttons.
///
/// A bar and a sentence. The sentence carries the reason the queue is waiting, because "waiting for
/// Wi-Fi" is something a listener can act on and "waiting" is something that makes them wonder
/// whether the app has stopped.
class _DownloadProgress extends StatelessWidget {
  const _DownloadProgress({required this.downloads});

  final BookDownloads downloads;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = downloads.progress;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // A determinate bar where the sizes are known, and a moving one where they are not: a bar
        // that guesses would jump backwards the moment the guess was corrected.
        // Determinate where the sizes are known, and a moving bar where they are not: a bar that
        // guessed would jump backwards the moment the guess was corrected.
        LinearProgressIndicator(value: progress),
        const SizedBox(height: 6),
        Text(
          describeDownloads(downloads),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// What the play button says for [book].
///
/// A top-level function because the button itself is the screen's floating one, and this is the one
/// piece of judgement it needs: a book never started is played, one left part-way is resumed, and a
/// finished one is played again from the top.
String playButtonLabel(BookOverview book) => book.finished
    ? 'Play again'
    : book.progress == null
    ? 'Start'
    : 'Resume';

/// Where the play button starts [book].
PlayFrom playButtonFrom(BookOverview book) =>
    book.finished ? PlayFrom.start : PlayFrom.savedPosition;

/// The cover beside what the source says about the book.
///
/// Side by side rather than stacked, so the title, the credits, the length and where the book came
/// from are all above the fold on a phone. Stacked under a full-width cover, everything that
/// identifies a book was pushed off the first screen.
class _Header extends StatelessWidget {
  const _Header({required this.book, required this.covers});

  final BookOverview book;
  final CoverFiles covers;

  /// Big enough to recognise a cover by, small enough to leave the metadata a readable column.
  static const _coverWidth = 120.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = book.totalDurationMs;
    final source = [?book.status, ?book.sourceName].join(' • ');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BookCover(
          file: covers.fileOf(book.coverFileName),
          size: _coverWidth,
          semanticLabel: 'Cover of ${book.title}',
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                book.title,
                style: theme.textTheme.titleLarge,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              if (book.authors.isNotEmpty)
                _MetaRow(
                  icon: Icons.person_outline,
                  text: book.authors.join(', '),
                  semanticLabel: 'Author',
                ),
              if (book.narrators.isNotEmpty)
                _MetaRow(
                  icon: Icons.mic_none,
                  text: book.narrators.join(', '),
                  semanticLabel: 'Narrator',
                ),
              if (total != null)
                _MetaRow(
                  icon: Icons.schedule,
                  text: formatClock(total),
                  semanticLabel: 'Length',
                ),
              if (source.isNotEmpty)
                _MetaRow(
                  icon: Icons.public,
                  text: source,
                  semanticLabel: 'Source',
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// One line of the header: a small icon and what it says.
class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.icon,
    required this.text,
    required this.semanticLabel,
  });

  final IconData icon;
  final String text;

  /// What the icon means, for a screen reader. The icon alone is decoration and says nothing.
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 16,
            color: theme.colorScheme.onSurfaceVariant,
            semanticLabel: semanticLabel,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// The row of things that can be done with the book, as icons over labels.
///
/// A strip rather than a wrap of buttons, because these are states as much as actions: whether the
/// book is in the library, whether it is downloaded, whether it is finished. An icon lit or not says
/// that at a glance, where a row of outlined buttons all look alike until they are read.
///
/// A cell with nothing to do is shown all the same, dimmed. Hiding it would move the others under
/// the listener's finger between one visit and the next.
class _ActionStrip extends StatelessWidget {
  const _ActionStrip({
    required this.inLibrary,
    required this.finished,
    required this.downloads,
    required this.onLibrary,
    required this.onDownload,
    required this.onStopDownloading,
    required this.onFinished,
    required this.onOpenAtSource,
    required this.nextChapters,
    required this.allChapters,
    required this.onDownloadChapters,
    required this.onOpenDownloadQueue,
  });

  final bool inLibrary;
  final bool finished;
  final BookDownloads downloads;
  final VoidCallback? onLibrary;
  final VoidCallback? onDownload;
  final VoidCallback? onStopDownloading;
  final VoidCallback onFinished;
  final VoidCallback? onOpenAtSource;
  final List<int> Function([int? count]) nextChapters;
  final List<int> allChapters;
  final ValueChanged<List<int>>? onDownloadChapters;
  final VoidCallback? onOpenDownloadQueue;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _Action(
        icon: inLibrary ? Icons.favorite : Icons.favorite_border,
        label: inLibrary ? 'In library' : 'Add to library',
        active: inLibrary,
        onTap: onLibrary,
      ),
      _downloadAction(),
      _Action(
        icon: finished ? Icons.done_all : Icons.check_circle_outline,
        label: finished ? 'Finished' : 'Mark finished',
        active: finished,
        onTap: onFinished,
      ),
      _Action(
        icon: Icons.open_in_new,
        label: 'Source',
        active: false,
        onTap: onOpenAtSource,
      ),
    ],
  );

  /// One cell with three faces, because at any moment there is exactly one thing worth doing: ask
  /// for the book, stop asking, or nothing at all.
  Widget _downloadAction() {
    if (downloads.isComplete) {
      return const _Action(
        icon: Icons.download_done,
        label: 'Downloaded',
        active: true,
        onTap: null,
      );
    }
    // While bytes are moving, the one useful thing is to stop them. Not `isEmpty`: a book that is
    // four chapters in and idle has tasks and is not complete, and it is exactly the book whose
    // owner wants the menu to ask for ten more.
    if (downloads.isWorking) {
      return _Action(
        icon: Icons.stop_circle_outlined,
        label: 'Stop',
        active: true,
        onTap: onStopDownloading,
      );
    }
    if (onDownloadChapters != null) {
      // The whole book is one of the things this menu offers, so the cell opens the menu rather
      // than being a second way to ask for the same thing. The `Expanded` stays out here, because a
      // flex child has to be the Row's own child; the menu goes inside it.
      return Expanded(
        child: _DownloadMenu(
          next: nextChapters,
          all: allChapters,
          onDownloadChapters: onDownloadChapters!,
          onOpenDownloadQueue: onOpenDownloadQueue,
          child: const _ActionFace(
            icon: Icons.download_outlined,
            label: 'Download',
            active: false,
            dim: false,
          ),
        ),
      );
    }
    return _Action(
      icon: Icons.download_outlined,
      label: 'Download',
      active: false,
      onTap: onDownload,
    );
  }
}

/// One cell of the strip.
class _Action extends StatelessWidget {
  const _Action({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;

  /// Whether this is a state the book is in, which is what the accent colour says.
  final bool active;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Expanded(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: _ActionFace(
        icon: icon,
        label: label,
        active: active,
        dim: onTap == null,
      ),
    ),
  );
}

/// What one cell looks like, without the [Expanded] around it.
///
/// Split out because the [Expanded] has to be the strip's own child -- a flex child cannot be
/// wrapped in anything else -- and the Download cell is wrapped, in the menu it opens. Wrapping the
/// whole cell instead threw `Incorrect use of ParentDataWidget` on every build of the page.
class _ActionFace extends StatelessWidget {
  const _ActionFace({
    required this.icon,
    required this.label,
    required this.active,
    required this.dim,
  });

  final IconData icon;
  final String label;
  final bool active;

  /// Whether there is nothing to press, which greys it.
  final bool dim;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colour = dim && !active
        ? theme.colorScheme.outlineVariant
        : active
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        children: [
          Icon(icon, color: colour),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: theme.textTheme.labelSmall?.copyWith(color: colour),
          ),
        ],
      ),
    );
  }
}

/// What the source says about the book, folded to a few lines until it is asked to open.
///
/// Folded by default because a description can run to several paragraphs and the chapters are what
/// most visits are for. The whole box is the target rather than the chevron alone, since a paragraph
/// of text is easier to hit than a small arrow.
class _Description extends StatefulWidget {
  const _Description({required this.text});

  final String text;

  @override
  State<_Description> createState() => _DescriptionState();
}

class _DescriptionState extends State<_Description> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => setState(() => _open = !_open),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.text,
              style: theme.textTheme.bodyMedium,
              maxLines: _open ? null : 3,
              overflow: _open ? TextOverflow.clip : TextOverflow.ellipsis,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Icon(
                _open ? Icons.expand_less : Icons.expand_more,
                size: 20,
                color: theme.colorScheme.onSurfaceVariant,
                semanticLabel: _open ? 'Show less' : 'Show more',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
