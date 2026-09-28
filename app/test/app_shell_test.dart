// The shell's tabs: the order they are in, and arranging them.

import 'dart:io';

import 'package:flutter/gestures.dart' show kLongPressTimeout, kPressTimeout;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikuyomi/src/app_shell.dart';
import 'package:kikuyomi/src/tabs_screen.dart';

import 'tab_order_support.dart';

Widget shell(
  Widget child, {
  List<AppTab>? order,
  Size size = const Size(400, 800),
}) => ProviderScope(
  overrides: [
    tabOrderProvider.overrideWith(() => FixedTabOrder(order ?? AppTab.values)),
  ],
  child: MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(size: size),
      child: child,
    ),
  ),
);

List<String> barLabels(WidgetTester tester) => [
  for (final destination in tester.widgetList<NavigationDestination>(
    find.byType(NavigationDestination),
  ))
    destination.label,
];

void main() {
  group('the order of the tabs', () {
    test('is the order the app declares, until someone says otherwise', () {
      expect(orderedTabs(null), AppTab.values);
      expect(orderedTabs(const []), AppTab.values);
    });

    test('is what was stored', () {
      expect(orderedTabs(const ['reading', 'library']).take(2), [
        AppTab.reading,
        AppTab.library,
      ]);
    });

    test('keeps a tab the stored order never mentions', () {
      // A tab added by a later version than the one that wrote the order. It goes last rather than
      // disappearing, which is what keeps a new tab reachable.
      final tabs = orderedTabs(const ['more', 'browse']);

      expect(tabs.take(2), [AppTab.more, AppTab.browse]);
      expect(tabs.toSet(), AppTab.values.toSet());
    });

    test('passes over a name this build does not know, and a repeat', () {
      // A tab a later version had and this one does not, and a list that names one twice.
      final tabs = orderedTabs(const ['read', 'comics', 'reading', 'library']);

      expect(tabs.take(2), [AppTab.reading, AppTab.library]);
      expect(tabs.length, AppTab.values.length);
    });
  });

  group('the bar', () {
    testWidgets('draws the tabs in that order', (tester) async {
      await tester.pumpWidget(
        shell(
          const AppShell(tab: AppTab.reading, body: Text('body')),
          order: const [AppTab.reading, AppTab.library, AppTab.more],
        ),
      );

      expect(barLabels(tester).take(3), ['Read', 'Listen', 'More']);
    });

    testWidgets('lights the tab being shown, wherever it has been moved to', (
      tester,
    ) async {
      await tester.pumpWidget(
        shell(
          const AppShell(tab: AppTab.downloads, body: Text('body')),
          order: const [AppTab.downloads, AppTab.library],
        ),
      );

      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        0,
      );
    });

    testWidgets('a wide window puts them down the rail in the same order', (
      tester,
    ) async {
      await tester.pumpWidget(
        shell(
          const AppShell(tab: AppTab.library, body: Text('body')),
          order: const [AppTab.reading, AppTab.library],
          size: const Size(1200, 800),
        ),
      );

      final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      expect(rail.selectedIndex, 1);
    });
  });

  _tabScreensHaveNoBackArrow();

  group('the shell', () {
    testWidgets('a narrow window gets a bottom bar', (tester) async {
      await tester.pumpWidget(
        shell(
          const AppShell(tab: AppTab.browse, body: Text('body')),
          size: const Size(400, 800),
        ),
      );

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
      expect(find.text('Listen'), findsOneWidget);
      expect(find.text('Read'), findsOneWidget);
      expect(find.text('Browse'), findsOneWidget);
    });

    testWidgets('a wide window gets a rail', (tester) async {
      await tester.pumpWidget(
        shell(
          const AppShell(tab: AppTab.library, body: Text('body')),
          size: const Size(1200, 800),
        ),
      );

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
    });
  });

  group('arranging them', () {
    testWidgets('moves a tab, and puts them all back', (tester) async {
      late WidgetRef ref;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tabOrderProvider.overrideWith(() => FixedTabOrder(AppTab.values)),
          ],
          child: MaterialApp(
            home: Consumer(
              builder: (context, r, _) {
                ref = r;
                return const TabsScreen();
              },
            ),
          ),
        ),
      );

      // More is last; drag it by its handle to the top.
      final drag = await tester.startGesture(
        tester.getCenter(find.byIcon(Icons.drag_handle).last),
      );
      await tester.pump(kLongPressTimeout + kPressTimeout);
      await drag.moveTo(tester.getCenter(find.text('Listen')));
      await tester.pumpAndSettle();
      await drag.up();
      await tester.pumpAndSettle();

      expect(ref.read(tabOrderProvider).first, AppTab.more);

      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();
      expect(ref.read(tabOrderProvider), AppTab.values);
    });
  });
}

/// A tab is where you are, not somewhere you went: its screen shows no back arrow.
///
/// Read this off the source rather than by building each screen, which would want the whole app
/// behind it. The rule is easy to forget when a tab is added, and the cost of forgetting is what
/// this app shipped with: every tab but the first drew an arrow back to the audiobook shelf, which
/// is not where a tab goes.
void _tabScreensHaveNoBackArrow() {
  group('a tab screen', () {
    const screens = {
      'lib/src/library_screen.dart': 'Listen',
      'lib/src/reading/reading_screen.dart': 'Read',
      'lib/src/history_screen.dart': 'History',
      'lib/src/browse_screen.dart': 'Browse',
      'lib/src/downloads_screen.dart': 'Downloads',
      'lib/src/more_screen.dart': 'More',
    };
    for (final MapEntry(key: path, value: tab) in screens.entries) {
      test('$tab has no back arrow', () {
        expect(
          File(path).readAsStringSync(),
          contains('automaticallyImplyLeading: false'),
          reason: '$tab is a tab, so its app bar must not imply a back button',
        );
      });
    }
  });
}
