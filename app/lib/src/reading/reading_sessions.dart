/// When someone was reading, for History (ADR-0019).
///
/// The player has it easy: it knows it is playing, so a stretch of listening is the time between
/// pressing play and pressing pause. Reading has no such signal. A chapter is on the screen whether
/// it is being read, glanced at, or left open on a table while its reader makes dinner, and a
/// history that recorded the last of those as four hours of reading would be worse than no history
/// at all.
///
/// So a stretch of reading is the time between opening a chapter and the last sign of life in it —
/// a scroll, a page turned, the reader coming back to the app — plus a little grace, because
/// someone reading a page is perfectly still for a minute or two at a time. Anything after that is
/// not recorded, and it is better to under-count someone's evening than to invent one.
library;

import 'package:kikuyomi_domain/kikuyomi_domain.dart' show Clock;

/// How long after the last sign of life a reader is still counted as reading.
///
/// Long enough to cover a page of a novel read without scrolling, short enough that a book left
/// open on the table records a few minutes rather than the rest of the day.
const readingIdleGrace = Duration(minutes: 3);

/// One stretch of reading, ready to be recorded.
typedef ReadingStretch = ({
  int chapterId,
  DateTime startedAt,
  DateTime endedAt,
});

/// Keeps track of the stretch of reading under way.
final class ReadingSessionRecorder {
  ReadingSessionRecorder({required this.clock, this.grace = readingIdleGrace});

  final Clock clock;

  /// How long after the last sign of life the reader is still counted as reading.
  final Duration grace;

  int? _chapterId;
  DateTime? _startedAt;
  DateTime? _lastAlive;

  /// Whether a stretch is under way.
  bool get isRecording => _chapterId != null;

  /// Starts a stretch in [chapterId], ending whatever was under way and returning it.
  ReadingStretch? start(int chapterId) {
    final finished = stop();
    final now = clock.now();
    _chapterId = chapterId;
    _startedAt = now;
    _lastAlive = now;
    return finished;
  }

  /// Records a sign of life: the reader scrolled, or came back to the app.
  void alive() {
    if (_chapterId != null) _lastAlive = clock.now();
  }

  /// Ends the stretch under way and returns it, or null when there was none.
  ///
  /// It ends at the last sign of life plus the grace, or now, whichever is sooner: the minutes
  /// after someone stopped turning pages are not reading, however long the chapter stayed open.
  ReadingStretch? stop() {
    final chapterId = _chapterId;
    final startedAt = _startedAt;
    final lastAlive = _lastAlive;
    if (chapterId == null || startedAt == null || lastAlive == null) {
      return null;
    }
    _chapterId = null;
    _startedAt = null;
    _lastAlive = null;

    final now = clock.now();
    final lapsed = lastAlive.add(grace);
    final endedAt = lapsed.isBefore(now) ? lapsed : now;
    return endedAt.isAfter(startedAt)
        ? (chapterId: chapterId, startedAt: startedAt, endedAt: endedAt)
        : null;
  }
}
