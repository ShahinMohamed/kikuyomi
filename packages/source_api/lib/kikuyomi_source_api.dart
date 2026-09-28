/// The versioned contract that source extensions implement.
///
/// The Dart mirror of SourceAPI 1.1 (`docs/source-api-1.0.md`, ADR-0016, and ADR-0019 for text): the
/// types a source hands
/// the app, the `ContentSource` interface both the JavaScript adapter and the built-in sources
/// implement, the error kinds the app reacts to, the contract's limits, and the decoders that hold
/// an extension's output to them.
///
/// This is a public API: changes are additive within a minor version, and a breaking change is a
/// major version with a published deprecation window.
///
/// Pure Dart. This package must never import Flutter or a platform plugin.
library;

export 'src/content_source.dart';
export 'src/domains.dart';
export 'src/errors.dart';
export 'src/limits.dart';
export 'src/models/book.dart';
export 'src/models/book_file.dart';
export 'src/models/chapter.dart';
export 'src/models/http_request.dart';
export 'src/models/media.dart';
export 'src/models/page_result.dart';
export 'src/models/search.dart';
export 'src/models/text.dart';
export 'src/version.dart';
export 'src/wire/decoder.dart';
export 'src/wire/encoding.dart';
export 'src/wire/html_content.dart';
