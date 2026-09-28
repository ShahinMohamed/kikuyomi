import 'package:drift/drift.dart';

import '../database/database.dart';

/// The tables a backup carries: every one `DriftBackupStore` reads into a library snapshot.
///
/// A new table is either added here, when the backup format carries it, or left out on purpose, as
/// §5.2's download queue will be. The test that compares this with the schema fails until one or the
/// other is decided, and names the tables left out.
List<TableInfo<Table, Object?>> backedUpTables(KikuyomiDatabase db) => [
  db.sources,
  db.books,
  db.people,
  db.bookPeople,
  db.chapters,
  db.mediaFiles,
  db.chapterSegments,
  db.playbackStates,
  db.readingStates,
  db.listeningSessions,
  db.readingSessions,
  db.bookmarks,
  db.categories,
  db.bookCategories,
];

/// The tables a backup leaves out on purpose, and why.
///
/// A backup is the listener's library (ADR-0008), and restoring one must not depend on anything a
/// restore cannot put back:
///
/// - `extensions` is what is installed *on this device*. A backup carries no extension code, and the
///   folder a folder-installed extension came from means nothing on the device being restored to.
///   Naming the extensions a restored library wants is worth doing — it is how a restore can offer to
///   install them again — but that needs somewhere to install them from, so it waits for the
///   repository door and a backup format version of its own.
/// - `extension_preferences` is one extension's own storage, keyed by an extension that may not be
///   installed. It follows the extensions.
/// - `download_tasks` is what this device has fetched or is fetching. A backup carries no audio, so
///   restoring a queue would describe files that are not there, and a phone restored from a laptop's
///   backup would start downloading a library it was never asked to hold. What a listener wants
///   downloaded is worth keeping one day, and that is a decision about the backup format rather than
///   a row to copy.
const backupLeavesOut = [
  'extensions',
  'extension_preferences',
  // For the same reason the extensions themselves are left out: which repositories a library wants
  // is worth carrying, and carrying it means restoring a list of URLs that decide what code runs on
  // the device. That belongs to a backup format version of its own, with the trust decision made
  // deliberately rather than inherited from a restore.
  'repositories',
  'download_tasks',
];

/// A signal after every committed change to what a backup carries: the library, chapters, progress,
/// listening sessions, bookmarks and categories.
///
/// What the backup scheduler listens to, to know that a backup is due. A signal carries nothing,
/// because the scheduler only needs to know that something changed; the backup reads the library
/// afresh. Progress saves arrive every few seconds during playback, and the scheduler, not this, is
/// what keeps them from causing a backup each.
Stream<void> backedUpChanges(KikuyomiDatabase db) => db
    .tableUpdates(TableUpdateQuery.onAllTables(backedUpTables(db)))
    .map((_) {});
