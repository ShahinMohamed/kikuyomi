import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'routes.dart';

/// The tabs of §2.6's adaptive shell.
///
/// §2.6 asks for Library, Home, Browse and More. What is here is those, with Home still folded into
/// Library — Continue Listening sits at the top of the shelf — and with History and Downloads given
/// tabs of their own rather than living under More.
///
/// That is a departure from the design and a deliberate one. Both were reached through the
/// library's app bar, which is the wrong place for them twice over: they are not about the library,
/// and an app bar is the one part of a screen that changes as you move around, so a button in it is
/// somewhere a listener has to find rather than somewhere they know. Both are things a listener
/// goes to directly and often, which is what a tab is for. More keeps what is genuinely occasional.
///
/// Listen and Read are two shelves side by side, as Aniyomi puts anime and manga (ADR-0019). Short
/// names, because six tabs share a phone's width.
enum AppTab {
  library('Listen', Icons.headphones_outlined, Icons.headphones),
  reading('Read', Icons.menu_book_outlined, Icons.menu_book),
  history('History', Icons.history_outlined, Icons.history),
  browse('Browse', Icons.explore_outlined, Icons.explore),
  downloads('Downloads', Icons.download_outlined, Icons.download),
  more('More', Icons.more_horiz_outlined, Icons.more_horiz);

  const AppTab(this.label, this.icon, this.selectedIcon);

  final String label;
  final IconData icon;
  final IconData selectedIcon;

  /// Where the tab goes. Every tab but the library sits under the home, so leaving one goes back to
  /// the library rather than out of the app.
  String get location => switch (this) {
    AppTab.library => const HomeRoute().location,
    AppTab.reading => const ReadingRoute().location,
    AppTab.history => const HistoryRoute().location,
    AppTab.browse => const BrowseRoute().location,
    AppTab.downloads => const DownloadsRoute().location,
    AppTab.more => const MoreRoute().location,
  };
}

/// The width at which the bottom bar becomes a rail.
///
/// §2.6: "Phones get a bottom navigation bar; wide windows (Windows desktop, tablets) get a
/// navigation rail or side panel." 700 logical pixels is about where a phone in landscape and a
/// small tablet part company, and it is the same figure the player uses to put its chapter list in a
/// side panel.
const shellRailBreakpoint = 700.0;

/// A screen inside the tabbed shell.
///
/// The shell is the Scaffold, so each screen passes what belongs to it — its app bar, its body, its
/// floating button — and the navigation is drawn once, here. Tapping a tab goes to that tab's
/// location rather than pushing it, so the stack never fills with tabs.
class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.tab,
    required this.body,
    this.appBar,
    this.floatingActionButton,
  });

  final AppTab tab;
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= shellRailBreakpoint;
    void go(int index) {
      final chosen = AppTab.values[index];
      if (chosen != tab) context.go(chosen.location);
    }

    return Scaffold(
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      body: wide
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: tab.index,
                  onDestinationSelected: go,
                  labelType: NavigationRailLabelType.all,
                  destinations: [
                    for (final tab in AppTab.values)
                      NavigationRailDestination(
                        icon: Icon(tab.icon),
                        selectedIcon: Icon(tab.selectedIcon),
                        label: Text(tab.label),
                      ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: body),
              ],
            )
          : body,
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: tab.index,
              onDestinationSelected: go,
              destinations: [
                for (final tab in AppTab.values)
                  NavigationDestination(
                    icon: Icon(tab.icon),
                    selectedIcon: Icon(tab.selectedIcon),
                    label: tab.label,
                  ),
              ],
            ),
    );
  }
}
