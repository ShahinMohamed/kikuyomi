// Choosing which shelves a book sits on.
//
// The distinction worth testing is between "changed my mind" and "on no shelf at all". Both look
// like nothing chosen, and conflating them would make taking a book off its last category silently
// do nothing.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikuyomi/src/library/file_book_dialog.dart';
import 'package:kikuyomi_data/kikuyomi_data.dart' show CategoryRow;

CategoryRow category(int id, String name) =>
    CategoryRow(id: id, name: name, sortOrder: id, flags: 0);

final someCategories = [category(1, 'Fiction'), category(2, 'History')];

/// Opens the dialog and records what it returned in [answers], and any request to manage.
Future<void> open(
  WidgetTester tester, {
  List<CategoryRow> categories = const [],
  Set<int> chosen = const {},
  required List<Set<int>?> answers,
  List<String>? managed,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async => answers.add(
              await chooseBookCategories(
                context,
                bookTitle: 'A Book',
                categories: categories,
                chosen: chosen,
                onManageCategories: () => managed?.add('manage'),
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('offers every category, with the ones it is in ticked', (
    tester,
  ) async {
    final answers = <Set<int>?>[];
    await open(
      tester,
      categories: someCategories,
      chosen: {2},
      answers: answers,
    );

    final boxes = tester.widgetList<CheckboxListTile>(
      find.byType(CheckboxListTile),
    );
    expect(boxes.map((b) => b.value), [false, true]);
  });

  testWidgets('saving gives back what was ticked', (tester) async {
    final answers = <Set<int>?>[];
    await open(tester, categories: someCategories, answers: answers);

    await tester.tap(find.text('Fiction'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(answers, [
      {1},
    ]);
  });

  testWidgets('unticking the last one gives an empty set, not nothing', (
    tester,
  ) async {
    // The distinction that matters: an empty set means "take it off every shelf" and null means
    // "leave it alone". A caller that treated them alike could never take a book off its last shelf.
    final answers = <Set<int>?>[];
    await open(
      tester,
      categories: someCategories,
      chosen: {1},
      answers: answers,
    );

    await tester.tap(find.text('Fiction'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(answers.single, isNotNull);
    expect(answers.single, isEmpty);
  });

  testWidgets('cancelling gives nothing at all', (tester) async {
    final answers = <Set<int>?>[];
    await open(
      tester,
      categories: someCategories,
      chosen: {1},
      answers: answers,
    );

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(answers, [null]);
  });

  testWidgets('with no categories it offers the way to make one', (
    tester,
  ) async {
    // A list with nothing in it and a Save button is a question with no answers.
    final answers = <Set<int>?>[];
    final managed = <String>[];
    await open(tester, answers: answers, managed: managed);

    expect(find.byType(CheckboxListTile), findsNothing);
    await tester.tap(find.text('Manage categories'));
    await tester.pumpAndSettle();

    expect(managed, ['manage']);
    expect(answers, [null], reason: 'and files the book under nothing');
  });
}
