/// A source written in Dart, for everything that has to be tested without a site or an engine.
///
/// SourceAPI's `ContentSource` is what the app sees of every source, extension or built-in
/// (§3.4), so a fake one is enough to test the library writes, the media resolver and every Browse
/// screen. Nothing here runs JavaScript; what the real engine does with a real extension is the
/// probe's business (`spikes/quickjs_binding`).
library;

import 'package:kikuyomi_source_api/kikuyomi_source_api.dart';

/// A source whose answers a test decides.
///
/// Each method answers from the matching field, and each field may instead be told to fail, so that
/// every one of the contract's error kinds can be put in front of a screen. Every call is recorded,
/// so a test can say what was asked and how often.
final class FakeContentSource implements ContentSource {
  FakeContentSource({
    this.kind = SourceKind.audio,
    this.texts = const {},
    this.capabilities = const {},
    this.pages = const {},
    this.searchPages = const {},
    this.filters = const [],
    this.details = const {},
    this.chapters = const {},
    this.media = const {},
    this.imageRequest,
    this.failure,
    this.delay,
  });

  @override
  final SourceKind kind;

  /// What `getChapterContent` answers, by chapter key, for a text source.
  final Map<String, ChapterContent> texts;

  @override
  final Set<SourceCapability> capabilities;

  /// What `getPopular` answers, by page number. A page not here is empty.
  final Map<int, PageResult<BookSummary>> pages;

  /// What `search` answers, by the text searched for and the page. A page not here is empty.
  final Map<(String, int), PageResult<BookSummary>> searchPages;

  final List<Filter> filters;
  final Map<String, BookDetails> details;
  final Map<String, List<ChapterInfo>> chapters;

  /// What `resolveMedia` answers, by chapter key.
  final Map<String, MediaResolution> media;

  final HttpRequest? imageRequest;

  /// When set, every call fails with it. The one knob a test needs to put an error kind on screen.
  final SourceException? failure;

  /// How long each call takes, for a test that wants to see a screen while it is loading.
  final Duration? delay;

  /// Every call made, as `method(argument)`, in order.
  final calls = <String>[];

  /// What each search was asked with, so a test can check the filters reached the source.
  final searches = <SearchQuery>[];

  /// What each resolution was asked with.
  final resolutions = <(ChapterRef, ResolveContext)>[];

  Future<T> _answer<T>(String call, T Function() value) async {
    calls.add(call);
    final wait = delay;
    if (wait != null) await Future<void>.delayed(wait);
    final failure = this.failure;
    if (failure != null) throw failure;
    return value();
  }

  @override
  Future<PageResult<BookSummary>> getPopular(int page) => _answer(
    'getPopular($page)',
    () => pages[page] ?? PageResult(items: const [], hasNextPage: false),
  );

  @override
  Future<PageResult<BookSummary>> getLatest(int page) =>
      _answer('getLatest($page)', () {
        if (!capabilities.contains(SourceCapability.latest)) {
          throw UnsupportedError('this source has no getLatest()');
        }
        return pages[page] ?? PageResult(items: const [], hasNextPage: false);
      });

  @override
  Future<PageResult<BookSummary>> search(SearchQuery query, int page) =>
      _answer('search("${query.text}", $page)', () {
        searches.add(query);
        return searchPages[(query.text, page)] ??
            PageResult(items: const [], hasNextPage: false);
      });

  @override
  Future<List<Filter>> getFilters() => _answer('getFilters()', () {
    if (!capabilities.contains(SourceCapability.filters)) {
      throw UnsupportedError('this source has no getFilters()');
    }
    return filters;
  });

  @override
  Future<BookDetails> getBookDetails(String bookKey) =>
      _answer('getBookDetails($bookKey)', () {
        final found = details[bookKey];
        if (found == null) throw NotFoundException('no book $bookKey');
        return found;
      });

  @override
  Future<List<ChapterInfo>> getChapters(String bookKey) =>
      _answer('getChapters($bookKey)', () {
        final found = chapters[bookKey];
        if (found == null) throw NotFoundException('no book $bookKey');
        return found;
      });

  @override
  Future<MediaResolution> resolveMedia(
    ChapterRef chapter,
    ResolveContext context,
  ) => _answer('resolveMedia(${chapter.chapterKey})', () {
    resolutions.add((chapter, context));
    final found = media[chapter.chapterKey];
    if (found == null) {
      throw NotFoundException('no media for ${chapter.chapterKey}');
    }
    return found;
  });

  @override
  Future<ChapterContent> getChapterContent(ChapterRef chapter) =>
      _answer('getChapterContent(${chapter.chapterKey})', () {
        if (kind != SourceKind.text) {
          throw UnsupportedError('an audio source has no chapter text');
        }
        final found = texts[chapter.chapterKey];
        if (found == null) {
          throw NotFoundException('no text for ${chapter.chapterKey}');
        }
        return found;
      });

  @override
  Future<HttpRequest> getImageRequest(Uri url) =>
      _answer('getImageRequest($url)', () {
        if (!capabilities.contains(SourceCapability.imageRequest)) {
          throw UnsupportedError('this source has no getImageRequest()');
        }
        return imageRequest ?? HttpRequest(url: url);
      });
}
