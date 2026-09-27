import 'package:kikuyomi_backup/kikuyomi_backup.dart';
import 'package:kikuyomi_domain/kikuyomi_domain.dart';
import 'package:kikuyomi_source_api/kikuyomi_source_api.dart' show SourceKind;
import 'package:test/test.dart';

import 'fixtures.dart';

// Builders with defaults, so that each test spells out only what it is about.

const local = SourceSnapshot(
  id: 1,
  key: 'local',
  name: 'Local files',
  lang: 'und',
);

ChapterSnapshot chapter(
  String key, {
  int index = 0,
  int positionMs = 0,
  bool listened = false,
  DateTime? updatedAt,
  List<SegmentSnapshot> segments = const [],
}) => ChapterSnapshot(
  key: key,
  title: key,
  sourceIndex: index,
  lastPositionMs: positionMs,
  isListened: listened,
  listenedAt: listened ? updatedAt ?? t0 : null,
  createdAt: t0,
  updatedAt: updatedAt ?? t0,
  segments: segments,
);

ProgressSnapshot progressAt(
  String chapterKey,
  int positionMs,
  DateTime updatedAt,
) => ProgressSnapshot(
  chapterKey: chapterKey,
  chapterPositionMs: positionMs,
  globalPositionMs: positionMs,
  updatedAt: updatedAt,
  deviceId: 'this-pc',
);

SessionSnapshot sessionAt(
  DateTime start, {
  String? chapterKey = 'one',
  String deviceId = 'this-pc',
}) => SessionSnapshot(
  chapterKey: chapterKey,
  startedAt: start,
  endedAt: start.add(const Duration(minutes: 5)),
  startGlobalMs: 0,
  endGlobalMs: 300000,
  speed: 1,
  deviceId: deviceId,
);

BookmarkSnapshot bookmarkAt(String chapterKey, int positionMs) =>
    BookmarkSnapshot(
      chapterKey: chapterKey,
      positionMs: positionMs,
      createdAt: t0,
    );

BookSnapshot book({
  int sourceId = 1,
  String key = 'book',
  BookDetailsSnapshot? details,
  Set<BookField> userOverrides = const {},
  bool inLibrary = true,
  DateTime? dateAdded,
  double? speed,
  List<MediaFileSnapshot> files = const [],
  List<ChapterSnapshot> chapters = const [],
  ProgressSnapshot? progress,
  SourceKind kind = SourceKind.audio,
  ReadingSnapshot? reading,
  List<SessionSnapshot> sessions = const [],
  List<BookmarkSnapshot> bookmarks = const [],
  List<String> categories = const [],
}) => BookSnapshot(
  sourceId: sourceId,
  key: key,
  details: details ?? BookDetailsSnapshot(title: 'A Book'),
  userOverrides: userOverrides,
  inLibrary: inLibrary,
  dateAdded: dateAdded,
  playbackSpeed: speed,
  createdAt: t0,
  updatedAt: t0,
  mediaFiles: files,
  chapters: chapters,
  progress: progress,
  kind: kind,
  reading: reading,
  sessions: sessions,
  bookmarks: bookmarks,
  categories: categories,
);

ReadingSnapshot readingAt(String chapterKey, double progress, DateTime at) =>
    ReadingSnapshot(chapterKey: chapterKey, progress: progress, updatedAt: at);

LibrarySnapshot libraryOf(
  List<BookSnapshot> books, {
  List<CategorySnapshot> categories = const [],
}) => LibrarySnapshot(
  sources: const [local],
  categories: categories,
  books: books,
);

/// The merge planned for one book that both the backup and the library hold.
BookMerge mergeOf({
  required BookSnapshot backedUp,
  required BookSnapshot here,
}) {
  final plan = planRestore(
    backup: libraryOf([backedUp]),
    current: libraryOf([here]),
  );
  expect(plan.newBooks, isEmpty);
  return plan.mergedBooks.single;
}

bool changesNothing({
  required BookSnapshot backedUp,
  required BookSnapshot here,
}) => planRestore(
  backup: libraryOf([backedUp]),
  current: libraryOf([here]),
).isEmpty;

void main() {
  test('into an empty library, everything is restored as it was backed up', () {
    final backup = fullLibrary();
    final plan = planRestore(backup: backup, current: const LibrarySnapshot());
    expect(plan.newSources, backup.sources);
    expect(plan.newBooks, backup.books);
    expect(plan.mergedBooks, isEmpty);
    final category = plan.newCategories.single;
    expect(
      (category.name, category.sortOrder, category.flags),
      ('Next up', 3, 5),
    );
  });

  group('listened state (§4.5)', () {
    final backup = libraryOf([
      book(chapters: [chapter('one', positionMs: 300000)]),
    ]);

    test('from a backup written before it was recorded, is worked out from positions', () {
      final plan = planRestore(
        backup: backup,
        current: const LibrarySnapshot(),
        formatVersion: 1,
      );
      expect(plan.listenedFromPositions, isTrue);
      expect(
        plan.newBooks,
        backup.books,
        reason: 'the backup is otherwise restored as written',
      );
    });

    test('from a backup that records it, is restored as written', () {
      for (final version in [
        backupListenedRecordedSince,
        backupFormatVersion,
        backupFormatVersion + 1,
      ]) {
        final plan = planRestore(
          backup: backup,
          current: const LibrarySnapshot(),
          formatVersion: version,
        );
        expect(plan.listenedFromPositions, isFalse, reason: 'version $version');
      }
    });

    test('is taken as written when no version is given', () {
      final plan = planRestore(
        backup: backup,
        current: const LibrarySnapshot(),
      );
      expect(plan.listenedFromPositions, isFalse);
    });
  });

  group('matching', () {
    test('a book the library has is merged, not added a second time', () {
      final plan = planRestore(
        backup: libraryOf([
          book(sessions: [sessionAt(at(1), chapterKey: null)]),
        ]),
        current: libraryOf([book()]),
      );
      expect(plan.newBooks, isEmpty);
      expect(plan.mergedBooks.single.newSessions, hasLength(1));
    });

    test('a book matches by its source as well as its key', () {
      const other = SourceSnapshot(
        id: 2,
        key: 'other',
        name: 'Other',
        lang: 'en',
      );
      final plan = planRestore(
        backup: LibrarySnapshot(
          sources: const [other],
          books: [book(sourceId: 2)],
        ),
        current: libraryOf([book()]),
      );
      expect(plan.newSources, [other]);
      expect(plan.newBooks.single.sourceId, 2);
    });

    test(
      'a library already holding everything in the backup needs nothing',
      () {
        final plan = planRestore(backup: fullLibrary(), current: fullLibrary());
        expect(plan.isEmpty, isTrue);
      },
    );

    test('what only the library holds is left alone', () {
      final here = book(
        chapters: [
          chapter('one', positionMs: 1000),
          chapter('extra', index: 1),
        ],
        bookmarks: [bookmarkAt('extra', 5)],
        sessions: [sessionAt(at(1))],
        categories: ['Mine'],
      );
      final plan = planRestore(
        backup: libraryOf([
          book(chapters: [chapter('one')]),
        ]),
        current: libraryOf(
          [here, book(key: 'only here')],
          categories: const [CategorySnapshot(name: 'Mine', sortOrder: 0)],
        ),
      );
      expect(plan.isEmpty, isTrue);
    });

    test('a source the library has is left as it is', () {
      final plan = planRestore(
        backup: const LibrarySnapshot(
          sources: [
            SourceSnapshot(
              id: 1,
              key: 'local',
              name: 'Renamed',
              lang: 'und',
              isPinned: true,
            ),
          ],
        ),
        current: libraryOf([]),
      );
      expect(plan.isEmpty, isTrue);
    });
  });

  group("the book's progress", () {
    test(
      'newer progress in the library is kept over older progress in the backup',
      () {
        expect(
          changesNothing(
            backedUp: book(
              chapters: [chapter('one')],
              progress: progressAt('one', 5000, at(1)),
            ),
            here: book(
              chapters: [chapter('one')],
              progress: progressAt('one', 9000, at(2)),
            ),
          ),
          isTrue,
        );
      },
    );

    test(
      'newer progress in the backup replaces older progress in the library',
      () {
        final backedUp = progressAt('one', 9000, at(2));
        final merge = mergeOf(
          backedUp: book(chapters: [chapter('one')], progress: backedUp),
          here: book(
            chapters: [chapter('one')],
            progress: progressAt('one', 5000, at(1)),
          ),
        );
        expect(merge.progress, same(backedUp));
      },
    );

    test('saved at the same moment, the library keeps its own', () {
      expect(
        changesNothing(
          backedUp: book(
            chapters: [chapter('one')],
            progress: progressAt('one', 9000, at(1)),
          ),
          here: book(
            chapters: [chapter('one')],
            progress: progressAt('one', 5000, at(1).toLocal()),
          ),
        ),
        isTrue,
      );
    });

    test("a book never started here takes the backup's", () {
      final backedUp = progressAt('one', 9000, at(1));
      final merge = mergeOf(
        backedUp: book(chapters: [chapter('one')], progress: backedUp),
        here: book(chapters: [chapter('one')]),
      );
      expect(merge.progress, same(backedUp));
    });
  });

  group('a reading position', () {
    // The same rule as playback progress: the more recent side wins, and a tie keeps the library's.
    test('newer in the backup replaces older in the library', () {
      final backedUp = readingAt('one', 0.8, at(2));
      final merge = mergeOf(
        backedUp: book(
          kind: SourceKind.text,
          chapters: [chapter('one')],
          reading: backedUp,
        ),
        here: book(
          kind: SourceKind.text,
          chapters: [chapter('one')],
          reading: readingAt('one', 0.2, at(1)),
        ),
      );
      expect(merge.reading, same(backedUp));
    });

    test('newer in the library is kept', () {
      expect(
        changesNothing(
          backedUp: book(
            kind: SourceKind.text,
            chapters: [chapter('one')],
            reading: readingAt('one', 0.2, at(1)),
          ),
          here: book(
            kind: SourceKind.text,
            chapters: [chapter('one')],
            reading: readingAt('one', 0.8, at(2)),
          ),
        ),
        isTrue,
      );
    });

    test("a book never opened here takes the backup's", () {
      final backedUp = readingAt('one', 0.5, at(1));
      final merge = mergeOf(
        backedUp: book(
          kind: SourceKind.text,
          chapters: [chapter('one')],
          reading: backedUp,
        ),
        here: book(kind: SourceKind.text, chapters: [chapter('one')]),
      );
      expect(merge.reading, same(backedUp));
    });

    test('brings back the chapter it is in when the library lacks it', () {
      // A place in a chapter the source has since dropped is still the reader's place.
      final merge = mergeOf(
        backedUp: book(
          kind: SourceKind.text,
          chapters: [chapter('gone')],
          reading: readingAt('gone', 0.5, at(1)),
        ),
        here: book(kind: SourceKind.text),
      );
      expect([for (final c in merge.newChapters) c.key], ['gone']);
      expect(merge.newChapters.single.removedFromSource, isTrue);
    });

    test('makes a book carry user data', () {
      // So that a book outside the library but being read is backed up at all.
      expect(
        book(
          inLibrary: false,
          reading: readingAt('one', 0.1, at(1)),
        ).carriesUserData,
        isTrue,
      );
    });
  });

  group("a chapter's progress", () {
    test('goes to the side that saved it more recently', () {
      final merge = mergeOf(
        backedUp: book(
          chapters: [chapter('one', positionMs: 9000, updatedAt: at(2))],
        ),
        here: book(
          chapters: [chapter('one', positionMs: 5000, updatedAt: at(1))],
        ),
      );
      expect(merge.chapterProgress.single.lastPositionMs, 9000);
      expect(merge.chapterProgress.single.updatedAt, at(2));

      expect(
        changesNothing(
          backedUp: book(
            chapters: [chapter('one', positionMs: 5000, updatedAt: at(1))],
          ),
          here: book(
            chapters: [chapter('one', positionMs: 9000, updatedAt: at(2))],
          ),
        ),
        isTrue,
      );
    });

    test('is never lost to a chapter with none, however recently written', () {
      // The book was added again just now, before restoring, so its chapters are newer.
      final merge = mergeOf(
        backedUp: book(
          chapters: [
            chapter('one', listened: true, updatedAt: at(1)),
            chapter('two', index: 1, positionMs: 7000, updatedAt: at(1)),
          ],
        ),
        here: book(
          chapters: [
            chapter('one', updatedAt: at(500)),
            chapter('two', index: 1, updatedAt: at(500)),
          ],
        ),
      );
      expect(
        [
          for (final c in merge.chapterProgress)
            (c.chapterKey, c.isListened, c.lastPositionMs),
        ],
        [('one', true, 0), ('two', false, 7000)],
      );
    });

    test('in the library is not reset by a backup without any', () {
      expect(
        changesNothing(
          backedUp: book(chapters: [chapter('one', updatedAt: at(9))]),
          here: book(
            chapters: [chapter('one', listened: true, updatedAt: at(1))],
          ),
        ),
        isTrue,
      );
    });
  });

  group('chapters the library lacks', () {
    test('are restored removed from source when they carry progress, with the files they need', () {
      const file = MediaFileSnapshot(fileKey: 'old.mp3', durationMs: 1000);
      final merge = mergeOf(
        backedUp: book(
          files: const [
            file,
            MediaFileSnapshot(fileKey: 'unused.mp3'),
          ],
          chapters: [
            chapter(
              'old',
              positionMs: 400,
              segments: const [SegmentSnapshot(fileKey: 'old.mp3')],
            ),
          ],
        ),
        here: book(chapters: [chapter('new')]),
      );
      final restored = merge.newChapters.single;
      expect(restored.key, 'old');
      expect(restored.removedFromSource, isTrue);
      expect(restored.lastPositionMs, 400);
      expect(restored.segments.single.fileKey, 'old.mp3');
      expect(merge.newFiles, [file]);
    });

    test("are restored when the book's position or a bookmark is in them", () {
      final merge = mergeOf(
        backedUp: book(
          chapters: [chapter('resume'), chapter('marked', index: 1)],
          progress: progressAt('resume', 0, at(1)),
          bookmarks: [bookmarkAt('marked', 100)],
        ),
        here: book(),
      );
      expect([for (final c in merge.newChapters) c.key], ['resume', 'marked']);
    });

    test("are not restored when they carry nothing of the user's", () {
      expect(
        changesNothing(
          backedUp: book(chapters: [chapter('before a rename')]),
          here: book(chapters: [chapter('after a rename')]),
        ),
        isTrue,
      );
    });

    test('leave a listening session in one its place in history', () {
      final merge = mergeOf(
        backedUp: book(
          chapters: [chapter('gone')],
          sessions: [sessionAt(at(1), chapterKey: 'gone')],
        ),
        here: book(),
      );
      expect(merge.newChapters, isEmpty);
      expect(merge.newSessions.single.chapterKey, isNull);
      expect(merge.newSessions.single.startedAt, at(1));
    });
  });

  group('details', () {
    test('stay as the library has them', () {
      expect(
        changesNothing(
          backedUp: book(
            details: BookDetailsSnapshot(title: 'Old', description: 'Old.'),
          ),
          here: book(details: BookDetailsSnapshot(title: 'A Book')),
        ),
        isTrue,
      );
    });

    test('a field edited in the backup but not here is carried over, still marked edited', () {
      final merge = mergeOf(
        backedUp: book(
          details: BookDetailsSnapshot(
            title: 'My Title',
            description: 'From the source, then.',
          ),
          userOverrides: const {BookField.title},
        ),
        here: book(
          details: BookDetailsSnapshot(
            title: 'A Book',
            description: 'From the source, now.',
          ),
        ),
      );
      final edits = merge.edits!;
      expect(edits.details.title, 'My Title');
      expect(edits.details.description, 'From the source, now.');
      expect(edits.userOverrides, {BookField.title});
      expect(merge.changesBook, isTrue);
    });

    test("where both sides edited a field, the library's edit wins", () {
      final merge = mergeOf(
        backedUp: book(
          details: BookDetailsSnapshot(
            title: 'Backed-up Title',
            subtitle: 'Backed-up Subtitle',
          ),
          userOverrides: const {BookField.title, BookField.subtitle},
        ),
        here: book(
          details: BookDetailsSnapshot(title: 'My Title'),
          userOverrides: const {BookField.title},
        ),
      );
      final edits = merge.edits!;
      expect(edits.details.title, 'My Title');
      expect(edits.details.subtitle, 'Backed-up Subtitle');
      expect(edits.userOverrides, {BookField.title, BookField.subtitle});
    });
  });

  group('the library', () {
    test(
      'a restore puts a book back in the library, dated as it was added',
      () {
        final merge = mergeOf(
          backedUp: book(dateAdded: at(3)),
          here: book(inLibrary: false),
        );
        expect(merge.addToLibrary, isTrue);
        expect(merge.dateAdded, at(3));
        expect(merge.changesBook, isTrue);
      },
    );

    test('a restore never takes a book out of the library', () {
      expect(
        changesNothing(backedUp: book(inLibrary: false), here: book()),
        isTrue,
      );
    });

    test(
      "a remembered speed stays, and a book without one takes the backup's",
      () {
        expect(
          changesNothing(backedUp: book(speed: 1.5), here: book(speed: 1.25)),
          isTrue,
        );
        expect(
          mergeOf(backedUp: book(speed: 1.5), here: book()).playbackSpeed,
          1.5,
        );
      },
    );
  });

  group('categories', () {
    test("new ones go after the library's own, in the backup's order", () {
      final plan = planRestore(
        backup: libraryOf(
          [],
          categories: const [
            CategorySnapshot(name: 'Later', sortOrder: 9, flags: 1),
            CategorySnapshot(name: 'Mine', sortOrder: 0),
            CategorySnapshot(name: 'Sooner', sortOrder: 2),
          ],
        ),
        current: libraryOf(
          [],
          categories: const [
            CategorySnapshot(name: 'Mine', sortOrder: 4),
            CategorySnapshot(name: 'Also mine', sortOrder: 5),
          ],
        ),
      );
      expect(
        [for (final c in plan.newCategories) (c.name, c.sortOrder, c.flags)],
        [('Sooner', 6, 0), ('Later', 7, 1)],
      );
    });

    test('one of the same name is the same category, and memberships are only added', () {
      final merge = mergeOf(
        backedUp: book(categories: ['Mine', 'Next up']),
        here: book(categories: ['Mine', 'Other']),
      );
      expect(merge.newCategories, ['Next up']);
    });
  });

  group('bookmarks and listening sessions', () {
    test('already in the library are not added again', () {
      expect(
        changesNothing(
          backedUp: book(
            chapters: [chapter('one')],
            bookmarks: [bookmarkAt('one', 100)],
            sessions: [sessionAt(at(1))],
          ),
          here: book(
            chapters: [chapter('one')],
            bookmarks: [
              BookmarkSnapshot(
                chapterKey: 'one',
                positionMs: 100,
                createdAt: t0.toLocal(),
                note: 'Written since',
              ),
            ],
            sessions: [sessionAt(at(1).toLocal())],
          ),
        ),
        isTrue,
      );
    });

    test('are added when new', () {
      final merge = mergeOf(
        backedUp: book(
          chapters: [chapter('one')],
          bookmarks: [bookmarkAt('one', 100), bookmarkAt('one', 200)],
          sessions: [
            sessionAt(at(1)),
            sessionAt(at(1), deviceId: 'phone'),
          ],
        ),
        here: book(
          chapters: [chapter('one')],
          bookmarks: [bookmarkAt('one', 100)],
          sessions: [sessionAt(at(1))],
        ),
      );
      expect([for (final m in merge.newBookmarks) m.positionMs], [200]);
      expect([for (final s in merge.newSessions) s.deviceId], ['phone']);
    });
  });
}
