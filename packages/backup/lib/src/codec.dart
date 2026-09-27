/// Reading and writing backup files: gzipped protobuf, as ADR-0008 decided.
///
/// A backup file is untrusted input, like extension output. It may have been cut short by a sync
/// client, edited, written by a newer build, or be some other file the user picked by mistake. So
/// decoding validates at the boundary, in two tiers:
///
/// - A file that is not a complete backup this build can read is refused whole, with a
///   [BackupException] saying why, and nothing is restored from it.
/// - A readable backup whose individual items cannot be restored faithfully, such as a bookmark in a
///   chapter the backup does not contain, has those items left out and listed in
///   [DecodedBackup.skipped]. One damaged item should never cost a user the rest of their library.
///
/// What a build does not know is not damage. Fields added by newer builds are skipped by protobuf
/// itself, and so are contributor roles and edited-field names this build has no meaning for, since
/// a newer build writing them is exactly the case ADR-0008 requires older builds to read.
library;

import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';
import 'package:kikuyomi_domain/kikuyomi_domain.dart';
import 'package:kikuyomi_source_api/kikuyomi_source_api.dart' show SourceKind;
import 'package:protobuf/protobuf.dart';

import 'generated/backup.pb.dart' as pb;
import 'gzip_frame.dart';

/// The format version this build writes, and the newest one it knows.
///
/// Raise it with every change to `proto/backup.proto` that a reader could care about, additive or
/// not, including a change in what a field means. `proto/backup.proto` lists what each version
/// changed.
const backupFormatVersion = 3;

/// The first format version whose chapters' `is_listened` is recorded, and so to be restored as
/// written (§4.5).
///
/// Builds before it worked listened state out from positions and wrote `is_listened` false for
/// every chapter, even one the listener finished. A restore from such a backup works the state out
/// from its positions instead; see `RestorePlan.listenedFromPositions`.
const backupListenedRecordedSince = 2;

/// The `min_reader_version` this build writes for a backup of audiobooks alone: the oldest format
/// version whose readers still restore it correctly.
///
/// Additive changes leave it alone, which is what keeps newer backups readable by older builds, as
/// ADR-0008 requires. Raise it only for a change an older reader would get silently wrong by
/// skipping fields it does not know. That should be rare enough to deserve its own ADR.
const backupMinReaderVersion = 1;

/// The `min_reader_version` of a backup holding a book to read (ADR-0020).
///
/// A reader before format version 3 skips `Book.kind` and restores such a book as an audiobook,
/// which is exactly the silent mistake the field exists to prevent. So it is raised, but only for a
/// backup where the mistake could happen: one of audiobooks alone stays readable by older builds.
const backupMinReaderVersionWithText = 3;

/// Who wrote a backup, and when.
final class BackupInfo {
  const BackupInfo({
    required this.createdAt,
    required this.appVersion,
    required this.deviceId,
  });

  final DateTime createdAt;

  /// The app's version as it reports it. For diagnosing a bad restore, never acted on.
  final String appVersion;

  /// The device that wrote the backup, in the form progress records use.
  final String deviceId;
}

/// A backup file, read.
final class DecodedBackup {
  const DecodedBackup({
    required this.formatVersion,
    required this.info,
    required this.library,
    this.skipped = const [],
  });

  /// The format version the writer implemented. It can be newer than [backupFormatVersion]: a
  /// newer build's backup stays readable when its changes were additive.
  final int formatVersion;

  final BackupInfo info;
  final LibrarySnapshot library;

  /// Items left out because they could not be restored faithfully, each described for a person to
  /// read. Empty for a backup this app wrote from its own database.
  final List<String> skipped;
}

/// A file that cannot be restored from at all.
sealed class BackupException implements Exception {
  const BackupException(this.message);

  /// What is wrong, for a person to read.
  final String message;
}

/// The file is not a complete Kikuyomi backup: not gzip, damaged, cut short, or something else.
final class CorruptBackupException extends BackupException {
  const CorruptBackupException(super.message);

  @override
  String toString() => 'CorruptBackupException: $message';
}

/// A backup from a newer build, in a form this build would restore incorrectly.
///
/// Told apart from a corrupt file because the way out is different: the file is fine, and updating
/// the app is what restores it.
final class UnsupportedBackupVersionException extends BackupException {
  UnsupportedBackupVersionException({required this.minReaderVersion})
    : super(
        'the backup needs a reader of format version $minReaderVersion, and this build reads '
        'up to $backupFormatVersion',
      );

  /// The oldest format version that can restore the backup.
  final int minReaderVersion;

  @override
  String toString() => 'UnsupportedBackupVersionException: $message';
}

/// Writes [library] as the bytes of a backup file.
///
/// Items are written in the order the snapshot lists them, so a reader that lists a library in a
/// stable order gets identical files from identical libraries.
Uint8List encodeBackup(LibrarySnapshot library, {required BackupInfo info}) {
  final message = pb.Backup(
    formatVersion: backupFormatVersion,
    minReaderVersion: library.books.any((book) => book.kind == SourceKind.text)
        ? backupMinReaderVersionWithText
        : backupMinReaderVersion,
    createdAtMs: _ms(info.createdAt),
    appVersion: info.appVersion,
    deviceId: info.deviceId,
    sources: library.sources.map(_encodeSource),
    categories: library.categories.map(
      (category) => pb.Category(
        name: category.name,
        sortOrder: category.sortOrder,
        flags: Int64(category.flags),
      ),
    ),
    books: library.books.map(_encodeBook),
  );
  return gzipFrame(message.writeToBuffer());
}

/// Reads the bytes of a backup file.
///
/// Throws [CorruptBackupException] for anything that is not a complete backup, and
/// [UnsupportedBackupVersionException] for a backup that needs a newer build. Never throws for an
/// individual item; those are left out and listed in [DecodedBackup.skipped].
DecodedBackup decodeBackup(List<int> bytes) {
  final payload = _payloadOf(bytes);

  final pb.Backup message;
  try {
    message = pb.Backup.fromBuffer(payload);
  } on InvalidProtocolBufferException catch (error) {
    throw CorruptBackupException('the backup cannot be read: ${error.message}');
  }

  _checkVersions(message.formatVersion, message.minReaderVersion);
  if (message.minReaderVersion > backupFormatVersion) {
    throw UnsupportedBackupVersionException(
      minReaderVersion: message.minReaderVersion,
    );
  }
  final createdAt = _creationTime(message.createdAtMs);

  final decoder = _Decoder();
  final library = decoder.library(message);
  return DecodedBackup(
    formatVersion: message.formatVersion,
    info: BackupInfo(
      createdAt: createdAt,
      appVersion: message.appVersion,
      deviceId: message.deviceId,
    ),
    library: library,
    skipped: List.unmodifiable(decoder.skipped),
  );
}

/// What a backup file holds at a glance: who wrote it, when, and how many books. Enough to list
/// backups for choosing one to restore.
final class BackupSummary {
  const BackupSummary({
    required this.formatVersion,
    required this.minReaderVersion,
    required this.info,
    required this.bookCount,
  });

  /// The format version the writer implemented.
  final int formatVersion;

  /// The oldest format version that can restore the backup.
  final int minReaderVersion;

  final BackupInfo info;

  /// The books the backup holds in the library. Books outside it that only carry progress are not
  /// counted, since a person counts the books in their library.
  final int bookCount;

  /// Whether this build can restore the backup.
  bool get isRestorable => minReaderVersion <= backupFormatVersion;
}

/// Reads what the backup file [bytes] holds at a glance, without decoding the library in it.
///
/// Listing a folder's backups reads every one, and decoding every book, chapter and session of each
/// only to count the books would keep the list waiting. This walks the top level of the message
/// instead, skipping every field but the few it needs, and looks into each book only for whether it
/// is in the library.
///
/// Throws [CorruptBackupException] for a file that is not a complete backup, as [decodeBackup] does.
/// A backup in a newer format that this build cannot restore is summarised rather than refused, so
/// that a list can say it needs a newer app; see [BackupSummary.isRestorable]. Whether each item in a
/// backup restores faithfully is only known from [decodeBackup].
BackupSummary readBackupSummary(List<int> bytes) {
  final payload = _payloadOf(bytes);
  var formatVersion = 0;
  var minReaderVersion = 0;
  var createdAtMs = Int64.ZERO;
  var appVersion = '';
  var deviceId = '';
  var bookCount = 0;
  try {
    final reader = CodedBufferReader(payload);
    // A field seen twice takes its last value, as protobuf's own parsing does.
    while (!reader.isAtEnd()) {
      final tag = reader.readTag();
      switch ((tag >> 3, tag & 7)) {
        case (_formatVersionField, _varint):
          formatVersion = reader.readUint32();
        case (_minReaderVersionField, _varint):
          minReaderVersion = reader.readUint32();
        case (_createdAtField, _varint):
          createdAtMs = reader.readInt64();
        case (_appVersionField, _lengthDelimited):
          appVersion = reader.readString();
        case (_deviceIdField, _lengthDelimited):
          deviceId = reader.readString();
        case (_booksField, _lengthDelimited):
          if (_isInLibrary(reader.readBytesAsView())) bookCount++;
        default:
          reader.skipField(tag);
      }
    }
  } on InvalidProtocolBufferException catch (error) {
    throw CorruptBackupException('the backup cannot be read: ${error.message}');
  } on FormatException catch (error) {
    throw CorruptBackupException('the backup cannot be read: ${error.message}');
  }

  _checkVersions(formatVersion, minReaderVersion);
  return BackupSummary(
    formatVersion: formatVersion,
    minReaderVersion: minReaderVersion,
    info: BackupInfo(
      createdAt: _creationTime(createdAtMs),
      appVersion: appVersion,
      deviceId: deviceId,
    ),
    bookCount: bookCount,
  );
}

// Field numbers from proto/backup.proto, for [readBackupSummary]. ADR-0008 makes field numbers
// permanent, so these cannot drift from the schema.
const _formatVersionField = 1;
const _minReaderVersionField = 2;
const _createdAtField = 3;
const _appVersionField = 4;
const _deviceIdField = 5;
const _booksField = 8;
const _bookInLibraryField = 21;

// Protobuf wire types.
const _varint = 0;
const _lengthDelimited = 2;

/// Whether the encoded `Book` message [book] is in the library.
bool _isInLibrary(List<int> book) {
  final reader = CodedBufferReader(book);
  var inLibrary = false;
  while (!reader.isAtEnd()) {
    final tag = reader.readTag();
    if (tag == (_bookInLibraryField << 3 | _varint)) {
      inLibrary = reader.readBool();
    } else {
      reader.skipField(tag);
    }
  }
  return inLibrary;
}

/// The protobuf message inside the backup file [bytes].
List<int> _payloadOf(List<int> bytes) {
  try {
    return gunzipFrame(bytes);
  } on FormatException catch (error) {
    throw CorruptBackupException(
      'not a complete backup file: ${error.message}',
    );
  }
}

/// Every backup ever written carries both. A file without them is some other gzipped data that
/// happened to parse, which protobuf's leniency makes more likely than it sounds.
void _checkVersions(int formatVersion, int minReaderVersion) {
  if (formatVersion == 0 || minReaderVersion == 0) {
    throw const CorruptBackupException(
      'the file has no format version, so it is not a Kikuyomi backup',
    );
  }
}

DateTime _creationTime(Int64 ms) =>
    _timeOrNull(ms) ??
    (throw const CorruptBackupException(
      'the backup has no valid creation time',
    ));

// Writing.

pb.Source _encodeSource(SourceSnapshot source) => pb.Source(
  id: Int64(source.id),
  extensionId: source.extensionId,
  key: source.key,
  name: source.name,
  lang: source.lang,
  contentRating: source.contentRating,
  isEnabled: source.isEnabled,
  isPinned: source.isPinned,
  lastUsedAtMs: _optionalMs(source.lastUsedAt),
);

pb.Book _encodeBook(BookSnapshot book) {
  final details = book.details;
  return pb.Book(
    sourceId: Int64(book.sourceId),
    key: book.key,
    title: details.title,
    subtitle: details.subtitle,
    description: details.description,
    coverUrl: details.coverUrl,
    seriesName: details.seriesName,
    seriesIndex: details.seriesIndex,
    genres: details.genres,
    language: details.language,
    publisher: details.publisher,
    publishedDate: details.publishedDate,
    isbn: details.isbn,
    abridged: details.abridged,
    status: details.status,
    contentRating: details.contentRating,
    totalDurationMs: _optionalInt64(details.totalDurationMs),
    webUrl: details.webUrl,
    userOverrides: [for (final field in book.userOverrides) field.name]..sort(),
    contributors: [
      for (final credit in book.contributors)
        pb.Contributor(
          name: credit.name,
          role: switch (credit.role) {
            ContributorRole.author =>
              pb.ContributorRole.CONTRIBUTOR_ROLE_AUTHOR,
            ContributorRole.narrator =>
              pb.ContributorRole.CONTRIBUTOR_ROLE_NARRATOR,
          },
          ordinal: credit.ordinal,
        ),
    ],
    inLibrary: book.inLibrary,
    dateAddedAtMs: _optionalMs(book.dateAdded),
    lastRefreshedAtMs: _optionalMs(book.lastRefreshedAt),
    detailsFetched: book.detailsFetched,
    playbackSpeed: book.playbackSpeed,
    kind: switch (book.kind) {
      SourceKind.audio => pb.BookKind.BOOK_KIND_AUDIO,
      SourceKind.text => pb.BookKind.BOOK_KIND_TEXT,
    },
    readingState: switch (book.reading) {
      final reading? => pb.ReadingState(
        chapterKey: reading.chapterKey,
        progress: reading.progress,
        updatedAtMs: _ms(reading.updatedAt),
      ),
      null => null,
    },
    createdAtMs: _ms(book.createdAt),
    updatedAtMs: _ms(book.updatedAt),
    mediaFiles: book.mediaFiles.map(_encodeFile),
    chapters: book.chapters.map(_encodeChapter),
    playbackState: switch (book.progress) {
      final progress? => pb.PlaybackState(
        chapterKey: progress.chapterKey,
        chapterPositionMs: Int64(progress.chapterPositionMs),
        globalPositionMs: Int64(progress.globalPositionMs),
        updatedAtMs: _ms(progress.updatedAt),
        deviceId: progress.deviceId,
      ),
      null => null,
    },
    listeningSessions: [
      for (final session in book.sessions)
        pb.ListeningSession(
          chapterKey: session.chapterKey,
          startedAtMs: _ms(session.startedAt),
          endedAtMs: _ms(session.endedAt),
          startGlobalMs: Int64(session.startGlobalMs),
          endGlobalMs: Int64(session.endGlobalMs),
          speed: session.speed,
          deviceId: session.deviceId,
        ),
    ],
    bookmarks: [
      for (final bookmark in book.bookmarks)
        pb.Bookmark(
          chapterKey: bookmark.chapterKey,
          positionMs: Int64(bookmark.positionMs),
          title: bookmark.title,
          note: bookmark.note,
          createdAtMs: _ms(bookmark.createdAt),
        ),
    ],
    categories: book.categories,
  );
}

pb.MediaFile _encodeFile(MediaFileSnapshot file) => pb.MediaFile(
  fileKey: file.fileKey,
  format: file.format,
  durationMs: _optionalInt64(file.durationMs),
  durationIsEstimate: file.durationIsEstimate,
  sizeBytes: _optionalInt64(file.sizeBytes),
  // A present but empty list is written as an empty message, which keeps "probed, none found" apart
  // from "never probed".
  embeddedMarkers: switch (file.embeddedMarkers) {
    final markers? => pb.MarkerList(
      markers: [
        for (final marker in markers)
          pb.Marker(title: marker.title, startMs: Int64(marker.startMs)),
      ],
    ),
    null => null,
  },
  localPath: file.localPath,
  downloadedAtMs: _optionalMs(file.downloadedAt),
);

pb.Chapter _encodeChapter(ChapterSnapshot chapter) => pb.Chapter(
  key: chapter.key,
  title: chapter.title,
  sourceIndex: chapter.sourceIndex,
  groupName: chapter.groupName,
  durationMs: _optionalInt64(chapter.durationMs),
  publishedAtMs: _optionalMs(chapter.publishedAt),
  isListened: chapter.isListened,
  listenedAtMs: _optionalMs(chapter.listenedAt),
  lastPositionMs: Int64(chapter.lastPositionMs),
  removedFromSource: chapter.removedFromSource,
  createdAtMs: _ms(chapter.createdAt),
  updatedAtMs: _ms(chapter.updatedAt),
  segments: [
    for (final segment in chapter.segments)
      pb.Segment(
        fileKey: segment.fileKey,
        startMs: Int64(segment.startMs),
        endMs: _optionalInt64(segment.endMs),
      ),
  ],
);

Int64 _ms(DateTime time) => Int64(time.millisecondsSinceEpoch);

Int64? _optionalMs(DateTime? time) => time == null ? null : _ms(time);

Int64? _optionalInt64(int? value) => value == null ? null : Int64(value);

// Reading.

/// The widest range `DateTime` accepts, in milliseconds either side of the epoch.
const _maxMs = 8640000000000000;

DateTime? _timeOrNull(Int64 ms) {
  final value = ms.toInt();
  return value.abs() > _maxMs
      ? null
      : DateTime.fromMillisecondsSinceEpoch(value, isUtc: true);
}

/// Thrown inside the decoder to leave out one item. Never escapes it.
final class _Skip implements Exception {
  const _Skip(this.reason);

  final String reason;
}

/// Turns a parsed message into a snapshot, collecting what it has to leave out.
final class _Decoder {
  final skipped = <String>[];

  LibrarySnapshot library(pb.Backup message) {
    final sources = _each(
      message.sources,
      describe: (source) => 'source ${source.id}',
      identity: (source) => source.id,
      decode: (source) => SourceSnapshot(
        id: source.id.toInt(),
        extensionId: source.hasExtensionId() ? source.extensionId : null,
        key: source.key,
        name: source.name,
        lang: source.lang,
        contentRating: source.hasContentRating() ? source.contentRating : null,
        isEnabled: source.isEnabled,
        isPinned: source.isPinned,
        lastUsedAt: source.hasLastUsedAtMs()
            ? _time(source.lastUsedAtMs)
            : null,
      ),
    );
    final sourceIds = {for (final source in sources) source.id};

    final categories = _each(
      message.categories,
      describe: (category) => 'category "${category.name}"',
      identity: (category) => category.name,
      decode: (category) {
        if (category.name.trim().isEmpty) throw const _Skip('it has no name');
        return CategorySnapshot(
          name: category.name,
          sortOrder: category.sortOrder,
          flags: category.flags.toInt(),
        );
      },
    );
    final categoryNames = {for (final category in categories) category.name};

    final books = _each(
      message.books,
      describe: (book) => 'book "${book.title}"',
      identity: (book) => (book.sourceId, book.key),
      decode: (book) {
        if (!sourceIds.contains(book.sourceId.toInt())) {
          throw _Skip('its source ${book.sourceId} is not in the backup');
        }
        return _book(book, 'book "${book.title}"', categoryNames);
      },
    );

    return LibrarySnapshot(
      sources: sources,
      categories: categories,
      books: books,
    );
  }

  BookSnapshot _book(pb.Book book, String what, Set<String> categoryNames) {
    if (book.key.isEmpty) throw const _Skip('it has no key');

    final details = BookDetailsSnapshot(
      title: book.title,
      subtitle: book.hasSubtitle() ? book.subtitle : null,
      description: book.hasDescription() ? book.description : null,
      coverUrl: book.hasCoverUrl() ? book.coverUrl : null,
      seriesName: book.hasSeriesName() ? book.seriesName : null,
      seriesIndex: book.hasSeriesIndex() ? book.seriesIndex : null,
      genres: book.genres,
      language: book.hasLanguage() ? book.language : null,
      publisher: book.hasPublisher() ? book.publisher : null,
      publishedDate: book.hasPublishedDate() ? book.publishedDate : null,
      isbn: book.hasIsbn() ? book.isbn : null,
      abridged: book.hasAbridged() ? book.abridged : null,
      status: book.hasStatus() ? book.status : null,
      contentRating: book.hasContentRating() ? book.contentRating : null,
      totalDurationMs: book.hasTotalDurationMs()
          ? book.totalDurationMs.toInt()
          : null,
      webUrl: book.hasWebUrl() ? book.webUrl : null,
    );
    final createdAt = _time(book.createdAtMs);
    final updatedAt = _time(book.updatedAtMs);
    final dateAdded = book.hasDateAddedAtMs()
        ? _time(book.dateAddedAtMs)
        : null;
    final lastRefreshedAt = book.hasLastRefreshedAtMs()
        ? _time(book.lastRefreshedAtMs)
        : null;

    // Names this build does not know come from a newer one, and are skipped as unknown fields are.
    final knownFields = BookField.values.asNameMap();
    final userOverrides = Set<BookField>.unmodifiable({
      for (final name in book.userOverrides) ?knownFields[name],
    });

    final contributors = <ContributorSnapshot>[];
    final credited = <(String, ContributorRole)>{};
    for (final credit in book.contributors) {
      final role = switch (credit.role) {
        pb.ContributorRole.CONTRIBUTOR_ROLE_AUTHOR => ContributorRole.author,
        pb.ContributorRole.CONTRIBUTOR_ROLE_NARRATOR =>
          ContributorRole.narrator,
        // A role from a newer build, skipped like an unknown field.
        _ => null,
      };
      final name = credit.name.trim();
      // The database credits a person once per role, so a repeat could not be stored anyway.
      if (role == null || name.isEmpty || !credited.add((name, role))) continue;
      contributors.add(
        ContributorSnapshot(name: name, role: role, ordinal: credit.ordinal),
      );
    }

    double? playbackSpeed;
    if (book.hasPlaybackSpeed()) {
      if (_isSpeed(book.playbackSpeed)) {
        playbackSpeed = book.playbackSpeed;
      } else {
        skipped.add('the speed of $what: ${book.playbackSpeed} is not a speed');
      }
    }

    final mediaFiles = _each(
      book.mediaFiles,
      describe: (file) => 'file "${file.fileKey}" of $what',
      identity: (file) => file.fileKey,
      decode: _file,
    );
    final fileKeys = {for (final file in mediaFiles) file.fileKey};

    final chapters = _each(
      book.chapters,
      describe: (chapter) => 'chapter "${chapter.key}" of $what',
      identity: (chapter) => chapter.key,
      decode: (chapter) =>
          _chapter(chapter, 'chapter "${chapter.key}" of $what', fileKeys),
    );
    final chapterKeys = {for (final chapter in chapters) chapter.key};

    ProgressSnapshot? progress;
    if (book.hasPlaybackState()) {
      progress = _each(
        [book.playbackState],
        describe: (_) => 'the progress of $what',
        decode: (state) => _progress(state, chapterKeys),
      ).firstOrNull;
    }

    ReadingSnapshot? reading;
    if (book.hasReadingState()) {
      reading = _each(
        [book.readingState],
        describe: (_) => 'the reading position of $what',
        decode: (state) => _reading(state, chapterKeys),
      ).firstOrNull;
    }

    final sessions = _each(
      book.listeningSessions,
      describe: (_) => 'a listening session of $what',
      decode: (session) => _session(session, chapterKeys),
    );
    final bookmarks = _each(
      book.bookmarks,
      describe: (_) => 'a bookmark of $what',
      decode: (bookmark) => _bookmark(bookmark, chapterKeys),
    );

    final memberships = <String>[];
    for (final name in book.categories) {
      if (!categoryNames.contains(name)) {
        skipped.add(
          '$what in category "$name": the backup has no such category',
        );
      } else if (!memberships.contains(name)) {
        memberships.add(name);
      }
    }

    return BookSnapshot(
      sourceId: book.sourceId.toInt(),
      key: book.key,
      details: details,
      userOverrides: userOverrides,
      contributors: List.unmodifiable(contributors),
      inLibrary: book.inLibrary,
      dateAdded: dateAdded,
      lastRefreshedAt: lastRefreshedAt,
      detailsFetched: book.detailsFetched,
      playbackSpeed: playbackSpeed,
      kind: switch (book.kind) {
        pb.BookKind.BOOK_KIND_TEXT => SourceKind.text,
        // A kind from a newer build arrives here as the default. A backup holding one names a
        // `min_reader_version` this build cannot meet, and is refused before it is read.
        _ => SourceKind.audio,
      },
      createdAt: createdAt,
      updatedAt: updatedAt,
      mediaFiles: mediaFiles,
      chapters: chapters,
      progress: progress,
      reading: reading,
      sessions: sessions,
      bookmarks: bookmarks,
      categories: List.unmodifiable(memberships),
    );
  }

  MediaFileSnapshot _file(pb.MediaFile file) {
    if (file.fileKey.isEmpty) throw const _Skip('it has no key');
    return MediaFileSnapshot(
      fileKey: file.fileKey,
      format: file.hasFormat() ? file.format : null,
      durationMs: file.hasDurationMs()
          ? _nonNegative(file.durationMs, 'its duration')
          : null,
      durationIsEstimate: file.durationIsEstimate,
      sizeBytes: file.hasSizeBytes()
          ? _nonNegative(file.sizeBytes, 'its size')
          : null,
      embeddedMarkers: file.hasEmbeddedMarkers()
          ? List.unmodifiable([
              for (final marker in file.embeddedMarkers.markers)
                TimelineMarker(
                  title: marker.title,
                  startMs: _nonNegative(marker.startMs, 'a marker'),
                ),
            ])
          : null,
      localPath: file.hasLocalPath() ? file.localPath : null,
      downloadedAt: file.hasDownloadedAtMs()
          ? _time(file.downloadedAtMs)
          : null,
    );
  }

  ChapterSnapshot _chapter(
    pb.Chapter chapter,
    String what,
    Set<String> fileKeys,
  ) {
    if (chapter.key.isEmpty) throw const _Skip('it has no key');
    final durationMs = chapter.hasDurationMs()
        ? _nonNegative(chapter.durationMs, 'its duration')
        : null;
    final publishedAt = chapter.hasPublishedAtMs()
        ? _time(chapter.publishedAtMs)
        : null;
    final listenedAt = chapter.hasListenedAtMs()
        ? _time(chapter.listenedAtMs)
        : null;
    final lastPositionMs = _nonNegative(chapter.lastPositionMs, 'its position');
    final createdAt = _time(chapter.createdAtMs);
    final updatedAt = _time(chapter.updatedAtMs);

    // A layout with any bad segment is dropped whole: a partial layout would put the chapter's audio
    // in the wrong place, where no layout only leaves it unplayable until the source reports it again.
    var segments = const <SegmentSnapshot>[];
    try {
      segments = List.unmodifiable([
        for (final segment in chapter.segments) _segment(segment, fileKeys),
      ]);
    } on _Skip catch (skip) {
      skipped.add('the layout of $what: ${skip.reason}');
    }

    return ChapterSnapshot(
      key: chapter.key,
      title: chapter.title,
      sourceIndex: chapter.sourceIndex,
      groupName: chapter.hasGroupName() ? chapter.groupName : null,
      durationMs: durationMs,
      publishedAt: publishedAt,
      isListened: chapter.isListened,
      listenedAt: listenedAt,
      lastPositionMs: lastPositionMs,
      removedFromSource: chapter.removedFromSource,
      createdAt: createdAt,
      updatedAt: updatedAt,
      segments: segments,
    );
  }

  SegmentSnapshot _segment(pb.Segment segment, Set<String> fileKeys) {
    if (!fileKeys.contains(segment.fileKey)) {
      throw _Skip('its file "${segment.fileKey}" is not in the backup');
    }
    final startMs = _nonNegative(segment.startMs, 'a segment start');
    final endMs = segment.hasEndMs() ? segment.endMs.toInt() : null;
    if (endMs != null && endMs <= startMs) {
      throw const _Skip('a segment ends before it starts');
    }
    return SegmentSnapshot(
      fileKey: segment.fileKey,
      startMs: startMs,
      endMs: endMs,
    );
  }

  ProgressSnapshot _progress(pb.PlaybackState state, Set<String> chapterKeys) {
    if (!chapterKeys.contains(state.chapterKey)) {
      throw _Skip('its chapter "${state.chapterKey}" is not in the backup');
    }
    return ProgressSnapshot(
      chapterKey: state.chapterKey,
      chapterPositionMs: _nonNegative(state.chapterPositionMs, 'its position'),
      globalPositionMs: _nonNegative(state.globalPositionMs, 'its position'),
      updatedAt: _time(state.updatedAtMs),
      deviceId: state.deviceId,
    );
  }

  ReadingSnapshot _reading(pb.ReadingState state, Set<String> chapterKeys) {
    if (!chapterKeys.contains(state.chapterKey)) {
      throw _Skip('its chapter "${state.chapterKey}" is not in the backup');
    }
    // A place outside the chapter is not a place, and NaN compares false with everything.
    if (!(state.progress >= 0 && state.progress <= 1)) {
      throw _Skip('${state.progress} is not a fraction of a chapter');
    }
    return ReadingSnapshot(
      chapterKey: state.chapterKey,
      progress: state.progress,
      updatedAt: _time(state.updatedAtMs),
    );
  }

  SessionSnapshot _session(
    pb.ListeningSession session,
    Set<String> chapterKeys,
  ) {
    final startedAt = _time(session.startedAtMs);
    final endedAt = _time(session.endedAtMs);
    if (endedAt.isBefore(startedAt)) {
      throw const _Skip('it ends before it starts');
    }
    if (!_isSpeed(session.speed)) {
      throw _Skip('${session.speed} is not a speed');
    }
    return SessionSnapshot(
      // A chapter the backup lacks does not cost the session: history outlives chapters, as it does
      // in the database.
      chapterKey:
          session.hasChapterKey() && chapterKeys.contains(session.chapterKey)
          ? session.chapterKey
          : null,
      startedAt: startedAt,
      endedAt: endedAt,
      startGlobalMs: _nonNegative(session.startGlobalMs, 'its start'),
      endGlobalMs: _nonNegative(session.endGlobalMs, 'its end'),
      speed: session.speed,
      deviceId: session.deviceId,
    );
  }

  BookmarkSnapshot _bookmark(pb.Bookmark bookmark, Set<String> chapterKeys) {
    if (!chapterKeys.contains(bookmark.chapterKey)) {
      throw _Skip('its chapter "${bookmark.chapterKey}" is not in the backup');
    }
    return BookmarkSnapshot(
      chapterKey: bookmark.chapterKey,
      positionMs: _nonNegative(bookmark.positionMs, 'its position'),
      title: bookmark.hasTitle() ? bookmark.title : null,
      note: bookmark.hasNote() ? bookmark.note : null,
      createdAt: _time(bookmark.createdAtMs),
    );
  }

  /// Decodes [messages] one at a time, leaving out, and recording, each one that [decode] rejects or
  /// whose [identity] repeats an earlier one's. Without an [identity], nothing counts as a repeat.
  List<T> _each<M, T>(
    Iterable<M> messages, {
    required String Function(M message) describe,
    required T Function(M message) decode,
    Object? Function(M message)? identity,
  }) {
    final seen = <Object?>{};
    final decoded = <T>[];
    for (final message in messages) {
      if (identity != null && !seen.add(identity(message))) {
        skipped.add('${describe(message)}: it appears more than once');
        continue;
      }
      try {
        decoded.add(decode(message));
      } on _Skip catch (skip) {
        skipped.add('${describe(message)}: ${skip.reason}');
      }
    }
    return List.unmodifiable(decoded);
  }
}

DateTime _time(Int64 ms) =>
    _timeOrNull(ms) ?? (throw const _Skip('a time is out of range'));

int _nonNegative(Int64 value, String name) {
  final result = value.toInt();
  if (result < 0) throw _Skip('$name is negative');
  return result;
}

bool _isSpeed(double speed) => speed > 0 && speed.isFinite;
