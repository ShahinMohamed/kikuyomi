/// A library as backup and restore exchange it: immutable values with no database ids.
///
/// Two packages meet here. The `backup` package writes snapshots into backup files and plans restores
/// from them; the data package reads snapshots from the database and writes restores into it. §2.4
/// lets neither depend on the other, so the values they share live in the domain, just as
/// `PlaybackStore` joins playback to the database. ADR-0008 already defines the backup format in
/// terms of domain values rather than tables.
///
/// A snapshot is not the backup format itself. The protobuf messages a backup file is written in are
/// mutable, full of `Int64`s, and unable to tell a missing value from a default except field by
/// field, so they never leave the `backup` package's codec.
///
/// A snapshot refers to things by the identities §4.4 defines, as the format does: a source by its
/// stable id, a book by its source and key, chapters and files by key within their book, and
/// categories by name. That is what lets a snapshot of one library be compared with, and restored
/// into, another.
///
/// Lists are not copied on the way in. Whoever builds a snapshot hands over lists it will not change
/// afterwards.
library;

import 'package:kikuyomi_source_api/kikuyomi_source_api.dart' show SourceKind;

import '../library/book_field.dart';
import '../library/contributor_role.dart';
import '../timeline/timeline_input.dart';

/// A whole library, or the part of one that a backup holds.
final class LibrarySnapshot {
  const LibrarySnapshot({
    this.sources = const [],
    this.categories = const [],
    this.books = const [],
  });

  final List<SourceSnapshot> sources;
  final List<CategorySnapshot> categories;
  final List<BookSnapshot> books;
}

/// A content source, as §4.3's `source` table describes it.
final class SourceSnapshot {
  const SourceSnapshot({
    required this.id,
    required this.key,
    required this.name,
    required this.lang,
    this.extensionId,
    this.contentRating,
    this.isEnabled = true,
    this.isPinned = false,
    this.lastUsedAt,
  });

  /// The stable id of §3.7, which is also the source's identity.
  final int id;
  final String key;
  final String name;
  final String lang;

  /// Null for a built-in source.
  final String? extensionId;
  final String? contentRating;
  final bool isEnabled;
  final bool isPinned;
  final DateTime? lastUsedAt;
}

/// A manual library category (ADR-0009), identified by its name.
final class CategorySnapshot {
  const CategorySnapshot({
    required this.name,
    required this.sortOrder,
    this.flags = 0,
  });

  final String name;
  final int sortOrder;

  /// Per-category sort, filter and display settings, packed as §4.3 describes.
  final int flags;
}

/// A book's source-provided details. Immutable.
///
/// Values are kept by [BookField], so that a restore can take individual fields from one set of
/// details into another, which is how it carries over a user's edits.
final class BookDetailsSnapshot {
  BookDetailsSnapshot({
    required String title,
    String? subtitle,
    String? description,
    String? coverUrl,
    String? seriesName,
    double? seriesIndex,
    List<String> genres = const [],
    String? language,
    String? publisher,
    String? publishedDate,
    String? isbn,
    bool? abridged,
    String? status,
    String? contentRating,
    int? totalDurationMs,
    String? webUrl,
  }) : _values = Map.unmodifiable(<BookField, Object?>{
         BookField.title: title,
         BookField.subtitle: subtitle,
         BookField.description: description,
         BookField.coverUrl: coverUrl,
         BookField.seriesName: seriesName,
         BookField.seriesIndex: seriesIndex,
         BookField.genres: List<String>.unmodifiable(genres),
         BookField.language: language,
         BookField.publisher: publisher,
         BookField.publishedDate: publishedDate,
         BookField.isbn: isbn,
         BookField.abridged: abridged,
         BookField.status: status,
         BookField.contentRating: contentRating,
         BookField.totalDurationMs: totalDurationMs,
         BookField.webUrl: webUrl,
       });

  BookDetailsSnapshot._(this._values);

  final Map<BookField, Object?> _values;

  String get title => _values[BookField.title]! as String;
  String? get subtitle => _values[BookField.subtitle] as String?;
  String? get description => _values[BookField.description] as String?;
  String? get coverUrl => _values[BookField.coverUrl] as String?;
  String? get seriesName => _values[BookField.seriesName] as String?;
  double? get seriesIndex => _values[BookField.seriesIndex] as double?;
  List<String> get genres => _values[BookField.genres]! as List<String>;
  String? get language => _values[BookField.language] as String?;
  String? get publisher => _values[BookField.publisher] as String?;
  String? get publishedDate => _values[BookField.publishedDate] as String?;
  String? get isbn => _values[BookField.isbn] as String?;
  bool? get abridged => _values[BookField.abridged] as bool?;
  String? get status => _values[BookField.status] as String?;
  String? get contentRating => _values[BookField.contentRating] as String?;
  int? get totalDurationMs => _values[BookField.totalDurationMs] as int?;
  String? get webUrl => _values[BookField.webUrl] as String?;

  /// The value of [field], for code that treats fields uniformly.
  Object? operator [](BookField field) => _values[field];

  /// These details, with the values of [fields] taken from [other] instead.
  BookDetailsSnapshot withFieldsFrom(
    BookDetailsSnapshot other,
    Iterable<BookField> fields,
  ) => BookDetailsSnapshot._(
    Map.unmodifiable(<BookField, Object?>{
      ..._values,
      for (final field in fields) field: other._values[field],
    }),
  );

  @override
  bool operator ==(Object other) =>
      other is BookDetailsSnapshot &&
      BookField.values.every(
        (field) => _sameValue(_values[field], other._values[field]),
      );

  @override
  int get hashCode => Object.hashAll([
    for (final field in BookField.values)
      switch (_values[field]) {
        final List<Object?> list => Object.hashAll(list),
        final value => value,
      },
  ]);
}

bool _sameValue(Object? a, Object? b) {
  if (a is List && b is List) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
  return a == b;
}

/// An author or narrator credit.
final class ContributorSnapshot {
  const ContributorSnapshot({
    required this.name,
    required this.role,
    required this.ordinal,
  });

  final String name;
  final ContributorRole role;

  /// Credit order within the role.
  final int ordinal;
}

/// A book, with everything that hangs off it.
final class BookSnapshot {
  const BookSnapshot({
    required this.sourceId,
    required this.key,
    required this.details,
    required this.createdAt,
    required this.updatedAt,
    this.userOverrides = const {},
    this.contributors = const [],
    this.inLibrary = false,
    this.dateAdded,
    this.lastRefreshedAt,
    this.detailsFetched = false,
    this.playbackSpeed,
    this.kind = SourceKind.audio,
    this.mediaFiles = const [],
    this.chapters = const [],
    this.progress,
    this.reading,
    this.sessions = const [],
    this.bookmarks = const [],
    this.categories = const [],
  });

  /// With [key], the book's identity (§4.4).
  final int sourceId;
  final String key;

  final BookDetailsSnapshot details;

  /// The fields of [details] the user has edited.
  final Set<BookField> userOverrides;

  final List<ContributorSnapshot> contributors;
  final bool inLibrary;
  final DateTime? dateAdded;
  final DateTime? lastRefreshedAt;
  final bool detailsFetched;

  /// §4.3: playback speed is remembered per book. Null when it was never changed.
  final double? playbackSpeed;

  /// A book to listen to or a book to read (ADR-0019).
  final SourceKind kind;

  final DateTime createdAt;
  final DateTime updatedAt;
  final List<MediaFileSnapshot> mediaFiles;
  final List<ChapterSnapshot> chapters;

  /// Where the book is up to, or null if it was never started.
  final ProgressSnapshot? progress;

  /// Where the reader of a book to read is up to, or null if it was never opened.
  final ReadingSnapshot? reading;

  final List<SessionSnapshot> sessions;
  final List<BookmarkSnapshot> bookmarks;

  /// The names of the categories the book belongs to.
  final List<String> categories;

  /// Whether the book holds anything of the user's beyond its place in the library: progress,
  /// a reading position, listening history, bookmarks, a started or listened chapter, or membership
  /// of a category.
  bool get carriesUserData =>
      progress != null ||
      reading != null ||
      sessions.isNotEmpty ||
      bookmarks.isNotEmpty ||
      categories.isNotEmpty ||
      chapters.any((chapter) => chapter.hasProgress);
}

/// One physical audio file of a book.
final class MediaFileSnapshot {
  const MediaFileSnapshot({
    required this.fileKey,
    this.format,
    this.durationMs,
    this.durationIsEstimate = true,
    this.sizeBytes,
    this.embeddedMarkers,
    this.localPath,
    this.downloadedAt,
  });

  /// The file's identity within its book.
  final String fileKey;

  final String? format;
  final int? durationMs;

  /// True while [durationMs] is an estimate rather than measured from the file (§4.5).
  final bool durationIsEstimate;

  final int? sizeBytes;

  /// Chapter markers probed from the file. Null when it was never probed for them, which is not the
  /// same as probed and found to have none.
  final List<TimelineMarker>? embeddedMarkers;

  /// Where the file is on the device the snapshot was taken on. The backup format's schema,
  /// `packages/backup/proto/backup.proto`, explains why a backup carries it.
  final String? localPath;

  final DateTime? downloadedAt;
}

/// A logical chapter of a book.
final class ChapterSnapshot {
  const ChapterSnapshot({
    required this.key,
    required this.title,
    required this.sourceIndex,
    required this.createdAt,
    required this.updatedAt,
    this.groupName,
    this.durationMs,
    this.publishedAt,
    this.isListened = false,
    this.listenedAt,
    this.lastPositionMs = 0,
    this.removedFromSource = false,
    this.segments = const [],
  });

  /// The chapter's identity within its book.
  final String key;

  final String title;
  final int sourceIndex;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? groupName;
  final int? durationMs;
  final DateTime? publishedAt;
  final bool isListened;
  final DateTime? listenedAt;

  /// Chapter-relative, per §4.5.
  final int lastPositionMs;

  /// §4.4's soft delete.
  final bool removedFromSource;

  /// The chapter's layout across files, in playing order. Empty when it has no known layout.
  final List<SegmentSnapshot> segments;

  /// Whether the user has listened to any of the chapter.
  bool get hasProgress => isListened || lastPositionMs > 0;
}

/// A stretch of one file that forms part of a chapter.
final class SegmentSnapshot {
  const SegmentSnapshot({required this.fileKey, this.startMs = 0, this.endMs});

  /// The [MediaFileSnapshot.fileKey] of a file of the same book.
  final String fileKey;

  final int startMs;

  /// Null means to the end of the file.
  final int? endMs;
}

/// Where a book is up to: §4.3's `playback_state`.
final class ProgressSnapshot {
  const ProgressSnapshot({
    required this.chapterKey,
    required this.chapterPositionMs,
    required this.globalPositionMs,
    required this.updatedAt,
    required this.deviceId,
  });

  /// The [ChapterSnapshot.key] of a chapter of the same book.
  final String chapterKey;

  /// The truth, per §4.5.
  final int chapterPositionMs;

  /// Derived from the Timeline and cached for sorting.
  final int globalPositionMs;

  final DateTime updatedAt;
  final String deviceId;
}

/// Where the reader of a book is up to: §4.3's `reading_state` (ADR-0019).
final class ReadingSnapshot {
  const ReadingSnapshot({
    required this.chapterKey,
    required this.progress,
    required this.updatedAt,
  });

  /// The [ChapterSnapshot.key] of a chapter of the same book.
  final String chapterKey;

  /// How far through the chapter, from 0 to 1.
  final double progress;

  final DateTime updatedAt;
}

/// One stretch of listening, for history and statistics.
final class SessionSnapshot {
  const SessionSnapshot({
    required this.startedAt,
    required this.endedAt,
    required this.startGlobalMs,
    required this.endGlobalMs,
    required this.speed,
    required this.deviceId,
    this.chapterKey,
  });

  final DateTime startedAt;
  final DateTime endedAt;
  final int startGlobalMs;
  final int endGlobalMs;
  final double speed;
  final String deviceId;

  /// The chapter listened in, or null when it is no longer known: history outlives the chapters it
  /// covered.
  final String? chapterKey;
}

/// A bookmark.
final class BookmarkSnapshot {
  const BookmarkSnapshot({
    required this.chapterKey,
    required this.positionMs,
    required this.createdAt,
    this.title,
    this.note,
  });

  /// The [ChapterSnapshot.key] of a chapter of the same book.
  final String chapterKey;

  /// Chapter-relative.
  final int positionMs;

  final DateTime createdAt;
  final String? title;
  final String? note;
}
