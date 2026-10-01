import 'package:drift/drift.dart' hide isNull;
import 'package:kikuyomi_domain/kikuyomi_domain.dart';

import '../database/database.dart';
import '../library/listened_chapters.dart';

/// The database-backed [PlaybackStore]: where the coordinator's progress, listening sessions and
/// per-book speed end up.
final class DriftPlaybackStore implements PlaybackStore {
  DriftPlaybackStore(this._db, {required this.deviceId, required Clock clock})
    : _clock = clock;

  final KikuyomiDatabase _db;
  final Clock _clock;

  /// Stored with progress and sessions (§4.3), so that sync can later tell devices apart.
  final String deviceId;

  /// One row per book in `playback_states`, replaced on every save, and the chapter's own last
  /// position alongside it, with the chapter recorded as listened when [listened] says so. All of
  /// it happens in one transaction, so Continue Listening and the chapter list can never disagree
  /// about where the listener is or whether the book is finished.
  ///
  /// The chapter's last position follows every save, down as well as up, as it always has: it is
  /// where the listener last was in the chapter. Its listened state only ever goes one way here. A
  /// chapter already listened keeps the time it was first recorded, however often it is reached
  /// again.
  @override
  Future<void> saveProgress({
    required int bookId,
    required ChapterPosition position,
    required int globalMs,
    required bool listened,
  }) {
    final now = _clock.now();
    return _db.transaction(() async {
      await _db
          .into(_db.playbackStates)
          .insertOnConflictUpdate(
            PlaybackStatesCompanion(
              bookId: Value(bookId),
              chapterId: Value(position.chapterId),
              chapterPositionMs: Value(position.offsetMs),
              globalPositionMs: Value(globalMs),
              updatedAt: Value(now),
              deviceId: Value(deviceId),
            ),
          );
      await (_db.update(
        _db.chapters,
      )..where((c) => c.id.equals(position.chapterId))).write(
        ChaptersCompanion(
          lastPositionMs: Value(position.offsetMs),
          updatedAt: Value(now),
        ),
      );
      if (!listened) return;
      await (_db.update(_db.chapters)..where(
            (c) => c.id.equals(position.chapterId) & c.isListened.equals(false),
          ))
          .write(
            ChaptersCompanion(
              isListened: const Value(true),
              listenedAt: Value(now),
            ),
          );
    });
  }

  /// As a chapter is marked by hand, with the same rules: see [setChaptersListened].
  @override
  Future<void> saveChapterListened({
    required int bookId,
    required int chapterId,
    required bool listened,
  }) async {
    await setChaptersListened(
      _db,
      bookId: bookId,
      chapterIds: {chapterId},
      listened: listened,
      clock: _clock,
    );
  }

  @override
  Future<void> saveSession(ListeningSession session) =>
      _db.transaction(() async {
        // A session is saved while it is still under way and again as it moves on, so the row for one
        // that began at this moment on this device is the same session, moved forward. No index is
        // needed to find it: the same book cannot begin twice in the same microsecond on one device.
        final existing =
            await (_db.select(_db.listeningSessions)
                  ..where(
                    (s) =>
                        s.bookId.equals(session.bookId) &
                        s.startedAt.equals(session.startedAt) &
                        s.deviceId.equals(deviceId),
                  )
                  ..limit(1))
                .getSingleOrNull();
        if (existing != null) {
          await (_db.update(
            _db.listeningSessions,
          )..where((s) => s.id.equals(existing.id))).write(
            ListeningSessionsCompanion(
              endedAt: Value(session.endedAt),
              endGlobalMs: Value(session.endGlobalMs),
            ),
          );
          return;
        }
        await _db
            .into(_db.listeningSessions)
            .insert(
              ListeningSessionsCompanion(
                bookId: Value(session.bookId),
                chapterId: Value(session.chapterId),
                startedAt: Value(session.startedAt),
                endedAt: Value(session.endedAt),
                startGlobalMs: Value(session.startGlobalMs),
                endGlobalMs: Value(session.endGlobalMs),
                speed: Value(session.speed),
                deviceId: Value(deviceId),
              ),
            );
      });

  @override
  Future<void> saveSpeed({required int bookId, required double speed}) async {
    await (_db.update(_db.books)..where((b) => b.id.equals(bookId))).write(
      BooksCompanion(
        playbackSpeed: Value(speed),
        updatedAt: Value(_clock.now()),
      ),
    );
  }

  /// Replaces the file's estimate and corrects the book's length by as much as the file's changed.
  ///
  /// The length is corrected by the difference rather than summed afresh from the files, because it
  /// is not always their sum: a source may supply its own figure (§4.4), and a correction keeps
  /// whatever that figure rests on. A length the user edited is theirs and stays as they wrote it,
  /// and a book with no length is left without one.
  ///
  /// It all happens in one transaction that first checks the stored file is still an estimate, so
  /// a duration probed exactly in the meantime is never overwritten, and saving the same duration
  /// twice corrects the book's length only once.
  @override
  Future<void> saveLearnedDuration({
    required int bookId,
    required int fileId,
    required int durationMs,
  }) {
    return _db.transaction(() async {
      final file =
          await (_db.select(_db.mediaFiles)
                ..where((f) => f.id.equals(fileId) & f.bookId.equals(bookId)))
              .getSingleOrNull();
      if (file == null || !file.durationIsEstimate) return;

      await (_db.update(
        _db.mediaFiles,
      )..where((f) => f.id.equals(fileId))).write(
        MediaFilesCompanion(
          durationMs: Value(durationMs),
          durationIsEstimate: const Value(false),
        ),
      );

      final estimate = file.durationMs;
      final book = await (_db.select(
        _db.books,
      )..where((b) => b.id.equals(bookId))).getSingle();
      final total = book.totalDurationMs;
      if (estimate == null ||
          total == null ||
          book.userOverrides.contains(BookField.totalDurationMs)) {
        return;
      }
      await (_db.update(_db.books)..where((b) => b.id.equals(bookId))).write(
        BooksCompanion(
          totalDurationMs: Value(total + durationMs - estimate),
          updatedAt: Value(_clock.now()),
        ),
      );
    });
  }
}
