// How long a chapter of a book to read takes, and how that is said.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikuyomi/src/reading/reading_settings_section.dart';
import 'package:kikuyomi/src/reading/reading_time.dart';
import 'package:kikuyomi_domain/kikuyomi_domain.dart'
    show defaultReadingWordsPerMinute;

void main() {
  group('counting words', () {
    test('counts what a person would call a word', () {
      // An apostrophe and a hyphen hold a word together; punctuation between words does not make
      // another one.
      expect(wordsIn("It began — don't you think? — well-meaning."), 6);
    });

    test('counts nothing in nothing', () {
      expect(wordsIn(''), 0);
      expect(wordsIn('   \n  '), 0);
    });

    test('counts words that are not in English', () {
      expect(wordsIn('ひらがな カタカナ'), 2);
      expect(wordsIn('Дом 42'), 2);
    });
  });

  group('how long that takes', () {
    test('is the words over the pace', () {
      expect(
        readingTime(2500, wordsPerMinute: 250),
        const Duration(minutes: 10),
      );
      expect(
        readingTime(2500, wordsPerMinute: 500),
        const Duration(minutes: 5),
      );
    });

    test('is nothing to say for a chapter never counted', () {
      // A chapter from a source, before its text has been fetched once.
      expect(readingTime(null, wordsPerMinute: 250), isNull);
    });

    test('is nothing to say for a reader who would rather not know', () {
      expect(readingTime(2500, wordsPerMinute: 0), isNull);
    });

    test('is hedged when it is said, because it is a guess', () {
      expect(formatReadingTime(const Duration(minutes: 42)), '~42 m');
      expect(formatReadingTime(const Duration(minutes: 75)), '~1 h 15 m');
      expect(formatReadingTime(const Duration(seconds: 20)), '~< 1 m');
    });

    test('the pace it assumes is the one the studies give', () {
      expect(defaultReadingWordsPerMinute, 250);
    });
  });

  group('the Reading settings', () {
    Widget section(int rate, List<int> chosen) => MaterialApp(
      home: Scaffold(
        body: ReadingSettingsSection(
          wordsPerMinute: rate,
          onChanged: chosen.add,
        ),
      ),
    );

    testWidgets('say what the pace comes to for a real chapter', (
      tester,
    ) async {
      await tester.pumpWidget(section(250, []));

      expect(find.textContaining('250 words a minute'), findsOneWidget);
      expect(find.textContaining('~16 m'), findsOneWidget);
    });

    testWidgets('turn the estimate off, and back on at the usual pace', (
      tester,
    ) async {
      final chosen = <int>[];
      await tester.pumpWidget(section(250, chosen));

      await tester.tap(find.byType(SwitchListTile));
      expect(chosen, [0]);

      await tester.pumpWidget(section(0, chosen));
      expect(find.textContaining('words a minute'), findsNothing);
      await tester.tap(find.byType(SwitchListTile));
      expect(chosen.last, defaultReadingWordsPerMinute);
    });

    testWidgets('offer a range a person could actually read at', (
      tester,
    ) async {
      await tester.pumpWidget(section(250, []));

      final slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.min, slowestReading.toDouble());
      expect(slider.max, fastestReading.toDouble());
    });
  });
}
