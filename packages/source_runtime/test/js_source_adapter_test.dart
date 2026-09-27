// The adapter that makes an extension look like any other source: arguments encoded as the
// contract says, results decoded and held to its Limits, and failures that are always one of its
// error kinds. The rest of the app never learns that this source is JavaScript.

import 'package:kikuyomi_source_api/kikuyomi_source_api.dart';
import 'package:kikuyomi_source_runtime/kikuyomi_source_runtime.dart';
import 'package:test/test.dart';

import 'support.dart';

/// One page of results, as an honest source answers.
Map<String, Object?> _page(List<Object?> items) => {
  'items': items,
  'hasNextPage': true,
};

Future<JsSourceAdapter> _adapter(
  Map<String, FakeMethod> methods, {
  String sourceKey = 'librivox',
  SourceKind kind = SourceKind.audio,
}) async {
  final (runtime, _) = await loadFake(FakeExtension({sourceKey: methods}));
  return JsSourceAdapter.open(
    runtime: runtime,
    sourceKey: sourceKey,
    kind: kind,
  );
}

void main() {
  group('a text source (1.1)', () {
    test('passes both keys and reads the chapter into blocks', () async {
      var asked = <Object?>[];
      final adapter = await _adapter({
        'getChapterContent': (args) {
          asked = args;
          return {'html': '<p>It was <i>very</i> dark.</p>'};
        },
      }, kind: SourceKind.text);

      final content = await adapter.getChapterContent(
        const ChapterRef(bookKey: 'novel', chapterKey: 'c1'),
      );

      expect(asked, [
        {'bookKey': 'novel', 'chapterKey': 'c1'},
      ]);
      expect(content.blocks, [
        const ParagraphBlock([
          TextRun('It was '),
          TextRun('very', italic: true),
          TextRun(' dark.'),
        ]),
      ]);
    });

    test('its markup is decoded, never passed through', () async {
      // The one guarantee that matters: nothing a stranger wrote reaches the reader as markup.
      final adapter = await _adapter({
        'getChapterContent': (_) => {
          'html': '<p>Hi</p><script>steal()</script><iframe src="x"></iframe>',
        },
      }, kind: SourceKind.text);

      final content = await adapter.getChapterContent(
        const ChapterRef(bookKey: 'novel', chapterKey: 'c1'),
      );

      expect(content.plainText, 'Hi');
    });

    test('has no audio to resolve', () async {
      final adapter = await _adapter({}, kind: SourceKind.text);

      expect(
        () => adapter.resolveMedia(
          const ChapterRef(bookKey: 'novel', chapterKey: 'c1'),
          const ResolveContext(
            purpose: ResolvePurpose.stream,
            network: NetworkType.unknown,
          ),
        ),
        throwsUnsupportedError,
      );
    });

    test('an audio source has no text to read', () async {
      final adapter = await _adapter({});

      expect(adapter.kind, SourceKind.audio);
      expect(
        () => adapter.getChapterContent(
          const ChapterRef(bookKey: 'b', chapterKey: 'c'),
        ),
        throwsUnsupportedError,
      );
    });

    test('a result that is not a chapter fails as Parse', () async {
      final adapter = await _adapter({
        'getChapterContent': (_) => {'html': '<p>a</p>', 'text': 'a'},
      }, kind: SourceKind.text);

      await expectLater(
        adapter.getChapterContent(
          const ChapterRef(bookKey: 'n', chapterKey: 'c'),
        ),
        throwsA(isA<ParseException>()),
      );
    });
  });

  group('capabilities', () {
    test('are the optional methods the source really has', () async {
      final adapter = await _adapter({
        'getPopular': (_) => _page([]),
        'getLatest': (_) => _page([]),
        'getImageRequest': (_) => {'url': 'https://example.org/c.jpg'},
      });

      expect(adapter.capabilities, {
        SourceCapability.latest,
        SourceCapability.imageRequest,
      });
    });

    test('calling one the source has not is a mistake in the app', () async {
      final adapter = await _adapter({'getPopular': (_) => _page([])});

      expect(() => adapter.getLatest(1), throwsUnsupportedError);
      expect(() => adapter.getFilters(), throwsUnsupportedError);
      expect(
        () => adapter.getImageRequest(Uri.parse('https://example.org/c.jpg')),
        throwsUnsupportedError,
      );
    });
  });

  group('discovery', () {
    test('passes the page number and reads a page of books', () async {
      var asked = <Object?>[];
      final adapter = await _adapter({
        'getPopular': (args) {
          asked = args;
          return _page([
            {
              'key': 'b1',
              'title': 'Moby-Dick',
              'authors': ['Herman Melville'],
              'durationMs': 86400000,
            },
          ]);
        },
      });

      final page = await adapter.getPopular(3);

      expect(asked, [3]);
      expect(page.hasNextPage, isTrue);
      expect(page.items.single.key, 'b1');
      expect(page.items.single.title, 'Moby-Dick');
      expect(page.items.single.authors, ['Herman Melville']);
      expect(page.items.single.durationMs, 86400000);
    });

    test('a page below 1 is the app asking for what does not exist', () async {
      final adapter = await _adapter({'getPopular': (_) => _page([])});

      expect(() => adapter.getPopular(0), throwsArgumentError);
    });

    test('a search goes out with its text and its filter values', () async {
      var asked = <Object?>[];
      final adapter = await _adapter({
        'search': (args) {
          asked = args;
          return _page([]);
        },
      });

      await adapter.search(
        SearchQuery(
          text: 'whale',
          filters: FilterValues({
            'lang': const SelectValue('en'),
            'free': const CheckboxValue(true),
            'order': const SortValue(value: 'title', ascending: false),
          }),
        ),
        2,
      );

      expect(asked.first, {
        'text': 'whale',
        'filters': {
          'lang': 'en',
          'free': true,
          'order': {'value': 'title', 'ascending': false},
        },
      });
      expect(asked.last, 2);
    });

    test('filters come back as the sealed family', () async {
      final adapter = await _adapter({
        'getPopular': (_) => _page([]),
        'getFilters': (_) => [
          {'kind': 'header', 'label': 'Language'},
          {
            'kind': 'select',
            'key': 'lang',
            'label': 'Language',
            'options': [
              {'value': 'en', 'label': 'English'},
            ],
          },
        ],
      });

      final filters = await adapter.getFilters();

      expect(filters, hasLength(2));
      expect(filters.first, isA<HeaderFilter>());
      expect(
        filters.last,
        isA<SelectFilter>()
            .having((f) => f.key, 'key', 'lang')
            .having((f) => f.options.single.value, 'option', 'en'),
      );
    });
  });

  group('content', () {
    test('a book\'s details are read whole', () async {
      final adapter = await _adapter({
        'getBookDetails': (args) => {
          'key': args.single,
          'title': 'Moby-Dick',
          'authors': ['Herman Melville'],
          'narrators': ['Stewart Wills'],
          'genres': ['Fiction'],
          'status': 'complete',
          'language': 'EN-us',
          'coverUrl': 'https://files.cdn.example.org/moby.jpg',
          'series': {'name': 'Classics', 'index': 2.5},
        },
      });

      final details = await adapter.getBookDetails('b1');

      expect(details.key, 'b1');
      expect(details.narrators, ['Stewart Wills']);
      // Written the one way BCP 47 writes it, so that two spellings are one language to filter by.
      expect(details.language, 'en-US');
      expect(details.series?.index, 2.5);
      expect(
        details.coverUrl.toString(),
        'https://files.cdn.example.org/moby.jpg',
      );
    });

    test('chapters keep the order the source gave them', () async {
      final adapter = await _adapter({
        'getChapters': (_) => [
          {'key': 'c1', 'title': 'Loomings', 'durationMs': 600000},
          {'key': 'c2', 'title': 'The Carpet-Bag'},
        ],
      });

      final chapters = await adapter.getChapters('b1');

      expect(chapters.map((c) => c.key), ['c1', 'c2']);
      expect(chapters.first.durationMs, 600000);
      expect(chapters.last.durationMs, isNull);
    });

    test('resolving media passes the chapter and the context', () async {
      var asked = <Object?>[];
      final adapter = await _adapter({
        'resolveMedia': (args) {
          asked = args;
          return {
            'segments': [
              {
                'fileKey': 'f1',
                'request': {'url': 'https://files.cdn.example.org/c1.mp3'},
                'format': 'mp3',
                'range': {'startMs': 0, 'endMs': 600000},
              },
            ],
          };
        },
      });

      final resolution = await adapter.resolveMedia(
        const ChapterRef(bookKey: 'b1', chapterKey: 'c1'),
        const ResolveContext(
          purpose: ResolvePurpose.download,
          network: NetworkType.cellular,
        ),
      );

      expect(asked.first, {'bookKey': 'b1', 'chapterKey': 'c1'});
      expect(asked.last, {'purpose': 'download', 'network': 'cellular'});
      expect(resolution.segments.single.fileKey, 'f1');
      expect(resolution.segments.single.format, MediaFormat.mp3);
    });

    test('a cover request is read as a request', () async {
      final adapter = await _adapter({
        'getPopular': (_) => _page([]),
        'getImageRequest': (args) => {
          'url': args.single,
          'headers': {'Referer': 'https://example.org/'},
        },
      });

      final request = await adapter.getImageRequest(
        Uri.parse('https://files.cdn.example.org/moby.jpg'),
      );

      expect(request.url.toString(), 'https://files.cdn.example.org/moby.jpg');
      expect(request.headers, {'Referer': 'https://example.org/'});
    });
  });

  group('a source that answers badly', () {
    test('a result that is not a page fails the call as Parse', () async {
      final adapter = await _adapter({'getPopular': (_) => 'sorry'});

      expect(() => adapter.getPopular(1), throwsA(isA<ParseException>()));
    });

    test('a URL outside the extension\'s domains fails the call', () async {
      final adapter = await _adapter({
        'getBookDetails': (_) => {
          'key': 'b1',
          'title': 'Moby-Dick',
          'authors': <String>[],
          'narrators': <String>[],
          'genres': <String>[],
          'status': 'complete',
          'coverUrl': 'https://tracker.example.net/pixel.gif',
        },
      });

      expect(
        () => adapter.getBookDetails('b1'),
        throwsA(
          isA<ParseException>().having(
            (e) => e.message,
            'message',
            contains('not among the extension\'s domains'),
          ),
        ),
      );
    });

    test('a page longer than the contract allows fails the call', () async {
      final adapter = await _adapter({
        'getPopular': (_) => _page([
          for (var i = 0; i < SourceLimits.maxPageItems + 1; i++)
            {'key': 'b$i', 'title': 'Book $i'},
        ]),
      });

      expect(() => adapter.getPopular(1), throwsA(isA<ParseException>()));
    });

    test('two chapters with one key fail the call', () async {
      final adapter = await _adapter({
        'getChapters': (_) => [
          {'key': 'c1', 'title': 'One'},
          {'key': 'c1', 'title': 'Two'},
        ],
      });

      expect(() => adapter.getChapters('b1'), throwsA(isA<ParseException>()));
    });

    test('the source\'s own error kind survives the crossing', () async {
      final adapter = await _adapter({
        'getChapters': (_) => throw const NotFoundException('gone'),
      });

      expect(
        () => adapter.getChapters('b1'),
        throwsA(isA<NotFoundException>()),
      );
    });
  });
}
