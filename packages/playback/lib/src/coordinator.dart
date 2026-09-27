import 'dart:async';
import 'dart:math' as math;

import 'package:kikuyomi_domain/kikuyomi_domain.dart';

import 'engine.dart';
import 'listening_sessions.dart';
import 'media.dart';
import 'player_state.dart';
import 'progress_tracker.dart';
import 'sleep_timer.dart';
import 'smart_rewind.dart';
import 'system_audio.dart';

/// What the coordinator needs to open a book.
final class PlaybackRequest {
  const PlaybackRequest({
    required this.bookId,
    required this.timeline,
    this.resumeFrom,
    this.pausedFor = Duration.zero,
    this.speed = 1.0,
    this.finished = false,
  });

  final int bookId;
  final Timeline timeline;

  /// The saved position, or null to start from the beginning.
  final ChapterPosition? resumeFrom;

  /// How long ago the book was last played, for smart rewind.
  final Duration pausedFor;

  /// The book's remembered speed (§4.3).
  final double speed;

  /// Whether the book is finished as it is stored: its last chapter is recorded as listened (§4.5).
  final bool finished;
}

/// §6.1's coordinator: the brain of playback, in pure Dart.
///
/// It owns the open book and its Timeline, turns user and system commands into engine operations,
/// feeds the progress tracker, the listening-session recorder and the sleep timer, persists what
/// they produce, and publishes a single [PlayerState].
///
/// Every command and every engine event runs through one serial queue. Without it, a seek could
/// interleave with a position event whose progress write is still in flight, and the last write
/// would be whichever finished second rather than whichever happened second.
///
/// Recovery from a stream error, per §6.3: one transparent re-resolve and reload at the same
/// position. It is re-armed by the next user action rather than by time passing, so a source that
/// fails every few seconds surfaces as an error instead of retrying forever.
///
/// §4.5's listened state is recorded as progress is saved: a save at a position that has reached
/// its chapter's listened threshold records the chapter as listened, in the same write. That is the
/// literal rule, so a seek past a chapter records nothing for it, since no position in it was
/// saved. The book is finished once its last chapter is recorded, and [PlayerReady.finished] follows
/// what is stored rather than the engine: it is true from the moment that chapter is recorded,
/// stays true as the listener moves about the book, and is cleared only when the book is started
/// again ([startAgain]) or the chapter is marked not listened by hand ([onListenedChanged]).
///
/// The coordinator does not own the engine and does not dispose it.
final class PlaybackCoordinator {
  PlaybackCoordinator({
    required PlaybackEngine engine,
    required MediaResolver resolver,
    required PlaybackStore store,
    required Clock clock,
    SmartRewind? smartRewind,
    SleepTimer? sleepTimer,
    this.onTiming,
    this.previousChapterThreshold = const Duration(seconds: 3),
    this.seekLandingTolerance = const Duration(milliseconds: 500),
    this.durationRefinementThreshold = const Duration(seconds: 1),
  }) : _engine = engine,
       _resolver = resolver,
       _store = store,
       _clock = clock,
       _smartRewind = smartRewind ?? SmartRewind(),
       _sleepTimer = sleepTimer ?? SleepTimer(clock: clock) {
    _events = _engine.events.listen(
      (event) =>
          unawaited(_serial(() => _onEvent(event)).catchError(_onUnexpected)),
    );
  }

  /// Where the time each slow step takes is reported, or null to measure nothing.
  ///
  /// The steps are `open.resolve`, `open.load` and `open` for opening a book, `reload` for §6.3's
  /// recovery, and `seek` for moving about in one. The app passes a sink that writes to the console
  /// in a debug build, which is how a listener saying "pressing play is slow" becomes a number.
  final TimingSink? onTiming;

  /// "Previous chapter" restarts the current chapter when playback is further into it than this,
  /// and goes to the previous chapter otherwise. The usual convention in media players.
  final Duration previousChapterThreshold;

  /// How far short of where a seek or load was sent the engine may report being, and still be
  /// taken to be there.
  ///
  /// The just_audio backend on Windows settles a seek just short of where it was sent: at normal
  /// speed, a seek to 9000 ms reports 8999 ms. Taken literally, a position short of a chapter's
  /// start belongs to the previous chapter: the player names the wrong chapter, progress is saved
  /// at the end of the previous one, and "next chapter" seeks to the same start again and again
  /// without moving. A position this close short of the destination is read as the destination
  /// itself. The margin is generous because nothing else reports such a position: playback only
  /// moves forwards from where it was sent.
  final Duration seekLandingTolerance;

  /// How far a duration the engine reports must differ from a file's estimate before the book is
  /// rebuilt around it and the duration stored (§4.5).
  ///
  /// A smaller difference leaves the estimate standing, still marked as one. A bitrate estimate of a
  /// constant-bitrate MP3 usually lands within a few frames, tens of milliseconds, of what the
  /// engine finds, and the player shows whole seconds, so rebuilding for that would move nothing a
  /// listener can see. The estimates worth correcting, such as a variable-bitrate file judged by its
  /// first frame, are out by seconds or minutes.
  final Duration durationRefinementThreshold;

  final PlaybackEngine _engine;
  final MediaResolver _resolver;
  final PlaybackStore _store;
  final Clock _clock;
  final SmartRewind _smartRewind;
  final SleepTimer _sleepTimer;

  late final StreamSubscription<EngineEvent> _events;
  final _states = StreamController<PlayerState>.broadcast();
  PlayerState _state = const PlayerIdle();
  _Session? _session;
  SleepTimerState _sleepState = const SleepTimerOff();
  Future<void> _tail = Future.value();

  PlayerState get state => _state;
  Stream<PlayerState> get states => _states.stream;

  /// Opens a book, resuming it with smart rewind applied, without starting playback.
  Future<void> open(PlaybackRequest request) => _serial(() async {
    await _closeSession();
    _emit(PlayerLoading(request.bookId));
    // A rewind owed to a previous book's sleep timer does not carry over to this one.
    _sleepTimer.takeResumeRewind();

    final timeline = request.timeline;
    final watch = onTiming == null ? null : (Stopwatch()..start());
    try {
      final saved = request.resumeFrom;
      final start = saved == null
          ? ChapterPosition(chapterId: timeline.chapterIds.first, offsetMs: 0)
          : _smartRewind.resumeFrom(saved, request.pausedFor);
      final startAt = timeline.queuePositionOfChapter(start);
      final items = await _resolve(timeline, refresh: false, startAt: startAt);
      final resolvedAt = watch?.elapsed;

      await _engine.load(items, startAt: startAt);
      await _engine.setSpeed(request.speed);
      await _engine.setVolume(1.0);
      if (watch != null && resolvedAt != null) {
        onTiming!('open.resolve', resolvedAt);
        onTiming!('open.load', watch.elapsed - resolvedAt);
      }

      final session = _Session(
        bookId: request.bookId,
        timeline: timeline,
        tracker: ProgressTracker(timeline: timeline, clock: _clock),
        recorder: ListeningSessionRecorder(
          bookId: request.bookId,
          timeline: timeline,
          clock: _clock,
        ),
        speed: request.speed,
        position: startAt,
        finished: request.finished,
      );
      session.tracker.onLoaded(startAt);
      _session = session;
      _publish();
      // Deliberately not awaited, and started only once the book is open: the point of leaving
      // files unresolved was to let playback begin, so finishing the job must not delay it.
      unawaited(_resolveTheRest(session, items));
    } catch (error) {
      _session = null;
      _emit(PlayerFailed(bookId: request.bookId, error: error));
    }
    if (watch != null) onTiming!('open', watch.elapsed);
  });

  Future<void> play() => _serial(() async {
    final session = _session;
    if (session != null) {
      // The user has taken over from any interruption, and re-armed §6.3's one recovery.
      session.interrupted = false;
      session.retried = false;
    }
    await _playInternal();
  });

  Future<void> pause() => _serial(() async {
    _session?.interrupted = false;
    await _pauseInternal();
  });

  /// A seek to a position in book-global time, which is what the scrubber and skip buttons produce.
  Future<void> seekTo(int globalMs) => _serial(() async {
    final session = _session;
    if (session == null) return;
    session.retried = false;
    session.completed = false;
    await _seekInternal(session, globalMs);
    _pinSleepChapter(session);
    _publish();
  });

  /// Skips forwards, or backwards for a negative [by], clamped to the book.
  Future<void> skip(Duration by) => _serial(() async {
    final session = _session;
    if (session == null) return;
    session.retried = false;
    session.completed = false;
    await _seekInternal(session, session.globalMs + by.inMilliseconds);
    _pinSleepChapter(session);
    _publish();
  });

  /// Moves to the next chapter, or the next embedded marker in a single-chapter book.
  Future<void> nextChapter() => _serial(() async {
    final session = _session;
    if (session == null) return;
    final entries = session.timeline.navigation;
    final index = entries.indexOf(
      session.timeline.navigationEntryAt(session.globalMs),
    );
    if (index + 1 >= entries.length) return;
    session.retried = false;
    await _seekInternal(session, entries[index + 1].startMs);
    _pinSleepChapter(session);
    _publish();
  });

  /// Moves to the start of chapter [chapterId], for a listener who picked it out of a list.
  ///
  /// Not the same as seeking to where that chapter happens to begin: a list gives a chapter's
  /// identity, and turning that into a position is the Timeline's job, not the caller's. The caller
  /// has a row; only the Timeline knows what millisecond it starts at, and only it knows whether
  /// the book's layout has changed since the row was drawn.
  ///
  /// A chapter this book's Timeline does not hold is ignored. §4.4 keeps a chapter whose files
  /// could not be laid out, so a details screen can list one that has no position to move to, and a
  /// tap on it should do nothing rather than land somewhere arbitrary.
  Future<void> goToChapter(int chapterId) => _serial(() async {
    final session = _session;
    if (session == null) return;
    final timeline = session.timeline;
    if (!timeline.chapterIds.contains(chapterId)) return;
    session.retried = false;
    session.completed = false;
    await _seekInternal(
      session,
      timeline.globalOf(ChapterPosition(chapterId: chapterId, offsetMs: 0)),
    );
    _pinSleepChapter(session);
    _publish();
  });

  /// Restarts the current chapter, or moves to the previous one near its start. See
  /// [previousChapterThreshold].
  Future<void> previousChapter() => _serial(() async {
    final session = _session;
    if (session == null) return;
    final timeline = session.timeline;
    final global = session.globalMs;
    final current = timeline.navigationEntryAt(global);
    final index = timeline.navigation.indexOf(current);
    final intoChapter = global - current.startMs;
    final target =
        index == 0 || intoChapter > previousChapterThreshold.inMilliseconds
        ? current.startMs
        : timeline.navigation[index - 1].startMs;
    session.retried = false;
    session.completed = false;
    await _seekInternal(session, target);
    _pinSleepChapter(session);
    _publish();
  });

  /// Starts the book again from its beginning, as playing it after it has played to its end does.
  ///
  /// A finished book started again is no longer finished (§4.5): its last chapter is recorded as not
  /// listened, so the book returns to Continue Listening while it is listened to again. Its other
  /// chapters keep their listened state, as they would if the listener only moved back through them.
  Future<void> startAgain() => _serial(() async {
    final session = _session;
    if (session == null) return;
    session.retried = false;
    await _startAgain(session);
    _pinSleepChapter(session);
    _publish();
  });

  /// Chapters [chapterIds] of book [bookId] were marked [listened], or not, by hand somewhere other
  /// than the player, such as the book's details.
  ///
  /// Nothing is written: the change is already stored. When the open book's last chapter is among
  /// them, [PlayerReady.finished] follows, so that the player and the store agree. Marks made in
  /// another book are ignored.
  Future<void> onListenedChanged({
    required int bookId,
    required Set<int> chapterIds,
    required bool listened,
  }) => _serial(() async {
    final session = _session;
    if (session == null || session.bookId != bookId) return;
    if (!chapterIds.contains(session.timeline.lastChapterId)) return;
    session.finished = listened;
    _publish();
  });

  /// §6.5: 0.5x to 3.5x. Remembered for the book.
  Future<void> setSpeed(double speed) => _serial(() async {
    if (speed < 0.5 || speed > 3.5) {
      throw ArgumentError.value(speed, 'speed', 'must be between 0.5 and 3.5');
    }
    final session = _session;
    if (session == null || speed == session.speed) return;
    await _engine.setSpeed(speed);
    await _saveSession(
      session.recorder.onSpeedChanged(globalMs: session.globalMs, speed: speed),
    );
    session.speed = speed;
    await _store.saveSpeed(bookId: session.bookId, speed: speed);
    _publish();
  });

  Future<void> startSleepTimer(SleepTimerTarget target) => _serial(() async {
    final session = _session;
    if (session == null) return;
    _sleepTimer.start(target);
    _pinSleepChapter(session);
    await _applySleepTimer(session, evenWhenPaused: true);
    _publish();
  });

  Future<void> extendSleepTimer(Duration by) => _serial(() async {
    final session = _session;
    if (session == null) return;
    _sleepTimer.extend(by);
    await _applySleepTimer(session, evenWhenPaused: true);
    _publish();
  });

  Future<void> cancelSleepTimer() => _serial(() async {
    final session = _session;
    if (session == null) return;
    _sleepTimer.cancel();
    session.sleepChapterEndMs = null;
    _sleepState = const SleepTimerOff();
    await _setVolume(session, 1.0);
    _publish();
  });

  /// §6.5's interruption rules.
  ///
  /// A spoken book pauses for an interruption rather than talking over it, saving progress at once
  /// (§6.4). It resumes when the interruption ends only if the interruption is what paused it,
  /// nobody has pressed play or pause since, and the system says resuming is appropriate; smart
  /// rewind then applies as after any pause. Losing the audio output pauses for good, so that a book
  /// playing through headphones does not carry on out of the phone's speaker.
  Future<void> onSystemAudio(SystemAudioEvent event) => _serial(() async {
    final session = _session;
    if (session == null) return;
    switch (event) {
      case AudioInterruptionBegan():
        if (!session.playing) return;
        await _pauseInternal();
        session.interrupted = true;
      case AudioInterruptionEnded(:final mayResume):
        final resume = session.interrupted && mayResume;
        session.interrupted = false;
        if (resume) await _playInternal();
      case AudioOutputLost():
        session.interrupted = false;
        await _pauseInternal();
    }
  });

  /// The app moved to the background. §6.4 saves progress immediately; playback continues.
  Future<void> onBackgrounded() => _serial(() async {
    final session = _session;
    if (session == null) return;
    await _saveProgress(session, session.tracker.onBackgrounded());
  });

  /// Stops the open book, saving its progress and listening, and stops listening to the engine.
  Future<void> close() async {
    await _serial(_closeSession);
    await _events.cancel();
    _emit(const PlayerIdle());
    await _states.close();
  }

  // Internals. Everything below assumes it is already running inside the serial queue.

  Future<void> _onEvent(EngineEvent event) async {
    final session = _session;
    if (session == null) return;
    switch (event) {
      case EnginePositionChanged(:final position):
        // Spike (b): after completion the engine reports position zero. It is not a position.
        if (session.completed) return;
        session.position = _settle(session, position);
        await _saveProgress(
          session,
          session.tracker.onPosition(session.position),
        );
        await _saveSession(session.recorder.onPosition(session.globalMs));
        await _applySleepTimer(session);
        _publish();
      case EngineItemChanged():
        // Positions arrive with their item index, so there is nothing extra to track.
        break;
      case EngineItemDurationKnown(:final itemIndex, :final durationMs):
        await _learnDuration(session, itemIndex, durationMs);
      case EngineBufferingChanged(:final buffering):
        session.buffering = buffering;
        _publish();
      case EngineCompleted():
        session.playing = false;
        session.completed = true;
        session.pausedAt = _clock.now();
        session.position = session.timeline.queuePositionAt(
          session.timeline.totalDurationMs,
        );
        _sleepTimer.onPaused();
        await _saveProgress(session, session.tracker.onCompleted());
        await _saveSession(
          session.recorder.onStop(session.timeline.totalDurationMs),
        );
        _publish();
      case EngineFailed(:final error):
        if (session.retried) {
          await _fail(session, error);
        } else {
          session.retried = true;
          await _reload(session, refresh: true);
        }
    }
  }

  Future<void> _playInternal() async {
    final session = _session;
    if (session == null || session.playing) return;

    if (session.error != null) {
      session.error = null;
      if (!await _reload(session, refresh: true)) return;
    }

    if (session.completed) {
      await _startAgain(session);
    } else {
      final pausedAt = session.pausedAt;
      final pause = pausedAt == null
          ? Duration.zero
          : _clock.now().difference(pausedAt);
      // Smart rewind and the sleep timer's rewind are independent; the larger one wins.
      final smart = _smartRewind.rewindAfter(pause);
      final sleep = _sleepTimer.takeResumeRewind();
      final rewind = smart > sleep ? smart : sleep;
      if (rewind > Duration.zero) {
        final here = session.timeline.chapterPositionOfQueue(session.position);
        final back = ChapterPosition(
          chapterId: here.chapterId,
          offsetMs: math.max(0, here.offsetMs - rewind.inMilliseconds),
        );
        await _seekInternal(session, session.timeline.globalOf(back));
      }
    }

    await _engine.play();
    session.playing = true;
    session.pausedAt = null;
    _sleepTimer.onPlaying();
    session.recorder.onPlay(globalMs: session.globalMs, speed: session.speed);
    _publish();
  }

  Future<void> _pauseInternal() async {
    final session = _session;
    if (session == null || !session.playing) return;
    await _engine.pause();
    session.playing = false;
    session.pausedAt = _clock.now();
    _sleepTimer.onPaused();
    await _saveProgress(session, session.tracker.onPause());
    await _saveSession(session.recorder.onStop(session.globalMs));
    _publish();
  }

  /// Moves to the start of the book and, for a finished book, records its last chapter as not
  /// listened. See [startAgain].
  ///
  /// The seek comes first, so that nothing watching the store sees the book unfinished while its
  /// progress is still at its end.
  Future<void> _startAgain(_Session session) async {
    session.completed = false;
    await _seekInternal(session, 0);
    if (!session.finished) return;
    await _store.saveChapterListened(
      bookId: session.bookId,
      chapterId: session.timeline.lastChapterId,
      listened: false,
    );
    session.finished = false;
  }

  Future<void> _seekInternal(_Session session, int globalMs) async {
    final timeline = session.timeline;
    final from = session.globalMs;
    final destination = timeline.queuePositionAt(globalMs);
    final watch = onTiming == null ? null : (Stopwatch()..start());
    await _engine.seek(destination);
    if (watch != null) {
      onTiming!(
        destination.itemIndex == session.position.itemIndex
            ? 'seek'
            : 'seek.item',
        watch.elapsed,
      );
    }
    session.position = destination;
    session.landing = destination;
    await _saveProgress(session, session.tracker.onSeek(destination));
    await _saveSession(
      session.recorder.onSeek(
        fromGlobalMs: from,
        toGlobalMs: timeline.globalOfQueue(destination),
      ),
    );
  }

  /// The engine's [reported] position, or where it was last sent if [reported] falls just short of
  /// that. See [seekLandingTolerance].
  ///
  /// The destination is kept until the next seek or load rather than cleared once passed. Playback
  /// only moves forwards from it, so nothing else reports a position just short of it, and a stale
  /// sample from before a backwards seek cannot clear it early.
  QueuePosition _settle(_Session session, QueuePosition reported) {
    final timeline = session.timeline;
    final shortBy =
        timeline.globalOfQueue(session.landing) -
        timeline.globalOfQueue(reported);
    return shortBy > 0 && shortBy <= seekLandingTolerance.inMilliseconds
        ? session.landing
        : reported;
  }

  /// §4.5: the engine reports that queue item [itemIndex] lasts [durationMs], which refines the book
  /// when it replaces an estimate.
  ///
  /// Only an item that plays its whole file says how long the file is. An item clipped at its end
  /// reports the clip it was asked to play. One clipped only at its start reports what is left of
  /// the file after the clip, from which the file's length could be worked out, but only by trusting
  /// every backend to clip the same way, which spike (b) never measured; a wrong figure would be
  /// stored as exact and never corrected. Clipped items are ignored.
  ///
  /// Nothing changes for a file whose duration is already exact, for a report within
  /// [durationRefinementThreshold] of the estimate, or for one the book's layout cannot fit.
  ///
  /// The engine's position and the last seek's destination stay as they are, in queue coordinates.
  /// The refinement moves no item within the engine, only where items fall in global time, so the
  /// same queue position is the same audio before and after: the listener's chapter position
  /// carries over, global positions from the refined file on shift, and [_settle] still compares
  /// what the engine reports with where it was sent. Nothing needs reloading either, because a
  /// whole-file item is loaded without an end, so the engine was never limited to the estimate.
  Future<void> _learnDuration(
    _Session session,
    int itemIndex,
    int durationMs,
  ) async {
    final before = session.timeline;
    if (itemIndex < 0 || itemIndex >= before.queue.length) return;
    final item = before.queue[itemIndex];
    if (!item.startsAtFileStart || !item.endsAtFileEnd) return;
    final file = before.file(item.fileId);
    final difference = (durationMs - file.durationMs).abs();
    if (!file.durationIsEstimate ||
        difference < durationRefinementThreshold.inMilliseconds) {
      return;
    }

    final Timeline after;
    try {
      after = before.withLearnedDuration(file.id, durationMs);
    } on InvalidTimelineException {
      // The stored layout ends a segment beyond what the file turned out to hold. Stored, the
      // duration would leave the book unable to load, so the estimate stands; playback reaches the
      // end of the file a little sooner than the Timeline expects, and moves on.
      return;
    }

    session.timeline = after;
    session.tracker.updateTimeline(after);
    session.recorder.updateTimeline(after);
    final pinned = session.sleepChapterEndMs;
    if (pinned != null) {
      session.sleepChapterEndMs = _entryEndAfterRefinement(
        before,
        after,
        pinned,
      );
    }
    if (session.completed) {
      // A book played to its end stays at its end, wherever the end now is.
      session.position = after.queuePositionAt(after.totalDurationMs);
    }
    await _store.saveLearnedDuration(
      bookId: session.bookId,
      fileId: file.id,
      durationMs: durationMs,
    );
    await _applySleepTimer(session);
    _publish();
  }

  /// Where the navigation entry that ends at [endMs] in [before] ends in [after].
  ///
  /// The entry is found again by its start, taken as a chapter position, because a refinement
  /// leaves that the same place in the book, whereas the entry's end in global time is exactly what
  /// a refinement moves.
  static int _entryEndAfterRefinement(
    Timeline before,
    Timeline after,
    int endMs,
  ) {
    // Entries are never empty, so the millisecond before an entry's end is inside it.
    final entry = before.navigationEntryAt(endMs - 1);
    final start = before.chapterPositionAt(entry.startMs);
    return after.navigationEntryAt(after.globalOf(start)).endMs;
  }

  /// Resolves the file being played again and reloads at the current position. Returns whether it
  /// worked.
  ///
  /// §6.3's one transparent recovery. It re-resolves what failed — the item the engine is on — and
  /// offers the rest as [_resolve] always does, so a book of a hundred chapters is not resolved
  /// from end to end because one URL expired.
  Future<bool> _reload(_Session session, {required bool refresh}) async {
    final watch = onTiming == null ? null : (Stopwatch()..start());
    try {
      final items = await _resolve(
        session.timeline,
        refresh: refresh,
        startAt: session.position,
      );
      session.landing = session.position;
      await _engine.load(items, startAt: session.position);
      await _engine.setSpeed(session.speed);
      await _engine.setVolume(session.volume);
      if (session.playing) await _engine.play();
      if (watch != null) onTiming!('reload', watch.elapsed);
      unawaited(_resolveTheRest(session, items));
      return true;
    } catch (error) {
      await _fail(session, error);
      return false;
    }
  }

  Future<void> _fail(_Session session, Object error) async {
    if (session.playing) {
      session.playing = false;
      session.pausedAt = _clock.now();
      _sleepTimer.onPaused();
      await _saveProgress(session, session.tracker.onPause());
      await _saveSession(session.recorder.onStop(session.globalMs));
    }
    session.error = error;
    _publish();
  }

  Future<void> _applySleepTimer(
    _Session session, {
    bool evenWhenPaused = false,
  }) async {
    if (!_sleepTimer.isActive || (!session.playing && !evenWhenPaused)) return;
    final global = session.globalMs;
    // A book opened while a timer runs has no chapter pinned yet, so it takes the one playing now.
    final chapterEnd = session.sleepChapterEndMs ??= session.timeline
        .navigationEntryAt(global)
        .endMs;
    final state = _sleepTimer.poll(
      chapterRemaining: Duration(milliseconds: chapterEnd - global),
      speed: session.speed,
    );
    switch (state) {
      case SleepTimerRunning(:final volume):
        _sleepState = state;
        await _setVolume(session, volume);
      case SleepTimerExpired():
        session.sleepChapterEndMs = null;
        _sleepState = const SleepTimerOff();
        await _pauseInternal();
        await _setVolume(session, 1.0);
      case SleepTimerOff():
        _sleepState = state;
    }
  }

  /// Makes the chapter playing now the one an end-of-chapter sleep timer waits for.
  ///
  /// Called when a timer is set and when the listener moves playback themselves, but not as
  /// playback crosses into the next chapter on its own: that crossing is what the timer waits for.
  /// Measured against whichever chapter is playing, the goal would move on at every chapter start
  /// and the timer would never run out. Nor is it called for the rewind on resuming, which may step
  /// back over a chapter start without the listener choosing that chapter.
  void _pinSleepChapter(_Session session) {
    session.sleepChapterEndMs = session.timeline
        .navigationEntryAt(session.globalMs)
        .endMs;
  }

  Future<void> _setVolume(_Session session, double volume) async {
    if (volume == session.volume) return;
    await _engine.setVolume(volume);
    session.volume = volume;
  }

  Future<void> _closeSession() async {
    final session = _session;
    if (session == null) return;
    await _pauseInternal();
    _session = null;
  }

  /// The queue made playable, with the item at [startAt] resolved and the rest left to the engine.
  ///
  /// The file the listener is about to hear is resolved here, so that a source that refuses is a
  /// failure the player shows before it claims to have opened the book, and so that §6.3's
  /// re-resolve after a stream error really re-resolves what failed. Every other file is offered
  /// as it stands: [MediaResolver.resolveIfOnHand] answers for the ones that cost nothing — which
  /// for a local book is all of them, so nothing about local playback changes — and the ones it
  /// does not answer for are handed over unresolved, to be resolved when the engine opens them.
  ///
  /// A file used by several items is resolved once, and the items share the answer.
  Future<List<EngineItem>> _resolve(
    Timeline timeline, {
    required bool refresh,
    required QueuePosition startAt,
  }) async {
    final queue = timeline.queue;
    final start = startAt.itemIndex.clamp(0, queue.length - 1);
    final resolved = <int, ResolvedMedia>{};
    resolved[queue[start].fileId] = await _resolver.resolve(
      queue[start].fileId,
      refresh: refresh,
    );
    final asked = <int>{queue[start].fileId};
    final items = <EngineItem>[];
    for (final item in queue) {
      if (asked.add(item.fileId)) {
        final onHand = await _resolver.resolveIfOnHand(item.fileId);
        if (onHand != null) resolved[item.fileId] = onHand;
      }
      items.add(
        EngineItem(
          item: item,
          media: resolved[item.fileId],
          resolve: () => _resolver.resolve(item.fileId, refresh: refresh),
        ),
      );
    }
    return items;
  }

  /// Resolves, one at a time and after playback has started, the files the load left unresolved.
  ///
  /// Nothing waits for this: it is what makes jumping to a chapter halfway through a streamed book
  /// as quick as playing the next one, because by the time anybody jumps the resolver is already
  /// holding the answer. It stops as soon as the book it was started for is no longer the open one,
  /// and a file that will not resolve is left for the engine to fail over when it is really played.
  Future<void> _resolveTheRest(_Session session, List<EngineItem> items) async {
    final done = <int>{};
    for (final item in items) {
      if (!identical(_session, session)) return;
      if (item.media != null || !done.add(item.item.fileId)) continue;
      try {
        await item.resolve();
      } catch (_) {
        // Resolving ahead is a convenience. A file that cannot be resolved now will be reported
        // when the listener asks for it, by the same path as any other stream error.
      }
    }
  }

  /// Saves [position], recording its chapter as listened when the position has reached the chapter's
  /// threshold (§4.5). The threshold is judged against the Timeline being played, so a duration
  /// refined mid-book moves it with the chapter.
  Future<void> _saveProgress(
    _Session session,
    ChapterPosition? position,
  ) async {
    if (position == null) return;
    final timeline = session.timeline;
    final listened = timeline.isChapterListened(position);
    await _store.saveProgress(
      bookId: session.bookId,
      position: position,
      globalMs: timeline.globalOf(position),
      listened: listened,
    );
    if (listened && position.chapterId == timeline.lastChapterId) {
      session.finished = true;
    }
  }

  Future<void> _saveSession(ListeningSession? listening) async {
    if (listening != null) await _store.saveSession(listening);
  }

  void _publish() {
    final session = _session;
    if (session == null) {
      _emit(const PlayerIdle());
      return;
    }
    final error = session.error;
    if (error != null) {
      _emit(PlayerFailed(bookId: session.bookId, error: error));
      return;
    }
    final timeline = session.timeline;
    final global = session.globalMs;
    _emit(
      PlayerReady(
        bookId: session.bookId,
        position: timeline.chapterPositionAt(global),
        globalMs: global,
        totalMs: timeline.totalDurationMs,
        entry: timeline.navigationEntryAt(global),
        navigation: timeline.navigation,
        playing: session.playing,
        buffering: session.buffering,
        speed: session.speed,
        sleepTimer: _sleepTimer.isActive ? _sleepState : const SleepTimerOff(),
        finished: session.finished,
      ),
    );
  }

  void _emit(PlayerState state) {
    _state = state;
    if (!_states.isClosed) _states.add(state);
  }

  /// An event handler threw something it did not anticipate. Surface it rather than lose it.
  void _onUnexpected(Object error) {
    final session = _session;
    if (session == null) return;
    session.error = error;
    _publish();
  }

  /// Runs [task] after everything already queued, and keeps the queue alive if [task] fails.
  Future<T> _serial<T>(Future<T> Function() task) {
    final result = _tail.then((_) => task());
    _tail = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }
}

final class _Session {
  _Session({
    required this.bookId,
    required this.timeline,
    required this.tracker,
    required this.recorder,
    required this.speed,
    required this.position,
    required this.finished,
  }) : landing = position;

  final int bookId;

  /// Replaced when a duration the engine learns refines the book (§4.5).
  Timeline timeline;
  final ProgressTracker tracker;
  final ListeningSessionRecorder recorder;
  double speed;
  QueuePosition position;

  /// Where the engine was last sent, by the load that opened the book, a reload or a seek. See
  /// [PlaybackCoordinator.seekLandingTolerance].
  QueuePosition landing;
  bool playing = false;
  bool buffering = false;

  /// Whether the engine has played the whole queue to its end. Positions it reports afterwards are
  /// ignored (spike (b)), and playing starts the book again.
  bool completed = false;

  /// Whether the book is finished as the store has it (§4.5). See [PlayerReady.finished].
  bool finished;

  /// Whether an interruption paused playback and nobody has pressed play or pause since, so that
  /// the interruption's end may start it again.
  bool interrupted = false;

  /// Where the chapter an end-of-chapter sleep timer waits for ends, in book-global time. See
  /// [PlaybackCoordinator._pinSleepChapter].
  int? sleepChapterEndMs;

  /// Whether the one automatic recovery §6.3 allows has been spent since the last user action.
  bool retried = false;
  double volume = 1.0;
  DateTime? pausedAt;
  Object? error;

  int get globalMs => timeline.globalOfQueue(position);
}
