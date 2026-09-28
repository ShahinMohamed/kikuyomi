// The database's side of backups, through the domain's interfaces and hand-built plans only. What the
// codec and the planner decide is tested in the backup package, against an in-memory library.

import 'package:drift/drift.dart' hide isNull;
import 'package:kikuyomi_data/kikuyomi_data.dart';
import 'package:kikuyomi_domain/kikuyomi_domain.dart';
import 'package:kikuyomi_test_support/kikuyomi_test_support.dart';
import 'package:test/test.dart';

import 'library_fixtures.dart';

/// A plan restoring the whole of [library] into a library holding none of it.
RestorePlan everything(LibrarySnapshot library) => RestorePlan(
  newSources: library.sources,
  newCategories: library.categories,
  newBooks: library.books,
);

/// What [library] lists, in the order it lists it, by identity.
List<Object?> orderOf(LibrarySnapshot library) => [
  [for (final source in library.sources) source.id],
  [for (final category in library.categories) category.name],
  for (final book in library.books)
    [
      book.sourceId,
      book.key,
      [for (final credit in book.contributors) credit.name],
      [for (final file in book.mediaFiles) file.fileKey],
      [
        for (final chapter in book.chapters)
          [
            chapter.key,
            for (final segment in chapter.segments) segment.fileKey,
          ],
      ],
      [
        for (final session in book.sessions)
          session.startedAt.millisecondsSinceEpoch,
      ],
      [for (final bookmark in book.bookmarks) bookmark.positionMs],
      book.categories,
    ],
];

/// [book] with every list it holds reversed, except chapter layouts, whose order is their meaning.
BookSnapshot reversed(BookSnapshot book) => BookSnapshot(
  sourceId: book.sourceId,
  key: book.key,
  details: book.details,
  userOverrides: book.userOverrides,
  contributors: book.contributors.reversed.toList(),
  inLibrary: book.inLibrary,
  dateAdded: book.dateAdded,
  lastRefreshedAt: book.lastRefreshedAt,
  detailsFetched: book.detailsFetched,
  playbackSpeed: book.playbackSpeed,
  kind: book.kind,
  createdAt: book.createdAt,
  updatedAt: book.updatedAt,
  mediaFiles: book.mediaFiles.reversed.toList(),
  chapters: book.chapters.reversed.toList(),
  progress: book.progress,
  reading: book.reading,
  sessions: book.sessions.reversed.toList(),
  readingSessions: book.readingSessions.reversed.toList(),
  bookmarks: book.bookmarks.reversed.toList(),
  categories: book.categories.reversed.toList(),
);

void main() {
  // Each test opens two databases, the one read from and the one restored into, each on its own
  // in-memory executor. Drift's warning is about two databases sharing one executor, not this.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late KikuyomiDatabase original;
  late KikuyomiDatabase restored;

  setUp(() async {
    original = openDatabase();
    restored = openDatabase();
    await seedLibrary(original);
  });

  tearDown(() async {
    await original.close();
    await restored.close();
  });

  group('what is read can be written back', () {
    test('column for column, apart from the cached cover', () async {
      final library = await DriftBackupStore(original).readLibrary();
      await DriftBackupStore(restored).restore((_) => everything(library));

      // A snapshot does not carry the cover image cached on this device, which is fetched again.
      await original
          .update(original.books)
          .write(
            const BooksCompanion(
              coverLocalPath: Value(null),
              coverUpdatedAt: Value(null),
            ),
          );
      // Nor a chapter's word count, which is counted from the text again when it is read.
      await original
          .update(original.chapters)
          .write(const ChaptersCompanion(wordCount: Value(null)));
      expect(await dumpLibrary(restored), await dumpLibrary(original));
    });

    test(
      'so that a book plays on from where it was left, at its speed',
      () async {
        final library = await DriftBackupStore(original).readLibrary();
        await DriftBackupStore(restored).restore((_) => everything(library));

        final book = await bookByKey(restored, aBook);
        final two = await chapterByKey(restored, book.id, 'two');
        final playback = await loadStoredPlayback(restored, book.id);
        expect(
          playback.resumeFrom,
          ChapterPosition(chapterId: two.id, offsetMs: 12345),
        );
        expect(playback.speed, 1.25);
        expect(playback.timeline.chapterIds, hasLength(2));
      },
    );

    test(
      'and reads back in an order set by identities, not by database ids',
      () async {
        final library = await DriftBackupStore(original).readLibrary();
        // Written in the opposite order, every row gets a different id.
        await DriftBackupStore(restored).restore(
          (_) => everything(
            LibrarySnapshot(
              sources: library.sources.reversed.toList(),
              categories: library.categories.reversed.toList(),
              books: [
                for (final book in library.books.reversed) reversed(book),
              ],
            ),
          ),
        );

        final reread = await DriftBackupStore(restored).readLibrary();
        expect(orderOf(reread), orderOf(library));
      },
    );
  });

  group('a restore', () {
    test(
      'is planned against the library as it is inside the transaction',
      () async {
        LibrarySnapshot? seen;
        final applied = await DriftBackupStore(original).restore((current) {
          seen = current;
          return const RestorePlan();
        });

        expect(applied.isEmpty, isTrue);
        expect([
          for (final book in seen!.books) book.key,
        ], unorderedEquals([aBook, startedBook, 'a-novel.epub', 'browsed']));
      },
    );

    test('writes everything a plan adds to a book the library has', () async {
      final store = DriftBackupStore(original);
      final before = await bookByKey(original, aBook);
      await (original.update(
        original.books,
      )..where((b) => b.id.equals(before.id))).write(
        const BooksCompanion(
          inLibrary: Value(false),
          playbackSpeed: Value(null),
        ),
      );

      await store.restore(
        (_) => RestorePlan(
          newCategories: const [
            CategorySnapshot(name: 'Later', sortOrder: 2, flags: 3),
          ],
          mergedBooks: [
            BookMerge(
              sourceId: catalogSourceId,
              key: aBook,
              updatedAt: at(700),
              edits: (
                details: BookDetailsSnapshot(
                  title: 'My Title',
                  subtitle: 'My Subtitle',
                ),
                userOverrides: const {BookField.title, BookField.subtitle},
              ),
              addToLibrary: true,
              dateAdded: at(701),
              playbackSpeed: 1.5,
              newFiles: const [
                MediaFileSnapshot(
                  fileKey: 'old.mp3',
                  durationMs: 1000,
                  durationIsEstimate: false,
                ),
              ],
              newChapters: [
                ChapterSnapshot(
                  key: 'old',
                  title: 'An Old Chapter',
                  sourceIndex: 9,
                  createdAt: at(702),
                  updatedAt: at(702),
                  lastPositionMs: 400,
                  removedFromSource: true,
                  segments: const [SegmentSnapshot(fileKey: 'old.mp3')],
                ),
              ],
              chapterProgress: [
                ChapterProgress(
                  chapterKey: 'two',
                  isListened: true,
                  listenedAt: at(703),
                  lastPositionMs: 150000,
                  updatedAt: at(703),
                ),
              ],
              progress: ProgressSnapshot(
                chapterKey: 'old',
                chapterPositionMs: 400,
                globalPositionMs: 400,
                updatedAt: at(704),
                deviceId: 'phone',
              ),
              newSessions: [
                SessionSnapshot(
                  chapterKey: 'old',
                  startedAt: at(705),
                  endedAt: at(706),
                  startGlobalMs: 0,
                  endGlobalMs: 400,
                  speed: 1.5,
                  deviceId: 'phone',
                ),
                SessionSnapshot(
                  startedAt: at(707),
                  endedAt: at(708),
                  startGlobalMs: 0,
                  endGlobalMs: 400,
                  speed: 1.5,
                  deviceId: 'phone',
                ),
              ],
              newBookmarks: [
                BookmarkSnapshot(
                  chapterKey: 'two',
                  positionMs: 777,
                  createdAt: at(709),
                  note: 'From the phone.',
                ),
              ],
              newCategories: const ['Later', 'Empty'],
            ),
          ],
        ),
      );

      final book = await bookByKey(original, aBook);
      expect(book.id, before.id, reason: 'merged, not added again');
      expect(book.title, 'My Title');
      expect(book.subtitle, 'My Subtitle');
      expect(book.description, isNull, reason: 'edits replace the details');
      expect(book.userOverrides, {BookField.title, BookField.subtitle});
      expect(book.inLibrary, isTrue);
      expect(book.dateAdded!.toUtc(), at(701));
      expect(book.playbackSpeed, 1.5);
      expect(book.updatedAt.toUtc(), at(700));

      final old = await chapterByKey(original, book.id, 'old');
      expect(old.removedFromSource, isTrue);
      expect(old.lastPositionMs, 400);
      final layout = await (original.select(
        original.chapterSegments,
      )..where((s) => s.chapterId.equals(old.id))).getSingle();
      final file = await (original.select(
        original.mediaFiles,
      )..where((f) => f.id.equals(layout.mediaFileId))).getSingle();
      expect(file.fileKey, 'old.mp3');

      final two = await chapterByKey(original, book.id, 'two');
      expect(two.isListened, isTrue);
      expect(two.lastPositionMs, 150000);
      expect(two.updatedAt.toUtc(), at(703));

      final progress = await (original.select(
        original.playbackStates,
      )..where((p) => p.bookId.equals(book.id))).getSingle();
      expect(progress.chapterId, old.id);
      expect(progress.deviceId, 'phone');

      final sessions = await (original.select(
        original.listeningSessions,
      )..where((s) => s.bookId.equals(book.id))).get();
      expect(sessions, hasLength(4));
      expect(sessions.where((s) => s.chapterId == old.id), hasLength(1));
      expect(
        await (original.select(
          original.bookmarks,
        )..where((b) => b.bookId.equals(book.id))).get(),
        hasLength(3),
      );

      final categoryNames = {
        for (final c in await original.select(original.categories).get())
          c.id: c.name,
      };
      final memberships = await (original.select(
        original.bookCategories,
      )..where((m) => m.bookId.equals(book.id))).get();
      expect(
        {for (final m in memberships) categoryNames[m.categoryId]},
        {'Next up', 'Later', 'Empty'},
      );
    });

    test(
      'joins books to the categories the library already has, by name',
      () async {
        await restored
            .into(restored.categories)
            .insert(
              const CategoriesCompanion(
                name: Value('Next up'),
                sortOrder: Value(5),
              ),
            );
        final library = await DriftBackupStore(original).readLibrary();
        final book = library.books.firstWhere((b) => b.key == aBook);

        await DriftBackupStore(restored).restore(
          (_) => RestorePlan(
            newSources: [
              library.sources.firstWhere((s) => s.id == catalogSourceId),
            ],
            newBooks: [book],
          ),
        );

        final categories = await restored.select(restored.categories).get();
        expect(categories, hasLength(1));
        final membership = await restored
            .select(restored.bookCategories)
            .getSingle();
        expect(membership.categoryId, categories.single.id);
      },
    );

    test('into a book imported again brings its progress back', () async {
      const path = r'C:\Books\Again.m4b';
      final id = await importLocalBook(
        restored,
        const LocalBookImport(
          file: LocalBookFile(path: path, durationMs: 60000),
          title: 'Again',
        ),
        clock: FakeClock(at(1000)),
      );

      await DriftBackupStore(restored).restore(
        (_) => RestorePlan(
          mergedBooks: [
            BookMerge(
              sourceId: localSourceId,
              key: path,
              updatedAt: at(1000),
              chapterProgress: [
                ChapterProgress(
                  chapterKey: 'whole',
                  isListened: false,
                  listenedAt: null,
                  lastPositionMs: 42000,
                  updatedAt: at(10),
                ),
              ],
              progress: ProgressSnapshot(
                chapterKey: 'whole',
                chapterPositionMs: 42000,
                globalPositionMs: 42000,
                updatedAt: at(10),
                deviceId: 'this-pc',
              ),
            ),
          ],
        ),
      );

      final whole = await chapterByKey(restored, id, 'whole');
      expect(whole.lastPositionMs, 42000);
      expect(
        (await loadStoredPlayback(restored, id)).resumeFrom,
        ChapterPosition(chapterId: whole.id, offsetMs: 42000),
      );
    });

    test('whose plan refers to something the library lacks fails, and writes none of it', () async {
      final before = await dumpLibrary(original);

      await expectLater(
        DriftBackupStore(original).restore(
          (_) => RestorePlan(
            newCategories: const [
              CategorySnapshot(name: 'Later', sortOrder: 2),
            ],
            mergedBooks: [
              BookMerge(
                sourceId: catalogSourceId,
                key: aBook,
                updatedAt: at(700),
                playbackSpeed: 2,
                newBookmarks: [
                  BookmarkSnapshot(
                    chapterKey: 'missing',
                    positionMs: 1,
                    createdAt: at(700),
                  ),
                ],
              ),
            ],
          ),
        ),
        throwsStateError,
      );
      expect(await dumpLibrary(original), before);
    });
  });
}
