// Listened state through a restore, written by the database's RestoreWriter from hand-built plans.
// Whether a backup's plan asks for listened state to be worked out from positions is the backup
// package's decision, tested there; this is what the database does with that decision.

import 'package:drift/drift.dart' hide isNull;
import 'package:kikuyomi_data/kikuyomi_data.dart';
import 'package:kikuyomi_domain/kikuyomi_domain.dart';
import 'package:kikuyomi_test_support/kikuyomi_test_support.dart';
import 'package:test/test.dart';

import '../library/fixtures.dart';

/// A plan restoring the whole of [library] into a library holding none of it.
RestorePlan everything(
  LibrarySnapshot library, {
  required bool listenedFromPositions,
}) => RestorePlan(
  newSources: library.sources,
  newCategories: library.categories,
  newBooks: library.books,
  listenedFromPositions: listenedFromPositions,
);

void main() {
  // Each test opens two databases, the one backed up and the one restored into, each on its own
  // in-memory executor. Drift's warning is about two databases sharing one executor, not this.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late KikuyomiDatabase original;
  late KikuyomiDatabase restored;
  late FakeClock clock;

  setUp(() {
    original = openDatabase();
    restored = openDatabase();
    clock = FakeClock(start);
  });

  tearDown(() async {
    await original.close();
    await restored.close();
  });

  /// Each chapter's recorded state in [db], in source order.
  Future<List<bool>> flags(KikuyomiDatabase db, int bookId) async => [
    for (final id in await chapterIdsOf(db, bookId))
      (await chapterRow(db, id)).isListened,
  ];

  Future<int> onlyBook(KikuyomiDatabase db) async =>
      (await db.select(db.books).getSingle()).id;

  group('from a backup written before listened state was recorded', () {
    test('records the chapters its positions reached, so finished books stay off Continue Listening', () async {
      final id = await addFolderBook(original, clock);
      await listenBeforeRecording(original, clock, id, 0, 600000);
      await listenBeforeRecording(original, clock, id, 1, 60000);
      await listenBeforeRecording(original, clock, id, 1, 1200000);
      await listenBeforeRecording(original, clock, id, 2, 300000);
      final finished = await addFolderBook(original, clock, title: 'Half');
      await listenBeforeRecording(original, clock, finished, 0, 300000);
      final backup = await DriftBackupStore(original).readLibrary();
      expect([
        for (final book in backup.books)
          for (final chapter in book.chapters) chapter.isListened,
      ], everyElement(isFalse));

      await DriftBackupStore(restored)
          .restore((_) => everything(backup, listenedFromPositions: true));

      final shelf = await watchContinueListening(restored, clock: clock).first;
      expect([for (final book in shelf) book.title], ['Half']);
      final book = await (restored.select(
        restored.books,
      )..where((b) => b.title.equals('A Book'))).getSingle();
      expect(await flags(restored, book.id), [true, true, true]);
      expect(
        (await watchBookOverview(restored, book.id).first)!.finished,
        isTrue,
      );
    });

    test('without that, would put finished books back on the shelf', () async {
      final id = await addFolderBook(original, clock);
      await listenBeforeRecording(original, clock, id, 2, 300000);
      final backup = await DriftBackupStore(original).readLibrary();

      await DriftBackupStore(restored)
          .restore((_) => everything(backup, listenedFromPositions: false));

      expect(
        await watchContinueListening(restored, clock: clock).first,
        hasLength(1),
      );
    });

    test('leaves alone chapters the restore did not write, so one marked not listened here stays so', () async {
      final id = await addFolderBook(restored, clock);
      final chapters = await chapterIdsOf(restored, id);
      await listen(restored, clock, id, 0, 600000);
      await mark(restored, clock, id, [chapters[0]], listened: false);
      final book = await (restored.select(
        restored.books,
      )..where((b) => b.id.equals(id))).getSingle();
      final second = (await chapterRow(restored, chapters[1])).key;

      // What a backup from before recording adds: the second chapter played through, elsewhere.
      await DriftBackupStore(restored).restore(
        (_) => RestorePlan(
          mergedBooks: [
            BookMerge(
              sourceId: book.sourceId,
              key: book.key,
              updatedAt: book.updatedAt,
              chapterProgress: [
                ChapterProgress(
                  chapterKey: second,
                  isListened: false,
                  listenedAt: null,
                  lastPositionMs: 1200000,
                  updatedAt: clock.now(),
                ),
              ],
            ),
          ],
          listenedFromPositions: true,
        ),
      );

      expect(await flags(restored, id), [false, true, false]);
    });

    test("records the chapter a restored book's progress is in", () async {
      final id = await addFolderBook(restored, clock);
      final chapters = await chapterIdsOf(restored, id);
      final book = await (restored.select(
        restored.books,
      )..where((b) => b.id.equals(id))).getSingle();
      final last = (await chapterRow(restored, chapters[2])).key;

      await DriftBackupStore(restored).restore(
        (_) => RestorePlan(
          mergedBooks: [
            BookMerge(
              sourceId: book.sourceId,
              key: book.key,
              updatedAt: book.updatedAt,
              progress: ProgressSnapshot(
                chapterKey: last,
                chapterPositionMs: 290000,
                globalPositionMs: 2090000,
                updatedAt: clock.now(),
                deviceId: 'phone',
              ),
            ),
          ],
          listenedFromPositions: true,
        ),
      );

      expect(await flags(restored, id), [false, false, true]);
      expect(
        await watchContinueListening(restored, clock: clock).first,
        isEmpty,
      );
    });
  });

  group('from a backup that records listened state', () {
    test(
      'restores it as written, so a chapter marked not listened stays so',
      () async {
        final id = await addFolderBook(original, clock);
        final chapters = await chapterIdsOf(original, id);
        await listen(original, clock, id, 0, 600000);
        await listen(original, clock, id, 1, 1200000);
        await mark(original, clock, id, [chapters[0]], listened: false);
        final backup = await DriftBackupStore(original).readLibrary();

        await DriftBackupStore(restored)
            .restore((_) => everything(backup, listenedFromPositions: false));

        final book = await onlyBook(restored);
        expect(await flags(restored, book), [false, true, false]);
        final first = await chapterRow(
          restored,
          (await chapterIdsOf(restored, book))[0],
        );
        expect(first.lastPositionMs, 600000, reason: 'the place is kept too');
      },
    );
  });
}
