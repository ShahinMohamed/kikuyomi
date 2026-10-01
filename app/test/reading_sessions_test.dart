// When someone was reading, for History.
//
// The hard part is not measuring; it is deciding that reading has stopped. A chapter left open on
// a table must not be recorded as an afternoon of reading, and a reader who is perfectly still for
// a minute over a page must not be cut off. These hold that line.

import 'package:flutter_test/flutter_test.dart';
import 'package:kikuyomi/src/reading/reading_sessions.dart';
import 'package:kikuyomi_test_support/kikuyomi_test_support.dart';

void main() {
  late FakeClock clock;
  late ReadingSessionRecorder recorder;

  setUp(() {
    clock = FakeClock(DateTime.utc(2026, 9, 28, 21));
    recorder = ReadingSessionRecorder(clock: clock);
  });

  test('a stretch runs from opening a chapter to the last scroll', () {
    recorder.start(7);
    clock.advance(const Duration(minutes: 20));
    recorder.alive();

    final stretch = recorder.stop()!;

    expect(stretch.chapterId, 7);
    expect(stretch.startedAt, DateTime.utc(2026, 9, 28, 21));
    expect(stretch.endedAt, DateTime.utc(2026, 9, 28, 21, 20));
  });

  test('a checkpoint is the stretch so far, and the stretch goes on', () {
    recorder.start(7);
    clock.advance(const Duration(minutes: 5));
    recorder.alive();

    final sofar = recorder.checkpoint()!;
    expect(sofar.endedAt, DateTime.utc(2026, 9, 28, 21, 5));
    expect(recorder.isRecording, isTrue);

    // And it names the same beginning the stop will, so the store moves one entry forward.
    clock.advance(const Duration(minutes: 5));
    recorder.alive();
    final last = recorder.stop()!;
    expect(last.startedAt, sofar.startedAt);
    expect(last.endedAt, DateTime.utc(2026, 9, 28, 21, 10));
  });

  test('a checkpoint does not count a book left open either', () {
    // The same line a stop holds: twenty minutes after the last scroll is three minutes of
    // reading and seventeen of dinner, whether it is saved now or later.
    recorder.start(7);
    clock.advance(const Duration(minutes: 20));
    expect(recorder.checkpoint()!.endedAt, DateTime.utc(2026, 9, 28, 21, 3));
  });

  test('a chapter still on the screen keeps being read, within reason', () {
    // Someone reading a page without scrolling is still reading.
    recorder.start(7);
    clock.advance(const Duration(minutes: 2));

    expect(recorder.stop()!.endedAt, DateTime.utc(2026, 9, 28, 21, 2));
  });

  test('a book left open is not read all afternoon', () {
    // The whole point. Four hours on the table is three minutes of reading and no more.
    recorder.start(7);
    clock.advance(const Duration(hours: 4));

    final stretch = recorder.stop()!;

    expect(stretch.endedAt, DateTime.utc(2026, 9, 28, 21, 3));
    expect(stretch.endedAt.difference(stretch.startedAt), readingIdleGrace);
  });

  test('scrolling keeps a long chapter alive', () {
    recorder.start(7);
    for (var page = 0; page < 30; page++) {
      clock.advance(const Duration(minutes: 2));
      recorder.alive();
    }

    expect(
      recorder.stop()!.endedAt.difference(DateTime.utc(2026, 9, 28, 21)),
      const Duration(minutes: 60),
    );
  });

  test('moving to the next chapter closes the one before', () {
    recorder.start(7);
    clock.advance(const Duration(minutes: 10));
    recorder.alive();

    final finished = recorder.start(8)!;

    expect(finished.chapterId, 7);
    expect(finished.endedAt, DateTime.utc(2026, 9, 28, 21, 10));
    expect(recorder.isRecording, isTrue);
  });

  test('a chapter opened and left at once is not a stretch of reading', () {
    // Someone hunting for their place, not reading.
    recorder.start(7);

    expect(recorder.stop(), isNull);
  });

  test('stopping twice records nothing the second time', () {
    recorder.start(7);
    clock.advance(const Duration(minutes: 5));

    expect(recorder.stop(), isNotNull);
    expect(recorder.stop(), isNull);
    expect(recorder.isRecording, isFalse);
  });
}
