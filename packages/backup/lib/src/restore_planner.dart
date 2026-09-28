/// Planning a restore: how a backup merges into a library that may already hold some of it.
///
/// docs/architecture.md gives restoring a purpose rather than rules. The library has to survive an
/// Android uninstall or an iOS re-sign (§5.1, Appendix A), so a restore must work on a fresh install.
/// It must also work on a library that is not empty, because a user may add a book, or press play,
/// before restoring. §4.4's identity rules decide what matches what. Everything else here is a choice
/// made where the documents are silent, and every choice follows one principle: a restore never loses
/// anything the user did, whether on this device or in the backup.
library;

import 'dart:math' as math;

import 'package:kikuyomi_domain/kikuyomi_domain.dart';

import 'codec.dart';

/// Plans restoring [backup] into [current], the library as it is now.
///
/// Matching follows §4.4 and ADR-0009. Sources match by their stable id, books by source and key,
/// and chapters, files, bookmarks and sessions within a matched book. Categories match by name,
/// since a name is how a user tells categories apart.
///
/// What the library lacks is added. A book the library does not have is restored whole, exactly as
/// backed up, and so are sources and categories. New categories keep their backed-up sort order in a
/// library with no categories yet, and otherwise go after the library's own, in the backup's order.
///
/// A book both have is merged. The documents say nothing about this, so the rules are conservative:
///
/// - Nothing is removed. Whatever the backup lacks stays as it is, and a restore never takes a book
///   out of the library, though it puts back a book the backup has in it.
/// - The book's progress goes to whichever side saved it more recently, and a tie keeps the
///   library's. A book never started here takes the backup's. A reading position goes the same way.
/// - A book's kind stays as the library has it. The same book always comes from the same source, so
///   the two can only differ in a backup that was tampered with.
/// - A chapter's progress, its listened state and last position, goes the same way, with one
///   exception: a chapter with no progress never wins over one with some, however recent. A book added
///   again before restoring has fresh chapters, written just now with nothing listened, and they must
///   not wipe out what the backup remembers.
/// - A chapter the library lacks is restored only if it carries progress, the book's position or a
///   new bookmark, and it is restored marked removed from source. The library's chapter list is the
///   source's latest word, and §4.4 keeps a chapter the source stopped reporting in exactly that way
///   while it carries user data. Restoring chapters without user data as live chapters would duplicate
///   any the source has since renamed.
/// - Details stay as the library has them, being what the source said most recently. The exception is
///   a field the user edited in the backup and not here: it takes the backup's value and stays marked
///   as edited, since §4.4 already ranks a user's edit above anything a source says. Where both sides
///   edited a field, the library's edit wins.
/// - A remembered speed stays. A book with none takes the backup's.
/// - Bookmarks and sessions are added unless already there. A bookmark is the same one when its
///   chapter, position and creation time match; a session when its device, start and end match, since
///   one device cannot be in two sessions at once.
/// - A book's existing files, chapter layouts and credits are left alone. Files are added only where a
///   restored chapter needs them.
///
/// Reconciling two devices that both kept listening is not a restore's job. ADR-0011 gives it to sync,
/// which will need rules that this planner deliberately does not attempt.
///
/// [formatVersion] is the version of the backup file [backup] was read from. A backup from before
/// [backupListenedRecordedSince] says no chapter is listened, even one the listener finished, so its
/// plan asks for listened state to be worked out from the positions it restores
/// ([RestorePlan.listenedFromPositions]). Taking such a backup as written would put every finished
/// book back on Continue Listening. A newer backup's listened state is restored as written, so a
/// chapter the listener marked not listened stays so, wherever its position is.
RestorePlan planRestore({
  required LibrarySnapshot backup,
  required LibrarySnapshot current,
  int formatVersion = backupFormatVersion,
}) {
  final sourceIds = {for (final source in current.sources) source.id};
  final booksHere = {
    for (final book in current.books) (book.sourceId, book.key): book,
  };

  final newBooks = <BookSnapshot>[];
  final mergedBooks = <BookMerge>[];
  for (final book in backup.books) {
    final here = booksHere[(book.sourceId, book.key)];
    if (here == null) {
      newBooks.add(book);
      continue;
    }
    final merge = _mergeBook(here: here, backedUp: book);
    if (!merge.isEmpty) mergedBooks.add(merge);
  }

  return RestorePlan(
    newSources: List.unmodifiable([
      for (final source in backup.sources)
        if (!sourceIds.contains(source.id)) source,
    ]),
    newCategories: _newCategories(
      backedUp: backup.categories,
      here: current.categories,
    ),
    newBooks: List.unmodifiable(newBooks),
    mergedBooks: List.unmodifiable(mergedBooks),
    listenedFromPositions: formatVersion < backupListenedRecordedSince,
  );
}

List<CategorySnapshot> _newCategories({
  required List<CategorySnapshot> backedUp,
  required List<CategorySnapshot> here,
}) {
  final names = {for (final category in here) category.name};
  final missing = [
    for (final category in backedUp)
      if (!names.contains(category.name)) category,
  ];
  if (here.isEmpty) return List.unmodifiable(missing);

  // Dart's sort is not stable, so the backup's own order breaks ties explicitly.
  final ordered = missing.indexed.toList()
    ..sort((a, b) {
      final bySortOrder = a.$2.sortOrder.compareTo(b.$2.sortOrder);
      return bySortOrder != 0 ? bySortOrder : a.$1.compareTo(b.$1);
    });
  final first = here.map((category) => category.sortOrder).reduce(math.max) + 1;
  return List.unmodifiable([
    for (final (i, (_, category)) in ordered.indexed)
      CategorySnapshot(
        name: category.name,
        sortOrder: first + i,
        flags: category.flags,
      ),
  ]);
}

BookMerge _mergeBook({
  required BookSnapshot here,
  required BookSnapshot backedUp,
}) {
  final carriedEdits = backedUp.userOverrides.difference(here.userOverrides);
  final EditedDetails? edits = carriedEdits.isEmpty
      ? null
      : (
          details: here.details.withFieldsFrom(backedUp.details, carriedEdits),
          userOverrides: Set.unmodifiable({
            ...here.userOverrides,
            ...carriedEdits,
          }),
        );
  final addToLibrary = backedUp.inLibrary && !here.inLibrary;

  final progress = _laterProgress(
    here: here.progress,
    backedUp: backedUp.progress,
  );

  final reading = _laterReading(here: here.reading, backedUp: backedUp.reading);

  final bookmarksHere = {
    for (final mark in here.bookmarks) _identifyMark(mark),
  };
  final newBookmarks = [
    for (final mark in backedUp.bookmarks)
      if (!bookmarksHere.contains(_identifyMark(mark))) mark,
  ];

  final chaptersHere = {
    for (final chapter in here.chapters) chapter.key: chapter,
  };
  final keysWithUserData = {
    ?progress?.chapterKey,
    ?reading?.chapterKey,
    for (final mark in newBookmarks) mark.chapterKey,
  };
  final newChapters = <ChapterSnapshot>[];
  final chapterProgress = <ChapterProgress>[];
  for (final chapter in backedUp.chapters) {
    final chapterHere = chaptersHere[chapter.key];
    if (chapterHere == null) {
      if (chapter.hasProgress || keysWithUserData.contains(chapter.key)) {
        newChapters.add(_removedFromSource(chapter));
      }
    } else if (_takesProgress(here: chapterHere, backedUp: chapter)) {
      chapterProgress.add(
        ChapterProgress(
          chapterKey: chapter.key,
          isListened: chapter.isListened,
          listenedAt: chapter.listenedAt,
          lastPositionMs: chapter.lastPositionMs,
          updatedAt: chapter.updatedAt,
        ),
      );
    }
  }

  final filesHere = {for (final file in here.mediaFiles) file.fileKey};
  final filesNeeded = {
    for (final chapter in newChapters)
      for (final segment in chapter.segments) segment.fileKey,
  };
  final newFiles = [
    for (final file in backedUp.mediaFiles)
      if (filesNeeded.contains(file.fileKey) &&
          !filesHere.contains(file.fileKey))
        file,
  ];

  final chapterKeys = {
    ...chaptersHere.keys,
    for (final chapter in newChapters) chapter.key,
  };
  final readingHere = {
    for (final session in here.readingSessions) _identifyReading(session),
  };
  final newReadingSessions = [
    for (final session in backedUp.readingSessions)
      if (!readingHere.contains(_identifyReading(session))) session,
  ];

  final sessionsHere = {
    for (final session in here.sessions) _identifySession(session),
  };
  final newSessions = [
    for (final session in backedUp.sessions)
      if (!sessionsHere.contains(_identifySession(session)))
        session.chapterKey == null || chapterKeys.contains(session.chapterKey)
            ? session
            // History outlives the chapter, as it does in the database.
            : _withoutChapter(session),
  ];

  return BookMerge(
    sourceId: here.sourceId,
    key: here.key,
    updatedAt: backedUp.updatedAt.isAfter(here.updatedAt)
        ? backedUp.updatedAt
        : here.updatedAt,
    edits: edits,
    addToLibrary: addToLibrary,
    dateAdded: addToLibrary ? backedUp.dateAdded ?? here.dateAdded : null,
    playbackSpeed: here.playbackSpeed == null ? backedUp.playbackSpeed : null,
    // Like a remembered speed: a choice made here wins, and one never made takes the backup's.
    chaptersReversed: here.chaptersReversed == null
        ? backedUp.chaptersReversed
        : null,
    newFiles: List.unmodifiable(newFiles),
    newChapters: List.unmodifiable(newChapters),
    chapterProgress: List.unmodifiable(chapterProgress),
    progress: progress,
    reading: reading,
    newSessions: List.unmodifiable(newSessions),
    newReadingSessions: List.unmodifiable(newReadingSessions),
    newBookmarks: List.unmodifiable(newBookmarks),
    newCategories: List.unmodifiable([
      for (final name in backedUp.categories)
        if (!here.categories.contains(name)) name,
    ]),
  );
}

/// The backup's progress, if it should replace the library's.
ProgressSnapshot? _laterProgress({
  required ProgressSnapshot? here,
  required ProgressSnapshot? backedUp,
}) {
  if (backedUp == null) return null;
  if (here == null) return backedUp;
  return backedUp.updatedAt.isAfter(here.updatedAt) ? backedUp : null;
}

/// The backup's reading position, if it should replace the library's.
ReadingSnapshot? _laterReading({
  required ReadingSnapshot? here,
  required ReadingSnapshot? backedUp,
}) {
  if (backedUp == null) return null;
  if (here == null) return backedUp;
  return backedUp.updatedAt.isAfter(here.updatedAt) ? backedUp : null;
}

/// Whether a chapter the library has should take the backup's progress.
bool _takesProgress({
  required ChapterSnapshot here,
  required ChapterSnapshot backedUp,
}) {
  if (!backedUp.hasProgress) return false;
  final same =
      here.isListened == backedUp.isListened &&
      here.lastPositionMs == backedUp.lastPositionMs &&
      _sameMoment(here.listenedAt, backedUp.listenedAt);
  if (same) return false;
  return !here.hasProgress || backedUp.updatedAt.isAfter(here.updatedAt);
}

/// Compares instants. `DateTime.==` also compares time zones, and a time read from the database is
/// local where one read from a backup is UTC.
bool _sameMoment(DateTime? a, DateTime? b) =>
    a == null ? b == null : b != null && a.isAtSameMomentAs(b);

(String, int, int) _identifyMark(BookmarkSnapshot mark) =>
    (mark.chapterKey, mark.positionMs, mark.createdAt.millisecondsSinceEpoch);

(String, int, int) _identifyReading(ReadingSessionSnapshot session) => (
  session.deviceId,
  session.startedAt.millisecondsSinceEpoch,
  session.endedAt.millisecondsSinceEpoch,
);

(String, int, int) _identifySession(SessionSnapshot session) => (
  session.deviceId,
  session.startedAt.millisecondsSinceEpoch,
  session.endedAt.millisecondsSinceEpoch,
);

ChapterSnapshot _removedFromSource(ChapterSnapshot chapter) => ChapterSnapshot(
  key: chapter.key,
  title: chapter.title,
  sourceIndex: chapter.sourceIndex,
  createdAt: chapter.createdAt,
  updatedAt: chapter.updatedAt,
  groupName: chapter.groupName,
  durationMs: chapter.durationMs,
  publishedAt: chapter.publishedAt,
  isListened: chapter.isListened,
  listenedAt: chapter.listenedAt,
  lastPositionMs: chapter.lastPositionMs,
  removedFromSource: true,
  segments: chapter.segments,
);

SessionSnapshot _withoutChapter(SessionSnapshot session) => SessionSnapshot(
  startedAt: session.startedAt,
  endedAt: session.endedAt,
  startGlobalMs: session.startGlobalMs,
  endGlobalMs: session.endGlobalMs,
  speed: session.speed,
  deviceId: session.deviceId,
);
