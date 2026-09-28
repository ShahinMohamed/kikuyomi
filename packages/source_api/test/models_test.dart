// The types themselves: two of the same value are equal, and none of them can be changed after it
// is made. Both matter because the app compares source results with what is stored (§4.4) and holds
// them across isolates.

import 'package:kikuyomi_source_api/kikuyomi_source_api.dart';
import 'package:test/test.dart';

/// A source with nothing in it, to show what a built-in source implements.
final class EmptySource implements ContentSource {
  EmptySource(this.capabilities);

  @override
  SourceKind get kind => SourceKind.audio;

  @override
  final Set<SourceCapability> capabilities;

  @override
  Future<ChapterContent> getChapterContent(ChapterRef chapter) async =>
      throw UnsupportedError('an audio source has no chapter text');

  @override
  Future<BookFile> resolveBook(String bookKey) async =>
      throw UnsupportedError('this source has no book files');

  @override
  Future<PageResult<BookSummary>> getPopular(int page) async =>
      PageResult(items: const [], hasNextPage: false);

  @override
  Future<PageResult<BookSummary>> getLatest(int page) async =>
      capabilities.contains(SourceCapability.latest)
      ? PageResult(items: const [], hasNextPage: false)
      : throw UnsupportedError('this source has no latest list');

  @override
  Future<PageResult<BookSummary>> search(SearchQuery query, int page) async =>
      PageResult(items: const [], hasNextPage: false);

  @override
  Future<List<Filter>> getFilters() async =>
      capabilities.contains(SourceCapability.filters)
      ? const []
      : throw UnsupportedError('this source has no filters');

  @override
  Future<BookDetails> getBookDetails(String bookKey) async =>
      throw const NotFoundException('nothing here');

  @override
  Future<List<ChapterInfo>> getChapters(String bookKey) async => const [];

  @override
  Future<MediaResolution> resolveMedia(
    ChapterRef chapter,
    ResolveContext context,
  ) async => throw const NotFoundException('nothing here');

  @override
  Future<HttpRequest> getImageRequest(Uri url) async =>
      capabilities.contains(SourceCapability.imageRequest)
      ? HttpRequest(url: url)
      : throw UnsupportedError('this source\'s covers need no headers');
}

void main() {
  group('a source', () {
    test('says which of the optional methods it has', () async {
      final source = EmptySource({SourceCapability.latest});
      expect(source.capabilities, {SourceCapability.latest});
      expect(
        await source.getLatest(1),
        PageResult<BookSummary>(items: const [], hasNextPage: false),
      );
      await expectLater(source.getFilters(), throwsUnsupportedError);
      await expectLater(
        source.getImageRequest(Uri.parse('https://example.org/1.jpg')),
        throwsUnsupportedError,
      );
    });

    test('fails with the kind of failure the app reacts to', () async {
      final source = EmptySource(const {});
      await expectLater(
        source.getBookDetails('b1'),
        throwsA(isA<NotFoundException>()),
      );
    });
  });

  group('equality', () {
    test('holds for two summaries of the same book', () {
      BookSummary made() => BookSummary(
        key: 'b1',
        title: 'Moby-Dick',
        coverUrl: Uri.parse('https://example.org/1.jpg'),
        authors: ['Herman Melville'],
        durationMs: 87000000,
      );
      expect(made(), made());
      expect(made().hashCode, made().hashCode);
      expect(made(), isNot(BookSummary(key: 'b2', title: 'Moby-Dick')));
      expect(
        made(),
        isNot(
          BookSummary(key: 'b1', title: 'Moby-Dick', authors: ['Melville']),
        ),
      );
    });

    test('holds for details, down to a field the source did not give', () {
      BookDetails made({String? subtitle}) => BookDetails(
        key: 'b1',
        title: 'Moby-Dick',
        subtitle: subtitle,
        authors: ['Herman Melville'],
        genres: ['Fiction'],
        series: const Series(name: 'Whales', index: 2.5),
        status: BookStatus.complete,
      );
      expect(made(), made());
      expect(made().hashCode, made().hashCode);
      expect(made(), isNot(made(subtitle: 'or, The Whale')));
    });

    test('holds for chapters, media and requests', () {
      expect(
        const ChapterInfo(key: 'c1', title: 'Loomings'),
        const ChapterInfo(key: 'c1', title: 'Loomings'),
      );
      expect(
        const ChapterRef(bookKey: 'b1', chapterKey: 'c1'),
        const ChapterRef(bookKey: 'b1', chapterKey: 'c1'),
      );
      MediaResolution made() => MediaResolution(
        segments: [
          MediaSegment(
            fileKey: 'f1',
            request: HttpRequest(
              url: Uri.parse('https://example.org/a.mp3'),
              headers: const {'Referer': 'https://example.org/'},
            ),
            range: const MediaRange(startMs: 0, endMs: 60000),
          ),
        ],
      );
      expect(made(), made());
      expect(made().hashCode, made().hashCode);
      expect(
        made(),
        isNot(
          MediaResolution(
            segments: made().segments,
            expiresAt: DateTime.utc(2026),
          ),
        ),
      );
    });

    test('holds for a page, and tells one kind of page from another', () {
      expect(
        PageResult(items: const [1, 2], hasNextPage: true),
        PageResult(items: const [1, 2], hasNextPage: true),
      );
      expect(
        PageResult(items: const [1, 2], hasNextPage: true),
        isNot(PageResult(items: const [2, 1], hasNextPage: true)),
      );
      expect(
        PageResult(items: const [1], hasNextPage: true),
        isNot(PageResult(items: const [1], hasNextPage: false)),
      );
    });

    test('holds for searches and their values, whatever order the values were built in', () {
      final one = SearchQuery(
        text: 'whales',
        filters: FilterValues({
          'author': const TextValue('Melville'),
          'fiction': TriState.include,
        }),
      );
      final other = SearchQuery(
        text: 'whales',
        filters: FilterValues({
          'fiction': TriState.include,
          'author': const TextValue('Melville'),
        }),
      );
      expect(one, other);
      expect(one.hashCode, other.hashCode);
      expect(one, isNot(const SearchQuery(text: 'whales')));
    });

    test('holds for filters, including the options inside them', () {
      SelectFilter made(String label) => SelectFilter(
        key: 'genre',
        label: label,
        options: const [Option(value: 'any', label: 'Any')],
      );
      expect(made('Genre'), made('Genre'));
      expect(made('Genre'), isNot(made('Kind')));
      expect(FilterValues.none, FilterValues(const {}));
    });
  });

  group('immutability', () {
    test('keeps a list handed to a type from changing under it', () {
      final authors = ['Herman Melville'];
      final summary = BookSummary(
        key: 'b1',
        title: 'Moby-Dick',
        authors: authors,
      );
      expect(() => summary.authors.add('Someone else'), throwsUnsupportedError);
    });

    test('keeps headers and filter values from changing under them', () {
      final request = HttpRequest(
        url: Uri.parse('https://example.org/a.mp3'),
        headers: const {'Referer': 'https://example.org/'},
      );
      expect(() => request.headers['X-Token'] = 'abc', throwsUnsupportedError);
      final values = FilterValues({'author': const TextValue('Melville')});
      expect(() => values.values.remove('author'), throwsUnsupportedError);
    });
  });

  test(
    'a select filter without options is a mistake in the app, not in a source',
    () {
      expect(
        () => SelectFilter(key: 'genre', label: 'Genre', options: const []),
        throwsArgumentError,
      );
    },
  );
}
