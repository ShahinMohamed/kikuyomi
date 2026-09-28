/// `ContentSource` over an extension's JavaScript (§3.6).
///
/// "A `JsSourceAdapter` implements the Dart `ContentSource` interface by forwarding calls to an
/// `ExtensionRuntime`." So the rest of the app cannot tell an extension from a built-in source:
/// both are a `ContentSource`, both answer with the contract's types, and both fail with the
/// contract's error kinds.
///
/// Each method does three things and nothing else: encode the arguments with `source_api`'s
/// encoders, call the method on the source, and decode the result with `PlainDataDecoder`, which
/// holds it to SourceAPI 1.0's Limits and its "Reading results" rules. A result that breaks one
/// fails that one call with [ParseException] and is never partly written to the library.
library;

import 'package:kikuyomi_source_api/kikuyomi_source_api.dart';

/// What the adapter needs of the thing holding an extension's code.
///
/// Both shapes of §3.6 satisfy it: an [ExtensionRuntime] called in this isolate, which is what a
/// test and the probe use, and an `ExtensionWorker` that owns one in an isolate of its own, which
/// is what the app uses. The adapter is the same either way, so the rules the contract is enforced
/// by are written once and neither path can drift from the other.
abstract interface class ExtensionCalls {
  /// The manifest's `id` of the extension, for messages.
  String get extensionId;

  /// The decoder every result of this extension is read with, built from its own domains.
  PlainDataDecoder get decoder;

  /// Whether `sources[sourceKey]` has [method], for the optional methods a screen reads as
  /// capabilities before it offers a Latest tab or a filter button.
  Future<bool> hasMethod(String sourceKey, String method);

  /// Calls `sources[sourceKey][method](...arguments)` and gives back its result as plain data.
  ///
  /// Throws a [SourceException]: the kind the extension threw, or the kind the failure amounts to.
  Future<Object?> invoke(
    String sourceKey,
    String method,
    List<Object?> arguments, {
    Duration? deadline,
  });
}

/// One source of one extension.
final class JsSourceAdapter implements ContentSource {
  JsSourceAdapter({
    required ExtensionCalls runtime,
    required this.sourceKey,
    required this.capabilities,
    this.kind = SourceKind.audio,
  }) : _runtime = runtime;

  /// Opens a source, asking the extension which of the optional methods it really has.
  ///
  /// The manifest declares capabilities too, and a caller that has read it can pass them to the
  /// constructor instead and call nothing. This asks the extension because the extension is what
  /// will be called: a manifest that claims `latest` for a source without `getLatest` would
  /// otherwise fail a listener's tap rather than never offering the tab.
  ///
  /// [kind] is the manifest's, which is where it is declared (1.1). It is not asked of the extension:
  /// what a source *is* is a promise the permissions screen already showed, not something to be
  /// discovered by probing for methods.
  static Future<JsSourceAdapter> open({
    required ExtensionCalls runtime,
    required String sourceKey,
    SourceKind kind = SourceKind.audio,
  }) async {
    final capabilities = <SourceCapability>{};
    if (await runtime.hasMethod(sourceKey, 'getLatest')) {
      capabilities.add(SourceCapability.latest);
    }
    if (await runtime.hasMethod(sourceKey, 'getFilters')) {
      capabilities.add(SourceCapability.filters);
    }
    if (await runtime.hasMethod(sourceKey, 'getImageRequest')) {
      capabilities.add(SourceCapability.imageRequest);
    }
    if (await runtime.hasMethod(sourceKey, 'resolveBook')) {
      capabilities.add(SourceCapability.bookFile);
    }
    return JsSourceAdapter(
      runtime: runtime,
      sourceKey: sourceKey,
      capabilities: Set.unmodifiable(capabilities),
      kind: kind,
    );
  }

  final ExtensionCalls _runtime;

  /// The manifest's key for this source, under which the extension exports it.
  final String sourceKey;

  @override
  final SourceKind kind;

  @override
  final Set<SourceCapability> capabilities;

  @override
  Future<PageResult<BookSummary>> getPopular(int page) async => _runtime.decoder
      .decodeBookPage(await _invoke('getPopular', [encodePage(page)]));

  @override
  Future<PageResult<BookSummary>> getLatest(int page) async {
    _require(SourceCapability.latest, 'getLatest');
    return _runtime.decoder.decodeBookPage(
      await _invoke('getLatest', [encodePage(page)]),
    );
  }

  @override
  Future<PageResult<BookSummary>> search(SearchQuery query, int page) async =>
      _runtime.decoder.decodeBookPage(
        await _invoke('search', [encodeSearchQuery(query), encodePage(page)]),
      );

  @override
  Future<List<Filter>> getFilters() async {
    _require(SourceCapability.filters, 'getFilters');
    return _runtime.decoder.decodeFilters(
      await _invoke('getFilters', const []),
    );
  }

  @override
  Future<BookDetails> getBookDetails(String bookKey) async => _runtime.decoder
      .decodeBookDetails(await _invoke('getBookDetails', [bookKey]));

  @override
  Future<List<ChapterInfo>> getChapters(String bookKey) async =>
      _runtime.decoder.decodeChapters(await _invoke('getChapters', [bookKey]));

  @override
  Future<MediaResolution> resolveMedia(
    ChapterRef chapter,
    ResolveContext context,
  ) async {
    _requireKind(SourceKind.audio, 'resolveMedia');
    return _runtime.decoder.decodeMediaResolution(
      await _invoke('resolveMedia', [
        encodeChapterRef(chapter),
        encodeResolveContext(context),
      ]),
    );
  }

  @override
  Future<BookFile> resolveBook(String bookKey) async {
    _requireKind(SourceKind.text, 'resolveBook');
    _require(SourceCapability.bookFile, 'resolveBook');
    return _runtime.decoder.decodeBookFile(
      await _invoke('resolveBook', [bookKey]),
    );
  }

  @override
  Future<ChapterContent> getChapterContent(ChapterRef chapter) async {
    _requireKind(SourceKind.text, 'getChapterContent');
    return _runtime.decoder.decodeChapterContent(
      await _invoke('getChapterContent', [encodeChapterRef(chapter)]),
    );
  }

  @override
  Future<HttpRequest> getImageRequest(Uri url) async {
    _require(SourceCapability.imageRequest, 'getImageRequest');
    return _runtime.decoder.decodeHttpRequest(
      await _invoke('getImageRequest', [url.toString()]),
    );
  }

  Future<Object?> _invoke(String method, List<Object?> arguments) =>
      _runtime.invoke(sourceKey, method, arguments);

  /// Asking a source for the other kind's content is a programming error in the app, as calling an
  /// undeclared optional method is: a screen should never have offered it.
  void _requireKind(SourceKind wanted, String method) {
    if (kind != wanted) {
      throw UnsupportedError(
        'the source "$sourceKey" of ${_runtime.extensionId} is ${kind.name}, '
        'and has no $method()',
      );
    }
  }

  /// Calling an optional method a source does not declare is a programming error in the app, not a
  /// source failure, so it is an [UnsupportedError] rather than a [SourceException].
  void _require(SourceCapability capability, String method) {
    if (!capabilities.contains(capability)) {
      throw UnsupportedError(
        'the source "$sourceKey" of ${_runtime.extensionId} has no $method()',
      );
    }
  }
}
