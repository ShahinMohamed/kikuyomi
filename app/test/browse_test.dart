import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikuyomi/src/app_shell.dart';
import 'package:kikuyomi/src/sources_view.dart';
import 'package:kikuyomi/src/source_books_view.dart';
import 'package:kikuyomi/src/sources/source_books_controller.dart';
import 'package:kikuyomi/src/sources/source_error_view.dart';
import 'package:kikuyomi/src/sources/source_filters_sheet.dart';
import 'package:kikuyomi/src/sources/source_registry.dart';
import 'package:kikuyomi_extension_manager/kikuyomi_extension_manager.dart';
import 'package:kikuyomi_source_api/kikuyomi_source_api.dart';
import 'package:kikuyomi_source_runtime/kikuyomi_source_runtime.dart';
import 'package:kikuyomi_test_support/kikuyomi_test_support.dart';

const local = SourceDescription(
  id: 1,
  key: 'local',
  name: 'Local files',
  lang: 'und',
  capabilities: {},
);

const librivox = SourceDescription(
  id: 0x4c4942,
  key: 'librivox',
  name: 'LibriVox',
  lang: 'multi',
  capabilities: {SourceCapability.filters},
  extensionId: 'org.kikuyomi.librivox',
);

const storynory = SourceDescription(
  id: 0x53544f,
  key: 'storynory',
  name: 'Storynory',
  lang: 'en',
  capabilities: {},
  extensionId: 'org.kikuyomi.storynory',
);

PageResult<BookSummary> booksPage(int from, int count, {bool more = false}) =>
    PageResult(
      items: [
        for (var i = from; i < from + count; i++)
          BookSummary(
            key: '$i',
            title: 'Book $i',
            authors: const ['Herman Melville'],
            durationMs: 3600000,
          ),
      ],
      hasNextPage: more,
    );

Widget wrap(Widget child, {Size size = const Size(400, 800)}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(size: size),
    child: child,
  ),
);

Widget grid(SourceBooksController controller, {List<String>? opened}) => wrap(
  Scaffold(
    body: SourceBooksView(
      controller: controller,
      sourceName: 'LibriVox',
      emptyMessage: 'LibriVox has nothing to show here.',
      onOpen: (book) => opened?.add(book.key),
    ),
  ),
);

void main() {
  group('the sources list', () {
    testWidgets('shows every source, and what each one is', (tester) async {
      await tester.pumpWidget(
        wrap(
          Scaffold(
            body: SourcesView(sources: const [local, librivox], onOpen: (_) {}),
          ),
        ),
      );

      expect(find.text('Local files'), findsOneWidget);
      expect(find.text('Books you added from this device'), findsOneWidget);
      expect(find.text('LibriVox'), findsOneWidget);
      expect(
        find.text('Several languages · org.kikuyomi.librivox'),
        findsOneWidget,
      );
    });

    testWidgets('opening one says which', (tester) async {
      final opened = <String>[];
      await tester.pumpWidget(
        wrap(
          Scaffold(
            body: SourcesView(
              sources: const [local, librivox],
              onOpen: (source) => opened.add(source.name),
            ),
          ),
        ),
      );

      await tester.tap(find.text('LibriVox'));

      expect(opened, ['LibriVox']);
    });

    testWidgets('says so when there are none', (tester) async {
      await tester.pumpWidget(
        wrap(
          Scaffold(
            body: SourcesView(sources: const [], onOpen: (_) {}),
          ),
        ),
      );

      expect(find.textContaining('No sources yet'), findsOneWidget);
    });

    testWidgets('groups the sources by language', (tester) async {
      // A list of thirty sources is unreadable in one run, and language is what divides them.
      await tester.pumpWidget(
        wrap(
          Scaffold(
            body: SourcesView(
              sources: const [local, librivox, storynory],
              onOpen: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Several languages'), findsWidgets);
      expect(find.text('EN'), findsOneWidget);
      expect(find.text('UND'), findsOneWidget);
    });

    testWidgets('puts the last one used at the top', (tester) async {
      // Coming back to Browse usually means going back where you were.
      await tester.pumpWidget(
        wrap(
          Scaffold(
            body: SourcesView(
              sources: const [local, librivox, storynory],
              recent: const [0x53544f],
              onOpen: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Last used'), findsOneWidget);
      // Once under its heading and once under its language: the groups answer different questions,
      // and a source leaving its language would make the language list wrong.
      expect(find.text('Storynory'), findsNWidgets(2));
    });

    testWidgets('only the most recent counts as last used', (tester) async {
      await tester.pumpWidget(
        wrap(
          Scaffold(
            body: SourcesView(
              sources: const [local, librivox, storynory],
              recent: const [0x53544f, 0x4c4942],
              onOpen: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Storynory'), findsNWidgets(2));
      expect(find.text('LibriVox'), findsOneWidget);
    });

    testWidgets('shows pinned sources under their own heading', (tester) async {
      await tester.pumpWidget(
        wrap(
          Scaffold(
            body: SourcesView(
              sources: const [local, librivox, storynory],
              pinned: const [0x4c4942],
              onOpen: (_) {},
              onTogglePin: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Pinned'), findsOneWidget);
      expect(find.text('LibriVox'), findsNWidgets(2));
    });

    testWidgets('pinning and unpinning say which source', (tester) async {
      final toggled = <String>[];
      await tester.pumpWidget(
        wrap(
          Scaffold(
            body: SourcesView(
              sources: const [librivox],
              onOpen: (_) {},
              onTogglePin: (source) => toggled.add(source.name),
            ),
          ),
        ),
      );

      await tester.tap(find.byTooltip('Pin LibriVox'));
      expect(toggled, ['LibriVox']);
    });

    testWidgets('a pinned source offers to be unpinned', (tester) async {
      await tester.pumpWidget(
        wrap(
          Scaffold(
            body: SourcesView(
              sources: const [librivox],
              pinned: const [0x4c4942],
              onOpen: (_) {},
              onTogglePin: (_) {},
            ),
          ),
        ),
      );

      expect(find.byTooltip('Unpin LibriVox'), findsWidgets);
    });

    testWidgets('the local source cannot be pinned', (tester) async {
      // It is not a source you browse, and it is already at the top of everything.
      await tester.pumpWidget(
        wrap(
          Scaffold(
            body: SourcesView(
              sources: const [local],
              onOpen: (_) {},
              onTogglePin: (_) {},
            ),
          ),
        ),
      );

      expect(find.byTooltip('Pin Local files'), findsNothing);
    });

    testWidgets('a source whose extension has no icon still shows', (
      tester,
    ) async {
      // Extensions published before icons, and folders an author has not drawn one for.
      await tester.pumpWidget(
        wrap(
          Scaffold(
            body: SourcesView(sources: const [librivox], onOpen: (_) {}),
          ),
        ),
      );

      expect(find.byIcon(Icons.public), findsOneWidget);
    });
  });

  group('a source\'s books', () {
    testWidgets('shows a spinner until the first page arrives', (tester) async {
      final source = FakeContentSource(
        pages: {1: booksPage(1, 4)},
        delay: const Duration(milliseconds: 20),
      );
      final controller = SourceBooksController(source.getPopular);
      addTearDown(controller.dispose);

      await tester.pumpWidget(grid(controller));
      unawaitedLoad(controller);
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Book 1'), findsNothing);

      await tester.pumpAndSettle();
      expect(find.text('Book 1'), findsOneWidget);
    });

    testWidgets('shows a page of covers once it arrives', (tester) async {
      final source = FakeContentSource(pages: {1: booksPage(1, 4)});
      final controller = SourceBooksController(source.getPopular);
      addTearDown(controller.dispose);

      await tester.pumpWidget(grid(controller));
      unawaitedLoad(controller);
      await tester.pumpAndSettle();

      expect(find.text('Book 1'), findsOneWidget);
      expect(find.text('Book 4'), findsOneWidget);
      expect(find.text('Herman Melville'), findsWidgets);
      expect(find.text('1 h'), findsWidgets);
    });

    testWidgets('a search shows what the source found for it', (tester) async {
      final source = FakeContentSource(
        searchPages: {('whale', 1): booksPage(7, 1)},
      );
      final controller = SourceBooksController(
        (page) => source.search(SearchQuery(text: 'whale'), page),
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(grid(controller));
      unawaitedLoad(controller);
      await tester.pumpAndSettle();

      expect(find.text('Book 7'), findsOneWidget);
      expect(source.searches.single.text, 'whale');
    });

    testWidgets('asks for the next page as the listener scrolls', (
      tester,
    ) async {
      final source = FakeContentSource(
        pages: {1: booksPage(1, 20, more: true), 2: booksPage(21, 4)},
      );
      final controller = SourceBooksController(source.getPopular);
      addTearDown(controller.dispose);

      await tester.pumpWidget(grid(controller));
      unawaitedLoad(controller);
      await tester.pumpAndSettle();
      expect(source.calls, ['getPopular(1)']);

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -4000));
      await tester.pumpAndSettle();
      expect(source.calls, ['getPopular(1)', 'getPopular(2)']);

      // The second page is appended below where the listener already is, so it takes another scroll
      // to reach it.
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -4000));
      await tester.pumpAndSettle();
      expect(find.text('Book 24'), findsOneWidget);
    });

    testWidgets('opening a book says which', (tester) async {
      final opened = <String>[];
      final source = FakeContentSource(pages: {1: booksPage(1, 2)});
      final controller = SourceBooksController(source.getPopular);
      addTearDown(controller.dispose);

      await tester.pumpWidget(grid(controller, opened: opened));
      unawaitedLoad(controller);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Book 1'));

      expect(opened, ['1']);
    });

    testWidgets('an empty answer says so rather than showing nothing', (
      tester,
    ) async {
      final controller = SourceBooksController(
        FakeContentSource(pages: const {}).getPopular,
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(grid(controller));
      unawaitedLoad(controller);
      await tester.pumpAndSettle();

      expect(find.text('LibriVox has nothing to show here.'), findsOneWidget);
    });
  });

  group('every failure says something', () {
    Future<void> show(WidgetTester tester, Object failure) async {
      final controller = SourceBooksController((_) => Future.error(failure));
      addTearDown(controller.dispose);
      await tester.pumpWidget(grid(controller));
      unawaitedLoad(controller);
      await tester.pumpAndSettle();
    }

    testWidgets('rate limited, with how long to wait', (tester) async {
      await show(
        tester,
        const RateLimitedException(retryAfterMs: 30000, message: 'slow down'),
      );

      expect(find.textContaining('asking for a pause'), findsOneWidget);
      expect(find.textContaining('30 seconds'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    });

    testWidgets('a network failure offers to try again', (tester) async {
      await show(tester, const NetworkException('no route to host'));

      expect(find.textContaining('Could not reach LibriVox'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
      // The extension's own words are shown, but never as the explanation.
      expect(find.text('no route to host'), findsOneWidget);
    });

    testWidgets('an answer that could not be read', (tester) async {
      await show(tester, const ParseException('items[3].title: too long'));

      expect(find.textContaining('could not read'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    });

    testWidgets('a book that is gone is not worth retrying', (tester) async {
      await show(tester, const NotFoundException());

      expect(find.textContaining('no longer has this'), findsOneWidget);
      expect(find.text('Try again'), findsNothing);
    });

    testWidgets('an extension the site has outgrown', (tester) async {
      await show(tester, const SourceOutdatedException());

      expect(find.textContaining('needs updating'), findsOneWidget);
      expect(find.text('Try again'), findsNothing);
    });

    testWidgets('a challenge offers the browser, which 1.0 cannot show', (
      tester,
    ) async {
      await show(
        tester,
        ChallengeRequiredException(Uri.parse('https://librivox.org/check')),
      );

      expect(find.textContaining('check in a browser'), findsOneWidget);
      expect(find.text('Open in browser'), findsOneWidget);
      expect(find.text('Try again'), findsNothing);
    });

    testWidgets('a login the app cannot offer yet', (tester) async {
      await show(tester, const LoginRequiredException());

      expect(find.textContaining('sign in'), findsOneWidget);
      expect(find.text('Try again'), findsNothing);
    });

    testWidgets('an extension that will not load', (tester) async {
      await show(
        tester,
        const ExtensionLoadException(
          'org.kikuyomi.librivox',
          'SyntaxError: unexpected token',
        ),
      );

      expect(
        find.text('The LibriVox extension could not be loaded.'),
        findsOneWidget,
      );
      expect(find.text('SyntaxError: unexpected token'), findsOneWidget);
    });

    testWidgets('an extension whose manifest could not be read', (
      tester,
    ) async {
      await show(tester, const ManifestException('domains: missing'));

      expect(
        find.text('The LibriVox extension could not be read.'),
        findsOneWidget,
      );
    });

    testWidgets('anything else, rather than an empty screen', (tester) async {
      await show(tester, StateError('something unexpected'));

      expect(find.text('Something went wrong with LibriVox.'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    });

    testWidgets('a page that fails keeps the books already shown', (
      tester,
    ) async {
      var first = true;
      final controller = SourceBooksController((page) {
        if (first) {
          first = false;
          return Future.value(booksPage(1, 4, more: true));
        }
        return Future.error(const NetworkException('gone'));
      });
      addTearDown(controller.dispose);

      await tester.pumpWidget(grid(controller));
      unawaitedLoad(controller);
      await tester.pumpAndSettle();
      await controller.loadMore();
      await tester.pumpAndSettle();

      expect(find.text('Book 1'), findsOneWidget);
      expect(find.textContaining('Could not reach LibriVox'), findsOneWidget);
    });

    testWidgets('trying again asks the source once more', (tester) async {
      var attempts = 0;
      final controller = SourceBooksController((page) {
        attempts++;
        return attempts == 1
            ? Future<PageResult<BookSummary>>.error(
                const NetworkException('gone'),
              )
            : Future.value(booksPage(1, 2));
      });
      addTearDown(controller.dispose);

      await tester.pumpWidget(grid(controller));
      unawaitedLoad(controller);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(find.text('Book 1'), findsOneWidget);
      expect(find.byType(SourceErrorView), findsNothing);
    });
  });

  group('the shell', () {
    testWidgets('a narrow window gets a bottom bar', (tester) async {
      await tester.pumpWidget(
        wrap(
          const AppShell(tab: AppTab.browse, body: Text('body')),
          size: const Size(400, 800),
        ),
      );

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
      expect(find.text('Library'), findsOneWidget);
      expect(find.text('Browse'), findsOneWidget);
    });

    testWidgets('a wide window gets a rail', (tester) async {
      await tester.pumpWidget(
        wrap(
          const AppShell(tab: AppTab.library, body: Text('body')),
          size: const Size(1200, 800),
        ),
      );

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
    });
  });

  group('the filters sheet', () {
    testWidgets('sends only what was changed from its default', (tester) async {
      FilterValues? chosen;
      final filters = [
        const HeaderFilter(label: 'Search LibriVox'),
        SelectFilter(
          key: 'field',
          label: 'Look in',
          options: const [
            Option(value: 'everything', label: 'Titles and authors'),
            Option(value: 'author', label: 'Authors'),
          ],
          defaultOption: 'everything',
        ),
      ];
      await tester.pumpWidget(
        wrap(
          Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async => chosen = await showSourceFilters(
                  context,
                  filters: filters,
                  values: FilterValues.none,
                ),
                child: const Text('Filters'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Filters'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Titles and authors').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Authors').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Search'));
      await tester.pumpAndSettle();

      expect(chosen?.values, {'field': const SelectValue('author')});
    });

    testWidgets('leaving a filter at its default sends nothing', (
      tester,
    ) async {
      FilterValues? chosen;
      await tester.pumpWidget(
        wrap(
          Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async => chosen = await showSourceFilters(
                  context,
                  filters: [
                    const CheckboxFilter(key: 'free', label: 'Free only'),
                  ],
                  values: FilterValues.none,
                ),
                child: const Text('Filters'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Filters'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Search'));
      await tester.pumpAndSettle();

      expect(chosen?.values, isEmpty);
    });
  });
}

/// Starts the first page without waiting for it, the way a screen does.
void unawaitedLoad(SourceBooksController controller) {
  controller.loadMore();
}
