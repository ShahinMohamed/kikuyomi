// The Repositories screen's own wiring, without a network or a database: what it shows about a
// repository, and what it refuses to offer.
//
// The refusal is the one worth pinning. Installing from a repository is not built, so nothing here
// offers it — a button that did nothing would be worse than a sentence saying so.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikuyomi/src/repositories_view.dart';
import 'package:kikuyomi_data/kikuyomi_data.dart' show RepositoryRow;
import 'package:kikuyomi_extension_manager/kikuyomi_extension_manager.dart';

final _at = DateTime.utc(2026, 9, 26, 9);

RepositoryRow repository({
  int id = 1,
  String name = 'Kikuyomi official',
  String url = 'https://example.org/repo/',
}) => RepositoryRow(
  id: id,
  url: url,
  name: name,
  publicKey: 'a2V5',
  fingerprint: 'AA:BB:CC',
  lastFetchedAt: _at,
);

RepositoryIndex listing({
  String name = 'LibriVox',
  List<String> domains = const ['librivox.org'],
  String rating = 'everyone',
  bool revoked = false,
}) => RepositoryIndex.parse(
  jsonEncode({
    'extensions': [
      {
        'id': 'org.example.librivox',
        'name': name,
        'version': '1.4.0',
        'versionCode': 14,
        'apiVersion': '1.0',
        'minAppVersion': '1.0.0',
        'contentRating': rating,
        'domains': domains,
        'sources': [
          {'key': 'lv', 'name': name, 'lang': 'en', 'versionId': 1},
        ],
        'package': {
          'url': 'https://example.org/a.zip',
          'sha256': '0123456789abcdef' * 4,
        },
        'signature': base64Encode(List.filled(64, 1)),
        'revoked': revoked,
      },
    ],
  }),
);

void main() {
  late List<RepositoryRow> browsed;
  late List<RepositoryRow> refreshed;
  late List<RepositoryRow> removed;
  late List<RepositoryEntry> installs;
  late int addTaps;

  setUp(() {
    browsed = [];
    refreshed = [];
    removed = [];
    installs = [];
    addTaps = 0;
  });

  Future<void> pumpView(
    WidgetTester tester, {
    List<RepositoryRow> repositories = const [],
    Map<int, RepositoryIndex> listings = const {},
    int? busyWith,
    Map<String, int> installed = const {},
    Set<String> installing = const {},
  }) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: RepositoriesView(
          repositories: repositories,
          listings: listings,
          busyWith: busyWith,
          installed: installed,
          installing: installing,
          onAdd: () => addTaps++,
          onBrowse: browsed.add,
          onRefresh: refreshed.add,
          onRemove: removed.add,
          onInstall: (_, entry) => installs.add(entry),
        ),
      ),
    ),
  );

  group('with none added', () {
    testWidgets('says what a repository is', (tester) async {
      await pumpView(tester);

      expect(find.text('No repositories'), findsOneWidget);
      expect(find.textContaining('lists extensions'), findsOneWidget);
    });

    testWidgets('offers to add one', (tester) async {
      await pumpView(tester);

      await tester.tap(find.text('Add a repository'));
      await tester.pumpAndSettle();

      expect(addTaps, 1);
    });
  });

  group('a repository', () {
    testWidgets('shows what it is called and where it is', (tester) async {
      await pumpView(tester, repositories: [repository()]);

      expect(find.text('Kikuyomi official'), findsOneWidget);
      expect(find.text('https://example.org/repo/'), findsOneWidget);
    });

    testWidgets('is read the first time it is opened, not before', (
      tester,
    ) async {
      // A listener with a dozen repositories should not pay for all of them to answer a question
      // about one.
      await pumpView(tester, repositories: [repository()]);
      expect(browsed, isEmpty);

      await tester.tap(find.text('Kikuyomi official'));
      await tester.pumpAndSettle();

      expect(browsed.single.id, 1);
    });

    testWidgets('is not read again once it has been', (tester) async {
      await pumpView(
        tester,
        repositories: [repository()],
        listings: {1: listing()},
      );

      await tester.tap(find.text('Kikuyomi official'));
      await tester.pumpAndSettle();

      expect(browsed, isEmpty);
    });

    testWidgets('can be refreshed and removed', (tester) async {
      await pumpView(tester, repositories: [repository()]);

      await tester.tap(find.byType(PopupMenuButton<VoidCallback>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Refresh'));
      await tester.pumpAndSettle();

      expect(refreshed.single.id, 1);

      await tester.tap(find.byType(PopupMenuButton<VoidCallback>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();

      expect(removed.single.id, 1);
    });

    testWidgets('shows a spinner instead of its menu while it works', (
      tester,
    ) async {
      await pumpView(tester, repositories: [repository()], busyWith: 1);

      expect(find.byType(PopupMenuButton<VoidCallback>), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('what it offers', () {
    Future<void> open(WidgetTester tester) async {
      await tester.tap(find.text('Kikuyomi official'));
      await tester.pumpAndSettle();
    }

    testWidgets('says it is still being read', (tester) async {
      await pumpView(tester, repositories: [repository()]);
      await open(tester);

      expect(find.textContaining('Reading what it offers'), findsOneWidget);
    });

    testWidgets('names each extension and its version', (tester) async {
      await pumpView(
        tester,
        repositories: [repository()],
        listings: {1: listing()},
      );
      await open(tester);

      expect(find.text('LibriVox 1.4.0'), findsOneWidget);
    });

    testWidgets('says what an extension would be allowed to contact', (
      tester,
    ) async {
      // §3.8's permissions summary, and the line that matters most before taking anything.
      await pumpView(
        tester,
        repositories: [repository()],
        listings: {
          1: listing(domains: ['librivox.org', 'archive.org']),
        },
      );
      await open(tester);

      expect(find.textContaining('librivox.org, archive.org'), findsOneWidget);
    });

    testWidgets('leaves out a version that has been withdrawn', (tester) async {
      await pumpView(
        tester,
        repositories: [repository()],
        listings: {1: listing(revoked: true)},
      );
      await open(tester);

      expect(find.text('LibriVox 1.4.0'), findsNothing);
      expect(find.textContaining('offers nothing'), findsOneWidget);
    });

    testWidgets('offers to install one that is not here', (tester) async {
      await pumpView(
        tester,
        repositories: [repository()],
        listings: {1: listing()},
      );
      await open(tester);

      await tester.tap(find.text('Install'));
      await tester.pumpAndSettle();

      expect(installs.single.id, 'org.example.librivox');
    });

    testWidgets('says so for one already here at the same version', (
      tester,
    ) async {
      // "Have I got this" is the question the row is being read to answer, so it is answered rather
      // than left blank.
      await pumpView(
        tester,
        repositories: [repository()],
        listings: {1: listing()},
        installed: {'org.example.librivox': 14},
      );
      await open(tester);

      expect(find.text('Installed'), findsOneWidget);
      expect(find.text('Install'), findsNothing);
    });

    testWidgets('offers the update when the repository has a newer one', (
      tester,
    ) async {
      // §3.3 orders versions by their code, whatever the version string says.
      await pumpView(
        tester,
        repositories: [repository()],
        listings: {1: listing()},
        installed: {'org.example.librivox': 13},
      );
      await open(tester);

      expect(find.text('Update'), findsOneWidget);
    });

    testWidgets('shows a spinner on the one being installed', (tester) async {
      await pumpView(
        tester,
        repositories: [repository()],
        listings: {1: listing()},
        installing: {'org.example.librivox'},
      );
      await tester.tap(find.text('Kikuyomi official'));
      // Pumped rather than settled: the spinner turns for ever, so there is nothing to settle to.
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Install'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
