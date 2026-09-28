import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kikuyomi/src/browse_screen.dart';
import 'package:kikuyomi/src/app_shell.dart';
import 'package:kikuyomi/src/providers.dart';
import 'package:kikuyomi/src/source_book_screen.dart';
import 'package:kikuyomi/src/source_screen.dart';
import 'package:kikuyomi/src/sources/source_gateway.dart';
import 'package:kikuyomi/src/sources/source_registry.dart';
import 'package:kikuyomi_source_api/kikuyomi_source_api.dart';
import 'package:kikuyomi_source_runtime/kikuyomi_source_runtime.dart';
import 'package:kikuyomi_test_support/kikuyomi_test_support.dart';

import 'tab_order_support.dart';

import 'browse_test.dart' show booksPage, librivox, local;

/// A gateway over a fake source, so a screen can be driven without a database, an engine or a
/// network.
final class FakeGateway implements SourceGateway {
  FakeGateway({
    required this.source,
    this.sources = const [local, librivox],
    this.openFailure,
    this.addFailure,
  });

  final ContentSource source;

  @override
  final List<SourceDescription> sources;

  /// Nothing is installed or removed in a widget test, so the list never changes.
  @override
  Stream<List<SourceDescription>> get sourceChanges =>
      const Stream<List<SourceDescription>>.empty();

  /// When set, opening the source fails with it, as an extension that will not load does.
  final Object? openFailure;

  /// When set, adding a book fails with it.
  final Object? addFailure;

  final added = <String>[];
  var opens = 0;

  @override
  Future<ContentSource> open(int sourceId) async {
    opens++;
    final failure = openFailure;
    if (failure != null) throw failure;
    return source;
  }

  @override
  Future<SourceBookPreview> preview(int sourceId, String bookKey) async {
    final details = await source.getBookDetails(bookKey);
    return (details: details, chapters: await source.getChapters(bookKey));
  }

  @override
  Future<int> addToLibrary({
    required int sourceId,
    required BookDetails details,
    required List<ChapterInfo> chapters,
  }) async {
    final failure = addFailure;
    if (failure != null) throw failure;
    added.add(details.key);
    return 42;
  }

  @override
  SourceDescription? describe(int sourceId) =>
      sources.where((source) => source.id == sourceId).firstOrNull;

  @override
  String nameOf(int sourceId) => describe(sourceId)?.name ?? 'This source';
}

/// One screen, inside a router that knows the Browse routes, so pushing a book's route works.
Widget screen(Widget child, FakeGateway gateway) => ProviderScope(
  overrides: [
    sourceGatewayProvider.overrideWithValue(gateway),
    // The shell draws the tabs, and their order is a setting, which is a service away.
    tabOrderProvider.overrideWith(FixedTabOrder.new),
  ],
  child: MaterialApp.router(
    routerConfig: GoRouter(
      routes: [GoRoute(path: '/', builder: (context, state) => child)],
    ),
  ),
);

BookDetails aBook({String key = '753'}) => BookDetails(
  key: key,
  title: 'Moby Dick, or the Whale',
  authors: const ['Herman Melville'],
  narrators: const ['Stewart Wills'],
  description: 'Call me Ishmael.',
  genres: const ['Nautical & Marine Fiction'],
  totalDurationMs: 3600000,
  status: BookStatus.complete,
);

void main() {
  group('Browse', () {
    testWidgets('lists the sources the app knows of', (tester) async {
      final gateway = FakeGateway(source: FakeContentSource());

      await tester.pumpWidget(screen(const BrowseScreen(), gateway));
      await tester.pumpAndSettle();

      // Twice: the app bar's title and the shell's own tab.
      expect(find.text('Browse'), findsNWidgets(2));
      expect(find.text('LibriVox'), findsOneWidget);
      expect(find.text('Local files'), findsOneWidget);
      // Reading the list runs no extension code (§3.6).
      expect(gateway.opens, 0);
    });
  });

  group('a source', () {
    testWidgets('shows what it calls popular, opening it once', (tester) async {
      final gateway = FakeGateway(
        source: FakeContentSource(pages: {1: booksPage(1, 3)}),
      );

      await tester.pumpWidget(
        screen(SourceScreen(sourceId: librivox.id), gateway),
      );
      await tester.pumpAndSettle();

      expect(find.text('Book 1'), findsOneWidget);
      expect(gateway.opens, 1);
    });

    testWidgets('searching asks the source for what was typed', (tester) async {
      final source = FakeContentSource(
        pages: {1: booksPage(1, 2)},
        searchPages: {('whale', 1): booksPage(9, 1)},
      );
      final gateway = FakeGateway(source: source);

      await tester.pumpWidget(
        screen(SourceScreen(sourceId: librivox.id), gateway),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(SearchBar), 'whale');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(source.searches.single.text, 'whale');
      expect(find.text('Book 9'), findsOneWidget);
      expect(find.text('Book 1'), findsNothing);
    });

    testWidgets('clearing the search goes back to what is popular', (
      tester,
    ) async {
      final gateway = FakeGateway(
        source: FakeContentSource(
          pages: {1: booksPage(1, 2)},
          searchPages: {('whale', 1): booksPage(9, 1)},
        ),
      );

      await tester.pumpWidget(
        screen(SourceScreen(sourceId: librivox.id), gateway),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(SearchBar), 'whale');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Clear'));
      await tester.pumpAndSettle();

      expect(find.text('Book 1'), findsOneWidget);
      expect(find.text('Book 9'), findsNothing);
    });

    testWidgets('a search that finds nothing says so', (tester) async {
      final gateway = FakeGateway(
        source: FakeContentSource(pages: {1: booksPage(1, 2)}),
      );

      await tester.pumpWidget(
        screen(SourceScreen(sourceId: librivox.id), gateway),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(SearchBar), 'zzzz');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(find.text('Nothing at LibriVox matches "zzzz".'), findsOneWidget);
    });

    testWidgets('a filter chosen reaches the source', (tester) async {
      final source = FakeContentSource(
        capabilities: const {SourceCapability.filters},
        pages: {1: booksPage(1, 2)},
        searchPages: {('whale', 1): booksPage(9, 1)},
        filters: [
          SelectFilter(
            key: 'field',
            label: 'Look in',
            options: const [
              Option(value: 'everything', label: 'Titles and authors'),
              Option(value: 'author', label: 'Authors'),
            ],
            defaultOption: 'everything',
          ),
        ],
      );
      final gateway = FakeGateway(source: source);

      await tester.pumpWidget(
        screen(SourceScreen(sourceId: librivox.id), gateway),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(SearchBar), 'whale');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Filters'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Titles and authors').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Authors').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Search'));
      await tester.pumpAndSettle();

      expect(source.searches.last.filters.values, {
        'field': const SelectValue('author'),
      });
    });

    testWidgets('a source with no filters offers no filter button', (
      tester,
    ) async {
      final gateway = FakeGateway(
        source: FakeContentSource(pages: {1: booksPage(1, 1)}),
        sources: const [
          SourceDescription(
            id: 99,
            key: 'plain',
            name: 'Plain',
            lang: 'en',
            capabilities: {},
            extensionId: 'org.example.plain',
          ),
        ],
      );

      await tester.pumpWidget(
        screen(const SourceScreen(sourceId: 99), gateway),
      );
      await tester.pumpAndSettle();

      expect(find.byTooltip('Filters'), findsNothing);
    });

    testWidgets('an extension that will not load is said so, with a retry', (
      tester,
    ) async {
      final gateway = FakeGateway(
        source: FakeContentSource(),
        openFailure: const ExtensionLoadException(
          'org.kikuyomi.librivox',
          'SyntaxError: unexpected token',
        ),
      );

      await tester.pumpWidget(
        screen(SourceScreen(sourceId: librivox.id), gateway),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('The LibriVox extension could not be loaded.'),
        findsOneWidget,
      );
      expect(find.text('SyntaxError: unexpected token'), findsOneWidget);
    });
  });

  group('a book at a source', () {
    FakeGateway gatewayFor({Object? addFailure}) => FakeGateway(
      source: FakeContentSource(
        details: {'753': aBook()},
        chapters: {
          '753': [
            const ChapterInfo(key: 's1', title: 'Loomings', durationMs: 60000),
          ],
        },
      ),
      addFailure: addFailure,
    );

    testWidgets('shows its details and its chapters', (tester) async {
      await tester.pumpWidget(
        screen(
          SourceBookScreen(sourceId: librivox.id, bookKey: '753'),
          gatewayFor(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Call me Ishmael.'), findsOneWidget);
      expect(find.text('Loomings'), findsOneWidget);
      expect(find.text('Add to library'), findsOneWidget);
    });

    testWidgets('adding it says so and then offers to open it', (tester) async {
      final gateway = gatewayFor();

      await tester.pumpWidget(
        screen(
          SourceBookScreen(sourceId: librivox.id, bookKey: '753'),
          gateway,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add to library'));
      await tester.pumpAndSettle();

      expect(gateway.added, ['753']);
      expect(
        find.text('Added Moby Dick, or the Whale to the library'),
        findsOneWidget,
      );
      expect(find.text('Open in library'), findsOneWidget);
    });

    testWidgets('an add that fails says why and offers the button again', (
      tester,
    ) async {
      final gateway = gatewayFor(
        addFailure: const NetworkException('no route to host'),
      );

      await tester.pumpWidget(
        screen(
          SourceBookScreen(sourceId: librivox.id, bookKey: '753'),
          gateway,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add to library'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Could not add the book'), findsOneWidget);
      expect(find.text('Add to library'), findsOneWidget);
    });

    testWidgets('a book the source no longer has says so', (tester) async {
      final gateway = FakeGateway(source: FakeContentSource());

      await tester.pumpWidget(
        screen(
          SourceBookScreen(sourceId: librivox.id, bookKey: 'gone'),
          gateway,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('LibriVox no longer has this.'), findsOneWidget);
      expect(find.text('Try again'), findsNothing);
    });
  });
}
