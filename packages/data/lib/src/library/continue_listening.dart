import 'package:drift/drift.dart';
import 'package:kikuyomi_domain/kikuyomi_domain.dart';

import '../database/database.dart';
import 'book_queries.dart';
import 'continue_shelf.dart';
import 'watch_tables.dart';

/// A started book, as Continue Listening shows it.
final class ContinueListeningBook {
  const ContinueListeningBook({
    required this.bookId,
    required this.title,
    required this.author,
    required this.totalDurationMs,
    required this.globalPositionMs,
    required this.chapterTitle,
    required this.lastPlayedAt,
    required this.coverFileName,
  });

  final int bookId;
  final String title;

  /// The name of the book's cover in the covers folder, or null for a book with no cover. `CoverFiles`
  /// finds the file.
  final String? coverFileName;

  /// The first credited author, or null for a book credited with none.
  final String? author;

  /// The length of the whole book, or null while it is unknown.
  final int? totalDurationMs;

  /// Where the listener is in the whole book: the global position cached with the progress for
  /// display (§4.3).
  final int globalPositionMs;

  /// The chapter the listener is in. For a single file with embedded markers it is the marker's
  /// title, since §4.5 presents those markers as the book's chapters.
  final String chapterTitle;

  /// When progress was last saved.
  final DateTime lastPlayedAt;
}

/// Continue Listening, which §1.5 calls the most important screen in the app: the books in the
/// library that have been started and not finished, most recently played first.
///
/// `playback_states` is its source of truth (§4.3): a book has been started when it has a row
/// there. It is finished, by §4.5, when its last chapter, the last one the player plays, is
/// recorded as listened, which is the same test a book's details and the player make. Recorded,
/// not worked out from the saved position: a book marked finished by hand leaves the shelf wherever
/// its listener was, and one whose listener only moves back through it stays off. A finished book
/// started again comes back, because starting it again records its last chapter as not listened.
///
/// Only books played within [continueShelfRecency] are on it, and not one its listener has taken off
/// by hand since it was last played ([belongsOnContinueShelf]). Without that the shelf held every
/// book ever started and not finished, and only grew.
///
/// The stream emits again whenever anything it shows changes, including every progress save.
/// [clock] says when now is, for the month a book stays; time passing on its own does not make the
/// stream emit, so a book ages off the next time anything on the shelf changes.
Stream<List<ContinueListeningBook>> watchContinueListening(
  KikuyomiDatabase db, {
  required Clock clock,
}) => watchTables(db, [
  db.playbackStates,
  db.books,
  db.chapters,
  db.chapterSegments,
  db.mediaFiles,
  db.bookPeople,
  db.people,
], () => _loadContinueListening(db, clock.now()));

Future<List<ContinueListeningBook>> _loadContinueListening(
  KikuyomiDatabase db,
  DateTime now,
) async {
  final isLast = noOtherPlayableChapter(db, after: true);
  final isFirst = noOtherPlayableChapter(db, after: false);
  final started =
      await (db.select(db.playbackStates).join([
              innerJoin(
                db.books,
                db.books.id.equalsExp(db.playbackStates.bookId),
              ),
              innerJoin(
                db.chapters,
                db.chapters.id.equalsExp(db.playbackStates.chapterId),
              ),
            ])
            ..addColumns([isLast, isFirst])
            ..where(db.books.inLibrary.equals(true)))
          .get();
  if (started.isEmpty) return const [];

  final lastChapters = await lastPlayableChapters(db, {
    for (final row in started) row.readTable(db.books).id,
  });
  final rows = [
    for (final row in started)
      if (!(lastChapters[row.readTable(db.books).id]?.isListened ?? false) &&
          belongsOnContinueShelf(
            lastActive: row.readTable(db.playbackStates).updatedAt,
            hiddenAt: row.readTable(db.books).continueHiddenAt,
            now: now,
          ))
        row,
  ];
  if (rows.isEmpty) return const [];

  final layouts = await _layouts(db, {
    for (final row in rows) row.readTable(db.chapters).id,
  });
  final authors = await _firstAuthors(db, {
    for (final row in rows) row.readTable(db.books).id,
  });

  final books = <ContinueListeningBook>[];
  for (final row in rows) {
    final state = row.readTable(db.playbackStates);
    final book = row.readTable(db.books);
    final chapter = row.readTable(db.chapters);
    // A chapter that cannot be played has no Timeline, and is named by its own title.
    final timeline = _chapterTimeline(
      chapter,
      layouts[chapter.id] ?? const [],
      withMarkers: (row.read(isLast) ?? false) && (row.read(isFirst) ?? false),
    );
    books.add(
      ContinueListeningBook(
        bookId: book.id,
        title: book.title,
        author: authors[book.id],
        totalDurationMs: book.totalDurationMs,
        globalPositionMs: state.globalPositionMs,
        chapterTitle:
            timeline?.navigationEntryAt(state.chapterPositionMs).title ??
            chapter.title,
        lastPlayedAt: state.updatedAt,
        coverFileName: book.coverLocalPath,
      ),
    );
  }
  // Sorted here rather than in SQL: times from the system clock are stored as text with their UTC
  // offset, and text order goes wrong across a daylight-saving change.
  books.sort((a, b) {
    final byTime = b.lastPlayedAt.compareTo(a.lastPlayedAt);
    return byTime != 0 ? byTime : b.bookId.compareTo(a.bookId);
  });
  return books;
}

typedef _Part = ({ChapterSegmentRow segment, MediaFileRow file});

/// The segments of each of [chapterIds], in order, with their files.
Future<Map<int, List<_Part>>> _layouts(
  KikuyomiDatabase db,
  Set<int> chapterIds,
) async {
  final rows =
      await (db.select(db.chapterSegments).join([
              innerJoin(
                db.mediaFiles,
                db.mediaFiles.id.equalsExp(db.chapterSegments.mediaFileId),
              ),
            ])
            ..where(db.chapterSegments.chapterId.isIn(chapterIds))
            ..orderBy([OrderingTerm.asc(db.chapterSegments.ordinal)]))
          .get();
  final layouts = <int, List<_Part>>{};
  for (final row in rows) {
    final segment = row.readTable(db.chapterSegments);
    (layouts[segment.chapterId] ??= []).add((
      segment: segment,
      file: row.readTable(db.mediaFiles),
    ));
  }
  return layouts;
}

/// The first credited author of each of [bookIds] that has one.
Future<Map<int, String>> _firstAuthors(
  KikuyomiDatabase db,
  Set<int> bookIds,
) async {
  final rows =
      await (db.select(db.bookPeople).join([
              innerJoin(
                db.people,
                db.people.id.equalsExp(db.bookPeople.personId),
              ),
            ])
            ..where(
              db.bookPeople.bookId.isIn(bookIds) &
                  db.bookPeople.role.equalsValue(ContributorRole.author),
            )
            ..orderBy([OrderingTerm.asc(db.bookPeople.ordinal)]))
          .get();
  final authors = <int, String>{};
  for (final row in rows) {
    authors.putIfAbsent(
      row.readTable(db.bookPeople).bookId,
      () => row.readTable(db.people).name,
    );
  }
  return authors;
}

/// A Timeline of [chapter] alone, built from its [layout], in which global positions are the
/// chapter's own offsets. Null when the chapter has no layout or a file of unknown length, when it
/// cannot be played anyway.
///
/// Only the chapter the listener is in is built, so a long shelf never loads every book's layout.
/// [withMarkers] hands over the files' embedded markers, and should be true only for a book's one
/// playable chapter: that is when §4.5 presents markers as chapters, and the Timeline cannot see the
/// rest of the book to check.
Timeline? _chapterTimeline(
  ChapterRow chapter,
  List<_Part> layout, {
  required bool withMarkers,
}) {
  if (layout.isEmpty) return null;
  final files = {for (final part in layout) part.file.id: part.file};
  final timelineFiles = [
    for (final file in files.values)
      if (file.durationMs case final durationMs?)
        TimelineFile(
          id: file.id,
          durationMs: durationMs,
          durationIsEstimate: file.durationIsEstimate,
        ),
  ];
  if (timelineFiles.length != files.length) return null;
  try {
    return Timeline.build(
      files: timelineFiles,
      chapters: [
        TimelineChapter(
          id: chapter.id,
          title: chapter.title,
          segments: [
            for (final part in layout)
              TimelineSegment(
                fileId: part.segment.mediaFileId,
                startMs: part.segment.startMs,
                endMs: part.segment.endMs,
              ),
          ],
        ),
      ],
      markersByFile: {
        if (withMarkers)
          for (final file in files.values)
            if (file.embeddedMarkers case final markers?
                when markers.isNotEmpty)
              file.id: markers,
      },
    );
  } on InvalidTimelineException {
    return null;
  }
}
