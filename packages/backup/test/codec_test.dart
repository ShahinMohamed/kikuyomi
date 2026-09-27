import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:fixnum/fixnum.dart';
import 'package:kikuyomi_backup/kikuyomi_backup.dart';
import 'package:kikuyomi_backup/src/generated/backup.pb.dart' as pb;
import 'package:kikuyomi_domain/kikuyomi_domain.dart';
import 'package:kikuyomi_source_api/kikuyomi_source_api.dart' show SourceKind;
import 'package:protobuf/protobuf.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

/// The message inside a backup file, to look at what was actually written.
pb.Backup unwrap(List<int> file) => pb.Backup.fromBuffer(gzip.decode(file));

/// A backup file holding [message], for writing files this build would not.
List<int> wrap(pb.Backup message) => gzip.encode(message.writeToBuffer());

/// The paths of the fields [message] leaves unset, looking into every nested message and every
/// element of every list.
List<String> unsetFields(GeneratedMessage message, [String path = '']) {
  final unset = <String>[];
  for (final field in message.info_.byIndex) {
    final name = '$path${field.name}';
    final value = message.getField(field.tagNumber);
    if (field.isRepeated) {
      final elements = value as List<Object?>;
      if (elements.isEmpty) unset.add(name);
      for (final element in elements) {
        if (element is GeneratedMessage) {
          unset.addAll(unsetFields(element, '$name.'));
        }
      }
    } else if (!message.hasField(field.tagNumber)) {
      unset.add(name);
    } else if (value is GeneratedMessage) {
      unset.addAll(unsetFields(value, '$name.'));
    }
  }
  return unset;
}

Matcher throwsCorrupt() => throwsA(isA<CorruptBackupException>());

void main() {
  group('writing', () {
    test('sets every field of the format from a fully populated library', () {
      // A new field in backup.proto fails this until the fixture fills it and the codec writes it.
      final message = unwrap(encodeBackup(fullLibrary(), info: info));
      expect(unsetFields(message), isEmpty);
    });

    test('a backup of audiobooks alone stays readable by older builds', () {
      // Only a book to read is something a version 2 reader would get wrong (ADR-0020).
      final message = unwrap(encodeBackup(minimalLibrary(), info: info));
      expect(message.minReaderVersion, backupMinReaderVersion);
    });

    test('a backup holding a book to read needs a reader that knows kinds', () {
      // A version 2 reader skips `kind` and would restore the book as an audiobook, without a word.
      final message = unwrap(encodeBackup(fullLibrary(), info: info));
      expect(message.minReaderVersion, backupMinReaderVersionWithText);
      expect(backupMinReaderVersionWithText, 3);
    });

    test('records the format versions and who wrote the backup, and when', () {
      final message = unwrap(encodeBackup(const LibrarySnapshot(), info: info));
      expect(message.formatVersion, backupFormatVersion);
      expect(message.minReaderVersion, backupMinReaderVersion);
      expect(
        message.createdAtMs.toInt(),
        info.createdAt.millisecondsSinceEpoch,
      );
      expect(message.appVersion, '0.1.0+1');
      expect(message.deviceId, 'this-pc');
    });
  });

  group('reading back', () {
    test('gives back exactly what was written', () {
      final file = encodeBackup(fullLibrary(), info: info);
      final decoded = decodeBackup(file);
      expect(decoded.skipped, isEmpty);
      expect(decoded.formatVersion, backupFormatVersion);

      // With the test above proving every field is written, writing the decoded library again and
      // getting the same message proves every field is read back too, into the right place.
      expect(
        unwrap(encodeBackup(decoded.library, info: decoded.info)),
        unwrap(file),
      );
    });

    test('keeps times to the millisecond, as instants in UTC', () {
      final decoded = decodeBackup(encodeBackup(fullLibrary(), info: info));
      final progress = decoded.library.books.single.progress!;
      expect(progress.updatedAt, at(11));
      expect(progress.updatedAt.isUtc, isTrue);
      expect(decoded.info.createdAt, info.createdAt);
    });

    test('keeps absent values absent', () {
      final book = decodeBackup(encodeBackup(minimalLibrary(), info: info))
          .library
          .books
          .single;
      expect(book.details.subtitle, isNull);
      expect(book.details.abridged, isNull);
      expect(book.details.seriesIndex, isNull);
      expect(book.playbackSpeed, isNull);
      expect(book.dateAdded, isNull);
      expect(book.progress, isNull);
      expect(book.sessions.single.chapterKey, isNull);
      expect(book.mediaFiles.first.durationMs, isNull);
      expect(book.mediaFiles.first.localPath, isNull);
      expect(book.chapters.single.listenedAt, isNull);
    });

    test('tells a file never probed for markers from one probed and found to have none', () {
      final files = decodeBackup(encodeBackup(minimalLibrary(), info: info))
          .library
          .books
          .single
          .mediaFiles;
      expect(files[0].embeddedMarkers, isNull);
      expect(files[1].embeddedMarkers, isEmpty);
    });
  });

  group('a file that is not a complete backup is refused whole', () {
    test('when it is not gzip at all', () {
      expect(
        () => decodeBackup(utf8.encode('not a backup, but long enough')),
        throwsCorrupt(),
      );
      expect(() => decodeBackup(const []), throwsCorrupt());
    });

    test('when it is cut short anywhere, rather than restored in part', () {
      final file = encodeBackup(fullLibrary(), info: info);
      for (var length = 0; length < file.length; length++) {
        expect(
          () => decodeBackup(file.sublist(0, length)),
          throwsCorrupt(),
          reason: 'cut to $length of ${file.length} bytes',
        );
      }
    });

    test('when it is damaged', () {
      final file = encodeBackup(fullLibrary(), info: info);
      // Past the ten-byte gzip header, whose timestamp and flags a decoder is free to ignore.
      for (var position = 10; position < file.length; position++) {
        final damaged = [...file]..[position] ^= 0xff;
        expect(
          () => decodeBackup(damaged),
          throwsCorrupt(),
          reason: 'byte $position of ${file.length} damaged',
        );
      }
    });

    test('when it holds random data', () {
      final random = Random(42);
      for (var run = 0; run < 200; run++) {
        final noise = [for (var i = 0; i < 64; i++) random.nextInt(256)];
        expect(
          () => decodeBackup(gzip.encode(noise)),
          throwsA(isA<BackupException>()),
        );
      }
    });

    test('when it is gzip holding something other than a backup', () {
      expect(() => decodeBackup(gzip.encode(const [])), throwsCorrupt());
      expect(
        () => decodeBackup(gzip.encode(utf8.encode('hello'))),
        throwsCorrupt(),
      );
    });
  });

  group('versions', () {
    test('a newer backup with only additive changes is read, skipping what is unknown', () {
      final message = unwrap(encodeBackup(fullLibrary(), info: info))
        ..formatVersion = 7;
      message.unknownFields.mergeVarintField(900, Int64(1));
      message.books.single.unknownFields.mergeLengthDelimitedField(
        901,
        utf8.encode('from the future'),
      );

      final decoded = decodeBackup(wrap(message));
      expect(decoded.formatVersion, 7);
      expect(decoded.skipped, isEmpty);
      expect(decoded.library.books.single.details.title, 'A Book');
    });

    test('a backup that needs a newer reader is refused, saying which', () {
      final message = unwrap(encodeBackup(fullLibrary(), info: info))
        ..formatVersion = backupFormatVersion + 1
        ..minReaderVersion = backupFormatVersion + 1;
      expect(
        () => decodeBackup(wrap(message)),
        throwsA(
          isA<UnsupportedBackupVersionException>()
              .having(
                (e) => e.minReaderVersion,
                'minReaderVersion',
                backupFormatVersion + 1,
              )
              .having(
                (e) => e.message,
                'message',
                contains('version ${backupFormatVersion + 1}'),
              ),
        ),
      );
    });

    test('a file without format versions is not taken for a backup', () {
      final message = unwrap(encodeBackup(fullLibrary(), info: info))
        ..clearFormatVersion();
      expect(() => decodeBackup(wrap(message)), throwsCorrupt());
    });

    test('credit roles and edited-field names from a newer build are skipped quietly', () {
      final message = unwrap(encodeBackup(fullLibrary(), info: info));
      final book = message.books.single;
      book.userOverrides.add('narratorPortrait');
      book.contributors.add(
        pb.Contributor(name: 'A Translator', ordinal: 1)
          ..unknownFields.mergeVarintField(2, Int64(7)),
      );

      final decoded = decodeBackup(wrap(message));
      final restored = decoded.library.books.single;
      expect(decoded.skipped, isEmpty);
      expect(restored.userOverrides, {BookField.title, BookField.coverUrl});
      expect([for (final c in restored.contributors) c.name], ['An Author']);
    });
  });

  group('items that cannot be restored faithfully', () {
    test('are left out and listed, and everything else is kept', () {
      final message = unwrap(encodeBackup(fullLibrary(), info: info));
      final book = message.books.single;
      book.bookmarks.add(
        pb.Bookmark(
          chapterKey: 'missing',
          positionMs: Int64(1),
          createdAtMs: Int64(1),
        ),
      );
      book.chapters.add(book.chapters.single.deepCopy()..title = 'A repeat');
      book.categories.add('No such category');
      message.books.add(
        pb.Book(sourceId: Int64(99), key: 'orphan', title: 'An Orphan'),
      );

      final decoded = decodeBackup(wrap(message));
      expect(decoded.skipped, [
        'chapter "one" of book "A Book": it appears more than once',
        'a bookmark of book "A Book": its chapter "missing" is not in the backup',
        'book "A Book" in category "No such category": the backup has no such category',
        'book "An Orphan": its source 99 is not in the backup',
      ]);

      final restored = decoded.library.books.single;
      expect(restored.chapters.single.title, 'Chapter One');
      expect(restored.bookmarks, hasLength(1));
      expect(restored.categories, ['Next up']);
      expect(restored.progress, isNotNull);
    });

    test('a bad segment costs its chapter the layout, not the chapter', () {
      final message = unwrap(encodeBackup(fullLibrary(), info: info));
      message.books.single.chapters.single.segments.add(
        pb.Segment(fileKey: 'part9.mp3'),
      );

      final decoded = decodeBackup(wrap(message));
      expect(decoded.skipped, [
        'the layout of chapter "one" of book "A Book": its file "part9.mp3" is not in the backup',
      ]);
      final chapter = decoded.library.books.single.chapters.single;
      expect(chapter.segments, isEmpty);
      expect(chapter.lastPositionMs, 12345);
    });

    test('progress in a chapter the backup lacks is left out', () {
      final message = unwrap(encodeBackup(fullLibrary(), info: info));
      message.books.single.playbackState.chapterKey = 'missing';

      final decoded = decodeBackup(wrap(message));
      expect(decoded.library.books.single.progress, isNull);
      expect(
        decoded.skipped.single,
        startsWith('the progress of book "A Book"'),
      );
    });

    test('a reading position in a chapter the backup lacks is left out', () {
      final message = unwrap(encodeBackup(fullLibrary(), info: info));
      message.books.single.readingState.chapterKey = 'missing';

      final decoded = decodeBackup(wrap(message));
      expect(decoded.library.books.single.reading, isNull);
      expect(
        decoded.skipped.single,
        startsWith('the reading position of book "A Book"'),
      );
    });

    test('a reading position outside its chapter is left out', () {
      for (final progress in [-0.1, 1.5, double.nan, double.infinity]) {
        final message = unwrap(encodeBackup(fullLibrary(), info: info));
        message.books.single.readingState.progress = progress;

        final decoded = decodeBackup(wrap(message));
        expect(
          decoded.library.books.single.reading,
          isNull,
          reason: '$progress',
        );
        expect(
          decoded.skipped.single,
          contains('is not a fraction of a chapter'),
        );
      }
    });

    test('a book from a backup older than kinds is an audiobook', () {
      final message = unwrap(encodeBackup(fullLibrary(), info: info))
        ..formatVersion = 2
        ..minReaderVersion = 1;
      message.books.single.clearKind();

      final decoded = decodeBackup(wrap(message));
      expect(decoded.library.books.single.kind, SourceKind.audio);
    });

    test(
      'a listening session keeps its place in history without its chapter',
      () {
        final message = unwrap(encodeBackup(fullLibrary(), info: info));
        message.books.single.listeningSessions.single.chapterKey = 'purged';

        final decoded = decodeBackup(wrap(message));
        expect(decoded.skipped, isEmpty);
        expect(decoded.library.books.single.sessions.single.chapterKey, isNull);
      },
    );

    test('impossible values are refused item by item', () {
      final message = unwrap(encodeBackup(fullLibrary(), info: info));
      final book = message.books.single;
      book.listeningSessions.single.speed = 0;
      book.bookmarks.single.positionMs = Int64(-1);
      book.playbackSpeed = double.nan;

      final decoded = decodeBackup(wrap(message));
      expect(decoded.skipped, [
        'the speed of book "A Book": NaN is not a speed',
        'a listening session of book "A Book": 0.0 is not a speed',
        'a bookmark of book "A Book": its position is negative',
      ]);
      final restored = decoded.library.books.single;
      expect(restored.playbackSpeed, isNull);
      expect(restored.sessions, isEmpty);
      expect(restored.bookmarks, isEmpty);
    });
  });
}
