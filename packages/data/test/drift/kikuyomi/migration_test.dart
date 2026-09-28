// Every schema change ships with a migration and a migration test (CLAUDE.md).
//
// Started from the test `dart run drift_dev make-migrations` writes, and then changed in two ways.
// It runs under `package:test`, because this package is pure Dart and has no flutter_test. And its
// data-integrity test carries real rows rather than the generated template's empty lists, which pass
// whatever the migration does to a library.
//
// The schema of each version comes from the snapshots in `drift_schemas/`, so these tests check the
// migration against what that version really was, not against what today's tables say it was.

import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:kikuyomi_data/kikuyomi_data.dart';
import 'package:kikuyomi_domain/kikuyomi_domain.dart';
import 'package:kikuyomi_source_api/kikuyomi_source_api.dart' show SourceKind;
import 'package:test/test.dart';

import 'generated/schema.dart';
import 'generated/schema_v1.dart' as v1;
import 'generated/schema_v2.dart' as v2;
import 'generated/schema_v4.dart' as v4;
import 'generated/schema_v5.dart' as v5;
import 'generated/schema_v6.dart' as v6;

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;

  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));

  group('every upgrade reaches the schema it claims', () {
    // A database at each version, migrated to each later one, and the result compared against that
    // version's snapshot. This is what catches a migration that forgot a table, a column or an
    // index.
    const versions = GeneratedHelper.versions;
    for (final (i, from) in versions.indexed) {
      group('from $from', () {
        for (final to in versions.skip(i + 1)) {
          test('to $to', () async {
            final schema = await verifier.schemaAt(from);
            final db = KikuyomiDatabase(schema.newConnection());
            await verifier.migrateAndValidate(db, to);
            await db.close();
          });
        }
      });
    }
  });

  test('upgrading to version 2 keeps the library it found', () async {
    // Version 2 adds tables and touches nothing else, so what a version-1 library holds must come
    // through it untouched: the source a book came from, the book, its chapter, and the progress in
    // it. The rows are compared field by field, so a migration that rewrote a column would fail here
    // even though the schema itself still validated.
    final source = v1.SourcesData(
      id: 7,
      extensionId: 'org.example.librivox',
      key: 'librivox',
      name: 'LibriVox',
      lang: 'en',
      isEnabled: 1,
      isPinned: 0,
    );
    final book = v1.BooksData(
      id: 1,
      sourceId: 7,
      key: 'a-book',
      title: 'A Book',
      genres: '["Fiction"]',
      inLibrary: 1,
      detailsFetched: 1,
      userOverrides: '[]',
      createdAt: _at,
      updatedAt: _at,
    );
    final chapter = v1.ChaptersData(
      id: 1,
      bookId: 1,
      key: 'ch-1',
      title: 'Chapter 1',
      sourceIndex: 0,
      durationMs: 600000,
      isListened: 0,
      lastPositionMs: 42000,
      removedFromSource: 0,
      createdAt: _at,
      updatedAt: _at,
    );
    final progress = v1.PlaybackStatesData(
      bookId: 1,
      chapterId: 1,
      chapterPositionMs: 42000,
      globalPositionMs: 42000,
      updatedAt: _at,
      deviceId: 'a-device',
    );

    await verifier.testWithDataIntegrity(
      oldVersion: 1,
      newVersion: 2,
      createOld: v1.DatabaseAtV1.new,
      createNew: v2.DatabaseAtV2.new,
      openTestedDatabase: KikuyomiDatabase.new,
      createItems: (batch, db) {
        batch.insert(db.sources, source);
        batch.insert(db.books, book);
        batch.insert(db.chapters, chapter);
        batch.insert(db.playbackStates, progress);
      },
      validateItems: (db) async {
        expect(await db.select(db.sources).get(), [
          v2.SourcesData(
            id: source.id,
            extensionId: source.extensionId,
            key: source.key,
            name: source.name,
            lang: source.lang,
            isEnabled: source.isEnabled,
            isPinned: source.isPinned,
          ),
        ]);
        final migrated = await db.select(db.books).getSingle();
        expect(migrated.title, book.title);
        expect(migrated.key, book.key);
        expect(migrated.inLibrary, 1);
        expect(migrated.genres, '["Fiction"]');
        // The snapshot classes hold each column as SQLite holds it, so a timestamp is compared as the
        // text drift writes (build.yaml stores them as text, to keep the milliseconds).
        expect(migrated.createdAt, _at);
        final migratedChapter = await db.select(db.chapters).getSingle();
        expect(migratedChapter.title, chapter.title);
        expect(migratedChapter.lastPositionMs, 42000);
        expect(
          await db.select(db.playbackStates).getSingle(),
          v2.PlaybackStatesData(
            bookId: progress.bookId,
            chapterId: progress.chapterId,
            chapterPositionMs: progress.chapterPositionMs,
            globalPositionMs: progress.globalPositionMs,
            updatedAt: progress.updatedAt,
            deviceId: progress.deviceId,
          ),
        );
      },
    );
  });

  test('an upgraded library can install an extension', () async {
    // The tables are not only there but usable, with the connection's foreign keys on and the
    // enum-backed columns reading back: a `beforeOpen` that ran before the upgrade, or a text column
    // the converter cannot read, would only show up here.
    final schema = await verifier.schemaAt(1);
    final db = KikuyomiDatabase(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 2);

    await db
        .into(db.extensions)
        .insert(
          ExtensionsCompanion.insert(
            id: 'org.example.librivox',
            name: 'LibriVox',
            version: '1.4.0',
            versionCode: 14,
            apiVersion: '1.0',
            status: ExtensionStatus.untrusted,
            origin: ExtensionOrigin.folder,
            originHandle: const Value(r'G:\extensions\librivox'),
            originName: const Value(r'G:\extensions\librivox'),
            installPath: const Value('org.example.librivox/14'),
            installedAt: _when,
          ),
        );
    await db
        .into(db.extensionPreferences)
        .insert(
          ExtensionPreferencesCompanion.insert(
            extensionId: 'org.example.librivox',
            key: 'catalogue',
            value: 'audiobooks',
          ),
        );

    final row = await db.select(db.extensions).getSingle();
    expect(row.status, ExtensionStatus.untrusted);
    expect(row.origin, ExtensionOrigin.folder);
    expect(row.installPath, 'org.example.librivox/14');
    expect(
      (await db.select(db.extensionPreferences).getSingle()).value,
      'audiobooks',
    );
  });

  test('an upgraded library can queue a download', () async {
    // The same check one version on: the table is there, its enum-backed columns read back, its
    // foreign key holds, and — the one that matters — a file cannot be queued twice. §5.2 makes a
    // task per physical file so a thirty-chapter M4B is fetched once, and the unique key is what
    // enforces that rather than whoever writes the next enqueue path.
    final schema = await verifier.schemaAt(1);
    final db = KikuyomiDatabase(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 3);

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
    final book = await db
        .into(db.books)
        .insert(
          BooksCompanion.insert(
            sourceId: 7,
            key: 'a-book',
            title: 'A Book',
            createdAt: _when,
            updatedAt: _when,
          ),
        );
    final file = await db
        .into(db.mediaFiles)
        .insert(MediaFilesCompanion.insert(bookId: book, fileKey: 'whole.m4b'));

    await db
        .into(db.downloadTasks)
        .insert(
          DownloadTasksCompanion.insert(
            mediaFileId: file,
            state: DownloadState.waiting,
            hold: const Value(DownloadHold.network),
            requestSnapshot: const Value(
              DownloadRequest(
                url: 'https://archive.org/download/a-book/whole.m4b',
                headers: {'referer': 'https://archive.org/'},
              ),
            ),
            createdAt: _when,
            updatedAt: _when,
          ),
        );

    final task = await db.select(db.downloadTasks).getSingle();
    expect(task.state, DownloadState.waiting);
    expect(task.hold, DownloadHold.network);
    expect(task.attempts, 0, reason: 'a fresh task has failed nothing');
    expect(task.bytesDone, 0);
    expect(task.requestSnapshot?.headers['referer'], 'https://archive.org/');

    await expectLater(
      db
          .into(db.downloadTasks)
          .insert(
            DownloadTasksCompanion.insert(
              mediaFileId: file,
              state: DownloadState.queued,
              createdAt: _when,
              updatedAt: _when,
            ),
          ),
      throwsA(
        predicate(
          (Object? e) => e.toString().contains('UNIQUE constraint failed'),
          'a file already queued cannot be queued again',
        ),
      ),
    );
  });

  test('an upgraded library can add a repository', () async {
    // Version 4's whole content. Nothing an earlier version wrote moves into it: until now the only
    // door was a folder (ADR-0017), so a library upgrading from any version has no repositories.
    //
    // The property worth pinning is the unique key on the URL. `RepositoryLocation` normalises what
    // the listener typed, so a project page and a raw index resolve to one address — and this is
    // what makes that one row rather than a matter of whoever writes the next add path.
    final schema = await verifier.schemaAt(1);
    final db = KikuyomiDatabase(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 4);

    await db
        .into(db.repositories)
        .insert(
          RepositoriesCompanion.insert(
            url: 'https://example.org/repo/',
            name: 'Kikuyomi official',
            publicKey: 'aGVsbG8gdGhlcmUgZnJpZW5kIG9mIG1pbmUh',
            fingerprint: 'AA:BB:CC',
          ),
        );

    final stored = await db.select(db.repositories).getSingle();
    expect(stored.name, 'Kikuyomi official');
    // `null` rather than the matcher: drift exports an `isNull` of its own for queries, and this
    // file imports both.
    expect(stored.etag, null, reason: 'nothing has been fetched from it yet');
    expect(stored.lastFetchedAt, null);

    await expectLater(
      db
          .into(db.repositories)
          .insert(
            RepositoriesCompanion.insert(
              url: 'https://example.org/repo/',
              name: 'The same place twice',
              publicKey: 'b3RoZXI=',
              fingerprint: 'DD:EE:FF',
            ),
          ),
      throwsA(anything),
      reason: 'one address is one repository',
    );
  });

  test('upgrading to version 5 leaves every book an audiobook', () async {
    // Version 5 adds `book.kind` with a default of audio, which is what every book written before it
    // is. The column must arrive filled in without the migration writing a single row, and nothing
    // else about the book may move. Carried through with real values in every column a listener
    // would notice.
    final source = v4.SourcesData(
      id: 7,
      extensionId: 'org.example.librivox',
      key: 'librivox',
      name: 'LibriVox',
      lang: 'en',
      isEnabled: 1,
      isPinned: 0,
    );
    final book = v4.BooksData(
      id: 1,
      sourceId: 7,
      key: 'a-book',
      title: 'A Book',
      genres: '["Fiction"]',
      inLibrary: 1,
      detailsFetched: 1,
      userOverrides: '[]',
      playbackSpeed: 1.25,
      createdAt: _at,
      updatedAt: _at,
    );

    await verifier.testWithDataIntegrity(
      oldVersion: 4,
      newVersion: 5,
      createOld: v4.DatabaseAtV4.new,
      createNew: v5.DatabaseAtV5.new,
      openTestedDatabase: KikuyomiDatabase.new,
      createItems: (batch, db) {
        batch.insert(db.sources, source);
        batch.insert(db.books, book);
      },
      validateItems: (db) async {
        final migrated = await db.select(db.books).getSingle();
        expect(migrated.kind, 'audio');
        expect(migrated.title, book.title);
        expect(migrated.playbackSpeed, 1.25);
        expect(migrated.inLibrary, 1);
        expect(migrated.createdAt, _at);
        expect(
          await db.select(db.readingStates).get(),
          isEmpty,
          reason: 'nobody has read anything yet',
        );
      },
    );
  });

  test(
    'upgrading to version 6 leaves a chapter uncounted, not empty',
    () async {
      // Version 6 adds `chapter.word_count`, which nothing can know for a chapter already in the
      // library: an EPUB's chapters are counted as the book is added, and a chapter from a source
      // when its text is fetched. So it arrives null, and the chapter is otherwise untouched.
      final source = v5.SourcesData(
        id: 7,
        key: 'novels',
        name: 'Novels',
        lang: 'en',
        isEnabled: 1,
        isPinned: 0,
      );
      final book = v5.BooksData(
        id: 1,
        sourceId: 7,
        key: 'a-novel',
        title: 'A Novel',
        kind: 'text',
        genres: '[]',
        inLibrary: 1,
        detailsFetched: 1,
        userOverrides: '[]',
        createdAt: _at,
        updatedAt: _at,
      );
      final chapter = v5.ChaptersData(
        id: 1,
        bookId: 1,
        key: 'chapter-1',
        title: 'Chapter One',
        sourceIndex: 0,
        isListened: 1,
        lastPositionMs: 0,
        removedFromSource: 0,
        createdAt: _at,
        updatedAt: _at,
      );

      await verifier.testWithDataIntegrity(
        oldVersion: 5,
        newVersion: 6,
        createOld: v5.DatabaseAtV5.new,
        createNew: v6.DatabaseAtV6.new,
        openTestedDatabase: KikuyomiDatabase.new,
        createItems: (batch, db) {
          batch.insert(db.sources, source);
          batch.insert(db.books, book);
          batch.insert(db.chapters, chapter);
        },
        validateItems: (db) async {
          final migrated = await db.select(db.chapters).getSingle();
          expect(migrated.wordCount, null);
          expect(migrated.title, 'Chapter One');
          expect(migrated.isListened, 1);
        },
      );
    },
  );

  test("an upgraded library can hold a reader's place", () async {
    // Version 5's other half, used for real: a book to read, a chapter, and where the reader is in
    // it, with the connection's foreign keys on.
    final schema = await verifier.schemaAt(1);
    final db = KikuyomiDatabase(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 5);

    await db
        .into(db.sources)
        .insert(
          const SourcesCompanion(
            id: Value(9),
            key: Value('novels'),
            name: Value('Novels'),
            lang: Value('en'),
          ),
        );
    final book = await db
        .into(db.books)
        .insert(
          BooksCompanion.insert(
            sourceId: 9,
            key: 'a-novel',
            title: 'A Novel',
            kind: const Value(SourceKind.text),
            createdAt: _when,
            updatedAt: _when,
          ),
        );
    final chapter = await db
        .into(db.chapters)
        .insert(
          ChaptersCompanion.insert(
            bookId: book,
            key: 'c1',
            title: 'Chapter 1',
            sourceIndex: 0,
            createdAt: _when,
            updatedAt: _when,
          ),
        );
    await db
        .into(db.readingStates)
        .insert(
          ReadingStatesCompanion.insert(
            bookId: Value(book),
            chapterId: chapter,
            progress: 0.4,
            updatedAt: _when,
          ),
        );

    final stored = await db.select(db.readingStates).getSingle();
    expect(stored.progress, 0.4);
    expect((await db.select(db.books).getSingle()).kind, SourceKind.text);

    await expectLater(
      (db.delete(db.chapters)..where((c) => c.id.equals(chapter))).go(),
      throwsA(anything),
      reason: "a chapter holding a reader's place is not deleted from under it",
    );

    await (db.delete(db.books)..where((b) => b.id.equals(book))).go();
    expect(
      await db.select(db.readingStates).get(),
      isEmpty,
      reason: 'the place goes with the book',
    );
  });
}

final _when = DateTime.utc(2026, 9, 13, 12, 30, 45, 123);

/// [_when] as a version-1 row holds it: the snapshot row classes are generated from the schema
/// alone, so every column is the SQLite type it really is, and a timestamp is the text drift writes.
final _at = _when.toIso8601String();
