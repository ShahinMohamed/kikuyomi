import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikuyomi_data/kikuyomi_data.dart'
    show BookOverview, ChapterOverview, readReadingPosition;
import 'package:kikuyomi_domain/kikuyomi_domain.dart' show AppSettings;

import '../providers.dart';
import '../services.dart';
import 'chapter_texts.dart';
import 'reader_view.dart';

/// Reading a book (ADR-0019), a chapter at a time. Reached through `ReaderRoute`.
///
/// Opens at [chapterId] when given, from its start, and otherwise where the reader left the book,
/// or at its first chapter. Where the reader is gets saved as they scroll, a moment after they
/// stop, and when they leave. Reaching the end of a chapter, or going on to the next, records the
/// chapter as finished, the same `is_listened` a listened chapter sets, so Continue Reading lets a
/// finished book go as Continue Listening does.
class ReaderScreen extends ConsumerStatefulWidget {
  const ReaderScreen({super.key, required this.bookId, this.chapterId});

  final int bookId;
  final int? chapterId;

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  /// Held from the start: the last place is saved when the screen goes, and by then `ref` may not
  /// be used.
  late final AppServices _services = ref.read(servicesProvider);

  int? _chapterId;
  double _openAt = 0;
  Future<ChapterText>? _text;

  /// The place last reported, saved a moment after scrolling stops rather than on every frame.
  double? _pending;
  Timer? _saveSoon;

  /// Chapters recorded as finished while this screen has been open, so reaching the end of one does
  /// not write again on every frame spent there.
  final _finished = <int>{};

  @override
  void initState() {
    super.initState();
    unawaited(_openFirst());
  }

  @override
  void dispose() {
    _saveSoon?.cancel();
    _saveNow();
    super.dispose();
  }

  Future<void> _openFirst() async {
    if (widget.chapterId case final chapterId?) {
      _open(chapterId, at: 0);
      return;
    }
    final place = await readReadingPosition(_services.database, widget.bookId);
    if (!mounted) return;
    if (place != null) {
      _open(place.chapterId, at: place.progress);
      return;
    }
    final book = await ref.read(bookOverviewProvider(widget.bookId).future);
    if (!mounted) return;
    final first = book?.chapters.firstOrNull;
    if (first == null) {
      setState(
        () => _text = Future.error(
          const ChapterTextException('This book has no chapters.'),
        ),
      );
      return;
    }
    _open(first.chapterId, at: 0);
  }

  /// Opens [chapterId] [at] a fraction through it, and records that the reader is there.
  void _open(int chapterId, {required double at}) {
    _saveSoon?.cancel();
    _saveNow();
    setState(() {
      _chapterId = chapterId;
      _openAt = at;
      _text = _services.chapterTexts.load(widget.bookId, chapterId);
    });
    unawaited(
      _services.saveReadingPlace(
        bookId: widget.bookId,
        chapterId: chapterId,
        progress: at,
      ),
    );
  }

  void _onProgress(double progress, bool atEnd) {
    final chapterId = _chapterId;
    if (chapterId == null) return;
    _pending = progress;
    _saveSoon?.cancel();
    _saveSoon = Timer(const Duration(milliseconds: 800), _saveNow);
    if (atEnd) _markFinished(chapterId);
  }

  void _saveNow() {
    final chapterId = _chapterId;
    final progress = _pending;
    if (chapterId == null || progress == null) return;
    _pending = null;
    unawaited(
      _services.saveReadingPlace(
        bookId: widget.bookId,
        chapterId: chapterId,
        progress: progress,
      ),
    );
  }

  void _markFinished(int chapterId) {
    if (!_finished.add(chapterId)) return;
    unawaited(
      _services.markChaptersListened(widget.bookId, {
        chapterId,
      }, listened: true),
    );
  }

  /// Goes on to [next], finishing the chapter being left: going on is saying so.
  void _goOn(ChapterOverview next) {
    final leaving = _chapterId;
    if (leaving != null) _markFinished(leaving);
    _open(next.chapterId, at: 0);
  }

  Future<void> _setTextScale(double scale) => _services.settings.write(
    AppSettings.readerTextScale,
    double.parse(scale.clamp(0.7, 2.0).toStringAsFixed(1)),
  );

  @override
  Widget build(BuildContext context) {
    final book = ref.watch(bookOverviewProvider(widget.bookId)).value;
    final textScale = ref.watch(readerTextScaleProvider).value ?? 1.0;
    final chapters = book?.chapters ?? const <ChapterOverview>[];
    final index = chapters.indexWhere((c) => c.chapterId == _chapterId);
    final chapter = index < 0 ? null : chapters[index];
    final previous = index > 0 ? chapters[index - 1] : null;
    final next = index >= 0 && index + 1 < chapters.length
        ? chapters[index + 1]
        : null;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              chapter?.title ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (book != null)
              Text(
                book.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Smaller text',
            icon: const Icon(Icons.text_decrease),
            onPressed: textScale <= 0.7
                ? null
                : () => _setTextScale(textScale - 0.1),
          ),
          IconButton(
            tooltip: 'Larger text',
            icon: const Icon(Icons.text_increase),
            onPressed: textScale >= 2.0
                ? null
                : () => _setTextScale(textScale + 0.1),
          ),
          if (book != null && chapters.length > 1)
            IconButton(
              tooltip: 'Chapters',
              icon: const Icon(Icons.toc),
              onPressed: () => _chooseChapter(context, book),
            ),
        ],
      ),
      body: FutureBuilder<ChapterText>(
        future: _text,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _Failed(
              error: snapshot.error!,
              onRetry: _chapterId == null
                  ? null
                  : () => _open(_chapterId!, at: _openAt),
            );
          }
          final text = snapshot.data;
          if (text == null ||
              snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          return ReaderView(
            key: ValueKey(_chapterId),
            blocks: text.content.blocks,
            pictures: text.pictures,
            textScale: textScale,
            initialProgress: _openAt,
            onProgress: _onProgress,
            onPrevious: previous == null
                ? null
                : () => _open(previous.chapterId, at: 0),
            onNext: next == null ? null : () => _goOn(next),
          );
        },
      ),
    );
  }

  Future<void> _chooseChapter(BuildContext context, BookOverview book) async {
    final chosen = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        builder: (context, scroll) => ListView(
          controller: scroll,
          children: [
            for (final chapter in book.chapters)
              ListTile(
                title: Text(chapter.title),
                selected: chapter.chapterId == _chapterId,
                trailing: chapter.listened
                    ? const Icon(Icons.done, size: 18)
                    : null,
                onTap: () => Navigator.pop(context, chapter.chapterId),
              ),
          ],
        ),
      ),
    );
    if (chosen != null && chosen != _chapterId) _open(chosen, at: 0);
  }
}

class _Failed extends StatelessWidget {
  const _Failed({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            error is ChapterTextException
                ? '$error'
                : 'This chapter could not be read: $error',
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ],
      ),
    ),
  );
}
