import 'dart:io';

import 'package:kikuyomi_source_api/kikuyomi_source_api.dart' show SourceKind;
import 'package:flutter/gestures.dart' show kSecondaryButton;
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show SemanticsAction;
import 'package:flutter_test/flutter_test.dart';
import 'package:kikuyomi/src/home_view.dart';
import 'package:kikuyomi_data/kikuyomi_data.dart'
    show BookRow, ContinueListeningBook, CoverFiles;
import 'package:kikuyomi_design_system/kikuyomi_design_system.dart';

final added = DateTime.utc(2026, 9, 14);

/// A covers folder that holds nothing: the views only name files in it.
final covers = CoverFiles(Directory('covers'));

BookRow inLibrary(int id, String title, {String? cover}) => BookRow(
  kind: SourceKind.audio,
  id: id,
  sourceId: 1,
  key: 'book-$id',
  title: title,
  genres: const [],
  totalDurationMs: 3725000,
  inLibrary: true,
  detailsFetched: true,
  userOverrides: const {},
  coverLocalPath: cover,
  createdAt: added,
  updatedAt: added,
);

ContinueListeningBook started(
  int id,
  String title, {
  String chapterTitle = 'Chapter Two',
  String? cover,
}) => ContinueListeningBook(
  bookId: id,
  title: title,
  author: 'An Author',
  totalDurationMs: 3725000,
  globalPositionMs: 65000,
  chapterTitle: chapterTitle,
  lastPlayedAt: added,
  coverFileName: cover,
);

/// A home showing [continueListening] and [library], recording what was tapped in [tapped].
Widget home({
  List<ContinueListeningBook> continueListening = const [],
  List<BookRow> library = const [],
  List<String>? tapped,
  Widget? header,
  ValueChanged<int>? onHide,
}) => MaterialApp(
  home: Scaffold(
    body: HomeView(
      continueListening: continueListening,
      library: library,
      covers: covers,
      emptyMessage: 'No books yet.',
      onResume: (bookId) => tapped?.add('resume $bookId'),
      onShowDetails: (bookId) => tapped?.add('details $bookId'),
      onHideFromContinue: onHide,
      header: header,
    ),
  ),
);

void main() {
  group('when many books are on the go', () {
    // Ten of them filled three rows of cards above the library, which is most of a window spent on
    // a list the listener was scrolling past.
    List<ContinueListeningBook> many(int count) => [
      for (var i = 0; i < count; i++) started(i + 1, 'Book $i'),
    ];

    /// A window wide enough for three cards of 320, so "one row" is a number this test knows.
    void threeWide(WidgetTester tester) {
      tester.view.physicalSize = const Size(1010, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
    }

    testWidgets('only a row of them is shown', (tester) async {
      threeWide(tester);
      await tester.pumpWidget(home(continueListening: many(10)));

      expect(find.text('Book 0'), findsOneWidget);
      expect(find.text('Book 2'), findsOneWidget);
      expect(find.text('Book 3'), findsNothing);
      expect(find.text('Show 7 more'), findsOneWidget);
    });

    testWidgets('the rest are one press away', (tester) async {
      threeWide(tester);
      await tester.pumpWidget(home(continueListening: many(10)));

      await tester.tap(find.text('Show 7 more'));
      await tester.pumpAndSettle();

      expect(find.text('Book 9'), findsOneWidget);
      expect(find.text('Show fewer'), findsOneWidget);
    });

    testWidgets('and can be put away again', (tester) async {
      threeWide(tester);
      await tester.pumpWidget(home(continueListening: many(10)));

      await tester.tap(find.text('Show 7 more'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Show fewer'));
      await tester.pumpAndSettle();

      expect(find.text('Book 3'), findsNothing);
    });

    testWidgets('a row that fits is left alone', (tester) async {
      threeWide(tester);
      await tester.pumpWidget(home(continueListening: many(3)));

      expect(find.text('Book 2'), findsOneWidget);
      expect(find.textContaining('Show'), findsNothing);
    });
  });

  testWidgets('shows the books to continue above the library', (tester) async {
    await tester.pumpWidget(
      home(
        continueListening: [started(2, 'Second Book')],
        library: [inLibrary(1, 'First Book'), inLibrary(2, 'Second Book')],
      ),
    );

    expect(find.text('An Author · Chapter Two'), findsOneWidget);
    expect(find.text('1:01:00 left'), findsOneWidget);
    expect(find.text('First Book'), findsOneWidget);
    expect(find.text('Second Book'), findsNWidgets(2));
    expect(
      tester.getTopLeft(find.text('Continue listening')).dy,
      lessThan(tester.getTopLeft(find.text('Library')).dy),
    );
  });

  testWidgets(
    'a book to continue resumes, and a library book shows its details',
    (tester) async {
      final tapped = <String>[];
      await tester.pumpWidget(
        home(
          continueListening: [started(2, 'Second Book')],
          library: [inLibrary(1, 'First Book'), inLibrary(2, 'Second Book')],
          tapped: tapped,
        ),
      );

      await tester.tap(find.text('An Author · Chapter Two'));
      await tester.tap(find.text('First Book'));
      expect(tapped, ['resume 2', 'details 1']);
    },
  );

  testWidgets("shows each book's cover, found by the name it has", (
    tester,
  ) async {
    await tester.pumpWidget(
      home(
        continueListening: [started(1, 'First Book', cover: '1.jpg')],
        library: [
          inLibrary(1, 'First Book', cover: '1.jpg'),
          inLibrary(2, 'Second Book'),
        ],
      ),
    );

    final shown = tester.widgetList<BookCover>(find.byType(BookCover));
    final first = covers.fileOf('1.jpg')!.path;
    expect([for (final cover in shown) cover.file?.path], [first, first, null]);
    expect(
      [for (final cover in shown) cover.semanticLabel],
      ['Cover of First Book', 'Cover of First Book', 'Cover of Second Book'],
    );
  });

  testWidgets('has no Continue listening before a book is started', (
    tester,
  ) async {
    await tester.pumpWidget(home(library: [inLibrary(1, 'First Book')]));
    expect(find.text('Continue listening'), findsNothing);
    expect(find.text('Library'), findsOneWidget);
  });

  testWidgets('says how to begin while there are no books', (tester) async {
    await tester.pumpWidget(home());
    expect(find.text('No books yet.'), findsOneWidget);
    expect(find.text('Library'), findsNothing);
  });

  group('a header, such as the backup reminder,', () {
    testWidgets('sits above the books', (tester) async {
      await tester.pumpWidget(
        home(
          continueListening: [started(1, 'First Book')],
          library: [inLibrary(1, 'First Book')],
          header: const Text('Reminder'),
        ),
      );
      expect(
        tester.getTopLeft(find.text('Reminder')).dy,
        lessThan(tester.getTopLeft(find.text('Continue listening')).dy),
      );
    });

    testWidgets('shows above the message while there are no books', (
      tester,
    ) async {
      await tester.pumpWidget(home(header: const Text('Reminder')));
      expect(find.text('Reminder'), findsOneWidget);
      expect(find.text('No books yet.'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Reminder')).dy,
        lessThan(tester.getTopLeft(find.text('No books yet.')).dy),
      );
    });
  });

  testWidgets('does not repeat a chapter title that is the book title', (
    tester,
  ) async {
    await tester.pumpWidget(
      home(
        continueListening: [started(1, 'A Book', chapterTitle: 'A Book')],
        library: [inLibrary(1, 'A Book')],
      ),
    );
    expect(find.text('An Author'), findsOneWidget);
  });

  group('the books to continue', () {
    Future<void> showTwo(WidgetTester tester, Size window) async {
      tester.view.physicalSize = window;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        home(
          continueListening: [started(1, 'One'), started(2, 'Two')],
          library: [inLibrary(3, 'Three')],
        ),
      );
    }

    testWidgets('sit side by side on a wide window', (tester) async {
      await showTwo(tester, const Size(1280, 800));
      expect(
        tester.getTopLeft(find.text('Two')).dy,
        tester.getTopLeft(find.text('One')).dy,
      );
    });

    testWidgets('sit in one row on a phone, swiped along', (tester) async {
      // They used to stack one above another, at least three of them, which was a third of a
      // phone's screen spent on a list the listener was scrolling past to reach their library.
      await showTwo(tester, const Size(400, 800));
      final one = tester.getTopLeft(find.text('One'));
      final two = tester.getTopLeft(find.text('Two'));
      expect(two.dy, one.dy);
      expect(two.dx, greaterThan(one.dx));
    });

    testWidgets('the next one shows at the edge, so there is plainly more', (
      tester,
    ) async {
      await showTwo(tester, const Size(400, 800));
      final secondCard = tester.getTopLeft(
        find.ancestor(of: find.text('Two'), matching: find.byType(Card)),
      );
      expect(secondCard.dx, lessThan(400), reason: 'visible at the edge');
      expect(secondCard.dx, greaterThan(200), reason: 'but only just');
    });

    testWidgets('swiping brings the next one into view', (tester) async {
      await showTwo(tester, const Size(400, 800));
      await tester.drag(find.text('One'), const Offset(-300, 0));
      await tester.pumpAndSettle();
      final second = tester.getRect(
        find.ancestor(of: find.text('Two'), matching: find.byType(Card)),
      );
      expect(second.left, greaterThanOrEqualTo(0));
      expect(second.right, lessThanOrEqualTo(400), reason: 'all of it in view');
    });

    testWidgets('one alone on a phone is simply the width of the screen', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(home(continueListening: [started(1, 'One')]));
      final card = tester.getSize(
        find.ancestor(of: find.text('One'), matching: find.byType(Card)),
      );
      expect(card.width, 400 - 32);
    });
  });

  group('taking a book off the shelf', () {
    Future<List<int>> showAndHide(
      WidgetTester tester,
      Future<void> Function(Finder card) open,
    ) async {
      final hidden = <int>[];
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        home(
          continueListening: [started(1, 'One'), started(2, 'Two')],
          onHide: hidden.add,
        ),
      );
      await open(find.text('Two'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove from Continue listening'));
      await tester.pumpAndSettle();
      return hidden;
    }

    testWidgets('a long press offers it', (tester) async {
      final hidden = await showAndHide(tester, tester.longPress);
      expect(hidden, [2]);
    });

    testWidgets('so does a right click', (tester) async {
      final hidden = await showAndHide(
        tester,
        (card) => tester.tap(card, buttons: kSecondaryButton),
      );
      expect(hidden, [2]);
    });

    testWidgets('and a screen reader can do it by name', (tester) async {
      // Someone who cannot see the card cannot long-press the right one, so the action has a name.
      final semantics = tester.ensureSemantics();
      final hidden = <int>[];
      await tester.pumpWidget(
        home(continueListening: [started(1, 'One')], onHide: hidden.add),
      );
      // The node a screen reader lands on when it reaches the card.
      final node = tester.getSemantics(find.text('One'));
      final actions = node.getSemanticsData().customSemanticsActionIds ?? [];
      expect(actions, hasLength(1), reason: 'on the card the reader focuses');
      final action = actions.single;
      node.owner!.performAction(node.id, SemanticsAction.customAction, action);
      await tester.pump();
      expect(hidden, [1]);
      semantics.dispose();
    });

    testWidgets('a tap still just continues the book', (tester) async {
      final tapped = <String>[];
      await tester.pumpWidget(
        home(
          continueListening: [started(1, 'One')],
          tapped: tapped,
          onHide: (_) {},
        ),
      );
      await tester.tap(find.text('One'));
      await tester.pumpAndSettle();
      expect(tapped, ['resume 1']);
      expect(find.text('Remove from Continue listening'), findsNothing);
    });

    testWidgets('is not offered where nothing would do it', (tester) async {
      await tester.pumpWidget(home(continueListening: [started(1, 'One')]));
      await tester.longPress(find.text('One'));
      await tester.pumpAndSettle();
      expect(find.text('Remove from Continue listening'), findsNothing);
    });
  });
}
