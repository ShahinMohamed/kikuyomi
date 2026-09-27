import 'package:drift/drift.dart';
import 'package:kikuyomi_domain/kikuyomi_domain.dart';

import '../database/database.dart';
import '../local/local_import.dart' show localSourceId;
import 'book_queries.dart';
import 'watch_tables.dart';

/// A book as its details screen shows it.
///
/// Named apart from `BookDetails`, which is what a source provides for §4.4's merge. This is what
/// the database holds about a book once it is in the library, progress included.
final class BookOverview {
  const BookOverview({
    required this.bookId,
    required this.sourceId,
    required this.title,
    required this.authors,
    required this.narrators,
    required this.totalDurationMs,
    required this.inLibrary,
    required this.chapters,
    required this.markers,
    required this.progress,
    required this.finished,
    required this.coverFileName,
    this.description,
    this.genres = const [],
    this.status,
    this.webUrl,
    this.sourceName,
  });

  final int bookId;
  final String title;

  /// The name of the book's cover in the covers folder, or null for a book with no cover. `CoverFiles`
  /// finds the file.
  final String? coverFileName;

  /// In credit order.
  final List<String> authors;

  /// In credit order.
  final List<String> narrators;

  /// The length of the whole book, or null while it is unknown.
  final int? totalDurationMs;

  /// False once the book has been taken out of the library. Its progress is kept all the same.
  final bool inLibrary;

  /// In source order, leaving out chapters the source no longer reports.
  final List<ChapterOverview> chapters;

  /// The embedded markers of a single file, which §4.5 presents as the book's chapters; empty for
  /// any other book. Where there are markers they are what to list, and [chapters] holds only the
  /// one chapter that spans the file.
  final List<MarkerOverview> markers;

  /// Where the listener is, or null for a book never started.
  final BookProgress? progress;

  /// §4.5: the book's last chapter, the last one the player plays, is recorded as listened.
  ///
  /// Recorded, not worked out from where the listener is, so it is the same test Continue Listening
  /// and the player make. A book can be finished without being started, when it is marked finished
  /// by hand, and stays finished while its listener moves back through it.
  final bool finished;

  /// What the source says the book is about, or null where it said nothing.
  final String? description;

  /// What the source files it under. Empty for a book with none, which a local import usually is.
  final List<String> genres;

  /// Whether the source calls it finished, ongoing, or something else again. A free-text field,
  /// because §3.4 lets a source say what it likes here and the app has no vocabulary to force on it.
  final String? status;

  /// The book's page at its source, for opening it in a browser, or null for a local book.
  final String? webUrl;

  /// What the source is called, for the line that says where the book came from.
  ///
  /// Null when the source row has gone, which happens to a book whose extension was removed:
  /// §3.9 keeps the books and lets the source go, so this has to be missing rather than assumed.
  final String? sourceName;

  /// Which source it came from, so a screen can tell a book with a source behind it from one added
  /// off this device. Only the first of those has anything to be refreshed against.
  final int sourceId;

  /// Whether asking the source for this book again could tell us anything.
  ///
  /// False for a local book: the files are the truth for one of those, and there is no catalogue to
  /// ask. A serial from a source is the opposite case, and the reason this exists -- a podcast that
  /// publishes weekly has new chapters that nothing else in the app will notice.
  bool get canRefresh => sourceId != localSourceId;
}

final class ChapterOverview {
  const ChapterOverview({
    required this.chapterId,
    required this.title,
    required this.durationMs,
    required this.listened,
    required this.current,
  });

  final int chapterId;
  final String title;

  /// Worked out from the files where the chapter's layout is known, as the player's Timeline does;
  /// otherwise what the source said, or null.
  final int? durationMs;

  /// §4.5: the chapter is recorded as listened, by playback reaching its threshold or by hand.
  ///
  /// Only what is recorded counts. A chapter marked not listened by hand reads as not listened
  /// wherever the listener's position in it is.
  final bool listened;

  /// True for the chapter the saved progress is in.
  final bool current;
}

/// An embedded marker presented as a chapter (§4.5).
final class MarkerOverview {
  const MarkerOverview({
    required this.title,
    required this.startMs,
    required this.endMs,
    required this.listened,
    required this.current,
  });

  final String title;

  /// Where the marker's stretch starts in the book, inclusive.
  final int startMs;

  /// Where it ends, exclusive.
  final int endMs;

  /// The file's one chapter is recorded as listened, or the listener's position in it has reached
  /// this marker's stretch less the larger of 30 seconds or 3 percent: §4.5's rule applied to the
  /// marker's own stretch.
  ///
  /// §4.5 anchors progress to that source chapter plus an offset and presents markers only for
  /// navigation and display, so a marker has no row of its own to record a state on. Its state is
  /// worked out, as it was before listened state was recorded, so that a single file part-way
  /// through shows the markers behind the listener as listened. The chapter's recorded state
  /// covers the rest: marked listened, every marker is; marked not listened, the markers the
  /// listener's position has passed still are, since that position is where they have been.
  final bool listened;

  /// True for the marker the saved progress is in.
  final bool current;

  int get durationMs => endMs - startMs;
}

/// A book's saved progress.
final class BookProgress {
  const BookProgress({
    required this.chapterId,
    required this.chapterPositionMs,
    required this.globalPositionMs,
    required this.lastPlayedAt,
  });

  /// Progress is stored chapter-relative (§4.5): this chapter and offset are the truth.
  final int chapterId;
  final int chapterPositionMs;

  /// Derived from the Timeline and cached with the progress, for display.
  final int globalPositionMs;
  final DateTime lastPlayedAt;
}

/// The details of book [bookId], emitting again whenever any of them changes, or null while there is
/// no such book.
///
/// Durations and markers come from the same Timeline the player builds, so the details and the
/// player agree. A book that cannot be played yet still has its details, with durations from its
/// chapter rows and no markers.
Stream<BookOverview?> watchBookOverview(KikuyomiDatabase db, int bookId) =>
    watchTables(db, [
      db.books,
      db.bookPeople,
      db.people,
      db.chapters,
      db.chapterSegments,
      db.mediaFiles,
      db.playbackStates,
      db.sources,
    ], () => _loadBookOverview(db, bookId));

Future<BookOverview?> _loadBookOverview(KikuyomiDatabase db, int bookId) async {
  final book = await (db.select(
    db.books,
  )..where((b) => b.id.equals(bookId))).getSingleOrNull();
  if (book == null) return null;

  final credits =
      await (db.select(db.bookPeople).join([
              innerJoin(
                db.people,
                db.people.id.equalsExp(db.bookPeople.personId),
              ),
            ])
            ..where(db.bookPeople.bookId.equals(bookId))
            ..orderBy([OrderingTerm.asc(db.bookPeople.ordinal)]))
          .get();
  List<String> credited(ContributorRole role) => [
    for (final row in credits)
      if (row.readTable(db.bookPeople).role == role)
        row.readTable(db.people).name,
  ];

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

  final state = await (db.select(
    db.playbackStates,
  )..where((p) => p.bookId.equals(bookId))).getSingleOrNull();

  final timeline = await timelineOrNone(db, bookId);
  final onTimeline = {...?timeline?.chapterIds};
  final last = (await lastPlayableChapters(db, [bookId]))[bookId];

  int? durationOf(ChapterRow chapter) =>
      timeline != null && onTimeline.contains(chapter.id)
      ? timeline.chapterDurationMs(chapter.id)
      : chapter.durationMs;

  var markers = const <MarkerOverview>[];
  final markerChapter = timeline == null
      ? null
      : chapters.where((c) => c.id == timeline.lastChapterId).firstOrNull;
  if (timeline != null && markerChapter != null) {
    // The Timeline presents markers only for a book of one chapter, so its offsets are the book's.
    final inChapter = state != null && state.chapterId == markerChapter.id;
    final here = inChapter
        ? timeline.navigationEntryAt(state.chapterPositionMs)
        : null;
    // Where the listener has reached in the chapter: the saved progress where it is in the chapter,
    // or else the chapter's own last position. A chapter never reached also sits at zero, which
    // would meet the threshold of a marker of 30 seconds or less at the very start, so zero counts
    // only where the saved progress is.
    final reached = inChapter
        ? state.chapterPositionMs
        : markerChapter.lastPositionMs > 0
        ? markerChapter.lastPositionMs
        : null;
    markers = [
      for (final entry in timeline.navigation.whereType<MarkerEntry>())
        MarkerOverview(
          title: entry.title,
          startMs: entry.startMs,
          endMs: entry.endMs,
          listened:
              markerChapter.isListened ||
              (reached != null &&
                  reached >=
                      entry.startMs + listenedThresholdMs(entry.durationMs)),
          current: entry == here,
        ),
    ];
  }

  // Left to be missing rather than assumed: §3.9 lets an extension be removed while its books stay,
  // and then there is no source row to name.
  final source = await (db.select(
    db.sources,
  )..where((s) => s.id.equals(book.sourceId))).getSingleOrNull();

  return BookOverview(
    bookId: book.id,
    sourceId: book.sourceId,
    title: book.title,
    description: book.description,
    genres: book.genres,
    status: book.status,
    webUrl: book.webUrl,
    sourceName: source?.name,
    authors: credited(ContributorRole.author),
    narrators: credited(ContributorRole.narrator),
    totalDurationMs: book.totalDurationMs ?? timeline?.totalDurationMs,
    inLibrary: book.inLibrary,
    coverFileName: book.coverLocalPath,
    chapters: [
      for (final chapter in chapters)
        ChapterOverview(
          chapterId: chapter.id,
          title: chapter.title,
          durationMs: durationOf(chapter),
          listened: chapter.isListened,
          current: state?.chapterId == chapter.id,
        ),
    ],
    markers: markers,
    progress: state == null
        ? null
        : BookProgress(
            chapterId: state.chapterId,
            chapterPositionMs: state.chapterPositionMs,
            globalPositionMs: state.globalPositionMs,
            lastPlayedAt: state.updatedAt,
          ),
    finished: last?.isListened ?? false,
  );
}
