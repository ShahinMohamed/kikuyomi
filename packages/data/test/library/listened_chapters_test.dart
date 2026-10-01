import 'package:drift/drift.dart' hide isNull;
import 'package:kikuyomi_data/kikuyomi_data.dart';
import 'package:kikuyomi_domain/kikuyomi_domain.dart';
import 'package:kikuyomi_test_support/kikuyomi_test_support.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

void main() {
  late KikuyomiDatabase db;
  late FakeClock clock;

  setUp(() {
    db = openDatabase();
    clock = FakeClock(start);
  });

  tearDown(() => db.close());

  Future<BookOverview> overview(int bookId) async =>
      (await watchBookOverview(db, bookId).first)!;

  /// Each chapter's recorded state, in source order.
  Future<List<bool>> flags(int bookId) async => [
    for (final id in await chapterIdsOf(db, bookId))
      (await chapterRow(db, id)).isListened,
  ];

  group('marking chapters by hand', () {
    test('records a chapter listened as of now, and returns it', () async {
      final id = await addFolderBook(db, clock);
      final chapters = await chapterIdsOf(db, id);

      final changed = await mark(db, clock, id, [chapters[1]], listened: true);

      expect(changed, {chapters[1]});
      expect(await flags(id), [false, true, false]);
      final row = await chapterRow(db, chapters[1]);
      expect(row.listenedAt!.isAtSameMomentAs(start), isTrue);
      expect(row.updatedAt.isAtSameMomentAs(start), isTrue);
    });

    test(
      'marks a chapter not listened, forgetting when it was listened',
      () async {
        final id = await addFolderBook(db, clock);
        final chapters = await chapterIdsOf(db, id);
        await listen(db, clock, id, 0, 600000);

        expect(await mark(db, clock, id, [chapters[0]], listened: false), {
          chapters[0],
        });
        final row = await chapterRow(db, chapters[0]);
        expect(row.isListened, isFalse);
        expect(row.listenedAt, isNull);
      },
    );

    test("leaves the listener's place where it was", () async {
      final id = await addFolderBook(db, clock);
      final chapters = await chapterIdsOf(db, id);
      await listen(db, clock, id, 0, 600000);
      await listen(db, clock, id, 1, 1190000);
      final before = await db.select(db.playbackStates).getSingle();

      await mark(db, clock, id, [chapters[0], chapters[1]], listened: false);

      final after = await db.select(db.playbackStates).getSingle();
      expect(after.chapterId, before.chapterId);
      expect(after.chapterPositionMs, 1190000);
      expect(after.updatedAt.isAtSameMomentAs(before.updatedAt), isTrue);
      expect((await chapterRow(db, chapters[0])).lastPositionMs, 600000);
      expect((await chapterRow(db, chapters[1])).lastPositionMs, 1190000);
    });

    test(
      "returns only the chapters it changed, and leaves another book's alone",
      () async {
        final id = await addFolderBook(db, clock);
        final other = await addFolderBook(db, clock, title: 'Another');
        final chapters = await chapterIdsOf(db, id);
        final others = await chapterIdsOf(db, other);
        await listen(db, clock, id, 0, 600000);

        expect(
          await mark(db, clock, id, [chapters[0], chapters[1]], listened: true),
          {chapters[1]},
        );
        expect(await mark(db, clock, id, [others[0]], listened: true), isEmpty);
        expect(await flags(other), [false, false, false]);
      },
    );

    test('a chapter marked not listened is recorded again once progress is saved past its threshold', () async {
      final id = await addFolderBook(db, clock);
      final chapters = await chapterIdsOf(db, id);
      await listen(db, clock, id, 0, 590000);
      await mark(db, clock, id, [chapters[0]], listened: false);
      expect(await flags(id), [false, false, false]);

      await listen(db, clock, id, 0, 595000);
      expect(await flags(id), [true, false, false]);
    });
  });

  group('marking a book finished', () {
    test(
      'records every chapter, and returns those that were not listened',
      () async {
        final id = await addFolderBook(db, clock);
        final chapters = await chapterIdsOf(db, id);
        await listen(db, clock, id, 0, 600000);
        await listen(db, clock, id, 1, 60000);

        final changed = await markBookFinished(db, id, clock: clock);

        expect(changed, {chapters[1], chapters[2]});
        expect(await flags(id), [true, true, true]);
        final book = await overview(id);
        expect(book.finished, isTrue);
        expect(
          book.progress!.chapterId,
          chapters[1],
          reason: 'the place stays',
        );
        expect(book.progress!.chapterPositionMs, 60000);
      },
    );

    test('leaves out chapters the source no longer reports', () async {
      final id = await addFolderBook(db, clock);
      final chapters = await chapterIdsOf(db, id);
      await (db.update(db.chapters)..where((c) => c.id.equals(chapters[2])))
          .write(const ChaptersCompanion(removedFromSource: Value(true)));

      expect(await markBookFinished(db, id, clock: clock), {
        chapters[0],
        chapters[1],
      });
      expect(await flags(id), [true, true, false]);
      expect((await overview(id)).finished, isTrue);
    });

    test('finishes a book never started', () async {
      final id = await addFolderBook(db, clock);
      await markBookFinished(db, id, clock: clock);
      final book = await overview(id);
      expect(book.finished, isTrue);
      expect(book.progress, isNull);
    });

    test(
      'is undone by marking the chapters it returned not listened',
      () async {
        final id = await addFolderBook(db, clock);
        await listen(db, clock, id, 0, 600000);

        final changed = await markBookFinished(db, id, clock: clock);
        await mark(db, clock, id, [...changed], listened: false);

        expect(await flags(id), [true, false, false]);
        expect((await overview(id)).finished, isFalse);
      },
    );
  });

  group('marking a book not finished', () {
    test('takes away only its last chapter', () async {
      final id = await addFolderBook(db, clock);
      final chapters = await chapterIdsOf(db, id);
      await markBookFinished(db, id, clock: clock);

      expect(await markBookNotFinished(db, id, clock: clock), {chapters[2]});
      expect(await flags(id), [true, true, false]);
      expect((await overview(id)).finished, isFalse);
    });

    test('does nothing to a book that is not finished', () async {
      final id = await addFolderBook(db, clock);
      await listen(db, clock, id, 0, 600000);
      expect(await markBookNotFinished(db, id, clock: clock), isEmpty);
      expect(await flags(id), [true, false, false]);
    });

    test("of a single file, takes away its one chapter's state", () async {
      final id = await addM4b(db, clock);
      await markBookFinished(db, id, clock: clock);
      expect(
        [for (final m in (await overview(id)).markers) m.listened],
        [true, true, true],
      );

      await markBookNotFinished(db, id, clock: clock);
      expect(
        [for (final m in (await overview(id)).markers) m.listened],
        [false, false, false],
      );
    });
  });

  group('the backfill of positions saved before listened state was recorded', () {
    Future<void> listenedBefore(int bookId, int chapterIndex, int offsetMs) =>
        listenBeforeRecording(db, clock, bookId, chapterIndex, offsetMs);

    test(
      'records the chapters whose positions reached their thresholds',
      () async {
        final id = await addFolderBook(db, clock);
        // Opening lasts 10 minutes, so 30 seconds is the larger: listened from 9:30.
        await listenedBefore(id, 0, 570000);
        // Middle lasts 20 minutes, so 3 percent is the larger: listened from 19:24.
        await listenedBefore(id, 1, 1163999);
        await listenedBefore(id, 2, 10000);
        expect(await flags(id), [false, false, false]);

        expect(await backfillListenedChapters(db), 1);
        expect(await flags(id), [true, false, false]);
      },
    );

    test('records a long chapter from 3 percent short of its end', () async {
      final id = await addFolderBook(db, clock);
      await listenedBefore(id, 1, 1164000);
      expect(await backfillListenedChapters(db), 1);
      expect(await flags(id), [false, true, false]);
    });

    test(
      'reads the progress of the chapter the listener is in, even at its start',
      () async {
        final id = await addFolderBook(
          db,
          clock,
          parts: const [('One', 20000), ('Two', 20000), ('Three', 20000)],
        );
        // At 30 seconds or less the threshold is zero, so being in the chapter is enough; the
        // chapters never reached are left alone.
        await listenedBefore(id, 1, 0);
        await backfillListenedChapters(db);
        expect(await flags(id), [false, true, false]);
      },
    );

    test('finishes a book whose progress reached its last chapter, which leaves Continue Listening', () async {
      final id = await addFolderBook(db, clock);
      await listenedBefore(id, 2, 270000);
      expect(
        await watchContinueListening(db, clock: clock).first,
        hasLength(1),
      );

      await backfillListenedChapters(db);

      expect((await overview(id)).finished, isTrue);
      expect(await watchContinueListening(db, clock: clock).first, isEmpty);
    });

    test('records a single file only once it is near its end', () async {
      final id = await addM4b(db, clock);
      await listenedBefore(id, 0, 1500000);
      expect(await backfillListenedChapters(db), 0);

      // An hour less 3 percent is 58:12.
      await listenedBefore(id, 0, 3492000);
      expect(await backfillListenedChapters(db), 1);
      expect((await overview(id)).finished, isTrue);
    });

    test('takes the time progress was last saved in the chapter as when it was listened', () async {
      final id = await addFolderBook(db, clock);
      final chapters = await chapterIdsOf(db, id);
      final savedAt = clock.now();
      await listenedBefore(id, 0, 600000);
      await listenedBefore(id, 1, 60000);

      await backfillListenedChapters(db);

      final row = await chapterRow(db, chapters[0]);
      expect(row.listenedAt!.isAtSameMomentAs(savedAt), isTrue);
      expect(row.updatedAt.isAtSameMomentAs(savedAt), isTrue);
    });

    test(
      "judges a book that cannot be played by its chapters' own durations",
      () async {
        final id = await addFolderBook(db, clock);
        await listenedBefore(id, 0, 570000);
        await (db.update(db.mediaFiles)..where((f) => f.bookId.equals(id)))
            .write(const MediaFilesCompanion(durationMs: Value(null)));

        await backfillListenedChapters(db);
        expect(await flags(id), [true, false, false]);
      },
    );

    test('leaves alone a chapter already recorded', () async {
      final id = await addFolderBook(db, clock);
      final chapters = await chapterIdsOf(db, id);
      final markedAt = clock.now();
      await mark(db, clock, id, [chapters[0]], listened: true);
      await listenedBefore(id, 0, 600000);

      expect(await backfillListenedChapters(db), 0);
      final row = await chapterRow(db, chapters[0]);
      expect(row.listenedAt!.isAtSameMomentAs(markedAt), isTrue);
    });

    test('run twice, changes nothing the second time', () async {
      final first = await addFolderBook(db, clock);
      final second = await addM4b(db, clock);
      await listenedBefore(first, 0, 600000);
      await listenedBefore(first, 2, 290000);
      await listenedBefore(second, 0, 3600000);

      expect(await backfillListenedChapters(db), 3);
      final once = [
        for (final row in await db.select(db.chapters).get())
          (
            row.id,
            row.isListened,
            row.listenedAt,
            row.updatedAt,
            row.lastPositionMs,
          ),
      ];

      expect(await backfillListenedChapters(db), 0);
      final twice = [
        for (final row in await db.select(db.chapters).get())
          (
            row.id,
            row.isListened,
            row.listenedAt,
            row.updatedAt,
            row.lastPositionMs,
          ),
      ];
      expect(twice, once);
    });

    group('once', () {
      test('runs the first time, and says so in settings', () async {
        final settings = InMemorySettingsStore();
        final id = await addFolderBook(db, clock);
        await listenedBefore(id, 0, 600000);

        await backfillListenedChaptersOnce(db, settings);

        expect(await flags(id), [true, false, false]);
        expect(settings.read(AppSettings.listenedBackfilled), isTrue);
      });

      test(
        'does not run again, so a chapter marked not listened stays so',
        () async {
          final settings = InMemorySettingsStore();
          final id = await addFolderBook(db, clock);
          final chapters = await chapterIdsOf(db, id);
          await listenedBefore(id, 0, 600000);
          await backfillListenedChaptersOnce(db, settings);

          await mark(db, clock, id, [chapters[0]], listened: false);
          await backfillListenedChaptersOnce(db, settings);

          expect(await flags(id), [false, false, false]);
        },
      );
    });
  });
}
