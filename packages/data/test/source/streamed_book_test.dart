// A book that streams from a source is a book like any other.
//
// The point of writing a source's answer through the §4.4 merges, rather than into a shape of its
// own, is that everything Phase 1 built keeps working on it: the Timeline, progress, listened state,
// bookmarks, Continue Listening and a book's details screen. Nothing here knows it is streaming.

import 'package:drift/drift.dart' show TableUpdate, TableUpdateQuery;
import 'package:drift/native.dart';
import 'package:kikuyomi_data/kikuyomi_data.dart';
import 'package:kikuyomi_domain/kikuyomi_domain.dart';
import 'package:kikuyomi_source_api/kikuyomi_source_api.dart' as api;
import 'package:kikuyomi_test_support/kikuyomi_test_support.dart';
import 'package:test/test.dart';

const sourceId = 0x4c4942;

final theBook = api.BookDetails(
  key: '9638',
  title: 'Yellowstone National Park',
  authors: const ['Various'],
  narrators: const ['David Wales'],
  coverUrl: Uri.parse('https://archive.org/services/img/yellowstone'),
  totalDurationMs: 2400000,
);

final theChapters = [
  const api.ChapterInfo(key: 's1', title: 'Hayden', durationMs: 1200000),
  const api.ChapterInfo(key: 's2', title: 'The Wonders', durationMs: 1200000),
];

api.MediaResolution fileNamed(String name, {int durationMs = 1200000}) =>
    api.MediaResolution(
      segments: [
        api.MediaSegment(
          fileKey: name,
          request: api.HttpRequest(
            url: Uri.parse('https://archive.org/download/yellowstone/$name'),
          ),
          format: api.MediaFormat.mp3,
          durationMs: durationMs,
        ),
      ],
    );

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

  Future<int> aStreamedBook() async {
    final saved = await saveSourceBook(
      db,
      sourceId: sourceId,
      details: theBook,
      chapters: theChapters,
      clock: clock,
      addToLibrary: true,
    );
    return saved.bookId;
  }

  test('it can be opened and scrubbed before anything is resolved', () async {
    final bookId = await aStreamedBook();

    final playback = await loadStoredPlayback(db, bookId);

    expect(playback.timeline.totalDurationMs, 2400000);
    expect(playback.timeline.navigation, hasLength(2));
    // Every figure is an estimate until a file is played (§4.5).
    expect(playback.timeline.isEstimate, isTrue);
    // Scrubbing to the middle lands in the second chapter, as it would for a local book.
    final position = playback.timeline.chapterPositionAt(1500000);
    expect(position.chapterId, playback.timeline.chapterIds.last);
    expect(playback.timeline.navigationEntryAt(1500000).title, 'The Wonders');
  });

  test(
    'progress, listened state and Continue Listening all work on it',
    () async {
      final bookId = await aStreamedBook();
      final timeline = (await loadStoredPlayback(db, bookId)).timeline;
      final store = DriftPlaybackStore(db, deviceId: 'test', clock: clock);
      final first = timeline.chapterIds.first;

      await store.saveProgress(
        bookId: bookId,
        position: ChapterPosition(chapterId: first, offsetMs: 1190000),
        globalMs: 1190000,
        listened: true,
      );

      final overview = await watchBookOverview(db, bookId).first;
      expect(overview!.progress!.chapterPositionMs, 1190000);
      expect(overview.chapters.first.listened, isTrue);
      expect(overview.chapters.first.current, isTrue);
      expect(overview.finished, isFalse);

      final shelf = await watchContinueListening(db, clock: clock).first;
      expect(shelf.single.bookId, bookId);
      expect(shelf.single.chapterTitle, 'Hayden');
    },
  );

  test('a bookmark in it is a bookmark like any other', () async {
    final bookId = await aStreamedBook();
    final timeline = (await loadStoredPlayback(db, bookId)).timeline;

    await addBookmark(
      db,
      bookId: bookId,
      position: ChapterPosition(
        chapterId: timeline.chapterIds.last,
        offsetMs: 30000,
      ),
      clock: clock,
    );

    final bookmarks = await watchBookmarks(db, bookId).first;
    expect(bookmarks.single.chapterTitle, 'The Wonders');
    expect(bookmarks.single.chapterPositionMs, 30000);
  });

  test('the last chapter listened finishes it (§4.5)', () async {
    final bookId = await aStreamedBook();

    await markBookFinished(db, bookId, clock: clock);

    expect((await watchBookOverview(db, bookId).first)!.finished, isTrue);
    expect(await watchContinueListening(db, clock: clock).first, isEmpty);
  });

  test('a duration learned from the engine refines the estimate', () async {
    // §4.5: what the source claimed is replaced by what the file turned out to be, and the
    // listener's chapter-relative position is untouched.
    final bookId = await aStreamedBook();
    final timeline = (await loadStoredPlayback(db, bookId)).timeline;
    final fileId = timeline.queue.first.fileId;
    final store = DriftPlaybackStore(db, deviceId: 'test', clock: clock);

    await store.saveLearnedDuration(
      bookId: bookId,
      fileId: fileId,
      durationMs: 1234567,
    );

    final file = await (db.select(
      db.mediaFiles,
    )..where((f) => f.id.equals(fileId))).getSingle();
    expect(file.durationMs, 1234567);
    expect(file.durationIsEstimate, isFalse);
  });

  test(
    'resolving keeps the book playable, with the real file behind it',
    () async {
      final bookId = await aStreamedBook();
      final before = await loadStoredPlayback(db, bookId);
      final resolver = SourceMediaResolver(
        db,
        openSource: (_) async => FakeContentSource(
          media: {
            's1': fileNamed('yellowstone_01.mp3'),
            's2': fileNamed('yellowstone_02.mp3'),
          },
        ),
        onDevice: _NothingOnDevice(),
        clock: clock,
      );

      for (final item in before.timeline.queue) {
        await resolver.resolve(item.fileId);
      }

      final after = await loadStoredPlayback(db, bookId);
      // The same files, in the same order: the estimates were consumed in place, so a book already
      // playing keeps the ids its Timeline holds.
      expect(
        after.timeline.queue.map((item) => item.fileId),
        before.timeline.queue.map((item) => item.fileId),
      );
      expect((await db.select(db.mediaFiles).get()).map((f) => f.fileKey), [
        'yellowstone_01.mp3',
        'yellowstone_02.mp3',
      ]);
    },
  );

  group('resolving the same book again', () {
    late FakeContentSource source;
    late SourceMediaResolver resolver;

    setUp(() {
      source = FakeContentSource(
        media: {
          's1': fileNamed('yellowstone_01.mp3'),
          's2': fileNamed('yellowstone_02.mp3'),
        },
      );
      resolver = SourceMediaResolver(
        db,
        openSource: (_) async => source,
        onDevice: _NothingOnDevice(),
        clock: clock,
      );
    });

    test('writes nothing when the layout is already what it says', () async {
      final bookId = await aStreamedBook();
      final fileId = (await loadStoredPlayback(
        db,
        bookId,
      )).timeline.queue.first.fileId;
      await resolver.resolve(fileId);
      final written = await db.select(db.chapterSegments).get();

      // A resolver with nothing in hand, as a second run of the app has: the URLs are gone, so the
      // source is asked again, and what it says is what the book already holds.
      final second = SourceMediaResolver(
        db,
        openSource: (_) async => source,
        onDevice: _NothingOnDevice(),
        clock: clock,
      );
      final changed = <TableUpdate>{};
      final watching = db
          .tableUpdates(const TableUpdateQuery.any())
          .listen(changed.addAll);
      addTearDown(watching.cancel);

      final media = await second.resolve(fileId);
      await Future<void>.delayed(Duration.zero);

      expect(
        '${media.uri}',
        'https://archive.org/download/yellowstone/yellowstone_01.mp3',
      );
      expect(changed, isEmpty, reason: 'the book already says all of this');
      expect(
        (await db.select(db.chapterSegments).get()).map(
          (s) => (s.chapterId, s.mediaFileId, s.startMs, s.endMs),
        ),
        written.map((s) => (s.chapterId, s.mediaFileId, s.startMs, s.endMs)),
      );
    });

    test('a resolution already in hand is not asked for again', () async {
      final bookId = await aStreamedBook();
      final fileId = (await loadStoredPlayback(
        db,
        bookId,
      )).timeline.queue.first.fileId;

      expect(
        await resolver.resolveIfOnHand(fileId),
        isNull,
        reason: 'nothing has been resolved yet, and nothing is on the device',
      );
      await resolver.resolve(fileId);
      final onHand = await resolver.resolveIfOnHand(fileId);

      expect(onHand, isNotNull);
      expect(source.calls.where((call) => call.startsWith('resolveMedia')), [
        'resolveMedia(s1)',
      ]);
    });

    test('two callers asking at once cost the source one call', () async {
      final bookId = await aStreamedBook();
      final fileId = (await loadStoredPlayback(
        db,
        bookId,
      )).timeline.queue.first.fileId;

      final both = await Future.wait([
        resolver.resolve(fileId),
        resolver.resolve(fileId),
      ]);

      expect(both.first.uri, both.last.uri);
      expect(source.calls.where((call) => call.startsWith('resolveMedia')), [
        'resolveMedia(s1)',
      ]);
    });
  });
}

/// A device with nothing on it: a streamed book has no local file to find.
final class _NothingOnDevice implements MediaResolver {
  @override
  Future<ResolvedMedia> resolve(int fileId, {bool refresh = false}) async =>
      throw const MediaUnavailableException('nothing is downloaded');

  @override
  Future<ResolvedMedia?> resolveIfOnHand(int fileId) async => null;
}
