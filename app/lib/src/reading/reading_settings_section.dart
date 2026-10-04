import 'package:flutter/material.dart';
import 'package:kikuyomi_domain/kikuyomi_domain.dart'
    show ReaderMode, defaultReadingWordsPerMinute;

import 'reading_time.dart';

/// The slowest and fastest paces the slider offers, in words a minute.
///
/// Roughly the range of adult silent reading: a careful reader of difficult prose at one end, and
/// someone skimming familiar material at the other. Past either end the figure beside a chapter
/// stops being a useful guess.
const slowestReading = 100;
const fastestReading = 600;

/// A chapter of middling length, for showing what a pace comes to. Four thousand words is about
/// fifteen pages, which is what most novels' chapters run to.
const _exampleChapter = 4000;

/// The Reading section of Settings: how long a chapter takes, and whether to say so.
///
/// Fed with the value rather than watching it, so it can be tested on its own.
class ReadingSettingsSection extends StatelessWidget {
  const ReadingSettingsSection({
    super.key,
    required this.readerMode,
    required this.wordsPerMinute,
    required this.onReaderModeChanged,
    required this.onChanged,
  });

  /// How chapters move through the reader.
  final ReaderMode readerMode;

  /// The reader's pace, or zero for one who would rather not be told how long a chapter takes.
  final int wordsPerMinute;

  /// A new way to move through a chapter.
  final ValueChanged<ReaderMode> onReaderModeChanged;

  /// A new pace, or zero to stop showing the estimate.
  final ValueChanged<int> onChanged;

  bool get _on => wordsPerMinute > 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final example = readingTime(
      _exampleChapter,
      wordsPerMinute: _on ? wordsPerMinute : defaultReadingWordsPerMinute,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Reading',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            'An audiobook chapter is as long as its recording. A chapter of a '
            'book to read is as long as it takes you, so Kikuyomi works it out '
            'from how many words it holds and how fast you read.',
            style: theme.textTheme.bodyMedium,
          ),
        ),
        const ListTile(
          title: Text('Page movement'),
          subtitle: Text('Scroll vertically or swipe between horizontal pages'),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: SegmentedButton<ReaderMode>(
            segments: const [
              ButtonSegment(
                value: ReaderMode.verticalScroll,
                icon: Icon(Icons.swap_vert),
                label: Text('Vertical'),
              ),
              ButtonSegment(
                value: ReaderMode.horizontalPages,
                icon: Icon(Icons.swap_horiz),
                label: Text('Horizontal'),
              ),
            ],
            selected: {readerMode},
            showSelectedIcon: false,
            onSelectionChanged: (selected) =>
                onReaderModeChanged(selected.single),
          ),
        ),
        SwitchListTile(
          title: const Text('Show how long a chapter takes'),
          subtitle: const Text('Beside each chapter of a book to read'),
          value: _on,
          onChanged: (on) => onChanged(on ? defaultReadingWordsPerMinute : 0),
        ),
        if (_on) ...[
          ListTile(
            title: const Text('Your reading speed'),
            subtitle: Text(
              '$wordsPerMinute words a minute — a ${_exampleChapter ~/ 1000},000-word '
              'chapter takes ${formatReadingTime(example!)}',
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Slider(
              value: wordsPerMinute
                  .clamp(slowestReading, fastestReading)
                  .toDouble(),
              min: slowestReading.toDouble(),
              max: fastestReading.toDouble(),
              // Ten words a minute is finer than anyone can tell about their own reading, and it
              // keeps the slider from landing on figures that suggest more precision than there is.
              divisions: (fastestReading - slowestReading) ~/ 10,
              label: '$wordsPerMinute',
              onChanged: (chosen) => onChanged(chosen.round()),
            ),
          ),
        ],
      ],
    );
  }
}
