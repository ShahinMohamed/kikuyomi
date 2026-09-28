/// History as a screen reads it: what was listened to and what was read: newest first, under a heading per day (§6.4).
///
/// A pure function, because every interesting case here is a calendar one. "Today" and "Yesterday"
/// are relative to the listener's own midnight, not to a fixed number of hours, so a session at
/// 00:30 belongs to today and one at 23:30 the night before belongs to yesterday even though they
/// are an hour apart. Getting that wrong is the kind of thing nobody notices until they look at the
/// screen at one in the morning.
library;

import 'package:kikuyomi_data/kikuyomi_data.dart';

/// One day of listening, with its heading.
final class HistoryDay {
  const HistoryDay({
    required this.day,
    required this.label,
    required this.entries,
  });

  /// Local midnight at the start of the day.
  final DateTime day;

  /// What to put above it: `Today`, `Yesterday`, or the date written out.
  final String label;

  /// Its entries, newest first.
  final List<HistoryEntry> entries;

  /// Everything heard and read that day, added up.
  Duration get spent =>
      entries.fold(Duration.zero, (total, entry) => total + entry.spent);
}

/// [entries] grouped under a heading per day, newest day first.
///
/// [now] decides which day counts as today, and is passed in rather than read so the grouping can be
/// tested at one minute past midnight.
List<HistoryDay> groupHistoryByDay(
  List<HistoryEntry> entries, {
  required DateTime now,
}) {
  final byDay = <DateTime, List<HistoryEntry>>{};
  for (final entry in entries) {
    final at = entry.startedAt.toLocal();
    byDay.putIfAbsent(DateTime(at.year, at.month, at.day), () => []).add(entry);
  }

  final days = byDay.keys.toList()..sort((a, b) => b.compareTo(a));
  return [
    for (final day in days)
      HistoryDay(
        day: day,
        label: describeHistoryDay(day, now: now),
        // Newest first within the day. The query already orders them, and relying on that would make
        // this function's answer depend on its caller.
        entries: byDay[day]!
          ..sort((a, b) => b.startedAt.compareTo(a.startedAt)),
      ),
  ];
}

/// What to call [day]: `Today`, `Yesterday`, or the date written out.
String describeHistoryDay(DateTime day, {required DateTime now}) {
  final today = DateTime(now.year, now.month, now.day);
  final difference = today.difference(DateTime(day.year, day.month, day.day));
  if (difference.inDays == 0) return 'Today';
  if (difference.inDays == 1) return 'Yesterday';
  final year = day.year == today.year ? '' : ' ${day.year}';
  return '${day.day} ${_months[day.month - 1]}$year';
}

/// A time of day as a clock, for the line under an entry.
String formatTimeOfDay(DateTime at) {
  final local = at.toLocal();
  return '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
}

const _months = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];
