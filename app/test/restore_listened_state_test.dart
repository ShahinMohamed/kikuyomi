// Listened state through a real backup file and back: the codec, the planner and the database
// together, which only the app depends on all at once. Each part's own rules are tested in its own
// package; this is that they meet as intended.

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikuyomi_backup/kikuyomi_backup.dart';
import 'package:kikuyomi_data/kikuyomi_data.dart';
import 'package:kikuyomi_domain/kikuyomi_domain.dart';
import 'package:kikuyomi_test_support/kikuyomi_test_support.dart';

/// Chapters of 10, 20 and 5 minutes, one file each.
Future<int> addBook(KikuyomiDatabase db, Clock clock) => importLocalFolderBook(
  db,
  LocalFolderImport(
    key: 'C:/Books/A Book',
    title: 'A Book',
    authors: const ['An Author'],
    narrators: const [],
    tracks: [
      for (final (index, (name, durationMs)) in [
        ('Opening', 600000),
        ('Middle', 1200000),
        ('End', 300000),
      ].indexed)
        LocalTrackImport(
          file: LocalBookFile(
            path: 'C:/Books/A Book/${index + 1}.mp3',
            durationMs: durationMs,
            format: 'mp3',
          ),
          title: name,
        ),
    ],
  ),
  clock: clock,
);

/// Saves progress in chapter [chapterIndex] at [offsetMs], recording the chapter listened only when
/// [recording], as builds before listened state was recorded never did.
Future<void> listen(
  KikuyomiDatabase db,
  FakeClock clock,
  int bookId,
  int chapterIndex,
  int offsetMs, {
  bool recording = true,
}) async {
  final timeline = (await loadStoredPlayback(db, bookId)).timeline;
  final position = ChapterPosition(
    chapterId: timeline.chapterIds[chapterIndex],
    offsetMs: offsetMs,
  );
  await DriftPlaybackStore(db, deviceId: 'phone', clock: clock).saveProgress(
    bookId: bookId,
    position: position,
    globalMs: timeline.globalOf(position),
    listened: recording && timeline.isChapterListened(position),
  );
  clock.advance(const Duration(minutes: 1));
}

Future<List<int>> backUp(KikuyomiDatabase db, Clock clock) => createBackup(
  DriftBackupStore(db),
  clock: clock,
  appVersion: '0.1.0',
  deviceId: 'phone',
);

/// [file] as a build writing format version 1 would have written it. Protobuf keeps the last value
/// it reads for a field, so appending format_version (field 1, a varint) holding 1 is enough.
List<int> asVersionOne(List<int> file) =>
    gzip.encode([...gzip.decode(file), 0x08, 0x01]);

Future<List<bool>> flags(KikuyomiDatabase db) async => [
  for (final chapter in await (db.select(
    db.chapters,
  )..orderBy([(c) => OrderingTerm.asc(c.sourceIndex)])).get())
    chapter.isListened,
];

void main() {
  // Each test opens two databases, the one backed up and the one restored into, each on its own
  // in-memory executor. Drift's warning is about two databases sharing one executor, not this.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late KikuyomiDatabase original;
  late KikuyomiDatabase restored;
  late FakeClock clock;

  setUp(() {
    original = KikuyomiDatabase(NativeDatabase.memory());
    restored = KikuyomiDatabase(NativeDatabase.memory());
    clock = FakeClock(DateTime.utc(2026, 9, 21, 8));
  });

  tearDown(() async {
    await original.close();
    await restored.close();
  });

  test('a backup from before listened state was recorded keeps its finished books off Continue Listening', () async {
    final id = await addBook(original, clock);
    await listen(original, clock, id, 0, 600000, recording: false);
    await listen(original, clock, id, 2, 300000, recording: false);
    final file = asVersionOne(await backUp(original, clock));
    expect(decodeBackup(file).formatVersion, 1);

    await restoreBackup(file, library: DriftBackupStore(restored));

    expect(await flags(restored), [true, false, true]);
    expect(await watchContinueListening(restored, clock: clock).first, isEmpty);
  });

  test('a backup that records listened state keeps a chapter marked not listened so', () async {
    final id = await addBook(original, clock);
    await listen(original, clock, id, 0, 600000);
    await listen(original, clock, id, 1, 60000);
    final opening = (await original.select(original.chapters).get()).first;
    await setChaptersListened(
      original,
      bookId: id,
      chapterIds: {opening.id},
      listened: false,
      clock: clock,
    );
    final file = await backUp(original, clock);
    expect(decodeBackup(file).formatVersion, backupFormatVersion);

    await restoreBackup(file, library: DriftBackupStore(restored));

    expect(await flags(restored), [false, false, false]);
    final shelf = await watchContinueListening(restored, clock: clock).first;
    expect(shelf.single.chapterTitle, 'Middle');
  });
}
