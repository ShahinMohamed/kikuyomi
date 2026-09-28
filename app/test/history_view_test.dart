// The History screen's own wiring, without a database or a covers folder: what it says about a
// stretch of listening, and what it offers to do with one.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikuyomi/src/history/listening_history_days.dart';
import 'package:kikuyomi/src/history_view.dart';
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
  _reading();

  setUp(() => _nextId = 0);

  late List<HistoryEntry> opened;
  late List<HistoryEntry> removed;

  setUp(() {
    opened = [];
    removed = [];
  });

  DateTime local(int day, int hour, [int minute = 0]) =>
      DateTime(2026, 9, day, hour, minute);

  final now = local(25, 14);

  Future<void> pumpView(WidgetTester tester, List<HistoryEntry> entries) =>
      tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HistoryView(
              days: groupHistoryByDay(entries, now: now),
              // No covers folder in a widget test; the placeholder is what a book without one shows
              // anyway, so the rows draw the same.
              coverOf: (_) => null,
              onOpenBook: opened.add,
              onRemove: removed.add,
            ),
          ),
        ),
      );

  testWidgets('with nothing heard, says so', (tester) async {
    await pumpView(tester, const []);

    expect(find.text('Nothing here yet'), findsOneWidget);
  });

  testWidgets('shows the book, the chapter and when it was heard', (
    tester,
  ) async {
    await pumpView(tester, [
      entry(startedAt: local(25, 20, 44), listened: const Duration(minutes: 8)),
    ]);

    expect(find.text('Moby-Dick'), findsOneWidget);
    expect(find.text('Loomings'), findsOneWidget);
    expect(find.textContaining('20:44'), findsOneWidget);
    expect(find.textContaining('8 m'), findsWidgets);
  });

  testWidgets('heads each day, with what it came to', (tester) async {
    await pumpView(tester, [
      entry(startedAt: local(25, 9), listened: const Duration(minutes: 20)),
      entry(startedAt: local(25, 11), listened: const Duration(minutes: 25)),
      entry(startedAt: local(23, 9), listened: const Duration(minutes: 5)),
    ]);

    expect(find.text('Today'), findsOneWidget);
    expect(find.text('23 September'), findsOneWidget);
    expect(find.text('45 m'), findsOneWidget);
  });

  testWidgets('says something for a chapter that has been purged', (
    tester,
  ) async {
    // The row must still be there: the chapter went, the listener's evening did not.
    await pumpView(tester, [
      entry(startedAt: local(25, 9), chapterTitle: null),
    ]);

    expect(find.text('Moby-Dick'), findsOneWidget);
    expect(find.textContaining('no longer listed'), findsOneWidget);
  });

  testWidgets('shows the speed only when it was not the ordinary one', (
    tester,
  ) async {
    await pumpView(tester, [entry(startedAt: local(25, 9), speed: 1.5)]);
    expect(find.textContaining('1.5x'), findsOneWidget);

    await pumpView(tester, [entry(startedAt: local(25, 9))]);
    expect(find.textContaining('x'), findsNothing);
  });

  testWidgets('tapping a row opens its book', (tester) async {
    await pumpView(tester, [entry(bookId: 42, startedAt: local(25, 9))]);

    await tester.tap(find.text('Moby-Dick'));
    await tester.pumpAndSettle();

    expect(opened.single.bookId, 42);
  });

  testWidgets('every row offers to be forgotten', (tester) async {
    await pumpView(tester, [
      entry(startedAt: local(25, 9)),
      entry(startedAt: local(24, 9)),
    ]);

    expect(find.byTooltip('Remove from history'), findsNWidgets(2));

    await tester.tap(find.byTooltip('Remove from history').first);
    await tester.pumpAndSettle();

    expect(removed, hasLength(1));
  });
}

/// History shows reading beside listening (ADR-0019).
void _reading() {
  HistoryEntry read({
    required DateTime startedAt,
    Duration spent = const Duration(minutes: 25),
  }) => HistoryEntry(
    sessionId: ++_nextId,
    kind: SourceKind.text,
    bookId: 2,
    bookTitle: 'A Novel',
    chapterTitle: 'Chapter One',
    startedAt: startedAt,
    endedAt: startedAt.add(spent),
  );

  Future<void> pump(WidgetTester tester, List<HistoryEntry> entries) =>
      tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HistoryView(
              days: groupHistoryByDay(entries, now: DateTime(2026, 9, 28, 23)),
              coverOf: (_) => null,
              onOpenBook: (_) {},
              onRemove: (_) {},
            ),
          ),
        ),
      );

  group('a stretch of reading', () {
    testWidgets('says how long it was, and nothing about speed', (
      tester,
    ) async {
      await pump(tester, [read(startedAt: DateTime(2026, 9, 28, 21))]);

      expect(find.text('A Novel'), findsOneWidget);
      expect(find.text('Chapter One'), findsOneWidget);
      expect(find.textContaining('25 m'), findsWidgets);
      expect(find.textContaining('x'), findsNothing);
    });

    testWidgets('counts towards the day it was read in', (tester) async {
      await pump(tester, [
        read(startedAt: DateTime(2026, 9, 28, 21)),
        entry(
          startedAt: DateTime(2026, 9, 28, 20),
          listened: const Duration(minutes: 35),
        ),
      ]);

      // An evening of reading and listening is one evening, and one total.
      expect(find.textContaining('1 h'), findsOneWidget);
    });
  });
}
