// This is a generated file - do not edit.
//
// Generated from backup.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'backup.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'backup.pbenum.dart';

/// One backup: the whole content of one backup file, before gzip.
class Backup extends $pb.GeneratedMessage {
  factory Backup({
    $core.int? formatVersion,
    $core.int? minReaderVersion,
    $fixnum.Int64? createdAtMs,
    $core.String? appVersion,
    $core.String? deviceId,
    $core.Iterable<Source>? sources,
    $core.Iterable<Category>? categories,
    $core.Iterable<Book>? books,
  }) {
    final result = Backup._();
    if (formatVersion != null) result.formatVersion = formatVersion;
    if (minReaderVersion != null) result.minReaderVersion = minReaderVersion;
    if (createdAtMs != null) result.createdAtMs = createdAtMs;
    if (appVersion != null) result.appVersion = appVersion;
    if (deviceId != null) result.deviceId = deviceId;
    if (sources != null) result.sources.addAll(sources);
    if (categories != null) result.categories.addAll(categories);
    if (books != null) result.books.addAll(books);
    return result;
  }

  Backup._();

  factory Backup.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Backup()..mergeFromBuffer(data, registry);
  factory Backup.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Backup()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Backup',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'kikuyomi.backup'),
      createEmptyInstance: Backup.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'formatVersion',
        fieldType: $pb.PbFieldType.OU3)
    ..aI(2, _omitFieldNames ? '' : 'minReaderVersion',
        fieldType: $pb.PbFieldType.OU3)
    ..aInt64(3, _omitFieldNames ? '' : 'createdAtMs')
    ..aOS(4, _omitFieldNames ? '' : 'appVersion')
    ..aOS(5, _omitFieldNames ? '' : 'deviceId')
    ..pPM<Source>(6, _omitFieldNames ? '' : 'sources',
        subBuilder: Source.$_createMessage)
    ..pPM<Category>(7, _omitFieldNames ? '' : 'categories',
        subBuilder: Category.$_createMessage)
    ..pPM<Book>(8, _omitFieldNames ? '' : 'books',
        subBuilder: Book.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Backup clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Backup copyWith(void Function(Backup) updates) =>
      super.copyWith((message) => updates(message as Backup)) as Backup;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Backup() / Backup.new instead')
  static Backup create() => Backup._();
  static $pb.GeneratedMessage $_createMessage() => Backup._();
  @$core.override
  Backup createEmptyInstance() => Backup._();
  @$core.pragma('dart2js:noInline')
  static Backup getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Backup>(Backup.$_createMessage);
  static Backup? _defaultInstance;

  /// The version of this schema the writer implemented. Informational: it says which fields a reader
  /// may expect, and helps diagnose a bad restore. It rises with every change to this file that
  /// matters to a reader, including purely additive ones.
  ///
  /// 1: the first version.
  /// 2: `Chapter.is_listened` and `listened_at_ms` are recorded, by playback and by hand. Builds
  ///    writing version 1 worked listened state out from positions and wrote no chapter as listened,
  ///    so a reader restores listened state from a version 1 backup's positions instead of taking it
  ///    as written. The fields and their meaning are unchanged, and a version 1 reader restores a
  ///    version 2 backup correctly, so `min_reader_version` stays at 1.
  /// 3: books to read as well as to listen to (ADR-0019): `Book.kind` and `Book.reading_state`. A
  ///    version 2 reader would restore a book to read as an audiobook, without a word, so a backup
  ///    holding one has `min_reader_version` 3. A backup of audiobooks alone restores correctly on a
  ///    version 2 reader and keeps `min_reader_version` at 1 (ADR-0020).
  @$pb.TagNumber(1)
  $core.int get formatVersion => $_getIZ(0);
  @$pb.TagNumber(1)
  set formatVersion($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasFormatVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearFormatVersion() => $_clearField(1);

  /// The oldest format version a reader can implement and still restore this backup correctly.
  /// Additive changes leave it alone, which is what lets an older build read a newer backup, as
  /// ADR-0008 requires. It rises only for a change an older reader would silently get wrong by
  /// skipping what it does not know, and a reader older than it refuses the backup rather than
  /// restoring it partially.
  @$pb.TagNumber(2)
  $core.int get minReaderVersion => $_getIZ(1);
  @$pb.TagNumber(2)
  set minReaderVersion($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMinReaderVersion() => $_has(1);
  @$pb.TagNumber(2)
  void clearMinReaderVersion() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get createdAtMs => $_getI64(2);
  @$pb.TagNumber(3)
  set createdAtMs($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasCreatedAtMs() => $_has(2);
  @$pb.TagNumber(3)
  void clearCreatedAtMs() => $_clearField(3);

  /// The app version that wrote the backup, as the app reports it. For diagnostics only.
  @$pb.TagNumber(4)
  $core.String get appVersion => $_getSZ(3);
  @$pb.TagNumber(4)
  set appVersion($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasAppVersion() => $_has(3);
  @$pb.TagNumber(4)
  void clearAppVersion() => $_clearField(4);

  /// The device that wrote the backup, in the same form as `PlaybackState.device_id`.
  @$pb.TagNumber(5)
  $core.String get deviceId => $_getSZ(4);
  @$pb.TagNumber(5)
  set deviceId($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasDeviceId() => $_has(4);
  @$pb.TagNumber(5)
  void clearDeviceId() => $_clearField(5);

  @$pb.TagNumber(6)
  $pb.PbList<Source> get sources => $_getList(5);

  @$pb.TagNumber(7)
  $pb.PbList<Category> get categories => $_getList(6);

  @$pb.TagNumber(8)
  $pb.PbList<Book> get books => $_getList(7);
}

/// A content source, as §4.3's `source` table describes it.
class Source extends $pb.GeneratedMessage {
  factory Source({
    $fixnum.Int64? id,
    $core.String? extensionId,
    $core.String? key,
    $core.String? name,
    $core.String? lang,
    $core.String? contentRating,
    $core.bool? isEnabled,
    $core.bool? isPinned,
    $fixnum.Int64? lastUsedAtMs,
  }) {
    final result = Source._();
    if (id != null) result.id = id;
    if (extensionId != null) result.extensionId = extensionId;
    if (key != null) result.key = key;
    if (name != null) result.name = name;
    if (lang != null) result.lang = lang;
    if (contentRating != null) result.contentRating = contentRating;
    if (isEnabled != null) result.isEnabled = isEnabled;
    if (isPinned != null) result.isPinned = isPinned;
    if (lastUsedAtMs != null) result.lastUsedAtMs = lastUsedAtMs;
    return result;
  }

  Source._();

  factory Source.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Source()..mergeFromBuffer(data, registry);
  factory Source.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Source()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Source',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'kikuyomi.backup'),
      createEmptyInstance: Source.$_createMessage)
    ..a<$fixnum.Int64>(1, _omitFieldNames ? '' : 'id', $pb.PbFieldType.OSF6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOS(2, _omitFieldNames ? '' : 'extensionId')
    ..aOS(3, _omitFieldNames ? '' : 'key')
    ..aOS(4, _omitFieldNames ? '' : 'name')
    ..aOS(5, _omitFieldNames ? '' : 'lang')
    ..aOS(6, _omitFieldNames ? '' : 'contentRating')
    ..aOB(7, _omitFieldNames ? '' : 'isEnabled')
    ..aOB(8, _omitFieldNames ? '' : 'isPinned')
    ..aInt64(9, _omitFieldNames ? '' : 'lastUsedAtMs')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Source clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Source copyWith(void Function(Source) updates) =>
      super.copyWith((message) => updates(message as Source)) as Source;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Source() / Source.new instead')
  static Source create() => Source._();
  static $pb.GeneratedMessage $_createMessage() => Source._();
  @$core.override
  Source createEmptyInstance() => Source._();
  @$core.pragma('dart2js:noInline')
  static Source getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Source>(Source.$_createMessage);
  static Source? _defaultInstance;

  /// The stable 64-bit id from §3.7: a hash, so its bits are uniformly spread and a fixed-width
  /// encoding is smaller than a varint.
  @$pb.TagNumber(1)
  $fixnum.Int64 get id => $_getI64(0);
  @$pb.TagNumber(1)
  set id($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  /// Absent for a built-in source.
  @$pb.TagNumber(2)
  $core.String get extensionId => $_getSZ(1);
  @$pb.TagNumber(2)
  set extensionId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasExtensionId() => $_has(1);
  @$pb.TagNumber(2)
  void clearExtensionId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get key => $_getSZ(2);
  @$pb.TagNumber(3)
  set key($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasKey() => $_has(2);
  @$pb.TagNumber(3)
  void clearKey() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get name => $_getSZ(3);
  @$pb.TagNumber(4)
  set name($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasName() => $_has(3);
  @$pb.TagNumber(4)
  void clearName() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get lang => $_getSZ(4);
  @$pb.TagNumber(5)
  set lang($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasLang() => $_has(4);
  @$pb.TagNumber(5)
  void clearLang() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get contentRating => $_getSZ(5);
  @$pb.TagNumber(6)
  set contentRating($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasContentRating() => $_has(5);
  @$pb.TagNumber(6)
  void clearContentRating() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.bool get isEnabled => $_getBF(6);
  @$pb.TagNumber(7)
  set isEnabled($core.bool value) => $_setBool(6, value);
  @$pb.TagNumber(7)
  $core.bool hasIsEnabled() => $_has(6);
  @$pb.TagNumber(7)
  void clearIsEnabled() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.bool get isPinned => $_getBF(7);
  @$pb.TagNumber(8)
  set isPinned($core.bool value) => $_setBool(7, value);
  @$pb.TagNumber(8)
  $core.bool hasIsPinned() => $_has(7);
  @$pb.TagNumber(8)
  void clearIsPinned() => $_clearField(8);

  @$pb.TagNumber(9)
  $fixnum.Int64 get lastUsedAtMs => $_getI64(8);
  @$pb.TagNumber(9)
  set lastUsedAtMs($fixnum.Int64 value) => $_setInt64(8, value);
  @$pb.TagNumber(9)
  $core.bool hasLastUsedAtMs() => $_has(8);
  @$pb.TagNumber(9)
  void clearLastUsedAtMs() => $_clearField(9);
}

/// A manual library category (ADR-0009). Identified by its name.
class Category extends $pb.GeneratedMessage {
  factory Category({
    $core.String? name,
    $core.int? sortOrder,
    $fixnum.Int64? flags,
  }) {
    final result = Category._();
    if (name != null) result.name = name;
    if (sortOrder != null) result.sortOrder = sortOrder;
    if (flags != null) result.flags = flags;
    return result;
  }

  Category._();

  factory Category.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Category()..mergeFromBuffer(data, registry);
  factory Category.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Category()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Category',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'kikuyomi.backup'),
      createEmptyInstance: Category.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aI(2, _omitFieldNames ? '' : 'sortOrder')
    ..aInt64(3, _omitFieldNames ? '' : 'flags')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Category clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Category copyWith(void Function(Category) updates) =>
      super.copyWith((message) => updates(message as Category)) as Category;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Category() / Category.new instead')
  static Category create() => Category._();
  static $pb.GeneratedMessage $_createMessage() => Category._();
  @$core.override
  Category createEmptyInstance() => Category._();
  @$core.pragma('dart2js:noInline')
  static Category getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Category>(Category.$_createMessage);
  static Category? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get sortOrder => $_getIZ(1);
  @$pb.TagNumber(2)
  set sortOrder($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSortOrder() => $_has(1);
  @$pb.TagNumber(2)
  void clearSortOrder() => $_clearField(2);

  /// Per-category sort, filter and display settings, packed as §4.3 describes.
  @$pb.TagNumber(3)
  $fixnum.Int64 get flags => $_getI64(2);
  @$pb.TagNumber(3)
  set flags($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasFlags() => $_has(2);
  @$pb.TagNumber(3)
  void clearFlags() => $_clearField(3);
}

/// A book, with everything that hangs off it.
class Book extends $pb.GeneratedMessage {
  factory Book({
    $fixnum.Int64? sourceId,
    $core.String? key,
    $core.String? title,
    $core.String? subtitle,
    $core.String? description,
    $core.String? coverUrl,
    $core.String? seriesName,
    $core.double? seriesIndex,
    $core.Iterable<$core.String>? genres,
    $core.String? language,
    $core.String? publisher,
    $core.String? publishedDate,
    $core.String? isbn,
    $core.bool? abridged,
    $core.String? status,
    $core.String? contentRating,
    $fixnum.Int64? totalDurationMs,
    $core.String? webUrl,
    $core.Iterable<$core.String>? userOverrides,
    $core.Iterable<Contributor>? contributors,
    $core.bool? inLibrary,
    $fixnum.Int64? dateAddedAtMs,
    $fixnum.Int64? lastRefreshedAtMs,
    $core.bool? detailsFetched,
    $core.double? playbackSpeed,
    $fixnum.Int64? createdAtMs,
    $fixnum.Int64? updatedAtMs,
    $core.Iterable<MediaFile>? mediaFiles,
    $core.Iterable<Chapter>? chapters,
    PlaybackState? playbackState,
    $core.Iterable<ListeningSession>? listeningSessions,
    $core.Iterable<Bookmark>? bookmarks,
    $core.Iterable<$core.String>? categories,
    BookKind? kind,
    ReadingState? readingState,
  }) {
    final result = Book._();
    if (sourceId != null) result.sourceId = sourceId;
    if (key != null) result.key = key;
    if (title != null) result.title = title;
    if (subtitle != null) result.subtitle = subtitle;
    if (description != null) result.description = description;
    if (coverUrl != null) result.coverUrl = coverUrl;
    if (seriesName != null) result.seriesName = seriesName;
    if (seriesIndex != null) result.seriesIndex = seriesIndex;
    if (genres != null) result.genres.addAll(genres);
    if (language != null) result.language = language;
    if (publisher != null) result.publisher = publisher;
    if (publishedDate != null) result.publishedDate = publishedDate;
    if (isbn != null) result.isbn = isbn;
    if (abridged != null) result.abridged = abridged;
    if (status != null) result.status = status;
    if (contentRating != null) result.contentRating = contentRating;
    if (totalDurationMs != null) result.totalDurationMs = totalDurationMs;
    if (webUrl != null) result.webUrl = webUrl;
    if (userOverrides != null) result.userOverrides.addAll(userOverrides);
    if (contributors != null) result.contributors.addAll(contributors);
    if (inLibrary != null) result.inLibrary = inLibrary;
    if (dateAddedAtMs != null) result.dateAddedAtMs = dateAddedAtMs;
    if (lastRefreshedAtMs != null) result.lastRefreshedAtMs = lastRefreshedAtMs;
    if (detailsFetched != null) result.detailsFetched = detailsFetched;
    if (playbackSpeed != null) result.playbackSpeed = playbackSpeed;
    if (createdAtMs != null) result.createdAtMs = createdAtMs;
    if (updatedAtMs != null) result.updatedAtMs = updatedAtMs;
    if (mediaFiles != null) result.mediaFiles.addAll(mediaFiles);
    if (chapters != null) result.chapters.addAll(chapters);
    if (playbackState != null) result.playbackState = playbackState;
    if (listeningSessions != null)
      result.listeningSessions.addAll(listeningSessions);
    if (bookmarks != null) result.bookmarks.addAll(bookmarks);
    if (categories != null) result.categories.addAll(categories);
    if (kind != null) result.kind = kind;
    if (readingState != null) result.readingState = readingState;
    return result;
  }

  Book._();

  factory Book.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Book()..mergeFromBuffer(data, registry);
  factory Book.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Book()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Book',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'kikuyomi.backup'),
      createEmptyInstance: Book.$_createMessage)
    ..a<$fixnum.Int64>(
        1, _omitFieldNames ? '' : 'sourceId', $pb.PbFieldType.OSF6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOS(2, _omitFieldNames ? '' : 'key')
    ..aOS(3, _omitFieldNames ? '' : 'title')
    ..aOS(4, _omitFieldNames ? '' : 'subtitle')
    ..aOS(5, _omitFieldNames ? '' : 'description')
    ..aOS(6, _omitFieldNames ? '' : 'coverUrl')
    ..aOS(7, _omitFieldNames ? '' : 'seriesName')
    ..aD(8, _omitFieldNames ? '' : 'seriesIndex')
    ..pPS(9, _omitFieldNames ? '' : 'genres')
    ..aOS(10, _omitFieldNames ? '' : 'language')
    ..aOS(11, _omitFieldNames ? '' : 'publisher')
    ..aOS(12, _omitFieldNames ? '' : 'publishedDate')
    ..aOS(13, _omitFieldNames ? '' : 'isbn')
    ..aOB(14, _omitFieldNames ? '' : 'abridged')
    ..aOS(15, _omitFieldNames ? '' : 'status')
    ..aOS(16, _omitFieldNames ? '' : 'contentRating')
    ..aInt64(17, _omitFieldNames ? '' : 'totalDurationMs')
    ..aOS(18, _omitFieldNames ? '' : 'webUrl')
    ..pPS(19, _omitFieldNames ? '' : 'userOverrides')
    ..pPM<Contributor>(20, _omitFieldNames ? '' : 'contributors',
        subBuilder: Contributor.$_createMessage)
    ..aOB(21, _omitFieldNames ? '' : 'inLibrary')
    ..aInt64(22, _omitFieldNames ? '' : 'dateAddedAtMs')
    ..aInt64(23, _omitFieldNames ? '' : 'lastRefreshedAtMs')
    ..aOB(24, _omitFieldNames ? '' : 'detailsFetched')
    ..aD(25, _omitFieldNames ? '' : 'playbackSpeed')
    ..aInt64(26, _omitFieldNames ? '' : 'createdAtMs')
    ..aInt64(27, _omitFieldNames ? '' : 'updatedAtMs')
    ..pPM<MediaFile>(28, _omitFieldNames ? '' : 'mediaFiles',
        subBuilder: MediaFile.$_createMessage)
    ..pPM<Chapter>(29, _omitFieldNames ? '' : 'chapters',
        subBuilder: Chapter.$_createMessage)
    ..aOM<PlaybackState>(30, _omitFieldNames ? '' : 'playbackState',
        subBuilder: PlaybackState.$_createMessage)
    ..pPM<ListeningSession>(31, _omitFieldNames ? '' : 'listeningSessions',
        subBuilder: ListeningSession.$_createMessage)
    ..pPM<Bookmark>(32, _omitFieldNames ? '' : 'bookmarks',
        subBuilder: Bookmark.$_createMessage)
    ..pPS(33, _omitFieldNames ? '' : 'categories')
    ..aE<BookKind>(34, _omitFieldNames ? '' : 'kind',
        enumValues: BookKind.values)
    ..aOM<ReadingState>(35, _omitFieldNames ? '' : 'readingState',
        subBuilder: ReadingState.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Book clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Book copyWith(void Function(Book) updates) =>
      super.copyWith((message) => updates(message as Book)) as Book;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Book() / Book.new instead')
  static Book create() => Book._();
  static $pb.GeneratedMessage $_createMessage() => Book._();
  @$core.override
  Book createEmptyInstance() => Book._();
  @$core.pragma('dart2js:noInline')
  static Book getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Book>(Book.$_createMessage);
  static Book? _defaultInstance;

  /// With `key`, the book's identity (§4.4).
  @$pb.TagNumber(1)
  $fixnum.Int64 get sourceId => $_getI64(0);
  @$pb.TagNumber(1)
  set sourceId($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSourceId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSourceId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get key => $_getSZ(1);
  @$pb.TagNumber(2)
  set key($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasKey() => $_has(1);
  @$pb.TagNumber(2)
  void clearKey() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get title => $_getSZ(2);
  @$pb.TagNumber(3)
  set title($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasTitle() => $_has(2);
  @$pb.TagNumber(3)
  void clearTitle() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get subtitle => $_getSZ(3);
  @$pb.TagNumber(4)
  set subtitle($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasSubtitle() => $_has(3);
  @$pb.TagNumber(4)
  void clearSubtitle() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get description => $_getSZ(4);
  @$pb.TagNumber(5)
  set description($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasDescription() => $_has(4);
  @$pb.TagNumber(5)
  void clearDescription() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get coverUrl => $_getSZ(5);
  @$pb.TagNumber(6)
  set coverUrl($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasCoverUrl() => $_has(5);
  @$pb.TagNumber(6)
  void clearCoverUrl() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get seriesName => $_getSZ(6);
  @$pb.TagNumber(7)
  set seriesName($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasSeriesName() => $_has(6);
  @$pb.TagNumber(7)
  void clearSeriesName() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.double get seriesIndex => $_getN(7);
  @$pb.TagNumber(8)
  set seriesIndex($core.double value) => $_setDouble(7, value);
  @$pb.TagNumber(8)
  $core.bool hasSeriesIndex() => $_has(7);
  @$pb.TagNumber(8)
  void clearSeriesIndex() => $_clearField(8);

  @$pb.TagNumber(9)
  $pb.PbList<$core.String> get genres => $_getList(8);

  @$pb.TagNumber(10)
  $core.String get language => $_getSZ(9);
  @$pb.TagNumber(10)
  set language($core.String value) => $_setString(9, value);
  @$pb.TagNumber(10)
  $core.bool hasLanguage() => $_has(9);
  @$pb.TagNumber(10)
  void clearLanguage() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.String get publisher => $_getSZ(10);
  @$pb.TagNumber(11)
  set publisher($core.String value) => $_setString(10, value);
  @$pb.TagNumber(11)
  $core.bool hasPublisher() => $_has(10);
  @$pb.TagNumber(11)
  void clearPublisher() => $_clearField(11);

  @$pb.TagNumber(12)
  $core.String get publishedDate => $_getSZ(11);
  @$pb.TagNumber(12)
  set publishedDate($core.String value) => $_setString(11, value);
  @$pb.TagNumber(12)
  $core.bool hasPublishedDate() => $_has(11);
  @$pb.TagNumber(12)
  void clearPublishedDate() => $_clearField(12);

  @$pb.TagNumber(13)
  $core.String get isbn => $_getSZ(12);
  @$pb.TagNumber(13)
  set isbn($core.String value) => $_setString(12, value);
  @$pb.TagNumber(13)
  $core.bool hasIsbn() => $_has(12);
  @$pb.TagNumber(13)
  void clearIsbn() => $_clearField(13);

  @$pb.TagNumber(14)
  $core.bool get abridged => $_getBF(13);
  @$pb.TagNumber(14)
  set abridged($core.bool value) => $_setBool(13, value);
  @$pb.TagNumber(14)
  $core.bool hasAbridged() => $_has(13);
  @$pb.TagNumber(14)
  void clearAbridged() => $_clearField(14);

  @$pb.TagNumber(15)
  $core.String get status => $_getSZ(14);
  @$pb.TagNumber(15)
  set status($core.String value) => $_setString(14, value);
  @$pb.TagNumber(15)
  $core.bool hasStatus() => $_has(14);
  @$pb.TagNumber(15)
  void clearStatus() => $_clearField(15);

  @$pb.TagNumber(16)
  $core.String get contentRating => $_getSZ(15);
  @$pb.TagNumber(16)
  set contentRating($core.String value) => $_setString(15, value);
  @$pb.TagNumber(16)
  $core.bool hasContentRating() => $_has(15);
  @$pb.TagNumber(16)
  void clearContentRating() => $_clearField(16);

  @$pb.TagNumber(17)
  $fixnum.Int64 get totalDurationMs => $_getI64(16);
  @$pb.TagNumber(17)
  set totalDurationMs($fixnum.Int64 value) => $_setInt64(16, value);
  @$pb.TagNumber(17)
  $core.bool hasTotalDurationMs() => $_has(16);
  @$pb.TagNumber(17)
  void clearTotalDurationMs() => $_clearField(17);

  @$pb.TagNumber(18)
  $core.String get webUrl => $_getSZ(17);
  @$pb.TagNumber(18)
  set webUrl($core.String value) => $_setString(17, value);
  @$pb.TagNumber(18)
  $core.bool hasWebUrl() => $_has(17);
  @$pb.TagNumber(18)
  void clearWebUrl() => $_clearField(18);

  /// The detail fields the user has edited, by name: `title`, `subtitle`, `description`, `cover_url`
  /// as `coverUrl`, and so on, spelled as the app's own field names. Names rather than an enum,
  /// because a name a reader does not know is simply skipped, where a new enum number would arrive
  /// as an unexplained default.
  @$pb.TagNumber(19)
  $pb.PbList<$core.String> get userOverrides => $_getList(18);

  @$pb.TagNumber(20)
  $pb.PbList<Contributor> get contributors => $_getList(19);

  @$pb.TagNumber(21)
  $core.bool get inLibrary => $_getBF(20);
  @$pb.TagNumber(21)
  set inLibrary($core.bool value) => $_setBool(20, value);
  @$pb.TagNumber(21)
  $core.bool hasInLibrary() => $_has(20);
  @$pb.TagNumber(21)
  void clearInLibrary() => $_clearField(21);

  @$pb.TagNumber(22)
  $fixnum.Int64 get dateAddedAtMs => $_getI64(21);
  @$pb.TagNumber(22)
  set dateAddedAtMs($fixnum.Int64 value) => $_setInt64(21, value);
  @$pb.TagNumber(22)
  $core.bool hasDateAddedAtMs() => $_has(21);
  @$pb.TagNumber(22)
  void clearDateAddedAtMs() => $_clearField(22);

  @$pb.TagNumber(23)
  $fixnum.Int64 get lastRefreshedAtMs => $_getI64(22);
  @$pb.TagNumber(23)
  set lastRefreshedAtMs($fixnum.Int64 value) => $_setInt64(22, value);
  @$pb.TagNumber(23)
  $core.bool hasLastRefreshedAtMs() => $_has(22);
  @$pb.TagNumber(23)
  void clearLastRefreshedAtMs() => $_clearField(23);

  @$pb.TagNumber(24)
  $core.bool get detailsFetched => $_getBF(23);
  @$pb.TagNumber(24)
  set detailsFetched($core.bool value) => $_setBool(23, value);
  @$pb.TagNumber(24)
  $core.bool hasDetailsFetched() => $_has(23);
  @$pb.TagNumber(24)
  void clearDetailsFetched() => $_clearField(24);

  /// §4.3: playback speed is remembered per book. Absent when it was never changed.
  @$pb.TagNumber(25)
  $core.double get playbackSpeed => $_getN(24);
  @$pb.TagNumber(25)
  set playbackSpeed($core.double value) => $_setDouble(24, value);
  @$pb.TagNumber(25)
  $core.bool hasPlaybackSpeed() => $_has(24);
  @$pb.TagNumber(25)
  void clearPlaybackSpeed() => $_clearField(25);

  @$pb.TagNumber(26)
  $fixnum.Int64 get createdAtMs => $_getI64(25);
  @$pb.TagNumber(26)
  set createdAtMs($fixnum.Int64 value) => $_setInt64(25, value);
  @$pb.TagNumber(26)
  $core.bool hasCreatedAtMs() => $_has(25);
  @$pb.TagNumber(26)
  void clearCreatedAtMs() => $_clearField(26);

  @$pb.TagNumber(27)
  $fixnum.Int64 get updatedAtMs => $_getI64(26);
  @$pb.TagNumber(27)
  set updatedAtMs($fixnum.Int64 value) => $_setInt64(26, value);
  @$pb.TagNumber(27)
  $core.bool hasUpdatedAtMs() => $_has(26);
  @$pb.TagNumber(27)
  void clearUpdatedAtMs() => $_clearField(27);

  @$pb.TagNumber(28)
  $pb.PbList<MediaFile> get mediaFiles => $_getList(27);

  @$pb.TagNumber(29)
  $pb.PbList<Chapter> get chapters => $_getList(28);

  /// Absent for a book that was never started.
  @$pb.TagNumber(30)
  PlaybackState get playbackState => $_getN(29);
  @$pb.TagNumber(30)
  set playbackState(PlaybackState value) => $_setField(30, value);
  @$pb.TagNumber(30)
  $core.bool hasPlaybackState() => $_has(29);
  @$pb.TagNumber(30)
  void clearPlaybackState() => $_clearField(30);
  @$pb.TagNumber(30)
  PlaybackState ensurePlaybackState() => $_ensure(29);

  @$pb.TagNumber(31)
  $pb.PbList<ListeningSession> get listeningSessions => $_getList(30);

  @$pb.TagNumber(32)
  $pb.PbList<Bookmark> get bookmarks => $_getList(31);

  /// The names of the categories the book belongs to.
  @$pb.TagNumber(33)
  $pb.PbList<$core.String> get categories => $_getList(32);

  /// A book to listen to or a book to read (format version 3). The default is audio, which is what
  /// every book in an older backup was.
  @$pb.TagNumber(34)
  BookKind get kind => $_getN(33);
  @$pb.TagNumber(34)
  set kind(BookKind value) => $_setField(34, value);
  @$pb.TagNumber(34)
  $core.bool hasKind() => $_has(33);
  @$pb.TagNumber(34)
  void clearKind() => $_clearField(34);

  /// Where the reader of a book to read is up to. Absent for a book never opened, and for every
  /// audiobook, whose place is `playback_state`.
  @$pb.TagNumber(35)
  ReadingState get readingState => $_getN(34);
  @$pb.TagNumber(35)
  set readingState(ReadingState value) => $_setField(35, value);
  @$pb.TagNumber(35)
  $core.bool hasReadingState() => $_has(34);
  @$pb.TagNumber(35)
  void clearReadingState() => $_clearField(35);
  @$pb.TagNumber(35)
  ReadingState ensureReadingState() => $_ensure(34);
}

/// An author or narrator credit. §4.3 normalises people in the database; here a credit carries the
/// name, and a restore finds or creates the person by it.
class Contributor extends $pb.GeneratedMessage {
  factory Contributor({
    $core.String? name,
    ContributorRole? role,
    $core.int? ordinal,
  }) {
    final result = Contributor._();
    if (name != null) result.name = name;
    if (role != null) result.role = role;
    if (ordinal != null) result.ordinal = ordinal;
    return result;
  }

  Contributor._();

  factory Contributor.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Contributor()..mergeFromBuffer(data, registry);
  factory Contributor.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Contributor()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Contributor',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'kikuyomi.backup'),
      createEmptyInstance: Contributor.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aE<ContributorRole>(2, _omitFieldNames ? '' : 'role',
        enumValues: ContributorRole.values)
    ..aI(3, _omitFieldNames ? '' : 'ordinal')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Contributor clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Contributor copyWith(void Function(Contributor) updates) =>
      super.copyWith((message) => updates(message as Contributor))
          as Contributor;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Contributor() / Contributor.new instead')
  static Contributor create() => Contributor._();
  static $pb.GeneratedMessage $_createMessage() => Contributor._();
  @$core.override
  Contributor createEmptyInstance() => Contributor._();
  @$core.pragma('dart2js:noInline')
  static Contributor getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Contributor>(
          Contributor.$_createMessage);
  static Contributor? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  /// A reader that does not know a role skips the credit.
  @$pb.TagNumber(2)
  ContributorRole get role => $_getN(1);
  @$pb.TagNumber(2)
  set role(ContributorRole value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasRole() => $_has(1);
  @$pb.TagNumber(2)
  void clearRole() => $_clearField(2);

  /// Credit order within the role.
  @$pb.TagNumber(3)
  $core.int get ordinal => $_getIZ(2);
  @$pb.TagNumber(3)
  set ordinal($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasOrdinal() => $_has(2);
  @$pb.TagNumber(3)
  void clearOrdinal() => $_clearField(3);
}

/// One physical audio file of a book.
class MediaFile extends $pb.GeneratedMessage {
  factory MediaFile({
    $core.String? fileKey,
    $core.String? format,
    $fixnum.Int64? durationMs,
    $core.bool? durationIsEstimate,
    $fixnum.Int64? sizeBytes,
    MarkerList? embeddedMarkers,
    $core.String? localPath,
    $fixnum.Int64? downloadedAtMs,
  }) {
    final result = MediaFile._();
    if (fileKey != null) result.fileKey = fileKey;
    if (format != null) result.format = format;
    if (durationMs != null) result.durationMs = durationMs;
    if (durationIsEstimate != null)
      result.durationIsEstimate = durationIsEstimate;
    if (sizeBytes != null) result.sizeBytes = sizeBytes;
    if (embeddedMarkers != null) result.embeddedMarkers = embeddedMarkers;
    if (localPath != null) result.localPath = localPath;
    if (downloadedAtMs != null) result.downloadedAtMs = downloadedAtMs;
    return result;
  }

  MediaFile._();

  factory MediaFile.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MediaFile()..mergeFromBuffer(data, registry);
  factory MediaFile.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MediaFile()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MediaFile',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'kikuyomi.backup'),
      createEmptyInstance: MediaFile.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'fileKey')
    ..aOS(2, _omitFieldNames ? '' : 'format')
    ..aInt64(3, _omitFieldNames ? '' : 'durationMs')
    ..aOB(4, _omitFieldNames ? '' : 'durationIsEstimate')
    ..aInt64(5, _omitFieldNames ? '' : 'sizeBytes')
    ..aOM<MarkerList>(6, _omitFieldNames ? '' : 'embeddedMarkers',
        subBuilder: MarkerList.$_createMessage)
    ..aOS(7, _omitFieldNames ? '' : 'localPath')
    ..aInt64(8, _omitFieldNames ? '' : 'downloadedAtMs')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MediaFile clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MediaFile copyWith(void Function(MediaFile) updates) =>
      super.copyWith((message) => updates(message as MediaFile)) as MediaFile;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use MediaFile() / MediaFile.new instead')
  static MediaFile create() => MediaFile._();
  static $pb.GeneratedMessage $_createMessage() => MediaFile._();
  @$core.override
  MediaFile createEmptyInstance() => MediaFile._();
  @$core.pragma('dart2js:noInline')
  static MediaFile getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MediaFile>(MediaFile.$_createMessage);
  static MediaFile? _defaultInstance;

  /// The file's identity within its book.
  @$pb.TagNumber(1)
  $core.String get fileKey => $_getSZ(0);
  @$pb.TagNumber(1)
  set fileKey($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasFileKey() => $_has(0);
  @$pb.TagNumber(1)
  void clearFileKey() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get format => $_getSZ(1);
  @$pb.TagNumber(2)
  set format($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasFormat() => $_has(1);
  @$pb.TagNumber(2)
  void clearFormat() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get durationMs => $_getI64(2);
  @$pb.TagNumber(3)
  set durationMs($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDurationMs() => $_has(2);
  @$pb.TagNumber(3)
  void clearDurationMs() => $_clearField(3);

  /// True while `duration_ms` is an estimate rather than measured from the file (§4.5).
  @$pb.TagNumber(4)
  $core.bool get durationIsEstimate => $_getBF(3);
  @$pb.TagNumber(4)
  set durationIsEstimate($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasDurationIsEstimate() => $_has(3);
  @$pb.TagNumber(4)
  void clearDurationIsEstimate() => $_clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get sizeBytes => $_getI64(4);
  @$pb.TagNumber(5)
  set sizeBytes($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasSizeBytes() => $_has(4);
  @$pb.TagNumber(5)
  void clearSizeBytes() => $_clearField(5);

  /// Chapter markers probed from the file. Absent when the file was never probed for them, which is
  /// not the same as probed and found to have none.
  @$pb.TagNumber(6)
  MarkerList get embeddedMarkers => $_getN(5);
  @$pb.TagNumber(6)
  set embeddedMarkers(MarkerList value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasEmbeddedMarkers() => $_has(5);
  @$pb.TagNumber(6)
  void clearEmbeddedMarkers() => $_clearField(6);
  @$pb.TagNumber(6)
  MarkerList ensureEmbeddedMarkers() => $_ensure(5);

  /// Where the file is on the device that wrote the backup: absolute for a file the user keeps where
  /// it is, relative to the app's media root for a file in the app's own storage. It is carried
  /// although another device may have nothing there, because for a local book it is the only way
  /// back to the user's own file, and the same device is the common case: a reinstall, or an iOS
  /// re-sign, leaves a user's folders where they were. A path with nothing behind it is reported as
  /// a missing file when played, the same as a file deleted behind the app's back.
  @$pb.TagNumber(7)
  $core.String get localPath => $_getSZ(6);
  @$pb.TagNumber(7)
  set localPath($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasLocalPath() => $_has(6);
  @$pb.TagNumber(7)
  void clearLocalPath() => $_clearField(7);

  @$pb.TagNumber(8)
  $fixnum.Int64 get downloadedAtMs => $_getI64(7);
  @$pb.TagNumber(8)
  set downloadedAtMs($fixnum.Int64 value) => $_setInt64(7, value);
  @$pb.TagNumber(8)
  $core.bool hasDownloadedAtMs() => $_has(7);
  @$pb.TagNumber(8)
  void clearDownloadedAtMs() => $_clearField(8);
}

class MarkerList extends $pb.GeneratedMessage {
  factory MarkerList({
    $core.Iterable<Marker>? markers,
  }) {
    final result = MarkerList._();
    if (markers != null) result.markers.addAll(markers);
    return result;
  }

  MarkerList._();

  factory MarkerList.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MarkerList()..mergeFromBuffer(data, registry);
  factory MarkerList.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MarkerList()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MarkerList',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'kikuyomi.backup'),
      createEmptyInstance: MarkerList.$_createMessage)
    ..pPM<Marker>(1, _omitFieldNames ? '' : 'markers',
        subBuilder: Marker.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MarkerList clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MarkerList copyWith(void Function(MarkerList) updates) =>
      super.copyWith((message) => updates(message as MarkerList)) as MarkerList;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use MarkerList() / MarkerList.new instead')
  static MarkerList create() => MarkerList._();
  static $pb.GeneratedMessage $_createMessage() => MarkerList._();
  @$core.override
  MarkerList createEmptyInstance() => MarkerList._();
  @$core.pragma('dart2js:noInline')
  static MarkerList getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MarkerList>(MarkerList.$_createMessage);
  static MarkerList? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<Marker> get markers => $_getList(0);
}

class Marker extends $pb.GeneratedMessage {
  factory Marker({
    $core.String? title,
    $fixnum.Int64? startMs,
  }) {
    final result = Marker._();
    if (title != null) result.title = title;
    if (startMs != null) result.startMs = startMs;
    return result;
  }

  Marker._();

  factory Marker.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Marker()..mergeFromBuffer(data, registry);
  factory Marker.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Marker()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Marker',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'kikuyomi.backup'),
      createEmptyInstance: Marker.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'title')
    ..aInt64(2, _omitFieldNames ? '' : 'startMs')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Marker clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Marker copyWith(void Function(Marker) updates) =>
      super.copyWith((message) => updates(message as Marker)) as Marker;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Marker() / Marker.new instead')
  static Marker create() => Marker._();
  static $pb.GeneratedMessage $_createMessage() => Marker._();
  @$core.override
  Marker createEmptyInstance() => Marker._();
  @$core.pragma('dart2js:noInline')
  static Marker getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Marker>(Marker.$_createMessage);
  static Marker? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get title => $_getSZ(0);
  @$pb.TagNumber(1)
  set title($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTitle() => $_has(0);
  @$pb.TagNumber(1)
  void clearTitle() => $_clearField(1);

  /// Offset into the file.
  @$pb.TagNumber(2)
  $fixnum.Int64 get startMs => $_getI64(1);
  @$pb.TagNumber(2)
  set startMs($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasStartMs() => $_has(1);
  @$pb.TagNumber(2)
  void clearStartMs() => $_clearField(2);
}

/// A logical chapter of a book.
class Chapter extends $pb.GeneratedMessage {
  factory Chapter({
    $core.String? key,
    $core.String? title,
    $core.int? sourceIndex,
    $core.String? groupName,
    $fixnum.Int64? durationMs,
    $fixnum.Int64? publishedAtMs,
    $core.bool? isListened,
    $fixnum.Int64? listenedAtMs,
    $fixnum.Int64? lastPositionMs,
    $core.bool? removedFromSource,
    $fixnum.Int64? createdAtMs,
    $fixnum.Int64? updatedAtMs,
    $core.Iterable<Segment>? segments,
  }) {
    final result = Chapter._();
    if (key != null) result.key = key;
    if (title != null) result.title = title;
    if (sourceIndex != null) result.sourceIndex = sourceIndex;
    if (groupName != null) result.groupName = groupName;
    if (durationMs != null) result.durationMs = durationMs;
    if (publishedAtMs != null) result.publishedAtMs = publishedAtMs;
    if (isListened != null) result.isListened = isListened;
    if (listenedAtMs != null) result.listenedAtMs = listenedAtMs;
    if (lastPositionMs != null) result.lastPositionMs = lastPositionMs;
    if (removedFromSource != null) result.removedFromSource = removedFromSource;
    if (createdAtMs != null) result.createdAtMs = createdAtMs;
    if (updatedAtMs != null) result.updatedAtMs = updatedAtMs;
    if (segments != null) result.segments.addAll(segments);
    return result;
  }

  Chapter._();

  factory Chapter.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Chapter()..mergeFromBuffer(data, registry);
  factory Chapter.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Chapter()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Chapter',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'kikuyomi.backup'),
      createEmptyInstance: Chapter.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'key')
    ..aOS(2, _omitFieldNames ? '' : 'title')
    ..aI(3, _omitFieldNames ? '' : 'sourceIndex')
    ..aOS(4, _omitFieldNames ? '' : 'groupName')
    ..aInt64(5, _omitFieldNames ? '' : 'durationMs')
    ..aInt64(6, _omitFieldNames ? '' : 'publishedAtMs')
    ..aOB(7, _omitFieldNames ? '' : 'isListened')
    ..aInt64(8, _omitFieldNames ? '' : 'listenedAtMs')
    ..aInt64(9, _omitFieldNames ? '' : 'lastPositionMs')
    ..aOB(10, _omitFieldNames ? '' : 'removedFromSource')
    ..aInt64(11, _omitFieldNames ? '' : 'createdAtMs')
    ..aInt64(12, _omitFieldNames ? '' : 'updatedAtMs')
    ..pPM<Segment>(13, _omitFieldNames ? '' : 'segments',
        subBuilder: Segment.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Chapter clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Chapter copyWith(void Function(Chapter) updates) =>
      super.copyWith((message) => updates(message as Chapter)) as Chapter;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Chapter() / Chapter.new instead')
  static Chapter create() => Chapter._();
  static $pb.GeneratedMessage $_createMessage() => Chapter._();
  @$core.override
  Chapter createEmptyInstance() => Chapter._();
  @$core.pragma('dart2js:noInline')
  static Chapter getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Chapter>(Chapter.$_createMessage);
  static Chapter? _defaultInstance;

  /// The chapter's identity within its book.
  @$pb.TagNumber(1)
  $core.String get key => $_getSZ(0);
  @$pb.TagNumber(1)
  set key($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasKey() => $_has(0);
  @$pb.TagNumber(1)
  void clearKey() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get title => $_getSZ(1);
  @$pb.TagNumber(2)
  set title($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTitle() => $_has(1);
  @$pb.TagNumber(2)
  void clearTitle() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get sourceIndex => $_getIZ(2);
  @$pb.TagNumber(3)
  set sourceIndex($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSourceIndex() => $_has(2);
  @$pb.TagNumber(3)
  void clearSourceIndex() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get groupName => $_getSZ(3);
  @$pb.TagNumber(4)
  set groupName($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasGroupName() => $_has(3);
  @$pb.TagNumber(4)
  void clearGroupName() => $_clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get durationMs => $_getI64(4);
  @$pb.TagNumber(5)
  set durationMs($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasDurationMs() => $_has(4);
  @$pb.TagNumber(5)
  void clearDurationMs() => $_clearField(5);

  @$pb.TagNumber(6)
  $fixnum.Int64 get publishedAtMs => $_getI64(5);
  @$pb.TagNumber(6)
  set publishedAtMs($fixnum.Int64 value) => $_setInt64(5, value);
  @$pb.TagNumber(6)
  $core.bool hasPublishedAtMs() => $_has(5);
  @$pb.TagNumber(6)
  void clearPublishedAtMs() => $_clearField(6);

  /// §4.5's listened state. False for every chapter in a backup of format version 1, whose writers
  /// did not record it; see `Backup.format_version`.
  @$pb.TagNumber(7)
  $core.bool get isListened => $_getBF(6);
  @$pb.TagNumber(7)
  set isListened($core.bool value) => $_setBool(6, value);
  @$pb.TagNumber(7)
  $core.bool hasIsListened() => $_has(6);
  @$pb.TagNumber(7)
  void clearIsListened() => $_clearField(7);

  @$pb.TagNumber(8)
  $fixnum.Int64 get listenedAtMs => $_getI64(7);
  @$pb.TagNumber(8)
  set listenedAtMs($fixnum.Int64 value) => $_setInt64(7, value);
  @$pb.TagNumber(8)
  $core.bool hasListenedAtMs() => $_has(7);
  @$pb.TagNumber(8)
  void clearListenedAtMs() => $_clearField(8);

  /// Chapter-relative, per §4.5.
  @$pb.TagNumber(9)
  $fixnum.Int64 get lastPositionMs => $_getI64(8);
  @$pb.TagNumber(9)
  set lastPositionMs($fixnum.Int64 value) => $_setInt64(8, value);
  @$pb.TagNumber(9)
  $core.bool hasLastPositionMs() => $_has(8);
  @$pb.TagNumber(9)
  void clearLastPositionMs() => $_clearField(9);

  /// §4.4's soft delete.
  @$pb.TagNumber(10)
  $core.bool get removedFromSource => $_getBF(9);
  @$pb.TagNumber(10)
  set removedFromSource($core.bool value) => $_setBool(9, value);
  @$pb.TagNumber(10)
  $core.bool hasRemovedFromSource() => $_has(9);
  @$pb.TagNumber(10)
  void clearRemovedFromSource() => $_clearField(10);

  @$pb.TagNumber(11)
  $fixnum.Int64 get createdAtMs => $_getI64(10);
  @$pb.TagNumber(11)
  set createdAtMs($fixnum.Int64 value) => $_setInt64(10, value);
  @$pb.TagNumber(11)
  $core.bool hasCreatedAtMs() => $_has(10);
  @$pb.TagNumber(11)
  void clearCreatedAtMs() => $_clearField(11);

  @$pb.TagNumber(12)
  $fixnum.Int64 get updatedAtMs => $_getI64(11);
  @$pb.TagNumber(12)
  set updatedAtMs($fixnum.Int64 value) => $_setInt64(11, value);
  @$pb.TagNumber(12)
  $core.bool hasUpdatedAtMs() => $_has(11);
  @$pb.TagNumber(12)
  void clearUpdatedAtMs() => $_clearField(12);

  /// The chapter's layout across files, in playing order.
  @$pb.TagNumber(13)
  $pb.PbList<Segment> get segments => $_getList(12);
}

/// A stretch of one file that forms part of a chapter.
class Segment extends $pb.GeneratedMessage {
  factory Segment({
    $core.String? fileKey,
    $fixnum.Int64? startMs,
    $fixnum.Int64? endMs,
  }) {
    final result = Segment._();
    if (fileKey != null) result.fileKey = fileKey;
    if (startMs != null) result.startMs = startMs;
    if (endMs != null) result.endMs = endMs;
    return result;
  }

  Segment._();

  factory Segment.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Segment()..mergeFromBuffer(data, registry);
  factory Segment.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Segment()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Segment',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'kikuyomi.backup'),
      createEmptyInstance: Segment.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'fileKey')
    ..aInt64(2, _omitFieldNames ? '' : 'startMs')
    ..aInt64(3, _omitFieldNames ? '' : 'endMs')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Segment clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Segment copyWith(void Function(Segment) updates) =>
      super.copyWith((message) => updates(message as Segment)) as Segment;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Segment() / Segment.new instead')
  static Segment create() => Segment._();
  static $pb.GeneratedMessage $_createMessage() => Segment._();
  @$core.override
  Segment createEmptyInstance() => Segment._();
  @$core.pragma('dart2js:noInline')
  static Segment getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Segment>(Segment.$_createMessage);
  static Segment? _defaultInstance;

  /// A `MediaFile.file_key` of the same book.
  @$pb.TagNumber(1)
  $core.String get fileKey => $_getSZ(0);
  @$pb.TagNumber(1)
  set fileKey($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasFileKey() => $_has(0);
  @$pb.TagNumber(1)
  void clearFileKey() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get startMs => $_getI64(1);
  @$pb.TagNumber(2)
  set startMs($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasStartMs() => $_has(1);
  @$pb.TagNumber(2)
  void clearStartMs() => $_clearField(2);

  /// Absent means to the end of the file.
  @$pb.TagNumber(3)
  $fixnum.Int64 get endMs => $_getI64(2);
  @$pb.TagNumber(3)
  set endMs($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasEndMs() => $_has(2);
  @$pb.TagNumber(3)
  void clearEndMs() => $_clearField(3);
}

/// Where a book is up to: §4.3's `playback_state`.
class PlaybackState extends $pb.GeneratedMessage {
  factory PlaybackState({
    $core.String? chapterKey,
    $fixnum.Int64? chapterPositionMs,
    $fixnum.Int64? globalPositionMs,
    $fixnum.Int64? updatedAtMs,
    $core.String? deviceId,
  }) {
    final result = PlaybackState._();
    if (chapterKey != null) result.chapterKey = chapterKey;
    if (chapterPositionMs != null) result.chapterPositionMs = chapterPositionMs;
    if (globalPositionMs != null) result.globalPositionMs = globalPositionMs;
    if (updatedAtMs != null) result.updatedAtMs = updatedAtMs;
    if (deviceId != null) result.deviceId = deviceId;
    return result;
  }

  PlaybackState._();

  factory PlaybackState.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PlaybackState()..mergeFromBuffer(data, registry);
  factory PlaybackState.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PlaybackState()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PlaybackState',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'kikuyomi.backup'),
      createEmptyInstance: PlaybackState.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'chapterKey')
    ..aInt64(2, _omitFieldNames ? '' : 'chapterPositionMs')
    ..aInt64(3, _omitFieldNames ? '' : 'globalPositionMs')
    ..aInt64(4, _omitFieldNames ? '' : 'updatedAtMs')
    ..aOS(5, _omitFieldNames ? '' : 'deviceId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PlaybackState clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PlaybackState copyWith(void Function(PlaybackState) updates) =>
      super.copyWith((message) => updates(message as PlaybackState))
          as PlaybackState;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use PlaybackState() / PlaybackState.new instead')
  static PlaybackState create() => PlaybackState._();
  static $pb.GeneratedMessage $_createMessage() => PlaybackState._();
  @$core.override
  PlaybackState createEmptyInstance() => PlaybackState._();
  @$core.pragma('dart2js:noInline')
  static PlaybackState getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PlaybackState>(
          PlaybackState.$_createMessage);
  static PlaybackState? _defaultInstance;

  /// A `Chapter.key` of the same book.
  @$pb.TagNumber(1)
  $core.String get chapterKey => $_getSZ(0);
  @$pb.TagNumber(1)
  set chapterKey($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasChapterKey() => $_has(0);
  @$pb.TagNumber(1)
  void clearChapterKey() => $_clearField(1);

  /// The truth, per §4.5.
  @$pb.TagNumber(2)
  $fixnum.Int64 get chapterPositionMs => $_getI64(1);
  @$pb.TagNumber(2)
  set chapterPositionMs($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasChapterPositionMs() => $_has(1);
  @$pb.TagNumber(2)
  void clearChapterPositionMs() => $_clearField(2);

  /// Derived from the Timeline and cached for sorting.
  @$pb.TagNumber(3)
  $fixnum.Int64 get globalPositionMs => $_getI64(2);
  @$pb.TagNumber(3)
  set globalPositionMs($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasGlobalPositionMs() => $_has(2);
  @$pb.TagNumber(3)
  void clearGlobalPositionMs() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get updatedAtMs => $_getI64(3);
  @$pb.TagNumber(4)
  set updatedAtMs($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasUpdatedAtMs() => $_has(3);
  @$pb.TagNumber(4)
  void clearUpdatedAtMs() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get deviceId => $_getSZ(4);
  @$pb.TagNumber(5)
  set deviceId($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasDeviceId() => $_has(4);
  @$pb.TagNumber(5)
  void clearDeviceId() => $_clearField(5);
}

/// Where the reader of a book is up to: §4.3's `reading_state` (ADR-0019).
class ReadingState extends $pb.GeneratedMessage {
  factory ReadingState({
    $core.String? chapterKey,
    $core.double? progress,
    $fixnum.Int64? updatedAtMs,
  }) {
    final result = ReadingState._();
    if (chapterKey != null) result.chapterKey = chapterKey;
    if (progress != null) result.progress = progress;
    if (updatedAtMs != null) result.updatedAtMs = updatedAtMs;
    return result;
  }

  ReadingState._();

  factory ReadingState.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReadingState()..mergeFromBuffer(data, registry);
  factory ReadingState.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ReadingState()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReadingState',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'kikuyomi.backup'),
      createEmptyInstance: ReadingState.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'chapterKey')
    ..aD(2, _omitFieldNames ? '' : 'progress')
    ..aInt64(3, _omitFieldNames ? '' : 'updatedAtMs')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReadingState clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReadingState copyWith(void Function(ReadingState) updates) =>
      super.copyWith((message) => updates(message as ReadingState))
          as ReadingState;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ReadingState() / ReadingState.new instead')
  static ReadingState create() => ReadingState._();
  static $pb.GeneratedMessage $_createMessage() => ReadingState._();
  @$core.override
  ReadingState createEmptyInstance() => ReadingState._();
  @$core.pragma('dart2js:noInline')
  static ReadingState getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ReadingState>(
          ReadingState.$_createMessage);
  static ReadingState? _defaultInstance;

  /// A `Chapter.key` of the same book.
  @$pb.TagNumber(1)
  $core.String get chapterKey => $_getSZ(0);
  @$pb.TagNumber(1)
  set chapterKey($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasChapterKey() => $_has(0);
  @$pb.TagNumber(1)
  void clearChapterKey() => $_clearField(1);

  /// How far through the chapter, from 0 at its start to 1 at its end. A fraction rather than a
  /// position in characters, so that it survives a different font size or screen.
  @$pb.TagNumber(2)
  $core.double get progress => $_getN(1);
  @$pb.TagNumber(2)
  set progress($core.double value) => $_setDouble(1, value);
  @$pb.TagNumber(2)
  $core.bool hasProgress() => $_has(1);
  @$pb.TagNumber(2)
  void clearProgress() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get updatedAtMs => $_getI64(2);
  @$pb.TagNumber(3)
  set updatedAtMs($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasUpdatedAtMs() => $_has(2);
  @$pb.TagNumber(3)
  void clearUpdatedAtMs() => $_clearField(3);
}

/// One stretch of listening, for history and statistics.
class ListeningSession extends $pb.GeneratedMessage {
  factory ListeningSession({
    $core.String? chapterKey,
    $fixnum.Int64? startedAtMs,
    $fixnum.Int64? endedAtMs,
    $fixnum.Int64? startGlobalMs,
    $fixnum.Int64? endGlobalMs,
    $core.double? speed,
    $core.String? deviceId,
  }) {
    final result = ListeningSession._();
    if (chapterKey != null) result.chapterKey = chapterKey;
    if (startedAtMs != null) result.startedAtMs = startedAtMs;
    if (endedAtMs != null) result.endedAtMs = endedAtMs;
    if (startGlobalMs != null) result.startGlobalMs = startGlobalMs;
    if (endGlobalMs != null) result.endGlobalMs = endGlobalMs;
    if (speed != null) result.speed = speed;
    if (deviceId != null) result.deviceId = deviceId;
    return result;
  }

  ListeningSession._();

  factory ListeningSession.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListeningSession()..mergeFromBuffer(data, registry);
  factory ListeningSession.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListeningSession()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListeningSession',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'kikuyomi.backup'),
      createEmptyInstance: ListeningSession.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'chapterKey')
    ..aInt64(2, _omitFieldNames ? '' : 'startedAtMs')
    ..aInt64(3, _omitFieldNames ? '' : 'endedAtMs')
    ..aInt64(4, _omitFieldNames ? '' : 'startGlobalMs')
    ..aInt64(5, _omitFieldNames ? '' : 'endGlobalMs')
    ..aD(6, _omitFieldNames ? '' : 'speed')
    ..aOS(7, _omitFieldNames ? '' : 'deviceId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListeningSession clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListeningSession copyWith(void Function(ListeningSession) updates) =>
      super.copyWith((message) => updates(message as ListeningSession))
          as ListeningSession;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ListeningSession() / ListeningSession.new instead')
  static ListeningSession create() => ListeningSession._();
  static $pb.GeneratedMessage $_createMessage() => ListeningSession._();
  @$core.override
  ListeningSession createEmptyInstance() => ListeningSession._();
  @$core.pragma('dart2js:noInline')
  static ListeningSession getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ListeningSession>(
          ListeningSession.$_createMessage);
  static ListeningSession? _defaultInstance;

  /// A `Chapter.key` of the same book. Absent when the chapter was purged, since history outlives
  /// the chapters it covered.
  @$pb.TagNumber(1)
  $core.String get chapterKey => $_getSZ(0);
  @$pb.TagNumber(1)
  set chapterKey($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasChapterKey() => $_has(0);
  @$pb.TagNumber(1)
  void clearChapterKey() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get startedAtMs => $_getI64(1);
  @$pb.TagNumber(2)
  set startedAtMs($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasStartedAtMs() => $_has(1);
  @$pb.TagNumber(2)
  void clearStartedAtMs() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get endedAtMs => $_getI64(2);
  @$pb.TagNumber(3)
  set endedAtMs($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasEndedAtMs() => $_has(2);
  @$pb.TagNumber(3)
  void clearEndedAtMs() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get startGlobalMs => $_getI64(3);
  @$pb.TagNumber(4)
  set startGlobalMs($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasStartGlobalMs() => $_has(3);
  @$pb.TagNumber(4)
  void clearStartGlobalMs() => $_clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get endGlobalMs => $_getI64(4);
  @$pb.TagNumber(5)
  set endGlobalMs($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasEndGlobalMs() => $_has(4);
  @$pb.TagNumber(5)
  void clearEndGlobalMs() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.double get speed => $_getN(5);
  @$pb.TagNumber(6)
  set speed($core.double value) => $_setDouble(5, value);
  @$pb.TagNumber(6)
  $core.bool hasSpeed() => $_has(5);
  @$pb.TagNumber(6)
  void clearSpeed() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get deviceId => $_getSZ(6);
  @$pb.TagNumber(7)
  set deviceId($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasDeviceId() => $_has(6);
  @$pb.TagNumber(7)
  void clearDeviceId() => $_clearField(7);
}

class Bookmark extends $pb.GeneratedMessage {
  factory Bookmark({
    $core.String? chapterKey,
    $fixnum.Int64? positionMs,
    $core.String? title,
    $core.String? note,
    $fixnum.Int64? createdAtMs,
  }) {
    final result = Bookmark._();
    if (chapterKey != null) result.chapterKey = chapterKey;
    if (positionMs != null) result.positionMs = positionMs;
    if (title != null) result.title = title;
    if (note != null) result.note = note;
    if (createdAtMs != null) result.createdAtMs = createdAtMs;
    return result;
  }

  Bookmark._();

  factory Bookmark.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Bookmark()..mergeFromBuffer(data, registry);
  factory Bookmark.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Bookmark()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Bookmark',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'kikuyomi.backup'),
      createEmptyInstance: Bookmark.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'chapterKey')
    ..aInt64(2, _omitFieldNames ? '' : 'positionMs')
    ..aOS(3, _omitFieldNames ? '' : 'title')
    ..aOS(4, _omitFieldNames ? '' : 'note')
    ..aInt64(5, _omitFieldNames ? '' : 'createdAtMs')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Bookmark clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Bookmark copyWith(void Function(Bookmark) updates) =>
      super.copyWith((message) => updates(message as Bookmark)) as Bookmark;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Bookmark() / Bookmark.new instead')
  static Bookmark create() => Bookmark._();
  static $pb.GeneratedMessage $_createMessage() => Bookmark._();
  @$core.override
  Bookmark createEmptyInstance() => Bookmark._();
  @$core.pragma('dart2js:noInline')
  static Bookmark getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Bookmark>(Bookmark.$_createMessage);
  static Bookmark? _defaultInstance;

  /// A `Chapter.key` of the same book.
  @$pb.TagNumber(1)
  $core.String get chapterKey => $_getSZ(0);
  @$pb.TagNumber(1)
  set chapterKey($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasChapterKey() => $_has(0);
  @$pb.TagNumber(1)
  void clearChapterKey() => $_clearField(1);

  /// Chapter-relative.
  @$pb.TagNumber(2)
  $fixnum.Int64 get positionMs => $_getI64(1);
  @$pb.TagNumber(2)
  set positionMs($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPositionMs() => $_has(1);
  @$pb.TagNumber(2)
  void clearPositionMs() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get title => $_getSZ(2);
  @$pb.TagNumber(3)
  set title($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasTitle() => $_has(2);
  @$pb.TagNumber(3)
  void clearTitle() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get note => $_getSZ(3);
  @$pb.TagNumber(4)
  set note($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasNote() => $_has(3);
  @$pb.TagNumber(4)
  void clearNote() => $_clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get createdAtMs => $_getI64(4);
  @$pb.TagNumber(5)
  set createdAtMs($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasCreatedAtMs() => $_has(4);
  @$pb.TagNumber(5)
  void clearCreatedAtMs() => $_clearField(5);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
