// What a book's details screen says beside each chapter (§5.2).
//
// The arithmetic is the whole of it, and it is not obvious, because the queue counts physical files
// and a listener counts chapters. A chapter over three files needs all three; a file under thirty
// chapters serves all thirty. Nearly every test here is about one of those two directions.

// Drift exports a query helper called isNull that collides with the matcher of the same name.
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:kikuyomi_data/kikuyomi_data.dart';
import 'package:kikuyomi_domain/kikuyomi_domain.dart';
import 'package:kikuyomi_test_support/kikuyomi_test_support.dart';
import 'package:test/test.dart';

void main() {
  late KikuyomiDatabase db;
  late FakeClock clock;

  setUp(() async {
    db = KikuyomiDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    clock = FakeClock(DateTime.utc(2026, 9, 27, 9));
    await db
        .into(db.sources)
        .insert(
          const SourcesCompanion(
            id: Value(7),
            key: Value('librivox'),
            name: Value('LibriVox'),
            lang: Value('multi'),
          ),
        );
  });

  Future<int> addBook({String key = 'a-book'}) => db
      .into(db.books)
      .insert(
        BooksCompanion.insert(
          sourceId: 7,
          key: key,
          title: 'A Book',
          createdAt: clock.now(),
          updatedAt: clock.now(),
        ),
      );

  Future<int> addFile(
    int bookId, {
    required String fileKey,
    String? localPath,
  }) => db
      .into(db.mediaFiles)
      .insert(
        MediaFilesCompanion.insert(
          bookId: bookId,
          fileKey: fileKey,
          localPath: Value(localPath),
        ),
      );

  Future<int> addChapter(
    int bookId, {
    required String key,
    required List<int> files,
    int sourceIndex = 0,
  }) async {
    final chapter = await db
        .into(db.chapters)
        .insert(
          ChaptersCompanion.insert(
            bookId: bookId,
            key: key,
            title: key,
            sourceIndex: sourceIndex,
            createdAt: clock.now(),
            updatedAt: clock.now(),
          ),
        );
    for (final (ordinal, file) in files.indexed) {
      await db
          .into(db.chapterSegments)
          .insert(
            ChapterSegmentsCompanion.insert(
              chapterId: chapter,
              ordinal: ordinal,
              mediaFileId: file,
            ),
          );
    }
    return chapter;
  }

  Future<void> addTask(int fileId, DownloadState state) => db
      .into(db.downloadTasks)
      .insert(
        DownloadTasksCompanion.insert(
          mediaFileId: fileId,
          state: state,
          createdAt: clock.now(),
          updatedAt: clock.now(),
        ),
      );

  test('a chapter nobody has asked for is absent', () async {
    final book = await addBook();
    final file = await addFile(book, fileKey: 'one.mp3');
    final chapter = await addChapter(book, key: 'c1', files: [file]);

    expect(await readChapterDownloads(db, book), {
      chapter: ChapterDownload.absent,
    });
  });

  test('a chapter whose one file is here is here', () async {
    final book = await addBook();
    final file = await addFile(book, fileKey: 'one.mp3', localPath: 'one.mp3');
    final chapter = await addChapter(book, key: 'c1', files: [file]);

    expect(await readChapterDownloads(db, book), {
      chapter: ChapterDownload.here,
    });
  });

  test('a local book is here without ever being downloaded', () async {
    // Its files have a path from the moment it was imported and no `downloaded_at` at all. Reading
    // that column instead of the path would have shown every local book as missing.
    final book = await addBook(key: 'local');
    final file = await addFile(
      book,
      fileKey: 'on-disk.m4b',
      localPath: r'C:\Books\on-disk.m4b',
    );
    final chapter = await addChapter(book, key: 'c1', files: [file]);

    expect(await readChapterDownloads(db, book), {
      chapter: ChapterDownload.here,
    });
  });

  group('a chapter spanning several files', () {
    test('is not here until every one of them is', () async {
      // The one that matters. A chapter missing its last file cannot be listened to, and saying it
      // is downloaded is a lie the listener finds out about on a train.
      final book = await addBook();
      final one = await addFile(book, fileKey: 'one.mp3', localPath: 'one.mp3');
      final two = await addFile(book, fileKey: 'two.mp3');
      final chapter = await addChapter(book, key: 'c1', files: [one, two]);

      expect(await readChapterDownloads(db, book), {
        chapter: ChapterDownload.absent,
      });
    });

    test('is here once the last one arrives', () async {
      final book = await addBook();
      final one = await addFile(book, fileKey: 'one.mp3', localPath: 'one.mp3');
      final two = await addFile(book, fileKey: 'two.mp3', localPath: 'two.mp3');
      final chapter = await addChapter(book, key: 'c1', files: [one, two]);

      expect(await readChapterDownloads(db, book), {
        chapter: ChapterDownload.here,
      });
    });

    test(
      'reads as failed when one file gave up, however the rest are going',
      () async {
        // A failure outranks the files still moving: those will finish and the chapter still will not
        // play, so telling the listener it is downloading would be telling them to wait for nothing.
        final book = await addBook();
        final one = await addFile(book, fileKey: 'one.mp3');
        final two = await addFile(book, fileKey: 'two.mp3');
        final chapter = await addChapter(book, key: 'c1', files: [one, two]);
        await addTask(one, DownloadState.downloading);
        await addTask(two, DownloadState.failedPermanent);

        expect(await readChapterDownloads(db, book), {
          chapter: ChapterDownload.failed,
        });
      },
    );

    test('reads as working while one moves and the other waits', () async {
      final book = await addBook();
      final one = await addFile(book, fileKey: 'one.mp3');
      final two = await addFile(book, fileKey: 'two.mp3');
      final chapter = await addChapter(book, key: 'c1', files: [one, two]);
      await addTask(one, DownloadState.downloading);
      await addTask(two, DownloadState.queued);

      expect(await readChapterDownloads(db, book), {
        chapter: ChapterDownload.working,
      });
    });
  });

  test('chapters sharing one file are all here once it is', () async {
    // Not a rounding error: downloading one chapter of an M4B downloads its neighbours, because it
    // is the same bytes. Reporting anything else would have the listener download it thirty times.
    final book = await addBook();
    final file = await addFile(
      book,
      fileKey: 'whole.m4b',
      localPath: 'whole.m4b',
    );
    final one = await addChapter(book, key: 'c1', files: [file]);
    final two = await addChapter(
      book,
      key: 'c2',
      files: [file],
      sourceIndex: 1,
    );

    expect(await readChapterDownloads(db, book), {
      one: ChapterDownload.here,
      two: ChapterDownload.here,
    });
  });

  test('a waiting task reads as queued, not as nothing', () async {
    // §5.2 holds a resolved file back for Wi-Fi or for a slot. It has been asked for, and a row
    // showing a bare download arrow would invite the listener to ask again.
    final book = await addBook();
    final file = await addFile(book, fileKey: 'one.mp3');
    final chapter = await addChapter(book, key: 'c1', files: [file]);
    await addTask(file, DownloadState.waiting);

    expect(await readChapterDownloads(db, book), {
      chapter: ChapterDownload.queued,
    });
  });

  test('a cancelled task leaves the chapter askable again', () async {
    final book = await addBook();
    final file = await addFile(book, fileKey: 'one.mp3');
    final chapter = await addChapter(book, key: 'c1', files: [file]);
    await addTask(file, DownloadState.cancelled);

    final state = (await readChapterDownloads(db, book))[chapter];
    expect(state, ChapterDownload.absent);
    expect(state!.canBeAskedFor, isTrue);
  });

  test(
    'a task that finished before its file has a path is not here yet',
    () async {
      // §5.2's post-processor checks, probes and moves the bytes into place after the transport is
      // done. Between those two moments the task says completed and the file has no path, and a
      // chapter shown as downloaded then would fail to play.
      final book = await addBook();
      final file = await addFile(book, fileKey: 'one.mp3');
      final chapter = await addChapter(book, key: 'c1', files: [file]);
      await addTask(file, DownloadState.completed);

      expect(await readChapterDownloads(db, book), {
        chapter: ChapterDownload.absent,
      });
    },
  );

  test('a chapter with no layout yet is absent rather than missing', () async {
    // §4.4 keeps a chapter whose files are not known. "Nothing to download" and "nothing
    // downloaded" look the same to a listener, and both are honest.
    final book = await addBook();
    final chapter = await addChapter(book, key: 'c1', files: const []);

    expect(await readChapterDownloads(db, book), {
      chapter: ChapterDownload.absent,
    });
  });

  test('progress writes do not become emissions', () async {
    // A running download writes `bytes_done` many times a second. None of those moves a chapter
    // between states, and handing each one to a screen made a four-hundred-chapter book rebuild its
    // whole list several times a second.
    final book = await addBook();
    final file = await addFile(book, fileKey: 'one.mp3');
    await addChapter(book, key: 'c1', files: [file]);
    await addTask(file, DownloadState.downloading);

    var emissions = 0;
    final sub = watchChapterDownloads(db, book).listen((_) => emissions++);
    addTearDown(sub.cancel);
    await pumpEventQueue();
    expect(emissions, 1, reason: 'the first reading is worth having');

    for (var bytes = 1; bytes <= 20; bytes++) {
      await (db.update(db.downloadTasks)
            ..where((t) => t.mediaFileId.equals(file)))
          .write(DownloadTasksCompanion(bytesDone: Value(bytes * 1000)));
      await pumpEventQueue();
    }

    expect(emissions, 1, reason: 'twenty progress writes said nothing new');
  });

  test('a state that really changes is still reported', () async {
    // The other half: quietening the stream must not make it silent.
    final book = await addBook();
    final file = await addFile(book, fileKey: 'one.mp3');
    await addChapter(book, key: 'c1', files: [file]);
    await addTask(file, DownloadState.downloading);

    final seen = <Map<int, ChapterDownload>>[];
    final sub = watchChapterDownloads(db, book).listen(seen.add);
    addTearDown(sub.cancel);
    await pumpEventQueue();

    await (db.update(db.downloadTasks)
          ..where((t) => t.mediaFileId.equals(file)))
        .write(const DownloadTasksCompanion(bytesDone: Value(4096)));
    await pumpEventQueue();
    await (db.update(db.mediaFiles)..where((f) => f.id.equals(file))).write(
      const MediaFilesCompanion(localPath: Value('one.mp3')),
    );
    await pumpEventQueue();

    expect(seen.first.values.single, ChapterDownload.working);
    expect(seen.last.values.single, ChapterDownload.here);
    expect(
      seen,
      hasLength(2),
      reason: 'the byte write in between said nothing',
    );
  });

  test('it answers again when a file arrives', () async {
    final book = await addBook();
    final file = await addFile(book, fileKey: 'one.mp3');
    final chapter = await addChapter(book, key: 'c1', files: [file]);

    final seen = <ChapterDownload>[];
    final sub = watchChapterDownloads(db, book).listen((states) {
      final state = states[chapter];
      if (state != null) seen.add(state);
    });
    addTearDown(sub.cancel);

    await pumpEventQueue();
    await (db.update(db.mediaFiles)..where((f) => f.id.equals(file))).write(
      const MediaFilesCompanion(localPath: Value('one.mp3')),
    );
    await pumpEventQueue();

    expect(seen.first, ChapterDownload.absent);
    expect(seen.last, ChapterDownload.here);
  });
}
