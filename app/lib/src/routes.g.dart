// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'routes.dart';

// **************************************************************************
// GoRouterGenerator
// **************************************************************************

List<RouteBase> get $appRoutes => [$setupRoute, $homeRoute];

RouteBase get $setupRoute => GoRouteData.$route(
  path: '/setup',
  hasOverriddenOnExit: false,
  factory: $SetupRoute._fromState,
);

mixin $SetupRoute on GoRouteData {
  static SetupRoute _fromState(GoRouterState state) => const SetupRoute();

  @override
  String get location => GoRouteData.$location('/setup');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $homeRoute => GoRouteData.$route(
  path: '/',
  hasOverriddenOnExit: false,
  factory: $HomeRoute._fromState,
  routes: [
    GoRouteData.$route(
      path: 'book/:bookId(\\d+)',
      hasOverriddenOnExit: false,
      factory: $BookRoute._fromState,
    ),
    GoRouteData.$route(
      path: 'player',
      hasOverriddenOnExit: false,
      factory: $PlayerRoute._fromState,
    ),
    GoRouteData.$route(
      path: 'reading',
      hasOverriddenOnExit: false,
      factory: $ReadingRoute._fromState,
    ),
    GoRouteData.$route(
      path: 'read/:bookId(\\d+)',
      hasOverriddenOnExit: false,
      factory: $ReaderRoute._fromState,
    ),
    GoRouteData.$route(
      path: 'settings',
      hasOverriddenOnExit: false,
      factory: $SettingsRoute._fromState,
      routes: [
        GoRouteData.$route(
          path: 'restore',
          hasOverriddenOnExit: false,
          factory: $RestoreRoute._fromState,
        ),
      ],
    ),
    GoRouteData.$route(
      path: 'downloads',
      hasOverriddenOnExit: false,
      factory: $DownloadsRoute._fromState,
    ),
    GoRouteData.$route(
      path: 'history',
      hasOverriddenOnExit: false,
      factory: $HistoryRoute._fromState,
    ),
    GoRouteData.$route(
      path: 'more',
      hasOverriddenOnExit: false,
      factory: $MoreRoute._fromState,
    ),
    GoRouteData.$route(
      path: 'categories',
      hasOverriddenOnExit: false,
      factory: $CategoriesRoute._fromState,
    ),
    GoRouteData.$route(
      path: 'browse',
      hasOverriddenOnExit: false,
      factory: $BrowseRoute._fromState,
      routes: [
        GoRouteData.$route(
          path: 'source',
          hasOverriddenOnExit: false,
          factory: $SourceRoute._fromState,
          routes: [
            GoRouteData.$route(
              path: 'book',
              hasOverriddenOnExit: false,
              factory: $SourceBookRoute._fromState,
            ),
          ],
        ),
        GoRouteData.$route(
          path: 'extensions',
          hasOverriddenOnExit: false,
          factory: $ExtensionsRoute._fromState,
          routes: [
            GoRouteData.$route(
              path: 'console',
              hasOverriddenOnExit: false,
              factory: $ExtensionConsoleRoute._fromState,
            ),
            GoRouteData.$route(
              path: 'repositories',
              hasOverriddenOnExit: false,
              factory: $RepositoriesRoute._fromState,
            ),
          ],
        ),
      ],
    ),
  ],
);

mixin $HomeRoute on GoRouteData {
  static HomeRoute _fromState(GoRouterState state) => const HomeRoute();

  @override
  String get location => GoRouteData.$location('/');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $BookRoute on GoRouteData {
  static BookRoute _fromState(GoRouterState state) =>
      BookRoute(bookId: int.parse(state.pathParameters['bookId']!));

  BookRoute get _self => this as BookRoute;

  @override
  String get location => GoRouteData.$location(
    '/book/${Uri.encodeComponent(_self.bookId.toString())}',
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $PlayerRoute on GoRouteData {
  static PlayerRoute _fromState(GoRouterState state) => const PlayerRoute();

  @override
  String get location => GoRouteData.$location('/player');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $ReadingRoute on GoRouteData {
  static ReadingRoute _fromState(GoRouterState state) => const ReadingRoute();

  @override
  String get location => GoRouteData.$location('/reading');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $ReaderRoute on GoRouteData {
  static ReaderRoute _fromState(GoRouterState state) => ReaderRoute(
    bookId: int.parse(state.pathParameters['bookId']!),
    chapterId: _$convertMapValue(
      'chapter-id',
      state.uri.queryParameters,
      int.tryParse,
    ),
  );

  ReaderRoute get _self => this as ReaderRoute;

  @override
  String get location => GoRouteData.$location(
    '/read/${Uri.encodeComponent(_self.bookId.toString())}',
    queryParams: {
      if (_self.chapterId != null) 'chapter-id': _self.chapterId!.toString(),
    },
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $SettingsRoute on GoRouteData {
  static SettingsRoute _fromState(GoRouterState state) => const SettingsRoute();

  @override
  String get location => GoRouteData.$location('/settings');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $RestoreRoute on GoRouteData {
  static RestoreRoute _fromState(GoRouterState state) => const RestoreRoute();

  @override
  String get location => GoRouteData.$location('/settings/restore');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $DownloadsRoute on GoRouteData {
  static DownloadsRoute _fromState(GoRouterState state) =>
      const DownloadsRoute();

  @override
  String get location => GoRouteData.$location('/downloads');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $HistoryRoute on GoRouteData {
  static HistoryRoute _fromState(GoRouterState state) => const HistoryRoute();

  @override
  String get location => GoRouteData.$location('/history');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $MoreRoute on GoRouteData {
  static MoreRoute _fromState(GoRouterState state) => const MoreRoute();

  @override
  String get location => GoRouteData.$location('/more');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $CategoriesRoute on GoRouteData {
  static CategoriesRoute _fromState(GoRouterState state) =>
      const CategoriesRoute();

  @override
  String get location => GoRouteData.$location('/categories');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $BrowseRoute on GoRouteData {
  static BrowseRoute _fromState(GoRouterState state) => const BrowseRoute();

  @override
  String get location => GoRouteData.$location('/browse');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $SourceRoute on GoRouteData {
  static SourceRoute _fromState(GoRouterState state) =>
      SourceRoute(sourceId: int.parse(state.uri.queryParameters['source-id']!));

  SourceRoute get _self => this as SourceRoute;

  @override
  String get location => GoRouteData.$location(
    '/browse/source',
    queryParams: {'source-id': _self.sourceId.toString()},
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $SourceBookRoute on GoRouteData {
  static SourceBookRoute _fromState(GoRouterState state) => SourceBookRoute(
    sourceId: int.parse(state.uri.queryParameters['source-id']!),
    bookKey: state.uri.queryParameters['book-key']!,
  );

  SourceBookRoute get _self => this as SourceBookRoute;

  @override
  String get location => GoRouteData.$location(
    '/browse/source/book',
    queryParams: {
      'source-id': _self.sourceId.toString(),
      'book-key': _self.bookKey,
    },
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $ExtensionsRoute on GoRouteData {
  static ExtensionsRoute _fromState(GoRouterState state) =>
      const ExtensionsRoute();

  @override
  String get location => GoRouteData.$location('/browse/extensions');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $ExtensionConsoleRoute on GoRouteData {
  static ExtensionConsoleRoute _fromState(GoRouterState state) =>
      ExtensionConsoleRoute(
        extensionId: state.uri.queryParameters['extension-id'],
      );

  ExtensionConsoleRoute get _self => this as ExtensionConsoleRoute;

  @override
  String get location => GoRouteData.$location(
    '/browse/extensions/console',
    queryParams: {
      if (_self.extensionId != null) 'extension-id': _self.extensionId,
    },
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $RepositoriesRoute on GoRouteData {
  static RepositoriesRoute _fromState(GoRouterState state) =>
      const RepositoriesRoute();

  @override
  String get location =>
      GoRouteData.$location('/browse/extensions/repositories');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

T? _$convertMapValue<T>(
  String key,
  Map<String, String> map,
  T? Function(String) converter,
) {
  final value = map[key];
  return value == null ? null : converter(value);
}
