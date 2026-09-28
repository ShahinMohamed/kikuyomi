import 'dart:io';

import 'package:flutter/material.dart';
import 'package:kikuyomi_data/kikuyomi_data.dart';
import 'package:kikuyomi_design_system/kikuyomi_design_system.dart';

import 'format.dart';
import 'history/listening_history_days.dart';

/// What the History screen shows, fed with data rather than reading it, so it can be tested without a
/// database or a covers folder (§2.10).
///
/// §6.4's `listening_session` rows, newest first, under a heading per day. The unit is a stretch of
/// listening rather than a chapter: the recorder splits a session whenever the chapter, the speed or
/// the position jumps, so one chapter heard in three sittings is three rows — which is what a history
/// is for, as against the "have I heard this" flag the book's own screen keeps.
class HistoryView extends StatelessWidget {
  const HistoryView({
    super.key,
    required this.days,
    required this.coverOf,
    required this.onOpenBook,
    required this.onRemove,
  });

  /// The history, newest day first.
  final List<HistoryDay> days;

  /// Where a book's cover file is, by its recorded name, or null when it has none.
  ///
  /// A function rather than the file itself, because the covers folder is a device path the view has
  /// no business knowing: `CoverFiles.fileOf` is what the screen passes in.
  final File? Function(String? coverFileName) coverOf;

  final ValueChanged<HistoryEntry> onOpenBook;

  /// Asked to forget an entry. The screen decides whether that means one row or the whole book.
  final ValueChanged<HistoryEntry> onRemove;

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) return const _NothingHeard();
    // Flattened once rather than nesting a list per day, so the whole history scrolls as one and a
    // long day does not scroll inside its own heading.
    final rows = <Widget>[];
    for (final day in days) {
      rows.add(_DayHeading(day: day));
      for (final entry in day.entries) {
        rows.add(
          _EntryTile(
            entry: entry,
            coverFile: coverOf(entry.coverFileName),
            onOpen: onOpenBook,
            onRemove: onRemove,
          ),
        );
      }
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: rows.length,
      itemBuilder: (context, index) => rows[index],
    );
  }
}

class _NothingHeard extends StatelessWidget {
  const _NothingHeard();

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.history,
            size: 48,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'Nothing here yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Once you have listened to something, or read it, it appears here '
            'with when.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    ),
  );
}

class _DayHeading extends StatelessWidget {
  const _DayHeading({required this.day});

  final HistoryDay day;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            day.label,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          // What the day came to. The reason anyone keeps a listening history at all is to see this
          // number, and adding it up by hand from a dozen rows is not a thing anyone does.
          Text(
            formatDuration(day.spent),
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({
    required this.entry,
    required this.coverFile,
    required this.onOpen,
    required this.onRemove,
  });

  final HistoryEntry entry;
  final File? coverFile;
  final ValueChanged<HistoryEntry> onOpen;
  final ValueChanged<HistoryEntry> onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      onTap: () => onOpen(entry),
      contentPadding: const EdgeInsets.only(left: 16, right: 4),
      leading: BookCover(
        file: coverFile,
        size: 56,
        semanticLabel: 'Cover of ${entry.bookTitle}',
      ),
      title: Text(
        entry.bookTitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            // A chapter purged from the source leaves its history behind, so this has to say
            // something rather than leave a gap where a title should be.
            entry.chapterTitle ?? 'A chapter that is no longer listed',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              fontStyle: entry.chapterTitle == null ? FontStyle.italic : null,
            ),
          ),
          Text(
            _when(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
      trailing: IconButton(
        tooltip: 'Remove from history',
        icon: const Icon(Icons.close),
        onPressed: () => onRemove(entry),
      ),
    );
  }

  /// When it was heard, for how long, and at what speed if that was not ordinary.
  String _when() {
    final at = formatTimeOfDay(entry.startedAt);
    final length = formatDuration(entry.spent);
    // Shown only when it is not 1x, and never for a book that was read, which has no speed. A
    // history of a book heard at 1.8x is a different record of time from one heard at normal speed,
    // and the figure explains why an hour of listening covered two.
    final rate = entry.speed;
    final speed = rate == null || rate == 1.0
        ? ''
        : ' · ${rate.toStringAsFixed(rate.truncateToDouble() == rate ? 0 : 1)}x';
    return '$at · $length$speed';
  }
}
