import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/gestures.dart' show kPrimaryButton, kTouchSlop;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:kikuyomi_domain/kikuyomi_domain.dart' show ReaderMode;
import 'package:kikuyomi_source_api/kikuyomi_source_api.dart' as api;

/// The widest a line of text runs. About seventy characters at the body size, the measure book
/// typesetters settled on long ago: past it, the eye loses its place going back for the next line.
const readerMaxWidth = 680.0;

/// One chapter, drawn (ADR-0019): the blocks a source or an EPUB said, scrolled.
///
/// Fed with the chapter rather than loading it, so it can be tested without a database or a book.
/// Where the reader is goes out through [onProgress] as a fraction of the chapter, which is what is
/// saved: it survives a different text size or window, where a pixel offset would not.
class ReaderView extends StatefulWidget {
  const ReaderView({
    super.key,
    required this.blocks,
    this.pictures = const {},
    this.mode = ReaderMode.verticalScroll,
    this.textScale = 1.0,
    this.initialProgress = 0,
    this.onProgress,
    this.onPrevious,
    this.onNext,
    this.onTap,
    this.onUserScroll,
  });

  final List<api.ContentBlock> blocks;

  /// The bytes of pictures from inside the book, by the path an image block names.
  final Map<String, Uint8List> pictures;

  /// Whether this chapter scrolls vertically or flips through horizontal pages.
  final ReaderMode mode;

  /// How large text is drawn, as a multiple of the theme's body size.
  final double textScale;

  /// Where to open the chapter, from 0 at its start to 1 at its end.
  final double initialProgress;

  /// Where the reader is now, and whether they have reached the end of a chapter longer than the
  /// screen. A chapter that fits on the screen never reports reaching its end by being shown: that
  /// would finish every short chapter the moment it was opened.
  final void Function(double progress, bool atEnd)? onProgress;

  /// Goes to the chapter before, or null at the first.
  final VoidCallback? onPrevious;

  /// Goes to the chapter after, or null at the last.
  final VoidCallback? onNext;

  /// The reader tapped the page — not a long press to select, not a drag, not one of the chapter
  /// buttons at the end. What the reading screen shows or hides its bar on.
  final VoidCallback? onTap;

  /// The reader scrolled. Only the reader: jumping to where the chapter was left is not them
  /// starting to read, and must not hide a bar that has only just appeared.
  final VoidCallback? onUserScroll;

  @override
  State<ReaderView> createState() => _ReaderViewState();
}

class _ReaderViewState extends State<ReaderView> {
  final _scroll = ScrollController();
  late double _lastProgress;

  @override
  void initState() {
    super.initState();
    _lastProgress = widget.initialProgress;
    if (widget.mode == ReaderMode.verticalScroll) _restore();
  }

  @override
  void didUpdateWidget(ReaderView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newChapter = !identical(oldWidget.blocks, widget.blocks);
    if (newChapter) _lastProgress = widget.initialProgress;
    // A new chapter opens where it was left, not where the last one was scrolled to. Changing back
    // from pages keeps the equivalent place rather than returning to where the chapter first opened.
    if (widget.mode == ReaderMode.verticalScroll &&
        (newChapter || oldWidget.mode != widget.mode)) {
      _restore();
    }
  }

  @override
  void dispose() {
    _heldTooLong?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  /// Scrolls to [ReaderView.initialProgress] once the chapter has been laid out, which is the first
  /// moment its length is known.
  void _restore() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      final max = _scroll.position.maxScrollExtent;
      _scroll.jumpTo((_lastProgress.clamp(0.0, 1.0)) * max);
    });
  }

  // A tap is told apart from everything else a finger does on a page by hand, rather than with a
  // gesture detector. The text is selectable, and a detector would compete with selection for the
  // tap and lose it; a [Listener] is told about every pointer without taking part in that contest.
  Offset? _downAt;
  bool _downOnControl = false;
  bool _tapAllowed = false;

  /// A finger held down this long is selecting a word, not tapping. Timed rather than worked out
  /// from the events' own timestamps, which are not real time in a test and would let a long press
  /// through there unnoticed.
  Timer? _heldTooLong;

  void _onPointerDown(PointerDownEvent event) {
    // Listeners are told deepest first, so a press on a chapter button has already been noted by
    // the time this runs.
    _tapAllowed = !_downOnControl && event.buttons == kPrimaryButton;
    _downOnControl = false;
    _downAt = event.position;
    _heldTooLong?.cancel();
    _heldTooLong = Timer(
      const Duration(milliseconds: 400),
      () => _tapAllowed = false,
    );
  }

  void _onPointerUp(PointerUpEvent event) {
    _heldTooLong?.cancel();
    final at = _downAt;
    _downAt = null;
    if (!_tapAllowed || at == null) return;
    // Moved: that was a scroll, not a tap.
    if ((event.position - at).distance > kTouchSlop) return;
    widget.onTap?.call();
  }

  void _reportProgress(double progress, bool atEnd) {
    _lastProgress = progress;
    widget.onProgress?.call(progress, atEnd);
  }

  bool _onVerticalScroll(ScrollNotification notification) {
    if (notification is UserScrollNotification &&
        notification.direction != ScrollDirection.idle) {
      widget.onUserScroll?.call();
      return false;
    }
    if (notification is! ScrollUpdateNotification &&
        notification is! ScrollEndNotification) {
      return false;
    }
    final metrics = notification.metrics;
    final max = metrics.maxScrollExtent;
    if (max <= 0) return false;
    final progress = (metrics.pixels / max).clamp(0.0, 1.0);
    _reportProgress(progress, metrics.pixels >= max - 24);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final body = (theme.textTheme.bodyLarge ?? const TextStyle()).copyWith(
      fontSize: (theme.textTheme.bodyLarge?.fontSize ?? 16) * widget.textScale,
      height: 1.6,
    );
    // Whatever sits over the page — the reading screen's bar, a phone's notch and home indicator —
    // is room the first and last lines have to clear. Zero where there is none, as in a test.
    final insets = MediaQuery.paddingOf(context);
    return Listener(
      onPointerDown: _onPointerDown,
      onPointerUp: _onPointerUp,
      onPointerCancel: (_) => _downAt = null,
      child: switch (widget.mode) {
        ReaderMode.verticalScroll => NotificationListener<ScrollNotification>(
          onNotification: _onVerticalScroll,
          child: Scrollbar(
            controller: _scroll,
            child: SingleChildScrollView(
              // One column rather than a lazy list. A lazy list only guesses at the length of what
              // it has not built, and a fraction of a guess is not a place anyone could return to.
              controller: _scroll,
              padding: EdgeInsets.fromLTRB(
                20,
                24 + insets.top,
                20,
                24 + insets.bottom,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: readerMaxWidth),
                  child: _ReaderBody(
                    blocks: widget.blocks,
                    pictures: widget.pictures,
                    body: body,
                    onPrevious: widget.onPrevious,
                    onNext: widget.onNext,
                    onControlPointerDown: () => _downOnControl = true,
                  ),
                ),
              ),
            ),
          ),
        ),
        ReaderMode.horizontalPages => _HorizontalReader(
          blocks: widget.blocks,
          pictures: widget.pictures,
          body: body,
          initialProgress: _lastProgress,
          insets: insets,
          onProgress: _reportProgress,
          onUserScroll: widget.onUserScroll,
          onPrevious: widget.onPrevious,
          onNext: widget.onNext,
        ),
      },
    );
  }
}

/// The continuous vertical column, including its explicit chapter controls.
class _ReaderBody extends StatelessWidget {
  const _ReaderBody({
    required this.blocks,
    required this.pictures,
    required this.body,
    required this.onPrevious,
    required this.onNext,
    this.onControlPointerDown,
  });

  final List<api.ContentBlock> blocks;
  final Map<String, Uint8List> pictures;
  final TextStyle body;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback? onControlPointerDown;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = <Widget>[
      if (blocks.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: Text(
            'This chapter has nothing in it to read.',
            textAlign: TextAlign.center,
            style: body.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
      for (final block in blocks)
        _Block(block: block, body: body, pictures: pictures),
      const SizedBox(height: 32),
      // A press here is a press on a button, never a tap on the page: going on to the next chapter
      // should not also toggle the bar.
      Listener(
        onPointerDown: onControlPointerDown == null
            ? null
            : (_) => onControlPointerDown!(),
        child: _ChapterEnd(onPrevious: onPrevious, onNext: onNext),
      ),
    ];
    return SelectionArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: items,
      ),
    );
  }
}

/// A chapter as screen-sized pages. [PageView] provides the platform's smooth, interruptible page
/// animation. The chapter is split into actual line fragments before it is drawn, so a page never
/// clips a line and never has to repeat the whole paragraph on the next page.
class _HorizontalReader extends StatefulWidget {
  const _HorizontalReader({
    required this.blocks,
    required this.pictures,
    required this.body,
    required this.initialProgress,
    required this.insets,
    required this.onProgress,
    required this.onUserScroll,
    required this.onPrevious,
    required this.onNext,
  });

  final List<api.ContentBlock> blocks;
  final Map<String, Uint8List> pictures;
  final TextStyle body;
  final double initialProgress;
  final EdgeInsets insets;
  final void Function(double progress, bool atEnd) onProgress;
  final VoidCallback? onUserScroll;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  State<_HorizontalReader> createState() => _HorizontalReaderState();
}

class _HorizontalReaderState extends State<_HorizontalReader> {
  Object? _layoutToken;
  PageController? _pages;
  late double _progress = widget.initialProgress;
  var _contentPageCount = 1;
  var _leadingPages = 0;
  var _leavingChapter = false;

  @override
  void dispose() {
    _pages?.dispose();
    super.dispose();
  }

  void _rememberCurrentProgress() {
    final pages = _pages;
    if (pages == null || _contentPageCount < 2 || !pages.hasClients) return;
    final contentPage =
        (pages.page ?? pages.initialPage.toDouble()) - _leadingPages;
    _progress = (contentPage / (_contentPageCount - 1)).clamp(0.0, 1.0);
  }

  bool _onPageScroll(ScrollNotification notification) {
    if (notification is UserScrollNotification &&
        notification.direction != ScrollDirection.idle) {
      widget.onUserScroll?.call();
    }
    if (notification is! ScrollUpdateNotification &&
        notification is! ScrollEndNotification) {
      return false;
    }
    final pages = _pages;
    if (pages == null) return false;
    final contentPage =
        (pages.page ?? pages.initialPage.toDouble()) - _leadingPages;
    if (_contentPageCount < 2) {
      _progress = contentPage > 0.25 ? 1 : 0;
    } else {
      _progress = (contentPage / (_contentPageCount - 1)).clamp(0.0, 1.0);
    }
    final atEnd = _contentPageCount < 2
        ? contentPage > 0.25
        : contentPage >= _contentPageCount - 1.01;
    widget.onProgress(_progress, atEnd);
    return false;
  }

  void _onPageChanged(int page) {
    if (_leavingChapter) return;
    if (_leadingPages == 1 && page == 0) {
      _leavingChapter = true;
      widget.onPrevious?.call();
      return;
    }
    if (widget.onNext != null && page == _leadingPages + _contentPageCount) {
      _leavingChapter = true;
      widget.onNext!();
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      const horizontalPadding = 20.0;
      final topPadding = 24 + widget.insets.top;
      final bottomPadding = 24 + widget.insets.bottom;
      final pageHeight = math.max(
        1.0,
        constraints.maxHeight - topPadding - bottomPadding,
      );
      final contentWidth = math.max(
        1.0,
        math.min(readerMaxWidth, constraints.maxWidth - horizontalPadding * 2),
      );
      final contentPages = _paginateChapter(
        blocks: widget.blocks,
        body: widget.body,
        pageWidth: contentWidth,
        // A small allowance protects against fractional font metrics rounding up during layout.
        pageHeight: math.max(1.0, pageHeight - 4),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
        locale: Localizations.maybeLocaleOf(context),
      );
      final leadingPages = widget.onPrevious == null ? 0 : 1;
      final token = (
        contentWidth,
        pageHeight,
        widget.body,
        identityHashCode(widget.blocks),
        Directionality.of(context),
        MediaQuery.textScalerOf(context),
        widget.onPrevious != null,
        widget.onNext != null,
      );
      if (_layoutToken != token) {
        _rememberCurrentProgress();
        final retired = _pages;
        _contentPageCount = contentPages.length;
        _leadingPages = leadingPages;
        _leavingChapter = false;
        _pages = PageController(
          initialPage:
              leadingPages +
              ((_contentPageCount - 1) * _progress.clamp(0.0, 1.0)).round(),
        );
        _layoutToken = token;
        if (retired != null) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => retired.dispose(),
          );
        }
      }
      final itemCount =
          leadingPages + contentPages.length + (widget.onNext == null ? 0 : 1);
      return NotificationListener<ScrollNotification>(
        onNotification: _onPageScroll,
        child: PageView.builder(
          controller: _pages,
          // Forward is a swipe to the left; back, including the previous chapter, is to the right.
          reverse: false,
          physics: const PageScrollPhysics(),
          itemCount: itemCount,
          onPageChanged: _onPageChanged,
          itemBuilder: (context, index) {
            final contentIndex = index - leadingPages;
            if (contentIndex < 0 || contentIndex >= contentPages.length) {
              return const SizedBox.expand();
            }
            return Semantics(
              container: true,
              label: 'Page ${contentIndex + 1} of ${contentPages.length}',
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  topPadding,
                  horizontalPadding,
                  bottomPadding,
                ),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    width: contentWidth,
                    height: pageHeight,
                    child: _PageContents(
                      pieces: contentPages[contentIndex],
                      chapterIsEmpty: widget.blocks.isEmpty,
                      pictures: widget.pictures,
                      body: widget.body,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
    },
  );
}

final class _PagePiece {
  const _PagePiece(
    this.block, {
    this.runs,
    this.preformattedText,
    this.firstPart = true,
    this.lastPart = true,
    this.maxPictureHeight,
  });

  final api.ContentBlock block;
  final List<api.TextRun>? runs;
  final String? preformattedText;
  final bool firstPart;
  final bool lastPart;
  final double? maxPictureHeight;
}

final class _MeasuredLine {
  const _MeasuredLine(this.start, this.end, this.height);

  final int start;
  final int end;
  final double height;
}

List<List<_PagePiece>> _paginateChapter({
  required List<api.ContentBlock> blocks,
  required TextStyle body,
  required double pageWidth,
  required double pageHeight,
  required TextDirection textDirection,
  required TextScaler textScaler,
  required Locale? locale,
}) {
  final pages = <List<_PagePiece>>[[]];
  final size = body.fontSize ?? 16;
  var used = 0.0;

  void nextPage() {
    if (pages.last.isEmpty) return;
    pages.add([]);
    used = 0;
  }

  void addFixed(_PagePiece piece, double height) {
    if (pages.last.isNotEmpty && used + height > pageHeight) nextPage();
    pages.last.add(piece);
    used += height;
  }

  void addText(
    api.ContentBlock block,
    List<api.TextRun> runs,
    TextStyle style, {
    required double width,
    required double top,
    required double bottom,
  }) {
    final lines = _measureLines(
      runs,
      style,
      width: width,
      textDirection: textDirection,
      textScaler: textScaler,
      locale: locale,
    );
    var firstLine = 0;
    var firstPart = true;
    while (firstLine < lines.length) {
      final topSpace = firstPart ? top : 0.0;
      final available = pageHeight - used;
      var lineHeight = 0.0;
      var endLine = firstLine;
      while (endLine < lines.length) {
        final candidate = lineHeight + lines[endLine].height;
        final isLast = endLine + 1 == lines.length;
        if (topSpace + candidate + (isLast ? bottom : 0) > available + 0.01) {
          break;
        }
        lineHeight = candidate;
        endLine++;
      }
      if (endLine == firstLine && pages.last.isNotEmpty) {
        nextPage();
        continue;
      }
      if (endLine == firstLine) {
        lineHeight = lines[firstLine].height;
        endLine++;
      }
      final lastPart = endLine == lines.length;
      pages.last.add(
        _PagePiece(
          block,
          runs: _sliceRuns(
            runs,
            lines[firstLine].start,
            lines[endLine - 1].end,
          ),
          firstPart: firstPart,
          lastPart: lastPart,
        ),
      );
      used += topSpace + lineHeight + (lastPart ? bottom : 0);
      firstLine = endLine;
      firstPart = false;
      if (!lastPart) nextPage();
    }
  }

  void addPreformatted(api.PreformattedBlock block) {
    final style = body.copyWith(fontFamily: 'monospace', height: 1.4);
    final painter = TextPainter(
      text: TextSpan(text: 'M', style: style),
      textDirection: textDirection,
      textScaler: textScaler,
      locale: locale,
    )..layout();
    final lines = block.text.split('\n');
    var first = 0;
    while (first < lines.length) {
      final available = pageHeight - used;
      if (pages.last.isNotEmpty && painter.preferredLineHeight > available) {
        nextPage();
        continue;
      }
      final canTake = math.max(
        1,
        (available / painter.preferredLineHeight).floor(),
      );
      final take = math.min(canTake, lines.length - first);
      final last = first + take == lines.length;
      if (last &&
          pages.last.isNotEmpty &&
          take * painter.preferredLineHeight + size * 0.9 > available) {
        nextPage();
        continue;
      }
      pages.last.add(
        _PagePiece(
          block,
          preformattedText: lines.sublist(first, first + take).join('\n'),
          firstPart: first == 0,
          lastPart: last,
        ),
      );
      used += take * painter.preferredLineHeight + (last ? size * 0.9 : 0);
      first += take;
      if (!last) nextPage();
    }
  }

  for (final block in blocks) {
    switch (block) {
      case api.ParagraphBlock(:final runs):
        addText(
          block,
          runs,
          body,
          width: pageWidth,
          top: 0,
          bottom: size * 0.9,
        );
      case api.HeadingBlock(:final level, :final runs):
        addText(
          block,
          runs,
          _headingStyle(body, level),
          width: pageWidth,
          top: size * 0.8,
          bottom: size * 0.8,
        );
      case api.QuoteBlock(:final runs):
        addText(
          block,
          runs,
          body,
          width: math.max(1.0, pageWidth - 16),
          top: 0,
          bottom: size * 0.9,
        );
      case api.ListItemBlock(:final runs, :final depth):
        addText(
          block,
          runs,
          body,
          width: math.max(1.0, pageWidth - 8 - depth * 24 - size * 2),
          top: 0,
          bottom: size * 0.4,
        );
      case api.PreformattedBlock():
        addPreformatted(block);
      case api.ImageBlock():
        nextPage();
        pages.last.add(
          _PagePiece(
            block,
            maxPictureHeight: math.max(1.0, pageHeight - size * 0.9),
          ),
        );
        used = pageHeight;
      case api.RuleBlock():
        final painter = TextPainter(
          text: TextSpan(text: '⁂', style: body),
          textDirection: textDirection,
          textScaler: textScaler,
          locale: locale,
        )..layout(maxWidth: pageWidth);
        addFixed(_PagePiece(block), painter.height + size * 2);
    }
  }
  if (pages.length > 1 && pages.last.isEmpty) pages.removeLast();
  return pages;
}

List<_MeasuredLine> _measureLines(
  List<api.TextRun> runs,
  TextStyle style, {
  required double width,
  required TextDirection textDirection,
  required TextScaler textScaler,
  required Locale? locale,
}) {
  final painter = TextPainter(
    text: _spanOf(runs, style),
    textDirection: textDirection,
    textScaler: textScaler,
    locale: locale,
  )..layout(maxWidth: width);
  final textLength = runs.fold<int>(
    0,
    (length, run) => length + run.text.length,
  );
  final metrics = painter.computeLineMetrics();
  if (metrics.isEmpty) {
    return [_MeasuredLine(0, textLength, painter.preferredLineHeight)];
  }
  final lines = <_MeasuredLine>[];
  var previousEnd = 0;
  for (var index = 0; index < metrics.length; index++) {
    final metric = metrics[index];
    final position = painter.getPositionForOffset(
      Offset(width / 2, metric.baseline - metric.ascent / 2),
    );
    final boundary = painter.getLineBoundary(position);
    final start = previousEnd;
    final end = index + 1 == metrics.length
        ? textLength
        : math.max(start, boundary.end);
    lines.add(_MeasuredLine(start, end, metric.height));
    previousEnd = end;
  }
  return lines;
}

List<api.TextRun> _sliceRuns(List<api.TextRun> runs, int start, int end) {
  final sliced = <api.TextRun>[];
  var offset = 0;
  for (final run in runs) {
    final runEnd = offset + run.text.length;
    final from = math.max(start, offset);
    final to = math.min(end, runEnd);
    if (from < to) {
      sliced.add(
        api.TextRun(
          run.text.substring(from - offset, to - offset),
          bold: run.bold,
          italic: run.italic,
        ),
      );
    }
    offset = runEnd;
    if (offset >= end) break;
  }
  return sliced;
}

class _PageContents extends StatelessWidget {
  const _PageContents({
    required this.pieces,
    required this.chapterIsEmpty,
    required this.pictures,
    required this.body,
  });

  final List<_PagePiece> pieces;
  final bool chapterIsEmpty;
  final Map<String, Uint8List> pictures;
  final TextStyle body;

  @override
  Widget build(BuildContext context) {
    if (chapterIsEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Text(
          'This chapter has nothing in it to read.',
          textAlign: TextAlign.center,
          style: body.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final piece in pieces)
          _Block(
            block: piece.block,
            body: body,
            pictures: pictures,
            maxPictureHeight: piece.maxPictureHeight,
            fragmentRuns: piece.runs,
            fragmentText: piece.preformattedText,
            firstPart: piece.firstPart,
            lastPart: piece.lastPart,
          ),
      ],
    );
  }
}

/// The runs of a block as one span, with their emphasis.
TextSpan _spanOf(List<api.TextRun> runs, TextStyle style) => TextSpan(
  style: style,
  children: [
    for (final run in runs)
      TextSpan(
        text: run.text,
        style: TextStyle(
          fontWeight: run.bold ? FontWeight.bold : null,
          fontStyle: run.italic ? FontStyle.italic : null,
        ),
      ),
  ],
);

TextStyle _headingStyle(TextStyle body, int level) {
  final size = body.fontSize ?? 16;
  return body.copyWith(
    // A step down per level, from about twice the body size at the top.
    fontSize:
        size *
        switch (level) {
          1 => 1.9,
          2 => 1.55,
          3 => 1.3,
          _ => 1.1,
        },
    height: 1.3,
    fontWeight: FontWeight.w600,
  );
}

class _Block extends StatelessWidget {
  const _Block({
    required this.block,
    required this.body,
    required this.pictures,
    this.maxPictureHeight,
    this.fragmentRuns,
    this.fragmentText,
    this.firstPart = true,
    this.lastPart = true,
  });

  final api.ContentBlock block;
  final TextStyle body;
  final Map<String, Uint8List> pictures;
  final double? maxPictureHeight;
  final List<api.TextRun>? fragmentRuns;
  final String? fragmentText;
  final bool firstPart;
  final bool lastPart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = body.fontSize ?? 16;
    return switch (block) {
      api.ParagraphBlock(:final runs) => Padding(
        padding: EdgeInsets.only(bottom: lastPart ? size * 0.9 : 0),
        child: Text.rich(_spanOf(fragmentRuns ?? runs, body)),
      ),
      api.HeadingBlock(:final level, :final runs) => Padding(
        padding: EdgeInsets.only(
          top: firstPart ? size * 0.8 : 0,
          bottom: lastPart ? size * 0.8 : 0,
        ),
        child: Text.rich(
          _spanOf(fragmentRuns ?? runs, _headingStyle(body, level)),
        ),
      ),
      api.QuoteBlock(:final runs) => Container(
        margin: EdgeInsets.only(bottom: lastPart ? size * 0.9 : 0),
        padding: const EdgeInsets.only(left: 16),
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: theme.colorScheme.outlineVariant, width: 3),
          ),
        ),
        child: Text.rich(
          _spanOf(
            fragmentRuns ?? runs,
            body.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
      ),
      api.ListItemBlock(:final runs, :final number, :final depth) => Padding(
        padding: EdgeInsets.only(
          left: 8.0 + depth * 24,
          bottom: lastPart ? size * 0.4 : 0,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: size * 2,
              child: firstPart
                  ? Text(number == null ? '•' : '$number.', style: body)
                  : null,
            ),
            Expanded(child: Text.rich(_spanOf(fragmentRuns ?? runs, body))),
          ],
        ),
      ),
      api.PreformattedBlock(:final text) => Padding(
        padding: EdgeInsets.only(bottom: lastPart ? size * 0.9 : 0),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Text(
            fragmentText ?? text,
            style: body.copyWith(fontFamily: 'monospace', height: 1.4),
          ),
        ),
      ),
      api.ImageBlock(:final url, :final alt) => Padding(
        padding: EdgeInsets.only(bottom: size * 0.9),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: maxPictureHeight ?? double.infinity,
          ),
          child: _Picture(url: url, alt: alt, pictures: pictures),
        ),
      ),
      api.RuleBlock() => Padding(
        padding: EdgeInsets.symmetric(vertical: size),
        child: Text(
          '⁂',
          textAlign: TextAlign.center,
          style: body.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ),
    };
  }
}

/// A picture: from inside the book when its address has no scheme, from the web otherwise. One that
/// will not load shows what it was of, when the book said.
class _Picture extends StatelessWidget {
  const _Picture({
    required this.url,
    required this.alt,
    required this.pictures,
  });

  final Uri url;
  final String? alt;
  final Map<String, Uint8List> pictures;

  @override
  Widget build(BuildContext context) {
    Widget missing(BuildContext context, Object error, StackTrace? stack) =>
        alt == null || alt!.trim().isEmpty
        ? const SizedBox.shrink()
        : Text(
            '[${alt!.trim()}]',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          );
    final label = alt?.trim();
    if (!url.hasScheme) {
      final bytes = pictures[url.path];
      if (bytes == null) return missing(context, 'absent', null);
      return Image.memory(
        bytes,
        semanticLabel: label,
        fit: BoxFit.contain,
        errorBuilder: missing,
      );
    }
    return Image.network(
      url.toString(),
      semanticLabel: label,
      fit: BoxFit.contain,
      errorBuilder: missing,
    );
  }
}

/// The foot of a chapter: the way to the next one, and back.
class _ChapterEnd extends StatelessWidget {
  const _ChapterEnd({required this.onPrevious, required this.onNext});

  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 24),
    child: Row(
      children: [
        if (onPrevious != null)
          OutlinedButton.icon(
            onPressed: onPrevious,
            icon: const Icon(Icons.chevron_left),
            label: const Text('Previous'),
          ),
        const Spacer(),
        if (onNext != null)
          FilledButton.icon(
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right),
            label: const Text('Next chapter'),
            iconAlignment: IconAlignment.end,
          )
        else
          Text('The end', style: Theme.of(context).textTheme.titleMedium),
      ],
    ),
  );
}
