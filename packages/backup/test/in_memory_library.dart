// A library held in memory, standing in for the database in tests that need the codec, the planner
// and a library together. The data package's DriftBackupStore is the real implementation, and its own
// tests hold what it writes to the schema, column by column.

import 'package:kikuyomi_domain/kikuyomi_domain.dart';

/// A library kept as a snapshot, which applies restore plans the way the database does.
final class InMemoryLibrary implements LibrarySnapshotReader, RestoreWriter {
  InMemoryLibrary([this.snapshot = const LibrarySnapshot()]);

  /// The library as it is now. Tests may replace it, as listening elsewhere in the app would.
  LibrarySnapshot snapshot;

  /// Every plan applied, in order.
  final applied = <RestorePlan>[];

  @override
  Future<LibrarySnapshot> readLibrary() async => snapshot;

  @override
  Future<RestorePlan> restore(
    RestorePlan Function(LibrarySnapshot current) plan,
  ) async {
    final planned = plan(snapshot);
    snapshot = _apply(snapshot, planned);
    applied.add(planned);
    return planned;
  }
}

LibrarySnapshot _apply(LibrarySnapshot library, RestorePlan plan) {
  final merges = {
    for (final merge in plan.mergedBooks) (merge.sourceId, merge.key): merge,
  };
  return LibrarySnapshot(
    sources: [...library.sources, ...plan.newSources],
    categories: [...library.categories, ...plan.newCategories],
    books: [
      for (final book in library.books)
        switch (merges[(book.sourceId, book.key)]) {
          final merge? => _merge(book, merge),
          null => book,
        },
      ...plan.newBooks,
    ],
  );
}

BookSnapshot _merge(BookSnapshot book, BookMerge merge) {
  final progressByKey = {
    for (final progress in merge.chapterProgress) progress.chapterKey: progress,
  };
  return BookSnapshot(
    sourceId: book.sourceId,
    key: book.key,
    details: merge.edits?.details ?? book.details,
    userOverrides: merge.edits?.userOverrides ?? book.userOverrides,
    contributors: book.contributors,
    inLibrary: book.inLibrary || merge.addToLibrary,
    dateAdded: merge.addToLibrary ? merge.dateAdded : book.dateAdded,
    lastRefreshedAt: book.lastRefreshedAt,
    detailsFetched: book.detailsFetched,
    playbackSpeed: merge.playbackSpeed ?? book.playbackSpeed,
    chaptersReversed: merge.chaptersReversed ?? book.chaptersReversed,
    kind: book.kind,
    createdAt: book.createdAt,
    updatedAt: merge.changesBook ? merge.updatedAt : book.updatedAt,
    mediaFiles: [...book.mediaFiles, ...merge.newFiles],
    chapters: [
      for (final chapter in book.chapters)
        switch (progressByKey[chapter.key]) {
          final progress? => withProgress(
            chapter,
            isListened: progress.isListened,
            listenedAt: progress.listenedAt,
            lastPositionMs: progress.lastPositionMs,
            updatedAt: progress.updatedAt,
          ),
          null => chapter,
        },
      ...merge.newChapters,
    ],
    progress: merge.progress ?? book.progress,
    reading: merge.reading ?? book.reading,
    sessions: [...book.sessions, ...merge.newSessions],
    readingSessions: [...book.readingSessions, ...merge.newReadingSessions],
    bookmarks: [...book.bookmarks, ...merge.newBookmarks],
    categories: [...book.categories, ...merge.newCategories],
  );
}

/// [chapter] with a different listened state and position.
ChapterSnapshot withProgress(
  ChapterSnapshot chapter, {
  required bool isListened,
  required DateTime? listenedAt,
  required int lastPositionMs,
  required DateTime updatedAt,
}) => ChapterSnapshot(
  key: chapter.key,
  title: chapter.title,
  sourceIndex: chapter.sourceIndex,
  createdAt: chapter.createdAt,
  updatedAt: updatedAt,
  groupName: chapter.groupName,
  durationMs: chapter.durationMs,
  publishedAt: chapter.publishedAt,
  isListened: isListened,
  listenedAt: listenedAt,
  lastPositionMs: lastPositionMs,
  removedFromSource: chapter.removedFromSource,
  segments: chapter.segments,
);
