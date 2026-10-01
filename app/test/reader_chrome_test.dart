// The bar over a book being read: there when a chapter opens, gone on its own a moment later, gone
// as soon as reading starts, and back for a tap.
//
// The reported problem was that it never left. These hold the other side too: that it comes back
// when asked, and that it stays put for someone who could not see it go.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikuyomi/src/reading/reader_chrome.dart';

const hideAfter = Duration(seconds: 3);

late ReaderChromeControls controls;

Widget chrome({Object? revealKey, bool accessible = false}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(accessibleNavigation: accessible),
    child: ReaderChrome(
      revealKey: revealKey,
      hideAfter: hideAfter,
      appBar: AppBar(
        title: const Text('Chapter Four'),
        actions: [IconButton(icon: const Icon(Icons.toc), onPressed: () {})],
      ),
      builder: (context, given) {
        controls = given;
        return const Center(child: Text('The page'));
      },
    ),
  ),
);

/// Whether the bar is showing: on the screen and taking taps.
bool barShowing(WidgetTester tester) {
  final ignoring = tester
      .widgetList<IgnorePointer>(
        find.ancestor(
          of: find.text('Chapter Four'),
          matching: find.byType(IgnorePointer),
        ),
      )
      .any((w) => w.ignoring);
  return !ignoring;
}

void main() {
  testWidgets('shows when the chapter opens, and leaves on its own', (
    tester,
  ) async {
    await tester.pumpWidget(chrome());
    expect(barShowing(tester), isTrue);

    await tester.pump(hideAfter - const Duration(milliseconds: 100));
    expect(barShowing(tester), isTrue, reason: 'not before its time');

    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
    expect(barShowing(tester), isFalse);
  });

  testWidgets('leaves at once when the reader starts reading', (tester) async {
    await tester.pumpWidget(chrome());
    controls.hide();
    await tester.pumpAndSettle();
    expect(barShowing(tester), isFalse);
  });

  testWidgets('a tap brings it back, and it leaves again later', (
    tester,
  ) async {
    await tester.pumpWidget(chrome());
    controls.hide();
    await tester.pumpAndSettle();

    controls.toggle();
    await tester.pumpAndSettle();
    expect(barShowing(tester), isTrue);

    await tester.pump(hideAfter);
    await tester.pumpAndSettle();
    expect(barShowing(tester), isFalse);
  });

  testWidgets('a tap while it shows sends it away', (tester) async {
    await tester.pumpWidget(chrome());
    controls.toggle();
    await tester.pumpAndSettle();
    expect(barShowing(tester), isFalse);
  });

  testWidgets('a new chapter brings it back', (tester) async {
    await tester.pumpWidget(chrome(revealKey: 1));
    controls.hide();
    await tester.pumpAndSettle();

    await tester.pumpWidget(chrome(revealKey: 2));
    await tester.pumpAndSettle();
    expect(barShowing(tester), isTrue);
  });

  testWidgets('reaching for a button on it keeps it a while longer', (
    tester,
  ) async {
    await tester.pumpWidget(chrome());
    await tester.pump(hideAfter - const Duration(milliseconds: 300));

    // A finger on the bar just before it would have gone.
    final gesture = await tester.startGesture(
      tester.getCenter(find.byIcon(Icons.toc)),
    );
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 600));
    expect(
      barShowing(tester),
      isTrue,
      reason: 'it must not leave under the finger reaching for it',
    );
  });

  testWidgets('never hides itself from someone using a screen reader', (
    tester,
  ) async {
    // They cannot see it go, so cannot know to tap for it, and its buttons are the only way to the
    // chapter list.
    await tester.pumpWidget(chrome(accessible: true));
    await tester.pump(hideAfter * 3);
    controls.hide();
    await tester.pumpAndSettle();
    expect(barShowing(tester), isTrue);
  });

  testWidgets('the page sits under the bar rather than being pushed down', (
    tester,
  ) async {
    // Moving every line by the bar's height each time it came or went would change the length of
    // the page under the reader, and the place saved as a fraction of it would drift.
    await tester.pumpWidget(chrome());
    final before = tester.getTopLeft(find.text('The page'));
    controls.hide();
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('The page')), before);
  });
}
