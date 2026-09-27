import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'book_details_screen.dart';
import 'browse_screen.dart';
import 'downloads_screen.dart';
import 'extension_console_screen.dart';
import 'extensions_screen.dart';
import 'history_screen.dart';
import 'repositories_screen.dart';
import 'library/categories_screen.dart';
import 'library_screen.dart';
import 'more_screen.dart';
import 'player_screen.dart';
import 'restore_screen.dart';
import 'settings_screen.dart';
import 'setup_gate.dart';
import 'setup_screen.dart';
import 'source_book_screen.dart';
import 'source_screen.dart';

part 'routes.g.dart';

/// The router the app runs on (ADR-0005), starting at [initialLocation].
///
/// Routes are typed: a screen's arguments are fields of its route, checked when the app is compiled
/// rather than parsed out of strings when it runs. Routing is confined to `app`, as ADR-0005
/// requires, so no package below it knows how screens are reached.
///
/// A route's location is its address within the app. §2.6's `kikuyomi://` deep links will resolve
/// through these same routes once the platforms register the scheme. A link meant for sharing will
/// then need a book's global identity, its source and key (§4.4), rather than the database id
/// [BookRoute] carries, which means nothing on another device.
///
/// With a [setupGate], the router keeps the app on [SetupRoute] while the gate offers setup, and
/// leaves it for the home once setup is finished, following the gate as it changes.
GoRouter createRouter({
  GlobalKey<NavigatorState>? navigatorKey,
  String initialLocation = '/',
  SetupGate? setupGate,
}) => GoRouter(
  navigatorKey: navigatorKey,
  initialLocation: initialLocation,
  routes: $appRoutes,
  refreshListenable: setupGate,
  redirect: setupGate == null
      ? null
      : (context, state) => setupRedirect(setupGate.offer, state.uri.path),
  errorBuilder: (context, state) =>
      _NotFoundScreen(location: state.uri.toString()),
);

/// Where the router goes instead of [location] while setup is [offer]ed, or null to go there.
///
/// While setup is offered every location leads to it, since the app starts on the home and a deep
/// link would otherwise slip past it. Once it is finished, or was never offered, it leads home.
String? setupRedirect(SetupOffer offer, String location) {
  final setup = const SetupRoute().location;
  return switch (offer) {
    SetupOffer.offered when location != setup => setup,
    SetupOffer.notOffered when location == setup => const HomeRoute().location,
    _ => null,
  };
}

/// Backup setup, offered when the app starts with an empty library. Outside the home, so that it
/// has nothing beneath it to go back to: it is finished or skipped, not left.
@TypedGoRoute<SetupRoute>(path: '/setup')
class SetupRoute extends GoRouteData with $SetupRoute {
  const SetupRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const SetupScreen();
}

/// The home: Continue Listening above the library.
///
/// The book and player routes sit under it, so a book reached by its location alone still has the
/// library beneath it to go back to.
@TypedGoRoute<HomeRoute>(
  path: '/',
  routes: [
    TypedGoRoute<BookRoute>(path: r'book/:bookId(\d+)'),
    TypedGoRoute<PlayerRoute>(path: 'player'),
    TypedGoRoute<SettingsRoute>(
      path: 'settings',
      routes: [TypedGoRoute<RestoreRoute>(path: 'restore')],
    ),
    TypedGoRoute<DownloadsRoute>(path: 'downloads'),
    TypedGoRoute<HistoryRoute>(path: 'history'),
    TypedGoRoute<MoreRoute>(path: 'more'),
    TypedGoRoute<CategoriesRoute>(path: 'categories'),
    TypedGoRoute<BrowseRoute>(
      path: 'browse',
      routes: [
        TypedGoRoute<SourceRoute>(
          path: 'source',
          routes: [TypedGoRoute<SourceBookRoute>(path: 'book')],
        ),
        TypedGoRoute<ExtensionsRoute>(
          path: 'extensions',
          routes: [
            TypedGoRoute<ExtensionConsoleRoute>(path: 'console'),
            TypedGoRoute<RepositoriesRoute>(path: 'repositories'),
          ],
        ),
      ],
    ),
  ],
)
class HomeRoute extends GoRouteData with $HomeRoute {
  const HomeRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const LibraryScreen();
}

/// A book's details.
class BookRoute extends GoRouteData with $BookRoute {
  const BookRoute({required this.bookId});

  /// The book's id in this device's database.
  final int bookId;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      BookDetailsScreen(bookId: bookId);
}

/// The player, showing the book the coordinator has open.
class PlayerRoute extends GoRouteData with $PlayerRoute {
  const PlayerRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const PlayerScreen();
}

/// Browse: the sources, and what can be found in them. The second tab of §2.6's shell.
///
/// Under the home rather than beside it, so that leaving Browse goes back to the library instead of
/// out of the app, and so a source reached by its location alone has somewhere to go back to.
class BrowseRoute extends GoRouteData with $BrowseRoute {
  const BrowseRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const BrowseScreen();
}

/// One source's catalogue: its popular books, and search.
///
/// The source is a query parameter rather than part of the path because a §3.7 source id is a signed
/// 64-bit number, which a path pattern would have to spell out negatives for.
class SourceRoute extends GoRouteData with $SourceRoute {
  const SourceRoute({required this.sourceId});

  final int sourceId;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      SourceScreen(sourceId: sourceId);
}

/// A book at a source, before it is in the library.
///
/// Identified the way §4.4 identifies a book everywhere else, by its source and its key, because
/// that is all the app knows about it until it has been added. The key is a query parameter: it is
/// an opaque string a source chose, and may hold slashes.
class SourceBookRoute extends GoRouteData with $SourceBookRoute {
  const SourceBookRoute({required this.sourceId, required this.bookKey});

  final int sourceId;
  final String bookKey;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      SourceBookScreen(sourceId: sourceId, bookKey: bookKey);
}

/// Extensions: what is installed, and installing or removing one (§3.9).
///
/// Under Browse, because an extension is where a source comes from. Mihon puts it in the same place,
/// for the same reason.
class ExtensionsRoute extends GoRouteData with $ExtensionsRoute {
  const ExtensionsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const ExtensionsScreen();
}

/// The extension console (§3.11), for every extension or for one.
///
/// The extension is a query parameter rather than part of the path: it is a reversed domain name, so it
/// holds the dots a path segment would otherwise have to be read around, and the console with no
/// extension named is the same screen showing everything.
class ExtensionConsoleRoute extends GoRouteData with $ExtensionConsoleRoute {
  const ExtensionConsoleRoute({this.extensionId});

  final String? extensionId;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      ExtensionConsoleScreen(extensionId: extensionId);
}

/// Downloads: what is on this device and what is being fetched (§5.6).
///
/// Beside Settings in the home's app bar and under the home in the tree, for the same reason Settings
/// is: §2.6's More tab is where both belong and it does not exist yet.
class DownloadsRoute extends GoRouteData with $DownloadsRoute {
  const DownloadsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const DownloadsScreen();
}

/// History: what has been listened to and when (§6.4).
///
/// Beside Downloads in the home's app bar and under the home in the tree, for the reason both are
/// there: §2.6's More tab is where they belong and it does not exist yet. The four tabs are unchanged.
class HistoryRoute extends GoRouteData with $HistoryRoute {
  const HistoryRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const HistoryScreen();
}

/// Repositories: the addresses extensions can be taken from (§3.8).
///
/// Under Extensions, because a repository is where an extension comes from and Extensions is where
/// they are managed. Mihon puts them in the same place, for the same reason.
/// The listener's own shelves, and what can be done with them (Phase 4).
class CategoriesRoute extends GoRouteData with $CategoriesRoute {
  const CategoriesRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const CategoriesScreen();
}

/// More: the things a listener reaches now and then rather than every day (§2.6).
///
/// A tab because the design asks for one, and it earns the place now that Settings is not the only
/// thing in it. What is *not* here is as deliberate: History and Downloads have tabs of their own,
/// because a listener goes to them directly and often.
class MoreRoute extends GoRouteData with $MoreRoute {
  const MoreRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const MoreScreen();
}

class RepositoriesRoute extends GoRouteData with $RepositoriesRoute {
  const RepositoriesRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const RepositoriesScreen();
}

/// Settings, from the home's app bar. There is no More tab yet, so it sits above the home.
class SettingsRoute extends GoRouteData with $SettingsRoute {
  const SettingsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const SettingsScreen();
}

/// Restoring from a backup, from Settings.
class RestoreRoute extends GoRouteData with $RestoreRoute {
  const RestoreRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const RestoreScreen();
}

/// What a location no route matches shows, such as a link written by a newer version of the app.
class _NotFoundScreen extends StatelessWidget {
  const _NotFoundScreen({required this.location});

  final String location;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'There is nothing at $location',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => const HomeRoute().go(context),
                child: const Text('Go to the library'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
