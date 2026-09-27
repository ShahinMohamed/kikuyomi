/// SourceAPI 1.0's Limits table, as named constants, in one place.
///
/// The limits bound what a broken or hostile extension can hand the app, and are generous for an
/// honest one. The decoders in this package enforce those that apply to a result; the runtime and
/// the host bridges (§3.5, §3.6) enforce the rest from here too, so that no limit is written down
/// twice.
///
/// Lengths are counted in UTF-16 code units, as JavaScript's `length` counts them, so an extension
/// can check a limit the way the app does. A megabyte is 2^20 bytes.
library;

/// The limits an extension's results and calls are held to.
abstract final class SourceLimits {
  /// The shortest key: a book, chapter, file or filter key, or an option's value.
  static const minKeyLength = 1;

  /// The longest key.
  static const maxKeyLength = 512;

  /// The longest title, label, name or other short text.
  static const maxShortTextLength = 1000;

  /// The longest description.
  static const maxDescriptionLength = 20000;

  /// The most results in one page.
  static const maxPageItems = 200;

  /// The most entries in one of a book's lists of names: its authors, its narrators, or its genres.
  static const maxNames = 200;

  /// The most options one select or sort filter offers.
  static const maxOptions = 1000;

  /// The most chapters in one book.
  static const maxChapters = 20000;

  /// The most segments in one chapter's media.
  static const maxSegments = 2000;

  /// How long a chapter's HTML or text may be, in characters (1.1). A chapter of a long novel runs to
  /// a few hundred kilobytes; the bound stops a page that is not a chapter from being read as one.
  static const maxChapterContentLength = 4 * 1024 * 1024;

  /// How many blocks a chapter may become (1.1).
  static const maxContentBlocks = 20000;

  /// The most variants of one segment.
  static const maxVariants = 10;

  /// The most filters one source declares, counting groups, headers and separators, and the filters
  /// inside groups.
  static const maxFilters = 100;

  /// The most headers on one request.
  static const maxHeaders = 50;

  /// The longest header name.
  static const maxHeaderNameLength = 256;

  /// The longest header value.
  static const maxHeaderValueLength = 8192;

  /// The longest body a request may carry, in characters.
  static const maxBodyLength = 1024 * 1024;

  /// Headers an extension may never set, in lower case. The HTTP client sets them from the request
  /// itself; letting an extension set them would let it smuggle a second request into the first or
  /// send it to a host other than the one the domain check saw.
  static const forbiddenHeaders = {
    'host',
    'content-length',
    'connection',
    'transfer-encoding',
  };

  /// The largest body an `http.fetch` response may have.
  static const maxResponseBodyBytes = 10 * 1024 * 1024;

  /// The longest one call to an extension may run: the watchdog's deadline (§3.6).
  static const callTimeout = Duration(seconds: 30);

  /// The most memory one extension's runtime may use (§3.6).
  static const maxRuntimeMemoryBytes = 64 * 1024 * 1024;

  /// The most an extension may keep in `storage`.
  static const maxStorageBytes = 1024 * 1024;

  /// The largest whole number a JavaScript number holds exactly: 2^53 − 1. Whole numbers crossing
  /// from an extension, such as durations, must lie within it, or two different values could
  /// arrive as the same one.
  static const maxSafeInteger = 9007199254740991;

  /// The furthest a time may lie from the epoch, in milliseconds, either way: the range of a
  /// JavaScript `Date`, and of a Dart `DateTime`.
  static const maxTimeMs = 8640000000000000;
}
