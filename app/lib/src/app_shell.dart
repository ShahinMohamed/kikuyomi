import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kikuyomi_domain/kikuyomi_domain.dart' show AppSettings;

import 'providers.dart';
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

/// The tabs in the order [stored] names them, by [AppTab.name].
///
/// A name this build does not know is passed over: it is a tab a later version had and this one
/// does not, and there is nothing to show for it. A tab the stored order does not mention goes at
/// the end, in the order the app declares it, which is what puts a tab added by a later version in
/// front of someone who had already arranged the ones before it.
List<AppTab> orderedTabs(List<String>? stored) {
  if (stored == null || stored.isEmpty) return AppTab.values;
  final byName = AppTab.values.asNameMap();
  final tabs = <AppTab>[];
  for (final name in stored) {
    final tab = byName[name];
    if (tab != null && !tabs.contains(tab)) tabs.add(tab);
  }
  for (final tab in AppTab.values) {
    if (!tabs.contains(tab)) tabs.add(tab);
  }
  return List.unmodifiable(tabs);
}

/// The order the shell's tabs are in, read at once rather than waited for.
///
/// A [Notifier] and not a stream, because the tab bar is on the screen from the first frame and a
/// bar that drew itself in one order and rearranged a frame later would look like a bug. The store
/// reads synchronously, so the order is known in time.
final tabOrderProvider = NotifierProvider<TabOrder, List<AppTab>>(TabOrder.new);

class TabOrder extends Notifier<List<AppTab>> {
  @override
  List<AppTab> build() => orderedTabs(
    ref.watch(servicesProvider).settings.read(AppSettings.tabOrder),
  );

  /// Puts the tabs in [tabs], remembering it.
  Future<void> reorder(List<AppTab> tabs) async {
    state = List.unmodifiable(tabs);
    await ref.read(servicesProvider).settings.write(AppSettings.tabOrder, [
      for (final tab in tabs) tab.name,
    ]);
  }

  /// Puts them back the way the app declares them.
  Future<void> reset() async {
    state = AppTab.values;
    await ref.read(servicesProvider).settings.write(AppSettings.tabOrder, null);
  }
}

/// A screen inside the tabbed shell.
///
/// The shell is the Scaffold, so each screen passes what belongs to it — its app bar, its body, its
/// floating button — and the navigation is drawn once, here. Tapping a tab goes to that tab's
/// location rather than pushing it, so the stack never fills with tabs.
class AppShell extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final wide = MediaQuery.sizeOf(context).width >= shellRailBreakpoint;
    final tabs = ref.watch(tabOrderProvider);
    void go(int index) {
      final chosen = tabs[index];
      if (chosen != tab) context.go(chosen.location);
    }

    return Scaffold(
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      body: wide
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: tabs.indexOf(tab),
                  onDestinationSelected: go,
                  labelType: NavigationRailLabelType.all,
                  destinations: [
                    for (final tab in tabs)
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
              selectedIndex: tabs.indexOf(tab),
              onDestinationSelected: go,
              destinations: [
                for (final tab in tabs)
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
