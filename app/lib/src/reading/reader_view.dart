import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/gestures.dart' show kPrimaryButton, kTouchSlop;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
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

  @override
  void initState() {
    super.initState();
    _restore();
  }

  @override
  void didUpdateWidget(ReaderView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A new chapter opens where it was left, not where the last one was scrolled to.
    if (!identical(oldWidget.blocks, widget.blocks)) _restore();
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
      _scroll.jumpTo((widget.initialProgress.clamp(0.0, 1.0)) * max);
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

  bool _onScroll(ScrollNotification notification) {
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
    widget.onProgress?.call(progress, metrics.pixels >= max - 24);
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
      child: NotificationListener<ScrollNotification>(
        onNotification: _onScroll,
        child: Scrollbar(
          controller: _scroll,
          child: SingleChildScrollView(
            // One column rather than a lazy list. A lazy list only guesses at the length of what it
            // has not built, and a fraction of a guess is not a place anyone could come back to.
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
                child: SelectionArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (widget.blocks.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 48),
                          child: Text(
                            'This chapter has nothing in it to read.',
                            textAlign: TextAlign.center,
                            style: body.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      for (final block in widget.blocks)
                        _Block(
                          block: block,
                          body: body,
                          pictures: widget.pictures,
                        ),
                      const SizedBox(height: 32),
                      // A press here is a press on a button, never a tap on the page: going on to the
                      // next chapter should not also toggle the bar.
                      Listener(
                        onPointerDown: (_) => _downOnControl = true,
                        child: _ChapterEnd(
                          onPrevious: widget.onPrevious,
                          onNext: widget.onNext,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
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

class _Block extends StatelessWidget {
  const _Block({
    required this.block,
    required this.body,
    required this.pictures,
  });

  final api.ContentBlock block;
  final TextStyle body;
  final Map<String, Uint8List> pictures;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = body.fontSize ?? 16;
    return switch (block) {
      api.ParagraphBlock(:final runs) => Padding(
        padding: EdgeInsets.only(bottom: size * 0.9),
        child: Text.rich(_spanOf(runs, body)),
      ),
      api.HeadingBlock(:final level, :final runs) => Padding(
        padding: EdgeInsets.only(top: size * 0.8, bottom: size * 0.8),
        child: Text.rich(
          _spanOf(
            runs,
            body.copyWith(
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
            ),
          ),
        ),
      ),
      api.QuoteBlock(:final runs) => Container(
        margin: EdgeInsets.only(bottom: size * 0.9),
        padding: const EdgeInsets.only(left: 16),
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: theme.colorScheme.outlineVariant, width: 3),
          ),
        ),
        child: Text.rich(
          _spanOf(
            runs,
            body.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
      ),
      api.ListItemBlock(:final runs, :final number, :final depth) => Padding(
        padding: EdgeInsets.only(left: 8.0 + depth * 24, bottom: size * 0.4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: size * 2,
              child: Text(number == null ? '•' : '$number.', style: body),
            ),
            Expanded(child: Text.rich(_spanOf(runs, body))),
          ],
        ),
      ),
      api.PreformattedBlock(:final text) => Padding(
        padding: EdgeInsets.only(bottom: size * 0.9),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Text(
            text,
            style: body.copyWith(fontFamily: 'monospace', height: 1.4),
          ),
        ),
      ),
      api.ImageBlock(:final url, :final alt) => Padding(
        padding: EdgeInsets.only(bottom: size * 0.9),
        child: _Picture(url: url, alt: alt, pictures: pictures),
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
