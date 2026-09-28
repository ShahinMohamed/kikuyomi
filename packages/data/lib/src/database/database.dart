import 'package:drift/drift.dart';
import 'package:kikuyomi_domain/kikuyomi_domain.dart';
import 'package:kikuyomi_source_api/kikuyomi_source_api.dart' show SourceKind;

import 'converters.dart';
import 'database.steps.dart';
import 'tables.dart';

part 'database.g.dart';

/// The app's database. §2.5: the single source of truth, which screens watch rather than copy.
@DriftDatabase(
  tables: [
    Sources,
    Books,
    People,
    BookPeople,
    Chapters,
    MediaFiles,
    ChapterSegments,
    PlaybackStates,
    ReadingStates,
    ReadingSessions,
    ListeningSessions,
    Bookmarks,
    Categories,
    BookCategories,
    Repositories,
    Extensions,
    ExtensionPreferences,
    DownloadTasks,
  ],
)
class KikuyomiDatabase extends _$KikuyomiDatabase {
  /// The caller supplies the executor: a file-backed database in the app, an in-memory one in tests.
  /// Opening a file here would tie this pure-Dart package to where the app keeps its data.
  KikuyomiDatabase(super.executor);

  @override
  int get schemaVersion => 7;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    // One step per version, each written against that version's own tables rather than against
    // today's, which is drift's `stepByStep`. A migration that said `createTable(extensions)` would
    // create whatever shape that table has when the app is built, so a library upgraded from version
    // 1 two versions from now would get a version-4 table in its version-2 step. `database.steps.dart`
    // is generated from the schema snapshots by `dart run drift_dev make-migrations`.
    onUpgrade: stepByStep(
      // Version 2 only adds tables: what extensions are installed, and what they have stored.
      // Nothing that version 1 wrote is moved or rewritten.
      from1To2: (m, schema) async {
        await m.createTable(schema.extensions);
        await m.createTable(schema.extensionPreferences);
      },
      // Version 3 adds the download queue, and nothing else. A library written by any earlier
      // version has nothing to download yet, so there is nothing to move into it.
      from2To3: (m, schema) async {
        await m.createTable(schema.downloadTasks);
        await m.createIndex(schema.downloadTasksPending);
      },
      // Version 4 adds the repositories the listener has added, and nothing else. A library written
      // by any earlier version has none: until now the only door was a folder (ADR-0017), so there
      // is nothing to move into it.
      from3To4: (m, schema) async {
        await m.createTable(schema.repositories);
      },
      // Version 5 makes room for reading (ADR-0019). Every book written by an earlier version is an
      // audiobook, which is what `kind`'s default says, so adding the column rewrites nothing; and
      // nobody has read anything yet, so the new table starts empty.
      from4To5: (m, schema) async {
        await m.addColumn(schema.books, schema.books.kind);
        await m.createTable(schema.readingStates);
        await m.createIndex(schema.readingStatesRecent);
      },
      // Version 7: History covers reading too, and a stretch of reading is not a stretch of
      // listening with the audio columns left empty, so it gets a table of its own.
      from6To7: (m, schema) async {
        await m.createTable(schema.readingSessions);
        await m.createIndex(schema.readingSessionsStarted);
      },
      // Version 6: how long a chapter of a book to read is, in the only unit that means anything
      // for text. Null everywhere to begin with, and filled in as books are added and read.
      from5To6: (m, schema) async {
        await m.addColumn(schema.chapters, schema.chapters.wordCount);
      },
    ),
    beforeOpen: (details) async {
      // SQLite leaves foreign keys off unless each connection asks for them, and every cascade and
      // restriction in the schema means nothing without this.
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
