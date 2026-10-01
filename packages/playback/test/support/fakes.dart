import 'dart:async';

import 'package:kikuyomi_domain/kikuyomi_domain.dart';
import 'package:kikuyomi_playback/kikuyomi_playback.dart';

/// An engine that records what it was asked to do and emits whatever a test tells it to.
final class FakeEngine implements PlaybackEngine {
  final calls = <String>[];
  final _events = StreamController<EngineEvent>.broadcast();

  List<EngineItem> loaded = const [];
  QueuePosition? loadedAt;
  QueuePosition? lastSeek;
  double speed = 1.0;
  double volume = 1.0;
  bool playing = false;

  /// Thrown by the next [load] and then forgotten: a player that cannot open one book's audio, as
  /// a dead URL, a refused host or a format the device will not play produces.
  ///
  /// Nothing is recorded as loaded when it throws, which is what the real adapter does — it empties
  /// its queue and stops the player, so that a failure cannot follow the listener to the next book.
  Object? nextLoadFailure;

  @override
  Future<void> load(
    List<EngineItem> items, {
    QueuePosition startAt = const QueuePosition(itemIndex: 0, offsetMs: 0),
  }) async {
    calls.add('load');
    final failure = nextLoadFailure;
    if (failure != null) {
      nextLoadFailure = null;
      throw failure;
    }
    loaded = items;
    loadedAt = startAt;
  }

  @override
  Future<void> play() async {
    calls.add('play');
    playing = true;
  }

  @override
  Future<void> pause() async {
    calls.add('pause');
    playing = false;
  }

  @override
  Future<void> seek(QueuePosition position) async {
    calls.add('seek');
    lastSeek = position;
  }

  @override
  Future<void> setSpeed(double speed) async => this.speed = speed;

  @override
  Future<void> setVolume(double volume) async => this.volume = volume;

  @override
  Stream<EngineEvent> get events => _events.stream;

  @override
  Future<void> dispose() => _events.close();

  void emit(EngineEvent event) => _events.add(event);
}

/// Resolves every file to a local path, or fails for the files a test names.
///
/// By default every file is on the device, as a local book's is, so [resolveIfOnHand] answers for
/// all of them. A test that wants a streamed book names its files in [streamed]: those are resolved
/// only when they are really asked for, which is what the coordinator leaves to the engine.
final class FakeResolver implements MediaResolver {
  final requests = <({int fileId, bool refresh})>[];
  final failing = <int>{};
  final streamed = <int>{};

  @override
  Future<ResolvedMedia> resolve(int fileId, {bool refresh = false}) async {
    requests.add((fileId: fileId, refresh: refresh));
    if (failing.contains(fileId)) throw StateError('cannot resolve $fileId');
    return ResolvedMedia(uri: Uri.file('/books/$fileId.m4a'));
  }

  @override
  Future<ResolvedMedia?> resolveIfOnHand(int fileId) async {
    if (streamed.contains(fileId)) return null;
    try {
      return await resolve(fileId);
    } on StateError {
      return null;
    }
  }
}

/// Records everything the coordinator persists.
final class FakeStore implements PlaybackStore {
  final progress =
      <({int bookId, ChapterPosition position, int globalMs, bool listened})>[];
  final listened = <({int bookId, int chapterId, bool listened})>[];
  final sessions = <ListeningSession>[];
  final speeds = <({int bookId, double speed})>[];
  final durations = <({int bookId, int fileId, int durationMs})>[];

  /// Progress and listened-state writes in the order they were made, by method name.
  final writes = <String>[];

  @override
  Future<void> saveProgress({
    required int bookId,
    required ChapterPosition position,
    required int globalMs,
    required bool listened,
  }) async {
    writes.add('saveProgress');
    progress.add((
      bookId: bookId,
      position: position,
      globalMs: globalMs,
      listened: listened,
    ));
  }

  @override
  Future<void> saveChapterListened({
    required int bookId,
    required int chapterId,
    required bool listened,
  }) async {
    writes.add('saveChapterListened');
    this.listened.add((
      bookId: bookId,
      chapterId: chapterId,
      listened: listened,
    ));
  }

  /// Behaves as the real store does: a session already saved, recognised by its book and the moment
  /// it began, is replaced by the later save rather than added beside it. A fake that appended would
  /// let a test pass on a coordinator that wrote a checkpoint the real store then duplicated.
  @override
  Future<void> saveSession(ListeningSession session) async {
    final index = sessions.indexWhere(
      (s) => s.bookId == session.bookId && s.startedAt == session.startedAt,
    );
    if (index < 0) {
      sessions.add(session);
    } else {
      sessions[index] = session;
    }
  }

  @override
  Future<void> saveSpeed({required int bookId, required double speed}) async =>
      speeds.add((bookId: bookId, speed: speed));

  @override
  Future<void> saveLearnedDuration({
    required int bookId,
    required int fileId,
    required int durationMs,
  }) async =>
      durations.add((bookId: bookId, fileId: fileId, durationMs: durationMs));
}
