import 'package:kikuyomi_domain/kikuyomi_domain.dart';
import 'package:kikuyomi_playback/kikuyomi_playback.dart';
import 'package:kikuyomi_test_support/kikuyomi_test_support.dart';
import 'package:test/test.dart';

const s = 1000;

Duration sec(int n) => Duration(seconds: n);

/// Two chapters of 300 s in one 600 s file.
Timeline book() => Timeline.build(
  files: const [TimelineFile(id: 1, durationMs: 600 * s)],
  chapters: [
    TimelineChapter(
      id: 1,
      title: 'One',
      segments: const [TimelineSegment(fileId: 1, endMs: 300 * s)],
    ),
    TimelineChapter(
      id: 2,
      title: 'Two',
      segments: const [TimelineSegment(fileId: 1, startMs: 300 * s)],
    ),
  ],
);

void main() {
  late FakeClock clock;
  late ListeningSessionRecorder recorder;

  setUp(() {
    clock = FakeClock();
    recorder = ListeningSessionRecorder(
      bookId: 42,
      timeline: book(),
      clock: clock,
    );
  });

  test('a play-to-pause span becomes one session', () {
    final started = clock.now();
    recorder.onPlay(globalMs: 0, speed: 1.0);
    clock.advance(const Duration(minutes: 4));
    final session = recorder.onStop(240 * s)!;

    expect(session.bookId, 42);
    expect(session.chapterId, 1);
    expect(session.startedAt, started);
    expect(session.listened, const Duration(minutes: 4));
    expect(session.startGlobalMs, 0);
    expect(session.endGlobalMs, 240 * s);
    expect(session.speed, 1.0);
    expect(recorder.isRecording, isFalse);
  });

  group('checkpoint', () {
    test('reports the session under way without ending it', () {
      final started = clock.now();
      recorder.onPlay(globalMs: 0, speed: 1.0);
      clock.advance(const Duration(minutes: 2));

      final sofar = recorder.checkpoint(120 * s)!;
      expect(sofar.startedAt, started);
      expect(sofar.endGlobalMs, 120 * s);
      expect(sofar.listened, const Duration(minutes: 2));
      // Still going: a checkpoint is a look, not a pause.
      expect(recorder.isRecording, isTrue);
    });

    test('names the same session the stop does, so the store moves one row forward', () {
      // This is what makes a checkpoint safe to write. The store recognises a session by its book
      // and the moment it began; if the stop began somewhere else, the checkpoint and the stop
      // would be two rows for one stretch of listening, and History would count it twice.
      recorder.onPlay(globalMs: 0, speed: 1.0);
      clock.advance(const Duration(minutes: 1));
      final early = recorder.checkpoint(60 * s)!;
      clock.advance(const Duration(minutes: 1));
      final later = recorder.checkpoint(120 * s)!;
      clock.advance(const Duration(minutes: 1));
      final last = recorder.onStop(180 * s)!;

      expect(later.startedAt, early.startedAt);
      expect(last.startedAt, early.startedAt);
      expect(last.endGlobalMs, 180 * s);
    });

    test('says nothing for a session too short to keep', () {
      // A checkpoint written for a three-second scrub would be a row the stop then refuses to
      // keep, and nothing would ever take it away again.
      recorder.onPlay(globalMs: 0, speed: 1.0);
      clock.advance(const Duration(seconds: 3));
      expect(recorder.checkpoint(3 * s), isNull);
    });

    test('says nothing while nothing is playing', () {
      expect(recorder.checkpoint(10 * s), isNull);
    });
  });

  test('nothing is recorded without playback', () {
    expect(recorder.onStop(10 * s), isNull);
    expect(recorder.onPosition(10 * s), isNull);
    expect(recorder.onSeek(fromGlobalMs: 0, toGlobalMs: 10 * s), isNull);
    expect(recorder.onSpeedChanged(globalMs: 0, speed: 2), isNull);
  });

  test('play while already recording does not restart the session', () {
    recorder.onPlay(globalMs: 0, speed: 1.0);
    clock.advance(sec(10));
    recorder.onPlay(globalMs: 99 * s, speed: 1.0);
    clock.advance(sec(10));
    final session = recorder.onStop(20 * s)!;
    expect(session.startGlobalMs, 0);
    expect(session.listened, sec(20));
  });

  group('splits', () {
    test(
      'at a chapter boundary, so each row names the chapter listened to',
      () {
        recorder.onPlay(globalMs: 290 * s, speed: 1.0);
        clock.advance(sec(10));
        final first = recorder.onPosition(300 * s + 500)!;
        clock.advance(sec(20));
        final second = recorder.onStop(320 * s + 500)!;

        expect(first.chapterId, 1);
        expect(first.startGlobalMs, 290 * s);
        expect(first.endGlobalMs, 300 * s);
        expect(first.listened, sec(10));

        expect(second.chapterId, 2);
        expect(second.startGlobalMs, 300 * s);
        expect(second.listened, sec(20));
      },
    );

    test('on a speed change, so each row has one true speed', () {
      recorder.onPlay(globalMs: 0, speed: 1.0);
      clock.advance(sec(60));
      final slow = recorder.onSpeedChanged(globalMs: 60 * s, speed: 1.5)!;
      clock.advance(sec(40));
      final fast = recorder.onStop(120 * s)!;

      expect(slow.speed, 1.0);
      expect(slow.coveredMs, 60 * s);
      expect(fast.speed, 1.5);
      expect(fast.listened, sec(40));
      expect(fast.coveredMs, 60 * s, reason: '40 s at 1.5x covers 60 s');
    });

    test('not when the speed is set to what it already was', () {
      recorder.onPlay(globalMs: 0, speed: 1.0);
      clock.advance(sec(60));
      expect(recorder.onSpeedChanged(globalMs: 60 * s, speed: 1.0), isNull);
      expect(recorder.onStop(90 * s)!.listened, sec(60));
    });

    test('on a seek, so no row brackets a jump', () {
      recorder.onPlay(globalMs: 10 * s, speed: 1.0);
      clock.advance(sec(30));
      final before = recorder.onSeek(fromGlobalMs: 40 * s, toGlobalMs: 5 * s)!;
      clock.advance(sec(20));
      final after = recorder.onStop(25 * s)!;

      expect(before.startGlobalMs, 10 * s);
      expect(before.endGlobalMs, 40 * s);
      expect(after.startGlobalMs, 5 * s);
      expect(after.endGlobalMs, 25 * s);
    });

    test('into the chapter a seek lands in', () {
      recorder.onPlay(globalMs: 10 * s, speed: 1.0);
      clock.advance(sec(30));
      recorder.onSeek(fromGlobalMs: 40 * s, toGlobalMs: 400 * s);
      clock.advance(sec(30));
      expect(recorder.onStop(430 * s)!.chapterId, 2);
    });

    test(
      'not when a refined duration moves the chapter, which keeps its start',
      () {
        Timeline twoFiles({required int firstFileMs, bool estimate = false}) =>
            Timeline.build(
              files: [
                TimelineFile(
                  id: 1,
                  durationMs: firstFileMs,
                  durationIsEstimate: estimate,
                ),
                const TimelineFile(id: 2, durationMs: 300 * s),
              ],
              chapters: [
                TimelineChapter(
                  id: 1,
                  title: 'One',
                  segments: const [TimelineSegment(fileId: 1)],
                ),
                TimelineChapter(
                  id: 2,
                  title: 'Two',
                  segments: const [TimelineSegment(fileId: 2)],
                ),
              ],
            );
        recorder = ListeningSessionRecorder(
          bookId: 1,
          timeline: twoFiles(firstFileMs: 300 * s, estimate: true),
          clock: clock,
        );

        recorder.onPlay(globalMs: 310 * s, speed: 1.0);
        clock.advance(sec(30));
        recorder.updateTimeline(twoFiles(firstFileMs: 312 * s));
        final session = recorder.onStop(352 * s)!;

        expect(session.chapterId, 2);
        expect(session.startGlobalMs, 322 * s);
        expect(session.endGlobalMs, 352 * s);
      },
    );

    test('without losing any time listened', () {
      recorder.onPlay(globalMs: 0, speed: 1.0);
      final sessions = <ListeningSession?>[];
      clock.advance(sec(30));
      sessions.add(recorder.onSpeedChanged(globalMs: 30 * s, speed: 2.0));
      clock.advance(sec(30));
      sessions.add(recorder.onSeek(fromGlobalMs: 90 * s, toGlobalMs: 200 * s));
      clock.advance(sec(30));
      sessions.add(recorder.onStop(260 * s));

      final total = sessions.nonNulls.fold(
        Duration.zero,
        (sum, session) => sum + session.listened,
      );
      expect(total, sec(90));
    });
  });

  group('short sessions', () {
    test('are dropped', () {
      recorder.onPlay(globalMs: 0, speed: 1.0);
      clock.advance(sec(4));
      expect(recorder.onStop(4 * s), isNull);
    });

    test('are dropped when a quick scrub splits them off', () {
      recorder.onPlay(globalMs: 0, speed: 1.0);
      clock.advance(sec(2));
      expect(recorder.onSeek(fromGlobalMs: 2 * s, toGlobalMs: 100 * s), isNull);
      clock.advance(sec(30));
      final session = recorder.onStop(130 * s)!;
      expect(session.startGlobalMs, 100 * s);
    });

    test('are kept when the minimum is zero', () {
      recorder = ListeningSessionRecorder(
        bookId: 1,
        timeline: book(),
        clock: clock,
        minimumLength: Duration.zero,
      );
      recorder.onPlay(globalMs: 0, speed: 1.0);
      expect(recorder.onStop(0)!.listened, Duration.zero);
    });

    test('a negative minimum is rejected', () {
      expect(
        () => ListeningSessionRecorder(
          bookId: 1,
          timeline: book(),
          clock: clock,
          minimumLength: sec(-1),
        ),
        throwsArgumentError,
      );
    });
  });
}
