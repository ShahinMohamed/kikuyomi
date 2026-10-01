// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $SourcesTable extends Sources with TableInfo<$SourcesTable, SourceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SourcesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _extensionIdMeta = const VerificationMeta(
    'extensionId',
  );
  @override
  late final GeneratedColumn<String> extensionId = GeneratedColumn<String>(
    'extension_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _langMeta = const VerificationMeta('lang');
  @override
  late final GeneratedColumn<String> lang = GeneratedColumn<String>(
    'lang',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentRatingMeta = const VerificationMeta(
    'contentRating',
  );
  @override
  late final GeneratedColumn<String> contentRating = GeneratedColumn<String>(
    'content_rating',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isEnabledMeta = const VerificationMeta(
    'isEnabled',
  );
  @override
  late final GeneratedColumn<bool> isEnabled = GeneratedColumn<bool>(
    'is_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _isPinnedMeta = const VerificationMeta(
    'isPinned',
  );
  @override
  late final GeneratedColumn<bool> isPinned = GeneratedColumn<bool>(
    'is_pinned',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_pinned" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _lastUsedAtMeta = const VerificationMeta(
    'lastUsedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastUsedAt = GeneratedColumn<DateTime>(
    'last_used_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    extensionId,
    key,
    name,
    lang,
    contentRating,
    isEnabled,
    isPinned,
    lastUsedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sources';
  @override
  VerificationContext validateIntegrity(
    Insertable<SourceRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('extension_id')) {
      context.handle(
        _extensionIdMeta,
        extensionId.isAcceptableOrUnknown(
          data['extension_id']!,
          _extensionIdMeta,
        ),
      );
    }
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('lang')) {
      context.handle(
        _langMeta,
        lang.isAcceptableOrUnknown(data['lang']!, _langMeta),
      );
    } else if (isInserting) {
      context.missing(_langMeta);
    }
    if (data.containsKey('content_rating')) {
      context.handle(
        _contentRatingMeta,
        contentRating.isAcceptableOrUnknown(
          data['content_rating']!,
          _contentRatingMeta,
        ),
      );
    }
    if (data.containsKey('is_enabled')) {
      context.handle(
        _isEnabledMeta,
        isEnabled.isAcceptableOrUnknown(data['is_enabled']!, _isEnabledMeta),
      );
    }
    if (data.containsKey('is_pinned')) {
      context.handle(
        _isPinnedMeta,
        isPinned.isAcceptableOrUnknown(data['is_pinned']!, _isPinnedMeta),
      );
    }
    if (data.containsKey('last_used_at')) {
      context.handle(
        _lastUsedAtMeta,
        lastUsedAt.isAcceptableOrUnknown(
          data['last_used_at']!,
          _lastUsedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SourceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SourceRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      extensionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}extension_id'],
      ),
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      lang: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lang'],
      )!,
      contentRating: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content_rating'],
      ),
      isEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_enabled'],
      )!,
      isPinned: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_pinned'],
      )!,
      lastUsedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_used_at'],
      ),
    );
  }

  @override
  $SourcesTable createAlias(String alias) {
    return $SourcesTable(attachedDatabase, alias);
  }
}

class SourceRow extends DataClass implements Insertable<SourceRow> {
  /// The stable 64-bit hash §3 describes, not an autoincrement.
  final int id;

  /// Null for a built-in source.
  ///
  /// Not a foreign key to [Extensions], although that table now exists, and deliberately so. §3.9:
  /// "Uninstalling removes the code but not the user's data: library books from that source keep
  /// their metadata, progress, and downloads, and point to a stub source until the extension returns
  /// or the books are migrated." A source therefore outlives the extension it came from, and holds
  /// on to its id so that the same extension installed again is recognised as the same one. A
  /// foreign key would force the opposite: either the uninstall fails, or the link is lost, or the
  /// books go with it.
  final String? extensionId;
  final String key;
  final String name;
  final String lang;
  final String? contentRating;
  final bool isEnabled;
  final bool isPinned;
  final DateTime? lastUsedAt;
  const SourceRow({
    required this.id,
    this.extensionId,
    required this.key,
    required this.name,
    required this.lang,
    this.contentRating,
    required this.isEnabled,
    required this.isPinned,
    this.lastUsedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || extensionId != null) {
      map['extension_id'] = Variable<String>(extensionId);
    }
    map['key'] = Variable<String>(key);
    map['name'] = Variable<String>(name);
    map['lang'] = Variable<String>(lang);
    if (!nullToAbsent || contentRating != null) {
      map['content_rating'] = Variable<String>(contentRating);
    }
    map['is_enabled'] = Variable<bool>(isEnabled);
    map['is_pinned'] = Variable<bool>(isPinned);
    if (!nullToAbsent || lastUsedAt != null) {
      map['last_used_at'] = Variable<DateTime>(lastUsedAt);
    }
    return map;
  }

  SourcesCompanion toCompanion(bool nullToAbsent) {
    return SourcesCompanion(
      id: Value(id),
      extensionId: extensionId == null && nullToAbsent
          ? const Value.absent()
          : Value(extensionId),
      key: Value(key),
      name: Value(name),
      lang: Value(lang),
      contentRating: contentRating == null && nullToAbsent
          ? const Value.absent()
          : Value(contentRating),
      isEnabled: Value(isEnabled),
      isPinned: Value(isPinned),
      lastUsedAt: lastUsedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastUsedAt),
    );
  }

  factory SourceRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SourceRow(
      id: serializer.fromJson<int>(json['id']),
      extensionId: serializer.fromJson<String?>(json['extensionId']),
      key: serializer.fromJson<String>(json['key']),
      name: serializer.fromJson<String>(json['name']),
      lang: serializer.fromJson<String>(json['lang']),
      contentRating: serializer.fromJson<String?>(json['contentRating']),
      isEnabled: serializer.fromJson<bool>(json['isEnabled']),
      isPinned: serializer.fromJson<bool>(json['isPinned']),
      lastUsedAt: serializer.fromJson<DateTime?>(json['lastUsedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'extensionId': serializer.toJson<String?>(extensionId),
      'key': serializer.toJson<String>(key),
      'name': serializer.toJson<String>(name),
      'lang': serializer.toJson<String>(lang),
      'contentRating': serializer.toJson<String?>(contentRating),
      'isEnabled': serializer.toJson<bool>(isEnabled),
      'isPinned': serializer.toJson<bool>(isPinned),
      'lastUsedAt': serializer.toJson<DateTime?>(lastUsedAt),
    };
  }

  SourceRow copyWith({
    int? id,
    Value<String?> extensionId = const Value.absent(),
    String? key,
    String? name,
    String? lang,
    Value<String?> contentRating = const Value.absent(),
    bool? isEnabled,
    bool? isPinned,
    Value<DateTime?> lastUsedAt = const Value.absent(),
  }) => SourceRow(
    id: id ?? this.id,
    extensionId: extensionId.present ? extensionId.value : this.extensionId,
    key: key ?? this.key,
    name: name ?? this.name,
    lang: lang ?? this.lang,
    contentRating: contentRating.present
        ? contentRating.value
        : this.contentRating,
    isEnabled: isEnabled ?? this.isEnabled,
    isPinned: isPinned ?? this.isPinned,
    lastUsedAt: lastUsedAt.present ? lastUsedAt.value : this.lastUsedAt,
  );
  SourceRow copyWithCompanion(SourcesCompanion data) {
    return SourceRow(
      id: data.id.present ? data.id.value : this.id,
      extensionId: data.extensionId.present
          ? data.extensionId.value
          : this.extensionId,
      key: data.key.present ? data.key.value : this.key,
      name: data.name.present ? data.name.value : this.name,
      lang: data.lang.present ? data.lang.value : this.lang,
      contentRating: data.contentRating.present
          ? data.contentRating.value
          : this.contentRating,
      isEnabled: data.isEnabled.present ? data.isEnabled.value : this.isEnabled,
      isPinned: data.isPinned.present ? data.isPinned.value : this.isPinned,
      lastUsedAt: data.lastUsedAt.present
          ? data.lastUsedAt.value
          : this.lastUsedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SourceRow(')
          ..write('id: $id, ')
          ..write('extensionId: $extensionId, ')
          ..write('key: $key, ')
          ..write('name: $name, ')
          ..write('lang: $lang, ')
          ..write('contentRating: $contentRating, ')
          ..write('isEnabled: $isEnabled, ')
          ..write('isPinned: $isPinned, ')
          ..write('lastUsedAt: $lastUsedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    extensionId,
    key,
    name,
    lang,
    contentRating,
    isEnabled,
    isPinned,
    lastUsedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SourceRow &&
          other.id == this.id &&
          other.extensionId == this.extensionId &&
          other.key == this.key &&
          other.name == this.name &&
          other.lang == this.lang &&
          other.contentRating == this.contentRating &&
          other.isEnabled == this.isEnabled &&
          other.isPinned == this.isPinned &&
          other.lastUsedAt == this.lastUsedAt);
}

class SourcesCompanion extends UpdateCompanion<SourceRow> {
  final Value<int> id;
  final Value<String?> extensionId;
  final Value<String> key;
  final Value<String> name;
  final Value<String> lang;
  final Value<String?> contentRating;
  final Value<bool> isEnabled;
  final Value<bool> isPinned;
  final Value<DateTime?> lastUsedAt;
  const SourcesCompanion({
    this.id = const Value.absent(),
    this.extensionId = const Value.absent(),
    this.key = const Value.absent(),
    this.name = const Value.absent(),
    this.lang = const Value.absent(),
    this.contentRating = const Value.absent(),
    this.isEnabled = const Value.absent(),
    this.isPinned = const Value.absent(),
    this.lastUsedAt = const Value.absent(),
  });
  SourcesCompanion.insert({
    this.id = const Value.absent(),
    this.extensionId = const Value.absent(),
    required String key,
    required String name,
    required String lang,
    this.contentRating = const Value.absent(),
    this.isEnabled = const Value.absent(),
    this.isPinned = const Value.absent(),
    this.lastUsedAt = const Value.absent(),
  }) : key = Value(key),
       name = Value(name),
       lang = Value(lang);
  static Insertable<SourceRow> custom({
    Expression<int>? id,
    Expression<String>? extensionId,
    Expression<String>? key,
    Expression<String>? name,
    Expression<String>? lang,
    Expression<String>? contentRating,
    Expression<bool>? isEnabled,
    Expression<bool>? isPinned,
    Expression<DateTime>? lastUsedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (extensionId != null) 'extension_id': extensionId,
      if (key != null) 'key': key,
      if (name != null) 'name': name,
      if (lang != null) 'lang': lang,
      if (contentRating != null) 'content_rating': contentRating,
      if (isEnabled != null) 'is_enabled': isEnabled,
      if (isPinned != null) 'is_pinned': isPinned,
      if (lastUsedAt != null) 'last_used_at': lastUsedAt,
    });
  }

  SourcesCompanion copyWith({
    Value<int>? id,
    Value<String?>? extensionId,
    Value<String>? key,
    Value<String>? name,
    Value<String>? lang,
    Value<String?>? contentRating,
    Value<bool>? isEnabled,
    Value<bool>? isPinned,
    Value<DateTime?>? lastUsedAt,
  }) {
    return SourcesCompanion(
      id: id ?? this.id,
      extensionId: extensionId ?? this.extensionId,
      key: key ?? this.key,
      name: name ?? this.name,
      lang: lang ?? this.lang,
      contentRating: contentRating ?? this.contentRating,
      isEnabled: isEnabled ?? this.isEnabled,
      isPinned: isPinned ?? this.isPinned,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (extensionId.present) {
      map['extension_id'] = Variable<String>(extensionId.value);
    }
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (lang.present) {
      map['lang'] = Variable<String>(lang.value);
    }
    if (contentRating.present) {
      map['content_rating'] = Variable<String>(contentRating.value);
    }
    if (isEnabled.present) {
      map['is_enabled'] = Variable<bool>(isEnabled.value);
    }
    if (isPinned.present) {
      map['is_pinned'] = Variable<bool>(isPinned.value);
    }
    if (lastUsedAt.present) {
      map['last_used_at'] = Variable<DateTime>(lastUsedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SourcesCompanion(')
          ..write('id: $id, ')
          ..write('extensionId: $extensionId, ')
          ..write('key: $key, ')
          ..write('name: $name, ')
          ..write('lang: $lang, ')
          ..write('contentRating: $contentRating, ')
          ..write('isEnabled: $isEnabled, ')
          ..write('isPinned: $isPinned, ')
          ..write('lastUsedAt: $lastUsedAt')
          ..write(')'))
        .toString();
  }
}

class $BooksTable extends Books with TableInfo<$BooksTable, BookRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BooksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _sourceIdMeta = const VerificationMeta(
    'sourceId',
  );
  @override
  late final GeneratedColumn<int> sourceId = GeneratedColumn<int>(
    'source_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES sources (id)',
    ),
  );
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subtitleMeta = const VerificationMeta(
    'subtitle',
  );
  @override
  late final GeneratedColumn<String> subtitle = GeneratedColumn<String>(
    'subtitle',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _coverUrlMeta = const VerificationMeta(
    'coverUrl',
  );
  @override
  late final GeneratedColumn<String> coverUrl = GeneratedColumn<String>(
    'cover_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _coverLocalPathMeta = const VerificationMeta(
    'coverLocalPath',
  );
  @override
  late final GeneratedColumn<String> coverLocalPath = GeneratedColumn<String>(
    'cover_local_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _coverUpdatedAtMeta = const VerificationMeta(
    'coverUpdatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> coverUpdatedAt =
      GeneratedColumn<DateTime>(
        'cover_updated_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _seriesNameMeta = const VerificationMeta(
    'seriesName',
  );
  @override
  late final GeneratedColumn<String> seriesName = GeneratedColumn<String>(
    'series_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _seriesIndexMeta = const VerificationMeta(
    'seriesIndex',
  );
  @override
  late final GeneratedColumn<double> seriesIndex = GeneratedColumn<double>(
    'series_index',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<List<String>, String> genres =
      GeneratedColumn<String>(
        'genres',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('[]'),
      ).withConverter<List<String>>($BooksTable.$convertergenres);
  static const VerificationMeta _languageMeta = const VerificationMeta(
    'language',
  );
  @override
  late final GeneratedColumn<String> language = GeneratedColumn<String>(
    'language',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _publisherMeta = const VerificationMeta(
    'publisher',
  );
  @override
  late final GeneratedColumn<String> publisher = GeneratedColumn<String>(
    'publisher',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _publishedDateMeta = const VerificationMeta(
    'publishedDate',
  );
  @override
  late final GeneratedColumn<String> publishedDate = GeneratedColumn<String>(
    'published_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isbnMeta = const VerificationMeta('isbn');
  @override
  late final GeneratedColumn<String> isbn = GeneratedColumn<String>(
    'isbn',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _abridgedMeta = const VerificationMeta(
    'abridged',
  );
  @override
  late final GeneratedColumn<bool> abridged = GeneratedColumn<bool>(
    'abridged',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("abridged" IN (0, 1))',
    ),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _contentRatingMeta = const VerificationMeta(
    'contentRating',
  );
  @override
  late final GeneratedColumn<String> contentRating = GeneratedColumn<String>(
    'content_rating',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _totalDurationMsMeta = const VerificationMeta(
    'totalDurationMs',
  );
  @override
  late final GeneratedColumn<int> totalDurationMs = GeneratedColumn<int>(
    'total_duration_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _webUrlMeta = const VerificationMeta('webUrl');
  @override
  late final GeneratedColumn<String> webUrl = GeneratedColumn<String>(
    'web_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _inLibraryMeta = const VerificationMeta(
    'inLibrary',
  );
  @override
  late final GeneratedColumn<bool> inLibrary = GeneratedColumn<bool>(
    'in_library',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("in_library" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _dateAddedMeta = const VerificationMeta(
    'dateAdded',
  );
  @override
  late final GeneratedColumn<DateTime> dateAdded = GeneratedColumn<DateTime>(
    'date_added',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastRefreshedAtMeta = const VerificationMeta(
    'lastRefreshedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastRefreshedAt =
      GeneratedColumn<DateTime>(
        'last_refreshed_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _detailsFetchedMeta = const VerificationMeta(
    'detailsFetched',
  );
  @override
  late final GeneratedColumn<bool> detailsFetched = GeneratedColumn<bool>(
    'details_fetched',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("details_fetched" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  late final GeneratedColumnWithTypeConverter<Set<BookField>, String>
  userOverrides = GeneratedColumn<String>(
    'user_overrides',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  ).withConverter<Set<BookField>>($BooksTable.$converteruserOverrides);
  static const VerificationMeta _playbackSpeedMeta = const VerificationMeta(
    'playbackSpeed',
  );
  @override
  late final GeneratedColumn<double> playbackSpeed = GeneratedColumn<double>(
    'playback_speed',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _chaptersReversedMeta = const VerificationMeta(
    'chaptersReversed',
  );
  @override
  late final GeneratedColumn<bool> chaptersReversed = GeneratedColumn<bool>(
    'chapters_reversed',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("chapters_reversed" IN (0, 1))',
    ),
  );
  static const VerificationMeta _continueHiddenAtMeta = const VerificationMeta(
    'continueHiddenAt',
  );
  @override
  late final GeneratedColumn<DateTime> continueHiddenAt =
      GeneratedColumn<DateTime>(
        'continue_hidden_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _filePathMeta = const VerificationMeta(
    'filePath',
  );
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
    'file_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<SourceKind, String> kind =
      GeneratedColumn<String>(
        'kind',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('audio'),
      ).withConverter<SourceKind>($BooksTable.$converterkind);
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sourceId,
    key,
    title,
    subtitle,
    description,
    coverUrl,
    coverLocalPath,
    coverUpdatedAt,
    seriesName,
    seriesIndex,
    genres,
    language,
    publisher,
    publishedDate,
    isbn,
    abridged,
    status,
    contentRating,
    totalDurationMs,
    webUrl,
    inLibrary,
    dateAdded,
    lastRefreshedAt,
    detailsFetched,
    userOverrides,
    playbackSpeed,
    chaptersReversed,
    continueHiddenAt,
    filePath,
    kind,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'books';
  @override
  VerificationContext validateIntegrity(
    Insertable<BookRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('source_id')) {
      context.handle(
        _sourceIdMeta,
        sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceIdMeta);
    }
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('subtitle')) {
      context.handle(
        _subtitleMeta,
        subtitle.isAcceptableOrUnknown(data['subtitle']!, _subtitleMeta),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('cover_url')) {
      context.handle(
        _coverUrlMeta,
        coverUrl.isAcceptableOrUnknown(data['cover_url']!, _coverUrlMeta),
      );
    }
    if (data.containsKey('cover_local_path')) {
      context.handle(
        _coverLocalPathMeta,
        coverLocalPath.isAcceptableOrUnknown(
          data['cover_local_path']!,
          _coverLocalPathMeta,
        ),
      );
    }
    if (data.containsKey('cover_updated_at')) {
      context.handle(
        _coverUpdatedAtMeta,
        coverUpdatedAt.isAcceptableOrUnknown(
          data['cover_updated_at']!,
          _coverUpdatedAtMeta,
        ),
      );
    }
    if (data.containsKey('series_name')) {
      context.handle(
        _seriesNameMeta,
        seriesName.isAcceptableOrUnknown(data['series_name']!, _seriesNameMeta),
      );
    }
    if (data.containsKey('series_index')) {
      context.handle(
        _seriesIndexMeta,
        seriesIndex.isAcceptableOrUnknown(
          data['series_index']!,
          _seriesIndexMeta,
        ),
      );
    }
    if (data.containsKey('language')) {
      context.handle(
        _languageMeta,
        language.isAcceptableOrUnknown(data['language']!, _languageMeta),
      );
    }
    if (data.containsKey('publisher')) {
      context.handle(
        _publisherMeta,
        publisher.isAcceptableOrUnknown(data['publisher']!, _publisherMeta),
      );
    }
    if (data.containsKey('published_date')) {
      context.handle(
        _publishedDateMeta,
        publishedDate.isAcceptableOrUnknown(
          data['published_date']!,
          _publishedDateMeta,
        ),
      );
    }
    if (data.containsKey('isbn')) {
      context.handle(
        _isbnMeta,
        isbn.isAcceptableOrUnknown(data['isbn']!, _isbnMeta),
      );
    }
    if (data.containsKey('abridged')) {
      context.handle(
        _abridgedMeta,
        abridged.isAcceptableOrUnknown(data['abridged']!, _abridgedMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('content_rating')) {
      context.handle(
        _contentRatingMeta,
        contentRating.isAcceptableOrUnknown(
          data['content_rating']!,
          _contentRatingMeta,
        ),
      );
    }
    if (data.containsKey('total_duration_ms')) {
      context.handle(
        _totalDurationMsMeta,
        totalDurationMs.isAcceptableOrUnknown(
          data['total_duration_ms']!,
          _totalDurationMsMeta,
        ),
      );
    }
    if (data.containsKey('web_url')) {
      context.handle(
        _webUrlMeta,
        webUrl.isAcceptableOrUnknown(data['web_url']!, _webUrlMeta),
      );
    }
    if (data.containsKey('in_library')) {
      context.handle(
        _inLibraryMeta,
        inLibrary.isAcceptableOrUnknown(data['in_library']!, _inLibraryMeta),
      );
    }
    if (data.containsKey('date_added')) {
      context.handle(
        _dateAddedMeta,
        dateAdded.isAcceptableOrUnknown(data['date_added']!, _dateAddedMeta),
      );
    }
    if (data.containsKey('last_refreshed_at')) {
      context.handle(
        _lastRefreshedAtMeta,
        lastRefreshedAt.isAcceptableOrUnknown(
          data['last_refreshed_at']!,
          _lastRefreshedAtMeta,
        ),
      );
    }
    if (data.containsKey('details_fetched')) {
      context.handle(
        _detailsFetchedMeta,
        detailsFetched.isAcceptableOrUnknown(
          data['details_fetched']!,
          _detailsFetchedMeta,
        ),
      );
    }
    if (data.containsKey('playback_speed')) {
      context.handle(
        _playbackSpeedMeta,
        playbackSpeed.isAcceptableOrUnknown(
          data['playback_speed']!,
          _playbackSpeedMeta,
        ),
      );
    }
    if (data.containsKey('chapters_reversed')) {
      context.handle(
        _chaptersReversedMeta,
        chaptersReversed.isAcceptableOrUnknown(
          data['chapters_reversed']!,
          _chaptersReversedMeta,
        ),
      );
    }
    if (data.containsKey('continue_hidden_at')) {
      context.handle(
        _continueHiddenAtMeta,
        continueHiddenAt.isAcceptableOrUnknown(
          data['continue_hidden_at']!,
          _continueHiddenAtMeta,
        ),
      );
    }
    if (data.containsKey('file_path')) {
      context.handle(
        _filePathMeta,
        filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {sourceId, key},
  ];
  @override
  BookRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BookRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}source_id'],
      )!,
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      subtitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subtitle'],
      ),
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      coverUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cover_url'],
      ),
      coverLocalPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cover_local_path'],
      ),
      coverUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cover_updated_at'],
      ),
      seriesName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}series_name'],
      ),
      seriesIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}series_index'],
      ),
      genres: $BooksTable.$convertergenres.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}genres'],
        )!,
      ),
      language: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}language'],
      ),
      publisher: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}publisher'],
      ),
      publishedDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}published_date'],
      ),
      isbn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}isbn'],
      ),
      abridged: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}abridged'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      ),
      contentRating: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content_rating'],
      ),
      totalDurationMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_duration_ms'],
      ),
      webUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}web_url'],
      ),
      inLibrary: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}in_library'],
      )!,
      dateAdded: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date_added'],
      ),
      lastRefreshedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_refreshed_at'],
      ),
      detailsFetched: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}details_fetched'],
      )!,
      userOverrides: $BooksTable.$converteruserOverrides.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}user_overrides'],
        )!,
      ),
      playbackSpeed: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}playback_speed'],
      ),
      chaptersReversed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}chapters_reversed'],
      ),
      continueHiddenAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}continue_hidden_at'],
      ),
      filePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_path'],
      ),
      kind: $BooksTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}kind'],
        )!,
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $BooksTable createAlias(String alias) {
    return $BooksTable(attachedDatabase, alias);
  }

  static TypeConverter<List<String>, String> $convertergenres =
      const StringListConverter();
  static TypeConverter<Set<BookField>, String> $converteruserOverrides =
      const BookFieldSetConverter();
  static JsonTypeConverter2<SourceKind, String, String> $converterkind =
      const EnumNameConverter<SourceKind>(SourceKind.values);
}

class BookRow extends DataClass implements Insertable<BookRow> {
  /// Surrogate key, used only for joins. §4.4: a book's identity is its source and key.
  final int id;
  final int sourceId;
  final String key;
  final String title;
  final String? subtitle;
  final String? description;
  final String? coverUrl;
  final String? coverLocalPath;
  final DateTime? coverUpdatedAt;
  final String? seriesName;
  final double? seriesIndex;
  final List<String> genres;
  final String? language;
  final String? publisher;
  final String? publishedDate;
  final String? isbn;
  final bool? abridged;
  final String? status;
  final String? contentRating;
  final int? totalDurationMs;
  final String? webUrl;
  final bool inLibrary;
  final DateTime? dateAdded;
  final DateTime? lastRefreshedAt;
  final bool detailsFetched;
  final Set<BookField> userOverrides;

  /// §4.3: playback speed is remembered per book.
  final double? playbackSpeed;

  /// Whether this book's chapter list is shown last chapter first (version 9).
  ///
  /// Per book, because it is a fact about the book rather than a preference about the app: a
  /// four-hundred-chapter serial is easiest to use from the newest end, and a novel is not.
  ///
  /// Nullable, so that "never chosen" can be told from "chosen to read in order". That is what lets
  /// a restore carry a choice over without overwriting one made since, the way a remembered playback
  /// speed does.
  final bool? chaptersReversed;

  /// When the listener took this book off Continue Listening or Continue Reading by hand
  /// (version 10).
  ///
  /// A moment rather than a flag, because taking a book off the shelf is about the book as it stood
  /// then: once it is played or read again, its activity is newer than this and it comes back on its
  /// own. A flag would need something to clear it, and forgetting to would hide a book someone is
  /// in the middle of for good.
  ///
  /// Not carried by backups. It is a tidy-up of one screen, not part of anyone's library, and a
  /// restore that brought back a book taken off the shelf would cost one long-press to undo.
  final DateTime? continueHiddenAt;

  /// Where the book's own file is, for a book that is one file rather than chapters to fetch
  /// (version 8, ADR-0021).
  ///
  /// A name within the book-files folder for a book downloaded from a source, and an absolute path,
  /// or one relative to the media root, for a book added from this device. Null for every other
  /// book: an audiobook is made of media files, and a text source that serves chapters has no file
  /// at all.
  final String? filePath;

  /// A book to listen to or a book to read (version 5, ADR-0019).
  ///
  /// On the book and not taken from its source, because the Local source offers both: a folder of
  /// audio files and an EPUB are both books from this device. Every book that existed before
  /// version 5 is audio, which is what the default says, so the migration writes nothing.
  final SourceKind kind;
  final DateTime createdAt;
  final DateTime updatedAt;
  const BookRow({
    required this.id,
    required this.sourceId,
    required this.key,
    required this.title,
    this.subtitle,
    this.description,
    this.coverUrl,
    this.coverLocalPath,
    this.coverUpdatedAt,
    this.seriesName,
    this.seriesIndex,
    required this.genres,
    this.language,
    this.publisher,
    this.publishedDate,
    this.isbn,
    this.abridged,
    this.status,
    this.contentRating,
    this.totalDurationMs,
    this.webUrl,
    required this.inLibrary,
    this.dateAdded,
    this.lastRefreshedAt,
    required this.detailsFetched,
    required this.userOverrides,
    this.playbackSpeed,
    this.chaptersReversed,
    this.continueHiddenAt,
    this.filePath,
    required this.kind,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['source_id'] = Variable<int>(sourceId);
    map['key'] = Variable<String>(key);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || subtitle != null) {
      map['subtitle'] = Variable<String>(subtitle);
    }
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || coverUrl != null) {
      map['cover_url'] = Variable<String>(coverUrl);
    }
    if (!nullToAbsent || coverLocalPath != null) {
      map['cover_local_path'] = Variable<String>(coverLocalPath);
    }
    if (!nullToAbsent || coverUpdatedAt != null) {
      map['cover_updated_at'] = Variable<DateTime>(coverUpdatedAt);
    }
    if (!nullToAbsent || seriesName != null) {
      map['series_name'] = Variable<String>(seriesName);
    }
    if (!nullToAbsent || seriesIndex != null) {
      map['series_index'] = Variable<double>(seriesIndex);
    }
    {
      map['genres'] = Variable<String>(
        $BooksTable.$convertergenres.toSql(genres),
      );
    }
    if (!nullToAbsent || language != null) {
      map['language'] = Variable<String>(language);
    }
    if (!nullToAbsent || publisher != null) {
      map['publisher'] = Variable<String>(publisher);
    }
    if (!nullToAbsent || publishedDate != null) {
      map['published_date'] = Variable<String>(publishedDate);
    }
    if (!nullToAbsent || isbn != null) {
      map['isbn'] = Variable<String>(isbn);
    }
    if (!nullToAbsent || abridged != null) {
      map['abridged'] = Variable<bool>(abridged);
    }
    if (!nullToAbsent || status != null) {
      map['status'] = Variable<String>(status);
    }
    if (!nullToAbsent || contentRating != null) {
      map['content_rating'] = Variable<String>(contentRating);
    }
    if (!nullToAbsent || totalDurationMs != null) {
      map['total_duration_ms'] = Variable<int>(totalDurationMs);
    }
    if (!nullToAbsent || webUrl != null) {
      map['web_url'] = Variable<String>(webUrl);
    }
    map['in_library'] = Variable<bool>(inLibrary);
    if (!nullToAbsent || dateAdded != null) {
      map['date_added'] = Variable<DateTime>(dateAdded);
    }
    if (!nullToAbsent || lastRefreshedAt != null) {
      map['last_refreshed_at'] = Variable<DateTime>(lastRefreshedAt);
    }
    map['details_fetched'] = Variable<bool>(detailsFetched);
    {
      map['user_overrides'] = Variable<String>(
        $BooksTable.$converteruserOverrides.toSql(userOverrides),
      );
    }
    if (!nullToAbsent || playbackSpeed != null) {
      map['playback_speed'] = Variable<double>(playbackSpeed);
    }
    if (!nullToAbsent || chaptersReversed != null) {
      map['chapters_reversed'] = Variable<bool>(chaptersReversed);
    }
    if (!nullToAbsent || continueHiddenAt != null) {
      map['continue_hidden_at'] = Variable<DateTime>(continueHiddenAt);
    }
    if (!nullToAbsent || filePath != null) {
      map['file_path'] = Variable<String>(filePath);
    }
    {
      map['kind'] = Variable<String>($BooksTable.$converterkind.toSql(kind));
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  BooksCompanion toCompanion(bool nullToAbsent) {
    return BooksCompanion(
      id: Value(id),
      sourceId: Value(sourceId),
      key: Value(key),
      title: Value(title),
      subtitle: subtitle == null && nullToAbsent
          ? const Value.absent()
          : Value(subtitle),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      coverUrl: coverUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(coverUrl),
      coverLocalPath: coverLocalPath == null && nullToAbsent
          ? const Value.absent()
          : Value(coverLocalPath),
      coverUpdatedAt: coverUpdatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(coverUpdatedAt),
      seriesName: seriesName == null && nullToAbsent
          ? const Value.absent()
          : Value(seriesName),
      seriesIndex: seriesIndex == null && nullToAbsent
          ? const Value.absent()
          : Value(seriesIndex),
      genres: Value(genres),
      language: language == null && nullToAbsent
          ? const Value.absent()
          : Value(language),
      publisher: publisher == null && nullToAbsent
          ? const Value.absent()
          : Value(publisher),
      publishedDate: publishedDate == null && nullToAbsent
          ? const Value.absent()
          : Value(publishedDate),
      isbn: isbn == null && nullToAbsent ? const Value.absent() : Value(isbn),
      abridged: abridged == null && nullToAbsent
          ? const Value.absent()
          : Value(abridged),
      status: status == null && nullToAbsent
          ? const Value.absent()
          : Value(status),
      contentRating: contentRating == null && nullToAbsent
          ? const Value.absent()
          : Value(contentRating),
      totalDurationMs: totalDurationMs == null && nullToAbsent
          ? const Value.absent()
          : Value(totalDurationMs),
      webUrl: webUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(webUrl),
      inLibrary: Value(inLibrary),
      dateAdded: dateAdded == null && nullToAbsent
          ? const Value.absent()
          : Value(dateAdded),
      lastRefreshedAt: lastRefreshedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastRefreshedAt),
      detailsFetched: Value(detailsFetched),
      userOverrides: Value(userOverrides),
      playbackSpeed: playbackSpeed == null && nullToAbsent
          ? const Value.absent()
          : Value(playbackSpeed),
      chaptersReversed: chaptersReversed == null && nullToAbsent
          ? const Value.absent()
          : Value(chaptersReversed),
      continueHiddenAt: continueHiddenAt == null && nullToAbsent
          ? const Value.absent()
          : Value(continueHiddenAt),
      filePath: filePath == null && nullToAbsent
          ? const Value.absent()
          : Value(filePath),
      kind: Value(kind),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory BookRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BookRow(
      id: serializer.fromJson<int>(json['id']),
      sourceId: serializer.fromJson<int>(json['sourceId']),
      key: serializer.fromJson<String>(json['key']),
      title: serializer.fromJson<String>(json['title']),
      subtitle: serializer.fromJson<String?>(json['subtitle']),
      description: serializer.fromJson<String?>(json['description']),
      coverUrl: serializer.fromJson<String?>(json['coverUrl']),
      coverLocalPath: serializer.fromJson<String?>(json['coverLocalPath']),
      coverUpdatedAt: serializer.fromJson<DateTime?>(json['coverUpdatedAt']),
      seriesName: serializer.fromJson<String?>(json['seriesName']),
      seriesIndex: serializer.fromJson<double?>(json['seriesIndex']),
      genres: serializer.fromJson<List<String>>(json['genres']),
      language: serializer.fromJson<String?>(json['language']),
      publisher: serializer.fromJson<String?>(json['publisher']),
      publishedDate: serializer.fromJson<String?>(json['publishedDate']),
      isbn: serializer.fromJson<String?>(json['isbn']),
      abridged: serializer.fromJson<bool?>(json['abridged']),
      status: serializer.fromJson<String?>(json['status']),
      contentRating: serializer.fromJson<String?>(json['contentRating']),
      totalDurationMs: serializer.fromJson<int?>(json['totalDurationMs']),
      webUrl: serializer.fromJson<String?>(json['webUrl']),
      inLibrary: serializer.fromJson<bool>(json['inLibrary']),
      dateAdded: serializer.fromJson<DateTime?>(json['dateAdded']),
      lastRefreshedAt: serializer.fromJson<DateTime?>(json['lastRefreshedAt']),
      detailsFetched: serializer.fromJson<bool>(json['detailsFetched']),
      userOverrides: serializer.fromJson<Set<BookField>>(json['userOverrides']),
      playbackSpeed: serializer.fromJson<double?>(json['playbackSpeed']),
      chaptersReversed: serializer.fromJson<bool?>(json['chaptersReversed']),
      continueHiddenAt: serializer.fromJson<DateTime?>(
        json['continueHiddenAt'],
      ),
      filePath: serializer.fromJson<String?>(json['filePath']),
      kind: $BooksTable.$converterkind.fromJson(
        serializer.fromJson<String>(json['kind']),
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sourceId': serializer.toJson<int>(sourceId),
      'key': serializer.toJson<String>(key),
      'title': serializer.toJson<String>(title),
      'subtitle': serializer.toJson<String?>(subtitle),
      'description': serializer.toJson<String?>(description),
      'coverUrl': serializer.toJson<String?>(coverUrl),
      'coverLocalPath': serializer.toJson<String?>(coverLocalPath),
      'coverUpdatedAt': serializer.toJson<DateTime?>(coverUpdatedAt),
      'seriesName': serializer.toJson<String?>(seriesName),
      'seriesIndex': serializer.toJson<double?>(seriesIndex),
      'genres': serializer.toJson<List<String>>(genres),
      'language': serializer.toJson<String?>(language),
      'publisher': serializer.toJson<String?>(publisher),
      'publishedDate': serializer.toJson<String?>(publishedDate),
      'isbn': serializer.toJson<String?>(isbn),
      'abridged': serializer.toJson<bool?>(abridged),
      'status': serializer.toJson<String?>(status),
      'contentRating': serializer.toJson<String?>(contentRating),
      'totalDurationMs': serializer.toJson<int?>(totalDurationMs),
      'webUrl': serializer.toJson<String?>(webUrl),
      'inLibrary': serializer.toJson<bool>(inLibrary),
      'dateAdded': serializer.toJson<DateTime?>(dateAdded),
      'lastRefreshedAt': serializer.toJson<DateTime?>(lastRefreshedAt),
      'detailsFetched': serializer.toJson<bool>(detailsFetched),
      'userOverrides': serializer.toJson<Set<BookField>>(userOverrides),
      'playbackSpeed': serializer.toJson<double?>(playbackSpeed),
      'chaptersReversed': serializer.toJson<bool?>(chaptersReversed),
      'continueHiddenAt': serializer.toJson<DateTime?>(continueHiddenAt),
      'filePath': serializer.toJson<String?>(filePath),
      'kind': serializer.toJson<String>(
        $BooksTable.$converterkind.toJson(kind),
      ),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  BookRow copyWith({
    int? id,
    int? sourceId,
    String? key,
    String? title,
    Value<String?> subtitle = const Value.absent(),
    Value<String?> description = const Value.absent(),
    Value<String?> coverUrl = const Value.absent(),
    Value<String?> coverLocalPath = const Value.absent(),
    Value<DateTime?> coverUpdatedAt = const Value.absent(),
    Value<String?> seriesName = const Value.absent(),
    Value<double?> seriesIndex = const Value.absent(),
    List<String>? genres,
    Value<String?> language = const Value.absent(),
    Value<String?> publisher = const Value.absent(),
    Value<String?> publishedDate = const Value.absent(),
    Value<String?> isbn = const Value.absent(),
    Value<bool?> abridged = const Value.absent(),
    Value<String?> status = const Value.absent(),
    Value<String?> contentRating = const Value.absent(),
    Value<int?> totalDurationMs = const Value.absent(),
    Value<String?> webUrl = const Value.absent(),
    bool? inLibrary,
    Value<DateTime?> dateAdded = const Value.absent(),
    Value<DateTime?> lastRefreshedAt = const Value.absent(),
    bool? detailsFetched,
    Set<BookField>? userOverrides,
    Value<double?> playbackSpeed = const Value.absent(),
    Value<bool?> chaptersReversed = const Value.absent(),
    Value<DateTime?> continueHiddenAt = const Value.absent(),
    Value<String?> filePath = const Value.absent(),
    SourceKind? kind,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => BookRow(
    id: id ?? this.id,
    sourceId: sourceId ?? this.sourceId,
    key: key ?? this.key,
    title: title ?? this.title,
    subtitle: subtitle.present ? subtitle.value : this.subtitle,
    description: description.present ? description.value : this.description,
    coverUrl: coverUrl.present ? coverUrl.value : this.coverUrl,
    coverLocalPath: coverLocalPath.present
        ? coverLocalPath.value
        : this.coverLocalPath,
    coverUpdatedAt: coverUpdatedAt.present
        ? coverUpdatedAt.value
        : this.coverUpdatedAt,
    seriesName: seriesName.present ? seriesName.value : this.seriesName,
    seriesIndex: seriesIndex.present ? seriesIndex.value : this.seriesIndex,
    genres: genres ?? this.genres,
    language: language.present ? language.value : this.language,
    publisher: publisher.present ? publisher.value : this.publisher,
    publishedDate: publishedDate.present
        ? publishedDate.value
        : this.publishedDate,
    isbn: isbn.present ? isbn.value : this.isbn,
    abridged: abridged.present ? abridged.value : this.abridged,
    status: status.present ? status.value : this.status,
    contentRating: contentRating.present
        ? contentRating.value
        : this.contentRating,
    totalDurationMs: totalDurationMs.present
        ? totalDurationMs.value
        : this.totalDurationMs,
    webUrl: webUrl.present ? webUrl.value : this.webUrl,
    inLibrary: inLibrary ?? this.inLibrary,
    dateAdded: dateAdded.present ? dateAdded.value : this.dateAdded,
    lastRefreshedAt: lastRefreshedAt.present
        ? lastRefreshedAt.value
        : this.lastRefreshedAt,
    detailsFetched: detailsFetched ?? this.detailsFetched,
    userOverrides: userOverrides ?? this.userOverrides,
    playbackSpeed: playbackSpeed.present
        ? playbackSpeed.value
        : this.playbackSpeed,
    chaptersReversed: chaptersReversed.present
        ? chaptersReversed.value
        : this.chaptersReversed,
    continueHiddenAt: continueHiddenAt.present
        ? continueHiddenAt.value
        : this.continueHiddenAt,
    filePath: filePath.present ? filePath.value : this.filePath,
    kind: kind ?? this.kind,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  BookRow copyWithCompanion(BooksCompanion data) {
    return BookRow(
      id: data.id.present ? data.id.value : this.id,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      key: data.key.present ? data.key.value : this.key,
      title: data.title.present ? data.title.value : this.title,
      subtitle: data.subtitle.present ? data.subtitle.value : this.subtitle,
      description: data.description.present
          ? data.description.value
          : this.description,
      coverUrl: data.coverUrl.present ? data.coverUrl.value : this.coverUrl,
      coverLocalPath: data.coverLocalPath.present
          ? data.coverLocalPath.value
          : this.coverLocalPath,
      coverUpdatedAt: data.coverUpdatedAt.present
          ? data.coverUpdatedAt.value
          : this.coverUpdatedAt,
      seriesName: data.seriesName.present
          ? data.seriesName.value
          : this.seriesName,
      seriesIndex: data.seriesIndex.present
          ? data.seriesIndex.value
          : this.seriesIndex,
      genres: data.genres.present ? data.genres.value : this.genres,
      language: data.language.present ? data.language.value : this.language,
      publisher: data.publisher.present ? data.publisher.value : this.publisher,
      publishedDate: data.publishedDate.present
          ? data.publishedDate.value
          : this.publishedDate,
      isbn: data.isbn.present ? data.isbn.value : this.isbn,
      abridged: data.abridged.present ? data.abridged.value : this.abridged,
      status: data.status.present ? data.status.value : this.status,
      contentRating: data.contentRating.present
          ? data.contentRating.value
          : this.contentRating,
      totalDurationMs: data.totalDurationMs.present
          ? data.totalDurationMs.value
          : this.totalDurationMs,
      webUrl: data.webUrl.present ? data.webUrl.value : this.webUrl,
      inLibrary: data.inLibrary.present ? data.inLibrary.value : this.inLibrary,
      dateAdded: data.dateAdded.present ? data.dateAdded.value : this.dateAdded,
      lastRefreshedAt: data.lastRefreshedAt.present
          ? data.lastRefreshedAt.value
          : this.lastRefreshedAt,
      detailsFetched: data.detailsFetched.present
          ? data.detailsFetched.value
          : this.detailsFetched,
      userOverrides: data.userOverrides.present
          ? data.userOverrides.value
          : this.userOverrides,
      playbackSpeed: data.playbackSpeed.present
          ? data.playbackSpeed.value
          : this.playbackSpeed,
      chaptersReversed: data.chaptersReversed.present
          ? data.chaptersReversed.value
          : this.chaptersReversed,
      continueHiddenAt: data.continueHiddenAt.present
          ? data.continueHiddenAt.value
          : this.continueHiddenAt,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      kind: data.kind.present ? data.kind.value : this.kind,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BookRow(')
          ..write('id: $id, ')
          ..write('sourceId: $sourceId, ')
          ..write('key: $key, ')
          ..write('title: $title, ')
          ..write('subtitle: $subtitle, ')
          ..write('description: $description, ')
          ..write('coverUrl: $coverUrl, ')
          ..write('coverLocalPath: $coverLocalPath, ')
          ..write('coverUpdatedAt: $coverUpdatedAt, ')
          ..write('seriesName: $seriesName, ')
          ..write('seriesIndex: $seriesIndex, ')
          ..write('genres: $genres, ')
          ..write('language: $language, ')
          ..write('publisher: $publisher, ')
          ..write('publishedDate: $publishedDate, ')
          ..write('isbn: $isbn, ')
          ..write('abridged: $abridged, ')
          ..write('status: $status, ')
          ..write('contentRating: $contentRating, ')
          ..write('totalDurationMs: $totalDurationMs, ')
          ..write('webUrl: $webUrl, ')
          ..write('inLibrary: $inLibrary, ')
          ..write('dateAdded: $dateAdded, ')
          ..write('lastRefreshedAt: $lastRefreshedAt, ')
          ..write('detailsFetched: $detailsFetched, ')
          ..write('userOverrides: $userOverrides, ')
          ..write('playbackSpeed: $playbackSpeed, ')
          ..write('chaptersReversed: $chaptersReversed, ')
          ..write('continueHiddenAt: $continueHiddenAt, ')
          ..write('filePath: $filePath, ')
          ..write('kind: $kind, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    sourceId,
    key,
    title,
    subtitle,
    description,
    coverUrl,
    coverLocalPath,
    coverUpdatedAt,
    seriesName,
    seriesIndex,
    genres,
    language,
    publisher,
    publishedDate,
    isbn,
    abridged,
    status,
    contentRating,
    totalDurationMs,
    webUrl,
    inLibrary,
    dateAdded,
    lastRefreshedAt,
    detailsFetched,
    userOverrides,
    playbackSpeed,
    chaptersReversed,
    continueHiddenAt,
    filePath,
    kind,
    createdAt,
    updatedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BookRow &&
          other.id == this.id &&
          other.sourceId == this.sourceId &&
          other.key == this.key &&
          other.title == this.title &&
          other.subtitle == this.subtitle &&
          other.description == this.description &&
          other.coverUrl == this.coverUrl &&
          other.coverLocalPath == this.coverLocalPath &&
          other.coverUpdatedAt == this.coverUpdatedAt &&
          other.seriesName == this.seriesName &&
          other.seriesIndex == this.seriesIndex &&
          other.genres == this.genres &&
          other.language == this.language &&
          other.publisher == this.publisher &&
          other.publishedDate == this.publishedDate &&
          other.isbn == this.isbn &&
          other.abridged == this.abridged &&
          other.status == this.status &&
          other.contentRating == this.contentRating &&
          other.totalDurationMs == this.totalDurationMs &&
          other.webUrl == this.webUrl &&
          other.inLibrary == this.inLibrary &&
          other.dateAdded == this.dateAdded &&
          other.lastRefreshedAt == this.lastRefreshedAt &&
          other.detailsFetched == this.detailsFetched &&
          other.userOverrides == this.userOverrides &&
          other.playbackSpeed == this.playbackSpeed &&
          other.chaptersReversed == this.chaptersReversed &&
          other.continueHiddenAt == this.continueHiddenAt &&
          other.filePath == this.filePath &&
          other.kind == this.kind &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class BooksCompanion extends UpdateCompanion<BookRow> {
  final Value<int> id;
  final Value<int> sourceId;
  final Value<String> key;
  final Value<String> title;
  final Value<String?> subtitle;
  final Value<String?> description;
  final Value<String?> coverUrl;
  final Value<String?> coverLocalPath;
  final Value<DateTime?> coverUpdatedAt;
  final Value<String?> seriesName;
  final Value<double?> seriesIndex;
  final Value<List<String>> genres;
  final Value<String?> language;
  final Value<String?> publisher;
  final Value<String?> publishedDate;
  final Value<String?> isbn;
  final Value<bool?> abridged;
  final Value<String?> status;
  final Value<String?> contentRating;
  final Value<int?> totalDurationMs;
  final Value<String?> webUrl;
  final Value<bool> inLibrary;
  final Value<DateTime?> dateAdded;
  final Value<DateTime?> lastRefreshedAt;
  final Value<bool> detailsFetched;
  final Value<Set<BookField>> userOverrides;
  final Value<double?> playbackSpeed;
  final Value<bool?> chaptersReversed;
  final Value<DateTime?> continueHiddenAt;
  final Value<String?> filePath;
  final Value<SourceKind> kind;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const BooksCompanion({
    this.id = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.key = const Value.absent(),
    this.title = const Value.absent(),
    this.subtitle = const Value.absent(),
    this.description = const Value.absent(),
    this.coverUrl = const Value.absent(),
    this.coverLocalPath = const Value.absent(),
    this.coverUpdatedAt = const Value.absent(),
    this.seriesName = const Value.absent(),
    this.seriesIndex = const Value.absent(),
    this.genres = const Value.absent(),
    this.language = const Value.absent(),
    this.publisher = const Value.absent(),
    this.publishedDate = const Value.absent(),
    this.isbn = const Value.absent(),
    this.abridged = const Value.absent(),
    this.status = const Value.absent(),
    this.contentRating = const Value.absent(),
    this.totalDurationMs = const Value.absent(),
    this.webUrl = const Value.absent(),
    this.inLibrary = const Value.absent(),
    this.dateAdded = const Value.absent(),
    this.lastRefreshedAt = const Value.absent(),
    this.detailsFetched = const Value.absent(),
    this.userOverrides = const Value.absent(),
    this.playbackSpeed = const Value.absent(),
    this.chaptersReversed = const Value.absent(),
    this.continueHiddenAt = const Value.absent(),
    this.filePath = const Value.absent(),
    this.kind = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  BooksCompanion.insert({
    this.id = const Value.absent(),
    required int sourceId,
    required String key,
    required String title,
    this.subtitle = const Value.absent(),
    this.description = const Value.absent(),
    this.coverUrl = const Value.absent(),
    this.coverLocalPath = const Value.absent(),
    this.coverUpdatedAt = const Value.absent(),
    this.seriesName = const Value.absent(),
    this.seriesIndex = const Value.absent(),
    this.genres = const Value.absent(),
    this.language = const Value.absent(),
    this.publisher = const Value.absent(),
    this.publishedDate = const Value.absent(),
    this.isbn = const Value.absent(),
    this.abridged = const Value.absent(),
    this.status = const Value.absent(),
    this.contentRating = const Value.absent(),
    this.totalDurationMs = const Value.absent(),
    this.webUrl = const Value.absent(),
    this.inLibrary = const Value.absent(),
    this.dateAdded = const Value.absent(),
    this.lastRefreshedAt = const Value.absent(),
    this.detailsFetched = const Value.absent(),
    this.userOverrides = const Value.absent(),
    this.playbackSpeed = const Value.absent(),
    this.chaptersReversed = const Value.absent(),
    this.continueHiddenAt = const Value.absent(),
    this.filePath = const Value.absent(),
    this.kind = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : sourceId = Value(sourceId),
       key = Value(key),
       title = Value(title),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<BookRow> custom({
    Expression<int>? id,
    Expression<int>? sourceId,
    Expression<String>? key,
    Expression<String>? title,
    Expression<String>? subtitle,
    Expression<String>? description,
    Expression<String>? coverUrl,
    Expression<String>? coverLocalPath,
    Expression<DateTime>? coverUpdatedAt,
    Expression<String>? seriesName,
    Expression<double>? seriesIndex,
    Expression<String>? genres,
    Expression<String>? language,
    Expression<String>? publisher,
    Expression<String>? publishedDate,
    Expression<String>? isbn,
    Expression<bool>? abridged,
    Expression<String>? status,
    Expression<String>? contentRating,
    Expression<int>? totalDurationMs,
    Expression<String>? webUrl,
    Expression<bool>? inLibrary,
    Expression<DateTime>? dateAdded,
    Expression<DateTime>? lastRefreshedAt,
    Expression<bool>? detailsFetched,
    Expression<String>? userOverrides,
    Expression<double>? playbackSpeed,
    Expression<bool>? chaptersReversed,
    Expression<DateTime>? continueHiddenAt,
    Expression<String>? filePath,
    Expression<String>? kind,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sourceId != null) 'source_id': sourceId,
      if (key != null) 'key': key,
      if (title != null) 'title': title,
      if (subtitle != null) 'subtitle': subtitle,
      if (description != null) 'description': description,
      if (coverUrl != null) 'cover_url': coverUrl,
      if (coverLocalPath != null) 'cover_local_path': coverLocalPath,
      if (coverUpdatedAt != null) 'cover_updated_at': coverUpdatedAt,
      if (seriesName != null) 'series_name': seriesName,
      if (seriesIndex != null) 'series_index': seriesIndex,
      if (genres != null) 'genres': genres,
      if (language != null) 'language': language,
      if (publisher != null) 'publisher': publisher,
      if (publishedDate != null) 'published_date': publishedDate,
      if (isbn != null) 'isbn': isbn,
      if (abridged != null) 'abridged': abridged,
      if (status != null) 'status': status,
      if (contentRating != null) 'content_rating': contentRating,
      if (totalDurationMs != null) 'total_duration_ms': totalDurationMs,
      if (webUrl != null) 'web_url': webUrl,
      if (inLibrary != null) 'in_library': inLibrary,
      if (dateAdded != null) 'date_added': dateAdded,
      if (lastRefreshedAt != null) 'last_refreshed_at': lastRefreshedAt,
      if (detailsFetched != null) 'details_fetched': detailsFetched,
      if (userOverrides != null) 'user_overrides': userOverrides,
      if (playbackSpeed != null) 'playback_speed': playbackSpeed,
      if (chaptersReversed != null) 'chapters_reversed': chaptersReversed,
      if (continueHiddenAt != null) 'continue_hidden_at': continueHiddenAt,
      if (filePath != null) 'file_path': filePath,
      if (kind != null) 'kind': kind,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  BooksCompanion copyWith({
    Value<int>? id,
    Value<int>? sourceId,
    Value<String>? key,
    Value<String>? title,
    Value<String?>? subtitle,
    Value<String?>? description,
    Value<String?>? coverUrl,
    Value<String?>? coverLocalPath,
    Value<DateTime?>? coverUpdatedAt,
    Value<String?>? seriesName,
    Value<double?>? seriesIndex,
    Value<List<String>>? genres,
    Value<String?>? language,
    Value<String?>? publisher,
    Value<String?>? publishedDate,
    Value<String?>? isbn,
    Value<bool?>? abridged,
    Value<String?>? status,
    Value<String?>? contentRating,
    Value<int?>? totalDurationMs,
    Value<String?>? webUrl,
    Value<bool>? inLibrary,
    Value<DateTime?>? dateAdded,
    Value<DateTime?>? lastRefreshedAt,
    Value<bool>? detailsFetched,
    Value<Set<BookField>>? userOverrides,
    Value<double?>? playbackSpeed,
    Value<bool?>? chaptersReversed,
    Value<DateTime?>? continueHiddenAt,
    Value<String?>? filePath,
    Value<SourceKind>? kind,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return BooksCompanion(
      id: id ?? this.id,
      sourceId: sourceId ?? this.sourceId,
      key: key ?? this.key,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      description: description ?? this.description,
      coverUrl: coverUrl ?? this.coverUrl,
      coverLocalPath: coverLocalPath ?? this.coverLocalPath,
      coverUpdatedAt: coverUpdatedAt ?? this.coverUpdatedAt,
      seriesName: seriesName ?? this.seriesName,
      seriesIndex: seriesIndex ?? this.seriesIndex,
      genres: genres ?? this.genres,
      language: language ?? this.language,
      publisher: publisher ?? this.publisher,
      publishedDate: publishedDate ?? this.publishedDate,
      isbn: isbn ?? this.isbn,
      abridged: abridged ?? this.abridged,
      status: status ?? this.status,
      contentRating: contentRating ?? this.contentRating,
      totalDurationMs: totalDurationMs ?? this.totalDurationMs,
      webUrl: webUrl ?? this.webUrl,
      inLibrary: inLibrary ?? this.inLibrary,
      dateAdded: dateAdded ?? this.dateAdded,
      lastRefreshedAt: lastRefreshedAt ?? this.lastRefreshedAt,
      detailsFetched: detailsFetched ?? this.detailsFetched,
      userOverrides: userOverrides ?? this.userOverrides,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      chaptersReversed: chaptersReversed ?? this.chaptersReversed,
      continueHiddenAt: continueHiddenAt ?? this.continueHiddenAt,
      filePath: filePath ?? this.filePath,
      kind: kind ?? this.kind,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sourceId.present) {
      map['source_id'] = Variable<int>(sourceId.value);
    }
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (subtitle.present) {
      map['subtitle'] = Variable<String>(subtitle.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (coverUrl.present) {
      map['cover_url'] = Variable<String>(coverUrl.value);
    }
    if (coverLocalPath.present) {
      map['cover_local_path'] = Variable<String>(coverLocalPath.value);
    }
    if (coverUpdatedAt.present) {
      map['cover_updated_at'] = Variable<DateTime>(coverUpdatedAt.value);
    }
    if (seriesName.present) {
      map['series_name'] = Variable<String>(seriesName.value);
    }
    if (seriesIndex.present) {
      map['series_index'] = Variable<double>(seriesIndex.value);
    }
    if (genres.present) {
      map['genres'] = Variable<String>(
        $BooksTable.$convertergenres.toSql(genres.value),
      );
    }
    if (language.present) {
      map['language'] = Variable<String>(language.value);
    }
    if (publisher.present) {
      map['publisher'] = Variable<String>(publisher.value);
    }
    if (publishedDate.present) {
      map['published_date'] = Variable<String>(publishedDate.value);
    }
    if (isbn.present) {
      map['isbn'] = Variable<String>(isbn.value);
    }
    if (abridged.present) {
      map['abridged'] = Variable<bool>(abridged.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (contentRating.present) {
      map['content_rating'] = Variable<String>(contentRating.value);
    }
    if (totalDurationMs.present) {
      map['total_duration_ms'] = Variable<int>(totalDurationMs.value);
    }
    if (webUrl.present) {
      map['web_url'] = Variable<String>(webUrl.value);
    }
    if (inLibrary.present) {
      map['in_library'] = Variable<bool>(inLibrary.value);
    }
    if (dateAdded.present) {
      map['date_added'] = Variable<DateTime>(dateAdded.value);
    }
    if (lastRefreshedAt.present) {
      map['last_refreshed_at'] = Variable<DateTime>(lastRefreshedAt.value);
    }
    if (detailsFetched.present) {
      map['details_fetched'] = Variable<bool>(detailsFetched.value);
    }
    if (userOverrides.present) {
      map['user_overrides'] = Variable<String>(
        $BooksTable.$converteruserOverrides.toSql(userOverrides.value),
      );
    }
    if (playbackSpeed.present) {
      map['playback_speed'] = Variable<double>(playbackSpeed.value);
    }
    if (chaptersReversed.present) {
      map['chapters_reversed'] = Variable<bool>(chaptersReversed.value);
    }
    if (continueHiddenAt.present) {
      map['continue_hidden_at'] = Variable<DateTime>(continueHiddenAt.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(
        $BooksTable.$converterkind.toSql(kind.value),
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BooksCompanion(')
          ..write('id: $id, ')
          ..write('sourceId: $sourceId, ')
          ..write('key: $key, ')
          ..write('title: $title, ')
          ..write('subtitle: $subtitle, ')
          ..write('description: $description, ')
          ..write('coverUrl: $coverUrl, ')
          ..write('coverLocalPath: $coverLocalPath, ')
          ..write('coverUpdatedAt: $coverUpdatedAt, ')
          ..write('seriesName: $seriesName, ')
          ..write('seriesIndex: $seriesIndex, ')
          ..write('genres: $genres, ')
          ..write('language: $language, ')
          ..write('publisher: $publisher, ')
          ..write('publishedDate: $publishedDate, ')
          ..write('isbn: $isbn, ')
          ..write('abridged: $abridged, ')
          ..write('status: $status, ')
          ..write('contentRating: $contentRating, ')
          ..write('totalDurationMs: $totalDurationMs, ')
          ..write('webUrl: $webUrl, ')
          ..write('inLibrary: $inLibrary, ')
          ..write('dateAdded: $dateAdded, ')
          ..write('lastRefreshedAt: $lastRefreshedAt, ')
          ..write('detailsFetched: $detailsFetched, ')
          ..write('userOverrides: $userOverrides, ')
          ..write('playbackSpeed: $playbackSpeed, ')
          ..write('chaptersReversed: $chaptersReversed, ')
          ..write('continueHiddenAt: $continueHiddenAt, ')
          ..write('filePath: $filePath, ')
          ..write('kind: $kind, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $PeopleTable extends People with TableInfo<$PeopleTable, PersonRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PeopleTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  @override
  List<GeneratedColumn> get $columns => [id, name];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'people';
  @override
  VerificationContext validateIntegrity(
    Insertable<PersonRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PersonRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PersonRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
    );
  }

  @override
  $PeopleTable createAlias(String alias) {
    return $PeopleTable(attachedDatabase, alias);
  }
}

class PersonRow extends DataClass implements Insertable<PersonRow> {
  final int id;

  /// Unique, so the same narrator across books is one person to filter by. Two different people
  /// sharing a name will merge; that is the accepted cost of not having an identity from sources.
  final String name;
  const PersonRow({required this.id, required this.name});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    return map;
  }

  PeopleCompanion toCompanion(bool nullToAbsent) {
    return PeopleCompanion(id: Value(id), name: Value(name));
  }

  factory PersonRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PersonRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
    };
  }

  PersonRow copyWith({int? id, String? name}) =>
      PersonRow(id: id ?? this.id, name: name ?? this.name);
  PersonRow copyWithCompanion(PeopleCompanion data) {
    return PersonRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PersonRow(')
          ..write('id: $id, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PersonRow && other.id == this.id && other.name == this.name);
}

class PeopleCompanion extends UpdateCompanion<PersonRow> {
  final Value<int> id;
  final Value<String> name;
  const PeopleCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
  });
  PeopleCompanion.insert({this.id = const Value.absent(), required String name})
    : name = Value(name);
  static Insertable<PersonRow> custom({
    Expression<int>? id,
    Expression<String>? name,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
    });
  }

  PeopleCompanion copyWith({Value<int>? id, Value<String>? name}) {
    return PeopleCompanion(id: id ?? this.id, name: name ?? this.name);
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PeopleCompanion(')
          ..write('id: $id, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }
}

class $BookPeopleTable extends BookPeople
    with TableInfo<$BookPeopleTable, BookPersonRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BookPeopleTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _bookIdMeta = const VerificationMeta('bookId');
  @override
  late final GeneratedColumn<int> bookId = GeneratedColumn<int>(
    'book_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES books (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _personIdMeta = const VerificationMeta(
    'personId',
  );
  @override
  late final GeneratedColumn<int> personId = GeneratedColumn<int>(
    'person_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES people (id)',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<ContributorRole, String> role =
      GeneratedColumn<String>(
        'role',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<ContributorRole>($BookPeopleTable.$converterrole);
  static const VerificationMeta _ordinalMeta = const VerificationMeta(
    'ordinal',
  );
  @override
  late final GeneratedColumn<int> ordinal = GeneratedColumn<int>(
    'ordinal',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [bookId, personId, role, ordinal];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'book_people';
  @override
  VerificationContext validateIntegrity(
    Insertable<BookPersonRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('book_id')) {
      context.handle(
        _bookIdMeta,
        bookId.isAcceptableOrUnknown(data['book_id']!, _bookIdMeta),
      );
    } else if (isInserting) {
      context.missing(_bookIdMeta);
    }
    if (data.containsKey('person_id')) {
      context.handle(
        _personIdMeta,
        personId.isAcceptableOrUnknown(data['person_id']!, _personIdMeta),
      );
    } else if (isInserting) {
      context.missing(_personIdMeta);
    }
    if (data.containsKey('ordinal')) {
      context.handle(
        _ordinalMeta,
        ordinal.isAcceptableOrUnknown(data['ordinal']!, _ordinalMeta),
      );
    } else if (isInserting) {
      context.missing(_ordinalMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {bookId, personId, role};
  @override
  BookPersonRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BookPersonRow(
      bookId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}book_id'],
      )!,
      personId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}person_id'],
      )!,
      role: $BookPeopleTable.$converterrole.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}role'],
        )!,
      ),
      ordinal: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ordinal'],
      )!,
    );
  }

  @override
  $BookPeopleTable createAlias(String alias) {
    return $BookPeopleTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<ContributorRole, String, String> $converterrole =
      const EnumNameConverter<ContributorRole>(ContributorRole.values);
}

class BookPersonRow extends DataClass implements Insertable<BookPersonRow> {
  final int bookId;
  final int personId;
  final ContributorRole role;

  /// Credit order within the role.
  final int ordinal;
  const BookPersonRow({
    required this.bookId,
    required this.personId,
    required this.role,
    required this.ordinal,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['book_id'] = Variable<int>(bookId);
    map['person_id'] = Variable<int>(personId);
    {
      map['role'] = Variable<String>(
        $BookPeopleTable.$converterrole.toSql(role),
      );
    }
    map['ordinal'] = Variable<int>(ordinal);
    return map;
  }

  BookPeopleCompanion toCompanion(bool nullToAbsent) {
    return BookPeopleCompanion(
      bookId: Value(bookId),
      personId: Value(personId),
      role: Value(role),
      ordinal: Value(ordinal),
    );
  }

  factory BookPersonRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BookPersonRow(
      bookId: serializer.fromJson<int>(json['bookId']),
      personId: serializer.fromJson<int>(json['personId']),
      role: $BookPeopleTable.$converterrole.fromJson(
        serializer.fromJson<String>(json['role']),
      ),
      ordinal: serializer.fromJson<int>(json['ordinal']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'bookId': serializer.toJson<int>(bookId),
      'personId': serializer.toJson<int>(personId),
      'role': serializer.toJson<String>(
        $BookPeopleTable.$converterrole.toJson(role),
      ),
      'ordinal': serializer.toJson<int>(ordinal),
    };
  }

  BookPersonRow copyWith({
    int? bookId,
    int? personId,
    ContributorRole? role,
    int? ordinal,
  }) => BookPersonRow(
    bookId: bookId ?? this.bookId,
    personId: personId ?? this.personId,
    role: role ?? this.role,
    ordinal: ordinal ?? this.ordinal,
  );
  BookPersonRow copyWithCompanion(BookPeopleCompanion data) {
    return BookPersonRow(
      bookId: data.bookId.present ? data.bookId.value : this.bookId,
      personId: data.personId.present ? data.personId.value : this.personId,
      role: data.role.present ? data.role.value : this.role,
      ordinal: data.ordinal.present ? data.ordinal.value : this.ordinal,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BookPersonRow(')
          ..write('bookId: $bookId, ')
          ..write('personId: $personId, ')
          ..write('role: $role, ')
          ..write('ordinal: $ordinal')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(bookId, personId, role, ordinal);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BookPersonRow &&
          other.bookId == this.bookId &&
          other.personId == this.personId &&
          other.role == this.role &&
          other.ordinal == this.ordinal);
}

class BookPeopleCompanion extends UpdateCompanion<BookPersonRow> {
  final Value<int> bookId;
  final Value<int> personId;
  final Value<ContributorRole> role;
  final Value<int> ordinal;
  final Value<int> rowid;
  const BookPeopleCompanion({
    this.bookId = const Value.absent(),
    this.personId = const Value.absent(),
    this.role = const Value.absent(),
    this.ordinal = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BookPeopleCompanion.insert({
    required int bookId,
    required int personId,
    required ContributorRole role,
    required int ordinal,
    this.rowid = const Value.absent(),
  }) : bookId = Value(bookId),
       personId = Value(personId),
       role = Value(role),
       ordinal = Value(ordinal);
  static Insertable<BookPersonRow> custom({
    Expression<int>? bookId,
    Expression<int>? personId,
    Expression<String>? role,
    Expression<int>? ordinal,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (bookId != null) 'book_id': bookId,
      if (personId != null) 'person_id': personId,
      if (role != null) 'role': role,
      if (ordinal != null) 'ordinal': ordinal,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BookPeopleCompanion copyWith({
    Value<int>? bookId,
    Value<int>? personId,
    Value<ContributorRole>? role,
    Value<int>? ordinal,
    Value<int>? rowid,
  }) {
    return BookPeopleCompanion(
      bookId: bookId ?? this.bookId,
      personId: personId ?? this.personId,
      role: role ?? this.role,
      ordinal: ordinal ?? this.ordinal,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (bookId.present) {
      map['book_id'] = Variable<int>(bookId.value);
    }
    if (personId.present) {
      map['person_id'] = Variable<int>(personId.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(
        $BookPeopleTable.$converterrole.toSql(role.value),
      );
    }
    if (ordinal.present) {
      map['ordinal'] = Variable<int>(ordinal.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BookPeopleCompanion(')
          ..write('bookId: $bookId, ')
          ..write('personId: $personId, ')
          ..write('role: $role, ')
          ..write('ordinal: $ordinal, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ChaptersTable extends Chapters
    with TableInfo<$ChaptersTable, ChapterRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChaptersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _bookIdMeta = const VerificationMeta('bookId');
  @override
  late final GeneratedColumn<int> bookId = GeneratedColumn<int>(
    'book_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES books (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceIndexMeta = const VerificationMeta(
    'sourceIndex',
  );
  @override
  late final GeneratedColumn<int> sourceIndex = GeneratedColumn<int>(
    'source_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _groupNameMeta = const VerificationMeta(
    'groupName',
  );
  @override
  late final GeneratedColumn<String> groupName = GeneratedColumn<String>(
    'group_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationMsMeta = const VerificationMeta(
    'durationMs',
  );
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
    'duration_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _wordCountMeta = const VerificationMeta(
    'wordCount',
  );
  @override
  late final GeneratedColumn<int> wordCount = GeneratedColumn<int>(
    'word_count',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _publishedAtMeta = const VerificationMeta(
    'publishedAt',
  );
  @override
  late final GeneratedColumn<DateTime> publishedAt = GeneratedColumn<DateTime>(
    'published_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isListenedMeta = const VerificationMeta(
    'isListened',
  );
  @override
  late final GeneratedColumn<bool> isListened = GeneratedColumn<bool>(
    'is_listened',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_listened" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _listenedAtMeta = const VerificationMeta(
    'listenedAt',
  );
  @override
  late final GeneratedColumn<DateTime> listenedAt = GeneratedColumn<DateTime>(
    'listened_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastPositionMsMeta = const VerificationMeta(
    'lastPositionMs',
  );
  @override
  late final GeneratedColumn<int> lastPositionMs = GeneratedColumn<int>(
    'last_position_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _removedFromSourceMeta = const VerificationMeta(
    'removedFromSource',
  );
  @override
  late final GeneratedColumn<bool> removedFromSource = GeneratedColumn<bool>(
    'removed_from_source',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("removed_from_source" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    bookId,
    key,
    title,
    sourceIndex,
    groupName,
    durationMs,
    wordCount,
    publishedAt,
    isListened,
    listenedAt,
    lastPositionMs,
    removedFromSource,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'chapters';
  @override
  VerificationContext validateIntegrity(
    Insertable<ChapterRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('book_id')) {
      context.handle(
        _bookIdMeta,
        bookId.isAcceptableOrUnknown(data['book_id']!, _bookIdMeta),
      );
    } else if (isInserting) {
      context.missing(_bookIdMeta);
    }
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('source_index')) {
      context.handle(
        _sourceIndexMeta,
        sourceIndex.isAcceptableOrUnknown(
          data['source_index']!,
          _sourceIndexMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sourceIndexMeta);
    }
    if (data.containsKey('group_name')) {
      context.handle(
        _groupNameMeta,
        groupName.isAcceptableOrUnknown(data['group_name']!, _groupNameMeta),
      );
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
        _durationMsMeta,
        durationMs.isAcceptableOrUnknown(data['duration_ms']!, _durationMsMeta),
      );
    }
    if (data.containsKey('word_count')) {
      context.handle(
        _wordCountMeta,
        wordCount.isAcceptableOrUnknown(data['word_count']!, _wordCountMeta),
      );
    }
    if (data.containsKey('published_at')) {
      context.handle(
        _publishedAtMeta,
        publishedAt.isAcceptableOrUnknown(
          data['published_at']!,
          _publishedAtMeta,
        ),
      );
    }
    if (data.containsKey('is_listened')) {
      context.handle(
        _isListenedMeta,
        isListened.isAcceptableOrUnknown(data['is_listened']!, _isListenedMeta),
      );
    }
    if (data.containsKey('listened_at')) {
      context.handle(
        _listenedAtMeta,
        listenedAt.isAcceptableOrUnknown(data['listened_at']!, _listenedAtMeta),
      );
    }
    if (data.containsKey('last_position_ms')) {
      context.handle(
        _lastPositionMsMeta,
        lastPositionMs.isAcceptableOrUnknown(
          data['last_position_ms']!,
          _lastPositionMsMeta,
        ),
      );
    }
    if (data.containsKey('removed_from_source')) {
      context.handle(
        _removedFromSourceMeta,
        removedFromSource.isAcceptableOrUnknown(
          data['removed_from_source']!,
          _removedFromSourceMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {bookId, key},
  ];
  @override
  ChapterRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChapterRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      bookId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}book_id'],
      )!,
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      sourceIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}source_index'],
      )!,
      groupName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_name'],
      ),
      durationMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_ms'],
      ),
      wordCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}word_count'],
      ),
      publishedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}published_at'],
      ),
      isListened: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_listened'],
      )!,
      listenedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}listened_at'],
      ),
      lastPositionMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_position_ms'],
      )!,
      removedFromSource: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}removed_from_source'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ChaptersTable createAlias(String alias) {
    return $ChaptersTable(attachedDatabase, alias);
  }
}

class ChapterRow extends DataClass implements Insertable<ChapterRow> {
  final int id;
  final int bookId;
  final String key;
  final String title;
  final int sourceIndex;
  final String? groupName;
  final int? durationMs;

  /// How many words the chapter holds, for a book to read (version 6, ADR-0019).
  ///
  /// An audiobook chapter says how long it is in minutes because its length is a fact about the
  /// recording. A chapter of text has no length in minutes of its own — it has a length in words,
  /// and how long that takes is the reader's own pace. So the words are stored and the minutes are
  /// worked out for whoever is reading.
  ///
  /// Null until it is known. A local EPUB's chapters are counted as the book is added; a chapter
  /// from a source cannot be counted until its text has been fetched, so it is counted the first
  /// time it is read. Derived from the text either way, which is why a backup does not carry it.
  final int? wordCount;
  final DateTime? publishedAt;
  final bool isListened;
  final DateTime? listenedAt;

  /// Chapter-relative, per §4.5.
  final int lastPositionMs;

  /// §4.4: chapters a source stops reporting are soft-deleted, never removed outright while they
  /// carry progress, bookmarks or downloads.
  final bool removedFromSource;
  final DateTime createdAt;
  final DateTime updatedAt;
  const ChapterRow({
    required this.id,
    required this.bookId,
    required this.key,
    required this.title,
    required this.sourceIndex,
    this.groupName,
    this.durationMs,
    this.wordCount,
    this.publishedAt,
    required this.isListened,
    this.listenedAt,
    required this.lastPositionMs,
    required this.removedFromSource,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['book_id'] = Variable<int>(bookId);
    map['key'] = Variable<String>(key);
    map['title'] = Variable<String>(title);
    map['source_index'] = Variable<int>(sourceIndex);
    if (!nullToAbsent || groupName != null) {
      map['group_name'] = Variable<String>(groupName);
    }
    if (!nullToAbsent || durationMs != null) {
      map['duration_ms'] = Variable<int>(durationMs);
    }
    if (!nullToAbsent || wordCount != null) {
      map['word_count'] = Variable<int>(wordCount);
    }
    if (!nullToAbsent || publishedAt != null) {
      map['published_at'] = Variable<DateTime>(publishedAt);
    }
    map['is_listened'] = Variable<bool>(isListened);
    if (!nullToAbsent || listenedAt != null) {
      map['listened_at'] = Variable<DateTime>(listenedAt);
    }
    map['last_position_ms'] = Variable<int>(lastPositionMs);
    map['removed_from_source'] = Variable<bool>(removedFromSource);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ChaptersCompanion toCompanion(bool nullToAbsent) {
    return ChaptersCompanion(
      id: Value(id),
      bookId: Value(bookId),
      key: Value(key),
      title: Value(title),
      sourceIndex: Value(sourceIndex),
      groupName: groupName == null && nullToAbsent
          ? const Value.absent()
          : Value(groupName),
      durationMs: durationMs == null && nullToAbsent
          ? const Value.absent()
          : Value(durationMs),
      wordCount: wordCount == null && nullToAbsent
          ? const Value.absent()
          : Value(wordCount),
      publishedAt: publishedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(publishedAt),
      isListened: Value(isListened),
      listenedAt: listenedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(listenedAt),
      lastPositionMs: Value(lastPositionMs),
      removedFromSource: Value(removedFromSource),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ChapterRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChapterRow(
      id: serializer.fromJson<int>(json['id']),
      bookId: serializer.fromJson<int>(json['bookId']),
      key: serializer.fromJson<String>(json['key']),
      title: serializer.fromJson<String>(json['title']),
      sourceIndex: serializer.fromJson<int>(json['sourceIndex']),
      groupName: serializer.fromJson<String?>(json['groupName']),
      durationMs: serializer.fromJson<int?>(json['durationMs']),
      wordCount: serializer.fromJson<int?>(json['wordCount']),
      publishedAt: serializer.fromJson<DateTime?>(json['publishedAt']),
      isListened: serializer.fromJson<bool>(json['isListened']),
      listenedAt: serializer.fromJson<DateTime?>(json['listenedAt']),
      lastPositionMs: serializer.fromJson<int>(json['lastPositionMs']),
      removedFromSource: serializer.fromJson<bool>(json['removedFromSource']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'bookId': serializer.toJson<int>(bookId),
      'key': serializer.toJson<String>(key),
      'title': serializer.toJson<String>(title),
      'sourceIndex': serializer.toJson<int>(sourceIndex),
      'groupName': serializer.toJson<String?>(groupName),
      'durationMs': serializer.toJson<int?>(durationMs),
      'wordCount': serializer.toJson<int?>(wordCount),
      'publishedAt': serializer.toJson<DateTime?>(publishedAt),
      'isListened': serializer.toJson<bool>(isListened),
      'listenedAt': serializer.toJson<DateTime?>(listenedAt),
      'lastPositionMs': serializer.toJson<int>(lastPositionMs),
      'removedFromSource': serializer.toJson<bool>(removedFromSource),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ChapterRow copyWith({
    int? id,
    int? bookId,
    String? key,
    String? title,
    int? sourceIndex,
    Value<String?> groupName = const Value.absent(),
    Value<int?> durationMs = const Value.absent(),
    Value<int?> wordCount = const Value.absent(),
    Value<DateTime?> publishedAt = const Value.absent(),
    bool? isListened,
    Value<DateTime?> listenedAt = const Value.absent(),
    int? lastPositionMs,
    bool? removedFromSource,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => ChapterRow(
    id: id ?? this.id,
    bookId: bookId ?? this.bookId,
    key: key ?? this.key,
    title: title ?? this.title,
    sourceIndex: sourceIndex ?? this.sourceIndex,
    groupName: groupName.present ? groupName.value : this.groupName,
    durationMs: durationMs.present ? durationMs.value : this.durationMs,
    wordCount: wordCount.present ? wordCount.value : this.wordCount,
    publishedAt: publishedAt.present ? publishedAt.value : this.publishedAt,
    isListened: isListened ?? this.isListened,
    listenedAt: listenedAt.present ? listenedAt.value : this.listenedAt,
    lastPositionMs: lastPositionMs ?? this.lastPositionMs,
    removedFromSource: removedFromSource ?? this.removedFromSource,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ChapterRow copyWithCompanion(ChaptersCompanion data) {
    return ChapterRow(
      id: data.id.present ? data.id.value : this.id,
      bookId: data.bookId.present ? data.bookId.value : this.bookId,
      key: data.key.present ? data.key.value : this.key,
      title: data.title.present ? data.title.value : this.title,
      sourceIndex: data.sourceIndex.present
          ? data.sourceIndex.value
          : this.sourceIndex,
      groupName: data.groupName.present ? data.groupName.value : this.groupName,
      durationMs: data.durationMs.present
          ? data.durationMs.value
          : this.durationMs,
      wordCount: data.wordCount.present ? data.wordCount.value : this.wordCount,
      publishedAt: data.publishedAt.present
          ? data.publishedAt.value
          : this.publishedAt,
      isListened: data.isListened.present
          ? data.isListened.value
          : this.isListened,
      listenedAt: data.listenedAt.present
          ? data.listenedAt.value
          : this.listenedAt,
      lastPositionMs: data.lastPositionMs.present
          ? data.lastPositionMs.value
          : this.lastPositionMs,
      removedFromSource: data.removedFromSource.present
          ? data.removedFromSource.value
          : this.removedFromSource,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChapterRow(')
          ..write('id: $id, ')
          ..write('bookId: $bookId, ')
          ..write('key: $key, ')
          ..write('title: $title, ')
          ..write('sourceIndex: $sourceIndex, ')
          ..write('groupName: $groupName, ')
          ..write('durationMs: $durationMs, ')
          ..write('wordCount: $wordCount, ')
          ..write('publishedAt: $publishedAt, ')
          ..write('isListened: $isListened, ')
          ..write('listenedAt: $listenedAt, ')
          ..write('lastPositionMs: $lastPositionMs, ')
          ..write('removedFromSource: $removedFromSource, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    bookId,
    key,
    title,
    sourceIndex,
    groupName,
    durationMs,
    wordCount,
    publishedAt,
    isListened,
    listenedAt,
    lastPositionMs,
    removedFromSource,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChapterRow &&
          other.id == this.id &&
          other.bookId == this.bookId &&
          other.key == this.key &&
          other.title == this.title &&
          other.sourceIndex == this.sourceIndex &&
          other.groupName == this.groupName &&
          other.durationMs == this.durationMs &&
          other.wordCount == this.wordCount &&
          other.publishedAt == this.publishedAt &&
          other.isListened == this.isListened &&
          other.listenedAt == this.listenedAt &&
          other.lastPositionMs == this.lastPositionMs &&
          other.removedFromSource == this.removedFromSource &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ChaptersCompanion extends UpdateCompanion<ChapterRow> {
  final Value<int> id;
  final Value<int> bookId;
  final Value<String> key;
  final Value<String> title;
  final Value<int> sourceIndex;
  final Value<String?> groupName;
  final Value<int?> durationMs;
  final Value<int?> wordCount;
  final Value<DateTime?> publishedAt;
  final Value<bool> isListened;
  final Value<DateTime?> listenedAt;
  final Value<int> lastPositionMs;
  final Value<bool> removedFromSource;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const ChaptersCompanion({
    this.id = const Value.absent(),
    this.bookId = const Value.absent(),
    this.key = const Value.absent(),
    this.title = const Value.absent(),
    this.sourceIndex = const Value.absent(),
    this.groupName = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.wordCount = const Value.absent(),
    this.publishedAt = const Value.absent(),
    this.isListened = const Value.absent(),
    this.listenedAt = const Value.absent(),
    this.lastPositionMs = const Value.absent(),
    this.removedFromSource = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  ChaptersCompanion.insert({
    this.id = const Value.absent(),
    required int bookId,
    required String key,
    required String title,
    required int sourceIndex,
    this.groupName = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.wordCount = const Value.absent(),
    this.publishedAt = const Value.absent(),
    this.isListened = const Value.absent(),
    this.listenedAt = const Value.absent(),
    this.lastPositionMs = const Value.absent(),
    this.removedFromSource = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : bookId = Value(bookId),
       key = Value(key),
       title = Value(title),
       sourceIndex = Value(sourceIndex),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<ChapterRow> custom({
    Expression<int>? id,
    Expression<int>? bookId,
    Expression<String>? key,
    Expression<String>? title,
    Expression<int>? sourceIndex,
    Expression<String>? groupName,
    Expression<int>? durationMs,
    Expression<int>? wordCount,
    Expression<DateTime>? publishedAt,
    Expression<bool>? isListened,
    Expression<DateTime>? listenedAt,
    Expression<int>? lastPositionMs,
    Expression<bool>? removedFromSource,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (bookId != null) 'book_id': bookId,
      if (key != null) 'key': key,
      if (title != null) 'title': title,
      if (sourceIndex != null) 'source_index': sourceIndex,
      if (groupName != null) 'group_name': groupName,
      if (durationMs != null) 'duration_ms': durationMs,
      if (wordCount != null) 'word_count': wordCount,
      if (publishedAt != null) 'published_at': publishedAt,
      if (isListened != null) 'is_listened': isListened,
      if (listenedAt != null) 'listened_at': listenedAt,
      if (lastPositionMs != null) 'last_position_ms': lastPositionMs,
      if (removedFromSource != null) 'removed_from_source': removedFromSource,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  ChaptersCompanion copyWith({
    Value<int>? id,
    Value<int>? bookId,
    Value<String>? key,
    Value<String>? title,
    Value<int>? sourceIndex,
    Value<String?>? groupName,
    Value<int?>? durationMs,
    Value<int?>? wordCount,
    Value<DateTime?>? publishedAt,
    Value<bool>? isListened,
    Value<DateTime?>? listenedAt,
    Value<int>? lastPositionMs,
    Value<bool>? removedFromSource,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return ChaptersCompanion(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      key: key ?? this.key,
      title: title ?? this.title,
      sourceIndex: sourceIndex ?? this.sourceIndex,
      groupName: groupName ?? this.groupName,
      durationMs: durationMs ?? this.durationMs,
      wordCount: wordCount ?? this.wordCount,
      publishedAt: publishedAt ?? this.publishedAt,
      isListened: isListened ?? this.isListened,
      listenedAt: listenedAt ?? this.listenedAt,
      lastPositionMs: lastPositionMs ?? this.lastPositionMs,
      removedFromSource: removedFromSource ?? this.removedFromSource,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (bookId.present) {
      map['book_id'] = Variable<int>(bookId.value);
    }
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (sourceIndex.present) {
      map['source_index'] = Variable<int>(sourceIndex.value);
    }
    if (groupName.present) {
      map['group_name'] = Variable<String>(groupName.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (wordCount.present) {
      map['word_count'] = Variable<int>(wordCount.value);
    }
    if (publishedAt.present) {
      map['published_at'] = Variable<DateTime>(publishedAt.value);
    }
    if (isListened.present) {
      map['is_listened'] = Variable<bool>(isListened.value);
    }
    if (listenedAt.present) {
      map['listened_at'] = Variable<DateTime>(listenedAt.value);
    }
    if (lastPositionMs.present) {
      map['last_position_ms'] = Variable<int>(lastPositionMs.value);
    }
    if (removedFromSource.present) {
      map['removed_from_source'] = Variable<bool>(removedFromSource.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChaptersCompanion(')
          ..write('id: $id, ')
          ..write('bookId: $bookId, ')
          ..write('key: $key, ')
          ..write('title: $title, ')
          ..write('sourceIndex: $sourceIndex, ')
          ..write('groupName: $groupName, ')
          ..write('durationMs: $durationMs, ')
          ..write('wordCount: $wordCount, ')
          ..write('publishedAt: $publishedAt, ')
          ..write('isListened: $isListened, ')
          ..write('listenedAt: $listenedAt, ')
          ..write('lastPositionMs: $lastPositionMs, ')
          ..write('removedFromSource: $removedFromSource, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $MediaFilesTable extends MediaFiles
    with TableInfo<$MediaFilesTable, MediaFileRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MediaFilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _bookIdMeta = const VerificationMeta('bookId');
  @override
  late final GeneratedColumn<int> bookId = GeneratedColumn<int>(
    'book_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES books (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _fileKeyMeta = const VerificationMeta(
    'fileKey',
  );
  @override
  late final GeneratedColumn<String> fileKey = GeneratedColumn<String>(
    'file_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _formatMeta = const VerificationMeta('format');
  @override
  late final GeneratedColumn<String> format = GeneratedColumn<String>(
    'format',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationMsMeta = const VerificationMeta(
    'durationMs',
  );
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
    'duration_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationIsEstimateMeta =
      const VerificationMeta('durationIsEstimate');
  @override
  late final GeneratedColumn<bool> durationIsEstimate = GeneratedColumn<bool>(
    'duration_is_estimate',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("duration_is_estimate" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _sizeBytesMeta = const VerificationMeta(
    'sizeBytes',
  );
  @override
  late final GeneratedColumn<int> sizeBytes = GeneratedColumn<int>(
    'size_bytes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<List<TimelineMarker>?, String>
  embeddedMarkers =
      GeneratedColumn<String>(
        'embedded_markers',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<List<TimelineMarker>?>(
        $MediaFilesTable.$converterembeddedMarkersn,
      );
  static const VerificationMeta _localPathMeta = const VerificationMeta(
    'localPath',
  );
  @override
  late final GeneratedColumn<String> localPath = GeneratedColumn<String>(
    'local_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _downloadedAtMeta = const VerificationMeta(
    'downloadedAt',
  );
  @override
  late final GeneratedColumn<DateTime> downloadedAt = GeneratedColumn<DateTime>(
    'downloaded_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    bookId,
    fileKey,
    format,
    durationMs,
    durationIsEstimate,
    sizeBytes,
    embeddedMarkers,
    localPath,
    downloadedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'media_files';
  @override
  VerificationContext validateIntegrity(
    Insertable<MediaFileRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('book_id')) {
      context.handle(
        _bookIdMeta,
        bookId.isAcceptableOrUnknown(data['book_id']!, _bookIdMeta),
      );
    } else if (isInserting) {
      context.missing(_bookIdMeta);
    }
    if (data.containsKey('file_key')) {
      context.handle(
        _fileKeyMeta,
        fileKey.isAcceptableOrUnknown(data['file_key']!, _fileKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_fileKeyMeta);
    }
    if (data.containsKey('format')) {
      context.handle(
        _formatMeta,
        format.isAcceptableOrUnknown(data['format']!, _formatMeta),
      );
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
        _durationMsMeta,
        durationMs.isAcceptableOrUnknown(data['duration_ms']!, _durationMsMeta),
      );
    }
    if (data.containsKey('duration_is_estimate')) {
      context.handle(
        _durationIsEstimateMeta,
        durationIsEstimate.isAcceptableOrUnknown(
          data['duration_is_estimate']!,
          _durationIsEstimateMeta,
        ),
      );
    }
    if (data.containsKey('size_bytes')) {
      context.handle(
        _sizeBytesMeta,
        sizeBytes.isAcceptableOrUnknown(data['size_bytes']!, _sizeBytesMeta),
      );
    }
    if (data.containsKey('local_path')) {
      context.handle(
        _localPathMeta,
        localPath.isAcceptableOrUnknown(data['local_path']!, _localPathMeta),
      );
    }
    if (data.containsKey('downloaded_at')) {
      context.handle(
        _downloadedAtMeta,
        downloadedAt.isAcceptableOrUnknown(
          data['downloaded_at']!,
          _downloadedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {bookId, fileKey},
  ];
  @override
  MediaFileRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MediaFileRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      bookId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}book_id'],
      )!,
      fileKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_key'],
      )!,
      format: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}format'],
      ),
      durationMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_ms'],
      ),
      durationIsEstimate: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}duration_is_estimate'],
      )!,
      sizeBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}size_bytes'],
      ),
      embeddedMarkers: $MediaFilesTable.$converterembeddedMarkersn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}embedded_markers'],
        ),
      ),
      localPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_path'],
      ),
      downloadedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}downloaded_at'],
      ),
    );
  }

  @override
  $MediaFilesTable createAlias(String alias) {
    return $MediaFilesTable(attachedDatabase, alias);
  }

  static TypeConverter<List<TimelineMarker>, String> $converterembeddedMarkers =
      const MarkerListConverter();
  static TypeConverter<List<TimelineMarker>?, String?>
  $converterembeddedMarkersn = NullAwareTypeConverter.wrap(
    $converterembeddedMarkers,
  );
}

class MediaFileRow extends DataClass implements Insertable<MediaFileRow> {
  final int id;
  final int bookId;
  final String fileKey;
  final String? format;
  final int? durationMs;

  /// Not in §4.3's column list, but §4.5 requires it: durations are estimated until a file is
  /// probed, and the Timeline has to know which figures are which.
  final bool durationIsEstimate;
  final int? sizeBytes;
  final List<TimelineMarker>? embeddedMarkers;

  /// Where the file is, once it is on this device at all.
  ///
  /// Absolute for a file that stays where the user keeps it, and otherwise relative — to the app's
  /// downloads folder when [downloadedAt] is set, and to the media root when it is not. The two are
  /// different folders, so the pair of columns has to be read together; `LocalMediaResolver` is the
  /// one place that does it.
  final String? localPath;

  /// When the download queue put this file here, and nothing else ever sets it (§5.2).
  ///
  /// So it is also what says that [localPath] is relative to the downloads folder rather than to the
  /// media root. An imported file is on the device without ever having been downloaded.
  final DateTime? downloadedAt;
  const MediaFileRow({
    required this.id,
    required this.bookId,
    required this.fileKey,
    this.format,
    this.durationMs,
    required this.durationIsEstimate,
    this.sizeBytes,
    this.embeddedMarkers,
    this.localPath,
    this.downloadedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['book_id'] = Variable<int>(bookId);
    map['file_key'] = Variable<String>(fileKey);
    if (!nullToAbsent || format != null) {
      map['format'] = Variable<String>(format);
    }
    if (!nullToAbsent || durationMs != null) {
      map['duration_ms'] = Variable<int>(durationMs);
    }
    map['duration_is_estimate'] = Variable<bool>(durationIsEstimate);
    if (!nullToAbsent || sizeBytes != null) {
      map['size_bytes'] = Variable<int>(sizeBytes);
    }
    if (!nullToAbsent || embeddedMarkers != null) {
      map['embedded_markers'] = Variable<String>(
        $MediaFilesTable.$converterembeddedMarkersn.toSql(embeddedMarkers),
      );
    }
    if (!nullToAbsent || localPath != null) {
      map['local_path'] = Variable<String>(localPath);
    }
    if (!nullToAbsent || downloadedAt != null) {
      map['downloaded_at'] = Variable<DateTime>(downloadedAt);
    }
    return map;
  }

  MediaFilesCompanion toCompanion(bool nullToAbsent) {
    return MediaFilesCompanion(
      id: Value(id),
      bookId: Value(bookId),
      fileKey: Value(fileKey),
      format: format == null && nullToAbsent
          ? const Value.absent()
          : Value(format),
      durationMs: durationMs == null && nullToAbsent
          ? const Value.absent()
          : Value(durationMs),
      durationIsEstimate: Value(durationIsEstimate),
      sizeBytes: sizeBytes == null && nullToAbsent
          ? const Value.absent()
          : Value(sizeBytes),
      embeddedMarkers: embeddedMarkers == null && nullToAbsent
          ? const Value.absent()
          : Value(embeddedMarkers),
      localPath: localPath == null && nullToAbsent
          ? const Value.absent()
          : Value(localPath),
      downloadedAt: downloadedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(downloadedAt),
    );
  }

  factory MediaFileRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MediaFileRow(
      id: serializer.fromJson<int>(json['id']),
      bookId: serializer.fromJson<int>(json['bookId']),
      fileKey: serializer.fromJson<String>(json['fileKey']),
      format: serializer.fromJson<String?>(json['format']),
      durationMs: serializer.fromJson<int?>(json['durationMs']),
      durationIsEstimate: serializer.fromJson<bool>(json['durationIsEstimate']),
      sizeBytes: serializer.fromJson<int?>(json['sizeBytes']),
      embeddedMarkers: serializer.fromJson<List<TimelineMarker>?>(
        json['embeddedMarkers'],
      ),
      localPath: serializer.fromJson<String?>(json['localPath']),
      downloadedAt: serializer.fromJson<DateTime?>(json['downloadedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'bookId': serializer.toJson<int>(bookId),
      'fileKey': serializer.toJson<String>(fileKey),
      'format': serializer.toJson<String?>(format),
      'durationMs': serializer.toJson<int?>(durationMs),
      'durationIsEstimate': serializer.toJson<bool>(durationIsEstimate),
      'sizeBytes': serializer.toJson<int?>(sizeBytes),
      'embeddedMarkers': serializer.toJson<List<TimelineMarker>?>(
        embeddedMarkers,
      ),
      'localPath': serializer.toJson<String?>(localPath),
      'downloadedAt': serializer.toJson<DateTime?>(downloadedAt),
    };
  }

  MediaFileRow copyWith({
    int? id,
    int? bookId,
    String? fileKey,
    Value<String?> format = const Value.absent(),
    Value<int?> durationMs = const Value.absent(),
    bool? durationIsEstimate,
    Value<int?> sizeBytes = const Value.absent(),
    Value<List<TimelineMarker>?> embeddedMarkers = const Value.absent(),
    Value<String?> localPath = const Value.absent(),
    Value<DateTime?> downloadedAt = const Value.absent(),
  }) => MediaFileRow(
    id: id ?? this.id,
    bookId: bookId ?? this.bookId,
    fileKey: fileKey ?? this.fileKey,
    format: format.present ? format.value : this.format,
    durationMs: durationMs.present ? durationMs.value : this.durationMs,
    durationIsEstimate: durationIsEstimate ?? this.durationIsEstimate,
    sizeBytes: sizeBytes.present ? sizeBytes.value : this.sizeBytes,
    embeddedMarkers: embeddedMarkers.present
        ? embeddedMarkers.value
        : this.embeddedMarkers,
    localPath: localPath.present ? localPath.value : this.localPath,
    downloadedAt: downloadedAt.present ? downloadedAt.value : this.downloadedAt,
  );
  MediaFileRow copyWithCompanion(MediaFilesCompanion data) {
    return MediaFileRow(
      id: data.id.present ? data.id.value : this.id,
      bookId: data.bookId.present ? data.bookId.value : this.bookId,
      fileKey: data.fileKey.present ? data.fileKey.value : this.fileKey,
      format: data.format.present ? data.format.value : this.format,
      durationMs: data.durationMs.present
          ? data.durationMs.value
          : this.durationMs,
      durationIsEstimate: data.durationIsEstimate.present
          ? data.durationIsEstimate.value
          : this.durationIsEstimate,
      sizeBytes: data.sizeBytes.present ? data.sizeBytes.value : this.sizeBytes,
      embeddedMarkers: data.embeddedMarkers.present
          ? data.embeddedMarkers.value
          : this.embeddedMarkers,
      localPath: data.localPath.present ? data.localPath.value : this.localPath,
      downloadedAt: data.downloadedAt.present
          ? data.downloadedAt.value
          : this.downloadedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MediaFileRow(')
          ..write('id: $id, ')
          ..write('bookId: $bookId, ')
          ..write('fileKey: $fileKey, ')
          ..write('format: $format, ')
          ..write('durationMs: $durationMs, ')
          ..write('durationIsEstimate: $durationIsEstimate, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('embeddedMarkers: $embeddedMarkers, ')
          ..write('localPath: $localPath, ')
          ..write('downloadedAt: $downloadedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    bookId,
    fileKey,
    format,
    durationMs,
    durationIsEstimate,
    sizeBytes,
    embeddedMarkers,
    localPath,
    downloadedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MediaFileRow &&
          other.id == this.id &&
          other.bookId == this.bookId &&
          other.fileKey == this.fileKey &&
          other.format == this.format &&
          other.durationMs == this.durationMs &&
          other.durationIsEstimate == this.durationIsEstimate &&
          other.sizeBytes == this.sizeBytes &&
          other.embeddedMarkers == this.embeddedMarkers &&
          other.localPath == this.localPath &&
          other.downloadedAt == this.downloadedAt);
}

class MediaFilesCompanion extends UpdateCompanion<MediaFileRow> {
  final Value<int> id;
  final Value<int> bookId;
  final Value<String> fileKey;
  final Value<String?> format;
  final Value<int?> durationMs;
  final Value<bool> durationIsEstimate;
  final Value<int?> sizeBytes;
  final Value<List<TimelineMarker>?> embeddedMarkers;
  final Value<String?> localPath;
  final Value<DateTime?> downloadedAt;
  const MediaFilesCompanion({
    this.id = const Value.absent(),
    this.bookId = const Value.absent(),
    this.fileKey = const Value.absent(),
    this.format = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.durationIsEstimate = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.embeddedMarkers = const Value.absent(),
    this.localPath = const Value.absent(),
    this.downloadedAt = const Value.absent(),
  });
  MediaFilesCompanion.insert({
    this.id = const Value.absent(),
    required int bookId,
    required String fileKey,
    this.format = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.durationIsEstimate = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.embeddedMarkers = const Value.absent(),
    this.localPath = const Value.absent(),
    this.downloadedAt = const Value.absent(),
  }) : bookId = Value(bookId),
       fileKey = Value(fileKey);
  static Insertable<MediaFileRow> custom({
    Expression<int>? id,
    Expression<int>? bookId,
    Expression<String>? fileKey,
    Expression<String>? format,
    Expression<int>? durationMs,
    Expression<bool>? durationIsEstimate,
    Expression<int>? sizeBytes,
    Expression<String>? embeddedMarkers,
    Expression<String>? localPath,
    Expression<DateTime>? downloadedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (bookId != null) 'book_id': bookId,
      if (fileKey != null) 'file_key': fileKey,
      if (format != null) 'format': format,
      if (durationMs != null) 'duration_ms': durationMs,
      if (durationIsEstimate != null)
        'duration_is_estimate': durationIsEstimate,
      if (sizeBytes != null) 'size_bytes': sizeBytes,
      if (embeddedMarkers != null) 'embedded_markers': embeddedMarkers,
      if (localPath != null) 'local_path': localPath,
      if (downloadedAt != null) 'downloaded_at': downloadedAt,
    });
  }

  MediaFilesCompanion copyWith({
    Value<int>? id,
    Value<int>? bookId,
    Value<String>? fileKey,
    Value<String?>? format,
    Value<int?>? durationMs,
    Value<bool>? durationIsEstimate,
    Value<int?>? sizeBytes,
    Value<List<TimelineMarker>?>? embeddedMarkers,
    Value<String?>? localPath,
    Value<DateTime?>? downloadedAt,
  }) {
    return MediaFilesCompanion(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      fileKey: fileKey ?? this.fileKey,
      format: format ?? this.format,
      durationMs: durationMs ?? this.durationMs,
      durationIsEstimate: durationIsEstimate ?? this.durationIsEstimate,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      embeddedMarkers: embeddedMarkers ?? this.embeddedMarkers,
      localPath: localPath ?? this.localPath,
      downloadedAt: downloadedAt ?? this.downloadedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (bookId.present) {
      map['book_id'] = Variable<int>(bookId.value);
    }
    if (fileKey.present) {
      map['file_key'] = Variable<String>(fileKey.value);
    }
    if (format.present) {
      map['format'] = Variable<String>(format.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (durationIsEstimate.present) {
      map['duration_is_estimate'] = Variable<bool>(durationIsEstimate.value);
    }
    if (sizeBytes.present) {
      map['size_bytes'] = Variable<int>(sizeBytes.value);
    }
    if (embeddedMarkers.present) {
      map['embedded_markers'] = Variable<String>(
        $MediaFilesTable.$converterembeddedMarkersn.toSql(
          embeddedMarkers.value,
        ),
      );
    }
    if (localPath.present) {
      map['local_path'] = Variable<String>(localPath.value);
    }
    if (downloadedAt.present) {
      map['downloaded_at'] = Variable<DateTime>(downloadedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MediaFilesCompanion(')
          ..write('id: $id, ')
          ..write('bookId: $bookId, ')
          ..write('fileKey: $fileKey, ')
          ..write('format: $format, ')
          ..write('durationMs: $durationMs, ')
          ..write('durationIsEstimate: $durationIsEstimate, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('embeddedMarkers: $embeddedMarkers, ')
          ..write('localPath: $localPath, ')
          ..write('downloadedAt: $downloadedAt')
          ..write(')'))
        .toString();
  }
}

class $ChapterSegmentsTable extends ChapterSegments
    with TableInfo<$ChapterSegmentsTable, ChapterSegmentRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChapterSegmentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _chapterIdMeta = const VerificationMeta(
    'chapterId',
  );
  @override
  late final GeneratedColumn<int> chapterId = GeneratedColumn<int>(
    'chapter_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES chapters (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _ordinalMeta = const VerificationMeta(
    'ordinal',
  );
  @override
  late final GeneratedColumn<int> ordinal = GeneratedColumn<int>(
    'ordinal',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mediaFileIdMeta = const VerificationMeta(
    'mediaFileId',
  );
  @override
  late final GeneratedColumn<int> mediaFileId = GeneratedColumn<int>(
    'media_file_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES media_files (id)',
    ),
  );
  static const VerificationMeta _startMsMeta = const VerificationMeta(
    'startMs',
  );
  @override
  late final GeneratedColumn<int> startMs = GeneratedColumn<int>(
    'start_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _endMsMeta = const VerificationMeta('endMs');
  @override
  late final GeneratedColumn<int> endMs = GeneratedColumn<int>(
    'end_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    chapterId,
    ordinal,
    mediaFileId,
    startMs,
    endMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'chapter_segments';
  @override
  VerificationContext validateIntegrity(
    Insertable<ChapterSegmentRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('chapter_id')) {
      context.handle(
        _chapterIdMeta,
        chapterId.isAcceptableOrUnknown(data['chapter_id']!, _chapterIdMeta),
      );
    } else if (isInserting) {
      context.missing(_chapterIdMeta);
    }
    if (data.containsKey('ordinal')) {
      context.handle(
        _ordinalMeta,
        ordinal.isAcceptableOrUnknown(data['ordinal']!, _ordinalMeta),
      );
    } else if (isInserting) {
      context.missing(_ordinalMeta);
    }
    if (data.containsKey('media_file_id')) {
      context.handle(
        _mediaFileIdMeta,
        mediaFileId.isAcceptableOrUnknown(
          data['media_file_id']!,
          _mediaFileIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_mediaFileIdMeta);
    }
    if (data.containsKey('start_ms')) {
      context.handle(
        _startMsMeta,
        startMs.isAcceptableOrUnknown(data['start_ms']!, _startMsMeta),
      );
    }
    if (data.containsKey('end_ms')) {
      context.handle(
        _endMsMeta,
        endMs.isAcceptableOrUnknown(data['end_ms']!, _endMsMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {chapterId, ordinal};
  @override
  ChapterSegmentRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChapterSegmentRow(
      chapterId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}chapter_id'],
      )!,
      ordinal: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ordinal'],
      )!,
      mediaFileId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}media_file_id'],
      )!,
      startMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_ms'],
      )!,
      endMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_ms'],
      ),
    );
  }

  @override
  $ChapterSegmentsTable createAlias(String alias) {
    return $ChapterSegmentsTable(attachedDatabase, alias);
  }
}

class ChapterSegmentRow extends DataClass
    implements Insertable<ChapterSegmentRow> {
  final int chapterId;
  final int ordinal;

  /// Deliberately not cascading: a file cannot be deleted out from under a chapter's layout.
  final int mediaFileId;
  final int startMs;

  /// Null means to the end of the file, as in the Timeline's own segments, so a whole-file segment
  /// follows its file's duration when a probe refines it and nothing has to be rewritten.
  final int? endMs;
  const ChapterSegmentRow({
    required this.chapterId,
    required this.ordinal,
    required this.mediaFileId,
    required this.startMs,
    this.endMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['chapter_id'] = Variable<int>(chapterId);
    map['ordinal'] = Variable<int>(ordinal);
    map['media_file_id'] = Variable<int>(mediaFileId);
    map['start_ms'] = Variable<int>(startMs);
    if (!nullToAbsent || endMs != null) {
      map['end_ms'] = Variable<int>(endMs);
    }
    return map;
  }

  ChapterSegmentsCompanion toCompanion(bool nullToAbsent) {
    return ChapterSegmentsCompanion(
      chapterId: Value(chapterId),
      ordinal: Value(ordinal),
      mediaFileId: Value(mediaFileId),
      startMs: Value(startMs),
      endMs: endMs == null && nullToAbsent
          ? const Value.absent()
          : Value(endMs),
    );
  }

  factory ChapterSegmentRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChapterSegmentRow(
      chapterId: serializer.fromJson<int>(json['chapterId']),
      ordinal: serializer.fromJson<int>(json['ordinal']),
      mediaFileId: serializer.fromJson<int>(json['mediaFileId']),
      startMs: serializer.fromJson<int>(json['startMs']),
      endMs: serializer.fromJson<int?>(json['endMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'chapterId': serializer.toJson<int>(chapterId),
      'ordinal': serializer.toJson<int>(ordinal),
      'mediaFileId': serializer.toJson<int>(mediaFileId),
      'startMs': serializer.toJson<int>(startMs),
      'endMs': serializer.toJson<int?>(endMs),
    };
  }

  ChapterSegmentRow copyWith({
    int? chapterId,
    int? ordinal,
    int? mediaFileId,
    int? startMs,
    Value<int?> endMs = const Value.absent(),
  }) => ChapterSegmentRow(
    chapterId: chapterId ?? this.chapterId,
    ordinal: ordinal ?? this.ordinal,
    mediaFileId: mediaFileId ?? this.mediaFileId,
    startMs: startMs ?? this.startMs,
    endMs: endMs.present ? endMs.value : this.endMs,
  );
  ChapterSegmentRow copyWithCompanion(ChapterSegmentsCompanion data) {
    return ChapterSegmentRow(
      chapterId: data.chapterId.present ? data.chapterId.value : this.chapterId,
      ordinal: data.ordinal.present ? data.ordinal.value : this.ordinal,
      mediaFileId: data.mediaFileId.present
          ? data.mediaFileId.value
          : this.mediaFileId,
      startMs: data.startMs.present ? data.startMs.value : this.startMs,
      endMs: data.endMs.present ? data.endMs.value : this.endMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChapterSegmentRow(')
          ..write('chapterId: $chapterId, ')
          ..write('ordinal: $ordinal, ')
          ..write('mediaFileId: $mediaFileId, ')
          ..write('startMs: $startMs, ')
          ..write('endMs: $endMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(chapterId, ordinal, mediaFileId, startMs, endMs);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChapterSegmentRow &&
          other.chapterId == this.chapterId &&
          other.ordinal == this.ordinal &&
          other.mediaFileId == this.mediaFileId &&
          other.startMs == this.startMs &&
          other.endMs == this.endMs);
}

class ChapterSegmentsCompanion extends UpdateCompanion<ChapterSegmentRow> {
  final Value<int> chapterId;
  final Value<int> ordinal;
  final Value<int> mediaFileId;
  final Value<int> startMs;
  final Value<int?> endMs;
  final Value<int> rowid;
  const ChapterSegmentsCompanion({
    this.chapterId = const Value.absent(),
    this.ordinal = const Value.absent(),
    this.mediaFileId = const Value.absent(),
    this.startMs = const Value.absent(),
    this.endMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ChapterSegmentsCompanion.insert({
    required int chapterId,
    required int ordinal,
    required int mediaFileId,
    this.startMs = const Value.absent(),
    this.endMs = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : chapterId = Value(chapterId),
       ordinal = Value(ordinal),
       mediaFileId = Value(mediaFileId);
  static Insertable<ChapterSegmentRow> custom({
    Expression<int>? chapterId,
    Expression<int>? ordinal,
    Expression<int>? mediaFileId,
    Expression<int>? startMs,
    Expression<int>? endMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (chapterId != null) 'chapter_id': chapterId,
      if (ordinal != null) 'ordinal': ordinal,
      if (mediaFileId != null) 'media_file_id': mediaFileId,
      if (startMs != null) 'start_ms': startMs,
      if (endMs != null) 'end_ms': endMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ChapterSegmentsCompanion copyWith({
    Value<int>? chapterId,
    Value<int>? ordinal,
    Value<int>? mediaFileId,
    Value<int>? startMs,
    Value<int?>? endMs,
    Value<int>? rowid,
  }) {
    return ChapterSegmentsCompanion(
      chapterId: chapterId ?? this.chapterId,
      ordinal: ordinal ?? this.ordinal,
      mediaFileId: mediaFileId ?? this.mediaFileId,
      startMs: startMs ?? this.startMs,
      endMs: endMs ?? this.endMs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (chapterId.present) {
      map['chapter_id'] = Variable<int>(chapterId.value);
    }
    if (ordinal.present) {
      map['ordinal'] = Variable<int>(ordinal.value);
    }
    if (mediaFileId.present) {
      map['media_file_id'] = Variable<int>(mediaFileId.value);
    }
    if (startMs.present) {
      map['start_ms'] = Variable<int>(startMs.value);
    }
    if (endMs.present) {
      map['end_ms'] = Variable<int>(endMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChapterSegmentsCompanion(')
          ..write('chapterId: $chapterId, ')
          ..write('ordinal: $ordinal, ')
          ..write('mediaFileId: $mediaFileId, ')
          ..write('startMs: $startMs, ')
          ..write('endMs: $endMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlaybackStatesTable extends PlaybackStates
    with TableInfo<$PlaybackStatesTable, PlaybackStateRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlaybackStatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _bookIdMeta = const VerificationMeta('bookId');
  @override
  late final GeneratedColumn<int> bookId = GeneratedColumn<int>(
    'book_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES books (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _chapterIdMeta = const VerificationMeta(
    'chapterId',
  );
  @override
  late final GeneratedColumn<int> chapterId = GeneratedColumn<int>(
    'chapter_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES chapters (id)',
    ),
  );
  static const VerificationMeta _chapterPositionMsMeta = const VerificationMeta(
    'chapterPositionMs',
  );
  @override
  late final GeneratedColumn<int> chapterPositionMs = GeneratedColumn<int>(
    'chapter_position_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _globalPositionMsMeta = const VerificationMeta(
    'globalPositionMs',
  );
  @override
  late final GeneratedColumn<int> globalPositionMs = GeneratedColumn<int>(
    'global_position_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    bookId,
    chapterId,
    chapterPositionMs,
    globalPositionMs,
    updatedAt,
    deviceId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'playback_states';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlaybackStateRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('book_id')) {
      context.handle(
        _bookIdMeta,
        bookId.isAcceptableOrUnknown(data['book_id']!, _bookIdMeta),
      );
    }
    if (data.containsKey('chapter_id')) {
      context.handle(
        _chapterIdMeta,
        chapterId.isAcceptableOrUnknown(data['chapter_id']!, _chapterIdMeta),
      );
    } else if (isInserting) {
      context.missing(_chapterIdMeta);
    }
    if (data.containsKey('chapter_position_ms')) {
      context.handle(
        _chapterPositionMsMeta,
        chapterPositionMs.isAcceptableOrUnknown(
          data['chapter_position_ms']!,
          _chapterPositionMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_chapterPositionMsMeta);
    }
    if (data.containsKey('global_position_ms')) {
      context.handle(
        _globalPositionMsMeta,
        globalPositionMs.isAcceptableOrUnknown(
          data['global_position_ms']!,
          _globalPositionMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_globalPositionMsMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {bookId};
  @override
  PlaybackStateRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlaybackStateRow(
      bookId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}book_id'],
      )!,
      chapterId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}chapter_id'],
      )!,
      chapterPositionMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}chapter_position_ms'],
      )!,
      globalPositionMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}global_position_ms'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
    );
  }

  @override
  $PlaybackStatesTable createAlias(String alias) {
    return $PlaybackStatesTable(attachedDatabase, alias);
  }
}

class PlaybackStateRow extends DataClass
    implements Insertable<PlaybackStateRow> {
  final int bookId;

  /// Not cascading: the database itself refuses to delete a chapter that holds a book's progress.
  final int chapterId;
  final int chapterPositionMs;

  /// Derived from the Timeline and cached for sorting and display. [chapterPositionMs] is the truth.
  final int globalPositionMs;
  final DateTime updatedAt;
  final String deviceId;
  const PlaybackStateRow({
    required this.bookId,
    required this.chapterId,
    required this.chapterPositionMs,
    required this.globalPositionMs,
    required this.updatedAt,
    required this.deviceId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['book_id'] = Variable<int>(bookId);
    map['chapter_id'] = Variable<int>(chapterId);
    map['chapter_position_ms'] = Variable<int>(chapterPositionMs);
    map['global_position_ms'] = Variable<int>(globalPositionMs);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['device_id'] = Variable<String>(deviceId);
    return map;
  }

  PlaybackStatesCompanion toCompanion(bool nullToAbsent) {
    return PlaybackStatesCompanion(
      bookId: Value(bookId),
      chapterId: Value(chapterId),
      chapterPositionMs: Value(chapterPositionMs),
      globalPositionMs: Value(globalPositionMs),
      updatedAt: Value(updatedAt),
      deviceId: Value(deviceId),
    );
  }

  factory PlaybackStateRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlaybackStateRow(
      bookId: serializer.fromJson<int>(json['bookId']),
      chapterId: serializer.fromJson<int>(json['chapterId']),
      chapterPositionMs: serializer.fromJson<int>(json['chapterPositionMs']),
      globalPositionMs: serializer.fromJson<int>(json['globalPositionMs']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'bookId': serializer.toJson<int>(bookId),
      'chapterId': serializer.toJson<int>(chapterId),
      'chapterPositionMs': serializer.toJson<int>(chapterPositionMs),
      'globalPositionMs': serializer.toJson<int>(globalPositionMs),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deviceId': serializer.toJson<String>(deviceId),
    };
  }

  PlaybackStateRow copyWith({
    int? bookId,
    int? chapterId,
    int? chapterPositionMs,
    int? globalPositionMs,
    DateTime? updatedAt,
    String? deviceId,
  }) => PlaybackStateRow(
    bookId: bookId ?? this.bookId,
    chapterId: chapterId ?? this.chapterId,
    chapterPositionMs: chapterPositionMs ?? this.chapterPositionMs,
    globalPositionMs: globalPositionMs ?? this.globalPositionMs,
    updatedAt: updatedAt ?? this.updatedAt,
    deviceId: deviceId ?? this.deviceId,
  );
  PlaybackStateRow copyWithCompanion(PlaybackStatesCompanion data) {
    return PlaybackStateRow(
      bookId: data.bookId.present ? data.bookId.value : this.bookId,
      chapterId: data.chapterId.present ? data.chapterId.value : this.chapterId,
      chapterPositionMs: data.chapterPositionMs.present
          ? data.chapterPositionMs.value
          : this.chapterPositionMs,
      globalPositionMs: data.globalPositionMs.present
          ? data.globalPositionMs.value
          : this.globalPositionMs,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlaybackStateRow(')
          ..write('bookId: $bookId, ')
          ..write('chapterId: $chapterId, ')
          ..write('chapterPositionMs: $chapterPositionMs, ')
          ..write('globalPositionMs: $globalPositionMs, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deviceId: $deviceId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    bookId,
    chapterId,
    chapterPositionMs,
    globalPositionMs,
    updatedAt,
    deviceId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlaybackStateRow &&
          other.bookId == this.bookId &&
          other.chapterId == this.chapterId &&
          other.chapterPositionMs == this.chapterPositionMs &&
          other.globalPositionMs == this.globalPositionMs &&
          other.updatedAt == this.updatedAt &&
          other.deviceId == this.deviceId);
}

class PlaybackStatesCompanion extends UpdateCompanion<PlaybackStateRow> {
  final Value<int> bookId;
  final Value<int> chapterId;
  final Value<int> chapterPositionMs;
  final Value<int> globalPositionMs;
  final Value<DateTime> updatedAt;
  final Value<String> deviceId;
  const PlaybackStatesCompanion({
    this.bookId = const Value.absent(),
    this.chapterId = const Value.absent(),
    this.chapterPositionMs = const Value.absent(),
    this.globalPositionMs = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
  });
  PlaybackStatesCompanion.insert({
    this.bookId = const Value.absent(),
    required int chapterId,
    required int chapterPositionMs,
    required int globalPositionMs,
    required DateTime updatedAt,
    required String deviceId,
  }) : chapterId = Value(chapterId),
       chapterPositionMs = Value(chapterPositionMs),
       globalPositionMs = Value(globalPositionMs),
       updatedAt = Value(updatedAt),
       deviceId = Value(deviceId);
  static Insertable<PlaybackStateRow> custom({
    Expression<int>? bookId,
    Expression<int>? chapterId,
    Expression<int>? chapterPositionMs,
    Expression<int>? globalPositionMs,
    Expression<DateTime>? updatedAt,
    Expression<String>? deviceId,
  }) {
    return RawValuesInsertable({
      if (bookId != null) 'book_id': bookId,
      if (chapterId != null) 'chapter_id': chapterId,
      if (chapterPositionMs != null) 'chapter_position_ms': chapterPositionMs,
      if (globalPositionMs != null) 'global_position_ms': globalPositionMs,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deviceId != null) 'device_id': deviceId,
    });
  }

  PlaybackStatesCompanion copyWith({
    Value<int>? bookId,
    Value<int>? chapterId,
    Value<int>? chapterPositionMs,
    Value<int>? globalPositionMs,
    Value<DateTime>? updatedAt,
    Value<String>? deviceId,
  }) {
    return PlaybackStatesCompanion(
      bookId: bookId ?? this.bookId,
      chapterId: chapterId ?? this.chapterId,
      chapterPositionMs: chapterPositionMs ?? this.chapterPositionMs,
      globalPositionMs: globalPositionMs ?? this.globalPositionMs,
      updatedAt: updatedAt ?? this.updatedAt,
      deviceId: deviceId ?? this.deviceId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (bookId.present) {
      map['book_id'] = Variable<int>(bookId.value);
    }
    if (chapterId.present) {
      map['chapter_id'] = Variable<int>(chapterId.value);
    }
    if (chapterPositionMs.present) {
      map['chapter_position_ms'] = Variable<int>(chapterPositionMs.value);
    }
    if (globalPositionMs.present) {
      map['global_position_ms'] = Variable<int>(globalPositionMs.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlaybackStatesCompanion(')
          ..write('bookId: $bookId, ')
          ..write('chapterId: $chapterId, ')
          ..write('chapterPositionMs: $chapterPositionMs, ')
          ..write('globalPositionMs: $globalPositionMs, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deviceId: $deviceId')
          ..write(')'))
        .toString();
  }
}

class $ReadingStatesTable extends ReadingStates
    with TableInfo<$ReadingStatesTable, ReadingStateRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReadingStatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _bookIdMeta = const VerificationMeta('bookId');
  @override
  late final GeneratedColumn<int> bookId = GeneratedColumn<int>(
    'book_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES books (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _chapterIdMeta = const VerificationMeta(
    'chapterId',
  );
  @override
  late final GeneratedColumn<int> chapterId = GeneratedColumn<int>(
    'chapter_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES chapters (id)',
    ),
  );
  static const VerificationMeta _progressMeta = const VerificationMeta(
    'progress',
  );
  @override
  late final GeneratedColumn<double> progress = GeneratedColumn<double>(
    'progress',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    bookId,
    chapterId,
    progress,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reading_states';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReadingStateRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('book_id')) {
      context.handle(
        _bookIdMeta,
        bookId.isAcceptableOrUnknown(data['book_id']!, _bookIdMeta),
      );
    }
    if (data.containsKey('chapter_id')) {
      context.handle(
        _chapterIdMeta,
        chapterId.isAcceptableOrUnknown(data['chapter_id']!, _chapterIdMeta),
      );
    } else if (isInserting) {
      context.missing(_chapterIdMeta);
    }
    if (data.containsKey('progress')) {
      context.handle(
        _progressMeta,
        progress.isAcceptableOrUnknown(data['progress']!, _progressMeta),
      );
    } else if (isInserting) {
      context.missing(_progressMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {bookId};
  @override
  ReadingStateRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReadingStateRow(
      bookId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}book_id'],
      )!,
      chapterId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}chapter_id'],
      )!,
      progress: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}progress'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ReadingStatesTable createAlias(String alias) {
    return $ReadingStatesTable(attachedDatabase, alias);
  }
}

class ReadingStateRow extends DataClass implements Insertable<ReadingStateRow> {
  final int bookId;

  /// Not cascading, for `playback_state`'s reason: the database refuses to delete a chapter that holds
  /// a reader's place. A sync never deletes one anyway — a chapter a source drops is marked
  /// `removed_from_source` — so this only ever stops a mistake.
  final int chapterId;

  /// How far through the chapter, from 0 at its start to 1 at its end.
  ///
  /// A fraction rather than characters or pixels, because it has to survive the reader changing the
  /// font size or turning the phone round, and neither of those should move anyone's place.
  final double progress;
  final DateTime updatedAt;
  const ReadingStateRow({
    required this.bookId,
    required this.chapterId,
    required this.progress,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['book_id'] = Variable<int>(bookId);
    map['chapter_id'] = Variable<int>(chapterId);
    map['progress'] = Variable<double>(progress);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ReadingStatesCompanion toCompanion(bool nullToAbsent) {
    return ReadingStatesCompanion(
      bookId: Value(bookId),
      chapterId: Value(chapterId),
      progress: Value(progress),
      updatedAt: Value(updatedAt),
    );
  }

  factory ReadingStateRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReadingStateRow(
      bookId: serializer.fromJson<int>(json['bookId']),
      chapterId: serializer.fromJson<int>(json['chapterId']),
      progress: serializer.fromJson<double>(json['progress']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'bookId': serializer.toJson<int>(bookId),
      'chapterId': serializer.toJson<int>(chapterId),
      'progress': serializer.toJson<double>(progress),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ReadingStateRow copyWith({
    int? bookId,
    int? chapterId,
    double? progress,
    DateTime? updatedAt,
  }) => ReadingStateRow(
    bookId: bookId ?? this.bookId,
    chapterId: chapterId ?? this.chapterId,
    progress: progress ?? this.progress,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ReadingStateRow copyWithCompanion(ReadingStatesCompanion data) {
    return ReadingStateRow(
      bookId: data.bookId.present ? data.bookId.value : this.bookId,
      chapterId: data.chapterId.present ? data.chapterId.value : this.chapterId,
      progress: data.progress.present ? data.progress.value : this.progress,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReadingStateRow(')
          ..write('bookId: $bookId, ')
          ..write('chapterId: $chapterId, ')
          ..write('progress: $progress, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(bookId, chapterId, progress, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReadingStateRow &&
          other.bookId == this.bookId &&
          other.chapterId == this.chapterId &&
          other.progress == this.progress &&
          other.updatedAt == this.updatedAt);
}

class ReadingStatesCompanion extends UpdateCompanion<ReadingStateRow> {
  final Value<int> bookId;
  final Value<int> chapterId;
  final Value<double> progress;
  final Value<DateTime> updatedAt;
  const ReadingStatesCompanion({
    this.bookId = const Value.absent(),
    this.chapterId = const Value.absent(),
    this.progress = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  ReadingStatesCompanion.insert({
    this.bookId = const Value.absent(),
    required int chapterId,
    required double progress,
    required DateTime updatedAt,
  }) : chapterId = Value(chapterId),
       progress = Value(progress),
       updatedAt = Value(updatedAt);
  static Insertable<ReadingStateRow> custom({
    Expression<int>? bookId,
    Expression<int>? chapterId,
    Expression<double>? progress,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (bookId != null) 'book_id': bookId,
      if (chapterId != null) 'chapter_id': chapterId,
      if (progress != null) 'progress': progress,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  ReadingStatesCompanion copyWith({
    Value<int>? bookId,
    Value<int>? chapterId,
    Value<double>? progress,
    Value<DateTime>? updatedAt,
  }) {
    return ReadingStatesCompanion(
      bookId: bookId ?? this.bookId,
      chapterId: chapterId ?? this.chapterId,
      progress: progress ?? this.progress,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (bookId.present) {
      map['book_id'] = Variable<int>(bookId.value);
    }
    if (chapterId.present) {
      map['chapter_id'] = Variable<int>(chapterId.value);
    }
    if (progress.present) {
      map['progress'] = Variable<double>(progress.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReadingStatesCompanion(')
          ..write('bookId: $bookId, ')
          ..write('chapterId: $chapterId, ')
          ..write('progress: $progress, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $ReadingSessionsTable extends ReadingSessions
    with TableInfo<$ReadingSessionsTable, ReadingSessionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReadingSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _bookIdMeta = const VerificationMeta('bookId');
  @override
  late final GeneratedColumn<int> bookId = GeneratedColumn<int>(
    'book_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES books (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _chapterIdMeta = const VerificationMeta(
    'chapterId',
  );
  @override
  late final GeneratedColumn<int> chapterId = GeneratedColumn<int>(
    'chapter_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES chapters (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endedAtMeta = const VerificationMeta(
    'endedAt',
  );
  @override
  late final GeneratedColumn<DateTime> endedAt = GeneratedColumn<DateTime>(
    'ended_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    bookId,
    chapterId,
    startedAt,
    endedAt,
    deviceId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reading_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReadingSessionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('book_id')) {
      context.handle(
        _bookIdMeta,
        bookId.isAcceptableOrUnknown(data['book_id']!, _bookIdMeta),
      );
    } else if (isInserting) {
      context.missing(_bookIdMeta);
    }
    if (data.containsKey('chapter_id')) {
      context.handle(
        _chapterIdMeta,
        chapterId.isAcceptableOrUnknown(data['chapter_id']!, _chapterIdMeta),
      );
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('ended_at')) {
      context.handle(
        _endedAtMeta,
        endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_endedAtMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReadingSessionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReadingSessionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      bookId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}book_id'],
      )!,
      chapterId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}chapter_id'],
      ),
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      endedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ended_at'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
    );
  }

  @override
  $ReadingSessionsTable createAlias(String alias) {
    return $ReadingSessionsTable(attachedDatabase, alias);
  }
}

class ReadingSessionRow extends DataClass
    implements Insertable<ReadingSessionRow> {
  final int id;
  final int bookId;

  /// Nullable and cleared when the chapter is purged, for `listening_session`'s reason: history
  /// outlives the chapters it covered.
  final int? chapterId;
  final DateTime startedAt;
  final DateTime endedAt;
  final String deviceId;
  const ReadingSessionRow({
    required this.id,
    required this.bookId,
    this.chapterId,
    required this.startedAt,
    required this.endedAt,
    required this.deviceId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['book_id'] = Variable<int>(bookId);
    if (!nullToAbsent || chapterId != null) {
      map['chapter_id'] = Variable<int>(chapterId);
    }
    map['started_at'] = Variable<DateTime>(startedAt);
    map['ended_at'] = Variable<DateTime>(endedAt);
    map['device_id'] = Variable<String>(deviceId);
    return map;
  }

  ReadingSessionsCompanion toCompanion(bool nullToAbsent) {
    return ReadingSessionsCompanion(
      id: Value(id),
      bookId: Value(bookId),
      chapterId: chapterId == null && nullToAbsent
          ? const Value.absent()
          : Value(chapterId),
      startedAt: Value(startedAt),
      endedAt: Value(endedAt),
      deviceId: Value(deviceId),
    );
  }

  factory ReadingSessionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReadingSessionRow(
      id: serializer.fromJson<int>(json['id']),
      bookId: serializer.fromJson<int>(json['bookId']),
      chapterId: serializer.fromJson<int?>(json['chapterId']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      endedAt: serializer.fromJson<DateTime>(json['endedAt']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'bookId': serializer.toJson<int>(bookId),
      'chapterId': serializer.toJson<int?>(chapterId),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'endedAt': serializer.toJson<DateTime>(endedAt),
      'deviceId': serializer.toJson<String>(deviceId),
    };
  }

  ReadingSessionRow copyWith({
    int? id,
    int? bookId,
    Value<int?> chapterId = const Value.absent(),
    DateTime? startedAt,
    DateTime? endedAt,
    String? deviceId,
  }) => ReadingSessionRow(
    id: id ?? this.id,
    bookId: bookId ?? this.bookId,
    chapterId: chapterId.present ? chapterId.value : this.chapterId,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt ?? this.endedAt,
    deviceId: deviceId ?? this.deviceId,
  );
  ReadingSessionRow copyWithCompanion(ReadingSessionsCompanion data) {
    return ReadingSessionRow(
      id: data.id.present ? data.id.value : this.id,
      bookId: data.bookId.present ? data.bookId.value : this.bookId,
      chapterId: data.chapterId.present ? data.chapterId.value : this.chapterId,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReadingSessionRow(')
          ..write('id: $id, ')
          ..write('bookId: $bookId, ')
          ..write('chapterId: $chapterId, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('deviceId: $deviceId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, bookId, chapterId, startedAt, endedAt, deviceId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReadingSessionRow &&
          other.id == this.id &&
          other.bookId == this.bookId &&
          other.chapterId == this.chapterId &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.deviceId == this.deviceId);
}

class ReadingSessionsCompanion extends UpdateCompanion<ReadingSessionRow> {
  final Value<int> id;
  final Value<int> bookId;
  final Value<int?> chapterId;
  final Value<DateTime> startedAt;
  final Value<DateTime> endedAt;
  final Value<String> deviceId;
  const ReadingSessionsCompanion({
    this.id = const Value.absent(),
    this.bookId = const Value.absent(),
    this.chapterId = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
  });
  ReadingSessionsCompanion.insert({
    this.id = const Value.absent(),
    required int bookId,
    this.chapterId = const Value.absent(),
    required DateTime startedAt,
    required DateTime endedAt,
    required String deviceId,
  }) : bookId = Value(bookId),
       startedAt = Value(startedAt),
       endedAt = Value(endedAt),
       deviceId = Value(deviceId);
  static Insertable<ReadingSessionRow> custom({
    Expression<int>? id,
    Expression<int>? bookId,
    Expression<int>? chapterId,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? endedAt,
    Expression<String>? deviceId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (bookId != null) 'book_id': bookId,
      if (chapterId != null) 'chapter_id': chapterId,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (deviceId != null) 'device_id': deviceId,
    });
  }

  ReadingSessionsCompanion copyWith({
    Value<int>? id,
    Value<int>? bookId,
    Value<int?>? chapterId,
    Value<DateTime>? startedAt,
    Value<DateTime>? endedAt,
    Value<String>? deviceId,
  }) {
    return ReadingSessionsCompanion(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      chapterId: chapterId ?? this.chapterId,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      deviceId: deviceId ?? this.deviceId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (bookId.present) {
      map['book_id'] = Variable<int>(bookId.value);
    }
    if (chapterId.present) {
      map['chapter_id'] = Variable<int>(chapterId.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<DateTime>(endedAt.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReadingSessionsCompanion(')
          ..write('id: $id, ')
          ..write('bookId: $bookId, ')
          ..write('chapterId: $chapterId, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('deviceId: $deviceId')
          ..write(')'))
        .toString();
  }
}

class $ListeningSessionsTable extends ListeningSessions
    with TableInfo<$ListeningSessionsTable, ListeningSessionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ListeningSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _bookIdMeta = const VerificationMeta('bookId');
  @override
  late final GeneratedColumn<int> bookId = GeneratedColumn<int>(
    'book_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES books (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _chapterIdMeta = const VerificationMeta(
    'chapterId',
  );
  @override
  late final GeneratedColumn<int> chapterId = GeneratedColumn<int>(
    'chapter_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES chapters (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endedAtMeta = const VerificationMeta(
    'endedAt',
  );
  @override
  late final GeneratedColumn<DateTime> endedAt = GeneratedColumn<DateTime>(
    'ended_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startGlobalMsMeta = const VerificationMeta(
    'startGlobalMs',
  );
  @override
  late final GeneratedColumn<int> startGlobalMs = GeneratedColumn<int>(
    'start_global_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endGlobalMsMeta = const VerificationMeta(
    'endGlobalMs',
  );
  @override
  late final GeneratedColumn<int> endGlobalMs = GeneratedColumn<int>(
    'end_global_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _speedMeta = const VerificationMeta('speed');
  @override
  late final GeneratedColumn<double> speed = GeneratedColumn<double>(
    'speed',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    bookId,
    chapterId,
    startedAt,
    endedAt,
    startGlobalMs,
    endGlobalMs,
    speed,
    deviceId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'listening_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<ListeningSessionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('book_id')) {
      context.handle(
        _bookIdMeta,
        bookId.isAcceptableOrUnknown(data['book_id']!, _bookIdMeta),
      );
    } else if (isInserting) {
      context.missing(_bookIdMeta);
    }
    if (data.containsKey('chapter_id')) {
      context.handle(
        _chapterIdMeta,
        chapterId.isAcceptableOrUnknown(data['chapter_id']!, _chapterIdMeta),
      );
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('ended_at')) {
      context.handle(
        _endedAtMeta,
        endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_endedAtMeta);
    }
    if (data.containsKey('start_global_ms')) {
      context.handle(
        _startGlobalMsMeta,
        startGlobalMs.isAcceptableOrUnknown(
          data['start_global_ms']!,
          _startGlobalMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_startGlobalMsMeta);
    }
    if (data.containsKey('end_global_ms')) {
      context.handle(
        _endGlobalMsMeta,
        endGlobalMs.isAcceptableOrUnknown(
          data['end_global_ms']!,
          _endGlobalMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_endGlobalMsMeta);
    }
    if (data.containsKey('speed')) {
      context.handle(
        _speedMeta,
        speed.isAcceptableOrUnknown(data['speed']!, _speedMeta),
      );
    } else if (isInserting) {
      context.missing(_speedMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ListeningSessionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ListeningSessionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      bookId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}book_id'],
      )!,
      chapterId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}chapter_id'],
      ),
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      endedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ended_at'],
      )!,
      startGlobalMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_global_ms'],
      )!,
      endGlobalMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_global_ms'],
      )!,
      speed: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}speed'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
    );
  }

  @override
  $ListeningSessionsTable createAlias(String alias) {
    return $ListeningSessionsTable(attachedDatabase, alias);
  }
}

class ListeningSessionRow extends DataClass
    implements Insertable<ListeningSessionRow> {
  final int id;
  final int bookId;

  /// Nullable and cleared when the chapter is purged. Listening history should outlive a chapter the
  /// source dropped; §4.4's "keep while it carries user data" rule covers progress, bookmarks and
  /// downloads, not history.
  final int? chapterId;
  final DateTime startedAt;
  final DateTime endedAt;
  final int startGlobalMs;
  final int endGlobalMs;
  final double speed;
  final String deviceId;
  const ListeningSessionRow({
    required this.id,
    required this.bookId,
    this.chapterId,
    required this.startedAt,
    required this.endedAt,
    required this.startGlobalMs,
    required this.endGlobalMs,
    required this.speed,
    required this.deviceId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['book_id'] = Variable<int>(bookId);
    if (!nullToAbsent || chapterId != null) {
      map['chapter_id'] = Variable<int>(chapterId);
    }
    map['started_at'] = Variable<DateTime>(startedAt);
    map['ended_at'] = Variable<DateTime>(endedAt);
    map['start_global_ms'] = Variable<int>(startGlobalMs);
    map['end_global_ms'] = Variable<int>(endGlobalMs);
    map['speed'] = Variable<double>(speed);
    map['device_id'] = Variable<String>(deviceId);
    return map;
  }

  ListeningSessionsCompanion toCompanion(bool nullToAbsent) {
    return ListeningSessionsCompanion(
      id: Value(id),
      bookId: Value(bookId),
      chapterId: chapterId == null && nullToAbsent
          ? const Value.absent()
          : Value(chapterId),
      startedAt: Value(startedAt),
      endedAt: Value(endedAt),
      startGlobalMs: Value(startGlobalMs),
      endGlobalMs: Value(endGlobalMs),
      speed: Value(speed),
      deviceId: Value(deviceId),
    );
  }

  factory ListeningSessionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ListeningSessionRow(
      id: serializer.fromJson<int>(json['id']),
      bookId: serializer.fromJson<int>(json['bookId']),
      chapterId: serializer.fromJson<int?>(json['chapterId']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      endedAt: serializer.fromJson<DateTime>(json['endedAt']),
      startGlobalMs: serializer.fromJson<int>(json['startGlobalMs']),
      endGlobalMs: serializer.fromJson<int>(json['endGlobalMs']),
      speed: serializer.fromJson<double>(json['speed']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'bookId': serializer.toJson<int>(bookId),
      'chapterId': serializer.toJson<int?>(chapterId),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'endedAt': serializer.toJson<DateTime>(endedAt),
      'startGlobalMs': serializer.toJson<int>(startGlobalMs),
      'endGlobalMs': serializer.toJson<int>(endGlobalMs),
      'speed': serializer.toJson<double>(speed),
      'deviceId': serializer.toJson<String>(deviceId),
    };
  }

  ListeningSessionRow copyWith({
    int? id,
    int? bookId,
    Value<int?> chapterId = const Value.absent(),
    DateTime? startedAt,
    DateTime? endedAt,
    int? startGlobalMs,
    int? endGlobalMs,
    double? speed,
    String? deviceId,
  }) => ListeningSessionRow(
    id: id ?? this.id,
    bookId: bookId ?? this.bookId,
    chapterId: chapterId.present ? chapterId.value : this.chapterId,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt ?? this.endedAt,
    startGlobalMs: startGlobalMs ?? this.startGlobalMs,
    endGlobalMs: endGlobalMs ?? this.endGlobalMs,
    speed: speed ?? this.speed,
    deviceId: deviceId ?? this.deviceId,
  );
  ListeningSessionRow copyWithCompanion(ListeningSessionsCompanion data) {
    return ListeningSessionRow(
      id: data.id.present ? data.id.value : this.id,
      bookId: data.bookId.present ? data.bookId.value : this.bookId,
      chapterId: data.chapterId.present ? data.chapterId.value : this.chapterId,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      startGlobalMs: data.startGlobalMs.present
          ? data.startGlobalMs.value
          : this.startGlobalMs,
      endGlobalMs: data.endGlobalMs.present
          ? data.endGlobalMs.value
          : this.endGlobalMs,
      speed: data.speed.present ? data.speed.value : this.speed,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ListeningSessionRow(')
          ..write('id: $id, ')
          ..write('bookId: $bookId, ')
          ..write('chapterId: $chapterId, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('startGlobalMs: $startGlobalMs, ')
          ..write('endGlobalMs: $endGlobalMs, ')
          ..write('speed: $speed, ')
          ..write('deviceId: $deviceId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    bookId,
    chapterId,
    startedAt,
    endedAt,
    startGlobalMs,
    endGlobalMs,
    speed,
    deviceId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ListeningSessionRow &&
          other.id == this.id &&
          other.bookId == this.bookId &&
          other.chapterId == this.chapterId &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.startGlobalMs == this.startGlobalMs &&
          other.endGlobalMs == this.endGlobalMs &&
          other.speed == this.speed &&
          other.deviceId == this.deviceId);
}

class ListeningSessionsCompanion extends UpdateCompanion<ListeningSessionRow> {
  final Value<int> id;
  final Value<int> bookId;
  final Value<int?> chapterId;
  final Value<DateTime> startedAt;
  final Value<DateTime> endedAt;
  final Value<int> startGlobalMs;
  final Value<int> endGlobalMs;
  final Value<double> speed;
  final Value<String> deviceId;
  const ListeningSessionsCompanion({
    this.id = const Value.absent(),
    this.bookId = const Value.absent(),
    this.chapterId = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.startGlobalMs = const Value.absent(),
    this.endGlobalMs = const Value.absent(),
    this.speed = const Value.absent(),
    this.deviceId = const Value.absent(),
  });
  ListeningSessionsCompanion.insert({
    this.id = const Value.absent(),
    required int bookId,
    this.chapterId = const Value.absent(),
    required DateTime startedAt,
    required DateTime endedAt,
    required int startGlobalMs,
    required int endGlobalMs,
    required double speed,
    required String deviceId,
  }) : bookId = Value(bookId),
       startedAt = Value(startedAt),
       endedAt = Value(endedAt),
       startGlobalMs = Value(startGlobalMs),
       endGlobalMs = Value(endGlobalMs),
       speed = Value(speed),
       deviceId = Value(deviceId);
  static Insertable<ListeningSessionRow> custom({
    Expression<int>? id,
    Expression<int>? bookId,
    Expression<int>? chapterId,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? endedAt,
    Expression<int>? startGlobalMs,
    Expression<int>? endGlobalMs,
    Expression<double>? speed,
    Expression<String>? deviceId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (bookId != null) 'book_id': bookId,
      if (chapterId != null) 'chapter_id': chapterId,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (startGlobalMs != null) 'start_global_ms': startGlobalMs,
      if (endGlobalMs != null) 'end_global_ms': endGlobalMs,
      if (speed != null) 'speed': speed,
      if (deviceId != null) 'device_id': deviceId,
    });
  }

  ListeningSessionsCompanion copyWith({
    Value<int>? id,
    Value<int>? bookId,
    Value<int?>? chapterId,
    Value<DateTime>? startedAt,
    Value<DateTime>? endedAt,
    Value<int>? startGlobalMs,
    Value<int>? endGlobalMs,
    Value<double>? speed,
    Value<String>? deviceId,
  }) {
    return ListeningSessionsCompanion(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      chapterId: chapterId ?? this.chapterId,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      startGlobalMs: startGlobalMs ?? this.startGlobalMs,
      endGlobalMs: endGlobalMs ?? this.endGlobalMs,
      speed: speed ?? this.speed,
      deviceId: deviceId ?? this.deviceId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (bookId.present) {
      map['book_id'] = Variable<int>(bookId.value);
    }
    if (chapterId.present) {
      map['chapter_id'] = Variable<int>(chapterId.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<DateTime>(endedAt.value);
    }
    if (startGlobalMs.present) {
      map['start_global_ms'] = Variable<int>(startGlobalMs.value);
    }
    if (endGlobalMs.present) {
      map['end_global_ms'] = Variable<int>(endGlobalMs.value);
    }
    if (speed.present) {
      map['speed'] = Variable<double>(speed.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ListeningSessionsCompanion(')
          ..write('id: $id, ')
          ..write('bookId: $bookId, ')
          ..write('chapterId: $chapterId, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('startGlobalMs: $startGlobalMs, ')
          ..write('endGlobalMs: $endGlobalMs, ')
          ..write('speed: $speed, ')
          ..write('deviceId: $deviceId')
          ..write(')'))
        .toString();
  }
}

class $BookmarksTable extends Bookmarks
    with TableInfo<$BookmarksTable, BookmarkRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BookmarksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _bookIdMeta = const VerificationMeta('bookId');
  @override
  late final GeneratedColumn<int> bookId = GeneratedColumn<int>(
    'book_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES books (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _chapterIdMeta = const VerificationMeta(
    'chapterId',
  );
  @override
  late final GeneratedColumn<int> chapterId = GeneratedColumn<int>(
    'chapter_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES chapters (id)',
    ),
  );
  static const VerificationMeta _positionMsMeta = const VerificationMeta(
    'positionMs',
  );
  @override
  late final GeneratedColumn<int> positionMs = GeneratedColumn<int>(
    'position_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    bookId,
    chapterId,
    positionMs,
    title,
    note,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bookmarks';
  @override
  VerificationContext validateIntegrity(
    Insertable<BookmarkRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('book_id')) {
      context.handle(
        _bookIdMeta,
        bookId.isAcceptableOrUnknown(data['book_id']!, _bookIdMeta),
      );
    } else if (isInserting) {
      context.missing(_bookIdMeta);
    }
    if (data.containsKey('chapter_id')) {
      context.handle(
        _chapterIdMeta,
        chapterId.isAcceptableOrUnknown(data['chapter_id']!, _chapterIdMeta),
      );
    } else if (isInserting) {
      context.missing(_chapterIdMeta);
    }
    if (data.containsKey('position_ms')) {
      context.handle(
        _positionMsMeta,
        positionMs.isAcceptableOrUnknown(data['position_ms']!, _positionMsMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMsMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BookmarkRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BookmarkRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      bookId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}book_id'],
      )!,
      chapterId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}chapter_id'],
      )!,
      positionMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position_ms'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $BookmarksTable createAlias(String alias) {
    return $BookmarksTable(attachedDatabase, alias);
  }
}

class BookmarkRow extends DataClass implements Insertable<BookmarkRow> {
  final int id;
  final int bookId;

  /// Not cascading, for the same reason as progress.
  final int chapterId;
  final int positionMs;
  final String? title;
  final String? note;
  final DateTime createdAt;
  const BookmarkRow({
    required this.id,
    required this.bookId,
    required this.chapterId,
    required this.positionMs,
    this.title,
    this.note,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['book_id'] = Variable<int>(bookId);
    map['chapter_id'] = Variable<int>(chapterId);
    map['position_ms'] = Variable<int>(positionMs);
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  BookmarksCompanion toCompanion(bool nullToAbsent) {
    return BookmarksCompanion(
      id: Value(id),
      bookId: Value(bookId),
      chapterId: Value(chapterId),
      positionMs: Value(positionMs),
      title: title == null && nullToAbsent
          ? const Value.absent()
          : Value(title),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      createdAt: Value(createdAt),
    );
  }

  factory BookmarkRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BookmarkRow(
      id: serializer.fromJson<int>(json['id']),
      bookId: serializer.fromJson<int>(json['bookId']),
      chapterId: serializer.fromJson<int>(json['chapterId']),
      positionMs: serializer.fromJson<int>(json['positionMs']),
      title: serializer.fromJson<String?>(json['title']),
      note: serializer.fromJson<String?>(json['note']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'bookId': serializer.toJson<int>(bookId),
      'chapterId': serializer.toJson<int>(chapterId),
      'positionMs': serializer.toJson<int>(positionMs),
      'title': serializer.toJson<String?>(title),
      'note': serializer.toJson<String?>(note),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  BookmarkRow copyWith({
    int? id,
    int? bookId,
    int? chapterId,
    int? positionMs,
    Value<String?> title = const Value.absent(),
    Value<String?> note = const Value.absent(),
    DateTime? createdAt,
  }) => BookmarkRow(
    id: id ?? this.id,
    bookId: bookId ?? this.bookId,
    chapterId: chapterId ?? this.chapterId,
    positionMs: positionMs ?? this.positionMs,
    title: title.present ? title.value : this.title,
    note: note.present ? note.value : this.note,
    createdAt: createdAt ?? this.createdAt,
  );
  BookmarkRow copyWithCompanion(BookmarksCompanion data) {
    return BookmarkRow(
      id: data.id.present ? data.id.value : this.id,
      bookId: data.bookId.present ? data.bookId.value : this.bookId,
      chapterId: data.chapterId.present ? data.chapterId.value : this.chapterId,
      positionMs: data.positionMs.present
          ? data.positionMs.value
          : this.positionMs,
      title: data.title.present ? data.title.value : this.title,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BookmarkRow(')
          ..write('id: $id, ')
          ..write('bookId: $bookId, ')
          ..write('chapterId: $chapterId, ')
          ..write('positionMs: $positionMs, ')
          ..write('title: $title, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, bookId, chapterId, positionMs, title, note, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BookmarkRow &&
          other.id == this.id &&
          other.bookId == this.bookId &&
          other.chapterId == this.chapterId &&
          other.positionMs == this.positionMs &&
          other.title == this.title &&
          other.note == this.note &&
          other.createdAt == this.createdAt);
}

class BookmarksCompanion extends UpdateCompanion<BookmarkRow> {
  final Value<int> id;
  final Value<int> bookId;
  final Value<int> chapterId;
  final Value<int> positionMs;
  final Value<String?> title;
  final Value<String?> note;
  final Value<DateTime> createdAt;
  const BookmarksCompanion({
    this.id = const Value.absent(),
    this.bookId = const Value.absent(),
    this.chapterId = const Value.absent(),
    this.positionMs = const Value.absent(),
    this.title = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  BookmarksCompanion.insert({
    this.id = const Value.absent(),
    required int bookId,
    required int chapterId,
    required int positionMs,
    this.title = const Value.absent(),
    this.note = const Value.absent(),
    required DateTime createdAt,
  }) : bookId = Value(bookId),
       chapterId = Value(chapterId),
       positionMs = Value(positionMs),
       createdAt = Value(createdAt);
  static Insertable<BookmarkRow> custom({
    Expression<int>? id,
    Expression<int>? bookId,
    Expression<int>? chapterId,
    Expression<int>? positionMs,
    Expression<String>? title,
    Expression<String>? note,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (bookId != null) 'book_id': bookId,
      if (chapterId != null) 'chapter_id': chapterId,
      if (positionMs != null) 'position_ms': positionMs,
      if (title != null) 'title': title,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  BookmarksCompanion copyWith({
    Value<int>? id,
    Value<int>? bookId,
    Value<int>? chapterId,
    Value<int>? positionMs,
    Value<String?>? title,
    Value<String?>? note,
    Value<DateTime>? createdAt,
  }) {
    return BookmarksCompanion(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      chapterId: chapterId ?? this.chapterId,
      positionMs: positionMs ?? this.positionMs,
      title: title ?? this.title,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (bookId.present) {
      map['book_id'] = Variable<int>(bookId.value);
    }
    if (chapterId.present) {
      map['chapter_id'] = Variable<int>(chapterId.value);
    }
    if (positionMs.present) {
      map['position_ms'] = Variable<int>(positionMs.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BookmarksCompanion(')
          ..write('id: $id, ')
          ..write('bookId: $bookId, ')
          ..write('chapterId: $chapterId, ')
          ..write('positionMs: $positionMs, ')
          ..write('title: $title, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $CategoriesTable extends Categories
    with TableInfo<$CategoriesTable, CategoryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _flagsMeta = const VerificationMeta('flags');
  @override
  late final GeneratedColumn<int> flags = GeneratedColumn<int>(
    'flags',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, sortOrder, flags];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<CategoryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    if (data.containsKey('flags')) {
      context.handle(
        _flagsMeta,
        flags.isAcceptableOrUnknown(data['flags']!, _flagsMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CategoryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CategoryRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      flags: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}flags'],
      )!,
    );
  }

  @override
  $CategoriesTable createAlias(String alias) {
    return $CategoriesTable(attachedDatabase, alias);
  }
}

class CategoryRow extends DataClass implements Insertable<CategoryRow> {
  final int id;
  final String name;
  final int sortOrder;

  /// Per-category sort, filter and display settings, packed as §4.3 describes.
  final int flags;
  const CategoryRow({
    required this.id,
    required this.name,
    required this.sortOrder,
    required this.flags,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['sort_order'] = Variable<int>(sortOrder);
    map['flags'] = Variable<int>(flags);
    return map;
  }

  CategoriesCompanion toCompanion(bool nullToAbsent) {
    return CategoriesCompanion(
      id: Value(id),
      name: Value(name),
      sortOrder: Value(sortOrder),
      flags: Value(flags),
    );
  }

  factory CategoryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CategoryRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      flags: serializer.fromJson<int>(json['flags']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'flags': serializer.toJson<int>(flags),
    };
  }

  CategoryRow copyWith({int? id, String? name, int? sortOrder, int? flags}) =>
      CategoryRow(
        id: id ?? this.id,
        name: name ?? this.name,
        sortOrder: sortOrder ?? this.sortOrder,
        flags: flags ?? this.flags,
      );
  CategoryRow copyWithCompanion(CategoriesCompanion data) {
    return CategoryRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      flags: data.flags.present ? data.flags.value : this.flags,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CategoryRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('flags: $flags')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, sortOrder, flags);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CategoryRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.sortOrder == this.sortOrder &&
          other.flags == this.flags);
}

class CategoriesCompanion extends UpdateCompanion<CategoryRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<int> sortOrder;
  final Value<int> flags;
  const CategoriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.flags = const Value.absent(),
  });
  CategoriesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required int sortOrder,
    this.flags = const Value.absent(),
  }) : name = Value(name),
       sortOrder = Value(sortOrder);
  static Insertable<CategoryRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? sortOrder,
    Expression<int>? flags,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (flags != null) 'flags': flags,
    });
  }

  CategoriesCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<int>? sortOrder,
    Value<int>? flags,
  }) {
    return CategoriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      sortOrder: sortOrder ?? this.sortOrder,
      flags: flags ?? this.flags,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (flags.present) {
      map['flags'] = Variable<int>(flags.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('flags: $flags')
          ..write(')'))
        .toString();
  }
}

class $BookCategoriesTable extends BookCategories
    with TableInfo<$BookCategoriesTable, BookCategoryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BookCategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _bookIdMeta = const VerificationMeta('bookId');
  @override
  late final GeneratedColumn<int> bookId = GeneratedColumn<int>(
    'book_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES books (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<int> categoryId = GeneratedColumn<int>(
    'category_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES categories (id) ON DELETE CASCADE',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [bookId, categoryId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'book_categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<BookCategoryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('book_id')) {
      context.handle(
        _bookIdMeta,
        bookId.isAcceptableOrUnknown(data['book_id']!, _bookIdMeta),
      );
    } else if (isInserting) {
      context.missing(_bookIdMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {bookId, categoryId};
  @override
  BookCategoryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BookCategoryRow(
      bookId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}book_id'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}category_id'],
      )!,
    );
  }

  @override
  $BookCategoriesTable createAlias(String alias) {
    return $BookCategoriesTable(attachedDatabase, alias);
  }
}

class BookCategoryRow extends DataClass implements Insertable<BookCategoryRow> {
  final int bookId;
  final int categoryId;
  const BookCategoryRow({required this.bookId, required this.categoryId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['book_id'] = Variable<int>(bookId);
    map['category_id'] = Variable<int>(categoryId);
    return map;
  }

  BookCategoriesCompanion toCompanion(bool nullToAbsent) {
    return BookCategoriesCompanion(
      bookId: Value(bookId),
      categoryId: Value(categoryId),
    );
  }

  factory BookCategoryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BookCategoryRow(
      bookId: serializer.fromJson<int>(json['bookId']),
      categoryId: serializer.fromJson<int>(json['categoryId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'bookId': serializer.toJson<int>(bookId),
      'categoryId': serializer.toJson<int>(categoryId),
    };
  }

  BookCategoryRow copyWith({int? bookId, int? categoryId}) => BookCategoryRow(
    bookId: bookId ?? this.bookId,
    categoryId: categoryId ?? this.categoryId,
  );
  BookCategoryRow copyWithCompanion(BookCategoriesCompanion data) {
    return BookCategoryRow(
      bookId: data.bookId.present ? data.bookId.value : this.bookId,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BookCategoryRow(')
          ..write('bookId: $bookId, ')
          ..write('categoryId: $categoryId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(bookId, categoryId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BookCategoryRow &&
          other.bookId == this.bookId &&
          other.categoryId == this.categoryId);
}

class BookCategoriesCompanion extends UpdateCompanion<BookCategoryRow> {
  final Value<int> bookId;
  final Value<int> categoryId;
  final Value<int> rowid;
  const BookCategoriesCompanion({
    this.bookId = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BookCategoriesCompanion.insert({
    required int bookId,
    required int categoryId,
    this.rowid = const Value.absent(),
  }) : bookId = Value(bookId),
       categoryId = Value(categoryId);
  static Insertable<BookCategoryRow> custom({
    Expression<int>? bookId,
    Expression<int>? categoryId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (bookId != null) 'book_id': bookId,
      if (categoryId != null) 'category_id': categoryId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BookCategoriesCompanion copyWith({
    Value<int>? bookId,
    Value<int>? categoryId,
    Value<int>? rowid,
  }) {
    return BookCategoriesCompanion(
      bookId: bookId ?? this.bookId,
      categoryId: categoryId ?? this.categoryId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (bookId.present) {
      map['book_id'] = Variable<int>(bookId.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<int>(categoryId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BookCategoriesCompanion(')
          ..write('bookId: $bookId, ')
          ..write('categoryId: $categoryId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RepositoriesTable extends Repositories
    with TableInfo<$RepositoriesTable, RepositoryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RepositoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
    'url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _publicKeyMeta = const VerificationMeta(
    'publicKey',
  );
  @override
  late final GeneratedColumn<String> publicKey = GeneratedColumn<String>(
    'public_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fingerprintMeta = const VerificationMeta(
    'fingerprint',
  );
  @override
  late final GeneratedColumn<String> fingerprint = GeneratedColumn<String>(
    'fingerprint',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _etagMeta = const VerificationMeta('etag');
  @override
  late final GeneratedColumn<String> etag = GeneratedColumn<String>(
    'etag',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastFetchedAtMeta = const VerificationMeta(
    'lastFetchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastFetchedAt =
      GeneratedColumn<DateTime>(
        'last_fetched_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    url,
    name,
    publicKey,
    fingerprint,
    etag,
    lastFetchedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'repositories';
  @override
  VerificationContext validateIntegrity(
    Insertable<RepositoryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('url')) {
      context.handle(
        _urlMeta,
        url.isAcceptableOrUnknown(data['url']!, _urlMeta),
      );
    } else if (isInserting) {
      context.missing(_urlMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('public_key')) {
      context.handle(
        _publicKeyMeta,
        publicKey.isAcceptableOrUnknown(data['public_key']!, _publicKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_publicKeyMeta);
    }
    if (data.containsKey('fingerprint')) {
      context.handle(
        _fingerprintMeta,
        fingerprint.isAcceptableOrUnknown(
          data['fingerprint']!,
          _fingerprintMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fingerprintMeta);
    }
    if (data.containsKey('etag')) {
      context.handle(
        _etagMeta,
        etag.isAcceptableOrUnknown(data['etag']!, _etagMeta),
      );
    }
    if (data.containsKey('last_fetched_at')) {
      context.handle(
        _lastFetchedAtMeta,
        lastFetchedAt.isAcceptableOrUnknown(
          data['last_fetched_at']!,
          _lastFetchedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {url},
  ];
  @override
  RepositoryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RepositoryRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      url: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}url'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      publicKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}public_key'],
      )!,
      fingerprint: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fingerprint'],
      )!,
      etag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}etag'],
      ),
      lastFetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_fetched_at'],
      ),
    );
  }

  @override
  $RepositoriesTable createAlias(String alias) {
    return $RepositoriesTable(attachedDatabase, alias);
  }
}

class RepositoryRow extends DataClass implements Insertable<RepositoryRow> {
  final int id;

  /// The folder its documents sit in, as `RepositoryLocation` works it out — so the same repository
  /// reached by its project page and by its raw index is one row, not two.
  final String url;

  /// What it calls itself, from `repo.json`.
  final String name;

  /// Its Ed25519 signing key, base64, exactly as published. What signatures are checked against.
  final String publicKey;

  /// The key's fingerprint, as it was shown to the listener when they accepted it.
  ///
  /// Derived from [publicKey] and stored anyway, because it is the thing a person compared against
  /// what the repository's operator published, and re-deriving it to show again would be deriving it
  /// from whatever the key is now rather than from what they agreed to.
  final String fingerprint;

  /// What the index answered with last time, to send back as `If-None-Match`. Null until one is
  /// fetched, and null again if the repository stops sending one.
  final String? etag;
  final DateTime? lastFetchedAt;
  const RepositoryRow({
    required this.id,
    required this.url,
    required this.name,
    required this.publicKey,
    required this.fingerprint,
    this.etag,
    this.lastFetchedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['url'] = Variable<String>(url);
    map['name'] = Variable<String>(name);
    map['public_key'] = Variable<String>(publicKey);
    map['fingerprint'] = Variable<String>(fingerprint);
    if (!nullToAbsent || etag != null) {
      map['etag'] = Variable<String>(etag);
    }
    if (!nullToAbsent || lastFetchedAt != null) {
      map['last_fetched_at'] = Variable<DateTime>(lastFetchedAt);
    }
    return map;
  }

  RepositoriesCompanion toCompanion(bool nullToAbsent) {
    return RepositoriesCompanion(
      id: Value(id),
      url: Value(url),
      name: Value(name),
      publicKey: Value(publicKey),
      fingerprint: Value(fingerprint),
      etag: etag == null && nullToAbsent ? const Value.absent() : Value(etag),
      lastFetchedAt: lastFetchedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastFetchedAt),
    );
  }

  factory RepositoryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RepositoryRow(
      id: serializer.fromJson<int>(json['id']),
      url: serializer.fromJson<String>(json['url']),
      name: serializer.fromJson<String>(json['name']),
      publicKey: serializer.fromJson<String>(json['publicKey']),
      fingerprint: serializer.fromJson<String>(json['fingerprint']),
      etag: serializer.fromJson<String?>(json['etag']),
      lastFetchedAt: serializer.fromJson<DateTime?>(json['lastFetchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'url': serializer.toJson<String>(url),
      'name': serializer.toJson<String>(name),
      'publicKey': serializer.toJson<String>(publicKey),
      'fingerprint': serializer.toJson<String>(fingerprint),
      'etag': serializer.toJson<String?>(etag),
      'lastFetchedAt': serializer.toJson<DateTime?>(lastFetchedAt),
    };
  }

  RepositoryRow copyWith({
    int? id,
    String? url,
    String? name,
    String? publicKey,
    String? fingerprint,
    Value<String?> etag = const Value.absent(),
    Value<DateTime?> lastFetchedAt = const Value.absent(),
  }) => RepositoryRow(
    id: id ?? this.id,
    url: url ?? this.url,
    name: name ?? this.name,
    publicKey: publicKey ?? this.publicKey,
    fingerprint: fingerprint ?? this.fingerprint,
    etag: etag.present ? etag.value : this.etag,
    lastFetchedAt: lastFetchedAt.present
        ? lastFetchedAt.value
        : this.lastFetchedAt,
  );
  RepositoryRow copyWithCompanion(RepositoriesCompanion data) {
    return RepositoryRow(
      id: data.id.present ? data.id.value : this.id,
      url: data.url.present ? data.url.value : this.url,
      name: data.name.present ? data.name.value : this.name,
      publicKey: data.publicKey.present ? data.publicKey.value : this.publicKey,
      fingerprint: data.fingerprint.present
          ? data.fingerprint.value
          : this.fingerprint,
      etag: data.etag.present ? data.etag.value : this.etag,
      lastFetchedAt: data.lastFetchedAt.present
          ? data.lastFetchedAt.value
          : this.lastFetchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RepositoryRow(')
          ..write('id: $id, ')
          ..write('url: $url, ')
          ..write('name: $name, ')
          ..write('publicKey: $publicKey, ')
          ..write('fingerprint: $fingerprint, ')
          ..write('etag: $etag, ')
          ..write('lastFetchedAt: $lastFetchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, url, name, publicKey, fingerprint, etag, lastFetchedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RepositoryRow &&
          other.id == this.id &&
          other.url == this.url &&
          other.name == this.name &&
          other.publicKey == this.publicKey &&
          other.fingerprint == this.fingerprint &&
          other.etag == this.etag &&
          other.lastFetchedAt == this.lastFetchedAt);
}

class RepositoriesCompanion extends UpdateCompanion<RepositoryRow> {
  final Value<int> id;
  final Value<String> url;
  final Value<String> name;
  final Value<String> publicKey;
  final Value<String> fingerprint;
  final Value<String?> etag;
  final Value<DateTime?> lastFetchedAt;
  const RepositoriesCompanion({
    this.id = const Value.absent(),
    this.url = const Value.absent(),
    this.name = const Value.absent(),
    this.publicKey = const Value.absent(),
    this.fingerprint = const Value.absent(),
    this.etag = const Value.absent(),
    this.lastFetchedAt = const Value.absent(),
  });
  RepositoriesCompanion.insert({
    this.id = const Value.absent(),
    required String url,
    required String name,
    required String publicKey,
    required String fingerprint,
    this.etag = const Value.absent(),
    this.lastFetchedAt = const Value.absent(),
  }) : url = Value(url),
       name = Value(name),
       publicKey = Value(publicKey),
       fingerprint = Value(fingerprint);
  static Insertable<RepositoryRow> custom({
    Expression<int>? id,
    Expression<String>? url,
    Expression<String>? name,
    Expression<String>? publicKey,
    Expression<String>? fingerprint,
    Expression<String>? etag,
    Expression<DateTime>? lastFetchedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (url != null) 'url': url,
      if (name != null) 'name': name,
      if (publicKey != null) 'public_key': publicKey,
      if (fingerprint != null) 'fingerprint': fingerprint,
      if (etag != null) 'etag': etag,
      if (lastFetchedAt != null) 'last_fetched_at': lastFetchedAt,
    });
  }

  RepositoriesCompanion copyWith({
    Value<int>? id,
    Value<String>? url,
    Value<String>? name,
    Value<String>? publicKey,
    Value<String>? fingerprint,
    Value<String?>? etag,
    Value<DateTime?>? lastFetchedAt,
  }) {
    return RepositoriesCompanion(
      id: id ?? this.id,
      url: url ?? this.url,
      name: name ?? this.name,
      publicKey: publicKey ?? this.publicKey,
      fingerprint: fingerprint ?? this.fingerprint,
      etag: etag ?? this.etag,
      lastFetchedAt: lastFetchedAt ?? this.lastFetchedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (publicKey.present) {
      map['public_key'] = Variable<String>(publicKey.value);
    }
    if (fingerprint.present) {
      map['fingerprint'] = Variable<String>(fingerprint.value);
    }
    if (etag.present) {
      map['etag'] = Variable<String>(etag.value);
    }
    if (lastFetchedAt.present) {
      map['last_fetched_at'] = Variable<DateTime>(lastFetchedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RepositoriesCompanion(')
          ..write('id: $id, ')
          ..write('url: $url, ')
          ..write('name: $name, ')
          ..write('publicKey: $publicKey, ')
          ..write('fingerprint: $fingerprint, ')
          ..write('etag: $etag, ')
          ..write('lastFetchedAt: $lastFetchedAt')
          ..write(')'))
        .toString();
  }
}

class $ExtensionsTable extends Extensions
    with TableInfo<$ExtensionsTable, ExtensionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExtensionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<String> version = GeneratedColumn<String>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionCodeMeta = const VerificationMeta(
    'versionCode',
  );
  @override
  late final GeneratedColumn<int> versionCode = GeneratedColumn<int>(
    'version_code',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _apiVersionMeta = const VerificationMeta(
    'apiVersion',
  );
  @override
  late final GeneratedColumn<String> apiVersion = GeneratedColumn<String>(
    'api_version',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ExtensionStatus, String> status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<ExtensionStatus>($ExtensionsTable.$converterstatus);
  @override
  late final GeneratedColumnWithTypeConverter<ExtensionOrigin, String> origin =
      GeneratedColumn<String>(
        'origin',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<ExtensionOrigin>($ExtensionsTable.$converterorigin);
  static const VerificationMeta _originHandleMeta = const VerificationMeta(
    'originHandle',
  );
  @override
  late final GeneratedColumn<String> originHandle = GeneratedColumn<String>(
    'origin_handle',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _originNameMeta = const VerificationMeta(
    'originName',
  );
  @override
  late final GeneratedColumn<String> originName = GeneratedColumn<String>(
    'origin_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _installPathMeta = const VerificationMeta(
    'installPath',
  );
  @override
  late final GeneratedColumn<String> installPath = GeneratedColumn<String>(
    'install_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _installedAtMeta = const VerificationMeta(
    'installedAt',
  );
  @override
  late final GeneratedColumn<DateTime> installedAt = GeneratedColumn<DateTime>(
    'installed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    version,
    versionCode,
    apiVersion,
    status,
    origin,
    originHandle,
    originName,
    installPath,
    installedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'extensions';
  @override
  VerificationContext validateIntegrity(
    Insertable<ExtensionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    if (data.containsKey('version_code')) {
      context.handle(
        _versionCodeMeta,
        versionCode.isAcceptableOrUnknown(
          data['version_code']!,
          _versionCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_versionCodeMeta);
    }
    if (data.containsKey('api_version')) {
      context.handle(
        _apiVersionMeta,
        apiVersion.isAcceptableOrUnknown(data['api_version']!, _apiVersionMeta),
      );
    } else if (isInserting) {
      context.missing(_apiVersionMeta);
    }
    if (data.containsKey('origin_handle')) {
      context.handle(
        _originHandleMeta,
        originHandle.isAcceptableOrUnknown(
          data['origin_handle']!,
          _originHandleMeta,
        ),
      );
    }
    if (data.containsKey('origin_name')) {
      context.handle(
        _originNameMeta,
        originName.isAcceptableOrUnknown(data['origin_name']!, _originNameMeta),
      );
    }
    if (data.containsKey('install_path')) {
      context.handle(
        _installPathMeta,
        installPath.isAcceptableOrUnknown(
          data['install_path']!,
          _installPathMeta,
        ),
      );
    }
    if (data.containsKey('installed_at')) {
      context.handle(
        _installedAtMeta,
        installedAt.isAcceptableOrUnknown(
          data['installed_at']!,
          _installedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_installedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ExtensionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExtensionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}version'],
      )!,
      versionCode: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version_code'],
      )!,
      apiVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}api_version'],
      )!,
      status: $ExtensionsTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      origin: $ExtensionsTable.$converterorigin.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}origin'],
        )!,
      ),
      originHandle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin_handle'],
      ),
      originName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin_name'],
      ),
      installPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}install_path'],
      ),
      installedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}installed_at'],
      )!,
    );
  }

  @override
  $ExtensionsTable createAlias(String alias) {
    return $ExtensionsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<ExtensionStatus, String, String> $converterstatus =
      const EnumNameConverter<ExtensionStatus>(ExtensionStatus.values);
  static JsonTypeConverter2<ExtensionOrigin, String, String> $converterorigin =
      const EnumNameConverter<ExtensionOrigin>(ExtensionOrigin.values);
}

class ExtensionRow extends DataClass implements Insertable<ExtensionRow> {
  /// The extension's own id, as its manifest gives it: `org.example.librivox`. Never a surrogate,
  /// because this is the id the manifest, the sources and the stored preferences all use.
  final String id;

  /// What the listener sees, from the manifest. Kept here so the Extensions screen can be shown
  /// before any manifest is read again.
  final String name;
  final String version;

  /// What orders versions: an update is a higher number, whatever `version` says (§3.3).
  final int versionCode;
  final String apiVersion;

  /// Whether it may run, and if not why (§3.8). A folder install is `untrusted`, which is this app
  /// saying that nothing proved the code is what the author published.
  final ExtensionStatus status;

  /// Where it came from, which is also how it is read again.
  final ExtensionOrigin origin;

  /// How to reach that origin again: the handle of the folder it was installed from, as
  /// `UserFolders.open` takes one. Null for the extension that ships inside the app.
  final String? originHandle;

  /// What to call the origin to the listener: a folder's path on desktop, its own name on Android.
  final String? originName;

  /// Where the app's copy of the files is, relative to the folder installed extensions are kept in
  /// (§3.9's versioned directory). Null for the extension that ships inside the app, whose files are
  /// assets.
  ///
  /// Relative for the reason a cover's path is relative: on iOS the app's container moves when the
  /// app is updated or reinstalled.
  final String? installPath;
  final DateTime installedAt;
  const ExtensionRow({
    required this.id,
    required this.name,
    required this.version,
    required this.versionCode,
    required this.apiVersion,
    required this.status,
    required this.origin,
    this.originHandle,
    this.originName,
    this.installPath,
    required this.installedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['version'] = Variable<String>(version);
    map['version_code'] = Variable<int>(versionCode);
    map['api_version'] = Variable<String>(apiVersion);
    {
      map['status'] = Variable<String>(
        $ExtensionsTable.$converterstatus.toSql(status),
      );
    }
    {
      map['origin'] = Variable<String>(
        $ExtensionsTable.$converterorigin.toSql(origin),
      );
    }
    if (!nullToAbsent || originHandle != null) {
      map['origin_handle'] = Variable<String>(originHandle);
    }
    if (!nullToAbsent || originName != null) {
      map['origin_name'] = Variable<String>(originName);
    }
    if (!nullToAbsent || installPath != null) {
      map['install_path'] = Variable<String>(installPath);
    }
    map['installed_at'] = Variable<DateTime>(installedAt);
    return map;
  }

  ExtensionsCompanion toCompanion(bool nullToAbsent) {
    return ExtensionsCompanion(
      id: Value(id),
      name: Value(name),
      version: Value(version),
      versionCode: Value(versionCode),
      apiVersion: Value(apiVersion),
      status: Value(status),
      origin: Value(origin),
      originHandle: originHandle == null && nullToAbsent
          ? const Value.absent()
          : Value(originHandle),
      originName: originName == null && nullToAbsent
          ? const Value.absent()
          : Value(originName),
      installPath: installPath == null && nullToAbsent
          ? const Value.absent()
          : Value(installPath),
      installedAt: Value(installedAt),
    );
  }

  factory ExtensionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExtensionRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      version: serializer.fromJson<String>(json['version']),
      versionCode: serializer.fromJson<int>(json['versionCode']),
      apiVersion: serializer.fromJson<String>(json['apiVersion']),
      status: $ExtensionsTable.$converterstatus.fromJson(
        serializer.fromJson<String>(json['status']),
      ),
      origin: $ExtensionsTable.$converterorigin.fromJson(
        serializer.fromJson<String>(json['origin']),
      ),
      originHandle: serializer.fromJson<String?>(json['originHandle']),
      originName: serializer.fromJson<String?>(json['originName']),
      installPath: serializer.fromJson<String?>(json['installPath']),
      installedAt: serializer.fromJson<DateTime>(json['installedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'version': serializer.toJson<String>(version),
      'versionCode': serializer.toJson<int>(versionCode),
      'apiVersion': serializer.toJson<String>(apiVersion),
      'status': serializer.toJson<String>(
        $ExtensionsTable.$converterstatus.toJson(status),
      ),
      'origin': serializer.toJson<String>(
        $ExtensionsTable.$converterorigin.toJson(origin),
      ),
      'originHandle': serializer.toJson<String?>(originHandle),
      'originName': serializer.toJson<String?>(originName),
      'installPath': serializer.toJson<String?>(installPath),
      'installedAt': serializer.toJson<DateTime>(installedAt),
    };
  }

  ExtensionRow copyWith({
    String? id,
    String? name,
    String? version,
    int? versionCode,
    String? apiVersion,
    ExtensionStatus? status,
    ExtensionOrigin? origin,
    Value<String?> originHandle = const Value.absent(),
    Value<String?> originName = const Value.absent(),
    Value<String?> installPath = const Value.absent(),
    DateTime? installedAt,
  }) => ExtensionRow(
    id: id ?? this.id,
    name: name ?? this.name,
    version: version ?? this.version,
    versionCode: versionCode ?? this.versionCode,
    apiVersion: apiVersion ?? this.apiVersion,
    status: status ?? this.status,
    origin: origin ?? this.origin,
    originHandle: originHandle.present ? originHandle.value : this.originHandle,
    originName: originName.present ? originName.value : this.originName,
    installPath: installPath.present ? installPath.value : this.installPath,
    installedAt: installedAt ?? this.installedAt,
  );
  ExtensionRow copyWithCompanion(ExtensionsCompanion data) {
    return ExtensionRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      version: data.version.present ? data.version.value : this.version,
      versionCode: data.versionCode.present
          ? data.versionCode.value
          : this.versionCode,
      apiVersion: data.apiVersion.present
          ? data.apiVersion.value
          : this.apiVersion,
      status: data.status.present ? data.status.value : this.status,
      origin: data.origin.present ? data.origin.value : this.origin,
      originHandle: data.originHandle.present
          ? data.originHandle.value
          : this.originHandle,
      originName: data.originName.present
          ? data.originName.value
          : this.originName,
      installPath: data.installPath.present
          ? data.installPath.value
          : this.installPath,
      installedAt: data.installedAt.present
          ? data.installedAt.value
          : this.installedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExtensionRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('version: $version, ')
          ..write('versionCode: $versionCode, ')
          ..write('apiVersion: $apiVersion, ')
          ..write('status: $status, ')
          ..write('origin: $origin, ')
          ..write('originHandle: $originHandle, ')
          ..write('originName: $originName, ')
          ..write('installPath: $installPath, ')
          ..write('installedAt: $installedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    version,
    versionCode,
    apiVersion,
    status,
    origin,
    originHandle,
    originName,
    installPath,
    installedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExtensionRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.version == this.version &&
          other.versionCode == this.versionCode &&
          other.apiVersion == this.apiVersion &&
          other.status == this.status &&
          other.origin == this.origin &&
          other.originHandle == this.originHandle &&
          other.originName == this.originName &&
          other.installPath == this.installPath &&
          other.installedAt == this.installedAt);
}

class ExtensionsCompanion extends UpdateCompanion<ExtensionRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> version;
  final Value<int> versionCode;
  final Value<String> apiVersion;
  final Value<ExtensionStatus> status;
  final Value<ExtensionOrigin> origin;
  final Value<String?> originHandle;
  final Value<String?> originName;
  final Value<String?> installPath;
  final Value<DateTime> installedAt;
  final Value<int> rowid;
  const ExtensionsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.version = const Value.absent(),
    this.versionCode = const Value.absent(),
    this.apiVersion = const Value.absent(),
    this.status = const Value.absent(),
    this.origin = const Value.absent(),
    this.originHandle = const Value.absent(),
    this.originName = const Value.absent(),
    this.installPath = const Value.absent(),
    this.installedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExtensionsCompanion.insert({
    required String id,
    required String name,
    required String version,
    required int versionCode,
    required String apiVersion,
    required ExtensionStatus status,
    required ExtensionOrigin origin,
    this.originHandle = const Value.absent(),
    this.originName = const Value.absent(),
    this.installPath = const Value.absent(),
    required DateTime installedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       version = Value(version),
       versionCode = Value(versionCode),
       apiVersion = Value(apiVersion),
       status = Value(status),
       origin = Value(origin),
       installedAt = Value(installedAt);
  static Insertable<ExtensionRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? version,
    Expression<int>? versionCode,
    Expression<String>? apiVersion,
    Expression<String>? status,
    Expression<String>? origin,
    Expression<String>? originHandle,
    Expression<String>? originName,
    Expression<String>? installPath,
    Expression<DateTime>? installedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (version != null) 'version': version,
      if (versionCode != null) 'version_code': versionCode,
      if (apiVersion != null) 'api_version': apiVersion,
      if (status != null) 'status': status,
      if (origin != null) 'origin': origin,
      if (originHandle != null) 'origin_handle': originHandle,
      if (originName != null) 'origin_name': originName,
      if (installPath != null) 'install_path': installPath,
      if (installedAt != null) 'installed_at': installedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExtensionsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? version,
    Value<int>? versionCode,
    Value<String>? apiVersion,
    Value<ExtensionStatus>? status,
    Value<ExtensionOrigin>? origin,
    Value<String?>? originHandle,
    Value<String?>? originName,
    Value<String?>? installPath,
    Value<DateTime>? installedAt,
    Value<int>? rowid,
  }) {
    return ExtensionsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      version: version ?? this.version,
      versionCode: versionCode ?? this.versionCode,
      apiVersion: apiVersion ?? this.apiVersion,
      status: status ?? this.status,
      origin: origin ?? this.origin,
      originHandle: originHandle ?? this.originHandle,
      originName: originName ?? this.originName,
      installPath: installPath ?? this.installPath,
      installedAt: installedAt ?? this.installedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (version.present) {
      map['version'] = Variable<String>(version.value);
    }
    if (versionCode.present) {
      map['version_code'] = Variable<int>(versionCode.value);
    }
    if (apiVersion.present) {
      map['api_version'] = Variable<String>(apiVersion.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $ExtensionsTable.$converterstatus.toSql(status.value),
      );
    }
    if (origin.present) {
      map['origin'] = Variable<String>(
        $ExtensionsTable.$converterorigin.toSql(origin.value),
      );
    }
    if (originHandle.present) {
      map['origin_handle'] = Variable<String>(originHandle.value);
    }
    if (originName.present) {
      map['origin_name'] = Variable<String>(originName.value);
    }
    if (installPath.present) {
      map['install_path'] = Variable<String>(installPath.value);
    }
    if (installedAt.present) {
      map['installed_at'] = Variable<DateTime>(installedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExtensionsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('version: $version, ')
          ..write('versionCode: $versionCode, ')
          ..write('apiVersion: $apiVersion, ')
          ..write('status: $status, ')
          ..write('origin: $origin, ')
          ..write('originHandle: $originHandle, ')
          ..write('originName: $originName, ')
          ..write('installPath: $installPath, ')
          ..write('installedAt: $installedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ExtensionPreferencesTable extends ExtensionPreferences
    with TableInfo<$ExtensionPreferencesTable, ExtensionPreferenceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExtensionPreferencesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _extensionIdMeta = const VerificationMeta(
    'extensionId',
  );
  @override
  late final GeneratedColumn<String> extensionId = GeneratedColumn<String>(
    'extension_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [extensionId, key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'extension_preferences';
  @override
  VerificationContext validateIntegrity(
    Insertable<ExtensionPreferenceRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('extension_id')) {
      context.handle(
        _extensionIdMeta,
        extensionId.isAcceptableOrUnknown(
          data['extension_id']!,
          _extensionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_extensionIdMeta);
    }
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {extensionId, key};
  @override
  ExtensionPreferenceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExtensionPreferenceRow(
      extensionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}extension_id'],
      )!,
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $ExtensionPreferencesTable createAlias(String alias) {
    return $ExtensionPreferencesTable(attachedDatabase, alias);
  }
}

class ExtensionPreferenceRow extends DataClass
    implements Insertable<ExtensionPreferenceRow> {
  final String extensionId;
  final String key;
  final String value;
  const ExtensionPreferenceRow({
    required this.extensionId,
    required this.key,
    required this.value,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['extension_id'] = Variable<String>(extensionId);
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  ExtensionPreferencesCompanion toCompanion(bool nullToAbsent) {
    return ExtensionPreferencesCompanion(
      extensionId: Value(extensionId),
      key: Value(key),
      value: Value(value),
    );
  }

  factory ExtensionPreferenceRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExtensionPreferenceRow(
      extensionId: serializer.fromJson<String>(json['extensionId']),
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'extensionId': serializer.toJson<String>(extensionId),
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  ExtensionPreferenceRow copyWith({
    String? extensionId,
    String? key,
    String? value,
  }) => ExtensionPreferenceRow(
    extensionId: extensionId ?? this.extensionId,
    key: key ?? this.key,
    value: value ?? this.value,
  );
  ExtensionPreferenceRow copyWithCompanion(ExtensionPreferencesCompanion data) {
    return ExtensionPreferenceRow(
      extensionId: data.extensionId.present
          ? data.extensionId.value
          : this.extensionId,
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExtensionPreferenceRow(')
          ..write('extensionId: $extensionId, ')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(extensionId, key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExtensionPreferenceRow &&
          other.extensionId == this.extensionId &&
          other.key == this.key &&
          other.value == this.value);
}

class ExtensionPreferencesCompanion
    extends UpdateCompanion<ExtensionPreferenceRow> {
  final Value<String> extensionId;
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const ExtensionPreferencesCompanion({
    this.extensionId = const Value.absent(),
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExtensionPreferencesCompanion.insert({
    required String extensionId,
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : extensionId = Value(extensionId),
       key = Value(key),
       value = Value(value);
  static Insertable<ExtensionPreferenceRow> custom({
    Expression<String>? extensionId,
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (extensionId != null) 'extension_id': extensionId,
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExtensionPreferencesCompanion copyWith({
    Value<String>? extensionId,
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return ExtensionPreferencesCompanion(
      extensionId: extensionId ?? this.extensionId,
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (extensionId.present) {
      map['extension_id'] = Variable<String>(extensionId.value);
    }
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExtensionPreferencesCompanion(')
          ..write('extensionId: $extensionId, ')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DownloadTasksTable extends DownloadTasks
    with TableInfo<$DownloadTasksTable, DownloadTaskRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DownloadTasksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _mediaFileIdMeta = const VerificationMeta(
    'mediaFileId',
  );
  @override
  late final GeneratedColumn<int> mediaFileId = GeneratedColumn<int>(
    'media_file_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES media_files (id) ON DELETE CASCADE',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<DownloadState, String> state =
      GeneratedColumn<String>(
        'state',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<DownloadState>($DownloadTasksTable.$converterstate);
  @override
  late final GeneratedColumnWithTypeConverter<DownloadHold?, String> hold =
      GeneratedColumn<String>(
        'hold',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<DownloadHold?>($DownloadTasksTable.$converterholdn);
  static const VerificationMeta _priorityMeta = const VerificationMeta(
    'priority',
  );
  @override
  late final GeneratedColumn<int> priority = GeneratedColumn<int>(
    'priority',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _bytesDoneMeta = const VerificationMeta(
    'bytesDone',
  );
  @override
  late final GeneratedColumn<int> bytesDone = GeneratedColumn<int>(
    'bytes_done',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _bytesTotalMeta = const VerificationMeta(
    'bytesTotal',
  );
  @override
  late final GeneratedColumn<int> bytesTotal = GeneratedColumn<int>(
    'bytes_total',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DownloadRequest?, String>
  requestSnapshot =
      GeneratedColumn<String>(
        'request_snapshot',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<DownloadRequest?>(
        $DownloadTasksTable.$converterrequestSnapshotn,
      );
  static const VerificationMeta _expiresAtMeta = const VerificationMeta(
    'expiresAt',
  );
  @override
  late final GeneratedColumn<DateTime> expiresAt = GeneratedColumn<DateTime>(
    'expires_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _retryAtMeta = const VerificationMeta(
    'retryAt',
  );
  @override
  late final GeneratedColumn<DateTime> retryAt = GeneratedColumn<DateTime>(
    'retry_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _transportTaskIdMeta = const VerificationMeta(
    'transportTaskId',
  );
  @override
  late final GeneratedColumn<String> transportTaskId = GeneratedColumn<String>(
    'transport_task_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    mediaFileId,
    state,
    hold,
    priority,
    bytesDone,
    bytesTotal,
    requestSnapshot,
    expiresAt,
    attempts,
    retryAt,
    lastError,
    transportTaskId,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'download_tasks';
  @override
  VerificationContext validateIntegrity(
    Insertable<DownloadTaskRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('media_file_id')) {
      context.handle(
        _mediaFileIdMeta,
        mediaFileId.isAcceptableOrUnknown(
          data['media_file_id']!,
          _mediaFileIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_mediaFileIdMeta);
    }
    if (data.containsKey('priority')) {
      context.handle(
        _priorityMeta,
        priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta),
      );
    }
    if (data.containsKey('bytes_done')) {
      context.handle(
        _bytesDoneMeta,
        bytesDone.isAcceptableOrUnknown(data['bytes_done']!, _bytesDoneMeta),
      );
    }
    if (data.containsKey('bytes_total')) {
      context.handle(
        _bytesTotalMeta,
        bytesTotal.isAcceptableOrUnknown(data['bytes_total']!, _bytesTotalMeta),
      );
    }
    if (data.containsKey('expires_at')) {
      context.handle(
        _expiresAtMeta,
        expiresAt.isAcceptableOrUnknown(data['expires_at']!, _expiresAtMeta),
      );
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    if (data.containsKey('retry_at')) {
      context.handle(
        _retryAtMeta,
        retryAt.isAcceptableOrUnknown(data['retry_at']!, _retryAtMeta),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    if (data.containsKey('transport_task_id')) {
      context.handle(
        _transportTaskIdMeta,
        transportTaskId.isAcceptableOrUnknown(
          data['transport_task_id']!,
          _transportTaskIdMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {mediaFileId},
  ];
  @override
  DownloadTaskRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DownloadTaskRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      mediaFileId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}media_file_id'],
      )!,
      state: $DownloadTasksTable.$converterstate.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}state'],
        )!,
      ),
      hold: $DownloadTasksTable.$converterholdn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}hold'],
        ),
      ),
      priority: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}priority'],
      )!,
      bytesDone: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}bytes_done'],
      )!,
      bytesTotal: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}bytes_total'],
      ),
      requestSnapshot: $DownloadTasksTable.$converterrequestSnapshotn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}request_snapshot'],
        ),
      ),
      expiresAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}expires_at'],
      ),
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      retryAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}retry_at'],
      ),
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
      transportTaskId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transport_task_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $DownloadTasksTable createAlias(String alias) {
    return $DownloadTasksTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<DownloadState, String, String> $converterstate =
      const EnumNameConverter<DownloadState>(DownloadState.values);
  static JsonTypeConverter2<DownloadHold, String, String> $converterhold =
      const EnumNameConverter<DownloadHold>(DownloadHold.values);
  static JsonTypeConverter2<DownloadHold?, String?, String?> $converterholdn =
      JsonTypeConverter2.asNullable($converterhold);
  static TypeConverter<DownloadRequest, String> $converterrequestSnapshot =
      const DownloadRequestConverter();
  static TypeConverter<DownloadRequest?, String?> $converterrequestSnapshotn =
      NullAwareTypeConverter.wrap($converterrequestSnapshot);
}

class DownloadTaskRow extends DataClass implements Insertable<DownloadTaskRow> {
  final int id;

  /// The file to fetch. Cascading: a file that is no longer part of any book has nothing to download.
  final int mediaFileId;
  final DownloadState state;

  /// Why a `waiting` task is waiting, and null in every other state. Kept apart from [state] so a
  /// screen can say "waiting for Wi-Fi" rather than "waiting" (§5.2).
  final DownloadHold? hold;

  /// What the scheduler picks first. Higher runs sooner; the chapter about to be played is raised
  /// above the rest of its book.
  final int priority;
  final int bytesDone;

  /// What the site said the whole file is, once it has said. Null until then, because a progress bar
  /// that guesses is worse than one that waits.
  final int? bytesTotal;

  /// The resolved URL and headers, written down as the file is about to start (§5.4). Null until the
  /// first resolution, and stale after [expiresAt].
  final DownloadRequest? requestSnapshot;

  /// When [requestSnapshot] stops being usable, as the source said. Null when the source gave no
  /// expiry, which does not mean the URL is eternal — a 403 or a 410 sends it back to be resolved
  /// either way.
  final DateTime? expiresAt;

  /// How many times this file has failed in a way that might not fail again (§5.5). Five ends it.
  /// A URL that merely expired does not count here: that is the source working as designed.
  final int attempts;

  /// When a `failedRetryable` task may join the queue again.
  ///
  /// Not in §4.3's column list, but the backoff has to outlive the process or a phone that was
  /// killed mid-queue would retry everything the moment it came back, which is the behaviour the
  /// jitter exists to prevent.
  final DateTime? retryAt;

  /// What went wrong last, for the listener and for a bug report. Never the explanation on its own.
  final String? lastError;

  /// What the transport calls this task, so the reconciler can match its live tasks to these rows at
  /// launch and repair the drift (§5.2).
  final String? transportTaskId;
  final DateTime createdAt;
  final DateTime updatedAt;
  const DownloadTaskRow({
    required this.id,
    required this.mediaFileId,
    required this.state,
    this.hold,
    required this.priority,
    required this.bytesDone,
    this.bytesTotal,
    this.requestSnapshot,
    this.expiresAt,
    required this.attempts,
    this.retryAt,
    this.lastError,
    this.transportTaskId,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['media_file_id'] = Variable<int>(mediaFileId);
    {
      map['state'] = Variable<String>(
        $DownloadTasksTable.$converterstate.toSql(state),
      );
    }
    if (!nullToAbsent || hold != null) {
      map['hold'] = Variable<String>(
        $DownloadTasksTable.$converterholdn.toSql(hold),
      );
    }
    map['priority'] = Variable<int>(priority);
    map['bytes_done'] = Variable<int>(bytesDone);
    if (!nullToAbsent || bytesTotal != null) {
      map['bytes_total'] = Variable<int>(bytesTotal);
    }
    if (!nullToAbsent || requestSnapshot != null) {
      map['request_snapshot'] = Variable<String>(
        $DownloadTasksTable.$converterrequestSnapshotn.toSql(requestSnapshot),
      );
    }
    if (!nullToAbsent || expiresAt != null) {
      map['expires_at'] = Variable<DateTime>(expiresAt);
    }
    map['attempts'] = Variable<int>(attempts);
    if (!nullToAbsent || retryAt != null) {
      map['retry_at'] = Variable<DateTime>(retryAt);
    }
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    if (!nullToAbsent || transportTaskId != null) {
      map['transport_task_id'] = Variable<String>(transportTaskId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  DownloadTasksCompanion toCompanion(bool nullToAbsent) {
    return DownloadTasksCompanion(
      id: Value(id),
      mediaFileId: Value(mediaFileId),
      state: Value(state),
      hold: hold == null && nullToAbsent ? const Value.absent() : Value(hold),
      priority: Value(priority),
      bytesDone: Value(bytesDone),
      bytesTotal: bytesTotal == null && nullToAbsent
          ? const Value.absent()
          : Value(bytesTotal),
      requestSnapshot: requestSnapshot == null && nullToAbsent
          ? const Value.absent()
          : Value(requestSnapshot),
      expiresAt: expiresAt == null && nullToAbsent
          ? const Value.absent()
          : Value(expiresAt),
      attempts: Value(attempts),
      retryAt: retryAt == null && nullToAbsent
          ? const Value.absent()
          : Value(retryAt),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      transportTaskId: transportTaskId == null && nullToAbsent
          ? const Value.absent()
          : Value(transportTaskId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory DownloadTaskRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DownloadTaskRow(
      id: serializer.fromJson<int>(json['id']),
      mediaFileId: serializer.fromJson<int>(json['mediaFileId']),
      state: $DownloadTasksTable.$converterstate.fromJson(
        serializer.fromJson<String>(json['state']),
      ),
      hold: $DownloadTasksTable.$converterholdn.fromJson(
        serializer.fromJson<String?>(json['hold']),
      ),
      priority: serializer.fromJson<int>(json['priority']),
      bytesDone: serializer.fromJson<int>(json['bytesDone']),
      bytesTotal: serializer.fromJson<int?>(json['bytesTotal']),
      requestSnapshot: serializer.fromJson<DownloadRequest?>(
        json['requestSnapshot'],
      ),
      expiresAt: serializer.fromJson<DateTime?>(json['expiresAt']),
      attempts: serializer.fromJson<int>(json['attempts']),
      retryAt: serializer.fromJson<DateTime?>(json['retryAt']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      transportTaskId: serializer.fromJson<String?>(json['transportTaskId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'mediaFileId': serializer.toJson<int>(mediaFileId),
      'state': serializer.toJson<String>(
        $DownloadTasksTable.$converterstate.toJson(state),
      ),
      'hold': serializer.toJson<String?>(
        $DownloadTasksTable.$converterholdn.toJson(hold),
      ),
      'priority': serializer.toJson<int>(priority),
      'bytesDone': serializer.toJson<int>(bytesDone),
      'bytesTotal': serializer.toJson<int?>(bytesTotal),
      'requestSnapshot': serializer.toJson<DownloadRequest?>(requestSnapshot),
      'expiresAt': serializer.toJson<DateTime?>(expiresAt),
      'attempts': serializer.toJson<int>(attempts),
      'retryAt': serializer.toJson<DateTime?>(retryAt),
      'lastError': serializer.toJson<String?>(lastError),
      'transportTaskId': serializer.toJson<String?>(transportTaskId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  DownloadTaskRow copyWith({
    int? id,
    int? mediaFileId,
    DownloadState? state,
    Value<DownloadHold?> hold = const Value.absent(),
    int? priority,
    int? bytesDone,
    Value<int?> bytesTotal = const Value.absent(),
    Value<DownloadRequest?> requestSnapshot = const Value.absent(),
    Value<DateTime?> expiresAt = const Value.absent(),
    int? attempts,
    Value<DateTime?> retryAt = const Value.absent(),
    Value<String?> lastError = const Value.absent(),
    Value<String?> transportTaskId = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => DownloadTaskRow(
    id: id ?? this.id,
    mediaFileId: mediaFileId ?? this.mediaFileId,
    state: state ?? this.state,
    hold: hold.present ? hold.value : this.hold,
    priority: priority ?? this.priority,
    bytesDone: bytesDone ?? this.bytesDone,
    bytesTotal: bytesTotal.present ? bytesTotal.value : this.bytesTotal,
    requestSnapshot: requestSnapshot.present
        ? requestSnapshot.value
        : this.requestSnapshot,
    expiresAt: expiresAt.present ? expiresAt.value : this.expiresAt,
    attempts: attempts ?? this.attempts,
    retryAt: retryAt.present ? retryAt.value : this.retryAt,
    lastError: lastError.present ? lastError.value : this.lastError,
    transportTaskId: transportTaskId.present
        ? transportTaskId.value
        : this.transportTaskId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  DownloadTaskRow copyWithCompanion(DownloadTasksCompanion data) {
    return DownloadTaskRow(
      id: data.id.present ? data.id.value : this.id,
      mediaFileId: data.mediaFileId.present
          ? data.mediaFileId.value
          : this.mediaFileId,
      state: data.state.present ? data.state.value : this.state,
      hold: data.hold.present ? data.hold.value : this.hold,
      priority: data.priority.present ? data.priority.value : this.priority,
      bytesDone: data.bytesDone.present ? data.bytesDone.value : this.bytesDone,
      bytesTotal: data.bytesTotal.present
          ? data.bytesTotal.value
          : this.bytesTotal,
      requestSnapshot: data.requestSnapshot.present
          ? data.requestSnapshot.value
          : this.requestSnapshot,
      expiresAt: data.expiresAt.present ? data.expiresAt.value : this.expiresAt,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      retryAt: data.retryAt.present ? data.retryAt.value : this.retryAt,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      transportTaskId: data.transportTaskId.present
          ? data.transportTaskId.value
          : this.transportTaskId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DownloadTaskRow(')
          ..write('id: $id, ')
          ..write('mediaFileId: $mediaFileId, ')
          ..write('state: $state, ')
          ..write('hold: $hold, ')
          ..write('priority: $priority, ')
          ..write('bytesDone: $bytesDone, ')
          ..write('bytesTotal: $bytesTotal, ')
          ..write('requestSnapshot: $requestSnapshot, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('attempts: $attempts, ')
          ..write('retryAt: $retryAt, ')
          ..write('lastError: $lastError, ')
          ..write('transportTaskId: $transportTaskId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    mediaFileId,
    state,
    hold,
    priority,
    bytesDone,
    bytesTotal,
    requestSnapshot,
    expiresAt,
    attempts,
    retryAt,
    lastError,
    transportTaskId,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DownloadTaskRow &&
          other.id == this.id &&
          other.mediaFileId == this.mediaFileId &&
          other.state == this.state &&
          other.hold == this.hold &&
          other.priority == this.priority &&
          other.bytesDone == this.bytesDone &&
          other.bytesTotal == this.bytesTotal &&
          other.requestSnapshot == this.requestSnapshot &&
          other.expiresAt == this.expiresAt &&
          other.attempts == this.attempts &&
          other.retryAt == this.retryAt &&
          other.lastError == this.lastError &&
          other.transportTaskId == this.transportTaskId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class DownloadTasksCompanion extends UpdateCompanion<DownloadTaskRow> {
  final Value<int> id;
  final Value<int> mediaFileId;
  final Value<DownloadState> state;
  final Value<DownloadHold?> hold;
  final Value<int> priority;
  final Value<int> bytesDone;
  final Value<int?> bytesTotal;
  final Value<DownloadRequest?> requestSnapshot;
  final Value<DateTime?> expiresAt;
  final Value<int> attempts;
  final Value<DateTime?> retryAt;
  final Value<String?> lastError;
  final Value<String?> transportTaskId;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const DownloadTasksCompanion({
    this.id = const Value.absent(),
    this.mediaFileId = const Value.absent(),
    this.state = const Value.absent(),
    this.hold = const Value.absent(),
    this.priority = const Value.absent(),
    this.bytesDone = const Value.absent(),
    this.bytesTotal = const Value.absent(),
    this.requestSnapshot = const Value.absent(),
    this.expiresAt = const Value.absent(),
    this.attempts = const Value.absent(),
    this.retryAt = const Value.absent(),
    this.lastError = const Value.absent(),
    this.transportTaskId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  DownloadTasksCompanion.insert({
    this.id = const Value.absent(),
    required int mediaFileId,
    required DownloadState state,
    this.hold = const Value.absent(),
    this.priority = const Value.absent(),
    this.bytesDone = const Value.absent(),
    this.bytesTotal = const Value.absent(),
    this.requestSnapshot = const Value.absent(),
    this.expiresAt = const Value.absent(),
    this.attempts = const Value.absent(),
    this.retryAt = const Value.absent(),
    this.lastError = const Value.absent(),
    this.transportTaskId = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : mediaFileId = Value(mediaFileId),
       state = Value(state),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<DownloadTaskRow> custom({
    Expression<int>? id,
    Expression<int>? mediaFileId,
    Expression<String>? state,
    Expression<String>? hold,
    Expression<int>? priority,
    Expression<int>? bytesDone,
    Expression<int>? bytesTotal,
    Expression<String>? requestSnapshot,
    Expression<DateTime>? expiresAt,
    Expression<int>? attempts,
    Expression<DateTime>? retryAt,
    Expression<String>? lastError,
    Expression<String>? transportTaskId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (mediaFileId != null) 'media_file_id': mediaFileId,
      if (state != null) 'state': state,
      if (hold != null) 'hold': hold,
      if (priority != null) 'priority': priority,
      if (bytesDone != null) 'bytes_done': bytesDone,
      if (bytesTotal != null) 'bytes_total': bytesTotal,
      if (requestSnapshot != null) 'request_snapshot': requestSnapshot,
      if (expiresAt != null) 'expires_at': expiresAt,
      if (attempts != null) 'attempts': attempts,
      if (retryAt != null) 'retry_at': retryAt,
      if (lastError != null) 'last_error': lastError,
      if (transportTaskId != null) 'transport_task_id': transportTaskId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  DownloadTasksCompanion copyWith({
    Value<int>? id,
    Value<int>? mediaFileId,
    Value<DownloadState>? state,
    Value<DownloadHold?>? hold,
    Value<int>? priority,
    Value<int>? bytesDone,
    Value<int?>? bytesTotal,
    Value<DownloadRequest?>? requestSnapshot,
    Value<DateTime?>? expiresAt,
    Value<int>? attempts,
    Value<DateTime?>? retryAt,
    Value<String?>? lastError,
    Value<String?>? transportTaskId,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return DownloadTasksCompanion(
      id: id ?? this.id,
      mediaFileId: mediaFileId ?? this.mediaFileId,
      state: state ?? this.state,
      hold: hold ?? this.hold,
      priority: priority ?? this.priority,
      bytesDone: bytesDone ?? this.bytesDone,
      bytesTotal: bytesTotal ?? this.bytesTotal,
      requestSnapshot: requestSnapshot ?? this.requestSnapshot,
      expiresAt: expiresAt ?? this.expiresAt,
      attempts: attempts ?? this.attempts,
      retryAt: retryAt ?? this.retryAt,
      lastError: lastError ?? this.lastError,
      transportTaskId: transportTaskId ?? this.transportTaskId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (mediaFileId.present) {
      map['media_file_id'] = Variable<int>(mediaFileId.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(
        $DownloadTasksTable.$converterstate.toSql(state.value),
      );
    }
    if (hold.present) {
      map['hold'] = Variable<String>(
        $DownloadTasksTable.$converterholdn.toSql(hold.value),
      );
    }
    if (priority.present) {
      map['priority'] = Variable<int>(priority.value);
    }
    if (bytesDone.present) {
      map['bytes_done'] = Variable<int>(bytesDone.value);
    }
    if (bytesTotal.present) {
      map['bytes_total'] = Variable<int>(bytesTotal.value);
    }
    if (requestSnapshot.present) {
      map['request_snapshot'] = Variable<String>(
        $DownloadTasksTable.$converterrequestSnapshotn.toSql(
          requestSnapshot.value,
        ),
      );
    }
    if (expiresAt.present) {
      map['expires_at'] = Variable<DateTime>(expiresAt.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (retryAt.present) {
      map['retry_at'] = Variable<DateTime>(retryAt.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (transportTaskId.present) {
      map['transport_task_id'] = Variable<String>(transportTaskId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DownloadTasksCompanion(')
          ..write('id: $id, ')
          ..write('mediaFileId: $mediaFileId, ')
          ..write('state: $state, ')
          ..write('hold: $hold, ')
          ..write('priority: $priority, ')
          ..write('bytesDone: $bytesDone, ')
          ..write('bytesTotal: $bytesTotal, ')
          ..write('requestSnapshot: $requestSnapshot, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('attempts: $attempts, ')
          ..write('retryAt: $retryAt, ')
          ..write('lastError: $lastError, ')
          ..write('transportTaskId: $transportTaskId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$KikuyomiDatabase extends GeneratedDatabase {
  _$KikuyomiDatabase(QueryExecutor e) : super(e);
  $KikuyomiDatabaseManager get managers => $KikuyomiDatabaseManager(this);
  late final $SourcesTable sources = $SourcesTable(this);
  late final $BooksTable books = $BooksTable(this);
  late final $PeopleTable people = $PeopleTable(this);
  late final $BookPeopleTable bookPeople = $BookPeopleTable(this);
  late final $ChaptersTable chapters = $ChaptersTable(this);
  late final $MediaFilesTable mediaFiles = $MediaFilesTable(this);
  late final $ChapterSegmentsTable chapterSegments = $ChapterSegmentsTable(
    this,
  );
  late final $PlaybackStatesTable playbackStates = $PlaybackStatesTable(this);
  late final $ReadingStatesTable readingStates = $ReadingStatesTable(this);
  late final $ReadingSessionsTable readingSessions = $ReadingSessionsTable(
    this,
  );
  late final $ListeningSessionsTable listeningSessions =
      $ListeningSessionsTable(this);
  late final $BookmarksTable bookmarks = $BookmarksTable(this);
  late final $CategoriesTable categories = $CategoriesTable(this);
  late final $BookCategoriesTable bookCategories = $BookCategoriesTable(this);
  late final $RepositoriesTable repositories = $RepositoriesTable(this);
  late final $ExtensionsTable extensions = $ExtensionsTable(this);
  late final $ExtensionPreferencesTable extensionPreferences =
      $ExtensionPreferencesTable(this);
  late final $DownloadTasksTable downloadTasks = $DownloadTasksTable(this);
  late final Index booksLibrary = Index(
    'books_library',
    'CREATE INDEX books_library ON books (in_library, date_added)',
  );
  late final Index chaptersOrder = Index(
    'chapters_order',
    'CREATE INDEX chapters_order ON chapters (book_id, source_index)',
  );
  late final Index playbackStatesRecent = Index(
    'playback_states_recent',
    'CREATE INDEX playback_states_recent ON playback_states (updated_at)',
  );
  late final Index readingStatesRecent = Index(
    'reading_states_recent',
    'CREATE INDEX reading_states_recent ON reading_states (updated_at)',
  );
  late final Index readingSessionsStarted = Index(
    'reading_sessions_started',
    'CREATE INDEX reading_sessions_started ON reading_sessions (started_at)',
  );
  late final Index listeningSessionsStarted = Index(
    'listening_sessions_started',
    'CREATE INDEX listening_sessions_started ON listening_sessions (started_at)',
  );
  late final Index downloadTasksPending = Index(
    'download_tasks_pending',
    'CREATE INDEX download_tasks_pending ON download_tasks (state, priority)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    sources,
    books,
    people,
    bookPeople,
    chapters,
    mediaFiles,
    chapterSegments,
    playbackStates,
    readingStates,
    readingSessions,
    listeningSessions,
    bookmarks,
    categories,
    bookCategories,
    repositories,
    extensions,
    extensionPreferences,
    downloadTasks,
    booksLibrary,
    chaptersOrder,
    playbackStatesRecent,
    readingStatesRecent,
    readingSessionsStarted,
    listeningSessionsStarted,
    downloadTasksPending,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'books',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('book_people', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'books',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('chapters', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'books',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('media_files', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'chapters',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('chapter_segments', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'books',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('playback_states', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'books',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('reading_states', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'books',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('reading_sessions', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'chapters',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('reading_sessions', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'books',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('listening_sessions', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'chapters',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('listening_sessions', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'books',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('bookmarks', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'books',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('book_categories', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'categories',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('book_categories', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'media_files',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('download_tasks', kind: UpdateKind.delete)],
    ),
  ]);
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $$SourcesTableCreateCompanionBuilder = SourcesCompanion Function({
  Value<int> id,
  Value<String?> extensionId,
  required String key,
  required String name,
  required String lang,
  Value<String?> contentRating,
  Value<bool> isEnabled,
  Value<bool> isPinned,
  Value<DateTime?> lastUsedAt,
});
typedef $$SourcesTableUpdateCompanionBuilder = SourcesCompanion Function({
  Value<int> id,
  Value<String?> extensionId,
  Value<String> key,
  Value<String> name,
  Value<String> lang,
  Value<String?> contentRating,
  Value<bool> isEnabled,
  Value<bool> isPinned,
  Value<DateTime?> lastUsedAt,
});

final class $$SourcesTableReferences
    extends BaseReferences<_$KikuyomiDatabase, $SourcesTable, SourceRow> {
  $$SourcesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$BooksTable, List<BookRow>> _booksRefsTable(
    _$KikuyomiDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.books,
    aliasName: 'sources__id__books__source_id',
  );

  $$BooksTableProcessedTableManager get booksRefs {
    final manager = $$BooksTableTableManager(
      $_db,
      $_db.books,
    ).filter((f) => f.sourceId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_booksRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SourcesTableFilterComposer
    extends Composer<_$KikuyomiDatabase, $SourcesTable> {
  $$SourcesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get extensionId => $composableBuilder(
    column: $table.extensionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lang => $composableBuilder(
    column: $table.lang,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contentRating => $composableBuilder(
    column: $table.contentRating,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isEnabled => $composableBuilder(
    column: $table.isEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPinned => $composableBuilder(
    column: $table.isPinned,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastUsedAt => $composableBuilder(
    column: $table.lastUsedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> booksRefs(
    Expression<bool> Function($$BooksTableFilterComposer f) f,
  ) {
    final $$BooksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.sourceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BooksTableFilterComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SourcesTableOrderingComposer
    extends Composer<_$KikuyomiDatabase, $SourcesTable> {
  $$SourcesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get extensionId => $composableBuilder(
    column: $table.extensionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lang => $composableBuilder(
    column: $table.lang,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contentRating => $composableBuilder(
    column: $table.contentRating,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isEnabled => $composableBuilder(
    column: $table.isEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPinned => $composableBuilder(
    column: $table.isPinned,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastUsedAt => $composableBuilder(
    column: $table.lastUsedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SourcesTableAnnotationComposer
    extends Composer<_$KikuyomiDatabase, $SourcesTable> {
  $$SourcesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get extensionId => $composableBuilder(
    column: $table.extensionId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get lang =>
      $composableBuilder(column: $table.lang, builder: (column) => column);

  GeneratedColumn<String> get contentRating => $composableBuilder(
    column: $table.contentRating,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isEnabled =>
      $composableBuilder(column: $table.isEnabled, builder: (column) => column);

  GeneratedColumn<bool> get isPinned =>
      $composableBuilder(column: $table.isPinned, builder: (column) => column);

  GeneratedColumn<DateTime> get lastUsedAt => $composableBuilder(
    column: $table.lastUsedAt,
    builder: (column) => column,
  );

  Expression<T> booksRefs<T extends Object>(
    Expression<T> Function($$BooksTableAnnotationComposer a) f,
  ) {
    final $$BooksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.sourceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BooksTableAnnotationComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SourcesTableTableManager
    extends
        RootTableManager<
          _$KikuyomiDatabase,
          $SourcesTable,
          SourceRow,
          $$SourcesTableFilterComposer,
          $$SourcesTableOrderingComposer,
          $$SourcesTableAnnotationComposer,
          $$SourcesTableCreateCompanionBuilder,
          $$SourcesTableUpdateCompanionBuilder,
          (SourceRow, $$SourcesTableReferences),
          SourceRow,
          PrefetchHooks Function({bool booksRefs})
        > {
  $$SourcesTableTableManager(_$KikuyomiDatabase db, $SourcesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SourcesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SourcesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SourcesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> extensionId = const Value.absent(),
                Value<String> key = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> lang = const Value.absent(),
                Value<String?> contentRating = const Value.absent(),
                Value<bool> isEnabled = const Value.absent(),
                Value<bool> isPinned = const Value.absent(),
                Value<DateTime?> lastUsedAt = const Value.absent(),
              }) => SourcesCompanion(
                id: id,
                extensionId: extensionId,
                key: key,
                name: name,
                lang: lang,
                contentRating: contentRating,
                isEnabled: isEnabled,
                isPinned: isPinned,
                lastUsedAt: lastUsedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> extensionId = const Value.absent(),
                required String key,
                required String name,
                required String lang,
                Value<String?> contentRating = const Value.absent(),
                Value<bool> isEnabled = const Value.absent(),
                Value<bool> isPinned = const Value.absent(),
                Value<DateTime?> lastUsedAt = const Value.absent(),
              }) => SourcesCompanion.insert(
                id: id,
                extensionId: extensionId,
                key: key,
                name: name,
                lang: lang,
                contentRating: contentRating,
                isEnabled: isEnabled,
                isPinned: isPinned,
                lastUsedAt: lastUsedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SourcesTable, SourceRow>(table),
                  $$SourcesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({booksRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (booksRefs) db.books],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (booksRefs)
                    await $_getPrefetchedData<
                      SourceRow,
                      $SourcesTable,
                      BookRow
                    >(
                      currentTable: table,
                      referencedTable: $$SourcesTableReferences._booksRefsTable(
                        db,
                      ),
                      managerFromTypedResult: (p0) =>
                          $$SourcesTableReferences(db, table, p0).booksRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.sourceId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$SourcesTableProcessedTableManager =
    ProcessedTableManager<
      _$KikuyomiDatabase,
      $SourcesTable,
      SourceRow,
      $$SourcesTableFilterComposer,
      $$SourcesTableOrderingComposer,
      $$SourcesTableAnnotationComposer,
      $$SourcesTableCreateCompanionBuilder,
      $$SourcesTableUpdateCompanionBuilder,
      (SourceRow, $$SourcesTableReferences),
      SourceRow,
      PrefetchHooks Function({bool booksRefs})
    >;
typedef $$BooksTableCreateCompanionBuilder = BooksCompanion Function({
  Value<int> id,
  required int sourceId,
  required String key,
  required String title,
  Value<String?> subtitle,
  Value<String?> description,
  Value<String?> coverUrl,
  Value<String?> coverLocalPath,
  Value<DateTime?> coverUpdatedAt,
  Value<String?> seriesName,
  Value<double?> seriesIndex,
  Value<List<String>> genres,
  Value<String?> language,
  Value<String?> publisher,
  Value<String?> publishedDate,
  Value<String?> isbn,
  Value<bool?> abridged,
  Value<String?> status,
  Value<String?> contentRating,
  Value<int?> totalDurationMs,
  Value<String?> webUrl,
  Value<bool> inLibrary,
  Value<DateTime?> dateAdded,
  Value<DateTime?> lastRefreshedAt,
  Value<bool> detailsFetched,
  Value<Set<BookField>> userOverrides,
  Value<double?> playbackSpeed,
  Value<bool?> chaptersReversed,
  Value<DateTime?> continueHiddenAt,
  Value<String?> filePath,
  Value<SourceKind> kind,
  required DateTime createdAt,
  required DateTime updatedAt,
});
typedef $$BooksTableUpdateCompanionBuilder = BooksCompanion Function({
  Value<int> id,
  Value<int> sourceId,
  Value<String> key,
  Value<String> title,
  Value<String?> subtitle,
  Value<String?> description,
  Value<String?> coverUrl,
  Value<String?> coverLocalPath,
  Value<DateTime?> coverUpdatedAt,
  Value<String?> seriesName,
  Value<double?> seriesIndex,
  Value<List<String>> genres,
  Value<String?> language,
  Value<String?> publisher,
  Value<String?> publishedDate,
  Value<String?> isbn,
  Value<bool?> abridged,
  Value<String?> status,
  Value<String?> contentRating,
  Value<int?> totalDurationMs,
  Value<String?> webUrl,
  Value<bool> inLibrary,
  Value<DateTime?> dateAdded,
  Value<DateTime?> lastRefreshedAt,
  Value<bool> detailsFetched,
  Value<Set<BookField>> userOverrides,
  Value<double?> playbackSpeed,
  Value<bool?> chaptersReversed,
  Value<DateTime?> continueHiddenAt,
  Value<String?> filePath,
  Value<SourceKind> kind,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

final class $$BooksTableReferences
    extends BaseReferences<_$KikuyomiDatabase, $BooksTable, BookRow> {
  $$BooksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SourcesTable _sourceIdTable(_$KikuyomiDatabase db) =>
      db.sources.createAlias('books__source_id__sources__id');

  $$SourcesTableProcessedTableManager get sourceId {
    final $_column = $_itemColumn<int>('source_id')!;

    final manager = $$SourcesTableTableManager(
      $_db,
      $_db.sources,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sourceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$BookPeopleTable, List<BookPersonRow>>
  _bookPeopleRefsTable(_$KikuyomiDatabase db) => MultiTypedResultKey.fromTable(
    db.bookPeople,
    aliasName: 'books__id__book_people__book_id',
  );

  $$BookPeopleTableProcessedTableManager get bookPeopleRefs {
    final manager = $$BookPeopleTableTableManager(
      $_db,
      $_db.bookPeople,
    ).filter((f) => f.bookId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_bookPeopleRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ChaptersTable, List<ChapterRow>>
  _chaptersRefsTable(_$KikuyomiDatabase db) => MultiTypedResultKey.fromTable(
    db.chapters,
    aliasName: 'books__id__chapters__book_id',
  );

  $$ChaptersTableProcessedTableManager get chaptersRefs {
    final manager = $$ChaptersTableTableManager(
      $_db,
      $_db.chapters,
    ).filter((f) => f.bookId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_chaptersRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$MediaFilesTable, List<MediaFileRow>>
  _mediaFilesRefsTable(_$KikuyomiDatabase db) => MultiTypedResultKey.fromTable(
    db.mediaFiles,
    aliasName: 'books__id__media_files__book_id',
  );

  $$MediaFilesTableProcessedTableManager get mediaFilesRefs {
    final manager = $$MediaFilesTableTableManager(
      $_db,
      $_db.mediaFiles,
    ).filter((f) => f.bookId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_mediaFilesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PlaybackStatesTable, List<PlaybackStateRow>>
  _playbackStatesRefsTable(_$KikuyomiDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.playbackStates,
        aliasName: 'books__id__playback_states__book_id',
      );

  $$PlaybackStatesTableProcessedTableManager get playbackStatesRefs {
    final manager = $$PlaybackStatesTableTableManager(
      $_db,
      $_db.playbackStates,
    ).filter((f) => f.bookId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_playbackStatesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ReadingStatesTable, List<ReadingStateRow>>
  _readingStatesRefsTable(_$KikuyomiDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.readingStates,
        aliasName: 'books__id__reading_states__book_id',
      );

  $$ReadingStatesTableProcessedTableManager get readingStatesRefs {
    final manager = $$ReadingStatesTableTableManager(
      $_db,
      $_db.readingStates,
    ).filter((f) => f.bookId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_readingStatesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ReadingSessionsTable, List<ReadingSessionRow>>
  _readingSessionsRefsTable(_$KikuyomiDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.readingSessions,
        aliasName: 'books__id__reading_sessions__book_id',
      );

  $$ReadingSessionsTableProcessedTableManager get readingSessionsRefs {
    final manager = $$ReadingSessionsTableTableManager(
      $_db,
      $_db.readingSessions,
    ).filter((f) => f.bookId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _readingSessionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ListeningSessionsTable, List<ListeningSessionRow>>
  _listeningSessionsRefsTable(_$KikuyomiDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.listeningSessions,
        aliasName: 'books__id__listening_sessions__book_id',
      );

  $$ListeningSessionsTableProcessedTableManager get listeningSessionsRefs {
    final manager = $$ListeningSessionsTableTableManager(
      $_db,
      $_db.listeningSessions,
    ).filter((f) => f.bookId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _listeningSessionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$BookmarksTable, List<BookmarkRow>>
  _bookmarksRefsTable(_$KikuyomiDatabase db) => MultiTypedResultKey.fromTable(
    db.bookmarks,
    aliasName: 'books__id__bookmarks__book_id',
  );

  $$BookmarksTableProcessedTableManager get bookmarksRefs {
    final manager = $$BookmarksTableTableManager(
      $_db,
      $_db.bookmarks,
    ).filter((f) => f.bookId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_bookmarksRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$BookCategoriesTable, List<BookCategoryRow>>
  _bookCategoriesRefsTable(_$KikuyomiDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.bookCategories,
        aliasName: 'books__id__book_categories__book_id',
      );

  $$BookCategoriesTableProcessedTableManager get bookCategoriesRefs {
    final manager = $$BookCategoriesTableTableManager(
      $_db,
      $_db.bookCategories,
    ).filter((f) => f.bookId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_bookCategoriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$BooksTableFilterComposer
    extends Composer<_$KikuyomiDatabase, $BooksTable> {
  $$BooksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subtitle => $composableBuilder(
    column: $table.subtitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get coverUrl => $composableBuilder(
    column: $table.coverUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get coverLocalPath => $composableBuilder(
    column: $table.coverLocalPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get coverUpdatedAt => $composableBuilder(
    column: $table.coverUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get seriesName => $composableBuilder(
    column: $table.seriesName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get seriesIndex => $composableBuilder(
    column: $table.seriesIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<List<String>, List<String>, String>
  get genres => $composableBuilder(
    column: $table.genres,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get publisher => $composableBuilder(
    column: $table.publisher,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get publishedDate => $composableBuilder(
    column: $table.publishedDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get isbn => $composableBuilder(
    column: $table.isbn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get abridged => $composableBuilder(
    column: $table.abridged,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contentRating => $composableBuilder(
    column: $table.contentRating,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalDurationMs => $composableBuilder(
    column: $table.totalDurationMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get webUrl => $composableBuilder(
    column: $table.webUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get inLibrary => $composableBuilder(
    column: $table.inLibrary,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dateAdded => $composableBuilder(
    column: $table.dateAdded,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastRefreshedAt => $composableBuilder(
    column: $table.lastRefreshedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get detailsFetched => $composableBuilder(
    column: $table.detailsFetched,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Set<BookField>, Set<BookField>, String>
  get userOverrides => $composableBuilder(
    column: $table.userOverrides,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<double> get playbackSpeed => $composableBuilder(
    column: $table.playbackSpeed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get chaptersReversed => $composableBuilder(
    column: $table.chaptersReversed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get continueHiddenAt => $composableBuilder(
    column: $table.continueHiddenAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SourceKind, SourceKind, String> get kind =>
      $composableBuilder(
        column: $table.kind,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$SourcesTableFilterComposer get sourceId {
    final $$SourcesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceId,
      referencedTable: $db.sources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SourcesTableFilterComposer(
            $db: $db,
            $table: $db.sources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> bookPeopleRefs(
    Expression<bool> Function($$BookPeopleTableFilterComposer f) f,
  ) {
    final $$BookPeopleTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.bookPeople,
      getReferencedColumn: (t) => t.bookId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BookPeopleTableFilterComposer(
            $db: $db,
            $table: $db.bookPeople,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> chaptersRefs(
    Expression<bool> Function($$ChaptersTableFilterComposer f) f,
  ) {
    final $$ChaptersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.chapters,
      getReferencedColumn: (t) => t.bookId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChaptersTableFilterComposer(
            $db: $db,
            $table: $db.chapters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> mediaFilesRefs(
    Expression<bool> Function($$MediaFilesTableFilterComposer f) f,
  ) {
    final $$MediaFilesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.mediaFiles,
      getReferencedColumn: (t) => t.bookId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MediaFilesTableFilterComposer(
            $db: $db,
            $table: $db.mediaFiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> playbackStatesRefs(
    Expression<bool> Function($$PlaybackStatesTableFilterComposer f) f,
  ) {
    final $$PlaybackStatesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.playbackStates,
      getReferencedColumn: (t) => t.bookId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaybackStatesTableFilterComposer(
            $db: $db,
            $table: $db.playbackStates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> readingStatesRefs(
    Expression<bool> Function($$ReadingStatesTableFilterComposer f) f,
  ) {
    final $$ReadingStatesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.readingStates,
      getReferencedColumn: (t) => t.bookId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReadingStatesTableFilterComposer(
            $db: $db,
            $table: $db.readingStates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> readingSessionsRefs(
    Expression<bool> Function($$ReadingSessionsTableFilterComposer f) f,
  ) {
    final $$ReadingSessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.readingSessions,
      getReferencedColumn: (t) => t.bookId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReadingSessionsTableFilterComposer(
            $db: $db,
            $table: $db.readingSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> listeningSessionsRefs(
    Expression<bool> Function($$ListeningSessionsTableFilterComposer f) f,
  ) {
    final $$ListeningSessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.listeningSessions,
      getReferencedColumn: (t) => t.bookId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ListeningSessionsTableFilterComposer(
            $db: $db,
            $table: $db.listeningSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> bookmarksRefs(
    Expression<bool> Function($$BookmarksTableFilterComposer f) f,
  ) {
    final $$BookmarksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.bookmarks,
      getReferencedColumn: (t) => t.bookId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BookmarksTableFilterComposer(
            $db: $db,
            $table: $db.bookmarks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> bookCategoriesRefs(
    Expression<bool> Function($$BookCategoriesTableFilterComposer f) f,
  ) {
    final $$BookCategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.bookCategories,
      getReferencedColumn: (t) => t.bookId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BookCategoriesTableFilterComposer(
            $db: $db,
            $table: $db.bookCategories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$BooksTableOrderingComposer
    extends Composer<_$KikuyomiDatabase, $BooksTable> {
  $$BooksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subtitle => $composableBuilder(
    column: $table.subtitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get coverUrl => $composableBuilder(
    column: $table.coverUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get coverLocalPath => $composableBuilder(
    column: $table.coverLocalPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get coverUpdatedAt => $composableBuilder(
    column: $table.coverUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get seriesName => $composableBuilder(
    column: $table.seriesName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get seriesIndex => $composableBuilder(
    column: $table.seriesIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get genres => $composableBuilder(
    column: $table.genres,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get publisher => $composableBuilder(
    column: $table.publisher,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get publishedDate => $composableBuilder(
    column: $table.publishedDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get isbn => $composableBuilder(
    column: $table.isbn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get abridged => $composableBuilder(
    column: $table.abridged,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contentRating => $composableBuilder(
    column: $table.contentRating,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalDurationMs => $composableBuilder(
    column: $table.totalDurationMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get webUrl => $composableBuilder(
    column: $table.webUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get inLibrary => $composableBuilder(
    column: $table.inLibrary,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dateAdded => $composableBuilder(
    column: $table.dateAdded,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastRefreshedAt => $composableBuilder(
    column: $table.lastRefreshedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get detailsFetched => $composableBuilder(
    column: $table.detailsFetched,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userOverrides => $composableBuilder(
    column: $table.userOverrides,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get playbackSpeed => $composableBuilder(
    column: $table.playbackSpeed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get chaptersReversed => $composableBuilder(
    column: $table.chaptersReversed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get continueHiddenAt => $composableBuilder(
    column: $table.continueHiddenAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$SourcesTableOrderingComposer get sourceId {
    final $$SourcesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceId,
      referencedTable: $db.sources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SourcesTableOrderingComposer(
            $db: $db,
            $table: $db.sources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BooksTableAnnotationComposer
    extends Composer<_$KikuyomiDatabase, $BooksTable> {
  $$BooksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get subtitle =>
      $composableBuilder(column: $table.subtitle, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get coverUrl =>
      $composableBuilder(column: $table.coverUrl, builder: (column) => column);

  GeneratedColumn<String> get coverLocalPath => $composableBuilder(
    column: $table.coverLocalPath,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get coverUpdatedAt => $composableBuilder(
    column: $table.coverUpdatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get seriesName => $composableBuilder(
    column: $table.seriesName,
    builder: (column) => column,
  );

  GeneratedColumn<double> get seriesIndex => $composableBuilder(
    column: $table.seriesIndex,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<List<String>, String> get genres =>
      $composableBuilder(column: $table.genres, builder: (column) => column);

  GeneratedColumn<String> get language =>
      $composableBuilder(column: $table.language, builder: (column) => column);

  GeneratedColumn<String> get publisher =>
      $composableBuilder(column: $table.publisher, builder: (column) => column);

  GeneratedColumn<String> get publishedDate => $composableBuilder(
    column: $table.publishedDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get isbn =>
      $composableBuilder(column: $table.isbn, builder: (column) => column);

  GeneratedColumn<bool> get abridged =>
      $composableBuilder(column: $table.abridged, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get contentRating => $composableBuilder(
    column: $table.contentRating,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalDurationMs => $composableBuilder(
    column: $table.totalDurationMs,
    builder: (column) => column,
  );

  GeneratedColumn<String> get webUrl =>
      $composableBuilder(column: $table.webUrl, builder: (column) => column);

  GeneratedColumn<bool> get inLibrary =>
      $composableBuilder(column: $table.inLibrary, builder: (column) => column);

  GeneratedColumn<DateTime> get dateAdded =>
      $composableBuilder(column: $table.dateAdded, builder: (column) => column);

  GeneratedColumn<DateTime> get lastRefreshedAt => $composableBuilder(
    column: $table.lastRefreshedAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get detailsFetched => $composableBuilder(
    column: $table.detailsFetched,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<Set<BookField>, String> get userOverrides =>
      $composableBuilder(
        column: $table.userOverrides,
        builder: (column) => column,
      );

  GeneratedColumn<double> get playbackSpeed => $composableBuilder(
    column: $table.playbackSpeed,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get chaptersReversed => $composableBuilder(
    column: $table.chaptersReversed,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get continueHiddenAt => $composableBuilder(
    column: $table.continueHiddenAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SourceKind, String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$SourcesTableAnnotationComposer get sourceId {
    final $$SourcesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceId,
      referencedTable: $db.sources,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SourcesTableAnnotationComposer(
            $db: $db,
            $table: $db.sources,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> bookPeopleRefs<T extends Object>(
    Expression<T> Function($$BookPeopleTableAnnotationComposer a) f,
  ) {
    final $$BookPeopleTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.bookPeople,
      getReferencedColumn: (t) => t.bookId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BookPeopleTableAnnotationComposer(
            $db: $db,
            $table: $db.bookPeople,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> chaptersRefs<T extends Object>(
    Expression<T> Function($$ChaptersTableAnnotationComposer a) f,
  ) {
    final $$ChaptersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.chapters,
      getReferencedColumn: (t) => t.bookId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChaptersTableAnnotationComposer(
            $db: $db,
            $table: $db.chapters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> mediaFilesRefs<T extends Object>(
    Expression<T> Function($$MediaFilesTableAnnotationComposer a) f,
  ) {
    final $$MediaFilesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.mediaFiles,
      getReferencedColumn: (t) => t.bookId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MediaFilesTableAnnotationComposer(
            $db: $db,
            $table: $db.mediaFiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> playbackStatesRefs<T extends Object>(
    Expression<T> Function($$PlaybackStatesTableAnnotationComposer a) f,
  ) {
    final $$PlaybackStatesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.playbackStates,
      getReferencedColumn: (t) => t.bookId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaybackStatesTableAnnotationComposer(
            $db: $db,
            $table: $db.playbackStates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> readingStatesRefs<T extends Object>(
    Expression<T> Function($$ReadingStatesTableAnnotationComposer a) f,
  ) {
    final $$ReadingStatesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.readingStates,
      getReferencedColumn: (t) => t.bookId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReadingStatesTableAnnotationComposer(
            $db: $db,
            $table: $db.readingStates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> readingSessionsRefs<T extends Object>(
    Expression<T> Function($$ReadingSessionsTableAnnotationComposer a) f,
  ) {
    final $$ReadingSessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.readingSessions,
      getReferencedColumn: (t) => t.bookId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReadingSessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.readingSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> listeningSessionsRefs<T extends Object>(
    Expression<T> Function($$ListeningSessionsTableAnnotationComposer a) f,
  ) {
    final $$ListeningSessionsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.listeningSessions,
          getReferencedColumn: (t) => t.bookId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ListeningSessionsTableAnnotationComposer(
                $db: $db,
                $table: $db.listeningSessions,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> bookmarksRefs<T extends Object>(
    Expression<T> Function($$BookmarksTableAnnotationComposer a) f,
  ) {
    final $$BookmarksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.bookmarks,
      getReferencedColumn: (t) => t.bookId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BookmarksTableAnnotationComposer(
            $db: $db,
            $table: $db.bookmarks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> bookCategoriesRefs<T extends Object>(
    Expression<T> Function($$BookCategoriesTableAnnotationComposer a) f,
  ) {
    final $$BookCategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.bookCategories,
      getReferencedColumn: (t) => t.bookId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BookCategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.bookCategories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$BooksTableTableManager
    extends
        RootTableManager<
          _$KikuyomiDatabase,
          $BooksTable,
          BookRow,
          $$BooksTableFilterComposer,
          $$BooksTableOrderingComposer,
          $$BooksTableAnnotationComposer,
          $$BooksTableCreateCompanionBuilder,
          $$BooksTableUpdateCompanionBuilder,
          (BookRow, $$BooksTableReferences),
          BookRow,
          PrefetchHooks Function({
            bool sourceId,
            bool bookPeopleRefs,
            bool chaptersRefs,
            bool mediaFilesRefs,
            bool playbackStatesRefs,
            bool readingStatesRefs,
            bool readingSessionsRefs,
            bool listeningSessionsRefs,
            bool bookmarksRefs,
            bool bookCategoriesRefs,
          })
        > {
  $$BooksTableTableManager(_$KikuyomiDatabase db, $BooksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BooksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BooksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BooksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> sourceId = const Value.absent(),
                Value<String> key = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> subtitle = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> coverUrl = const Value.absent(),
                Value<String?> coverLocalPath = const Value.absent(),
                Value<DateTime?> coverUpdatedAt = const Value.absent(),
                Value<String?> seriesName = const Value.absent(),
                Value<double?> seriesIndex = const Value.absent(),
                Value<List<String>> genres = const Value.absent(),
                Value<String?> language = const Value.absent(),
                Value<String?> publisher = const Value.absent(),
                Value<String?> publishedDate = const Value.absent(),
                Value<String?> isbn = const Value.absent(),
                Value<bool?> abridged = const Value.absent(),
                Value<String?> status = const Value.absent(),
                Value<String?> contentRating = const Value.absent(),
                Value<int?> totalDurationMs = const Value.absent(),
                Value<String?> webUrl = const Value.absent(),
                Value<bool> inLibrary = const Value.absent(),
                Value<DateTime?> dateAdded = const Value.absent(),
                Value<DateTime?> lastRefreshedAt = const Value.absent(),
                Value<bool> detailsFetched = const Value.absent(),
                Value<Set<BookField>> userOverrides = const Value.absent(),
                Value<double?> playbackSpeed = const Value.absent(),
                Value<bool?> chaptersReversed = const Value.absent(),
                Value<DateTime?> continueHiddenAt = const Value.absent(),
                Value<String?> filePath = const Value.absent(),
                Value<SourceKind> kind = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => BooksCompanion(
                id: id,
                sourceId: sourceId,
                key: key,
                title: title,
                subtitle: subtitle,
                description: description,
                coverUrl: coverUrl,
                coverLocalPath: coverLocalPath,
                coverUpdatedAt: coverUpdatedAt,
                seriesName: seriesName,
                seriesIndex: seriesIndex,
                genres: genres,
                language: language,
                publisher: publisher,
                publishedDate: publishedDate,
                isbn: isbn,
                abridged: abridged,
                status: status,
                contentRating: contentRating,
                totalDurationMs: totalDurationMs,
                webUrl: webUrl,
                inLibrary: inLibrary,
                dateAdded: dateAdded,
                lastRefreshedAt: lastRefreshedAt,
                detailsFetched: detailsFetched,
                userOverrides: userOverrides,
                playbackSpeed: playbackSpeed,
                chaptersReversed: chaptersReversed,
                continueHiddenAt: continueHiddenAt,
                filePath: filePath,
                kind: kind,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int sourceId,
                required String key,
                required String title,
                Value<String?> subtitle = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> coverUrl = const Value.absent(),
                Value<String?> coverLocalPath = const Value.absent(),
                Value<DateTime?> coverUpdatedAt = const Value.absent(),
                Value<String?> seriesName = const Value.absent(),
                Value<double?> seriesIndex = const Value.absent(),
                Value<List<String>> genres = const Value.absent(),
                Value<String?> language = const Value.absent(),
                Value<String?> publisher = const Value.absent(),
                Value<String?> publishedDate = const Value.absent(),
                Value<String?> isbn = const Value.absent(),
                Value<bool?> abridged = const Value.absent(),
                Value<String?> status = const Value.absent(),
                Value<String?> contentRating = const Value.absent(),
                Value<int?> totalDurationMs = const Value.absent(),
                Value<String?> webUrl = const Value.absent(),
                Value<bool> inLibrary = const Value.absent(),
                Value<DateTime?> dateAdded = const Value.absent(),
                Value<DateTime?> lastRefreshedAt = const Value.absent(),
                Value<bool> detailsFetched = const Value.absent(),
                Value<Set<BookField>> userOverrides = const Value.absent(),
                Value<double?> playbackSpeed = const Value.absent(),
                Value<bool?> chaptersReversed = const Value.absent(),
                Value<DateTime?> continueHiddenAt = const Value.absent(),
                Value<String?> filePath = const Value.absent(),
                Value<SourceKind> kind = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
              }) => BooksCompanion.insert(
                id: id,
                sourceId: sourceId,
                key: key,
                title: title,
                subtitle: subtitle,
                description: description,
                coverUrl: coverUrl,
                coverLocalPath: coverLocalPath,
                coverUpdatedAt: coverUpdatedAt,
                seriesName: seriesName,
                seriesIndex: seriesIndex,
                genres: genres,
                language: language,
                publisher: publisher,
                publishedDate: publishedDate,
                isbn: isbn,
                abridged: abridged,
                status: status,
                contentRating: contentRating,
                totalDurationMs: totalDurationMs,
                webUrl: webUrl,
                inLibrary: inLibrary,
                dateAdded: dateAdded,
                lastRefreshedAt: lastRefreshedAt,
                detailsFetched: detailsFetched,
                userOverrides: userOverrides,
                playbackSpeed: playbackSpeed,
                chaptersReversed: chaptersReversed,
                continueHiddenAt: continueHiddenAt,
                filePath: filePath,
                kind: kind,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BooksTable, BookRow>(table),
                  $$BooksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                sourceId = false,
                bookPeopleRefs = false,
                chaptersRefs = false,
                mediaFilesRefs = false,
                playbackStatesRefs = false,
                readingStatesRefs = false,
                readingSessionsRefs = false,
                listeningSessionsRefs = false,
                bookmarksRefs = false,
                bookCategoriesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (bookPeopleRefs) db.bookPeople,
                    if (chaptersRefs) db.chapters,
                    if (mediaFilesRefs) db.mediaFiles,
                    if (playbackStatesRefs) db.playbackStates,
                    if (readingStatesRefs) db.readingStates,
                    if (readingSessionsRefs) db.readingSessions,
                    if (listeningSessionsRefs) db.listeningSessions,
                    if (bookmarksRefs) db.bookmarks,
                    if (bookCategoriesRefs) db.bookCategories,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (sourceId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.sourceId,
                            referencedTable: $$BooksTableReferences
                                ._sourceIdTable(db),
                            referencedColumn: $$BooksTableReferences
                                ._sourceIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (bookPeopleRefs)
                        await $_getPrefetchedData<
                          BookRow,
                          $BooksTable,
                          BookPersonRow
                        >(
                          currentTable: table,
                          referencedTable: $$BooksTableReferences
                              ._bookPeopleRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BooksTableReferences(
                                db,
                                table,
                                p0,
                              ).bookPeopleRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.bookId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (chaptersRefs)
                        await $_getPrefetchedData<
                          BookRow,
                          $BooksTable,
                          ChapterRow
                        >(
                          currentTable: table,
                          referencedTable: $$BooksTableReferences
                              ._chaptersRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BooksTableReferences(
                                db,
                                table,
                                p0,
                              ).chaptersRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.bookId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (mediaFilesRefs)
                        await $_getPrefetchedData<
                          BookRow,
                          $BooksTable,
                          MediaFileRow
                        >(
                          currentTable: table,
                          referencedTable: $$BooksTableReferences
                              ._mediaFilesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BooksTableReferences(
                                db,
                                table,
                                p0,
                              ).mediaFilesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.bookId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (playbackStatesRefs)
                        await $_getPrefetchedData<
                          BookRow,
                          $BooksTable,
                          PlaybackStateRow
                        >(
                          currentTable: table,
                          referencedTable: $$BooksTableReferences
                              ._playbackStatesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BooksTableReferences(
                                db,
                                table,
                                p0,
                              ).playbackStatesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.bookId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (readingStatesRefs)
                        await $_getPrefetchedData<
                          BookRow,
                          $BooksTable,
                          ReadingStateRow
                        >(
                          currentTable: table,
                          referencedTable: $$BooksTableReferences
                              ._readingStatesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BooksTableReferences(
                                db,
                                table,
                                p0,
                              ).readingStatesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.bookId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (readingSessionsRefs)
                        await $_getPrefetchedData<
                          BookRow,
                          $BooksTable,
                          ReadingSessionRow
                        >(
                          currentTable: table,
                          referencedTable: $$BooksTableReferences
                              ._readingSessionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BooksTableReferences(
                                db,
                                table,
                                p0,
                              ).readingSessionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.bookId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (listeningSessionsRefs)
                        await $_getPrefetchedData<
                          BookRow,
                          $BooksTable,
                          ListeningSessionRow
                        >(
                          currentTable: table,
                          referencedTable: $$BooksTableReferences
                              ._listeningSessionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BooksTableReferences(
                                db,
                                table,
                                p0,
                              ).listeningSessionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.bookId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (bookmarksRefs)
                        await $_getPrefetchedData<
                          BookRow,
                          $BooksTable,
                          BookmarkRow
                        >(
                          currentTable: table,
                          referencedTable: $$BooksTableReferences
                              ._bookmarksRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BooksTableReferences(
                                db,
                                table,
                                p0,
                              ).bookmarksRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.bookId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (bookCategoriesRefs)
                        await $_getPrefetchedData<
                          BookRow,
                          $BooksTable,
                          BookCategoryRow
                        >(
                          currentTable: table,
                          referencedTable: $$BooksTableReferences
                              ._bookCategoriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BooksTableReferences(
                                db,
                                table,
                                p0,
                              ).bookCategoriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.bookId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$BooksTableProcessedTableManager =
    ProcessedTableManager<
      _$KikuyomiDatabase,
      $BooksTable,
      BookRow,
      $$BooksTableFilterComposer,
      $$BooksTableOrderingComposer,
      $$BooksTableAnnotationComposer,
      $$BooksTableCreateCompanionBuilder,
      $$BooksTableUpdateCompanionBuilder,
      (BookRow, $$BooksTableReferences),
      BookRow,
      PrefetchHooks Function({
        bool sourceId,
        bool bookPeopleRefs,
        bool chaptersRefs,
        bool mediaFilesRefs,
        bool playbackStatesRefs,
        bool readingStatesRefs,
        bool readingSessionsRefs,
        bool listeningSessionsRefs,
        bool bookmarksRefs,
        bool bookCategoriesRefs,
      })
    >;
typedef $$PeopleTableCreateCompanionBuilder = PeopleCompanion Function({
  Value<int> id,
  required String name,
});
typedef $$PeopleTableUpdateCompanionBuilder = PeopleCompanion Function({
  Value<int> id,
  Value<String> name,
});

final class $$PeopleTableReferences
    extends BaseReferences<_$KikuyomiDatabase, $PeopleTable, PersonRow> {
  $$PeopleTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$BookPeopleTable, List<BookPersonRow>>
  _bookPeopleRefsTable(_$KikuyomiDatabase db) => MultiTypedResultKey.fromTable(
    db.bookPeople,
    aliasName: 'people__id__book_people__person_id',
  );

  $$BookPeopleTableProcessedTableManager get bookPeopleRefs {
    final manager = $$BookPeopleTableTableManager(
      $_db,
      $_db.bookPeople,
    ).filter((f) => f.personId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_bookPeopleRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PeopleTableFilterComposer
    extends Composer<_$KikuyomiDatabase, $PeopleTable> {
  $$PeopleTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> bookPeopleRefs(
    Expression<bool> Function($$BookPeopleTableFilterComposer f) f,
  ) {
    final $$BookPeopleTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.bookPeople,
      getReferencedColumn: (t) => t.personId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BookPeopleTableFilterComposer(
            $db: $db,
            $table: $db.bookPeople,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PeopleTableOrderingComposer
    extends Composer<_$KikuyomiDatabase, $PeopleTable> {
  $$PeopleTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PeopleTableAnnotationComposer
    extends Composer<_$KikuyomiDatabase, $PeopleTable> {
  $$PeopleTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  Expression<T> bookPeopleRefs<T extends Object>(
    Expression<T> Function($$BookPeopleTableAnnotationComposer a) f,
  ) {
    final $$BookPeopleTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.bookPeople,
      getReferencedColumn: (t) => t.personId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BookPeopleTableAnnotationComposer(
            $db: $db,
            $table: $db.bookPeople,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PeopleTableTableManager
    extends
        RootTableManager<
          _$KikuyomiDatabase,
          $PeopleTable,
          PersonRow,
          $$PeopleTableFilterComposer,
          $$PeopleTableOrderingComposer,
          $$PeopleTableAnnotationComposer,
          $$PeopleTableCreateCompanionBuilder,
          $$PeopleTableUpdateCompanionBuilder,
          (PersonRow, $$PeopleTableReferences),
          PersonRow,
          PrefetchHooks Function({bool bookPeopleRefs})
        > {
  $$PeopleTableTableManager(_$KikuyomiDatabase db, $PeopleTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PeopleTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PeopleTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PeopleTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
          }) => PeopleCompanion(id: id, name: name),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
          }) => PeopleCompanion.insert(id: id, name: name),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PeopleTable, PersonRow>(table),
                  $$PeopleTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({bookPeopleRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (bookPeopleRefs) db.bookPeople],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (bookPeopleRefs)
                    await $_getPrefetchedData<
                      PersonRow,
                      $PeopleTable,
                      BookPersonRow
                    >(
                      currentTable: table,
                      referencedTable: $$PeopleTableReferences
                          ._bookPeopleRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$PeopleTableReferences(db, table, p0).bookPeopleRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.personId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$PeopleTableProcessedTableManager =
    ProcessedTableManager<
      _$KikuyomiDatabase,
      $PeopleTable,
      PersonRow,
      $$PeopleTableFilterComposer,
      $$PeopleTableOrderingComposer,
      $$PeopleTableAnnotationComposer,
      $$PeopleTableCreateCompanionBuilder,
      $$PeopleTableUpdateCompanionBuilder,
      (PersonRow, $$PeopleTableReferences),
      PersonRow,
      PrefetchHooks Function({bool bookPeopleRefs})
    >;
typedef $$BookPeopleTableCreateCompanionBuilder = BookPeopleCompanion Function({
  required int bookId,
  required int personId,
  required ContributorRole role,
  required int ordinal,
  Value<int> rowid,
});
typedef $$BookPeopleTableUpdateCompanionBuilder = BookPeopleCompanion Function({
  Value<int> bookId,
  Value<int> personId,
  Value<ContributorRole> role,
  Value<int> ordinal,
  Value<int> rowid,
});

final class $$BookPeopleTableReferences
    extends
        BaseReferences<_$KikuyomiDatabase, $BookPeopleTable, BookPersonRow> {
  $$BookPeopleTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $BooksTable _bookIdTable(_$KikuyomiDatabase db) =>
      db.books.createAlias('book_people__book_id__books__id');

  $$BooksTableProcessedTableManager get bookId {
    final $_column = $_itemColumn<int>('book_id')!;

    final manager = $$BooksTableTableManager(
      $_db,
      $_db.books,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_bookIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $PeopleTable _personIdTable(_$KikuyomiDatabase db) =>
      db.people.createAlias('book_people__person_id__people__id');

  $$PeopleTableProcessedTableManager get personId {
    final $_column = $_itemColumn<int>('person_id')!;

    final manager = $$PeopleTableTableManager(
      $_db,
      $_db.people,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_personIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$BookPeopleTableFilterComposer
    extends Composer<_$KikuyomiDatabase, $BookPeopleTable> {
  $$BookPeopleTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnWithTypeConverterFilters<ContributorRole, ContributorRole, String>
  get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get ordinal => $composableBuilder(
    column: $table.ordinal,
    builder: (column) => ColumnFilters(column),
  );

  $$BooksTableFilterComposer get bookId {
    final $$BooksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BooksTableFilterComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PeopleTableFilterComposer get personId {
    final $$PeopleTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personId,
      referencedTable: $db.people,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PeopleTableFilterComposer(
            $db: $db,
            $table: $db.people,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BookPeopleTableOrderingComposer
    extends Composer<_$KikuyomiDatabase, $BookPeopleTable> {
  $$BookPeopleTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ordinal => $composableBuilder(
    column: $table.ordinal,
    builder: (column) => ColumnOrderings(column),
  );

  $$BooksTableOrderingComposer get bookId {
    final $$BooksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BooksTableOrderingComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PeopleTableOrderingComposer get personId {
    final $$PeopleTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personId,
      referencedTable: $db.people,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PeopleTableOrderingComposer(
            $db: $db,
            $table: $db.people,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BookPeopleTableAnnotationComposer
    extends Composer<_$KikuyomiDatabase, $BookPeopleTable> {
  $$BookPeopleTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumnWithTypeConverter<ContributorRole, String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<int> get ordinal =>
      $composableBuilder(column: $table.ordinal, builder: (column) => column);

  $$BooksTableAnnotationComposer get bookId {
    final $$BooksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BooksTableAnnotationComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PeopleTableAnnotationComposer get personId {
    final $$PeopleTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personId,
      referencedTable: $db.people,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PeopleTableAnnotationComposer(
            $db: $db,
            $table: $db.people,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BookPeopleTableTableManager
    extends
        RootTableManager<
          _$KikuyomiDatabase,
          $BookPeopleTable,
          BookPersonRow,
          $$BookPeopleTableFilterComposer,
          $$BookPeopleTableOrderingComposer,
          $$BookPeopleTableAnnotationComposer,
          $$BookPeopleTableCreateCompanionBuilder,
          $$BookPeopleTableUpdateCompanionBuilder,
          (BookPersonRow, $$BookPeopleTableReferences),
          BookPersonRow,
          PrefetchHooks Function({bool bookId, bool personId})
        > {
  $$BookPeopleTableTableManager(_$KikuyomiDatabase db, $BookPeopleTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BookPeopleTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BookPeopleTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BookPeopleTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> bookId = const Value.absent(),
                Value<int> personId = const Value.absent(),
                Value<ContributorRole> role = const Value.absent(),
                Value<int> ordinal = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BookPeopleCompanion(
                bookId: bookId,
                personId: personId,
                role: role,
                ordinal: ordinal,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int bookId,
                required int personId,
                required ContributorRole role,
                required int ordinal,
                Value<int> rowid = const Value.absent(),
              }) => BookPeopleCompanion.insert(
                bookId: bookId,
                personId: personId,
                role: role,
                ordinal: ordinal,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BookPeopleTable, BookPersonRow>(table),
                  $$BookPeopleTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({bookId = false, personId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (bookId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.bookId,
                        referencedTable: $$BookPeopleTableReferences
                            ._bookIdTable(db),
                        referencedColumn: $$BookPeopleTableReferences
                            ._bookIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (personId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.personId,
                        referencedTable: $$BookPeopleTableReferences
                            ._personIdTable(db),
                        referencedColumn: $$BookPeopleTableReferences
                            ._personIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$BookPeopleTableProcessedTableManager =
    ProcessedTableManager<
      _$KikuyomiDatabase,
      $BookPeopleTable,
      BookPersonRow,
      $$BookPeopleTableFilterComposer,
      $$BookPeopleTableOrderingComposer,
      $$BookPeopleTableAnnotationComposer,
      $$BookPeopleTableCreateCompanionBuilder,
      $$BookPeopleTableUpdateCompanionBuilder,
      (BookPersonRow, $$BookPeopleTableReferences),
      BookPersonRow,
      PrefetchHooks Function({bool bookId, bool personId})
    >;
typedef $$ChaptersTableCreateCompanionBuilder = ChaptersCompanion Function({
  Value<int> id,
  required int bookId,
  required String key,
  required String title,
  required int sourceIndex,
  Value<String?> groupName,
  Value<int?> durationMs,
  Value<int?> wordCount,
  Value<DateTime?> publishedAt,
  Value<bool> isListened,
  Value<DateTime?> listenedAt,
  Value<int> lastPositionMs,
  Value<bool> removedFromSource,
  required DateTime createdAt,
  required DateTime updatedAt,
});
typedef $$ChaptersTableUpdateCompanionBuilder = ChaptersCompanion Function({
  Value<int> id,
  Value<int> bookId,
  Value<String> key,
  Value<String> title,
  Value<int> sourceIndex,
  Value<String?> groupName,
  Value<int?> durationMs,
  Value<int?> wordCount,
  Value<DateTime?> publishedAt,
  Value<bool> isListened,
  Value<DateTime?> listenedAt,
  Value<int> lastPositionMs,
  Value<bool> removedFromSource,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

final class $$ChaptersTableReferences
    extends BaseReferences<_$KikuyomiDatabase, $ChaptersTable, ChapterRow> {
  $$ChaptersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $BooksTable _bookIdTable(_$KikuyomiDatabase db) =>
      db.books.createAlias('chapters__book_id__books__id');

  $$BooksTableProcessedTableManager get bookId {
    final $_column = $_itemColumn<int>('book_id')!;

    final manager = $$BooksTableTableManager(
      $_db,
      $_db.books,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_bookIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$ChapterSegmentsTable, List<ChapterSegmentRow>>
  _chapterSegmentsRefsTable(_$KikuyomiDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.chapterSegments,
        aliasName: 'chapters__id__chapter_segments__chapter_id',
      );

  $$ChapterSegmentsTableProcessedTableManager get chapterSegmentsRefs {
    final manager = $$ChapterSegmentsTableTableManager(
      $_db,
      $_db.chapterSegments,
    ).filter((f) => f.chapterId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _chapterSegmentsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PlaybackStatesTable, List<PlaybackStateRow>>
  _playbackStatesRefsTable(_$KikuyomiDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.playbackStates,
        aliasName: 'chapters__id__playback_states__chapter_id',
      );

  $$PlaybackStatesTableProcessedTableManager get playbackStatesRefs {
    final manager = $$PlaybackStatesTableTableManager(
      $_db,
      $_db.playbackStates,
    ).filter((f) => f.chapterId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_playbackStatesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ReadingStatesTable, List<ReadingStateRow>>
  _readingStatesRefsTable(_$KikuyomiDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.readingStates,
        aliasName: 'chapters__id__reading_states__chapter_id',
      );

  $$ReadingStatesTableProcessedTableManager get readingStatesRefs {
    final manager = $$ReadingStatesTableTableManager(
      $_db,
      $_db.readingStates,
    ).filter((f) => f.chapterId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_readingStatesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ReadingSessionsTable, List<ReadingSessionRow>>
  _readingSessionsRefsTable(_$KikuyomiDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.readingSessions,
        aliasName: 'chapters__id__reading_sessions__chapter_id',
      );

  $$ReadingSessionsTableProcessedTableManager get readingSessionsRefs {
    final manager = $$ReadingSessionsTableTableManager(
      $_db,
      $_db.readingSessions,
    ).filter((f) => f.chapterId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _readingSessionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ListeningSessionsTable, List<ListeningSessionRow>>
  _listeningSessionsRefsTable(_$KikuyomiDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.listeningSessions,
        aliasName: 'chapters__id__listening_sessions__chapter_id',
      );

  $$ListeningSessionsTableProcessedTableManager get listeningSessionsRefs {
    final manager = $$ListeningSessionsTableTableManager(
      $_db,
      $_db.listeningSessions,
    ).filter((f) => f.chapterId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _listeningSessionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$BookmarksTable, List<BookmarkRow>>
  _bookmarksRefsTable(_$KikuyomiDatabase db) => MultiTypedResultKey.fromTable(
    db.bookmarks,
    aliasName: 'chapters__id__bookmarks__chapter_id',
  );

  $$BookmarksTableProcessedTableManager get bookmarksRefs {
    final manager = $$BookmarksTableTableManager(
      $_db,
      $_db.bookmarks,
    ).filter((f) => f.chapterId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_bookmarksRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ChaptersTableFilterComposer
    extends Composer<_$KikuyomiDatabase, $ChaptersTable> {
  $$ChaptersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sourceIndex => $composableBuilder(
    column: $table.sourceIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get groupName => $composableBuilder(
    column: $table.groupName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get wordCount => $composableBuilder(
    column: $table.wordCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get publishedAt => $composableBuilder(
    column: $table.publishedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isListened => $composableBuilder(
    column: $table.isListened,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get listenedAt => $composableBuilder(
    column: $table.listenedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastPositionMs => $composableBuilder(
    column: $table.lastPositionMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get removedFromSource => $composableBuilder(
    column: $table.removedFromSource,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$BooksTableFilterComposer get bookId {
    final $$BooksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BooksTableFilterComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> chapterSegmentsRefs(
    Expression<bool> Function($$ChapterSegmentsTableFilterComposer f) f,
  ) {
    final $$ChapterSegmentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.chapterSegments,
      getReferencedColumn: (t) => t.chapterId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChapterSegmentsTableFilterComposer(
            $db: $db,
            $table: $db.chapterSegments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> playbackStatesRefs(
    Expression<bool> Function($$PlaybackStatesTableFilterComposer f) f,
  ) {
    final $$PlaybackStatesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.playbackStates,
      getReferencedColumn: (t) => t.chapterId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaybackStatesTableFilterComposer(
            $db: $db,
            $table: $db.playbackStates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> readingStatesRefs(
    Expression<bool> Function($$ReadingStatesTableFilterComposer f) f,
  ) {
    final $$ReadingStatesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.readingStates,
      getReferencedColumn: (t) => t.chapterId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReadingStatesTableFilterComposer(
            $db: $db,
            $table: $db.readingStates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> readingSessionsRefs(
    Expression<bool> Function($$ReadingSessionsTableFilterComposer f) f,
  ) {
    final $$ReadingSessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.readingSessions,
      getReferencedColumn: (t) => t.chapterId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReadingSessionsTableFilterComposer(
            $db: $db,
            $table: $db.readingSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> listeningSessionsRefs(
    Expression<bool> Function($$ListeningSessionsTableFilterComposer f) f,
  ) {
    final $$ListeningSessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.listeningSessions,
      getReferencedColumn: (t) => t.chapterId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ListeningSessionsTableFilterComposer(
            $db: $db,
            $table: $db.listeningSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> bookmarksRefs(
    Expression<bool> Function($$BookmarksTableFilterComposer f) f,
  ) {
    final $$BookmarksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.bookmarks,
      getReferencedColumn: (t) => t.chapterId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BookmarksTableFilterComposer(
            $db: $db,
            $table: $db.bookmarks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ChaptersTableOrderingComposer
    extends Composer<_$KikuyomiDatabase, $ChaptersTable> {
  $$ChaptersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sourceIndex => $composableBuilder(
    column: $table.sourceIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get groupName => $composableBuilder(
    column: $table.groupName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get wordCount => $composableBuilder(
    column: $table.wordCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get publishedAt => $composableBuilder(
    column: $table.publishedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isListened => $composableBuilder(
    column: $table.isListened,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get listenedAt => $composableBuilder(
    column: $table.listenedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastPositionMs => $composableBuilder(
    column: $table.lastPositionMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get removedFromSource => $composableBuilder(
    column: $table.removedFromSource,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$BooksTableOrderingComposer get bookId {
    final $$BooksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BooksTableOrderingComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ChaptersTableAnnotationComposer
    extends Composer<_$KikuyomiDatabase, $ChaptersTable> {
  $$ChaptersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<int> get sourceIndex => $composableBuilder(
    column: $table.sourceIndex,
    builder: (column) => column,
  );

  GeneratedColumn<String> get groupName =>
      $composableBuilder(column: $table.groupName, builder: (column) => column);

  GeneratedColumn<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get wordCount =>
      $composableBuilder(column: $table.wordCount, builder: (column) => column);

  GeneratedColumn<DateTime> get publishedAt => $composableBuilder(
    column: $table.publishedAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isListened => $composableBuilder(
    column: $table.isListened,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get listenedAt => $composableBuilder(
    column: $table.listenedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastPositionMs => $composableBuilder(
    column: $table.lastPositionMs,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get removedFromSource => $composableBuilder(
    column: $table.removedFromSource,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$BooksTableAnnotationComposer get bookId {
    final $$BooksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BooksTableAnnotationComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> chapterSegmentsRefs<T extends Object>(
    Expression<T> Function($$ChapterSegmentsTableAnnotationComposer a) f,
  ) {
    final $$ChapterSegmentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.chapterSegments,
      getReferencedColumn: (t) => t.chapterId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChapterSegmentsTableAnnotationComposer(
            $db: $db,
            $table: $db.chapterSegments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> playbackStatesRefs<T extends Object>(
    Expression<T> Function($$PlaybackStatesTableAnnotationComposer a) f,
  ) {
    final $$PlaybackStatesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.playbackStates,
      getReferencedColumn: (t) => t.chapterId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaybackStatesTableAnnotationComposer(
            $db: $db,
            $table: $db.playbackStates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> readingStatesRefs<T extends Object>(
    Expression<T> Function($$ReadingStatesTableAnnotationComposer a) f,
  ) {
    final $$ReadingStatesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.readingStates,
      getReferencedColumn: (t) => t.chapterId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReadingStatesTableAnnotationComposer(
            $db: $db,
            $table: $db.readingStates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> readingSessionsRefs<T extends Object>(
    Expression<T> Function($$ReadingSessionsTableAnnotationComposer a) f,
  ) {
    final $$ReadingSessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.readingSessions,
      getReferencedColumn: (t) => t.chapterId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReadingSessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.readingSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> listeningSessionsRefs<T extends Object>(
    Expression<T> Function($$ListeningSessionsTableAnnotationComposer a) f,
  ) {
    final $$ListeningSessionsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.listeningSessions,
          getReferencedColumn: (t) => t.chapterId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ListeningSessionsTableAnnotationComposer(
                $db: $db,
                $table: $db.listeningSessions,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> bookmarksRefs<T extends Object>(
    Expression<T> Function($$BookmarksTableAnnotationComposer a) f,
  ) {
    final $$BookmarksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.bookmarks,
      getReferencedColumn: (t) => t.chapterId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BookmarksTableAnnotationComposer(
            $db: $db,
            $table: $db.bookmarks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ChaptersTableTableManager
    extends
        RootTableManager<
          _$KikuyomiDatabase,
          $ChaptersTable,
          ChapterRow,
          $$ChaptersTableFilterComposer,
          $$ChaptersTableOrderingComposer,
          $$ChaptersTableAnnotationComposer,
          $$ChaptersTableCreateCompanionBuilder,
          $$ChaptersTableUpdateCompanionBuilder,
          (ChapterRow, $$ChaptersTableReferences),
          ChapterRow,
          PrefetchHooks Function({
            bool bookId,
            bool chapterSegmentsRefs,
            bool playbackStatesRefs,
            bool readingStatesRefs,
            bool readingSessionsRefs,
            bool listeningSessionsRefs,
            bool bookmarksRefs,
          })
        > {
  $$ChaptersTableTableManager(_$KikuyomiDatabase db, $ChaptersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChaptersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChaptersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChaptersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> bookId = const Value.absent(),
                Value<String> key = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<int> sourceIndex = const Value.absent(),
                Value<String?> groupName = const Value.absent(),
                Value<int?> durationMs = const Value.absent(),
                Value<int?> wordCount = const Value.absent(),
                Value<DateTime?> publishedAt = const Value.absent(),
                Value<bool> isListened = const Value.absent(),
                Value<DateTime?> listenedAt = const Value.absent(),
                Value<int> lastPositionMs = const Value.absent(),
                Value<bool> removedFromSource = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => ChaptersCompanion(
                id: id,
                bookId: bookId,
                key: key,
                title: title,
                sourceIndex: sourceIndex,
                groupName: groupName,
                durationMs: durationMs,
                wordCount: wordCount,
                publishedAt: publishedAt,
                isListened: isListened,
                listenedAt: listenedAt,
                lastPositionMs: lastPositionMs,
                removedFromSource: removedFromSource,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int bookId,
                required String key,
                required String title,
                required int sourceIndex,
                Value<String?> groupName = const Value.absent(),
                Value<int?> durationMs = const Value.absent(),
                Value<int?> wordCount = const Value.absent(),
                Value<DateTime?> publishedAt = const Value.absent(),
                Value<bool> isListened = const Value.absent(),
                Value<DateTime?> listenedAt = const Value.absent(),
                Value<int> lastPositionMs = const Value.absent(),
                Value<bool> removedFromSource = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
              }) => ChaptersCompanion.insert(
                id: id,
                bookId: bookId,
                key: key,
                title: title,
                sourceIndex: sourceIndex,
                groupName: groupName,
                durationMs: durationMs,
                wordCount: wordCount,
                publishedAt: publishedAt,
                isListened: isListened,
                listenedAt: listenedAt,
                lastPositionMs: lastPositionMs,
                removedFromSource: removedFromSource,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ChaptersTable, ChapterRow>(table),
                  $$ChaptersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                bookId = false,
                chapterSegmentsRefs = false,
                playbackStatesRefs = false,
                readingStatesRefs = false,
                readingSessionsRefs = false,
                listeningSessionsRefs = false,
                bookmarksRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (chapterSegmentsRefs) db.chapterSegments,
                    if (playbackStatesRefs) db.playbackStates,
                    if (readingStatesRefs) db.readingStates,
                    if (readingSessionsRefs) db.readingSessions,
                    if (listeningSessionsRefs) db.listeningSessions,
                    if (bookmarksRefs) db.bookmarks,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (bookId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.bookId,
                            referencedTable: $$ChaptersTableReferences
                                ._bookIdTable(db),
                            referencedColumn: $$ChaptersTableReferences
                                ._bookIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (chapterSegmentsRefs)
                        await $_getPrefetchedData<
                          ChapterRow,
                          $ChaptersTable,
                          ChapterSegmentRow
                        >(
                          currentTable: table,
                          referencedTable: $$ChaptersTableReferences
                              ._chapterSegmentsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ChaptersTableReferences(
                                db,
                                table,
                                p0,
                              ).chapterSegmentsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.chapterId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (playbackStatesRefs)
                        await $_getPrefetchedData<
                          ChapterRow,
                          $ChaptersTable,
                          PlaybackStateRow
                        >(
                          currentTable: table,
                          referencedTable: $$ChaptersTableReferences
                              ._playbackStatesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ChaptersTableReferences(
                                db,
                                table,
                                p0,
                              ).playbackStatesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.chapterId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (readingStatesRefs)
                        await $_getPrefetchedData<
                          ChapterRow,
                          $ChaptersTable,
                          ReadingStateRow
                        >(
                          currentTable: table,
                          referencedTable: $$ChaptersTableReferences
                              ._readingStatesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ChaptersTableReferences(
                                db,
                                table,
                                p0,
                              ).readingStatesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.chapterId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (readingSessionsRefs)
                        await $_getPrefetchedData<
                          ChapterRow,
                          $ChaptersTable,
                          ReadingSessionRow
                        >(
                          currentTable: table,
                          referencedTable: $$ChaptersTableReferences
                              ._readingSessionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ChaptersTableReferences(
                                db,
                                table,
                                p0,
                              ).readingSessionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.chapterId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (listeningSessionsRefs)
                        await $_getPrefetchedData<
                          ChapterRow,
                          $ChaptersTable,
                          ListeningSessionRow
                        >(
                          currentTable: table,
                          referencedTable: $$ChaptersTableReferences
                              ._listeningSessionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ChaptersTableReferences(
                                db,
                                table,
                                p0,
                              ).listeningSessionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.chapterId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (bookmarksRefs)
                        await $_getPrefetchedData<
                          ChapterRow,
                          $ChaptersTable,
                          BookmarkRow
                        >(
                          currentTable: table,
                          referencedTable: $$ChaptersTableReferences
                              ._bookmarksRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ChaptersTableReferences(
                                db,
                                table,
                                p0,
                              ).bookmarksRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.chapterId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ChaptersTableProcessedTableManager =
    ProcessedTableManager<
      _$KikuyomiDatabase,
      $ChaptersTable,
      ChapterRow,
      $$ChaptersTableFilterComposer,
      $$ChaptersTableOrderingComposer,
      $$ChaptersTableAnnotationComposer,
      $$ChaptersTableCreateCompanionBuilder,
      $$ChaptersTableUpdateCompanionBuilder,
      (ChapterRow, $$ChaptersTableReferences),
      ChapterRow,
      PrefetchHooks Function({
        bool bookId,
        bool chapterSegmentsRefs,
        bool playbackStatesRefs,
        bool readingStatesRefs,
        bool readingSessionsRefs,
        bool listeningSessionsRefs,
        bool bookmarksRefs,
      })
    >;
typedef $$MediaFilesTableCreateCompanionBuilder = MediaFilesCompanion Function({
  Value<int> id,
  required int bookId,
  required String fileKey,
  Value<String?> format,
  Value<int?> durationMs,
  Value<bool> durationIsEstimate,
  Value<int?> sizeBytes,
  Value<List<TimelineMarker>?> embeddedMarkers,
  Value<String?> localPath,
  Value<DateTime?> downloadedAt,
});
typedef $$MediaFilesTableUpdateCompanionBuilder = MediaFilesCompanion Function({
  Value<int> id,
  Value<int> bookId,
  Value<String> fileKey,
  Value<String?> format,
  Value<int?> durationMs,
  Value<bool> durationIsEstimate,
  Value<int?> sizeBytes,
  Value<List<TimelineMarker>?> embeddedMarkers,
  Value<String?> localPath,
  Value<DateTime?> downloadedAt,
});

final class $$MediaFilesTableReferences
    extends BaseReferences<_$KikuyomiDatabase, $MediaFilesTable, MediaFileRow> {
  $$MediaFilesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $BooksTable _bookIdTable(_$KikuyomiDatabase db) =>
      db.books.createAlias('media_files__book_id__books__id');

  $$BooksTableProcessedTableManager get bookId {
    final $_column = $_itemColumn<int>('book_id')!;

    final manager = $$BooksTableTableManager(
      $_db,
      $_db.books,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_bookIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$ChapterSegmentsTable, List<ChapterSegmentRow>>
  _chapterSegmentsRefsTable(_$KikuyomiDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.chapterSegments,
        aliasName: 'media_files__id__chapter_segments__media_file_id',
      );

  $$ChapterSegmentsTableProcessedTableManager get chapterSegmentsRefs {
    final manager = $$ChapterSegmentsTableTableManager(
      $_db,
      $_db.chapterSegments,
    ).filter((f) => f.mediaFileId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _chapterSegmentsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$DownloadTasksTable, List<DownloadTaskRow>>
  _downloadTasksRefsTable(_$KikuyomiDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.downloadTasks,
        aliasName: 'media_files__id__download_tasks__media_file_id',
      );

  $$DownloadTasksTableProcessedTableManager get downloadTasksRefs {
    final manager = $$DownloadTasksTableTableManager(
      $_db,
      $_db.downloadTasks,
    ).filter((f) => f.mediaFileId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_downloadTasksRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$MediaFilesTableFilterComposer
    extends Composer<_$KikuyomiDatabase, $MediaFilesTable> {
  $$MediaFilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileKey => $composableBuilder(
    column: $table.fileKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get format => $composableBuilder(
    column: $table.format,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get durationIsEstimate => $composableBuilder(
    column: $table.durationIsEstimate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<
    List<TimelineMarker>?,
    List<TimelineMarker>,
    String
  >
  get embeddedMarkers => $composableBuilder(
    column: $table.embeddedMarkers,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get downloadedAt => $composableBuilder(
    column: $table.downloadedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$BooksTableFilterComposer get bookId {
    final $$BooksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BooksTableFilterComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> chapterSegmentsRefs(
    Expression<bool> Function($$ChapterSegmentsTableFilterComposer f) f,
  ) {
    final $$ChapterSegmentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.chapterSegments,
      getReferencedColumn: (t) => t.mediaFileId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChapterSegmentsTableFilterComposer(
            $db: $db,
            $table: $db.chapterSegments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> downloadTasksRefs(
    Expression<bool> Function($$DownloadTasksTableFilterComposer f) f,
  ) {
    final $$DownloadTasksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.downloadTasks,
      getReferencedColumn: (t) => t.mediaFileId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DownloadTasksTableFilterComposer(
            $db: $db,
            $table: $db.downloadTasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MediaFilesTableOrderingComposer
    extends Composer<_$KikuyomiDatabase, $MediaFilesTable> {
  $$MediaFilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileKey => $composableBuilder(
    column: $table.fileKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get format => $composableBuilder(
    column: $table.format,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get durationIsEstimate => $composableBuilder(
    column: $table.durationIsEstimate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get embeddedMarkers => $composableBuilder(
    column: $table.embeddedMarkers,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get downloadedAt => $composableBuilder(
    column: $table.downloadedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$BooksTableOrderingComposer get bookId {
    final $$BooksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BooksTableOrderingComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MediaFilesTableAnnotationComposer
    extends Composer<_$KikuyomiDatabase, $MediaFilesTable> {
  $$MediaFilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get fileKey =>
      $composableBuilder(column: $table.fileKey, builder: (column) => column);

  GeneratedColumn<String> get format =>
      $composableBuilder(column: $table.format, builder: (column) => column);

  GeneratedColumn<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get durationIsEstimate => $composableBuilder(
    column: $table.durationIsEstimate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sizeBytes =>
      $composableBuilder(column: $table.sizeBytes, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<TimelineMarker>?, String>
  get embeddedMarkers => $composableBuilder(
    column: $table.embeddedMarkers,
    builder: (column) => column,
  );

  GeneratedColumn<String> get localPath =>
      $composableBuilder(column: $table.localPath, builder: (column) => column);

  GeneratedColumn<DateTime> get downloadedAt => $composableBuilder(
    column: $table.downloadedAt,
    builder: (column) => column,
  );

  $$BooksTableAnnotationComposer get bookId {
    final $$BooksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BooksTableAnnotationComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> chapterSegmentsRefs<T extends Object>(
    Expression<T> Function($$ChapterSegmentsTableAnnotationComposer a) f,
  ) {
    final $$ChapterSegmentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.chapterSegments,
      getReferencedColumn: (t) => t.mediaFileId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChapterSegmentsTableAnnotationComposer(
            $db: $db,
            $table: $db.chapterSegments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> downloadTasksRefs<T extends Object>(
    Expression<T> Function($$DownloadTasksTableAnnotationComposer a) f,
  ) {
    final $$DownloadTasksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.downloadTasks,
      getReferencedColumn: (t) => t.mediaFileId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DownloadTasksTableAnnotationComposer(
            $db: $db,
            $table: $db.downloadTasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MediaFilesTableTableManager
    extends
        RootTableManager<
          _$KikuyomiDatabase,
          $MediaFilesTable,
          MediaFileRow,
          $$MediaFilesTableFilterComposer,
          $$MediaFilesTableOrderingComposer,
          $$MediaFilesTableAnnotationComposer,
          $$MediaFilesTableCreateCompanionBuilder,
          $$MediaFilesTableUpdateCompanionBuilder,
          (MediaFileRow, $$MediaFilesTableReferences),
          MediaFileRow,
          PrefetchHooks Function({
            bool bookId,
            bool chapterSegmentsRefs,
            bool downloadTasksRefs,
          })
        > {
  $$MediaFilesTableTableManager(_$KikuyomiDatabase db, $MediaFilesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MediaFilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MediaFilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MediaFilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> bookId = const Value.absent(),
                Value<String> fileKey = const Value.absent(),
                Value<String?> format = const Value.absent(),
                Value<int?> durationMs = const Value.absent(),
                Value<bool> durationIsEstimate = const Value.absent(),
                Value<int?> sizeBytes = const Value.absent(),
                Value<List<TimelineMarker>?> embeddedMarkers =
                    const Value.absent(),
                Value<String?> localPath = const Value.absent(),
                Value<DateTime?> downloadedAt = const Value.absent(),
              }) => MediaFilesCompanion(
                id: id,
                bookId: bookId,
                fileKey: fileKey,
                format: format,
                durationMs: durationMs,
                durationIsEstimate: durationIsEstimate,
                sizeBytes: sizeBytes,
                embeddedMarkers: embeddedMarkers,
                localPath: localPath,
                downloadedAt: downloadedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int bookId,
                required String fileKey,
                Value<String?> format = const Value.absent(),
                Value<int?> durationMs = const Value.absent(),
                Value<bool> durationIsEstimate = const Value.absent(),
                Value<int?> sizeBytes = const Value.absent(),
                Value<List<TimelineMarker>?> embeddedMarkers =
                    const Value.absent(),
                Value<String?> localPath = const Value.absent(),
                Value<DateTime?> downloadedAt = const Value.absent(),
              }) => MediaFilesCompanion.insert(
                id: id,
                bookId: bookId,
                fileKey: fileKey,
                format: format,
                durationMs: durationMs,
                durationIsEstimate: durationIsEstimate,
                sizeBytes: sizeBytes,
                embeddedMarkers: embeddedMarkers,
                localPath: localPath,
                downloadedAt: downloadedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MediaFilesTable, MediaFileRow>(table),
                  $$MediaFilesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                bookId = false,
                chapterSegmentsRefs = false,
                downloadTasksRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (chapterSegmentsRefs) db.chapterSegments,
                    if (downloadTasksRefs) db.downloadTasks,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (bookId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.bookId,
                            referencedTable: $$MediaFilesTableReferences
                                ._bookIdTable(db),
                            referencedColumn: $$MediaFilesTableReferences
                                ._bookIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (chapterSegmentsRefs)
                        await $_getPrefetchedData<
                          MediaFileRow,
                          $MediaFilesTable,
                          ChapterSegmentRow
                        >(
                          currentTable: table,
                          referencedTable: $$MediaFilesTableReferences
                              ._chapterSegmentsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MediaFilesTableReferences(
                                db,
                                table,
                                p0,
                              ).chapterSegmentsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.mediaFileId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (downloadTasksRefs)
                        await $_getPrefetchedData<
                          MediaFileRow,
                          $MediaFilesTable,
                          DownloadTaskRow
                        >(
                          currentTable: table,
                          referencedTable: $$MediaFilesTableReferences
                              ._downloadTasksRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MediaFilesTableReferences(
                                db,
                                table,
                                p0,
                              ).downloadTasksRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.mediaFileId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$MediaFilesTableProcessedTableManager =
    ProcessedTableManager<
      _$KikuyomiDatabase,
      $MediaFilesTable,
      MediaFileRow,
      $$MediaFilesTableFilterComposer,
      $$MediaFilesTableOrderingComposer,
      $$MediaFilesTableAnnotationComposer,
      $$MediaFilesTableCreateCompanionBuilder,
      $$MediaFilesTableUpdateCompanionBuilder,
      (MediaFileRow, $$MediaFilesTableReferences),
      MediaFileRow,
      PrefetchHooks Function({
        bool bookId,
        bool chapterSegmentsRefs,
        bool downloadTasksRefs,
      })
    >;
typedef $$ChapterSegmentsTableCreateCompanionBuilder =
    ChapterSegmentsCompanion Function({
      required int chapterId,
      required int ordinal,
      required int mediaFileId,
      Value<int> startMs,
      Value<int?> endMs,
      Value<int> rowid,
    });
typedef $$ChapterSegmentsTableUpdateCompanionBuilder =
    ChapterSegmentsCompanion Function({
      Value<int> chapterId,
      Value<int> ordinal,
      Value<int> mediaFileId,
      Value<int> startMs,
      Value<int?> endMs,
      Value<int> rowid,
    });

final class $$ChapterSegmentsTableReferences
    extends
        BaseReferences<
          _$KikuyomiDatabase,
          $ChapterSegmentsTable,
          ChapterSegmentRow
        > {
  $$ChapterSegmentsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ChaptersTable _chapterIdTable(_$KikuyomiDatabase db) =>
      db.chapters.createAlias('chapter_segments__chapter_id__chapters__id');

  $$ChaptersTableProcessedTableManager get chapterId {
    final $_column = $_itemColumn<int>('chapter_id')!;

    final manager = $$ChaptersTableTableManager(
      $_db,
      $_db.chapters,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_chapterIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $MediaFilesTable _mediaFileIdTable(_$KikuyomiDatabase db) => db
      .mediaFiles
      .createAlias('chapter_segments__media_file_id__media_files__id');

  $$MediaFilesTableProcessedTableManager get mediaFileId {
    final $_column = $_itemColumn<int>('media_file_id')!;

    final manager = $$MediaFilesTableTableManager(
      $_db,
      $_db.mediaFiles,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_mediaFileIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ChapterSegmentsTableFilterComposer
    extends Composer<_$KikuyomiDatabase, $ChapterSegmentsTable> {
  $$ChapterSegmentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get ordinal => $composableBuilder(
    column: $table.ordinal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startMs => $composableBuilder(
    column: $table.startMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endMs => $composableBuilder(
    column: $table.endMs,
    builder: (column) => ColumnFilters(column),
  );

  $$ChaptersTableFilterComposer get chapterId {
    final $$ChaptersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.chapterId,
      referencedTable: $db.chapters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChaptersTableFilterComposer(
            $db: $db,
            $table: $db.chapters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MediaFilesTableFilterComposer get mediaFileId {
    final $$MediaFilesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.mediaFileId,
      referencedTable: $db.mediaFiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MediaFilesTableFilterComposer(
            $db: $db,
            $table: $db.mediaFiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ChapterSegmentsTableOrderingComposer
    extends Composer<_$KikuyomiDatabase, $ChapterSegmentsTable> {
  $$ChapterSegmentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get ordinal => $composableBuilder(
    column: $table.ordinal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startMs => $composableBuilder(
    column: $table.startMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endMs => $composableBuilder(
    column: $table.endMs,
    builder: (column) => ColumnOrderings(column),
  );

  $$ChaptersTableOrderingComposer get chapterId {
    final $$ChaptersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.chapterId,
      referencedTable: $db.chapters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChaptersTableOrderingComposer(
            $db: $db,
            $table: $db.chapters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MediaFilesTableOrderingComposer get mediaFileId {
    final $$MediaFilesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.mediaFileId,
      referencedTable: $db.mediaFiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MediaFilesTableOrderingComposer(
            $db: $db,
            $table: $db.mediaFiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ChapterSegmentsTableAnnotationComposer
    extends Composer<_$KikuyomiDatabase, $ChapterSegmentsTable> {
  $$ChapterSegmentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get ordinal =>
      $composableBuilder(column: $table.ordinal, builder: (column) => column);

  GeneratedColumn<int> get startMs =>
      $composableBuilder(column: $table.startMs, builder: (column) => column);

  GeneratedColumn<int> get endMs =>
      $composableBuilder(column: $table.endMs, builder: (column) => column);

  $$ChaptersTableAnnotationComposer get chapterId {
    final $$ChaptersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.chapterId,
      referencedTable: $db.chapters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChaptersTableAnnotationComposer(
            $db: $db,
            $table: $db.chapters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MediaFilesTableAnnotationComposer get mediaFileId {
    final $$MediaFilesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.mediaFileId,
      referencedTable: $db.mediaFiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MediaFilesTableAnnotationComposer(
            $db: $db,
            $table: $db.mediaFiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ChapterSegmentsTableTableManager
    extends
        RootTableManager<
          _$KikuyomiDatabase,
          $ChapterSegmentsTable,
          ChapterSegmentRow,
          $$ChapterSegmentsTableFilterComposer,
          $$ChapterSegmentsTableOrderingComposer,
          $$ChapterSegmentsTableAnnotationComposer,
          $$ChapterSegmentsTableCreateCompanionBuilder,
          $$ChapterSegmentsTableUpdateCompanionBuilder,
          (ChapterSegmentRow, $$ChapterSegmentsTableReferences),
          ChapterSegmentRow,
          PrefetchHooks Function({bool chapterId, bool mediaFileId})
        > {
  $$ChapterSegmentsTableTableManager(
    _$KikuyomiDatabase db,
    $ChapterSegmentsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChapterSegmentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChapterSegmentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChapterSegmentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> chapterId = const Value.absent(),
                Value<int> ordinal = const Value.absent(),
                Value<int> mediaFileId = const Value.absent(),
                Value<int> startMs = const Value.absent(),
                Value<int?> endMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ChapterSegmentsCompanion(
                chapterId: chapterId,
                ordinal: ordinal,
                mediaFileId: mediaFileId,
                startMs: startMs,
                endMs: endMs,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int chapterId,
                required int ordinal,
                required int mediaFileId,
                Value<int> startMs = const Value.absent(),
                Value<int?> endMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ChapterSegmentsCompanion.insert(
                chapterId: chapterId,
                ordinal: ordinal,
                mediaFileId: mediaFileId,
                startMs: startMs,
                endMs: endMs,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ChapterSegmentsTable, ChapterSegmentRow>(table),
                  $$ChapterSegmentsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({chapterId = false, mediaFileId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (chapterId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.chapterId,
                        referencedTable: $$ChapterSegmentsTableReferences
                            ._chapterIdTable(db),
                        referencedColumn: $$ChapterSegmentsTableReferences
                            ._chapterIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (mediaFileId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.mediaFileId,
                        referencedTable: $$ChapterSegmentsTableReferences
                            ._mediaFileIdTable(db),
                        referencedColumn: $$ChapterSegmentsTableReferences
                            ._mediaFileIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ChapterSegmentsTableProcessedTableManager =
    ProcessedTableManager<
      _$KikuyomiDatabase,
      $ChapterSegmentsTable,
      ChapterSegmentRow,
      $$ChapterSegmentsTableFilterComposer,
      $$ChapterSegmentsTableOrderingComposer,
      $$ChapterSegmentsTableAnnotationComposer,
      $$ChapterSegmentsTableCreateCompanionBuilder,
      $$ChapterSegmentsTableUpdateCompanionBuilder,
      (ChapterSegmentRow, $$ChapterSegmentsTableReferences),
      ChapterSegmentRow,
      PrefetchHooks Function({bool chapterId, bool mediaFileId})
    >;
typedef $$PlaybackStatesTableCreateCompanionBuilder =
    PlaybackStatesCompanion Function({
      Value<int> bookId,
      required int chapterId,
      required int chapterPositionMs,
      required int globalPositionMs,
      required DateTime updatedAt,
      required String deviceId,
    });
typedef $$PlaybackStatesTableUpdateCompanionBuilder =
    PlaybackStatesCompanion Function({
      Value<int> bookId,
      Value<int> chapterId,
      Value<int> chapterPositionMs,
      Value<int> globalPositionMs,
      Value<DateTime> updatedAt,
      Value<String> deviceId,
    });

final class $$PlaybackStatesTableReferences
    extends
        BaseReferences<
          _$KikuyomiDatabase,
          $PlaybackStatesTable,
          PlaybackStateRow
        > {
  $$PlaybackStatesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $BooksTable _bookIdTable(_$KikuyomiDatabase db) =>
      db.books.createAlias('playback_states__book_id__books__id');

  $$BooksTableProcessedTableManager get bookId {
    final $_column = $_itemColumn<int>('book_id')!;

    final manager = $$BooksTableTableManager(
      $_db,
      $_db.books,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_bookIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ChaptersTable _chapterIdTable(_$KikuyomiDatabase db) =>
      db.chapters.createAlias('playback_states__chapter_id__chapters__id');

  $$ChaptersTableProcessedTableManager get chapterId {
    final $_column = $_itemColumn<int>('chapter_id')!;

    final manager = $$ChaptersTableTableManager(
      $_db,
      $_db.chapters,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_chapterIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PlaybackStatesTableFilterComposer
    extends Composer<_$KikuyomiDatabase, $PlaybackStatesTable> {
  $$PlaybackStatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get chapterPositionMs => $composableBuilder(
    column: $table.chapterPositionMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get globalPositionMs => $composableBuilder(
    column: $table.globalPositionMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  $$BooksTableFilterComposer get bookId {
    final $$BooksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BooksTableFilterComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ChaptersTableFilterComposer get chapterId {
    final $$ChaptersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.chapterId,
      referencedTable: $db.chapters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChaptersTableFilterComposer(
            $db: $db,
            $table: $db.chapters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlaybackStatesTableOrderingComposer
    extends Composer<_$KikuyomiDatabase, $PlaybackStatesTable> {
  $$PlaybackStatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get chapterPositionMs => $composableBuilder(
    column: $table.chapterPositionMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get globalPositionMs => $composableBuilder(
    column: $table.globalPositionMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  $$BooksTableOrderingComposer get bookId {
    final $$BooksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BooksTableOrderingComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ChaptersTableOrderingComposer get chapterId {
    final $$ChaptersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.chapterId,
      referencedTable: $db.chapters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChaptersTableOrderingComposer(
            $db: $db,
            $table: $db.chapters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlaybackStatesTableAnnotationComposer
    extends Composer<_$KikuyomiDatabase, $PlaybackStatesTable> {
  $$PlaybackStatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get chapterPositionMs => $composableBuilder(
    column: $table.chapterPositionMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get globalPositionMs => $composableBuilder(
    column: $table.globalPositionMs,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  $$BooksTableAnnotationComposer get bookId {
    final $$BooksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BooksTableAnnotationComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ChaptersTableAnnotationComposer get chapterId {
    final $$ChaptersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.chapterId,
      referencedTable: $db.chapters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChaptersTableAnnotationComposer(
            $db: $db,
            $table: $db.chapters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlaybackStatesTableTableManager
    extends
        RootTableManager<
          _$KikuyomiDatabase,
          $PlaybackStatesTable,
          PlaybackStateRow,
          $$PlaybackStatesTableFilterComposer,
          $$PlaybackStatesTableOrderingComposer,
          $$PlaybackStatesTableAnnotationComposer,
          $$PlaybackStatesTableCreateCompanionBuilder,
          $$PlaybackStatesTableUpdateCompanionBuilder,
          (PlaybackStateRow, $$PlaybackStatesTableReferences),
          PlaybackStateRow,
          PrefetchHooks Function({bool bookId, bool chapterId})
        > {
  $$PlaybackStatesTableTableManager(
    _$KikuyomiDatabase db,
    $PlaybackStatesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlaybackStatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlaybackStatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlaybackStatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> bookId = const Value.absent(),
                Value<int> chapterId = const Value.absent(),
                Value<int> chapterPositionMs = const Value.absent(),
                Value<int> globalPositionMs = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
              }) => PlaybackStatesCompanion(
                bookId: bookId,
                chapterId: chapterId,
                chapterPositionMs: chapterPositionMs,
                globalPositionMs: globalPositionMs,
                updatedAt: updatedAt,
                deviceId: deviceId,
              ),
          createCompanionCallback:
              ({
                Value<int> bookId = const Value.absent(),
                required int chapterId,
                required int chapterPositionMs,
                required int globalPositionMs,
                required DateTime updatedAt,
                required String deviceId,
              }) => PlaybackStatesCompanion.insert(
                bookId: bookId,
                chapterId: chapterId,
                chapterPositionMs: chapterPositionMs,
                globalPositionMs: globalPositionMs,
                updatedAt: updatedAt,
                deviceId: deviceId,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PlaybackStatesTable, PlaybackStateRow>(table),
                  $$PlaybackStatesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({bookId = false, chapterId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (bookId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.bookId,
                        referencedTable: $$PlaybackStatesTableReferences
                            ._bookIdTable(db),
                        referencedColumn: $$PlaybackStatesTableReferences
                            ._bookIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (chapterId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.chapterId,
                        referencedTable: $$PlaybackStatesTableReferences
                            ._chapterIdTable(db),
                        referencedColumn: $$PlaybackStatesTableReferences
                            ._chapterIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PlaybackStatesTableProcessedTableManager =
    ProcessedTableManager<
      _$KikuyomiDatabase,
      $PlaybackStatesTable,
      PlaybackStateRow,
      $$PlaybackStatesTableFilterComposer,
      $$PlaybackStatesTableOrderingComposer,
      $$PlaybackStatesTableAnnotationComposer,
      $$PlaybackStatesTableCreateCompanionBuilder,
      $$PlaybackStatesTableUpdateCompanionBuilder,
      (PlaybackStateRow, $$PlaybackStatesTableReferences),
      PlaybackStateRow,
      PrefetchHooks Function({bool bookId, bool chapterId})
    >;
typedef $$ReadingStatesTableCreateCompanionBuilder =
    ReadingStatesCompanion Function({
      Value<int> bookId,
      required int chapterId,
      required double progress,
      required DateTime updatedAt,
    });
typedef $$ReadingStatesTableUpdateCompanionBuilder =
    ReadingStatesCompanion Function({
      Value<int> bookId,
      Value<int> chapterId,
      Value<double> progress,
      Value<DateTime> updatedAt,
    });

final class $$ReadingStatesTableReferences
    extends
        BaseReferences<
          _$KikuyomiDatabase,
          $ReadingStatesTable,
          ReadingStateRow
        > {
  $$ReadingStatesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $BooksTable _bookIdTable(_$KikuyomiDatabase db) =>
      db.books.createAlias('reading_states__book_id__books__id');

  $$BooksTableProcessedTableManager get bookId {
    final $_column = $_itemColumn<int>('book_id')!;

    final manager = $$BooksTableTableManager(
      $_db,
      $_db.books,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_bookIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ChaptersTable _chapterIdTable(_$KikuyomiDatabase db) =>
      db.chapters.createAlias('reading_states__chapter_id__chapters__id');

  $$ChaptersTableProcessedTableManager get chapterId {
    final $_column = $_itemColumn<int>('chapter_id')!;

    final manager = $$ChaptersTableTableManager(
      $_db,
      $_db.chapters,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_chapterIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ReadingStatesTableFilterComposer
    extends Composer<_$KikuyomiDatabase, $ReadingStatesTable> {
  $$ReadingStatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<double> get progress => $composableBuilder(
    column: $table.progress,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$BooksTableFilterComposer get bookId {
    final $$BooksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BooksTableFilterComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ChaptersTableFilterComposer get chapterId {
    final $$ChaptersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.chapterId,
      referencedTable: $db.chapters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChaptersTableFilterComposer(
            $db: $db,
            $table: $db.chapters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReadingStatesTableOrderingComposer
    extends Composer<_$KikuyomiDatabase, $ReadingStatesTable> {
  $$ReadingStatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<double> get progress => $composableBuilder(
    column: $table.progress,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$BooksTableOrderingComposer get bookId {
    final $$BooksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BooksTableOrderingComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ChaptersTableOrderingComposer get chapterId {
    final $$ChaptersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.chapterId,
      referencedTable: $db.chapters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChaptersTableOrderingComposer(
            $db: $db,
            $table: $db.chapters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReadingStatesTableAnnotationComposer
    extends Composer<_$KikuyomiDatabase, $ReadingStatesTable> {
  $$ReadingStatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<double> get progress =>
      $composableBuilder(column: $table.progress, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$BooksTableAnnotationComposer get bookId {
    final $$BooksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BooksTableAnnotationComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ChaptersTableAnnotationComposer get chapterId {
    final $$ChaptersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.chapterId,
      referencedTable: $db.chapters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChaptersTableAnnotationComposer(
            $db: $db,
            $table: $db.chapters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReadingStatesTableTableManager
    extends
        RootTableManager<
          _$KikuyomiDatabase,
          $ReadingStatesTable,
          ReadingStateRow,
          $$ReadingStatesTableFilterComposer,
          $$ReadingStatesTableOrderingComposer,
          $$ReadingStatesTableAnnotationComposer,
          $$ReadingStatesTableCreateCompanionBuilder,
          $$ReadingStatesTableUpdateCompanionBuilder,
          (ReadingStateRow, $$ReadingStatesTableReferences),
          ReadingStateRow,
          PrefetchHooks Function({bool bookId, bool chapterId})
        > {
  $$ReadingStatesTableTableManager(
    _$KikuyomiDatabase db,
    $ReadingStatesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReadingStatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReadingStatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReadingStatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> bookId = const Value.absent(),
                Value<int> chapterId = const Value.absent(),
                Value<double> progress = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => ReadingStatesCompanion(
                bookId: bookId,
                chapterId: chapterId,
                progress: progress,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> bookId = const Value.absent(),
                required int chapterId,
                required double progress,
                required DateTime updatedAt,
              }) => ReadingStatesCompanion.insert(
                bookId: bookId,
                chapterId: chapterId,
                progress: progress,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ReadingStatesTable, ReadingStateRow>(table),
                  $$ReadingStatesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({bookId = false, chapterId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (bookId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.bookId,
                        referencedTable: $$ReadingStatesTableReferences
                            ._bookIdTable(db),
                        referencedColumn: $$ReadingStatesTableReferences
                            ._bookIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (chapterId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.chapterId,
                        referencedTable: $$ReadingStatesTableReferences
                            ._chapterIdTable(db),
                        referencedColumn: $$ReadingStatesTableReferences
                            ._chapterIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ReadingStatesTableProcessedTableManager =
    ProcessedTableManager<
      _$KikuyomiDatabase,
      $ReadingStatesTable,
      ReadingStateRow,
      $$ReadingStatesTableFilterComposer,
      $$ReadingStatesTableOrderingComposer,
      $$ReadingStatesTableAnnotationComposer,
      $$ReadingStatesTableCreateCompanionBuilder,
      $$ReadingStatesTableUpdateCompanionBuilder,
      (ReadingStateRow, $$ReadingStatesTableReferences),
      ReadingStateRow,
      PrefetchHooks Function({bool bookId, bool chapterId})
    >;
typedef $$ReadingSessionsTableCreateCompanionBuilder =
    ReadingSessionsCompanion Function({
      Value<int> id,
      required int bookId,
      Value<int?> chapterId,
      required DateTime startedAt,
      required DateTime endedAt,
      required String deviceId,
    });
typedef $$ReadingSessionsTableUpdateCompanionBuilder =
    ReadingSessionsCompanion Function({
      Value<int> id,
      Value<int> bookId,
      Value<int?> chapterId,
      Value<DateTime> startedAt,
      Value<DateTime> endedAt,
      Value<String> deviceId,
    });

final class $$ReadingSessionsTableReferences
    extends
        BaseReferences<
          _$KikuyomiDatabase,
          $ReadingSessionsTable,
          ReadingSessionRow
        > {
  $$ReadingSessionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $BooksTable _bookIdTable(_$KikuyomiDatabase db) =>
      db.books.createAlias('reading_sessions__book_id__books__id');

  $$BooksTableProcessedTableManager get bookId {
    final $_column = $_itemColumn<int>('book_id')!;

    final manager = $$BooksTableTableManager(
      $_db,
      $_db.books,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_bookIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ChaptersTable _chapterIdTable(_$KikuyomiDatabase db) =>
      db.chapters.createAlias('reading_sessions__chapter_id__chapters__id');

  $$ChaptersTableProcessedTableManager? get chapterId {
    final $_column = $_itemColumn<int>('chapter_id');
    if ($_column == null) return null;
    final manager = $$ChaptersTableTableManager(
      $_db,
      $_db.chapters,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_chapterIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ReadingSessionsTableFilterComposer
    extends Composer<_$KikuyomiDatabase, $ReadingSessionsTable> {
  $$ReadingSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  $$BooksTableFilterComposer get bookId {
    final $$BooksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BooksTableFilterComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ChaptersTableFilterComposer get chapterId {
    final $$ChaptersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.chapterId,
      referencedTable: $db.chapters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChaptersTableFilterComposer(
            $db: $db,
            $table: $db.chapters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReadingSessionsTableOrderingComposer
    extends Composer<_$KikuyomiDatabase, $ReadingSessionsTable> {
  $$ReadingSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  $$BooksTableOrderingComposer get bookId {
    final $$BooksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BooksTableOrderingComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ChaptersTableOrderingComposer get chapterId {
    final $$ChaptersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.chapterId,
      referencedTable: $db.chapters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChaptersTableOrderingComposer(
            $db: $db,
            $table: $db.chapters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReadingSessionsTableAnnotationComposer
    extends Composer<_$KikuyomiDatabase, $ReadingSessionsTable> {
  $$ReadingSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  $$BooksTableAnnotationComposer get bookId {
    final $$BooksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BooksTableAnnotationComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ChaptersTableAnnotationComposer get chapterId {
    final $$ChaptersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.chapterId,
      referencedTable: $db.chapters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChaptersTableAnnotationComposer(
            $db: $db,
            $table: $db.chapters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReadingSessionsTableTableManager
    extends
        RootTableManager<
          _$KikuyomiDatabase,
          $ReadingSessionsTable,
          ReadingSessionRow,
          $$ReadingSessionsTableFilterComposer,
          $$ReadingSessionsTableOrderingComposer,
          $$ReadingSessionsTableAnnotationComposer,
          $$ReadingSessionsTableCreateCompanionBuilder,
          $$ReadingSessionsTableUpdateCompanionBuilder,
          (ReadingSessionRow, $$ReadingSessionsTableReferences),
          ReadingSessionRow,
          PrefetchHooks Function({bool bookId, bool chapterId})
        > {
  $$ReadingSessionsTableTableManager(
    _$KikuyomiDatabase db,
    $ReadingSessionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReadingSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReadingSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReadingSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> bookId = const Value.absent(),
                Value<int?> chapterId = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime> endedAt = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
              }) => ReadingSessionsCompanion(
                id: id,
                bookId: bookId,
                chapterId: chapterId,
                startedAt: startedAt,
                endedAt: endedAt,
                deviceId: deviceId,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int bookId,
                Value<int?> chapterId = const Value.absent(),
                required DateTime startedAt,
                required DateTime endedAt,
                required String deviceId,
              }) => ReadingSessionsCompanion.insert(
                id: id,
                bookId: bookId,
                chapterId: chapterId,
                startedAt: startedAt,
                endedAt: endedAt,
                deviceId: deviceId,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ReadingSessionsTable, ReadingSessionRow>(table),
                  $$ReadingSessionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({bookId = false, chapterId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (bookId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.bookId,
                        referencedTable: $$ReadingSessionsTableReferences
                            ._bookIdTable(db),
                        referencedColumn: $$ReadingSessionsTableReferences
                            ._bookIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (chapterId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.chapterId,
                        referencedTable: $$ReadingSessionsTableReferences
                            ._chapterIdTable(db),
                        referencedColumn: $$ReadingSessionsTableReferences
                            ._chapterIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ReadingSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$KikuyomiDatabase,
      $ReadingSessionsTable,
      ReadingSessionRow,
      $$ReadingSessionsTableFilterComposer,
      $$ReadingSessionsTableOrderingComposer,
      $$ReadingSessionsTableAnnotationComposer,
      $$ReadingSessionsTableCreateCompanionBuilder,
      $$ReadingSessionsTableUpdateCompanionBuilder,
      (ReadingSessionRow, $$ReadingSessionsTableReferences),
      ReadingSessionRow,
      PrefetchHooks Function({bool bookId, bool chapterId})
    >;
typedef $$ListeningSessionsTableCreateCompanionBuilder =
    ListeningSessionsCompanion Function({
      Value<int> id,
      required int bookId,
      Value<int?> chapterId,
      required DateTime startedAt,
      required DateTime endedAt,
      required int startGlobalMs,
      required int endGlobalMs,
      required double speed,
      required String deviceId,
    });
typedef $$ListeningSessionsTableUpdateCompanionBuilder =
    ListeningSessionsCompanion Function({
      Value<int> id,
      Value<int> bookId,
      Value<int?> chapterId,
      Value<DateTime> startedAt,
      Value<DateTime> endedAt,
      Value<int> startGlobalMs,
      Value<int> endGlobalMs,
      Value<double> speed,
      Value<String> deviceId,
    });

final class $$ListeningSessionsTableReferences
    extends
        BaseReferences<
          _$KikuyomiDatabase,
          $ListeningSessionsTable,
          ListeningSessionRow
        > {
  $$ListeningSessionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $BooksTable _bookIdTable(_$KikuyomiDatabase db) =>
      db.books.createAlias('listening_sessions__book_id__books__id');

  $$BooksTableProcessedTableManager get bookId {
    final $_column = $_itemColumn<int>('book_id')!;

    final manager = $$BooksTableTableManager(
      $_db,
      $_db.books,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_bookIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ChaptersTable _chapterIdTable(_$KikuyomiDatabase db) =>
      db.chapters.createAlias('listening_sessions__chapter_id__chapters__id');

  $$ChaptersTableProcessedTableManager? get chapterId {
    final $_column = $_itemColumn<int>('chapter_id');
    if ($_column == null) return null;
    final manager = $$ChaptersTableTableManager(
      $_db,
      $_db.chapters,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_chapterIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ListeningSessionsTableFilterComposer
    extends Composer<_$KikuyomiDatabase, $ListeningSessionsTable> {
  $$ListeningSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startGlobalMs => $composableBuilder(
    column: $table.startGlobalMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endGlobalMs => $composableBuilder(
    column: $table.endGlobalMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get speed => $composableBuilder(
    column: $table.speed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  $$BooksTableFilterComposer get bookId {
    final $$BooksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BooksTableFilterComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ChaptersTableFilterComposer get chapterId {
    final $$ChaptersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.chapterId,
      referencedTable: $db.chapters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChaptersTableFilterComposer(
            $db: $db,
            $table: $db.chapters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ListeningSessionsTableOrderingComposer
    extends Composer<_$KikuyomiDatabase, $ListeningSessionsTable> {
  $$ListeningSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startGlobalMs => $composableBuilder(
    column: $table.startGlobalMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endGlobalMs => $composableBuilder(
    column: $table.endGlobalMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get speed => $composableBuilder(
    column: $table.speed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  $$BooksTableOrderingComposer get bookId {
    final $$BooksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BooksTableOrderingComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ChaptersTableOrderingComposer get chapterId {
    final $$ChaptersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.chapterId,
      referencedTable: $db.chapters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChaptersTableOrderingComposer(
            $db: $db,
            $table: $db.chapters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ListeningSessionsTableAnnotationComposer
    extends Composer<_$KikuyomiDatabase, $ListeningSessionsTable> {
  $$ListeningSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumn<int> get startGlobalMs => $composableBuilder(
    column: $table.startGlobalMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get endGlobalMs => $composableBuilder(
    column: $table.endGlobalMs,
    builder: (column) => column,
  );

  GeneratedColumn<double> get speed =>
      $composableBuilder(column: $table.speed, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  $$BooksTableAnnotationComposer get bookId {
    final $$BooksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BooksTableAnnotationComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ChaptersTableAnnotationComposer get chapterId {
    final $$ChaptersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.chapterId,
      referencedTable: $db.chapters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChaptersTableAnnotationComposer(
            $db: $db,
            $table: $db.chapters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ListeningSessionsTableTableManager
    extends
        RootTableManager<
          _$KikuyomiDatabase,
          $ListeningSessionsTable,
          ListeningSessionRow,
          $$ListeningSessionsTableFilterComposer,
          $$ListeningSessionsTableOrderingComposer,
          $$ListeningSessionsTableAnnotationComposer,
          $$ListeningSessionsTableCreateCompanionBuilder,
          $$ListeningSessionsTableUpdateCompanionBuilder,
          (ListeningSessionRow, $$ListeningSessionsTableReferences),
          ListeningSessionRow,
          PrefetchHooks Function({bool bookId, bool chapterId})
        > {
  $$ListeningSessionsTableTableManager(
    _$KikuyomiDatabase db,
    $ListeningSessionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ListeningSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ListeningSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ListeningSessionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> bookId = const Value.absent(),
                Value<int?> chapterId = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime> endedAt = const Value.absent(),
                Value<int> startGlobalMs = const Value.absent(),
                Value<int> endGlobalMs = const Value.absent(),
                Value<double> speed = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
              }) => ListeningSessionsCompanion(
                id: id,
                bookId: bookId,
                chapterId: chapterId,
                startedAt: startedAt,
                endedAt: endedAt,
                startGlobalMs: startGlobalMs,
                endGlobalMs: endGlobalMs,
                speed: speed,
                deviceId: deviceId,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int bookId,
                Value<int?> chapterId = const Value.absent(),
                required DateTime startedAt,
                required DateTime endedAt,
                required int startGlobalMs,
                required int endGlobalMs,
                required double speed,
                required String deviceId,
              }) => ListeningSessionsCompanion.insert(
                id: id,
                bookId: bookId,
                chapterId: chapterId,
                startedAt: startedAt,
                endedAt: endedAt,
                startGlobalMs: startGlobalMs,
                endGlobalMs: endGlobalMs,
                speed: speed,
                deviceId: deviceId,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ListeningSessionsTable, ListeningSessionRow>(
                    table,
                  ),
                  $$ListeningSessionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({bookId = false, chapterId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (bookId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.bookId,
                        referencedTable: $$ListeningSessionsTableReferences
                            ._bookIdTable(db),
                        referencedColumn: $$ListeningSessionsTableReferences
                            ._bookIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (chapterId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.chapterId,
                        referencedTable: $$ListeningSessionsTableReferences
                            ._chapterIdTable(db),
                        referencedColumn: $$ListeningSessionsTableReferences
                            ._chapterIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ListeningSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$KikuyomiDatabase,
      $ListeningSessionsTable,
      ListeningSessionRow,
      $$ListeningSessionsTableFilterComposer,
      $$ListeningSessionsTableOrderingComposer,
      $$ListeningSessionsTableAnnotationComposer,
      $$ListeningSessionsTableCreateCompanionBuilder,
      $$ListeningSessionsTableUpdateCompanionBuilder,
      (ListeningSessionRow, $$ListeningSessionsTableReferences),
      ListeningSessionRow,
      PrefetchHooks Function({bool bookId, bool chapterId})
    >;
typedef $$BookmarksTableCreateCompanionBuilder = BookmarksCompanion Function({
  Value<int> id,
  required int bookId,
  required int chapterId,
  required int positionMs,
  Value<String?> title,
  Value<String?> note,
  required DateTime createdAt,
});
typedef $$BookmarksTableUpdateCompanionBuilder = BookmarksCompanion Function({
  Value<int> id,
  Value<int> bookId,
  Value<int> chapterId,
  Value<int> positionMs,
  Value<String?> title,
  Value<String?> note,
  Value<DateTime> createdAt,
});

final class $$BookmarksTableReferences
    extends BaseReferences<_$KikuyomiDatabase, $BookmarksTable, BookmarkRow> {
  $$BookmarksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $BooksTable _bookIdTable(_$KikuyomiDatabase db) =>
      db.books.createAlias('bookmarks__book_id__books__id');

  $$BooksTableProcessedTableManager get bookId {
    final $_column = $_itemColumn<int>('book_id')!;

    final manager = $$BooksTableTableManager(
      $_db,
      $_db.books,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_bookIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ChaptersTable _chapterIdTable(_$KikuyomiDatabase db) =>
      db.chapters.createAlias('bookmarks__chapter_id__chapters__id');

  $$ChaptersTableProcessedTableManager get chapterId {
    final $_column = $_itemColumn<int>('chapter_id')!;

    final manager = $$ChaptersTableTableManager(
      $_db,
      $_db.chapters,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_chapterIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$BookmarksTableFilterComposer
    extends Composer<_$KikuyomiDatabase, $BookmarksTable> {
  $$BookmarksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get positionMs => $composableBuilder(
    column: $table.positionMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$BooksTableFilterComposer get bookId {
    final $$BooksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BooksTableFilterComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ChaptersTableFilterComposer get chapterId {
    final $$ChaptersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.chapterId,
      referencedTable: $db.chapters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChaptersTableFilterComposer(
            $db: $db,
            $table: $db.chapters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BookmarksTableOrderingComposer
    extends Composer<_$KikuyomiDatabase, $BookmarksTable> {
  $$BookmarksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get positionMs => $composableBuilder(
    column: $table.positionMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$BooksTableOrderingComposer get bookId {
    final $$BooksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BooksTableOrderingComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ChaptersTableOrderingComposer get chapterId {
    final $$ChaptersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.chapterId,
      referencedTable: $db.chapters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChaptersTableOrderingComposer(
            $db: $db,
            $table: $db.chapters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BookmarksTableAnnotationComposer
    extends Composer<_$KikuyomiDatabase, $BookmarksTable> {
  $$BookmarksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get positionMs => $composableBuilder(
    column: $table.positionMs,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$BooksTableAnnotationComposer get bookId {
    final $$BooksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BooksTableAnnotationComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ChaptersTableAnnotationComposer get chapterId {
    final $$ChaptersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.chapterId,
      referencedTable: $db.chapters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChaptersTableAnnotationComposer(
            $db: $db,
            $table: $db.chapters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BookmarksTableTableManager
    extends
        RootTableManager<
          _$KikuyomiDatabase,
          $BookmarksTable,
          BookmarkRow,
          $$BookmarksTableFilterComposer,
          $$BookmarksTableOrderingComposer,
          $$BookmarksTableAnnotationComposer,
          $$BookmarksTableCreateCompanionBuilder,
          $$BookmarksTableUpdateCompanionBuilder,
          (BookmarkRow, $$BookmarksTableReferences),
          BookmarkRow,
          PrefetchHooks Function({bool bookId, bool chapterId})
        > {
  $$BookmarksTableTableManager(_$KikuyomiDatabase db, $BookmarksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BookmarksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BookmarksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BookmarksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> bookId = const Value.absent(),
                Value<int> chapterId = const Value.absent(),
                Value<int> positionMs = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => BookmarksCompanion(
                id: id,
                bookId: bookId,
                chapterId: chapterId,
                positionMs: positionMs,
                title: title,
                note: note,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int bookId,
                required int chapterId,
                required int positionMs,
                Value<String?> title = const Value.absent(),
                Value<String?> note = const Value.absent(),
                required DateTime createdAt,
              }) => BookmarksCompanion.insert(
                id: id,
                bookId: bookId,
                chapterId: chapterId,
                positionMs: positionMs,
                title: title,
                note: note,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BookmarksTable, BookmarkRow>(table),
                  $$BookmarksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({bookId = false, chapterId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (bookId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.bookId,
                        referencedTable: $$BookmarksTableReferences
                            ._bookIdTable(db),
                        referencedColumn: $$BookmarksTableReferences
                            ._bookIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (chapterId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.chapterId,
                        referencedTable: $$BookmarksTableReferences
                            ._chapterIdTable(db),
                        referencedColumn: $$BookmarksTableReferences
                            ._chapterIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$BookmarksTableProcessedTableManager =
    ProcessedTableManager<
      _$KikuyomiDatabase,
      $BookmarksTable,
      BookmarkRow,
      $$BookmarksTableFilterComposer,
      $$BookmarksTableOrderingComposer,
      $$BookmarksTableAnnotationComposer,
      $$BookmarksTableCreateCompanionBuilder,
      $$BookmarksTableUpdateCompanionBuilder,
      (BookmarkRow, $$BookmarksTableReferences),
      BookmarkRow,
      PrefetchHooks Function({bool bookId, bool chapterId})
    >;
typedef $$CategoriesTableCreateCompanionBuilder = CategoriesCompanion Function({
  Value<int> id,
  required String name,
  required int sortOrder,
  Value<int> flags,
});
typedef $$CategoriesTableUpdateCompanionBuilder = CategoriesCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<int> sortOrder,
  Value<int> flags,
});

final class $$CategoriesTableReferences
    extends BaseReferences<_$KikuyomiDatabase, $CategoriesTable, CategoryRow> {
  $$CategoriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$BookCategoriesTable, List<BookCategoryRow>>
  _bookCategoriesRefsTable(_$KikuyomiDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.bookCategories,
        aliasName: 'categories__id__book_categories__category_id',
      );

  $$BookCategoriesTableProcessedTableManager get bookCategoriesRefs {
    final manager = $$BookCategoriesTableTableManager(
      $_db,
      $_db.bookCategories,
    ).filter((f) => f.categoryId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_bookCategoriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CategoriesTableFilterComposer
    extends Composer<_$KikuyomiDatabase, $CategoriesTable> {
  $$CategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get flags => $composableBuilder(
    column: $table.flags,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> bookCategoriesRefs(
    Expression<bool> Function($$BookCategoriesTableFilterComposer f) f,
  ) {
    final $$BookCategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.bookCategories,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BookCategoriesTableFilterComposer(
            $db: $db,
            $table: $db.bookCategories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CategoriesTableOrderingComposer
    extends Composer<_$KikuyomiDatabase, $CategoriesTable> {
  $$CategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get flags => $composableBuilder(
    column: $table.flags,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CategoriesTableAnnotationComposer
    extends Composer<_$KikuyomiDatabase, $CategoriesTable> {
  $$CategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<int> get flags =>
      $composableBuilder(column: $table.flags, builder: (column) => column);

  Expression<T> bookCategoriesRefs<T extends Object>(
    Expression<T> Function($$BookCategoriesTableAnnotationComposer a) f,
  ) {
    final $$BookCategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.bookCategories,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BookCategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.bookCategories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CategoriesTableTableManager
    extends
        RootTableManager<
          _$KikuyomiDatabase,
          $CategoriesTable,
          CategoryRow,
          $$CategoriesTableFilterComposer,
          $$CategoriesTableOrderingComposer,
          $$CategoriesTableAnnotationComposer,
          $$CategoriesTableCreateCompanionBuilder,
          $$CategoriesTableUpdateCompanionBuilder,
          (CategoryRow, $$CategoriesTableReferences),
          CategoryRow,
          PrefetchHooks Function({bool bookCategoriesRefs})
        > {
  $$CategoriesTableTableManager(_$KikuyomiDatabase db, $CategoriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> flags = const Value.absent(),
              }) => CategoriesCompanion(
                id: id,
                name: name,
                sortOrder: sortOrder,
                flags: flags,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required int sortOrder,
                Value<int> flags = const Value.absent(),
              }) => CategoriesCompanion.insert(
                id: id,
                name: name,
                sortOrder: sortOrder,
                flags: flags,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CategoriesTable, CategoryRow>(table),
                  $$CategoriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({bookCategoriesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (bookCategoriesRefs) db.bookCategories,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (bookCategoriesRefs)
                    await $_getPrefetchedData<
                      CategoryRow,
                      $CategoriesTable,
                      BookCategoryRow
                    >(
                      currentTable: table,
                      referencedTable: $$CategoriesTableReferences
                          ._bookCategoriesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$CategoriesTableReferences(
                            db,
                            table,
                            p0,
                          ).bookCategoriesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.categoryId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$CategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$KikuyomiDatabase,
      $CategoriesTable,
      CategoryRow,
      $$CategoriesTableFilterComposer,
      $$CategoriesTableOrderingComposer,
      $$CategoriesTableAnnotationComposer,
      $$CategoriesTableCreateCompanionBuilder,
      $$CategoriesTableUpdateCompanionBuilder,
      (CategoryRow, $$CategoriesTableReferences),
      CategoryRow,
      PrefetchHooks Function({bool bookCategoriesRefs})
    >;
typedef $$BookCategoriesTableCreateCompanionBuilder =
    BookCategoriesCompanion Function({
      required int bookId,
      required int categoryId,
      Value<int> rowid,
    });
typedef $$BookCategoriesTableUpdateCompanionBuilder =
    BookCategoriesCompanion Function({
      Value<int> bookId,
      Value<int> categoryId,
      Value<int> rowid,
    });

final class $$BookCategoriesTableReferences
    extends
        BaseReferences<
          _$KikuyomiDatabase,
          $BookCategoriesTable,
          BookCategoryRow
        > {
  $$BookCategoriesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $BooksTable _bookIdTable(_$KikuyomiDatabase db) =>
      db.books.createAlias('book_categories__book_id__books__id');

  $$BooksTableProcessedTableManager get bookId {
    final $_column = $_itemColumn<int>('book_id')!;

    final manager = $$BooksTableTableManager(
      $_db,
      $_db.books,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_bookIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $CategoriesTable _categoryIdTable(_$KikuyomiDatabase db) =>
      db.categories.createAlias('book_categories__category_id__categories__id');

  $$CategoriesTableProcessedTableManager get categoryId {
    final $_column = $_itemColumn<int>('category_id')!;

    final manager = $$CategoriesTableTableManager(
      $_db,
      $_db.categories,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$BookCategoriesTableFilterComposer
    extends Composer<_$KikuyomiDatabase, $BookCategoriesTable> {
  $$BookCategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$BooksTableFilterComposer get bookId {
    final $$BooksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BooksTableFilterComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CategoriesTableFilterComposer get categoryId {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableFilterComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BookCategoriesTableOrderingComposer
    extends Composer<_$KikuyomiDatabase, $BookCategoriesTable> {
  $$BookCategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$BooksTableOrderingComposer get bookId {
    final $$BooksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BooksTableOrderingComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CategoriesTableOrderingComposer get categoryId {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableOrderingComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BookCategoriesTableAnnotationComposer
    extends Composer<_$KikuyomiDatabase, $BookCategoriesTable> {
  $$BookCategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$BooksTableAnnotationComposer get bookId {
    final $$BooksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.books,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BooksTableAnnotationComposer(
            $db: $db,
            $table: $db.books,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CategoriesTableAnnotationComposer get categoryId {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BookCategoriesTableTableManager
    extends
        RootTableManager<
          _$KikuyomiDatabase,
          $BookCategoriesTable,
          BookCategoryRow,
          $$BookCategoriesTableFilterComposer,
          $$BookCategoriesTableOrderingComposer,
          $$BookCategoriesTableAnnotationComposer,
          $$BookCategoriesTableCreateCompanionBuilder,
          $$BookCategoriesTableUpdateCompanionBuilder,
          (BookCategoryRow, $$BookCategoriesTableReferences),
          BookCategoryRow,
          PrefetchHooks Function({bool bookId, bool categoryId})
        > {
  $$BookCategoriesTableTableManager(
    _$KikuyomiDatabase db,
    $BookCategoriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BookCategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BookCategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BookCategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> bookId = const Value.absent(),
                Value<int> categoryId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BookCategoriesCompanion(
                bookId: bookId,
                categoryId: categoryId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int bookId,
                required int categoryId,
                Value<int> rowid = const Value.absent(),
              }) => BookCategoriesCompanion.insert(
                bookId: bookId,
                categoryId: categoryId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BookCategoriesTable, BookCategoryRow>(table),
                  $$BookCategoriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({bookId = false, categoryId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (bookId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.bookId,
                        referencedTable: $$BookCategoriesTableReferences
                            ._bookIdTable(db),
                        referencedColumn: $$BookCategoriesTableReferences
                            ._bookIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (categoryId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.categoryId,
                        referencedTable: $$BookCategoriesTableReferences
                            ._categoryIdTable(db),
                        referencedColumn: $$BookCategoriesTableReferences
                            ._categoryIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$BookCategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$KikuyomiDatabase,
      $BookCategoriesTable,
      BookCategoryRow,
      $$BookCategoriesTableFilterComposer,
      $$BookCategoriesTableOrderingComposer,
      $$BookCategoriesTableAnnotationComposer,
      $$BookCategoriesTableCreateCompanionBuilder,
      $$BookCategoriesTableUpdateCompanionBuilder,
      (BookCategoryRow, $$BookCategoriesTableReferences),
      BookCategoryRow,
      PrefetchHooks Function({bool bookId, bool categoryId})
    >;
typedef $$RepositoriesTableCreateCompanionBuilder =
    RepositoriesCompanion Function({
      Value<int> id,
      required String url,
      required String name,
      required String publicKey,
      required String fingerprint,
      Value<String?> etag,
      Value<DateTime?> lastFetchedAt,
    });
typedef $$RepositoriesTableUpdateCompanionBuilder =
    RepositoriesCompanion Function({
      Value<int> id,
      Value<String> url,
      Value<String> name,
      Value<String> publicKey,
      Value<String> fingerprint,
      Value<String?> etag,
      Value<DateTime?> lastFetchedAt,
    });

class $$RepositoriesTableFilterComposer
    extends Composer<_$KikuyomiDatabase, $RepositoriesTable> {
  $$RepositoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get publicKey => $composableBuilder(
    column: $table.publicKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fingerprint => $composableBuilder(
    column: $table.fingerprint,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get etag => $composableBuilder(
    column: $table.etag,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastFetchedAt => $composableBuilder(
    column: $table.lastFetchedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RepositoriesTableOrderingComposer
    extends Composer<_$KikuyomiDatabase, $RepositoriesTable> {
  $$RepositoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get publicKey => $composableBuilder(
    column: $table.publicKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fingerprint => $composableBuilder(
    column: $table.fingerprint,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get etag => $composableBuilder(
    column: $table.etag,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastFetchedAt => $composableBuilder(
    column: $table.lastFetchedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RepositoriesTableAnnotationComposer
    extends Composer<_$KikuyomiDatabase, $RepositoriesTable> {
  $$RepositoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get publicKey =>
      $composableBuilder(column: $table.publicKey, builder: (column) => column);

  GeneratedColumn<String> get fingerprint => $composableBuilder(
    column: $table.fingerprint,
    builder: (column) => column,
  );

  GeneratedColumn<String> get etag =>
      $composableBuilder(column: $table.etag, builder: (column) => column);

  GeneratedColumn<DateTime> get lastFetchedAt => $composableBuilder(
    column: $table.lastFetchedAt,
    builder: (column) => column,
  );
}

class $$RepositoriesTableTableManager
    extends
        RootTableManager<
          _$KikuyomiDatabase,
          $RepositoriesTable,
          RepositoryRow,
          $$RepositoriesTableFilterComposer,
          $$RepositoriesTableOrderingComposer,
          $$RepositoriesTableAnnotationComposer,
          $$RepositoriesTableCreateCompanionBuilder,
          $$RepositoriesTableUpdateCompanionBuilder,
          (
            RepositoryRow,
            BaseReferences<
              _$KikuyomiDatabase,
              $RepositoriesTable,
              RepositoryRow
            >,
          ),
          RepositoryRow,
          PrefetchHooks Function()
        > {
  $$RepositoriesTableTableManager(
    _$KikuyomiDatabase db,
    $RepositoriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RepositoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RepositoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RepositoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> url = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> publicKey = const Value.absent(),
                Value<String> fingerprint = const Value.absent(),
                Value<String?> etag = const Value.absent(),
                Value<DateTime?> lastFetchedAt = const Value.absent(),
              }) => RepositoriesCompanion(
                id: id,
                url: url,
                name: name,
                publicKey: publicKey,
                fingerprint: fingerprint,
                etag: etag,
                lastFetchedAt: lastFetchedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String url,
                required String name,
                required String publicKey,
                required String fingerprint,
                Value<String?> etag = const Value.absent(),
                Value<DateTime?> lastFetchedAt = const Value.absent(),
              }) => RepositoriesCompanion.insert(
                id: id,
                url: url,
                name: name,
                publicKey: publicKey,
                fingerprint: fingerprint,
                etag: etag,
                lastFetchedAt: lastFetchedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RepositoriesTable, RepositoryRow>(table),
                  BaseReferences<
                    _$KikuyomiDatabase,
                    $RepositoriesTable,
                    RepositoryRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RepositoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$KikuyomiDatabase,
      $RepositoriesTable,
      RepositoryRow,
      $$RepositoriesTableFilterComposer,
      $$RepositoriesTableOrderingComposer,
      $$RepositoriesTableAnnotationComposer,
      $$RepositoriesTableCreateCompanionBuilder,
      $$RepositoriesTableUpdateCompanionBuilder,
      (
        RepositoryRow,
        BaseReferences<_$KikuyomiDatabase, $RepositoriesTable, RepositoryRow>,
      ),
      RepositoryRow,
      PrefetchHooks Function()
    >;
typedef $$ExtensionsTableCreateCompanionBuilder = ExtensionsCompanion Function({
  required String id,
  required String name,
  required String version,
  required int versionCode,
  required String apiVersion,
  required ExtensionStatus status,
  required ExtensionOrigin origin,
  Value<String?> originHandle,
  Value<String?> originName,
  Value<String?> installPath,
  required DateTime installedAt,
  Value<int> rowid,
});
typedef $$ExtensionsTableUpdateCompanionBuilder = ExtensionsCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> version,
  Value<int> versionCode,
  Value<String> apiVersion,
  Value<ExtensionStatus> status,
  Value<ExtensionOrigin> origin,
  Value<String?> originHandle,
  Value<String?> originName,
  Value<String?> installPath,
  Value<DateTime> installedAt,
  Value<int> rowid,
});

class $$ExtensionsTableFilterComposer
    extends Composer<_$KikuyomiDatabase, $ExtensionsTable> {
  $$ExtensionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get versionCode => $composableBuilder(
    column: $table.versionCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get apiVersion => $composableBuilder(
    column: $table.apiVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ExtensionStatus, ExtensionStatus, String>
  get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<ExtensionOrigin, ExtensionOrigin, String>
  get origin => $composableBuilder(
    column: $table.origin,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get originHandle => $composableBuilder(
    column: $table.originHandle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originName => $composableBuilder(
    column: $table.originName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get installPath => $composableBuilder(
    column: $table.installPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get installedAt => $composableBuilder(
    column: $table.installedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ExtensionsTableOrderingComposer
    extends Composer<_$KikuyomiDatabase, $ExtensionsTable> {
  $$ExtensionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get versionCode => $composableBuilder(
    column: $table.versionCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get apiVersion => $composableBuilder(
    column: $table.apiVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get origin => $composableBuilder(
    column: $table.origin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originHandle => $composableBuilder(
    column: $table.originHandle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originName => $composableBuilder(
    column: $table.originName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get installPath => $composableBuilder(
    column: $table.installPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get installedAt => $composableBuilder(
    column: $table.installedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ExtensionsTableAnnotationComposer
    extends Composer<_$KikuyomiDatabase, $ExtensionsTable> {
  $$ExtensionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<int> get versionCode => $composableBuilder(
    column: $table.versionCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get apiVersion => $composableBuilder(
    column: $table.apiVersion,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<ExtensionStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ExtensionOrigin, String> get origin =>
      $composableBuilder(column: $table.origin, builder: (column) => column);

  GeneratedColumn<String> get originHandle => $composableBuilder(
    column: $table.originHandle,
    builder: (column) => column,
  );

  GeneratedColumn<String> get originName => $composableBuilder(
    column: $table.originName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get installPath => $composableBuilder(
    column: $table.installPath,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get installedAt => $composableBuilder(
    column: $table.installedAt,
    builder: (column) => column,
  );
}

class $$ExtensionsTableTableManager
    extends
        RootTableManager<
          _$KikuyomiDatabase,
          $ExtensionsTable,
          ExtensionRow,
          $$ExtensionsTableFilterComposer,
          $$ExtensionsTableOrderingComposer,
          $$ExtensionsTableAnnotationComposer,
          $$ExtensionsTableCreateCompanionBuilder,
          $$ExtensionsTableUpdateCompanionBuilder,
          (
            ExtensionRow,
            BaseReferences<_$KikuyomiDatabase, $ExtensionsTable, ExtensionRow>,
          ),
          ExtensionRow,
          PrefetchHooks Function()
        > {
  $$ExtensionsTableTableManager(_$KikuyomiDatabase db, $ExtensionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExtensionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExtensionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExtensionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> version = const Value.absent(),
                Value<int> versionCode = const Value.absent(),
                Value<String> apiVersion = const Value.absent(),
                Value<ExtensionStatus> status = const Value.absent(),
                Value<ExtensionOrigin> origin = const Value.absent(),
                Value<String?> originHandle = const Value.absent(),
                Value<String?> originName = const Value.absent(),
                Value<String?> installPath = const Value.absent(),
                Value<DateTime> installedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExtensionsCompanion(
                id: id,
                name: name,
                version: version,
                versionCode: versionCode,
                apiVersion: apiVersion,
                status: status,
                origin: origin,
                originHandle: originHandle,
                originName: originName,
                installPath: installPath,
                installedAt: installedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String version,
                required int versionCode,
                required String apiVersion,
                required ExtensionStatus status,
                required ExtensionOrigin origin,
                Value<String?> originHandle = const Value.absent(),
                Value<String?> originName = const Value.absent(),
                Value<String?> installPath = const Value.absent(),
                required DateTime installedAt,
                Value<int> rowid = const Value.absent(),
              }) => ExtensionsCompanion.insert(
                id: id,
                name: name,
                version: version,
                versionCode: versionCode,
                apiVersion: apiVersion,
                status: status,
                origin: origin,
                originHandle: originHandle,
                originName: originName,
                installPath: installPath,
                installedAt: installedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ExtensionsTable, ExtensionRow>(table),
                  BaseReferences<
                    _$KikuyomiDatabase,
                    $ExtensionsTable,
                    ExtensionRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ExtensionsTableProcessedTableManager =
    ProcessedTableManager<
      _$KikuyomiDatabase,
      $ExtensionsTable,
      ExtensionRow,
      $$ExtensionsTableFilterComposer,
      $$ExtensionsTableOrderingComposer,
      $$ExtensionsTableAnnotationComposer,
      $$ExtensionsTableCreateCompanionBuilder,
      $$ExtensionsTableUpdateCompanionBuilder,
      (
        ExtensionRow,
        BaseReferences<_$KikuyomiDatabase, $ExtensionsTable, ExtensionRow>,
      ),
      ExtensionRow,
      PrefetchHooks Function()
    >;
typedef $$ExtensionPreferencesTableCreateCompanionBuilder =
    ExtensionPreferencesCompanion Function({
      required String extensionId,
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$ExtensionPreferencesTableUpdateCompanionBuilder =
    ExtensionPreferencesCompanion Function({
      Value<String> extensionId,
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$ExtensionPreferencesTableFilterComposer
    extends Composer<_$KikuyomiDatabase, $ExtensionPreferencesTable> {
  $$ExtensionPreferencesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get extensionId => $composableBuilder(
    column: $table.extensionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ExtensionPreferencesTableOrderingComposer
    extends Composer<_$KikuyomiDatabase, $ExtensionPreferencesTable> {
  $$ExtensionPreferencesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get extensionId => $composableBuilder(
    column: $table.extensionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ExtensionPreferencesTableAnnotationComposer
    extends Composer<_$KikuyomiDatabase, $ExtensionPreferencesTable> {
  $$ExtensionPreferencesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get extensionId => $composableBuilder(
    column: $table.extensionId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$ExtensionPreferencesTableTableManager
    extends
        RootTableManager<
          _$KikuyomiDatabase,
          $ExtensionPreferencesTable,
          ExtensionPreferenceRow,
          $$ExtensionPreferencesTableFilterComposer,
          $$ExtensionPreferencesTableOrderingComposer,
          $$ExtensionPreferencesTableAnnotationComposer,
          $$ExtensionPreferencesTableCreateCompanionBuilder,
          $$ExtensionPreferencesTableUpdateCompanionBuilder,
          (
            ExtensionPreferenceRow,
            BaseReferences<
              _$KikuyomiDatabase,
              $ExtensionPreferencesTable,
              ExtensionPreferenceRow
            >,
          ),
          ExtensionPreferenceRow,
          PrefetchHooks Function()
        > {
  $$ExtensionPreferencesTableTableManager(
    _$KikuyomiDatabase db,
    $ExtensionPreferencesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExtensionPreferencesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExtensionPreferencesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ExtensionPreferencesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> extensionId = const Value.absent(),
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExtensionPreferencesCompanion(
                extensionId: extensionId,
                key: key,
                value: value,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String extensionId,
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => ExtensionPreferencesCompanion.insert(
                extensionId: extensionId,
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $ExtensionPreferencesTable,
                    ExtensionPreferenceRow
                  >(table),
                  BaseReferences<
                    _$KikuyomiDatabase,
                    $ExtensionPreferencesTable,
                    ExtensionPreferenceRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ExtensionPreferencesTableProcessedTableManager =
    ProcessedTableManager<
      _$KikuyomiDatabase,
      $ExtensionPreferencesTable,
      ExtensionPreferenceRow,
      $$ExtensionPreferencesTableFilterComposer,
      $$ExtensionPreferencesTableOrderingComposer,
      $$ExtensionPreferencesTableAnnotationComposer,
      $$ExtensionPreferencesTableCreateCompanionBuilder,
      $$ExtensionPreferencesTableUpdateCompanionBuilder,
      (
        ExtensionPreferenceRow,
        BaseReferences<
          _$KikuyomiDatabase,
          $ExtensionPreferencesTable,
          ExtensionPreferenceRow
        >,
      ),
      ExtensionPreferenceRow,
      PrefetchHooks Function()
    >;
typedef $$DownloadTasksTableCreateCompanionBuilder =
    DownloadTasksCompanion Function({
      Value<int> id,
      required int mediaFileId,
      required DownloadState state,
      Value<DownloadHold?> hold,
      Value<int> priority,
      Value<int> bytesDone,
      Value<int?> bytesTotal,
      Value<DownloadRequest?> requestSnapshot,
      Value<DateTime?> expiresAt,
      Value<int> attempts,
      Value<DateTime?> retryAt,
      Value<String?> lastError,
      Value<String?> transportTaskId,
      required DateTime createdAt,
      required DateTime updatedAt,
    });
typedef $$DownloadTasksTableUpdateCompanionBuilder =
    DownloadTasksCompanion Function({
      Value<int> id,
      Value<int> mediaFileId,
      Value<DownloadState> state,
      Value<DownloadHold?> hold,
      Value<int> priority,
      Value<int> bytesDone,
      Value<int?> bytesTotal,
      Value<DownloadRequest?> requestSnapshot,
      Value<DateTime?> expiresAt,
      Value<int> attempts,
      Value<DateTime?> retryAt,
      Value<String?> lastError,
      Value<String?> transportTaskId,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

final class $$DownloadTasksTableReferences
    extends
        BaseReferences<
          _$KikuyomiDatabase,
          $DownloadTasksTable,
          DownloadTaskRow
        > {
  $$DownloadTasksTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $MediaFilesTable _mediaFileIdTable(_$KikuyomiDatabase db) => db
      .mediaFiles
      .createAlias('download_tasks__media_file_id__media_files__id');

  $$MediaFilesTableProcessedTableManager get mediaFileId {
    final $_column = $_itemColumn<int>('media_file_id')!;

    final manager = $$MediaFilesTableTableManager(
      $_db,
      $_db.mediaFiles,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_mediaFileIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$DownloadTasksTableFilterComposer
    extends Composer<_$KikuyomiDatabase, $DownloadTasksTable> {
  $$DownloadTasksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DownloadState, DownloadState, String>
  get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<DownloadHold?, DownloadHold, String>
  get hold => $composableBuilder(
    column: $table.hold,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bytesDone => $composableBuilder(
    column: $table.bytesDone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bytesTotal => $composableBuilder(
    column: $table.bytesTotal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DownloadRequest?, DownloadRequest, String>
  get requestSnapshot => $composableBuilder(
    column: $table.requestSnapshot,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<DateTime> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get retryAt => $composableBuilder(
    column: $table.retryAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get transportTaskId => $composableBuilder(
    column: $table.transportTaskId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$MediaFilesTableFilterComposer get mediaFileId {
    final $$MediaFilesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.mediaFileId,
      referencedTable: $db.mediaFiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MediaFilesTableFilterComposer(
            $db: $db,
            $table: $db.mediaFiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DownloadTasksTableOrderingComposer
    extends Composer<_$KikuyomiDatabase, $DownloadTasksTable> {
  $$DownloadTasksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hold => $composableBuilder(
    column: $table.hold,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bytesDone => $composableBuilder(
    column: $table.bytesDone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bytesTotal => $composableBuilder(
    column: $table.bytesTotal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get requestSnapshot => $composableBuilder(
    column: $table.requestSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get retryAt => $composableBuilder(
    column: $table.retryAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get transportTaskId => $composableBuilder(
    column: $table.transportTaskId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$MediaFilesTableOrderingComposer get mediaFileId {
    final $$MediaFilesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.mediaFileId,
      referencedTable: $db.mediaFiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MediaFilesTableOrderingComposer(
            $db: $db,
            $table: $db.mediaFiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DownloadTasksTableAnnotationComposer
    extends Composer<_$KikuyomiDatabase, $DownloadTasksTable> {
  $$DownloadTasksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DownloadState, String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DownloadHold?, String> get hold =>
      $composableBuilder(column: $table.hold, builder: (column) => column);

  GeneratedColumn<int> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<int> get bytesDone =>
      $composableBuilder(column: $table.bytesDone, builder: (column) => column);

  GeneratedColumn<int> get bytesTotal => $composableBuilder(
    column: $table.bytesTotal,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<DownloadRequest?, String>
  get requestSnapshot => $composableBuilder(
    column: $table.requestSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get expiresAt =>
      $composableBuilder(column: $table.expiresAt, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<DateTime> get retryAt =>
      $composableBuilder(column: $table.retryAt, builder: (column) => column);

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<String> get transportTaskId => $composableBuilder(
    column: $table.transportTaskId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$MediaFilesTableAnnotationComposer get mediaFileId {
    final $$MediaFilesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.mediaFileId,
      referencedTable: $db.mediaFiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MediaFilesTableAnnotationComposer(
            $db: $db,
            $table: $db.mediaFiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DownloadTasksTableTableManager
    extends
        RootTableManager<
          _$KikuyomiDatabase,
          $DownloadTasksTable,
          DownloadTaskRow,
          $$DownloadTasksTableFilterComposer,
          $$DownloadTasksTableOrderingComposer,
          $$DownloadTasksTableAnnotationComposer,
          $$DownloadTasksTableCreateCompanionBuilder,
          $$DownloadTasksTableUpdateCompanionBuilder,
          (DownloadTaskRow, $$DownloadTasksTableReferences),
          DownloadTaskRow,
          PrefetchHooks Function({bool mediaFileId})
        > {
  $$DownloadTasksTableTableManager(
    _$KikuyomiDatabase db,
    $DownloadTasksTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DownloadTasksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DownloadTasksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DownloadTasksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> mediaFileId = const Value.absent(),
                Value<DownloadState> state = const Value.absent(),
                Value<DownloadHold?> hold = const Value.absent(),
                Value<int> priority = const Value.absent(),
                Value<int> bytesDone = const Value.absent(),
                Value<int?> bytesTotal = const Value.absent(),
                Value<DownloadRequest?> requestSnapshot = const Value.absent(),
                Value<DateTime?> expiresAt = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<DateTime?> retryAt = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<String?> transportTaskId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => DownloadTasksCompanion(
                id: id,
                mediaFileId: mediaFileId,
                state: state,
                hold: hold,
                priority: priority,
                bytesDone: bytesDone,
                bytesTotal: bytesTotal,
                requestSnapshot: requestSnapshot,
                expiresAt: expiresAt,
                attempts: attempts,
                retryAt: retryAt,
                lastError: lastError,
                transportTaskId: transportTaskId,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int mediaFileId,
                required DownloadState state,
                Value<DownloadHold?> hold = const Value.absent(),
                Value<int> priority = const Value.absent(),
                Value<int> bytesDone = const Value.absent(),
                Value<int?> bytesTotal = const Value.absent(),
                Value<DownloadRequest?> requestSnapshot = const Value.absent(),
                Value<DateTime?> expiresAt = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<DateTime?> retryAt = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<String?> transportTaskId = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
              }) => DownloadTasksCompanion.insert(
                id: id,
                mediaFileId: mediaFileId,
                state: state,
                hold: hold,
                priority: priority,
                bytesDone: bytesDone,
                bytesTotal: bytesTotal,
                requestSnapshot: requestSnapshot,
                expiresAt: expiresAt,
                attempts: attempts,
                retryAt: retryAt,
                lastError: lastError,
                transportTaskId: transportTaskId,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DownloadTasksTable, DownloadTaskRow>(table),
                  $$DownloadTasksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({mediaFileId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (mediaFileId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.mediaFileId,
                        referencedTable: $$DownloadTasksTableReferences
                            ._mediaFileIdTable(db),
                        referencedColumn: $$DownloadTasksTableReferences
                            ._mediaFileIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$DownloadTasksTableProcessedTableManager =
    ProcessedTableManager<
      _$KikuyomiDatabase,
      $DownloadTasksTable,
      DownloadTaskRow,
      $$DownloadTasksTableFilterComposer,
      $$DownloadTasksTableOrderingComposer,
      $$DownloadTasksTableAnnotationComposer,
      $$DownloadTasksTableCreateCompanionBuilder,
      $$DownloadTasksTableUpdateCompanionBuilder,
      (DownloadTaskRow, $$DownloadTasksTableReferences),
      DownloadTaskRow,
      PrefetchHooks Function({bool mediaFileId})
    >;

class $KikuyomiDatabaseManager {
  final _$KikuyomiDatabase _db;
  $KikuyomiDatabaseManager(this._db);
  $$SourcesTableTableManager get sources =>
      $$SourcesTableTableManager(_db, _db.sources);
  $$BooksTableTableManager get books =>
      $$BooksTableTableManager(_db, _db.books);
  $$PeopleTableTableManager get people =>
      $$PeopleTableTableManager(_db, _db.people);
  $$BookPeopleTableTableManager get bookPeople =>
      $$BookPeopleTableTableManager(_db, _db.bookPeople);
  $$ChaptersTableTableManager get chapters =>
      $$ChaptersTableTableManager(_db, _db.chapters);
  $$MediaFilesTableTableManager get mediaFiles =>
      $$MediaFilesTableTableManager(_db, _db.mediaFiles);
  $$ChapterSegmentsTableTableManager get chapterSegments =>
      $$ChapterSegmentsTableTableManager(_db, _db.chapterSegments);
  $$PlaybackStatesTableTableManager get playbackStates =>
      $$PlaybackStatesTableTableManager(_db, _db.playbackStates);
  $$ReadingStatesTableTableManager get readingStates =>
      $$ReadingStatesTableTableManager(_db, _db.readingStates);
  $$ReadingSessionsTableTableManager get readingSessions =>
      $$ReadingSessionsTableTableManager(_db, _db.readingSessions);
  $$ListeningSessionsTableTableManager get listeningSessions =>
      $$ListeningSessionsTableTableManager(_db, _db.listeningSessions);
  $$BookmarksTableTableManager get bookmarks =>
      $$BookmarksTableTableManager(_db, _db.bookmarks);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db, _db.categories);
  $$BookCategoriesTableTableManager get bookCategories =>
      $$BookCategoriesTableTableManager(_db, _db.bookCategories);
  $$RepositoriesTableTableManager get repositories =>
      $$RepositoriesTableTableManager(_db, _db.repositories);
  $$ExtensionsTableTableManager get extensions =>
      $$ExtensionsTableTableManager(_db, _db.extensions);
  $$ExtensionPreferencesTableTableManager get extensionPreferences =>
      $$ExtensionPreferencesTableTableManager(_db, _db.extensionPreferences);
  $$DownloadTasksTableTableManager get downloadTasks =>
      $$DownloadTasksTableTableManager(_db, _db.downloadTasks);
}
