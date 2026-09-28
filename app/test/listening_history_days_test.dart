// Listening history grouped under a heading per day.
//
// Every interesting case is a calendar one. "Today" is relative to the listener's own midnight and
// not to a number of hours, so 00:30 and 23:30 the night before are an hour apart and belong to
// different days — the kind of thing nobody notices until they look at the screen at one in the
// morning.

import 'package:flutter_test/flutter_test.dart';
import 'package:kikuyomi/src/history/listening_history_days.dart';
import 'package:kikuyomi_data/kikuyomi_data.dart';
import 'package:kikuyomi_source_api/kikuyomi_source_api.dart' show SourceKind;

var _nextId = 0;

HistoryEntry entry({
  int bookId = 1,
  String title = 'Moby-Dick',
  String? chapterTitle = 'Loomings',
  required DateTime startedAt,
  Duration listened = const Duration(minutes: 10),
  double speed = 1,
}) {
  final id = ++_nextId;
  return HistoryEntry(
    sessionId: id,
    kind: SourceKind.audio,
    bookId: bookId,
    bookTitle: title,
    chapterTitle: chapterTitle,
    startedAt: startedAt,
    endedAt: startedAt.add(listened),
    startGlobalMs: 0,
    endGlobalMs: listened.inMilliseconds,
    speed: speed,
  );
}

void main() {
  setUp(() => _nextId = 0);

  // A local time, because the grouping is about the listener's own midnight.
  DateTime local(int day, int hour, [int minute = 0]) =>
      DateTime(2026, 9, day, hour, minute);

  final now = local(25, 14);

  group('grouping', () {
    test('puts a day under one heading', () {
      final days = groupHistoryByDay([
        entry(startedAt: local(25, 9)),
        entry(startedAt: local(25, 11)),
      ], now: now);

      expect(days, hasLength(1));
      expect(days.single.entries, hasLength(2));
    });

    test('newest day first', () {
      final days = groupHistoryByDay([
        entry(startedAt: local(23, 9)),
        entry(startedAt: local(25, 9)),
        entry(startedAt: local(24, 9)),
      ], now: now);

      expect([for (final day in days) day.day.day], [25, 24, 23]);
    });

    test('newest entry first within a day', () {
      final days = groupHistoryByDay([
        entry(startedAt: local(25, 9)),
        entry(startedAt: local(25, 13)),
        entry(startedAt: local(25, 11)),
      ], now: now);

      expect(
        [for (final e in days.single.entries) e.startedAt.hour],
        [13, 11, 9],
      );
    });

    test('adds up what a day came to', () {
      final days = groupHistoryByDay([
        entry(startedAt: local(25, 9), listened: const Duration(minutes: 20)),
        entry(startedAt: local(25, 11), listened: const Duration(minutes: 25)),
      ], now: now);

      expect(days.single.spent, const Duration(minutes: 45));
    });

    test('nothing heard is no days, not an empty day', () {
      expect(groupHistoryByDay(const [], now: now), isEmpty);
    });
  });

  group('what a day is called', () {
    test('today and yesterday', () {
      final days = groupHistoryByDay([
        entry(startedAt: local(25, 9)),
        entry(startedAt: local(24, 9)),
      ], now: now);

      expect(days.first.label, 'Today');
      expect(days.last.label, 'Yesterday');
    });

    test('half past midnight is today, not last night', () {
      // The case that catches a grouping written in hours rather than in days.
      expect(describeHistoryDay(local(25, 0), now: local(25, 0, 30)), 'Today');
    });

    test('half past eleven the night before is yesterday', () {
      // An hour earlier than the case above, and a different day.
      expect(
        describeHistoryDay(local(24, 23), now: local(25, 0, 30)),
        'Yesterday',
      );
    });

    test('anything older is the date', () {
      expect(describeHistoryDay(local(20, 9), now: now), '20 September');
    });

    test('and carries the year once it is not this one', () {
      expect(
        describeHistoryDay(DateTime(2025, 12, 31), now: now),
        '31 December 2025',
      );
    });
  });

  group('a time of day', () {
    test('is padded to a clock', () {
      expect(formatTimeOfDay(local(25, 9, 5)), '09:05');
      expect(formatTimeOfDay(local(25, 20, 44)), '20:44');
    });

    test('midnight reads as midnight rather than as nothing', () {
      expect(formatTimeOfDay(local(25, 0, 0)), '00:00');
    });
  });
}
