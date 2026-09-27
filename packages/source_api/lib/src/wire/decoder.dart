/// Reading what an extension returns: plain data in, SourceAPI 1.0's types out.
///
/// Extension output is untrusted (§3.6): it is decoded into strict types and checked against the
/// contract's Limits at the boundary. A result that breaks a rule fails that one call with
/// [ParseException] and is never partly written to the library, so a broken source costs a listener
/// an error message rather than a corrupted book.
///
/// The JavaScript adapter in `source_runtime` and the contract test suite (§3.11) both decode with
/// this, so an extension is held to the same rules while it is being written as it is once it is
/// installed.
///
/// The rules it applies beyond the Limits table, such as what an unknown `status` becomes and what
/// an empty entry in a list of names means, are listed under "Reading results" in the contract.
library;

import '../domains.dart';
import '../errors.dart';
import '../limits.dart';
import '../models/book.dart';
import '../models/chapter.dart';
import '../models/http_request.dart';
import '../models/media.dart';
import '../models/page_result.dart';
import '../models/search.dart';
import '../models/text.dart';
import 'html_content.dart';
import 'reading.dart';

/// Decodes one extension's results, against the domains that extension declared.
final class PlainDataDecoder {
  const PlainDataDecoder(this.domains);

  /// The hosts this extension may name. Every URL in a result is held to it.
  final DomainAllowlist domains;

  /// One page of `getPopular`, `getLatest` or `search`.
  ///
  /// A book key that repeats within the page is left out after its first appearance: sites list the
  /// same book twice often enough, in a "featured" strip above the results it also appears in, and
  /// a repeat costs the listener nothing to drop.
  PageResult<BookSummary> decodeBookPage(Object? data) {
    final page = Fields.of(data, '');
    final items = page.array(
      'items',
      what: 'results',
      max: SourceLimits.maxPageItems,
    );
    final hasNextPage = page.flag('hasNextPage');
    final keys = <String>{};
    final summaries = <BookSummary>[];
    for (var i = 0; i < items.length; i++) {
      final summary = _bookSummary(items[i], 'items[$i]');
      if (keys.add(summary.key)) summaries.add(summary);
    }
    return PageResult(items: summaries, hasNextPage: hasNextPage);
  }

  /// The result of `getBookDetails`.
  BookDetails decodeBookDetails(Object? data) {
    final book = Fields.of(data, '');
    final series = book.optionalObject('series');
    return BookDetails(
      key: book.key('key'),
      title: book.text('title'),
      subtitle: book.optionalText('subtitle'),
      authors: book.textList('authors', required: true),
      narrators: book.textList('narrators', required: true),
      series: series == null
          ? null
          : Series(
              name: series.text('name'),
              index: series.optionalNumber('index'),
            ),
      description: book.optionalText(
        'description',
        max: SourceLimits.maxDescriptionLength,
        multiline: true,
      ),
      coverUrl: _optionalUrl(book, 'coverUrl'),
      genres: book.textList('genres', required: true),
      language: _language(book),
      publisher: book.optionalText('publisher'),
      publishedDate: book.optionalText('publishedDate'),
      isbn: book.optionalText('isbn'),
      abridged: book.optionalFlag('abridged'),
      totalDurationMs: book.optionalAmount('totalDurationMs'),
      status: switch (book.name('status')) {
        'complete' => BookStatus.complete,
        'ongoing' => BookStatus.ongoing,
        // A status this app does not know is not knowing the status.
        _ => BookStatus.unknown,
      },
      contentRating: switch (book.optionalName('contentRating')) {
        null => null,
        'everyone' => ContentRating.everyone,
        'mature' => ContentRating.mature,
        // Including a rating this app does not know: an unknown rating is read as the most
        // restrictive one there is, never as a laxer one, so a rating added by a later version
        // cannot show adult books to someone who did not ask for them.
        _ => ContentRating.adult,
      },
      webUrl: _optionalUrl(book, 'webUrl'),
    );
  }

  /// The result of `getChapters`, in listening order.
  ///
  /// Chapter keys must differ: §4.4 matches chapters by key when a book is refreshed, so two
  /// chapters sharing one would make progress land on whichever of them was written last.
  List<ChapterInfo> decodeChapters(Object? data) {
    final items = readArray(
      data,
      'chapters',
      what: 'chapters',
      max: SourceLimits.maxChapters,
    );
    final firstAt = <String, int>{};
    final chapters = <ChapterInfo>[];
    for (var i = 0; i < items.length; i++) {
      final chapter = Fields.of(items[i], 'chapters[$i]');
      final key = chapter.key('key');
      final seen = firstAt[key];
      if (seen != null) {
        rejectAt(
          chapter.pathOf('key'),
          'repeats the key of chapters[$seen]; a chapter key identifies a chapter within its book '
          'and no two may share one',
        );
      }
      firstAt[key] = i;
      chapters.add(
        ChapterInfo(
          key: key,
          title: chapter.text('title'),
          durationMs: chapter.optionalAmount('durationMs'),
          publishedAt: chapter.optionalTime('publishedAt'),
          group: chapter.optionalText('group'),
        ),
      );
    }
    return chapters;
  }

  /// The result of `getChapterContent` (1.1): `{ html, baseUrl? }` or `{ text }`.
  ///
  /// HTML is turned into blocks here and nowhere else, so nothing downstream ever holds markup a
  /// stranger wrote. An image is kept only when its address, resolved against `baseUrl` if the
  /// source gave one, is on a host the source declared — the same rule as every other URL it hands
  /// over. A relative address with no `baseUrl` to resolve it against names nothing, and is left out.
  ChapterContent decodeChapterContent(Object? data) {
    final content = Fields.of(data, '');
    final markup = content['html'];
    final text = content['text'];
    if ((markup == null) == (text == null)) {
      rejectAt(
        '',
        'expected exactly one of html and text, got '
            '${markup == null ? 'neither' : 'both'}',
      );
    }
    final body = (markup ?? text)!;
    final field = markup != null ? 'html' : 'text';
    if (body is! String) {
      rejectAt(
        content.pathOf(field),
        'expected a string, got ${describe(body)}',
      );
    }
    if (body.length > SourceLimits.maxChapterContentLength) {
      rejectAt(
        content.pathOf(field),
        'is ${body.length} characters, and a chapter may be at most '
        '${SourceLimits.maxChapterContentLength}',
      );
    }

    final ChapterContent decoded;
    if (markup != null) {
      final base = _optionalUrl(content, 'baseUrl');
      decoded = contentFromHtml(
        body,
        resolveImage: (src) {
          final Uri resolved;
          try {
            resolved = base == null ? Uri.parse(src) : base.resolve(src);
          } on FormatException {
            return null;
          }
          if (!resolved.hasScheme) return null;
          try {
            return domains.checkUrl(resolved.toString());
          } on FormatException {
            // Not on a declared host. Left out rather than failing the chapter: one picture on a
            // CDN the author forgot to declare should cost that picture, not the words around it.
            return null;
          }
        },
      );
    } else {
      decoded = contentFromText(body);
    }

    if (decoded.blocks.length > SourceLimits.maxContentBlocks) {
      rejectAt(
        content.pathOf(field),
        'makes ${decoded.blocks.length} blocks, and a chapter may make at most '
        '${SourceLimits.maxContentBlocks}',
      );
    }
    return decoded;
  }

  /// The result of `resolveMedia`.
  MediaResolution decodeMediaResolution(Object? data) {
    final resolution = Fields.of(data, '');
    final segments = resolution.array(
      'segments',
      what: 'segments',
      max: SourceLimits.maxSegments,
    );
    if (segments.isEmpty) {
      rejectAt(
        resolution.pathOf('segments'),
        'is empty; a chapter is made of at least one segment',
      );
    }
    return MediaResolution(
      segments: [
        for (var i = 0; i < segments.length; i++)
          _segment(segments[i], 'segments[$i]'),
      ],
      expiresAt: resolution.optionalTime('expiresAt'),
    );
  }

  /// The result of `getFilters`.
  List<Filter> decodeFilters(Object? data) {
    final items = readArray(
      data,
      'filters',
      what: 'filters',
      max: SourceLimits.maxFilters,
    );
    final scope = _FilterScope();
    return [
      for (var i = 0; i < items.length; i++)
        _filter(items[i], 'filters[$i]', scope, inGroup: false),
    ];
  }

  /// A request an extension hands over: the result of `getImageRequest`, and what `http.fetch` is
  /// asked to send.
  HttpRequest decodeHttpRequest(Object? data) => _request(data, '');

  /// What an extension threw, as the kind the app reacts to.
  ///
  /// Never throws: anything that is not one of the contract's kinds, including a plain `Error`, a
  /// kind from a later minor version and a thrown string, is a [ParseException], as the contract
  /// says. A kind survives an optional field it cannot read, such as a `retryAfterMs` that is not a
  /// number, because backing off matters more than the figure; a kind whose required field cannot
  /// be read does not, because the app could not act on it anyway.
  SourceException decodeError(Object? thrown) {
    // The adapter and built-in sources raise these directly.
    if (thrown is SourceException) return thrown;
    final fields = thrown is Map ? thrown : const {};
    final kind = fields['kind'];
    final message = _errorMessage(thrown, named: kind is! String);
    if (kind is! String) return ParseException(message);
    switch (kind) {
      case 'ChallengeRequired':
        final url = fields['url'];
        if (url is! String) {
          return ParseException(
            'ChallengeRequired without a url: ${describe(url)}'
            '${message.isEmpty ? '' : ' ($message)'}',
          );
        }
        try {
          return ChallengeRequiredException(domains.checkUrl(url), message);
        } on FormatException catch (error) {
          return ParseException("ChallengeRequired's url ${error.message}");
        }
      case 'LoginRequired':
        return LoginRequiredException(message);
      case 'RateLimited':
        final retryAfter = fields['retryAfterMs'];
        return RateLimitedException(
          message: message,
          retryAfterMs: switch (retryAfter) {
            final int ms when ms >= 0 && ms <= SourceLimits.maxSafeInteger =>
              ms,
            final double ms
                when ms.isFinite &&
                    ms >= 0 &&
                    ms <= SourceLimits.maxSafeInteger &&
                    ms == ms.truncateToDouble() =>
              ms.toInt(),
            // Anything else, including nothing: back off for as long as the app decides.
            _ => null,
          },
        );
      case 'NotFound':
        return NotFoundException(message);
      case 'SourceOutdated':
        return SourceOutdatedException(message);
      case 'Network':
        return NetworkException(message);
      case 'Parse':
        return ParseException(message);
      default:
        // A kind a later minor version added. Treating it as Parse is what keeps adding kinds
        // additive.
        return ParseException(
          message.isEmpty
              ? 'an error of kind ${quote(kind)}'
              : '${quote(kind)}: $message',
        );
    }
  }

  BookSummary _bookSummary(Object? data, String path) {
    final summary = Fields.of(data, path);
    return BookSummary(
      key: summary.key('key'),
      title: summary.text('title'),
      coverUrl: _optionalUrl(summary, 'coverUrl'),
      authors: summary.textList('authors', required: false),
      narrators: summary.textList('narrators', required: false),
      durationMs: summary.optionalAmount('durationMs'),
    );
  }

  MediaSegment _segment(Object? data, String path) {
    final segment = Fields.of(data, path);
    final range = segment.optionalObject('range');
    final variants = segment.optionalArray(
      'variants',
      what: 'variants',
      max: SourceLimits.maxVariants,
    );
    final startMs = range?.wholeNumber('startMs') ?? 0;
    final endMs = range?.optionalWholeNumber('endMs');
    if (range != null && endMs != null && endMs <= startMs) {
      rejectAt(
        range.pathOf('endMs'),
        'is not after startMs: $endMs after $startMs',
      );
    }
    return MediaSegment(
      fileKey: segment.key('fileKey'),
      request: _request(segment['request'], segment.pathOf('request')),
      format: switch (segment.optionalName('format')) {
        'mp3' => MediaFormat.mp3,
        'm4a' => MediaFormat.m4a,
        'm4b' => MediaFormat.m4b,
        'aac' => MediaFormat.aac,
        'flac' => MediaFormat.flac,
        'ogg' => MediaFormat.ogg,
        'opus' => MediaFormat.opus,
        'hls' => MediaFormat.hls,
        // Including nothing and a format this app does not know: the app probes the file (§4.5)
        // rather than trusting the source's word anyway.
        _ => MediaFormat.unknown,
      },
      range: range == null ? null : MediaRange(startMs: startMs, endMs: endMs),
      durationMs: segment.optionalAmount('durationMs'),
      sizeBytes: segment.optionalAmount('sizeBytes'),
      variants: [
        for (var i = 0; i < variants.length; i++)
          _variant(variants[i], '$path.variants[$i]'),
      ],
    );
  }

  MediaVariant _variant(Object? data, String path) {
    final variant = Fields.of(data, path);
    return MediaVariant(
      label: variant.text('label'),
      bitrateKbps: variant.optionalAmount('bitrateKbps'),
      request: _request(variant['request'], variant.pathOf('request')),
    );
  }

  HttpRequest _request(Object? data, String path) {
    final request = Fields.of(data, path);
    final method = switch (request.optionalName('method')) {
      null || 'GET' => HttpMethod.get,
      'POST' => HttpMethod.post,
      final other => rejectAt(
        request.pathOf('method'),
        '${quote(other)} is not a method; the contract has "GET" and "POST"',
      ),
    };
    final body = request.optionalRawText('body');
    if (body != null && method == HttpMethod.get) {
      rejectAt(request.pathOf('body'), 'only a POST request carries a body');
    }
    if (body != null && body.length > SourceLimits.maxBodyLength) {
      rejectAt(
        request.pathOf('body'),
        'longer than ${grouped(SourceLimits.maxBodyLength)} characters',
      );
    }
    return HttpRequest(
      url: _url(request, 'url'),
      method: method,
      headers: _headers(request),
      body: body,
    );
  }

  /// Headers, checked as the transport will send them.
  ///
  /// A name that is not an HTTP token, a value carrying a line break, or two names differing only
  /// in case would each let a request say something other than what it appears to say once it is on
  /// the wire.
  Map<String, String> _headers(Fields request) {
    final data = request['headers'];
    if (data == null) return const {};
    final path = request.pathOf('headers');
    if (data is! Map) {
      rejectAt(path, 'expected an object, got ${describe(data)}');
    }
    if (data.length > SourceLimits.maxHeaders) {
      rejectAt(
        path,
        'holds ${grouped(data.length)} headers; at most '
        '${grouped(SourceLimits.maxHeaders)} are allowed',
      );
    }
    final headers = <String, String>{};
    final namesSeen = <String, String>{};
    for (final MapEntry(:key, :value) in data.entries) {
      if (key is! String) {
        rejectAt(path, 'has a name that is not a string: ${describe(key)}');
      }
      final at = '$path[${quote(key)}]';
      if (key.isEmpty || key.length > SourceLimits.maxHeaderNameLength) {
        rejectAt(
          at,
          'is not a header name of 1 to ${grouped(SourceLimits.maxHeaderNameLength)} characters',
        );
      }
      if (!_token.hasMatch(key)) {
        rejectAt(
          at,
          'is not a header name: HTTP allows letters, digits and !#\$%&\'*+-.^_`|~',
        );
      }
      final lower = key.toLowerCase();
      if (SourceLimits.forbiddenHeaders.contains(lower)) {
        rejectAt(
          at,
          'is set by the app itself, and an extension may not set it',
        );
      }
      final earlier = namesSeen[lower];
      if (earlier != null) {
        rejectAt(
          at,
          'repeats ${quote(earlier)}, which differs from it only in case',
        );
      }
      namesSeen[lower] = key;
      if (value is! String) {
        rejectAt(at, 'has a value that is not a string: ${describe(value)}');
      }
      if (value.length > SourceLimits.maxHeaderValueLength) {
        rejectAt(
          at,
          'has a value longer than ${grouped(SourceLimits.maxHeaderValueLength)} characters',
        );
      }
      for (var i = 0; i < value.length; i++) {
        final unit = value.codeUnitAt(i);
        if ((unit < 0x20 && unit != 0x09) || unit == 0x7f) {
          rejectAt(
            at,
            'has a value holding a control character '
            '(U+${unit.toRadixString(16).toUpperCase().padLeft(4, '0')})',
          );
        }
      }
      headers[key] = value;
    }
    return headers;
  }

  static final _token = RegExp(r"^[A-Za-z0-9!#$%&'*+\-.^_`|~]+$");

  Uri? _optionalUrl(Fields fields, String name) =>
      fields[name] == null ? null : _url(fields, name);

  Uri _url(Fields fields, String name) {
    final path = fields.pathOf(name);
    final value = fields[name];
    if (value is! String) {
      rejectAt(path, 'expected a string, got ${describe(value)}');
    }
    try {
      return domains.checkUrl(value);
    } on FormatException catch (error) {
      rejectAt(path, error.message);
    }
  }

  /// A BCP 47 tag, such as `en` or `pt-BR`, or nothing when the source wrote something else.
  ///
  /// The shape is checked loosely, for a primary subtag of two or three letters with any number of
  /// subtags after it, rather than for being registered. What does not fit is dropped rather than
  /// failing the call: sites write "English" where its tag belongs often enough, and a label on a
  /// book is worth less than the book. The app filters and groups by this value, so a name left in
  /// it would quietly become a language of its own.
  ///
  /// What is kept is written the one way BCP 47 writes it, so that `EN-us` and `en-US` are one
  /// language to filter by: the primary subtag in lower case, a four-letter script subtag in title
  /// case, a two-letter region in upper case, and the rest in lower case.
  String? _language(Fields book) {
    final tag = book.optionalText('language');
    if (tag == null || !_languageTag.hasMatch(tag)) return null;
    final subtags = tag.split('-');
    return [
      for (var i = 0; i < subtags.length; i++)
        if (i == 0)
          subtags[i].toLowerCase()
        else if (subtags[i].length == 4)
          '${subtags[i][0].toUpperCase()}${subtags[i].substring(1).toLowerCase()}'
        else if (subtags[i].length == 2)
          subtags[i].toUpperCase()
        else
          subtags[i].toLowerCase(),
    ].join('-');
  }

  static final _languageTag = RegExp(r'^[A-Za-z]{2,3}(-[A-Za-z0-9]{1,8})*$');

  Filter _filter(
    Object? data,
    String path,
    _FilterScope scope, {
    required bool inGroup,
  }) {
    final filter = Fields.of(data, path);
    scope.counted++;
    if (scope.counted > SourceLimits.maxFilters) {
      rejectAt(
        'filters',
        'holds more than ${grouped(SourceLimits.maxFilters)} filters, counting groups and the '
            'filters inside them',
      );
    }
    final kind = filter.name('kind');
    switch (kind) {
      case 'header':
        return HeaderFilter(label: filter.text('label'));
      case 'separator':
        return const SeparatorFilter();
      case 'text':
        return TextFilter(
          key: scope.claim(filter, path),
          label: filter.text('label'),
          defaultText: filter.optionalText('default') ?? '',
        );
      case 'checkbox':
        return CheckboxFilter(
          key: scope.claim(filter, path),
          label: filter.text('label'),
          defaultChecked: filter.optionalFlag('default') ?? false,
        );
      case 'tristate':
        return TriStateFilter(
          key: scope.claim(filter, path),
          label: filter.text('label'),
          defaultValue: switch (filter.optionalName('default')) {
            null || 'ignore' => TriState.ignore,
            'include' => TriState.include,
            'exclude' => TriState.exclude,
            final other => rejectAt(
              filter.pathOf('default'),
              '${quote(other)} is not "ignore", "include" or "exclude"',
            ),
          },
        );
      case 'select':
        final options = _options(filter);
        final chosen = filter.optionalKey('default');
        if (chosen != null &&
            !options.any((option) => option.value == chosen)) {
          rejectAt(
            filter.pathOf('default'),
            '${quote(chosen)} is not one of this filter\'s options',
          );
        }
        return SelectFilter(
          key: scope.claim(filter, path),
          label: filter.text('label'),
          options: options,
          defaultOption: chosen,
        );
      case 'sort':
        final options = _options(filter);
        final chosen = filter.optionalObject('default');
        final value = chosen?.key('value');
        if (value != null && !options.any((option) => option.value == value)) {
          rejectAt(
            chosen!.pathOf('value'),
            '${quote(value)} is not one of this filter\'s options',
          );
        }
        return SortFilter(
          key: scope.claim(filter, path),
          label: filter.text('label'),
          options: options,
          defaultValue: chosen == null
              ? null
              : SortValue(value: value!, ascending: chosen.flag('ascending')),
        );
      case 'group':
        if (inGroup) {
          rejectAt(
            path,
            'is a group inside a group; groups are one level deep',
          );
        }
        final inner = filter.array(
          'filters',
          what: 'filters',
          max: SourceLimits.maxFilters,
        );
        return GroupFilter(
          label: filter.text('label'),
          filters: [
            for (var i = 0; i < inner.length; i++)
              _filter(inner[i], '$path.filters[$i]', scope, inGroup: true),
          ],
        );
      default:
        rejectAt(filter.pathOf('kind'), '${quote(kind)} is not a filter kind');
    }
  }

  List<Option> _options(Fields filter) {
    final items = filter.array(
      'options',
      what: 'options',
      max: SourceLimits.maxOptions,
    );
    if (items.isEmpty) {
      rejectAt(
        filter.pathOf('options'),
        'is empty; a filter to choose from needs options',
      );
    }
    final path = filter.pathOf('options');
    final values = <String, int>{};
    final options = <Option>[];
    for (var i = 0; i < items.length; i++) {
      final option = Fields.of(items[i], '$path[$i]');
      final value = option.key('value');
      final seen = values[value];
      if (seen != null) {
        rejectAt(option.pathOf('value'), 'repeats the value of $path[$seen]');
      }
      values[value] = i;
      options.add(Option(value: value, label: option.text('label')));
    }
    return options;
  }

  String _errorMessage(Object? thrown, {required bool named}) {
    if (thrown is String) return _readable(thrown);
    if (thrown is! Map) return 'the extension threw ${describe(thrown)}';
    final message = thrown['message'];
    final text = message is String ? _readable(message) : '';
    final name = thrown['name'];
    // Only for something that is not one of the contract's errors, where the name is all there is
    // to say what went wrong: "TypeError: x is not a function".
    if (named && name is String && name.isNotEmpty) {
      final described = text.isEmpty
          ? _readable(name)
          : '${_readable(name)}: $text';
      return '$described${_where(thrown['stack'])}';
    }
    return text;
  }

  /// Where an error the extension did not mean to throw came from, as the first frames of its stack.
  ///
  /// A bare "TypeError: not a function" says nothing an author can act on; the stack says which
  /// function and which line, which is usually the whole diagnosis. Only for an accidental error: a
  /// kind the extension threw on purpose carries its author's own sentence, and a stack under it
  /// would be noise.
  ///
  /// A few frames, not all of them, because this ends up in a message that is cut to length, and the
  /// frames nearest the failure are the ones worth keeping.
  String _where(Object? stack) {
    if (stack is! String) return '';
    final frames = [
      for (final line in stack.split(RegExp(r'[\r\n]+')))
        if (line.trim().isNotEmpty) line.trim(),
    ];
    if (frames.isEmpty) return '';
    return ' (${frames.take(_keptFrames).join(' < ')})';
  }

  /// How many stack frames a message carries.
  static const _keptFrames = 3;

  /// An extension's own message, made safe to show and short enough to log.
  ///
  /// Unlike a result's text, a message is never refused: an error's kind is what the app acts on,
  /// and losing it over a stray character in a message would cost more than the message is worth.
  String _readable(String message) {
    final cut = message.length > SourceLimits.maxShortTextLength;
    final kept = cut
        ? message.substring(0, SourceLimits.maxShortTextLength)
        : message;
    final buffer = StringBuffer();
    for (var i = 0; i < kept.length; i++) {
      final unit = kept.codeUnitAt(i);
      buffer.write(unit < 0x20 || unit == 0x7f ? ' ' : kept[i]);
    }
    final text = buffer.toString().trim();
    return cut && text.isNotEmpty ? '$text…' : text;
  }
}

/// What has been seen so far while reading one source's filters: how many there are, and which keys
/// are taken.
final class _FilterScope {
  var counted = 0;
  final _keys = <String, String>{};

  /// The filter's key, refusing one another filter already has.
  ///
  /// Values are keyed by a filter's key, so two filters sharing one would have the same value: the
  /// listener would set one and change both.
  String claim(Fields filter, String path) {
    final key = filter.key('key');
    final earlier = _keys[key];
    if (earlier != null) {
      rejectAt(filter.pathOf('key'), 'repeats the key of $earlier');
    }
    _keys[key] = path;
    return key;
  }
}
