import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:kikuyomi_data/kikuyomi_data.dart';
import 'package:kikuyomi_domain/kikuyomi_domain.dart';
import 'package:kikuyomi_source_api/kikuyomi_source_api.dart' as api;
import 'package:kikuyomi_test_support/kikuyomi_test_support.dart';
import 'package:test/test.dart';

const sourceId = 0x4c4942;

api.BookDetails details({
  String key = '753',
  String title = 'Moby Dick',
  List<String> authors = const ['Herman Melville'],
  List<String> narrators = const ['Stewart Wills'],
  String? description = 'A whale.',
  String? coverUrl = 'https://archive.org/services/img/moby_dick_librivox',
  api.BookStatus status = api.BookStatus.complete,
  int? totalDurationMs = 3600000,
}) => api.BookDetails(
  key: key,
  title: title,
  authors: authors,
  narrators: narrators,
  description: description,
  coverUrl: coverUrl == null ? null : Uri.parse(coverUrl),
  genres: const ['Nautical & Marine Fiction'],
  language: 'en',
  publisher: 'LibriVox',
  publishedDate: '1851',
  totalDurationMs: totalDurationMs,
  status: status,
  webUrl: Uri.parse('https://librivox.org/moby-dick/'),
);

List<api.ChapterInfo> threeChapters({int? durationMs = 1200000}) => [
  api.ChapterInfo(key: 's1', title: 'Loomings', durationMs: durationMs),
  api.ChapterInfo(key: 's2', title: 'The Carpet-Bag', durationMs: durationMs),
  api.ChapterInfo(key: 's3', title: 'The Spouter-Inn', durationMs: durationMs),
];

void main() {
  late KikuyomiDatabase db;
  late FakeClock clock;

  setUp(() async {
    db = KikuyomiDatabase(NativeDatabase.memory());
    clock = FakeClock(DateTime.utc(2026, 9, 23, 12));
    await registerSource(
      db,
      id: sourceId,
      key: 'librivox',
      name: 'LibriVox',
      lang: 'multi',
      extensionId: 'org.kikuyomi.librivox',
    );
  });

  tearDown(() => db.close());

  Future<BookRow> bookRow(int id) =>
      (db.select(db.books)..where((b) => b.id.equals(id))).getSingle();

  Future<List<ChapterRow>> chapterRows(int bookId) =>
      (db.select(db.chapters)
            ..where((c) => c.bookId.equals(bookId))
            ..orderBy([(c) => OrderingTerm.asc(c.sourceIndex)]))
          .get();

  group('forgetting a source nothing uses', () {
    // §3.9 keeps a source row after its extension goes so the library's books still point
    // somewhere. That reason runs out when the last of those books does, and what is left is a row
    // naming an extension nobody has, which a listener sees as a dead entry they cannot remove.

    Future<List<int>> sourceIds() async => [
      for (final row in await db.select(db.sources).get()) row.id,
    ];

    Future<void> addStub(int id, String extensionId) => registerSource(
      db,
      id: id,
      key: 'gone',
      name: 'Gone',
      lang: 'en',
      extensionId: extensionId,
    );

    test('removes one with no books and no extension loaded', () async {
      await addStub(99, 'com.example.gone');

      final removed = await pruneUnusedSources(db, keep: {sourceId});

      expect(removed, 1);
      expect(await sourceIds(), isNot(contains(99)));
    });

    test('keeps one whose books are still in the library', () async {
      // The whole reason §3.9 leaves the row behind. Taking it would leave those books pointing at
      // nothing.
      await addStub(99, 'com.example.gone');
      await db
          .into(db.books)
          .insert(
            BooksCompanion.insert(
              sourceId: 99,
              key: 'a-book',
              title: 'A Book',
              createdAt: clock.now(),
              updatedAt: clock.now(),
            ),
          );

      expect(await pruneUnusedSources(db, keep: {sourceId}), 0);
      expect(await sourceIds(), contains(99));
    });

    test('keeps a book that was taken out of the library', () async {
      // Out of the library is not gone: §4.4 keeps its progress, and adding it again must find its
      // source still there.
      await addStub(99, 'com.example.gone');
      await db
          .into(db.books)
          .insert(
            BooksCompanion.insert(
              sourceId: 99,
              key: 'a-book',
              title: 'A Book',
              inLibrary: const Value(false),
              createdAt: clock.now(),
              updatedAt: clock.now(),
            ),
          );

      expect(await pruneUnusedSources(db, keep: {sourceId}), 0);
    });

    test('keeps the sources of the extensions loaded now', () async {
      // An extension that is installed but has no books yet: its sources are what Browse lists.
      expect(await pruneUnusedSources(db, keep: {sourceId}), 0);
      expect(await sourceIds(), contains(sourceId));
    });

    test('never removes the local source', () async {
      await registerSource(
        db,
        id: 1,
        key: 'local',
        name: 'Local files',
        lang: 'und',
      );

      await pruneUnusedSources(db, keep: const {});

      expect(await sourceIds(), contains(1));
    });
  });

  group('registering a source', () {
    test('keeps what the listener decided about one already known', () async {
      await (db.update(db.sources)..where((s) => s.id.equals(sourceId))).write(
        const SourcesCompanion(isEnabled: Value(false), isPinned: Value(true)),
      );

      await registerSource(
        db,
        id: sourceId,
        key: 'librivox',
        name: 'LibriVox (renamed)',
        lang: 'multi',
        extensionId: 'org.kikuyomi.librivox',
      );

      final source = await (db.select(
        db.sources,
      )..where((s) => s.id.equals(sourceId))).getSingle();
      expect(source.name, 'LibriVox (renamed)');
      expect(source.isEnabled, isFalse);
      expect(source.isPinned, isTrue);
    });
  });

  group('saving a book from a source', () {
    test('writes its details, its credits and its chapters', () async {
      final saved = await saveSourceBook(
        db,
        sourceId: sourceId,
        details: details(),
        chapters: threeChapters(),
        clock: clock,
        addToLibrary: true,
      );

      final book = await bookRow(saved.bookId);
      expect(book.key, '753');
      expect(book.title, 'Moby Dick');
      expect(book.description, 'A whale.');
      expect(book.status, 'complete');
      expect(book.language, 'en');
      expect(book.genres, ['Nautical & Marine Fiction']);
      expect(book.inLibrary, isTrue);
      expect(book.dateAdded, clock.now());
      expect(book.detailsFetched, isTrue);
      expect(saved.coverUrl, contains('archive.org'));

      final overview = await watchBookOverview(db, saved.bookId).first;
      expect(overview!.authors, ['Herman Melville']);
      expect(overview.narrators, ['Stewart Wills']);
      expect(overview.chapters.map((c) => c.title), [
        'Loomings',
        'The Carpet-Bag',
        'The Spouter-Inn',
      ]);
    });

    test(
      'browsing a book stores it without putting it in the library',
      () async {
        final saved = await saveSourceBook(
          db,
          sourceId: sourceId,
          details: details(),
          chapters: threeChapters(),
          clock: clock,
        );

        final book = await bookRow(saved.bookId);
        expect(book.inLibrary, isFalse);
        expect(book.dateAdded, isNull);
      },
    );

    test('adding a browsed book later is one book, added now', () async {
      final first = await saveSourceBook(
        db,
        sourceId: sourceId,
        details: details(),
        chapters: threeChapters(),
        clock: clock,
      );
      clock.advance(const Duration(days: 1));

      final second = await saveSourceBook(
        db,
        sourceId: sourceId,
        details: details(),
        chapters: threeChapters(),
        clock: clock,
        addToLibrary: true,
      );

      expect(second.bookId, first.bookId);
      expect((await db.select(db.books).get()), hasLength(1));
      expect((await bookRow(first.bookId)).dateAdded, clock.now());
    });

    test('a refresh keeps a field the listener edited (§4.4)', () async {
      final saved = await saveSourceBook(
        db,
        sourceId: sourceId,
        details: details(),
        chapters: threeChapters(),
        clock: clock,
        addToLibrary: true,
      );
      await (db.update(
        db.books,
      )..where((b) => b.id.equals(saved.bookId))).write(
        BooksCompanion(
          title: const Value('Moby-Dick, or The Whale'),
          userOverrides: Value({BookField.title}),
        ),
      );

      await saveSourceBook(
        db,
        sourceId: sourceId,
        details: details(title: 'Moby Dick'),
        chapters: threeChapters(),
        clock: clock,
        addToLibrary: true,
      );

      expect((await bookRow(saved.bookId)).title, 'Moby-Dick, or The Whale');
    });

    test(
      'a status of unknown never undoes one the source gave before',
      () async {
        final saved = await saveSourceBook(
          db,
          sourceId: sourceId,
          details: details(),
          chapters: threeChapters(),
          clock: clock,
        );

        await saveSourceBook(
          db,
          sourceId: sourceId,
          details: details(status: api.BookStatus.unknown),
          chapters: threeChapters(),
          clock: clock,
        );

        expect((await bookRow(saved.bookId)).status, 'complete');
      },
    );

    test(
      'a chapter the source drops is soft-deleted, keeping its progress',
      () async {
        final saved = await saveSourceBook(
          db,
          sourceId: sourceId,
          details: details(),
          chapters: threeChapters(),
          clock: clock,
          addToLibrary: true,
        );
        final chapters = await chapterRows(saved.bookId);
        await (db.update(db.chapters)
              ..where((c) => c.id.equals(chapters.last.id)))
            .write(const ChaptersCompanion(lastPositionMs: Value(60000)));

        await saveSourceBook(
          db,
          sourceId: sourceId,
          details: details(),
          chapters: threeChapters().take(2).toList(),
          clock: clock,
        );

        final after = await chapterRows(saved.bookId);
        expect(after, hasLength(3));
        expect(after.last.removedFromSource, isTrue);
        expect(after.last.lastPositionMs, 60000);
      },
    );

    test('carries a release time and a group heading through sync', () async {
      final published = DateTime.utc(2026, 1, 2);
      final saved = await saveSourceBook(
        db,
        sourceId: sourceId,
        details: details(),
        chapters: [
          api.ChapterInfo(
            key: 's1',
            title: 'Loomings',
            durationMs: 1200000,
            publishedAt: published,
            group: 'Part One',
          ),
        ],
        clock: clock,
      );

      final chapter = (await chapterRows(saved.bookId)).single;
      expect(chapter.publishedAt, published);
      expect(chapter.groupName, 'Part One');
    });
  });

  group('the layout before a chapter is resolved', () {
    test('gives each chapter one estimated file of its own length', () async {
      final saved = await saveSourceBook(
        db,
        sourceId: sourceId,
        details: details(),
        chapters: threeChapters(),
        clock: clock,
        addToLibrary: true,
      );

      final files = await db.select(db.mediaFiles).get();
      expect(files, hasLength(3));
      expect(files.every((f) => isEstimatedFileKey(f.fileKey)), isTrue);
      expect(files.every((f) => f.durationIsEstimate), isTrue);
      expect(files.map((f) => f.durationMs), everyElement(1200000));

      // The point of the estimate: the book can be opened, scrubbed and resumed straight away.
      final playback = await loadStoredPlayback(db, saved.bookId);
      expect(playback.timeline.totalDurationMs, 3600000);
    });

    test('spreads the book\'s total over chapters with no duration', () async {
      final saved = await saveSourceBook(
        db,
        sourceId: sourceId,
        details: details(totalDurationMs: 3000),
        chapters: threeChapters(durationMs: null),
        clock: clock,
      );

      final playback = await loadStoredPlayback(db, saved.bookId);
      expect(playback.timeline.totalDurationMs, 3000);
    });

    test('falls back to a plain estimate when nothing can be spread', () async {
      final saved = await saveSourceBook(
        db,
        sourceId: sourceId,
        details: details(totalDurationMs: null),
        chapters: threeChapters(durationMs: null),
        clock: clock,
      );

      final files = await db.select(db.mediaFiles).get();
      expect(
        files.map((f) => f.durationMs),
        everyElement(defaultChapterEstimateMs),
      );
      final playback = await loadStoredPlayback(db, saved.bookId);
      expect(playback.timeline.totalDurationMs, 3 * defaultChapterEstimateMs);
    });

    test(
      'a refresh does not lay out a chapter that already has a layout',
      () async {
        await saveSourceBook(
          db,
          sourceId: sourceId,
          details: details(),
          chapters: threeChapters(),
          clock: clock,
        );
        final before = await db.select(db.mediaFiles).get();

        await saveSourceBook(
          db,
          sourceId: sourceId,
          details: details(),
          chapters: threeChapters(),
          clock: clock,
        );

        expect(
          (await db.select(db.mediaFiles).get()).map((f) => f.id),
          before.map((f) => f.id),
        );
      },
    );
  });
}
