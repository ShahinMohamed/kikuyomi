/// Where each chapter of a book stands, as a row on its details screen needs to say it (§5.2).
///
/// The queue counts physical files and a listener counts chapters, and the two do not line up: a
/// thirty-chapter M4B is one file, and a chapter read over three days is three. So a chapter's
/// state is a summary of its files' states, and the summary has to be pessimistic — a chapter is
/// only here when every file it needs is here, because a chapter missing its last file cannot be
/// listened to and saying otherwise would be a lie a listener discovers on a train.
///
/// One consequence worth knowing before reading the rest of this: **downloading one chapter of a
/// shared file downloads its neighbours too**, and this reports them as downloaded, because they
/// are. That is not a rounding error; it is what the file being shared means.
library;

import 'package:drift/drift.dart';
import 'package:kikuyomi_domain/kikuyomi_domain.dart';

import '../database/database.dart';
import '../library/watch_tables.dart';

/// What a book's details screen shows beside one chapter.
enum ChapterDownload {
  /// Nothing has been asked for, or what was asked for was cancelled.
  absent,

  /// Asked for, and waiting: on its turn, on a resolve, on Wi-Fi, on the listener resuming it.
  queued,

  /// Something is happening to it right now.
  working,

  /// Every file it needs is on the device, and it plays with no network at all.
  ///
  /// True of a local book from the moment it is imported: its files were never downloaded, and they
  /// are no less here for that.
  here,

  /// At least one of its files has given up. The chapter cannot complete until that is dealt with,
  /// which is why a failure outranks the files still going: those will finish and it still will not
  /// be playable.
  failed;

  /// Whether asking for this chapter again would do anything.
  bool get canBeAskedFor => this == absent || this == failed;
}

/// Where every chapter of book [bookId] stands, by chapter id, again whenever that **changes**.
///
/// Chapters with no files at all are [ChapterDownload.absent]: §4.4 keeps a chapter whose layout is
/// not known yet, and "nothing to download" and "nothing downloaded" look the same to a listener
/// and are both honest here.
///
/// **Only when it changes**, which is the whole reason this is not a plain `watchTables`. A running
/// download writes `bytes_done` many times a second, and every one of those is a change to
/// `download_tasks`. None of them moves a chapter from one of these five states to another: a
/// chapter that was downloading is still downloading. Handing each one to a screen made a
/// four-hundred-chapter book rebuild its whole list several times a second, which is exactly as slow
/// as it sounds.
///
/// The queries still run per write; what stops is the rebuilding above. A coarser watch is possible
/// -- `download_tasks` could say which columns changed -- and is not worth it while this costs three
/// small indexed reads.
Stream<Map<int, ChapterDownload>> watchChapterDownloads(
  KikuyomiDatabase db,
  int bookId,
) => watchTables(db, [
  db.chapters,
  db.chapterSegments,
  db.mediaFiles,
  db.downloadTasks,
], () => readChapterDownloads(db, bookId)).distinct(_sameStates);

/// Whether two readings say the same thing about every chapter.
///
/// Written out rather than taken from `package:collection`, because it is six lines and this package
/// does not otherwise depend on it.
bool _sameStates(Map<int, ChapterDownload> a, Map<int, ChapterDownload> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (final entry in a.entries) {
    if (b[entry.key] != entry.value) return false;
  }
  return true;
}

/// Where every chapter of book [bookId] stands, once.
Future<Map<int, ChapterDownload>> readChapterDownloads(
  KikuyomiDatabase db,
  int bookId,
) async {
  final chapters = await (db.select(
    db.chapters,
  )..where((c) => c.bookId.equals(bookId))).get();
  if (chapters.isEmpty) return const {};

  // Which files each chapter is made of, and whether each of those files is here. One query: a
  // chapter may name a file in several segments, and a file may serve several chapters, so this is
  // a many-to-many that a per-chapter query would walk once per row.
  final segments = await (db.select(db.chapterSegments).join([
    innerJoin(
      db.mediaFiles,
      db.mediaFiles.id.equalsExp(db.chapterSegments.mediaFileId),
    ),
  ])..where(db.mediaFiles.bookId.equals(bookId))).get();

  final filesOf = <int, Set<int>>{};
  final onDevice = <int, bool>{};
  for (final row in segments) {
    final segment = row.readTable(db.chapterSegments);
    final file = row.readTable(db.mediaFiles);
    (filesOf[segment.chapterId] ??= {}).add(file.id);
    // `localPath`, not `downloadedAt`: a local book's own files have a path and were never
    // downloaded, and `downloadedAt` only says which folder the path is relative to. This is the
    // same test the queue uses to decide a file needs no fetching.
    onDevice[file.id] = file.localPath != null;
  }

  final tasks = await (db.select(db.downloadTasks).join([
    innerJoin(
      db.mediaFiles,
      db.mediaFiles.id.equalsExp(db.downloadTasks.mediaFileId),
    ),
  ])..where(db.mediaFiles.bookId.equals(bookId))).get();
  // One task per file, which the schema enforces with a unique key on `media_file_id`, so there is
  // never a second row to choose between.
  final taskFor = {
    for (final row in tasks)
      row.readTable(db.downloadTasks).mediaFileId: row
          .readTable(db.downloadTasks)
          .state,
  };

  return {
    for (final chapter in chapters)
      chapter.id: _stateOf(filesOf[chapter.id] ?? const {}, onDevice, taskFor),
  };
}

ChapterDownload _stateOf(
  Set<int> files,
  Map<int, bool> onDevice,
  Map<int, DownloadState> taskFor,
) {
  if (files.isEmpty) return ChapterDownload.absent;
  if (files.every((id) => onDevice[id] ?? false)) return ChapterDownload.here;

  var failed = false;
  var working = false;
  var queued = false;
  for (final id in files) {
    if (onDevice[id] ?? false) continue;
    switch (taskFor[id]) {
      case DownloadState.failedRetryable:
      case DownloadState.failedPermanent:
        failed = true;
      case DownloadState.resolving:
      case DownloadState.downloading:
      case DownloadState.processing:
        working = true;
      case DownloadState.queued:
      case DownloadState.waiting:
      case DownloadState.needsResolve:
      case DownloadState.paused:
        queued = true;
      // Completed without the file being on the device means the row has not caught up, and
      // cancelled means nobody wants it. Neither is worth a badge of its own.
      case DownloadState.completed:
      case DownloadState.cancelled:
      case null:
        break;
    }
  }
  // A failure outranks the files still going: those will finish, and the chapter still will not
  // play. Telling a listener it is downloading would be telling them to wait for something that is
  // not coming.
  if (failed) return ChapterDownload.failed;
  if (working) return ChapterDownload.working;
  return queued ? ChapterDownload.queued : ChapterDownload.absent;
}
