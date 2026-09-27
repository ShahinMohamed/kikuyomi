import 'package:drift/drift.dart';
import 'package:kikuyomi_domain/kikuyomi_domain.dart';

import '../database/database.dart';

/// Reads everything stored as a [LibrarySnapshot], for backing up and for planning a restore.
///
/// One query per table, grouped in memory, rather than queries per book. A backup reads the whole
/// library anyway, and a dozen queries stay a dozen however large the library grows.
///
/// Database ids are resolved into the identities a snapshot uses, and everything is ordered by those
/// identities, never by id, as [LibrarySnapshotReader.readLibrary] requires. Two databases holding the
/// same library therefore read identically, and back up to identical files.
///
/// Call it inside a transaction, so that every table is read at the same moment.
Future<LibrarySnapshot> readLibrarySnapshot(KikuyomiDatabase db) async {
  final sources = await (db.select(
    db.sources,
  )..orderBy([(s) => OrderingTerm.asc(s.id)])).get();
  final categories =
      await (db.select(db.categories)..orderBy([
            (c) => OrderingTerm.asc(c.sortOrder),
            (c) => OrderingTerm.asc(c.name),
            (c) => OrderingTerm.asc(c.id),
          ]))
          .get();
  final books =
      await (db.select(db.books)..orderBy([
            (b) => OrderingTerm.asc(b.sourceId),
            (b) => OrderingTerm.asc(b.key),
          ]))
          .get();
  final chapters =
      await (db.select(db.chapters)..orderBy([
            (c) => OrderingTerm.asc(c.sourceIndex),
            (c) => OrderingTerm.asc(c.key),
          ]))
          .get();
  final files = await (db.select(
    db.mediaFiles,
  )..orderBy([(f) => OrderingTerm.asc(f.fileKey)])).get();
  final segments = await (db.select(
    db.chapterSegments,
  )..orderBy([(s) => OrderingTerm.asc(s.ordinal)])).get();

  final people = {
    for (final person in await db.select(db.people).get())
      person.id: person.name,
  };
  final chapterKeys = {for (final chapter in chapters) chapter.id: chapter.key};
  final fileKeys = {for (final file in files) file.id: file.fileKey};
  final categoryNames = {
    for (final category in categories) category.id: category.name,
  };
  final categoryRanks = {
    for (final (rank, category) in categories.indexed) category.id: rank,
  };

  final creditsByBook = _groupBy(
    await db.select(db.bookPeople).get(),
    (credit) => credit.bookId,
  );
  final filesByBook = _groupBy(files, (file) => file.bookId);
  final chaptersByBook = _groupBy(chapters, (chapter) => chapter.bookId);
  final segmentsByChapter = _groupBy(segments, (s) => s.chapterId);
  final progressByBook = {
    for (final state in await db.select(db.playbackStates).get())
      state.bookId: state,
  };
  final readingByBook = {
    for (final state in await db.select(db.readingStates).get())
      state.bookId: state,
  };
  final sessionsByBook = _groupBy(
    await db.select(db.listeningSessions).get(),
    (session) => session.bookId,
  );
  final bookmarksByBook = _groupBy(
    await db.select(db.bookmarks).get(),
    (bookmark) => bookmark.bookId,
  );
  final membershipsByBook = _groupBy(
    await db.select(db.bookCategories).get(),
    (membership) => membership.bookId,
  );

  BookSnapshot snapshotOf(BookRow book) {
    final contributors = [
      for (final credit in creditsByBook[book.id] ?? const <BookPersonRow>[])
        ContributorSnapshot(
          name: people[credit.personId]!,
          role: credit.role,
          ordinal: credit.ordinal,
        ),
    ]..sort(_byCredit);

    final sessions = [
      for (final session
          in sessionsByBook[book.id] ?? const <ListeningSessionRow>[])
        SessionSnapshot(
          chapterKey: switch (session.chapterId) {
            final id? => chapterKeys[id]!,
            null => null,
          },
          startedAt: session.startedAt,
          endedAt: session.endedAt,
          startGlobalMs: session.startGlobalMs,
          endGlobalMs: session.endGlobalMs,
          speed: session.speed,
          deviceId: session.deviceId,
        ),
    ]..sort(_bySession);

    final bookmarks = [
      for (final bookmark in bookmarksByBook[book.id] ?? const <BookmarkRow>[])
        BookmarkSnapshot(
          chapterKey: chapterKeys[bookmark.chapterId]!,
          positionMs: bookmark.positionMs,
          title: bookmark.title,
          note: bookmark.note,
          createdAt: bookmark.createdAt,
        ),
    ]..sort(_byBookmark);

    final memberships =
        [...membershipsByBook[book.id] ?? const <BookCategoryRow>[]]..sort(
          (a, b) => categoryRanks[a.categoryId]!.compareTo(
            categoryRanks[b.categoryId]!,
          ),
        );

    final progress = progressByBook[book.id];
    final reading = readingByBook[book.id];

    return BookSnapshot(
      sourceId: book.sourceId,
      key: book.key,
      details: BookDetailsSnapshot(
        title: book.title,
        subtitle: book.subtitle,
        description: book.description,
        coverUrl: book.coverUrl,
        seriesName: book.seriesName,
        seriesIndex: book.seriesIndex,
        genres: book.genres,
        language: book.language,
        publisher: book.publisher,
        publishedDate: book.publishedDate,
        isbn: book.isbn,
        abridged: book.abridged,
        status: book.status,
        contentRating: book.contentRating,
        totalDurationMs: book.totalDurationMs,
        webUrl: book.webUrl,
      ),
      userOverrides: book.userOverrides,
      contributors: contributors,
      inLibrary: book.inLibrary,
      dateAdded: book.dateAdded,
      lastRefreshedAt: book.lastRefreshedAt,
      detailsFetched: book.detailsFetched,
      playbackSpeed: book.playbackSpeed,
      kind: book.kind,
      createdAt: book.createdAt,
      updatedAt: book.updatedAt,
      mediaFiles: [
        for (final file in filesByBook[book.id] ?? const <MediaFileRow>[])
          MediaFileSnapshot(
            fileKey: file.fileKey,
            format: file.format,
            durationMs: file.durationMs,
            durationIsEstimate: file.durationIsEstimate,
            sizeBytes: file.sizeBytes,
            embeddedMarkers: file.embeddedMarkers,
            localPath: file.localPath,
            downloadedAt: file.downloadedAt,
          ),
      ],
      chapters: [
        for (final chapter in chaptersByBook[book.id] ?? const <ChapterRow>[])
          ChapterSnapshot(
            key: chapter.key,
            title: chapter.title,
            sourceIndex: chapter.sourceIndex,
            groupName: chapter.groupName,
            durationMs: chapter.durationMs,
            publishedAt: chapter.publishedAt,
            isListened: chapter.isListened,
            listenedAt: chapter.listenedAt,
            lastPositionMs: chapter.lastPositionMs,
            removedFromSource: chapter.removedFromSource,
            createdAt: chapter.createdAt,
            updatedAt: chapter.updatedAt,
            segments: [
              for (final segment
                  in segmentsByChapter[chapter.id] ??
                      const <ChapterSegmentRow>[])
                SegmentSnapshot(
                  fileKey: fileKeys[segment.mediaFileId]!,
                  startMs: segment.startMs,
                  endMs: segment.endMs,
                ),
            ],
          ),
      ],
      progress: progress == null
          ? null
          : ProgressSnapshot(
              chapterKey: chapterKeys[progress.chapterId]!,
              chapterPositionMs: progress.chapterPositionMs,
              globalPositionMs: progress.globalPositionMs,
              updatedAt: progress.updatedAt,
              deviceId: progress.deviceId,
            ),
      reading: reading == null
          ? null
          : ReadingSnapshot(
              chapterKey: chapterKeys[reading.chapterId]!,
              progress: reading.progress,
              updatedAt: reading.updatedAt,
            ),
      sessions: sessions,
      bookmarks: bookmarks,
      categories: [
        for (final membership in memberships)
          categoryNames[membership.categoryId]!,
      ],
    );
  }

  return LibrarySnapshot(
    sources: [
      for (final source in sources)
        SourceSnapshot(
          id: source.id,
          key: source.key,
          name: source.name,
          lang: source.lang,
          extensionId: source.extensionId,
          contentRating: source.contentRating,
          isEnabled: source.isEnabled,
          isPinned: source.isPinned,
          lastUsedAt: source.lastUsedAt,
        ),
    ],
    categories: [
      for (final category in categories)
        CategorySnapshot(
          name: category.name,
          sortOrder: category.sortOrder,
          flags: category.flags,
        ),
    ],
    books: [for (final book in books) snapshotOf(book)],
  );
}

Map<int, List<T>> _groupBy<T>(Iterable<T> rows, int Function(T row) keyOf) {
  final groups = <int, List<T>>{};
  for (final row in rows) {
    (groups[keyOf(row)] ??= []).add(row);
  }
  return groups;
}

int _byCredit(ContributorSnapshot a, ContributorSnapshot b) {
  final byRole = a.role.index.compareTo(b.role.index);
  if (byRole != 0) return byRole;
  final byOrdinal = a.ordinal.compareTo(b.ordinal);
  return byOrdinal != 0 ? byOrdinal : a.name.compareTo(b.name);
}

int _bySession(SessionSnapshot a, SessionSnapshot b) {
  final byStart = a.startedAt.compareTo(b.startedAt);
  if (byStart != 0) return byStart;
  final byEnd = a.endedAt.compareTo(b.endedAt);
  return byEnd != 0 ? byEnd : a.deviceId.compareTo(b.deviceId);
}

int _byBookmark(BookmarkSnapshot a, BookmarkSnapshot b) {
  final byCreation = a.createdAt.compareTo(b.createdAt);
  if (byCreation != 0) return byCreation;
  final byChapter = a.chapterKey.compareTo(b.chapterKey);
  return byChapter != 0 ? byChapter : a.positionMs.compareTo(b.positionMs);
}
