/// The schema, following docs/architecture.md §4.3.
///
/// Version 1 holds what Phase 1 needs: sources, books and their contributors, chapters, the physical
/// file layout, progress, listening history, bookmarks and categories.
///
/// Version 2 adds what installing an extension needs: `extension`, so that what is installed
/// survives a restart, and `extension_preference`, so that what an extension stores does too.
///
/// Version 3 adds `download_task`, the queue that makes a book playable with no network (§5.2).
/// Version 4 adds `repository`, for the repository door.
///
/// Version 5 makes room for reading (ADR-0019): `book.kind`, and `reading_state`. One model with a
/// kind rather than a parallel set of tables, which is §1.2's lesson from Aniyomi taken literally.
/// Version 9 adds `book.chapters_reversed`, the order one book's chapter list is read in.
///
/// Version 8 adds `book.file_path`, for a book that is one file: an EPUB downloaded whole from a
/// source (ADR-0021), or one added from this device.
///
/// Version 7 adds `reading_session`, so that History covers reading as well as listening.
///
/// Version 6 adds `chapter.word_count`, so that a book to read can say how long a chapter is the
/// way an audiobook says it in minutes.
///
/// `smart_collection` and the `book_fts` full-text index follow in Phase 4.
///
/// Row classes are named `…Row`. §4.1 keeps database records, domain entities and extension DTOs as
/// three separate types, and the suffix keeps a record from being mistaken for an entity.
library;

import 'package:drift/drift.dart';
import 'package:kikuyomi_domain/kikuyomi_domain.dart';
import 'package:kikuyomi_source_api/kikuyomi_source_api.dart' show SourceKind;

import 'converters.dart';

/// A content source: a built-in one such as Local files, or one provided by an extension.
@DataClassName('SourceRow')
class Sources extends Table {
  /// The stable 64-bit hash §3 describes, not an autoincrement.
  IntColumn get id => integer()();

  /// Null for a built-in source.
  ///
  /// Not a foreign key to [Extensions], although that table now exists, and deliberately so. §3.9:
  /// "Uninstalling removes the code but not the user's data: library books from that source keep
  /// their metadata, progress, and downloads, and point to a stub source until the extension returns
  /// or the books are migrated." A source therefore outlives the extension it came from, and holds
  /// on to its id so that the same extension installed again is recognised as the same one. A
  /// foreign key would force the opposite: either the uninstall fails, or the link is lost, or the
  /// books go with it.
  TextColumn get extensionId => text().nullable()();
  TextColumn get key => text()();
  TextColumn get name => text()();
  TextColumn get lang => text()();
  TextColumn get contentRating => text().nullable()();
  BoolColumn get isEnabled => boolean().withDefault(const Constant(true))();
  BoolColumn get isPinned => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastUsedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('BookRow')
@TableIndex(name: 'books_library', columns: {#inLibrary, #dateAdded})
class Books extends Table {
  /// Surrogate key, used only for joins. §4.4: a book's identity is its source and key.
  IntColumn get id => integer().autoIncrement()();
  IntColumn get sourceId => integer().references(Sources, #id)();
  TextColumn get key => text()();
  TextColumn get title => text()();
  TextColumn get subtitle => text().nullable()();
  TextColumn get description => text().nullable()();
  TextColumn get coverUrl => text().nullable()();
  TextColumn get coverLocalPath => text().nullable()();
  DateTimeColumn get coverUpdatedAt => dateTime().nullable()();
  TextColumn get seriesName => text().nullable()();
  RealColumn get seriesIndex => real().nullable()();
  TextColumn get genres => text()
      .withDefault(const Constant('[]'))
      .map(const StringListConverter())();
  TextColumn get language => text().nullable()();
  TextColumn get publisher => text().nullable()();
  TextColumn get publishedDate => text().nullable()();
  TextColumn get isbn => text().nullable()();
  BoolColumn get abridged => boolean().nullable()();
  TextColumn get status => text().nullable()();
  TextColumn get contentRating => text().nullable()();
  IntColumn get totalDurationMs => integer().nullable()();
  TextColumn get webUrl => text().nullable()();
  BoolColumn get inLibrary => boolean().withDefault(const Constant(false))();
  DateTimeColumn get dateAdded => dateTime().nullable()();
  DateTimeColumn get lastRefreshedAt => dateTime().nullable()();
  BoolColumn get detailsFetched =>
      boolean().withDefault(const Constant(false))();
  TextColumn get userOverrides => text()
      .withDefault(const Constant('[]'))
      .map(const BookFieldSetConverter())();

  /// §4.3: playback speed is remembered per book.
  RealColumn get playbackSpeed => real().nullable()();

  /// Whether this book's chapter list is shown last chapter first (version 9).
  ///
  /// Per book, because it is a fact about the book rather than a preference about the app: a
  /// four-hundred-chapter serial is easiest to use from the newest end, and a novel is not.
  ///
  /// Nullable, so that "never chosen" can be told from "chosen to read in order". That is what lets
  /// a restore carry a choice over without overwriting one made since, the way a remembered playback
  /// speed does.
  BoolColumn get chaptersReversed => boolean().nullable()();

  /// When the listener took this book off Continue Listening or Continue Reading by hand
  /// (version 10).
  ///
  /// A moment rather than a flag, because taking a book off the shelf is about the book as it stood
  /// then: once it is played or read again, its activity is newer than this and it comes back on its
  /// own. A flag would need something to clear it, and forgetting to would hide a book someone is
  /// in the middle of for good.
  ///
  /// Not carried by backups. It is a tidy-up of one screen, not part of anyone's library, and a
  /// restore that brought back a book taken off the shelf would cost one long-press to undo.
  DateTimeColumn get continueHiddenAt => dateTime().nullable()();

  /// Where the book's own file is, for a book that is one file rather than chapters to fetch
  /// (version 8, ADR-0021).
  ///
  /// A name within the book-files folder for a book downloaded from a source, and an absolute path,
  /// or one relative to the media root, for a book added from this device. Null for every other
  /// book: an audiobook is made of media files, and a text source that serves chapters has no file
  /// at all.
  TextColumn get filePath => text().nullable()();

  /// A book to listen to or a book to read (version 5, ADR-0019).
  ///
  /// On the book and not taken from its source, because the Local source offers both: a folder of
  /// audio files and an EPUB are both books from this device. Every book that existed before
  /// version 5 is audio, which is what the default says, so the migration writes nothing.
  TextColumn get kind =>
      textEnum<SourceKind>().withDefault(const Constant('audio'))();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {sourceId, key},
  ];
}

/// An author or narrator. §4.3 normalises contributors because narrators matter in audiobooks:
/// users filter by them, follow them, and use them to tell editions apart.
@DataClassName('PersonRow')
class People extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Unique, so the same narrator across books is one person to filter by. Two different people
  /// sharing a name will merge; that is the accepted cost of not having an identity from sources.
  TextColumn get name => text().unique()();
}

@DataClassName('BookPersonRow')
class BookPeople extends Table {
  IntColumn get bookId =>
      integer().references(Books, #id, onDelete: KeyAction.cascade)();
  IntColumn get personId => integer().references(People, #id)();
  TextColumn get role => textEnum<ContributorRole>()();

  /// Credit order within the role.
  IntColumn get ordinal => integer()();

  @override
  Set<Column<Object>> get primaryKey => {bookId, personId, role};
}

@DataClassName('ChapterRow')
@TableIndex(name: 'chapters_order', columns: {#bookId, #sourceIndex})
class Chapters extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get bookId =>
      integer().references(Books, #id, onDelete: KeyAction.cascade)();
  TextColumn get key => text()();
  TextColumn get title => text()();
  IntColumn get sourceIndex => integer()();
  TextColumn get groupName => text().nullable()();
  IntColumn get durationMs => integer().nullable()();

  /// How many words the chapter holds, for a book to read (version 6, ADR-0019).
  ///
  /// An audiobook chapter says how long it is in minutes because its length is a fact about the
  /// recording. A chapter of text has no length in minutes of its own — it has a length in words,
  /// and how long that takes is the reader's own pace. So the words are stored and the minutes are
  /// worked out for whoever is reading.
  ///
  /// Null until it is known. A local EPUB's chapters are counted as the book is added; a chapter
  /// from a source cannot be counted until its text has been fetched, so it is counted the first
  /// time it is read. Derived from the text either way, which is why a backup does not carry it.
  IntColumn get wordCount => integer().nullable()();

  DateTimeColumn get publishedAt => dateTime().nullable()();
  BoolColumn get isListened => boolean().withDefault(const Constant(false))();
  DateTimeColumn get listenedAt => dateTime().nullable()();

  /// Chapter-relative, per §4.5.
  IntColumn get lastPositionMs => integer().withDefault(const Constant(0))();

  /// §4.4: chapters a source stops reporting are soft-deleted, never removed outright while they
  /// carry progress, bookmarks or downloads.
  BoolColumn get removedFromSource =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {bookId, key},
  ];
}

/// One physical audio file known for a book.
@DataClassName('MediaFileRow')
class MediaFiles extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get bookId =>
      integer().references(Books, #id, onDelete: KeyAction.cascade)();
  TextColumn get fileKey => text()();
  TextColumn get format => text().nullable()();
  IntColumn get durationMs => integer().nullable()();

  /// Not in §4.3's column list, but §4.5 requires it: durations are estimated until a file is
  /// probed, and the Timeline has to know which figures are which.
  BoolColumn get durationIsEstimate =>
      boolean().withDefault(const Constant(true))();
  IntColumn get sizeBytes => integer().nullable()();
  TextColumn get embeddedMarkers =>
      text().map(const MarkerListConverter()).nullable()();

  /// Where the file is, once it is on this device at all.
  ///
  /// Absolute for a file that stays where the user keeps it, and otherwise relative — to the app's
  /// downloads folder when [downloadedAt] is set, and to the media root when it is not. The two are
  /// different folders, so the pair of columns has to be read together; `LocalMediaResolver` is the
  /// one place that does it.
  TextColumn get localPath => text().nullable()();

  /// When the download queue put this file here, and nothing else ever sets it (§5.2).
  ///
  /// So it is also what says that [localPath] is relative to the downloads folder rather than to the
  /// media root. An imported file is on the device without ever having been downloaded.
  DateTimeColumn get downloadedAt => dateTime().nullable()();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {bookId, fileKey},
  ];
}

/// The persisted layout of each chapter across physical files. No URLs are stored: §4.3 treats them
/// as ephemeral, and the Timeline never needs one.
@DataClassName('ChapterSegmentRow')
class ChapterSegments extends Table {
  IntColumn get chapterId =>
      integer().references(Chapters, #id, onDelete: KeyAction.cascade)();
  IntColumn get ordinal => integer()();

  /// Deliberately not cascading: a file cannot be deleted out from under a chapter's layout.
  IntColumn get mediaFileId => integer().references(MediaFiles, #id)();
  IntColumn get startMs => integer().withDefault(const Constant(0))();

  /// Null means to the end of the file, as in the Timeline's own segments, so a whole-file segment
  /// follows its file's duration when a probe refines it and nothing has to be rewritten.
  IntColumn get endMs => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {chapterId, ordinal};
}

/// One row per started book: the source of truth for Continue Listening.
@DataClassName('PlaybackStateRow')
@TableIndex(name: 'playback_states_recent', columns: {#updatedAt})
class PlaybackStates extends Table {
  IntColumn get bookId =>
      integer().references(Books, #id, onDelete: KeyAction.cascade)();

  /// Not cascading: the database itself refuses to delete a chapter that holds a book's progress.
  IntColumn get chapterId => integer().references(Chapters, #id)();
  IntColumn get chapterPositionMs => integer()();

  /// Derived from the Timeline and cached for sorting and display. [chapterPositionMs] is the truth.
  IntColumn get globalPositionMs => integer()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get deviceId => text()();

  @override
  Set<Column<Object>> get primaryKey => {bookId};
}

/// One row per book being read: where the reader is (version 5, ADR-0019).
///
/// Its own table rather than `playback_state`'s, whose columns are shaped for audio — a global
/// position derived from a Timeline, a speed, a device's queue — and would mean nothing for half its
/// rows. The shapes are otherwise the same on purpose: one row per book, and a chapter the database
/// refuses to lose while it holds someone's place.
@DataClassName('ReadingStateRow')
@TableIndex(name: 'reading_states_recent', columns: {#updatedAt})
class ReadingStates extends Table {
  IntColumn get bookId =>
      integer().references(Books, #id, onDelete: KeyAction.cascade)();

  /// Not cascading, for `playback_state`'s reason: the database refuses to delete a chapter that holds
  /// a reader's place. A sync never deletes one anyway — a chapter a source drops is marked
  /// `removed_from_source` — so this only ever stops a mistake.
  IntColumn get chapterId => integer().references(Chapters, #id)();

  /// How far through the chapter, from 0 at its start to 1 at its end.
  ///
  /// A fraction rather than characters or pixels, because it has to survive the reader changing the
  /// font size or turning the phone round, and neither of those should move anyone's place.
  RealColumn get progress => real()();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {bookId};
}

@DataClassName('ListeningSessionRow')
@TableIndex(name: 'listening_sessions_started', columns: {#startedAt})
class ListeningSessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get bookId =>
      integer().references(Books, #id, onDelete: KeyAction.cascade)();

  /// Nullable and cleared when the chapter is purged. Listening history should outlive a chapter the
  /// source dropped; §4.4's "keep while it carries user data" rule covers progress, bookmarks and
  /// downloads, not history.
  IntColumn get chapterId => integer().nullable().references(
    Chapters,
    #id,
    onDelete: KeyAction.setNull,
  )();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime()();
  IntColumn get startGlobalMs => integer()();
  IntColumn get endGlobalMs => integer()();
  RealColumn get speed => real()();
  TextColumn get deviceId => text()();
}

/// One stretch of reading, for History (version 7, ADR-0019).
///
/// `listening_session`'s counterpart, and deliberately not the same table: half its columns are a
/// global position in milliseconds and a playback speed, which mean nothing for text. What both
/// have in common is what History shows — a book, a chapter, and when.
///
/// There is no "covered" figure. A listening session covers a stretch of a recording, which is a
/// fact; how much of a chapter was read in eleven minutes is a guess, and History is a record of
/// what happened rather than a place to guess.
@DataClassName('ReadingSessionRow')
@TableIndex(name: 'reading_sessions_started', columns: {#startedAt})
class ReadingSessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get bookId =>
      integer().references(Books, #id, onDelete: KeyAction.cascade)();

  /// Nullable and cleared when the chapter is purged, for `listening_session`'s reason: history
  /// outlives the chapters it covered.
  IntColumn get chapterId => integer().nullable().references(
    Chapters,
    #id,
    onDelete: KeyAction.setNull,
  )();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime()();
  TextColumn get deviceId => text()();
}

@DataClassName('BookmarkRow')
class Bookmarks extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get bookId =>
      integer().references(Books, #id, onDelete: KeyAction.cascade)();

  /// Not cascading, for the same reason as progress.
  IntColumn get chapterId => integer().references(Chapters, #id)();
  IntColumn get positionMs => integer()();
  TextColumn get title => text().nullable()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
}

/// A manual, many-to-many library tab, per ADR-0009.
@DataClassName('CategoryRow')
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  IntColumn get sortOrder => integer()();

  /// Per-category sort, filter and display settings, packed as §4.3 describes.
  IntColumn get flags => integer().withDefault(const Constant(0))();
}

@DataClassName('BookCategoryRow')
class BookCategories extends Table {
  IntColumn get bookId =>
      integer().references(Books, #id, onDelete: KeyAction.cascade)();
  IntColumn get categoryId =>
      integer().references(Categories, #id, onDelete: KeyAction.cascade)();

  @override
  Set<Column<Object>> get primaryKey => {bookId, categoryId};
}

/// An extension the app has installed (§4.3), or the one that ships inside it.
///
/// Version 2's reason for existing: what is installed, which version it is and where it came from
/// have to survive a restart, since after one the app has only its own storage to go on. No code is
/// here — the files live in the app's storage, at [Extensions.installPath] — and nothing here runs:
/// A repository the listener has added: where it is, who it says it is, and the key it signs with
/// (§3.8, §4.3).
///
/// **The key is pinned here, and that is the point of the row.** §3.8's trust is trust on first use:
/// the fingerprint is shown when a repository is added, the listener accepts it, and what is stored
/// is what every later fetch is checked against. A repository that comes back one day with a
/// different key has either rotated it properly, signed by the old one, or is not the repository it
/// was — and the only way to tell is to have written down what it used to be.
///
/// [etag] and [lastFetchedAt] are the cache. A listener with a dozen repositories refreshes them all
/// on the same schedule and almost nothing has changed, so the tag turns most of those refreshes
/// into a conditional request with no body at all.
@DataClassName('RepositoryRow')
class Repositories extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// The folder its documents sit in, as `RepositoryLocation` works it out — so the same repository
  /// reached by its project page and by its raw index is one row, not two.
  TextColumn get url => text()();

  /// What it calls itself, from `repo.json`.
  TextColumn get name => text()();

  /// Its Ed25519 signing key, base64, exactly as published. What signatures are checked against.
  TextColumn get publicKey => text()();

  /// The key's fingerprint, as it was shown to the listener when they accepted it.
  ///
  /// Derived from [publicKey] and stored anyway, because it is the thing a person compared against
  /// what the repository's operator published, and re-deriving it to show again would be deriving it
  /// from whatever the key is now rather than from what they agreed to.
  TextColumn get fingerprint => text()();

  /// What the index answered with last time, to send back as `If-None-Match`. Null until one is
  /// fetched, and null again if the repository stops sending one.
  TextColumn get etag => text().nullable()();

  DateTimeColumn get lastFetchedAt => dateTime().nullable()();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {url},
  ];
}

/// §3.6 starts a runtime on first use, from these rows and the manifest beside the code.
///
/// §4.3's column list also has `repository_id`, which waits for the repository door: until then
/// [Extensions.origin] is where an extension came from, and a repository will be one more kind of
/// origin rather than a second way of saying it.
@DataClassName('ExtensionRow')
class Extensions extends Table {
  /// The extension's own id, as its manifest gives it: `org.example.librivox`. Never a surrogate,
  /// because this is the id the manifest, the sources and the stored preferences all use.
  TextColumn get id => text()();

  /// What the listener sees, from the manifest. Kept here so the Extensions screen can be shown
  /// before any manifest is read again.
  TextColumn get name => text()();
  TextColumn get version => text()();

  /// What orders versions: an update is a higher number, whatever `version` says (§3.3).
  IntColumn get versionCode => integer()();
  TextColumn get apiVersion => text()();

  /// Whether it may run, and if not why (§3.8). A folder install is `untrusted`, which is this app
  /// saying that nothing proved the code is what the author published.
  TextColumn get status => textEnum<ExtensionStatus>()();

  /// Where it came from, which is also how it is read again.
  TextColumn get origin => textEnum<ExtensionOrigin>()();

  /// How to reach that origin again: the handle of the folder it was installed from, as
  /// `UserFolders.open` takes one. Null for the extension that ships inside the app.
  TextColumn get originHandle => text().nullable()();

  /// What to call the origin to the listener: a folder's path on desktop, its own name on Android.
  TextColumn get originName => text().nullable()();

  /// Where the app's copy of the files is, relative to the folder installed extensions are kept in
  /// (§3.9's versioned directory). Null for the extension that ships inside the app, whose files are
  /// assets.
  ///
  /// Relative for the reason a cover's path is relative: on iOS the app's container moves when the
  /// app is updated or reinstalled.
  TextColumn get installPath => text().nullable()();

  DateTimeColumn get installedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// One extension's stored preferences: the `storage` module of §3.5, and §4.3's
/// `extension_preference`.
///
/// Deliberately not a foreign key to [Extensions]. §3.9: "Uninstalling removes the code but not the
/// user's data." A source's login, its chosen catalogue, whatever it kept — all of that is the
/// listener's, and it is here when the extension comes back. Secrets are not: §4.3 sends those to
/// platform secure storage, and SourceAPI 1.0 says so to extension authors.
@DataClassName('ExtensionPreferenceRow')
class ExtensionPreferences extends Table {
  TextColumn get extensionId => text()();
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {extensionId, key};
}

/// One file the listener wants on the device (§5.2's queue, and §4.3's `download_task`).
///
/// The table is the source of truth for downloading, not the transport: `background_downloader`
/// delegates to WorkManager, a background `URLSession` or an in-process isolate depending on the
/// platform, and none of those survives inspection, reordering or a process kill the way a row does
/// (ADR-0007). The transport is handed work and reports back; what is *wanted* is here.
///
/// **One task per physical file, never per chapter.** A thirty-chapter M4B is one row, so it is
/// fetched once however many chapters point into it, and a chapter spanning three files is three
/// rows. That is the same model the playback engine uses for its queue, and [mediaFileId] is unique
/// to enforce it rather than leaving it to whoever writes the next enqueue path.
@DataClassName('DownloadTaskRow')
@TableIndex(name: 'download_tasks_pending', columns: {#state, #priority})
class DownloadTasks extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// The file to fetch. Cascading: a file that is no longer part of any book has nothing to download.
  IntColumn get mediaFileId =>
      integer().references(MediaFiles, #id, onDelete: KeyAction.cascade)();

  TextColumn get state => textEnum<DownloadState>()();

  /// Why a `waiting` task is waiting, and null in every other state. Kept apart from [state] so a
  /// screen can say "waiting for Wi-Fi" rather than "waiting" (§5.2).
  TextColumn get hold => textEnum<DownloadHold>().nullable()();

  /// What the scheduler picks first. Higher runs sooner; the chapter about to be played is raised
  /// above the rest of its book.
  IntColumn get priority => integer().withDefault(const Constant(0))();

  IntColumn get bytesDone => integer().withDefault(const Constant(0))();

  /// What the site said the whole file is, once it has said. Null until then, because a progress bar
  /// that guesses is worse than one that waits.
  IntColumn get bytesTotal => integer().nullable()();

  /// The resolved URL and headers, written down as the file is about to start (§5.4). Null until the
  /// first resolution, and stale after [expiresAt].
  TextColumn get requestSnapshot =>
      text().map(const DownloadRequestConverter()).nullable()();

  /// When [requestSnapshot] stops being usable, as the source said. Null when the source gave no
  /// expiry, which does not mean the URL is eternal — a 403 or a 410 sends it back to be resolved
  /// either way.
  DateTimeColumn get expiresAt => dateTime().nullable()();

  /// How many times this file has failed in a way that might not fail again (§5.5). Five ends it.
  /// A URL that merely expired does not count here: that is the source working as designed.
  IntColumn get attempts => integer().withDefault(const Constant(0))();

  /// When a `failedRetryable` task may join the queue again.
  ///
  /// Not in §4.3's column list, but the backoff has to outlive the process or a phone that was
  /// killed mid-queue would retry everything the moment it came back, which is the behaviour the
  /// jitter exists to prevent.
  DateTimeColumn get retryAt => dateTime().nullable()();

  /// What went wrong last, for the listener and for a bug report. Never the explanation on its own.
  TextColumn get lastError => text().nullable()();

  /// What the transport calls this task, so the reconciler can match its live tasks to these rows at
  /// launch and repair the drift (§5.2).
  TextColumn get transportTaskId => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {mediaFileId},
  ];
}
