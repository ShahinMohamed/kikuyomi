// The iOS back gesture, from a strip wide enough to hit.
//
// Flutter's own strip is 20 logical pixels, about three millimetres, and a swipe starting a
// finger's width further in does nothing. These hold the wider strip in place, and hold on to the
// thing that made it worth widening: every screen in this app is a list, and a list competes for
// the drag, so a near miss looks exactly like an app that ignores the gesture.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikuyomi/src/back_gesture.dart';

/// Pushes a screen that looks like this app's — an app bar over a list — and swipes right from
/// [startX], as a thumb does: 400 logical pixels over 400 milliseconds, a frame at a time.
///
/// Returns whether the swipe went back.
Future<bool> swipesBack(
  WidgetTester tester, {
  required double startX,
  PageTransitionsTheme? transitions,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFFF0A868),
        pageTransitionsTheme: transitions ?? kikuyomiPageTransitions,
      ),
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => Scaffold(
                    appBar: AppBar(title: const Text('A Book')),
                    body: ListView(
                      children: const [Text('PUSHED'), SizedBox(height: 2000)],
                    ),
                  ),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  expect(find.text('PUSHED'), findsOneWidget);

  final gesture = await tester.startGesture(Offset(startX, 300));
  for (var frame = 1; frame <= 50; frame++) {
    await gesture.moveBy(
      const Offset(8, 0),
      timeStamp: Duration(milliseconds: 8 * frame),
    );
    await tester.pump(const Duration(milliseconds: 8));
  }
  await gesture.up();
  await tester.pumpAndSettle();
  return find.text('PUSHED').evaluate().isEmpty;
}

/// Only on iOS, set and put back for us.
final onIos = TargetPlatformVariant.only(TargetPlatform.iOS);

void main() {
  group('on iOS a swipe from the left edge goes back', () {
    test('from a strip wide enough for a finger', () {
      // Apple's own smallest touch target. Flutter's is 20.
      expect(backGestureWidth, 44.0);
    });

    testWidgets(
      'from the very edge',
      (tester) async => expect(await swipesBack(tester, startX: 4), isTrue),
      variant: onIos,
    );

    testWidgets(
      'from a finger-width in, over a list',
      // The one this is all for: Flutter's own 20-pixel strip ends before here, so this swipe used
      // to do nothing at all.
      (tester) async => expect(await swipesBack(tester, startX: 30), isTrue),
      variant: onIos,
    );

    testWidgets(
      "and Flutter's own strip is as narrow as it looks",
      // Not a test of this app so much as of why it has this file. If Flutter ever widens its own
      // strip, this fails and the whole file can go.
      (tester) async => expect(
        await swipesBack(
          tester,
          startX: 30,
          transitions: const PageTransitionsTheme(),
        ),
        isFalse,
      ),
      variant: onIos,
    );

    testWidgets(
      'but not from the middle of the screen',
      // A drag across the page is for whatever is under it, not for going back.
      (tester) async => expect(await swipesBack(tester, startX: 300), isFalse),
      variant: onIos,
    );
  });

  test('elsewhere the platform keeps its own transition', () {
    expect(
      kikuyomiPageTransitions.builders[TargetPlatform.android],
      isA<PredictiveBackPageTransitionsBuilder>(),
    );
    expect(
      kikuyomiPageTransitions.builders[TargetPlatform.windows],
      isA<ZoomPageTransitionsBuilder>(),
    );
  });
}
