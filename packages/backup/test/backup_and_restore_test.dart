import 'dart:io';

import 'package:kikuyomi_backup/kikuyomi_backup.dart';
import 'package:kikuyomi_domain/kikuyomi_domain.dart';
import 'package:kikuyomi_test_support/kikuyomi_test_support.dart';
import 'package:test/test.dart';

import 'fixtures.dart';
import 'in_memory_library.dart';

const catalog = SourceSnapshot(
  id: 1,
  key: 'catalog',
  name: 'A Catalog',
  lang: 'en',
);

const browsed = SourceSnapshot(
  id: 2,
  key: 'browsed',
  name: 'Browsed',
  lang: 'en',
);

BookSnapshot stored(
  String key, {
  int sourceId = 1,
  bool inLibrary = false,
  bool started = false,
  List<String> categories = const [],
}) => BookSnapshot(
  sourceId: sourceId,
  key: key,
  details: BookDetailsSnapshot(title: key),
  createdAt: t0,
  updatedAt: t0,
  inLibrary: inLibrary,
  chapters: [
    ChapterSnapshot(
      key: 'one',
      title: 'One',
      sourceIndex: 0,
      createdAt: t0,
      updatedAt: t0,
    ),
  ],
  progress: started
      ? ProgressSnapshot(
          chapterKey: 'one',
          chapterPositionMs: 1000,
          globalPositionMs: 1000,
          updatedAt: t0,
          deviceId: 'this-pc',
        )
      : null,
  categories: categories,
);

/// A backup file of [library], always stamped with the same time, so that two backups of one library
/// are byte for byte the same.
Future<List<int>> backUp(LibrarySnapshotReader library) => createBackup(
  library,
  clock: FakeClock(at(100)),
  appVersion: '1.2.3',
  deviceId: 'phone',
);

/// [book], listened to further: chapter "one" at [positionMs], saved at [savedAt].
BookSnapshot playedOn(
  BookSnapshot book, {
  required int positionMs,
  required DateTime savedAt,
}) => BookSnapshot(
  sourceId: book.sourceId,
  key: book.key,
  details: book.details,
  userOverrides: book.userOverrides,
  contributors: book.contributors,
  inLibrary: book.inLibrary,
  dateAdded: book.dateAdded,
  lastRefreshedAt: book.lastRefreshedAt,
  detailsFetched: book.detailsFetched,
  playbackSpeed: book.playbackSpeed,
  kind: book.kind,
  createdAt: book.createdAt,
  updatedAt: book.updatedAt,
  mediaFiles: book.mediaFiles,
  chapters: [
    for (final chapter in book.chapters)
      chapter.key == 'one'
          ? withProgress(
              chapter,
              isListened: chapter.isListened,
              listenedAt: chapter.listenedAt,
              lastPositionMs: positionMs,
              updatedAt: savedAt,
            )
          : chapter,
  ],
  progress: ProgressSnapshot(
    chapterKey: 'one',
    chapterPositionMs: positionMs,
    globalPositionMs: positionMs,
    updatedAt: savedAt,
    deviceId: 'this-pc',
  ),
  reading: book.reading,
  readingSessions: book.readingSessions,
  sessions: book.sessions,
  bookmarks: book.bookmarks,
  categories: book.categories,
);

LibrarySnapshot withBooks(LibrarySnapshot library, List<BookSnapshot> books) =>
    LibrarySnapshot(
      sources: library.sources,
      categories: library.categories,
      books: books,
    );

/// The book of [fullLibrary], as a device that has it but never listened to it holds it.
BookSnapshot unplayed({bool inLibrary = false, required DateTime at}) =>
    BookSnapshot(
      sourceId: catalogSourceId,
      key: '/books/a-book',
      details: BookDetailsSnapshot(title: 'A Book'),
      inLibrary: inLibrary,
      createdAt: at,
      updatedAt: at,
      chapters: [
        ChapterSnapshot(
          key: 'one',
          title: 'Chapter One',
          sourceIndex: 1,
          createdAt: at,
          updatedAt: at,
        ),
      ],
    );

void main() {
  group('a backup keeps', () {
    LibrarySnapshot selected() => selectForBackup(
      LibrarySnapshot(
        sources: const [catalog, browsed],
        categories: const [
          CategorySnapshot(name: 'Empty', sortOrder: 0),
          CategorySnapshot(name: 'Next up', sortOrder: 1),
          CategorySnapshot(name: 'Next up', sortOrder: 2),
        ],
        books: [
          stored('in the library', inLibrary: true),
          stored('started, never added', started: true),
          stored('filed, never added', categories: ['Next up']),
          stored('browsed past', sourceId: 2),
        ],
      ),
    );

    test('books in the library, and books outside it that carry user data', () {
      expect(
        [for (final book in selected().books) book.key],
        ['in the library', 'started, never added', 'filed, never added'],
      );
    });

    test('only the sources those books refer to', () {
      expect(selected().sources, [catalog]);
    });

    test('every category, empty ones included, once per name', () {
      expect(
        [for (final c in selected().categories) (c.name, c.sortOrder)],
        [('Empty', 0), ('Next up', 1)],
      );
    });
  });

  test('a backup holds the library, stamped with when and by whom', () async {
    final backup = decodeBackup(await backUp(InMemoryLibrary(fullLibrary())));
    expect(backup.info.createdAt, at(100));
    expect(backup.info.appVersion, '1.2.3');
    expect(backup.info.deviceId, 'phone');
    expect(backup.library.books.single.key, '/books/a-book');
  });

  group('restoring a backup file', () {
    test(
      'plans against the library the writer reads, and reports what it did',
      () async {
        final library = InMemoryLibrary();
        final report = await restoreBackup(
          encodeBackup(fullLibrary(), info: info),
          library: library,
        );

        expect(library.applied.single, same(report.plan));
        expect(report.plan.newBooks.single.key, '/books/a-book');
        expect(report.backup.info.deviceId, 'this-pc');
        expect(report.backup.skipped, isEmpty);
      },
    );

    test(
      'into an empty library brings back everything the backup kept',
      () async {
        final original = InMemoryLibrary(fullLibrary());
        final restored = InMemoryLibrary();

        final report = await restoreBackup(
          await backUp(original),
          library: restored,
        );
        expect(report.backup.skipped, isEmpty);

        // Backing the restored library up again gives the very same file, so nothing was lost or
        // changed on the way through.
        expect(await backUp(restored), await backUp(original));
      },
    );

    test('written before listened state was recorded, asks for it to be worked out from positions', () async {
      final file = await backUp(InMemoryLibrary(fullLibrary()));
      // Protobuf keeps the last value it reads for a field, so appending format_version (field 1,
      // a varint) holding 1 makes the file one that a build before version 2 wrote.
      final old = gzip.encode([...gzip.decode(file), 0x08, 0x01]);
      final library = InMemoryLibrary();

      final report = await restoreBackup(old, library: library);

      expect(report.backup.formatVersion, 1);
      expect(library.applied.single.listenedFromPositions, isTrue);
    });

    test('this build wrote, restores listened state as written', () async {
      final library = InMemoryLibrary();
      await restoreBackup(
        await backUp(InMemoryLibrary(fullLibrary())),
        library: library,
      );
      expect(library.applied.single.listenedFromPositions, isFalse);
    });

    test('a second time changes nothing', () async {
      final file = await backUp(InMemoryLibrary(fullLibrary()));
      final restored = InMemoryLibrary();
      await restoreBackup(file, library: restored);

      final again = await restoreBackup(file, library: restored);
      expect(again.plan.isEmpty, isTrue);
    });

    test(
      'into a library in use merges into its books and duplicates nothing',
      () async {
        // This device holds the same book, out of the library and never played, a category of the same
        // name as the backup's, and a book of its own.
        final here = InMemoryLibrary(
          LibrarySnapshot(
            sources: fullLibrary().sources,
            categories: const [
              CategorySnapshot(name: 'Mine', sortOrder: 0),
              CategorySnapshot(name: 'Next up', sortOrder: 1),
            ],
            books: [
              unplayed(at: at(500)),
              BookSnapshot(
                sourceId: catalogSourceId,
                key: 'mine',
                details: BookDetailsSnapshot(title: 'My Own Book'),
                inLibrary: true,
                createdAt: at(500),
                updatedAt: at(500),
              ),
            ],
          ),
        );

        final report = await restoreBackup(
          await backUp(InMemoryLibrary(fullLibrary())),
          library: here,
        );
        expect(report.plan.newBooks, isEmpty);
        expect(report.plan.newSources, isEmpty);
        expect(report.plan.newCategories, isEmpty);

        final books = here.snapshot.books;
        expect([for (final b in books) b.key], ['/books/a-book', 'mine']);
        final book = books.first;
        expect(book.inLibrary, isTrue);
        expect(book.playbackSpeed, 1.25);
        expect(book.progress!.chapterPositionMs, 12345);
        expect(book.chapters.single.lastPositionMs, 12345);
        expect(book.bookmarks, hasLength(1));
        expect(book.sessions, hasLength(1));
        expect(book.categories, ['Next up']);
        expect(
          [for (final c in here.snapshot.categories) (c.name, c.sortOrder)],
          [('Mine', 0), ('Next up', 1)],
        );
      },
    );

    test(
      'keeps newer progress here over older progress in the backup',
      () async {
        final file = await backUp(InMemoryLibrary(fullLibrary()));
        final restored = InMemoryLibrary();
        await restoreBackup(file, library: restored);

        // Listening goes on here after the backup was taken.
        restored.snapshot = withBooks(restored.snapshot, [
          playedOn(
            restored.snapshot.books.single,
            positionMs: 99000,
            savedAt: at(900),
          ),
        ]);

        final again = await restoreBackup(file, library: restored);
        expect(again.plan.isEmpty, isTrue);
        final book = restored.snapshot.books.single;
        expect(book.progress!.chapterPositionMs, 99000);
        expect(book.chapters.single.lastPositionMs, 99000);
      },
    );

    test(
      'takes newer progress from the backup over older progress here',
      () async {
        final original = InMemoryLibrary(fullLibrary());
        final restored = InMemoryLibrary();
        await restoreBackup(await backUp(original), library: restored);

        // Listening goes on on the original device, which backs up again.
        original.snapshot = withBooks(original.snapshot, [
          playedOn(
            original.snapshot.books.single,
            positionMs: 99000,
            savedAt: at(900),
          ),
        ]);
        await restoreBackup(await backUp(original), library: restored);

        final book = restored.snapshot.books.single;
        expect(book.progress!.chapterPositionMs, 99000);
        expect(book.chapters.single.lastPositionMs, 99000);
      },
    );

    test(
      'gives a book added again before restoring its progress back',
      () async {
        final file = await backUp(InMemoryLibrary(fullLibrary()));
        // After a reinstall the book was added again first, so its chapter is newer than the backup's
        // and has nothing listened.
        final here = InMemoryLibrary(
          LibrarySnapshot(
            sources: fullLibrary().sources,
            books: [unplayed(inLibrary: true, at: at(1000))],
          ),
        );

        await restoreBackup(file, library: here);
        final book = here.snapshot.books.single;
        expect(book.progress!.chapterPositionMs, 12345);
        expect(book.chapters.single.lastPositionMs, 12345);
        expect(book.chapters.single.isListened, isTrue);
      },
    );
  });

  group('a file that cannot be restored from leaves the library untouched', () {
    test('when cut short or damaged', () async {
      final library = InMemoryLibrary(minimalLibrary());
      final before = library.snapshot;
      final file = await backUp(InMemoryLibrary(fullLibrary()));

      await expectLater(
        restoreBackup(file.sublist(0, file.length ~/ 2), library: library),
        throwsA(isA<CorruptBackupException>()),
      );
      final damaged = [...file]..[file.length ~/ 2] ^= 0xff;
      await expectLater(
        restoreBackup(damaged, library: library),
        throwsA(isA<CorruptBackupException>()),
      );
      expect(library.applied, isEmpty);
      expect(library.snapshot, same(before));
    });

    test(
      'when from a newer format this build cannot restore, saying so',
      () async {
        final library = InMemoryLibrary();
        final file = await backUp(InMemoryLibrary(fullLibrary()));
        // Protobuf keeps the last value it reads for a field, so appending min_reader_version (field 2,
        // a varint) makes the backup demand a newer reader than this build.
        final future = gzip.encode([
          ...gzip.decode(file),
          0x10,
          backupFormatVersion + 1,
        ]);

        await expectLater(
          restoreBackup(future, library: library),
          throwsA(
            isA<UnsupportedBackupVersionException>().having(
              (e) => e.message,
              'message',
              contains('format version ${backupFormatVersion + 1}'),
            ),
          ),
        );
        expect(library.applied, isEmpty);
      },
    );
  });
}
