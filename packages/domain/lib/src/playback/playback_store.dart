import '../timeline/positions.dart';
import 'listening_session.dart';

/// Where playback persists what it produces.
///
/// A service interface, so it lives in the domain (§2.4): the data layer implements it over the
/// database and the playback coordinator consumes it, and neither has to know about the other.
abstract interface class PlaybackStore {
  /// Progress for a book. [position] is the truth (§4.5); [globalMs] is derived and cached for
  /// sorting Continue Listening.
  ///
  /// [listened] says that [position] has reached its chapter's listened threshold (§4.5), which the
  /// caller works out from the Timeline it plays, where the chapter's duration is known. The
  /// chapter is then recorded as listened, if it is not already, in the same write as the progress,
  /// so nothing that reads both can see the one without the other. A chapter already recorded keeps
  /// the time it was first recorded.
  ///
  /// A position short of the threshold leaves the chapter's listened state as it is. Moving back
  /// through a listened chapter does not make it unlistened; only [saveChapterListened], or the
  /// listener by hand, takes the state away.
  Future<void> saveProgress({
    required int bookId,
    required ChapterPosition position,
    required int globalMs,
    required bool listened,
  });

  /// Records chapter [chapterId] of book [bookId] as [listened] or not (§4.5), apart from any
  /// progress: for a finished book started again from its beginning, whose last chapter is then no
  /// longer listened. Positions are left as they are.
  Future<void> saveChapterListened({
    required int bookId,
    required int chapterId,
    required bool listened,
  });

  /// A stretch of listening, for history and statistics.
  ///
  /// Saved more than once while it is still going on, each time with a later end: a session is
  /// identified by its book and the moment it began, and saving one that is already stored moves its
  /// end rather than adding a second row. That is what lets a stretch be written while it is being
  /// listened to, so a process killed mid-chapter loses the last few seconds of history rather than
  /// the whole evening.
  Future<void> saveSession(ListeningSession session);

  /// §4.3: playback speed is remembered per book.
  Future<void> saveSpeed({required int bookId, required double speed});

  /// §4.5: durations are estimated until known, refined as files load, and persisted once learned.
  ///
  /// File [fileId] of book [bookId] has been found to last [durationMs], which replaces its
  /// estimate and is no longer one. A duration already stored as exact is left untouched, whatever
  /// [durationMs] says: a probe that read the file's own timing is better evidence than a player's
  /// report, and the store is the last place that can enforce it.
  Future<void> saveLearnedDuration({
    required int bookId,
    required int fileId,
    required int durationMs,
  });
}
