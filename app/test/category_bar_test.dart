// The shelves above the library, and choosing between them.
//
// Two decisions carry the weight. "All" is not a category — it is the absence of a filter, always
// first, so a listener who has filed nothing sees what they saw before categories existed. And a bar
// with nothing to choose between is not shown at all, because a row of one chip saying "All" takes
// the width of the window to offer nothing.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikuyomi/src/library/category_bar.dart';
import 'package:kikuyomi_data/kikuyomi_data.dart' show CategoryRow;

CategoryRow category(int id, String name) =>
    CategoryRow(id: id, name: name, sortOrder: id, flags: 0);

Widget bar({
  List<CategoryRow> categories = const [],
  Map<int, int> counts = const {},
  int? selected,
  List<int?>? chose,
}) => MaterialApp(
  home: Scaffold(
    body: CategoryBar(
      categories: categories,
      counts: counts,
      selected: selected,
      onSelected: (id) => chose?.add(id),
    ),
  ),
);

void main() {
  testWidgets('shows nothing at all when there are no categories', (
    tester,
  ) async {
    await tester.pumpWidget(bar());

    expect(find.text('All'), findsNothing);
    expect(find.byType(ChoiceChip), findsNothing);
  });

  testWidgets('puts All first, and it is what is chosen to begin with', (
    tester,
  ) async {
    await tester.pumpWidget(
      bar(categories: [category(1, 'Fiction'), category(2, 'History')]),
    );

    final chips = tester.widgetList<ChoiceChip>(find.byType(ChoiceChip));
    expect(chips.first.selected, isTrue);
    expect(find.text('All'), findsOneWidget);
  });

  testWidgets('says how many books each shelf holds', (tester) async {
    await tester.pumpWidget(
      bar(categories: [category(1, 'Fiction')], counts: {1: 12}),
    );

    expect(find.text('Fiction  12'), findsOneWidget);
  });

  testWidgets('an empty shelf says nought rather than nothing', (tester) async {
    // It is a shelf that exists and holds nothing, which is different from a shelf whose count has
    // not arrived. Leaving the number off would make those look the same.
    await tester.pumpWidget(bar(categories: [category(1, 'Fiction')]));

    expect(find.text('Fiction  0'), findsOneWidget);
  });

  testWidgets('choosing one says which', (tester) async {
    final chose = <int?>[];
    await tester.pumpWidget(
      bar(categories: [category(1, 'Fiction')], chose: chose),
    );

    await tester.tap(find.text('Fiction  0'));
    await tester.pump();

    expect(chose, [1]);
  });

  testWidgets('choosing All asks for no filter at all', (tester) async {
    // Null, not an id and not an empty set: "no category chosen" is a different thing from "a
    // category that happens to hold nothing", and only one of them should show the whole library.
    final chose = <int?>[];
    await tester.pumpWidget(
      bar(categories: [category(1, 'Fiction')], selected: 1, chose: chose),
    );

    await tester.tap(find.text('All'));
    await tester.pump();

    expect(chose, [null]);
  });

  testWidgets('the chosen shelf is the one marked', (tester) async {
    await tester.pumpWidget(
      bar(
        categories: [category(1, 'Fiction'), category(2, 'History')],
        selected: 2,
      ),
    );

    final chips = tester.widgetList<ChoiceChip>(find.byType(ChoiceChip));
    expect(chips.map((c) => c.selected), [false, false, true]);
  });
}
