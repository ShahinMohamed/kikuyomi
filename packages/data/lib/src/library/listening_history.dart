/// What has been listened to and read, and letting go of it (§4.3, §6.4, ADR-0019).
///
/// `listening_session` has been filled in since the coordinator learned to record one: every
/// play-to-pause span becomes a row, split whenever the chapter, the speed or the position jumps, so
/// that each row describes a stretch actually heard. Nothing has ever read them back. This does.
///
/// **A session outlives the chapter it was in.** `chapter_id` is nullable and set to null when a
/// chapter is purged, because §4.4's "keep while it carries user data" rule covers progress,
/// bookmarks and downloads — not history. So a chapter title may be missing from an entry whose book
/// is still perfectly present, and the screen has to say something sensible rather than skip the row.
library;

import 'package:drift/drift.dart';
import 'package:kikuyomi_source_api/kikuyomi_source_api.dart' show SourceKind;

import '../database/database.dart';
import 'watch_tables.dart';

/// One stretch of a book, listened to or read, as a history screen shows it.
///
/// One type for both, because what History shows is the same either way: a book, a chapter, when,
/// and for how long. What differs is that a recording also has a speed and a stretch of its own,
/// and those are absent rather than faked for a book that was read.
final class HistoryEntry {
  const HistoryEntry({
    required this.sessionId,
    required this.kind,
    required this.bookId,
    required this.bookTitle,
    required this.startedAt,
    required this.endedAt,
    this.startGlobalMs,
    this.endGlobalMs,
    this.speed,
    this.chapterTitle,
    this.coverFileName,
  });

  /// The row's own id, which is what deleting one entry needs: a book may have many, and two of them
  /// may be in the same chapter minutes apart. Unique only within its own [kind]'s table.
  final int sessionId;

  /// Whether this stretch was listened to or read, which is also which table it came from.
  final SourceKind kind;

  final int bookId;
  final String bookTitle;

  /// The chapter this stretch was in, or null once that chapter has been purged from the source.
  final String? chapterTitle;

  /// The book's cover in the covers folder, or null for a book without one.
  final String? coverFileName;

  final DateTime startedAt;
  final DateTime endedAt;

  /// The stretch of the recording this covered. Null for a book that was read: a page has no
  /// position in milliseconds.
  final int? startGlobalMs;
  final int? endGlobalMs;

  /// The speed this stretch was heard at, which is why it is a stretch of its own: the recorder
  /// splits a session when the speed changes so that each row's figure is true for its whole length.
  /// Null for a book that was read.
  final double? speed;

  /// Wall-clock time spent on it, listening or reading.
  Duration get spent => endedAt.difference(startedAt);

  /// How much of the recording it covered, or null for a book that was read. At 2x this is about
  /// twice [spent].
  Duration? get covered => startGlobalMs == null || endGlobalMs == null
      ? null
      : Duration(milliseconds: endGlobalMs! - startGlobalMs!);
}

/// Everything listened to and read, newest first, watched (§6.4).
///
/// Both tables, merged by when each stretch began, because History is one record of time spent with
/// books rather than two: a listener who reads on the train and listens in the car has one evening,
/// not two.
///
/// [limit] bounds it because history grows for ever and a screen shows a few days of it. The stream
/// emits again whenever a session is recorded or deleted, and whenever a book is renamed, so a
/// listener watching the screen while a book plays sees the entry appear.
Stream<List<HistoryEntry>> watchListeningHistory(
  KikuyomiDatabase db, {
  int limit = 500,
}) => watchTables(db, [
  db.listeningSessions,
  db.readingSessions,
  db.books,
  db.chapters,
], () => _readHistory(db, limit: limit));

Future<List<HistoryEntry>> _readHistory(
  KikuyomiDatabase db, {
  required int limit,
}) async {
  final listening =
      db.select(db.listeningSessions).join([
        innerJoin(db.books, db.books.id.equalsExp(db.listeningSessions.bookId)),
        // Left, because the chapter may have been purged while the history stays.
        leftOuterJoin(
          db.chapters,
          db.chapters.id.equalsExp(db.listeningSessions.chapterId),
        ),
      ])..orderBy([
        OrderingTerm.desc(db.listeningSessions.startedAt),
        OrderingTerm.desc(db.listeningSessions.id),
      ]);
  // Each table is limited before they are merged, so one busy month of listening cannot push every
  // evening of reading off the end, and the merged list is cut to the limit afterwards.
  listening.limit(limit);

  final reading =
      db.select(db.readingSessions).join([
        innerJoin(db.books, db.books.id.equalsExp(db.readingSessions.bookId)),
        leftOuterJoin(
          db.chapters,
          db.chapters.id.equalsExp(db.readingSessions.chapterId),
        ),
      ])..orderBy([
        OrderingTerm.desc(db.readingSessions.startedAt),
        OrderingTerm.desc(db.readingSessions.id),
      ]);
  reading.limit(limit);

  final entries =
      [
        for (final row in await listening.get())
          _heard(
            row.readTable(db.listeningSessions),
            row.readTable(db.books),
            row.readTableOrNull(db.chapters),
          ),
        for (final row in await reading.get())
          _read(
            row.readTable(db.readingSessions),
            row.readTable(db.books),
            row.readTableOrNull(db.chapters),
          ),
      ]..sort((a, b) {
        final byTime = b.startedAt.compareTo(a.startedAt);
        // Two stretches that began in the same millisecond still have to come out in the same order
        // every time, or the screen shuffles under the reader between rebuilds.
        return byTime != 0 ? byTime : b.sessionId.compareTo(a.sessionId);
      });
  return entries.length > limit ? entries.sublist(0, limit) : entries;
}

HistoryEntry _heard(
  ListeningSessionRow session,
  BookRow book,
  ChapterRow? chapter,
) => HistoryEntry(
  sessionId: session.id,
  kind: SourceKind.audio,
  bookId: book.id,
  bookTitle: book.title,
  chapterTitle: chapter?.title,
  coverFileName: book.coverLocalPath,
  startedAt: session.startedAt,
  endedAt: session.endedAt,
  startGlobalMs: session.startGlobalMs,
  endGlobalMs: session.endGlobalMs,
  speed: session.speed,
);

HistoryEntry _read(
  ReadingSessionRow session,
  BookRow book,
  ChapterRow? chapter,
) => HistoryEntry(
  sessionId: session.id,
  kind: SourceKind.text,
  bookId: book.id,
  bookTitle: book.title,
  chapterTitle: chapter?.title,
  coverFileName: book.coverLocalPath,
  startedAt: session.startedAt,
  endedAt: session.endedAt,
);

/// Records that [bookId]'s reader spent [startedAt] to [endedAt] in [chapterId].
///
/// A stretch too short to be reading is not recorded: opening a chapter and going straight back is
/// something everyone does while looking for their place, and a history full of eight-second rows
/// would bury the evening someone actually read.
///
/// Recording the same stretch again — same book, same moment it began, same device — moves its end
/// instead of adding a row. The reader saves a stretch while it is still going on, so an app the
/// system ends without warning keeps the reading it had done; without this, every one of those
/// saves would be another entry in History.
Future<void> recordReadingSession(
  KikuyomiDatabase db, {
  required int bookId,
  required int chapterId,
  required DateTime startedAt,
  required DateTime endedAt,
  required String deviceId,
  Duration shortest = const Duration(seconds: 20),
}) async {
  if (endedAt.difference(startedAt) < shortest) return;
  await db.transaction(() async {
    final existing =
        await (db.select(db.readingSessions)
              ..where(
                (s) =>
                    s.bookId.equals(bookId) &
                    s.startedAt.equals(startedAt) &
                    s.deviceId.equals(deviceId),
              )
              ..limit(1))
            .getSingleOrNull();
    if (existing != null) {
      await (db.update(db.readingSessions)
            ..where((s) => s.id.equals(existing.id)))
          .write(ReadingSessionsCompanion(endedAt: Value(endedAt)));
      return;
    }
    await db
        .into(db.readingSessions)
        .insert(
          ReadingSessionsCompanion.insert(
            bookId: bookId,
            chapterId: Value(chapterId),
            startedAt: startedAt,
            endedAt: endedAt,
            deviceId: deviceId,
          ),
        );
  });
}

/// Forgets one entry, from whichever table it came from.
Future<void> deleteHistoryEntry(KikuyomiDatabase db, HistoryEntry entry) =>
    switch (entry.kind) {
      SourceKind.audio => (db.delete(
        db.listeningSessions,
      )..where((s) => s.id.equals(entry.sessionId))).go(),
      SourceKind.text => (db.delete(
        db.readingSessions,
      )..where((s) => s.id.equals(entry.sessionId))).go(),
    };

/// Forgets everything recorded for book [bookId], and says how many entries went.
///
/// The listener's own book stays, and so does their progress in it: history is a record of when
/// something was heard, not the fact of having heard it (§4.5 keeps that in `playback_state` and the
/// listened flags).
Future<int> deleteBookHistory(KikuyomiDatabase db, int bookId) async =>
    await (db.delete(
      db.listeningSessions,
    )..where((s) => s.bookId.equals(bookId))).go() +
    await (db.delete(
      db.readingSessions,
    )..where((s) => s.bookId.equals(bookId))).go();

/// Forgets all of it, and says how many entries went.
Future<int> clearListeningHistory(KikuyomiDatabase db) async =>
    await db.delete(db.listeningSessions).go() +
    await db.delete(db.readingSessions).go();
