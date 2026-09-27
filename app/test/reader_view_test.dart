// The reader's page (ADR-0019): what it draws from blocks, the way on to the next chapter, and the
// place it reports and comes back to.

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikuyomi/src/reading/reader_view.dart';
import 'package:kikuyomi_source_api/kikuyomi_source_api.dart';

/// A PNG of one transparent pixel.
final onePixel = Uint8List.fromList([
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

Widget reader(ReaderView view) => MaterialApp(home: Scaffold(body: view));

List<ContentBlock> paragraphs(int count) => [
  for (var i = 0; i < count; i++)
    ParagraphBlock([TextRun('Paragraph $i. ${'Words go on. ' * 20}')]),
];

void main() {
  testWidgets('draws each kind of block', (tester) async {
    await tester.pumpWidget(
      reader(
        const ReaderView(
          blocks: [
            HeadingBlock(1, [TextRun('Chapter One')]),
            ParagraphBlock([TextRun('It '), TextRun('began', italic: true)]),
            ListItemBlock([TextRun('first')], number: 1),
            ListItemBlock([TextRun('loose')]),
            QuoteBlock([TextRun('Said someone.')]),
            PreformattedBlock('code()'),
            RuleBlock(),
          ],
        ),
      ),
    );
    expect(find.text('Chapter One'), findsOneWidget);
    expect(find.textContaining('It began', findRichText: true), findsOneWidget);
    expect(find.text('1.'), findsOneWidget);
    expect(find.text('•'), findsOneWidget);
    expect(
      find.textContaining('Said someone.', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('code()'), findsOneWidget);
    expect(find.text('⁂'), findsOneWidget);
  });

  testWidgets(
    'shows a picture from inside the book, and says what a missing one was of',
    (tester) async {
      await tester.pumpWidget(
        reader(
          ReaderView(
            blocks: [
              ImageBlock(Uri(path: 'OEBPS/map.png')),
              ImageBlock(Uri(path: 'OEBPS/lost.png'), alt: 'A lost map'),
            ],
            pictures: {'OEBPS/map.png': onePixel},
          ),
        ),
      );
      expect(find.byType(Image), findsOneWidget);
      expect(find.text('[A lost map]'), findsOneWidget);
    },
  );

  testWidgets('an empty chapter says so', (tester) async {
    await tester.pumpWidget(reader(const ReaderView(blocks: [])));
    expect(
      find.text('This chapter has nothing in it to read.'),
      findsOneWidget,
    );
  });

  testWidgets('offers the next chapter, and says the end at the last', (
    tester,
  ) async {
    var went = 0;
    await tester.pumpWidget(
      reader(
        ReaderView(
          blocks: const [
            ParagraphBlock([TextRun('Short.')]),
          ],
          onPrevious: () {},
          onNext: () => went++,
        ),
      ),
    );
    await tester.tap(find.text('Next chapter'));
    expect(went, 1);
    expect(find.text('Previous'), findsOneWidget);

    await tester.pumpWidget(
      reader(
        const ReaderView(
          blocks: [
            ParagraphBlock([TextRun('Short.')]),
          ],
        ),
      ),
    );
    expect(find.text('The end'), findsOneWidget);
    expect(find.text('Next chapter'), findsNothing);
  });

  testWidgets('reports where the reader is, and reaching the end', (
    tester,
  ) async {
    final reported = <(double, bool)>[];
    await tester.pumpWidget(
      reader(
        ReaderView(
          blocks: paragraphs(80),
          onProgress: (progress, atEnd) => reported.add((progress, atEnd)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -500),
    );
    await tester.pumpAndSettle();
    expect(reported.last.$1, greaterThan(0));
    expect(reported.last.$2, isFalse);

    await tester.fling(
      find.byType(SingleChildScrollView),
      const Offset(0, -100000),
      20000,
    );
    await tester.pumpAndSettle();
    expect(reported.last.$1, 1.0);
    expect(reported.last.$2, isTrue);
  });

  testWidgets(
    'a chapter that fits on the screen is not finished by being shown',
    (tester) async {
      final reported = <(double, bool)>[];
      await tester.pumpWidget(
        reader(
          ReaderView(
            blocks: const [
              ParagraphBlock([TextRun('Short.')]),
            ],
            onProgress: (progress, atEnd) => reported.add((progress, atEnd)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(reported.where((r) => r.$2), isEmpty);
    },
  );

  testWidgets('opens where the reader left off', (tester) async {
    await tester.pumpWidget(
      reader(ReaderView(blocks: paragraphs(80), initialProgress: 0.5)),
    );
    await tester.pumpAndSettle();
    final position = tester
        .state<ScrollableState>(find.byType(Scrollable).first)
        .position;
    expect(position.pixels, closeTo(position.maxScrollExtent / 2, 1));
  });
}
