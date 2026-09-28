import 'package:drift/drift.dart';
import 'package:kikuyomi_domain/kikuyomi_domain.dart';

import '../database/database.dart';
import '../library/listened_backfill.dart';

/// Writes a [RestorePlan] to the database.
///
/// The plan has already decided everything. This only turns the identities it refers to, such as a
/// chapter's key within its book or a category's name, into database ids, and writes rows.
///
/// A reference that resolves to nothing, like a chapter key the book does not have, is a bug in
/// whatever made the plan. It fails with a [StateError] rather than writing a row that points
/// nowhere. Call this inside a transaction, so that such a failure leaves nothing half-written.
///
/// For a plan whose listened states are to be worked out from positions
/// ([RestorePlan.listenedFromPositions]), the chapters it wrote are then recorded as listened where
/// their positions have reached their thresholds, as the library's own backfill records them. Those
/// are the chapters it added, those it gave the backup's progress, and the chapter a book's restored
/// progress is in. Chapters already listened are left alone, and so is every chapter the plan did not
/// write, so a restore never records again a chapter the listener marked not listened here.
Future<void> applyRestorePlan(KikuyomiDatabase db, RestorePlan plan) async {
  for (final source in plan.newSources) {
    await db
        .into(db.sources)
        .insert(
          SourcesCompanion(
            id: Value(source.id),
            extensionId: Value(source.extensionId),
            key: Value(source.key),
            name: Value(source.name),
            lang: Value(source.lang),
            contentRating: Value(source.contentRating),
            isEnabled: Value(source.isEnabled),
            isPinned: Value(source.isPinned),
            lastUsedAt: Value(source.lastUsedAt),
          ),
        );
  }

  for (final category in plan.newCategories) {
    await db
        .into(db.categories)
        .insert(
          CategoriesCompanion(
            name: Value(category.name),
            sortOrder: Value(category.sortOrder),
            flags: Value(category.flags),
          ),
        );
  }

  // Backups know categories by name. Should the library hold two of one name, books join the first.
  final categoryIds = <String, int>{};
  final categories =
      await (db.select(db.categories)..orderBy([
            (c) => OrderingTerm.asc(c.sortOrder),
            (c) => OrderingTerm.asc(c.id),
          ]))
          .get();
  for (final category in categories) {
    categoryIds.putIfAbsent(category.name, () => category.id);
  }

  final written = <int>{};
  for (final book in plan.newBooks) {
    written.addAll(await _insertBook(db, book, categoryIds));
  }
  for (final merge in plan.mergedBooks) {
    written.addAll(await _mergeBook(db, merge, categoryIds));
  }
  if (plan.listenedFromPositions) {
    await recordListenedFromPositions(db, onlyChapters: written);
  }
}

/// Inserts [book] whole, and returns the ids of the chapters it wrote, which are all of them.
Future<Iterable<int>> _insertBook(
  KikuyomiDatabase db,
  BookSnapshot book,
  Map<String, int> categoryIds,
) async {
  final bookId = await db
      .into(db.books)
      .insert(
        _details(book.details, book.userOverrides).copyWith(
          sourceId: Value(book.sourceId),
          key: Value(book.key),
          inLibrary: Value(book.inLibrary),
          dateAdded: Value(book.dateAdded),
          lastRefreshedAt: Value(book.lastRefreshedAt),
          detailsFetched: Value(book.detailsFetched),
          playbackSpeed: Value(book.playbackSpeed),
          kind: Value(book.kind),
          chaptersReversed: Value(book.chaptersReversed),
          createdAt: Value(book.createdAt),
          updatedAt: Value(book.updatedAt),
        ),
      );
  await _credit(db, bookId, book.contributors);
  final fileIds = await _insertFiles(db, bookId, book.mediaFiles);
  final chapterIds = await _insertChapters(db, bookId, book.chapters, fileIds);
  if (book.progress case final progress?) {
    await _saveProgress(db, bookId, progress, chapterIds);
  }
  if (book.reading case final reading?) {
    await _saveReading(db, bookId, reading, chapterIds);
  }
  await _addSessions(db, bookId, book.sessions, chapterIds);
  await _addReadingSessions(db, bookId, book.readingSessions, chapterIds);
  await _addBookmarks(db, bookId, book.bookmarks, chapterIds);
  await _join(db, bookId, book.categories, categoryIds);
  return chapterIds.values;
}

/// Applies [merge], and returns the ids of the chapters whose listened state or position it wrote:
/// those it added, those given the backup's progress, and the one the book's progress is now in.
Future<Set<int>> _mergeBook(
  KikuyomiDatabase db,
  BookMerge merge,
  Map<String, int> categoryIds,
) async {
  final book =
      await (db.select(db.books)..where(
            (b) => b.sourceId.equals(merge.sourceId) & b.key.equals(merge.key),
          ))
          .getSingleOrNull() ??
      (throw StateError(
        'the plan merges into book "${merge.key}" of source ${merge.sourceId}, '
        'which the library does not have',
      ));

  if (merge.changesBook) {
    var row = switch (merge.edits) {
      final edits? => _details(edits.details, edits.userOverrides),
      null => const BooksCompanion(),
    }.copyWith(updatedAt: Value(merge.updatedAt));
    if (merge.addToLibrary) {
      row = row.copyWith(
        inLibrary: const Value(true),
        dateAdded: Value(merge.dateAdded),
      );
    }
    if (merge.playbackSpeed case final speed?) {
      row = row.copyWith(playbackSpeed: Value(speed));
    }
    if (merge.chaptersReversed case final reversed?) {
      row = row.copyWith(chaptersReversed: Value(reversed));
    }
    await (db.update(db.books)..where((b) => b.id.equals(book.id))).write(row);
  }

  final fileIds = {
    for (final file in await (db.select(
      db.mediaFiles,
    )..where((f) => f.bookId.equals(book.id))).get())
      file.fileKey: file.id,
    ...await _insertFiles(db, book.id, merge.newFiles),
  };
  final chapterIds = {
    for (final chapter in await (db.select(
      db.chapters,
    )..where((c) => c.bookId.equals(book.id))).get())
      chapter.key: chapter.id,
  };
  final added = await _insertChapters(db, book.id, merge.newChapters, fileIds);
  chapterIds.addAll(added);
  final written = {...added.values};

  for (final progress in merge.chapterProgress) {
    final chapterId = _idOf(chapterIds, progress.chapterKey, 'chapter');
    written.add(chapterId);
    await (db.update(db.chapters)..where((c) => c.id.equals(chapterId))).write(
      ChaptersCompanion(
        isListened: Value(progress.isListened),
        listenedAt: Value(progress.listenedAt),
        lastPositionMs: Value(progress.lastPositionMs),
        updatedAt: Value(progress.updatedAt),
      ),
    );
  }
  if (merge.progress case final progress?) {
    await _saveProgress(db, book.id, progress, chapterIds);
    written.add(_idOf(chapterIds, progress.chapterKey, 'chapter'));
  }
  if (merge.reading case final reading?) {
    await _saveReading(db, book.id, reading, chapterIds);
  }
  await _addSessions(db, book.id, merge.newSessions, chapterIds);
  await _addReadingSessions(db, book.id, merge.newReadingSessions, chapterIds);
  await _addBookmarks(db, book.id, merge.newBookmarks, chapterIds);
  await _join(db, book.id, merge.newCategories, categoryIds);
  return written;
}

/// The detail columns of a book row.
BooksCompanion _details(
  BookDetailsSnapshot details,
  Set<BookField> userOverrides,
) => BooksCompanion(
  title: Value(details.title),
  subtitle: Value(details.subtitle),
  description: Value(details.description),
  coverUrl: Value(details.coverUrl),
  seriesName: Value(details.seriesName),
  seriesIndex: Value(details.seriesIndex),
  genres: Value(details.genres),
  language: Value(details.language),
  publisher: Value(details.publisher),
  publishedDate: Value(details.publishedDate),
  isbn: Value(details.isbn),
  abridged: Value(details.abridged),
  status: Value(details.status),
  contentRating: Value(details.contentRating),
  totalDurationMs: Value(details.totalDurationMs),
  webUrl: Value(details.webUrl),
  userOverrides: Value(userOverrides),
);

/// Credits people by name, creating each person the first time, as importing a book does.
Future<void> _credit(
  KikuyomiDatabase db,
  int bookId,
  List<ContributorSnapshot> contributors,
) async {
  for (final credit in contributors) {
    await db
        .into(db.people)
        .insert(
          PeopleCompanion(name: Value(credit.name)),
          mode: InsertMode.insertOrIgnore,
        );
    final person = await (db.select(
      db.people,
    )..where((p) => p.name.equals(credit.name))).getSingle();
    await db
        .into(db.bookPeople)
        .insert(
          BookPeopleCompanion(
            bookId: Value(bookId),
            personId: Value(person.id),
            role: Value(credit.role),
            ordinal: Value(credit.ordinal),
          ),
          mode: InsertMode.insertOrIgnore,
        );
  }
}

/// Inserts [files] and returns their ids by file key.
Future<Map<String, int>> _insertFiles(
  KikuyomiDatabase db,
  int bookId,
  List<MediaFileSnapshot> files,
) async {
  final ids = <String, int>{};
  for (final file in files) {
    ids[file.fileKey] = await db
        .into(db.mediaFiles)
        .insert(
          MediaFilesCompanion(
            bookId: Value(bookId),
            fileKey: Value(file.fileKey),
            format: Value(file.format),
            durationMs: Value(file.durationMs),
            durationIsEstimate: Value(file.durationIsEstimate),
            sizeBytes: Value(file.sizeBytes),
            embeddedMarkers: Value(file.embeddedMarkers),
            localPath: Value(file.localPath),
            downloadedAt: Value(file.downloadedAt),
          ),
        );
  }
  return ids;
}

/// Inserts [chapters] with their layouts, and returns their ids by key.
Future<Map<String, int>> _insertChapters(
  KikuyomiDatabase db,
  int bookId,
  List<ChapterSnapshot> chapters,
  Map<String, int> fileIds,
) async {
  final ids = <String, int>{};
  for (final chapter in chapters) {
    final chapterId = await db
        .into(db.chapters)
        .insert(
          ChaptersCompanion(
            bookId: Value(bookId),
            key: Value(chapter.key),
            title: Value(chapter.title),
            sourceIndex: Value(chapter.sourceIndex),
            groupName: Value(chapter.groupName),
            durationMs: Value(chapter.durationMs),
            publishedAt: Value(chapter.publishedAt),
            isListened: Value(chapter.isListened),
            listenedAt: Value(chapter.listenedAt),
            lastPositionMs: Value(chapter.lastPositionMs),
            removedFromSource: Value(chapter.removedFromSource),
            createdAt: Value(chapter.createdAt),
            updatedAt: Value(chapter.updatedAt),
          ),
        );
    ids[chapter.key] = chapterId;
    for (final (ordinal, segment) in chapter.segments.indexed) {
      await db
          .into(db.chapterSegments)
          .insert(
            ChapterSegmentsCompanion(
              chapterId: Value(chapterId),
              ordinal: Value(ordinal),
              mediaFileId: Value(_idOf(fileIds, segment.fileKey, 'file')),
              startMs: Value(segment.startMs),
              endMs: Value(segment.endMs),
            ),
          );
    }
  }
  return ids;
}

Future<void> _saveProgress(
  KikuyomiDatabase db,
  int bookId,
  ProgressSnapshot progress,
  Map<String, int> chapterIds,
) async {
  await db
      .into(db.playbackStates)
      .insertOnConflictUpdate(
        PlaybackStatesCompanion(
          bookId: Value(bookId),
          chapterId: Value(_idOf(chapterIds, progress.chapterKey, 'chapter')),
          chapterPositionMs: Value(progress.chapterPositionMs),
          globalPositionMs: Value(progress.globalPositionMs),
          updatedAt: Value(progress.updatedAt),
          deviceId: Value(progress.deviceId),
        ),
      );
}

Future<void> _saveReading(
  KikuyomiDatabase db,
  int bookId,
  ReadingSnapshot reading,
  Map<String, int> chapterIds,
) async {
  await db
      .into(db.readingStates)
      .insertOnConflictUpdate(
        ReadingStatesCompanion(
          bookId: Value(bookId),
          chapterId: Value(_idOf(chapterIds, reading.chapterKey, 'chapter')),
          progress: Value(reading.progress),
          updatedAt: Value(reading.updatedAt),
        ),
      );
}

Future<void> _addSessions(
  KikuyomiDatabase db,
  int bookId,
  List<SessionSnapshot> sessions,
  Map<String, int> chapterIds,
) async {
  for (final session in sessions) {
    await db
        .into(db.listeningSessions)
        .insert(
          ListeningSessionsCompanion(
            bookId: Value(bookId),
            chapterId: Value(switch (session.chapterKey) {
              final key? => _idOf(chapterIds, key, 'chapter'),
              null => null,
            }),
            startedAt: Value(session.startedAt),
            endedAt: Value(session.endedAt),
            startGlobalMs: Value(session.startGlobalMs),
            endGlobalMs: Value(session.endGlobalMs),
            speed: Value(session.speed),
            deviceId: Value(session.deviceId),
          ),
        );
  }
}

Future<void> _addReadingSessions(
  KikuyomiDatabase db,
  int bookId,
  List<ReadingSessionSnapshot> sessions,
  Map<String, int> chapterIds,
) async {
  for (final session in sessions) {
    await db
        .into(db.readingSessions)
        .insert(
          ReadingSessionsCompanion.insert(
            bookId: bookId,
            chapterId: Value(switch (session.chapterKey) {
              final key? => _idOf(chapterIds, key, 'chapter'),
              null => null,
            }),
            startedAt: session.startedAt,
            endedAt: session.endedAt,
            deviceId: session.deviceId,
          ),
        );
  }
}

Future<void> _addBookmarks(
  KikuyomiDatabase db,
  int bookId,
  List<BookmarkSnapshot> bookmarks,
  Map<String, int> chapterIds,
) async {
  for (final bookmark in bookmarks) {
    await db
        .into(db.bookmarks)
        .insert(
          BookmarksCompanion(
            bookId: Value(bookId),
            chapterId: Value(_idOf(chapterIds, bookmark.chapterKey, 'chapter')),
            positionMs: Value(bookmark.positionMs),
            title: Value(bookmark.title),
            note: Value(bookmark.note),
            createdAt: Value(bookmark.createdAt),
          ),
        );
  }
}

Future<void> _join(
  KikuyomiDatabase db,
  int bookId,
  List<String> names,
  Map<String, int> categoryIds,
) async {
  for (final name in names) {
    await db
        .into(db.bookCategories)
        .insert(
          BookCategoriesCompanion(
            bookId: Value(bookId),
            categoryId: Value(_idOf(categoryIds, name, 'category')),
          ),
          mode: InsertMode.insertOrIgnore,
        );
  }
}

int _idOf(Map<String, int> ids, String key, String what) =>
    ids[key] ??
    (throw StateError(
      'the restore plan refers to $what "$key", which is not in the library',
    ));
