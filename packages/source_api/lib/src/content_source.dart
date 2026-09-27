/// SourceAPI's `Source`, as the rest of the app sees every source.
///
/// The JavaScript adapter in `source_runtime` implements [ContentSource] over QuickJS (§3.6), and
/// built-in sources implement it natively: Local first, then Audiobookshelf and OPDS. The rest of
/// the app cannot tell the two apart.
library;

import 'errors.dart';
import 'models/book.dart';
import 'models/chapter.dart';
import 'models/http_request.dart';
import 'models/media.dart';
import 'models/page_result.dart';
import 'models/search.dart';
import 'models/text.dart';

/// The optional methods of [ContentSource], which a source declares it has.
enum SourceCapability {
  /// [ContentSource.getLatest]: the source can list recently added books.
  latest,

  /// [ContentSource.getFilters]: search takes filters.
  filters,

  /// [ContentSource.getImageRequest]: covers need headers or cookies. Without it, a cover is
  /// fetched with a plain GET of its URL.
  imageRequest,
}

/// A source of books: what an extension's `Source` is to the app.
///
/// **Optional methods.** The contract makes `getLatest`, `getFilters` and `getImageRequest`
/// optional. Here every source has all three methods, and says which it really has in
/// [capabilities]. Callers check before calling, so that a screen can leave out a Latest tab or a
/// filter button without calling anything, and so that loading a cover costs no call to the
/// extension when it needs no headers. Calling an optional method a source does not declare is a
/// programming error: it fails with [UnsupportedError], not a [SourceException].
///
/// **Failures.** Every method fails with a [SourceException], whose kind tells the caller how to
/// react. A result has always passed SourceAPI 1.0's rules by the time it is returned: for the
/// JavaScript adapter, because it decodes each result with `PlainDataDecoder`, which fails the call
/// as [ParseException] instead.
///
/// **Pages** are numbered from 1.
abstract interface class ContentSource {
  /// Whether this source offers books to listen to or books to read (1.1). Fixed for the life of the
  /// source.
  ///
  /// It decides which of [resolveMedia] and [getChapterContent] the source has: an audio source has
  /// only the first and a text source only the second. Calling the other is a programming error and
  /// fails with [UnsupportedError], as calling an undeclared optional method does.
  SourceKind get kind;

  /// The optional methods this source has. Fixed for the life of the source.
  Set<SourceCapability> get capabilities;

  /// Popular books, a page at a time.
  Future<PageResult<BookSummary>> getPopular(int page);

  /// Recently added or updated books, a page at a time. Only when [capabilities] has
  /// [SourceCapability.latest].
  Future<PageResult<BookSummary>> getLatest(int page);

  /// Books matching [query], a page at a time.
  Future<PageResult<BookSummary>> search(SearchQuery query, int page);

  /// The filters [search] takes. Only when [capabilities] has [SourceCapability.filters].
  Future<List<Filter>> getFilters();

  /// Everything the source says about the book with [bookKey].
  Future<BookDetails> getBookDetails(String bookKey);

  /// The book's chapters, in listening order. Their keys are unique within the book.
  Future<List<ChapterInfo>> getChapters(String bookKey);

  /// Where the audio of [chapter] is, for [context]. Only when [kind] is [SourceKind.audio].
  Future<MediaResolution> resolveMedia(
    ChapterRef chapter,
    ResolveContext context,
  );

  /// What [chapter] says (1.1). Only when [kind] is [SourceKind.text].
  Future<ChapterContent> getChapterContent(ChapterRef chapter);

  /// How to fetch the cover at [url], with the headers or cookies it needs. Only when
  /// [capabilities] has [SourceCapability.imageRequest].
  Future<HttpRequest> getImageRequest(Uri url);
}
