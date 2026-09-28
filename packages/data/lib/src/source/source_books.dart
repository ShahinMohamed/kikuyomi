/// Writing what a source says about a book into the library, through the §4.4 merges.
///
/// A source's answer is never written straight down. `mergeBookDetails` decides which fields a
/// refresh may overwrite, `mergeCredits` decides the credits, and `planChapterSync` decides which
/// chapters are new, renamed, changed or gone — the last of which is what keeps progress from being
/// lost when a site shuffles its keys. This file is the one that puts those three together and
/// writes the result.
///
/// It also writes the **estimated layout** SourceAPI 1.0 describes under "Before a chapter is
/// resolved": the app knows a chapter's layout only once `resolveMedia` has been called, so until
/// then each chapter is stored as one file of its own `durationMs`, marked as an estimate, "so the
/// whole book can be shown, scrubbed and resumed before every chapter has been resolved". The first
/// resolution replaces it (`source_media_resolver.dart`).
library;

import 'package:drift/drift.dart';
import 'package:kikuyomi_domain/kikuyomi_domain.dart';
import 'package:kikuyomi_source_api/kikuyomi_source_api.dart' as api;

import '../database/database.dart';
import '../local/local_import.dart' show LocalEpubChapter, localSourceId;
import '../merge/book_details.dart';
import '../merge/chapter_sync.dart';
import '../merge/credits.dart';
import 'source_mapping.dart';

/// What a chapter with no duration at all is guessed to last, when the book gives nothing to spread.
///
/// Ten minutes is a plausible chapter and, more to the point, it is an estimate: §4.5 refines it the
/// first time the engine reports how long the file really is, and the refined figure is stored.
const defaultChapterEstimateMs = 10 * 60 * 1000;

/// The prefix of the file key a chapter's estimated layout is written under.
///
/// SourceAPI 1.0 says a key "holds no control character at all, tabs and line breaks included", so a
/// key that begins with U+0000 can never be one a source gave. An estimate and a real file therefore
/// cannot collide, whatever a source calls its files, and the resolver can tell them apart by
/// looking.
const estimatedFileKeyPrefix = '\u0000estimate:';

/// Whether [fileKey] is one of the estimates [saveSourceBook] writes rather than a file a source
/// named.
bool isEstimatedFileKey(String fileKey) =>
    fileKey.startsWith(estimatedFileKeyPrefix);

/// A book written into the library from a source.
final class SavedSourceBook {
  const SavedSourceBook({required this.bookId, this.coverUrl});

  final int bookId;

  /// The cover the book now names, for a caller that fetches it. Null for a book with none, or one
  /// whose cover the listener chose.
  final String? coverUrl;
}

/// Records [fileName] as book [bookId]'s own file, with the chapters inside it (ADR-0021).
///
/// The chapters are the EPUB's, because for a source whose books are one file they are the only
/// ones there are. Written by key rather than replaced, so that downloading a book again — a new
/// edition, or a file that went missing — keeps the chapter rows the reader's place points at.
Future<void> saveBookFile(
  KikuyomiDatabase db, {
  required int bookId,
  required String fileName,
  required List<LocalEpubChapter> chapters,
  required Clock clock,
}) async {
  final now = clock.now();
  await db.transaction(() async {
    await (db.update(db.books)..where((b) => b.id.equals(bookId))).write(
      BooksCompanion(filePath: Value(fileName), updatedAt: Value(now)),
    );
    for (final (index, chapter) in chapters.indexed) {
      await db
          .into(db.chapters)
          .insert(
            ChaptersCompanion.insert(
              bookId: bookId,
              key: chapter.key,
              title: chapter.title,
              sourceIndex: index,
              wordCount: Value(chapter.wordCount),
              createdAt: now,
              updatedAt: now,
            ),
            onConflict: DoUpdate(
              (_) => ChaptersCompanion(
                title: Value(chapter.title),
                sourceIndex: Value(index),
                wordCount: Value(chapter.wordCount),
                removedFromSource: const Value(false),
                updatedAt: Value(now),
              ),
              target: [db.chapters.bookId, db.chapters.key],
            ),
          );
    }
  });
}

/// A source the app knows about, as `source` holds it (§4.3).
///
/// Only the columns that describe the source are written. `is_enabled`, `is_pinned` and
/// `last_used_at` belong to the listener, so a source already known keeps them: registering a
/// source at every start must not undo what the listener did to it.
Future<void> registerSource(
  KikuyomiDatabase db, {
  required int id,
  required String key,
  required String name,
  required String lang,
  String? extensionId,
  String? contentRating,
}) async {
  await db
      .into(db.sources)
      .insert(
        SourcesCompanion(
          id: Value(id),
          extensionId: Value(extensionId),
          key: Value(key),
          name: Value(name),
          lang: Value(lang),
          contentRating: Value(contentRating),
        ),
        mode: InsertMode.insertOrIgnore,
      );
  await (db.update(db.sources)..where((s) => s.id.equals(id))).write(
    SourcesCompanion(
      extensionId: Value(extensionId),
      key: Value(key),
      name: Value(name),
      lang: Value(lang),
      contentRating: Value(contentRating),
    ),
  );
}

/// Every source the app has ever registered, by name.
///
/// Including those whose extension is no longer installed. §3.9: a library book from a removed
/// extension's source "points to a stub source until the extension returns or the books are
/// migrated", so the row outlives the extension and the app has to be able to read it to say so.
Future<List<SourceRow>> readRegisteredSources(KikuyomiDatabase db) =>
    (db.select(db.sources)..orderBy([(s) => OrderingTerm.asc(s.name)])).get();

/// Deletes the source rows that no longer serve any purpose, and says how many went.
///
/// §3.9 keeps a source row after its extension is removed so the library's books still point
/// somewhere: they "point to a stub source until the extension returns or the books are migrated".
/// That reason runs out when the last book from it goes. What is left then is a row naming an
/// extension nobody has, with nothing pointing at it, sitting in the sources list for ever.
///
/// So: never the local source, never one of [keep] -- the sources of the extensions loaded right now
/// -- and never one a book still names. Everything else is rubbish from an extension that was
/// installed once and is not any more, which is exactly what a listener sees as a dead row they
/// cannot get rid of.
///
/// Reinstalling the extension brings its source back, because registering one writes the row again.
Future<int> pruneUnusedSources(
  KikuyomiDatabase db, {
  required Set<int> keep,
}) async {
  final used = await (db.selectOnly(
    db.books,
  )..addColumns([db.books.sourceId])).get();
  final spoken = {
    for (final row in used) row.read(db.books.sourceId)!,
    ...keep,
    localSourceId,
  };
  return (db.delete(db.sources)..where((s) => s.id.isNotIn(spoken))).go();
}

/// Writes what [details] and [chapters] say about a book of source [sourceId], and returns its id.
///
/// The book is matched by its §4.4 identity, `(source_id, key)`. A book already known is refreshed
/// through the merges rather than replaced, so a listener's edits, progress and bookmarks survive.
/// With [addToLibrary] the book joins the library and keeps its `date_added` if it was already in
/// it; without it the book is stored but not in the library, which is what browsing a source's
/// details does before anyone presses Add.
///
/// The whole write is one transaction: a book is never half-refreshed, and nothing reading the
/// library sees a chapter list mid-sync.
///
/// [kind] is the source's (ADR-0019). It is written when a book is first saved and never changed
/// afterwards: a book does not stop being a novel because the extension that offered it was updated,
/// and a refresh that flipped it would move a reader's book to the other tab.
Future<SavedSourceBook> saveSourceBook(
  KikuyomiDatabase db, {
  required int sourceId,
  required api.BookDetails details,
  required List<api.ChapterInfo> chapters,
  required Clock clock,
  bool addToLibrary = false,
  api.SourceKind kind = api.SourceKind.audio,
}) async {
  final now = clock.now();
  return db.transaction(() async {
    final existing =
        await (db.select(db.books)..where(
              (b) => b.sourceId.equals(sourceId) & b.key.equals(details.key),
            ))
            .getSingleOrNull();

    final stored = existing == null
        ? BookDetails()
        : _storedDetailsOf(existing);
    final merge = mergeBookDetails(
      stored: stored,
      incoming: toStoredDetails(details),
      userOverrides: existing?.userOverrides ?? const {},
    );

    final bookId = existing == null
        ? await db
              .into(db.books)
              .insert(
                _companion(merge.details).copyWith(
                  sourceId: Value(sourceId),
                  key: Value(details.key),
                  kind: Value(kind),
                  inLibrary: Value(addToLibrary),
                  dateAdded: Value(addToLibrary ? now : null),
                  detailsFetched: const Value(true),
                  lastRefreshedAt: Value(now),
                  createdAt: Value(now),
                  updatedAt: Value(now),
                ),
              )
        : await _refresh(
            db,
            existing,
            merge,
            addToLibrary: addToLibrary,
            now: now,
          );

    await applyCredits(db, bookId, toCredits(details));
    await _syncChapters(db, bookId, toIncomingChapters(chapters), now: now);
    await _writeEstimatedLayout(
      db,
      bookId,
      totalDurationMs: merge.details.totalDurationMs,
    );

    final book = await (db.select(
      db.books,
    )..where((b) => b.id.equals(bookId))).getSingle();
    return SavedSourceBook(bookId: bookId, coverUrl: book.coverUrl);
  });
}

BookDetails _storedDetailsOf(BookRow book) => BookDetails(
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
);

/// The merged details as columns. A merged title is never absent: the source's title is required and
/// a stored book always has one.
BooksCompanion _companion(BookDetails details) => BooksCompanion(
  title: Value(details.title ?? ''),
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
);

Future<int> _refresh(
  KikuyomiDatabase db,
  BookRow existing,
  BookDetailsMerge merge, {
  required bool addToLibrary,
  required DateTime now,
}) async {
  final joiningTheLibrary = addToLibrary && !existing.inLibrary;
  await (db.update(db.books)..where((b) => b.id.equals(existing.id))).write(
    _companion(merge.details).copyWith(
      // A book keeps the day it was first added; adding it again after it was taken out is a new
      // addition, and Continue Listening and the library both sort by that.
      inLibrary: Value(existing.inLibrary || addToLibrary),
      dateAdded: joiningTheLibrary ? Value(now) : Value(existing.dateAdded),
      detailsFetched: const Value(true),
      lastRefreshedAt: Value(now),
      updatedAt: Value(now),
      // A cover URL that changed means the kept image is of the wrong book, so it is looked for
      // again. §4.4 keeps a custom cover, which the merge has already refused to change.
      coverLocalPath: merge.coverChanged
          ? const Value(null)
          : Value(existing.coverLocalPath),
      coverUpdatedAt: merge.coverChanged
          ? const Value(null)
          : Value(existing.coverUpdatedAt),
    ),
  );
  return existing.id;
}

/// Reconciles the stored chapters of [bookId] with [incoming], following §4.4.
Future<void> _syncChapters(
  KikuyomiDatabase db,
  int bookId,
  List<IncomingChapter> incoming, {
  required DateTime now,
}) async {
  final stored = await _storedChapters(db, bookId);
  for (final change in planChapterSync(stored: stored, incoming: incoming)) {
    switch (change) {
      case InsertChapter(:final chapter):
        await db
            .into(db.chapters)
            .insert(
              ChaptersCompanion(
                bookId: Value(bookId),
                key: Value(chapter.key),
                title: Value(chapter.title),
                sourceIndex: Value(chapter.sourceIndex),
                groupName: Value(chapter.group),
                durationMs: Value(chapter.durationMs),
                publishedAt: Value(chapter.publishedAt),
                createdAt: Value(now),
                updatedAt: Value(now),
              ),
            );
      case UpdateChapter(:final id, :final chapter):
        await _writeChapter(db, id, chapter, now: now);
      case RenameChapter(:final id, :final chapter):
        await _writeChapter(db, id, chapter, now: now, key: chapter.key);
      case RemoveChapter(:final id):
        await (db.update(db.chapters)..where((c) => c.id.equals(id))).write(
          ChaptersCompanion(
            removedFromSource: const Value(true),
            updatedAt: Value(now),
          ),
        );
    }
  }
}

/// Writes an incoming chapter over a stored one.
///
/// A field the source did not report this time keeps its stored value, which is chapter sync's own
/// rule for a duration and the same rule `mergeBookDetails` applies to a book's fields.
Future<void> _writeChapter(
  KikuyomiDatabase db,
  int id,
  IncomingChapter chapter, {
  required DateTime now,
  String? key,
}) async {
  await (db.update(db.chapters)..where((c) => c.id.equals(id))).write(
    ChaptersCompanion(
      key: key == null ? const Value.absent() : Value(key),
      title: Value(chapter.title),
      sourceIndex: Value(chapter.sourceIndex),
      durationMs: chapter.durationMs == null
          ? const Value.absent()
          : Value(chapter.durationMs),
      publishedAt: chapter.publishedAt == null
          ? const Value.absent()
          : Value(chapter.publishedAt),
      groupName: chapter.group == null
          ? const Value.absent()
          : Value(chapter.group),
      removedFromSource: const Value(false),
      updatedAt: Value(now),
    ),
  );
}

/// The stored chapters of [bookId], with what §4.4 keeps a removed chapter for.
Future<List<StoredChapter>> _storedChapters(
  KikuyomiDatabase db,
  int bookId,
) async {
  final rows = await (db.select(
    db.chapters,
  )..where((c) => c.bookId.equals(bookId))).get();
  if (rows.isEmpty) return const [];
  final ids = [for (final row in rows) row.id];

  final playing = await (db.select(
    db.playbackStates,
  )..where((p) => p.bookId.equals(bookId))).getSingleOrNull();
  final bookmarked = {
    for (final row in await (db.select(
      db.bookmarks,
    )..where((b) => b.chapterId.isIn(ids))).get())
      row.chapterId,
  };
  final downloaded = {
    for (final row
        in await (db.select(db.chapterSegments).join([
              innerJoin(
                db.mediaFiles,
                db.mediaFiles.id.equalsExp(db.chapterSegments.mediaFileId),
              ),
            ])..where(
              db.chapterSegments.chapterId.isIn(ids) &
                  db.mediaFiles.localPath.isNotNull(),
            ))
            .get())
      row.readTable(db.chapterSegments).chapterId,
  };

  return [
    for (final row in rows)
      StoredChapter(
        id: row.id,
        key: row.key,
        title: row.title,
        sourceIndex: row.sourceIndex,
        durationMs: row.durationMs,
        publishedAt: row.publishedAt,
        group: row.groupName,
        removedFromSource: row.removedFromSource,
        hasProgress:
            row.lastPositionMs > 0 ||
            row.isListened ||
            playing?.chapterId == row.id,
        hasBookmarks: bookmarked.contains(row.id),
        hasDownloads: downloaded.contains(row.id),
      ),
  ];
}

/// Gives every chapter of [bookId] that has no layout yet the estimated one the contract describes:
/// one file of the chapter's own length, marked as an estimate.
///
/// A chapter whose source gave no duration is guessed at, because a file with no duration cannot go
/// on a Timeline at all and the book would not open. What is left of [totalDurationMs] after the
/// chapters that do have one is spread evenly over those that do not; failing that, each gets
/// [defaultChapterEstimateMs]. Every figure here is written as an estimate, and §4.5 replaces it
/// with the real one the first time the engine plays the file.
Future<void> _writeEstimatedLayout(
  KikuyomiDatabase db,
  int bookId, {
  int? totalDurationMs,
}) async {
  final chapters =
      await (db.select(db.chapters)
            ..where(
              (c) =>
                  c.bookId.equals(bookId) & c.removedFromSource.equals(false),
            )
            ..orderBy([
              (c) => OrderingTerm.asc(c.sourceIndex),
              (c) => OrderingTerm.asc(c.id),
            ]))
          .get();
  if (chapters.isEmpty) return;
  final laidOut = {
    for (final row in await (db.select(
      db.chapterSegments,
    )..where((s) => s.chapterId.isIn([for (final c in chapters) c.id]))).get())
      row.chapterId,
  };
  final missing = [
    for (final chapter in chapters)
      if (!laidOut.contains(chapter.id)) chapter,
  ];
  if (missing.isEmpty) return;

  final guess = _guessedDurationMs(chapters, totalDurationMs);
  for (final chapter in missing) {
    final fileId = await db
        .into(db.mediaFiles)
        .insert(
          MediaFilesCompanion(
            bookId: Value(bookId),
            fileKey: Value('$estimatedFileKeyPrefix${chapter.key}'),
            durationMs: Value(chapter.durationMs ?? guess),
            durationIsEstimate: const Value(true),
          ),
        );
    await db
        .into(db.chapterSegments)
        .insert(
          ChapterSegmentsCompanion(
            chapterId: Value(chapter.id),
            ordinal: const Value(0),
            mediaFileId: Value(fileId),
          ),
        );
  }
}

int _guessedDurationMs(List<ChapterRow> chapters, int? totalDurationMs) {
  final unknown = chapters.where((c) => c.durationMs == null).length;
  if (unknown == 0 || totalDurationMs == null) return defaultChapterEstimateMs;
  final known = chapters.fold(
    0,
    (total, chapter) => total + (chapter.durationMs ?? 0),
  );
  final left = totalDurationMs - known;
  return left > 0 ? left ~/ unknown : defaultChapterEstimateMs;
}
