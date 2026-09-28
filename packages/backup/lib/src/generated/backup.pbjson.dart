// This is a generated file - do not edit.
//
// Generated from backup.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports
// ignore_for_file: unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use bookKindDescriptor instead')
const BookKind$json = {
  '1': 'BookKind',
  '2': [
    {'1': 'BOOK_KIND_AUDIO', '2': 0},
    {'1': 'BOOK_KIND_TEXT', '2': 1},
  ],
};

/// Descriptor for `BookKind`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List bookKindDescriptor = $convert.base64Decode(
    'CghCb29rS2luZBITCg9CT09LX0tJTkRfQVVESU8QABISCg5CT09LX0tJTkRfVEVYVBAB');

@$core.Deprecated('Use contributorRoleDescriptor instead')
const ContributorRole$json = {
  '1': 'ContributorRole',
  '2': [
    {'1': 'CONTRIBUTOR_ROLE_UNSPECIFIED', '2': 0},
    {'1': 'CONTRIBUTOR_ROLE_AUTHOR', '2': 1},
    {'1': 'CONTRIBUTOR_ROLE_NARRATOR', '2': 2},
  ],
};

/// Descriptor for `ContributorRole`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List contributorRoleDescriptor = $convert.base64Decode(
    'Cg9Db250cmlidXRvclJvbGUSIAocQ09OVFJJQlVUT1JfUk9MRV9VTlNQRUNJRklFRBAAEhsKF0'
    'NPTlRSSUJVVE9SX1JPTEVfQVVUSE9SEAESHQoZQ09OVFJJQlVUT1JfUk9MRV9OQVJSQVRPUhAC');

@$core.Deprecated('Use backupDescriptor instead')
const Backup$json = {
  '1': 'Backup',
  '2': [
    {'1': 'format_version', '3': 1, '4': 1, '5': 13, '10': 'formatVersion'},
    {
      '1': 'min_reader_version',
      '3': 2,
      '4': 1,
      '5': 13,
      '10': 'minReaderVersion'
    },
    {'1': 'created_at_ms', '3': 3, '4': 1, '5': 3, '10': 'createdAtMs'},
    {'1': 'app_version', '3': 4, '4': 1, '5': 9, '10': 'appVersion'},
    {'1': 'device_id', '3': 5, '4': 1, '5': 9, '10': 'deviceId'},
    {
      '1': 'sources',
      '3': 6,
      '4': 3,
      '5': 11,
      '6': '.kikuyomi.backup.Source',
      '10': 'sources'
    },
    {
      '1': 'categories',
      '3': 7,
      '4': 3,
      '5': 11,
      '6': '.kikuyomi.backup.Category',
      '10': 'categories'
    },
    {
      '1': 'books',
      '3': 8,
      '4': 3,
      '5': 11,
      '6': '.kikuyomi.backup.Book',
      '10': 'books'
    },
  ],
};

/// Descriptor for `Backup`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List backupDescriptor = $convert.base64Decode(
    'CgZCYWNrdXASJQoOZm9ybWF0X3ZlcnNpb24YASABKA1SDWZvcm1hdFZlcnNpb24SLAoSbWluX3'
    'JlYWRlcl92ZXJzaW9uGAIgASgNUhBtaW5SZWFkZXJWZXJzaW9uEiIKDWNyZWF0ZWRfYXRfbXMY'
    'AyABKANSC2NyZWF0ZWRBdE1zEh8KC2FwcF92ZXJzaW9uGAQgASgJUgphcHBWZXJzaW9uEhsKCW'
    'RldmljZV9pZBgFIAEoCVIIZGV2aWNlSWQSMQoHc291cmNlcxgGIAMoCzIXLmtpa3V5b21pLmJh'
    'Y2t1cC5Tb3VyY2VSB3NvdXJjZXMSOQoKY2F0ZWdvcmllcxgHIAMoCzIZLmtpa3V5b21pLmJhY2'
    't1cC5DYXRlZ29yeVIKY2F0ZWdvcmllcxIrCgVib29rcxgIIAMoCzIVLmtpa3V5b21pLmJhY2t1'
    'cC5Cb29rUgVib29rcw==');

@$core.Deprecated('Use sourceDescriptor instead')
const Source$json = {
  '1': 'Source',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 16, '10': 'id'},
    {
      '1': 'extension_id',
      '3': 2,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'extensionId',
      '17': true
    },
    {'1': 'key', '3': 3, '4': 1, '5': 9, '10': 'key'},
    {'1': 'name', '3': 4, '4': 1, '5': 9, '10': 'name'},
    {'1': 'lang', '3': 5, '4': 1, '5': 9, '10': 'lang'},
    {
      '1': 'content_rating',
      '3': 6,
      '4': 1,
      '5': 9,
      '9': 1,
      '10': 'contentRating',
      '17': true
    },
    {'1': 'is_enabled', '3': 7, '4': 1, '5': 8, '10': 'isEnabled'},
    {'1': 'is_pinned', '3': 8, '4': 1, '5': 8, '10': 'isPinned'},
    {
      '1': 'last_used_at_ms',
      '3': 9,
      '4': 1,
      '5': 3,
      '9': 2,
      '10': 'lastUsedAtMs',
      '17': true
    },
  ],
  '8': [
    {'1': '_extension_id'},
    {'1': '_content_rating'},
    {'1': '_last_used_at_ms'},
  ],
};

/// Descriptor for `Source`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sourceDescriptor = $convert.base64Decode(
    'CgZTb3VyY2USDgoCaWQYASABKBBSAmlkEiYKDGV4dGVuc2lvbl9pZBgCIAEoCUgAUgtleHRlbn'
    'Npb25JZIgBARIQCgNrZXkYAyABKAlSA2tleRISCgRuYW1lGAQgASgJUgRuYW1lEhIKBGxhbmcY'
    'BSABKAlSBGxhbmcSKgoOY29udGVudF9yYXRpbmcYBiABKAlIAVINY29udGVudFJhdGluZ4gBAR'
    'IdCgppc19lbmFibGVkGAcgASgIUglpc0VuYWJsZWQSGwoJaXNfcGlubmVkGAggASgIUghpc1Bp'
    'bm5lZBIqCg9sYXN0X3VzZWRfYXRfbXMYCSABKANIAlIMbGFzdFVzZWRBdE1ziAEBQg8KDV9leH'
    'RlbnNpb25faWRCEQoPX2NvbnRlbnRfcmF0aW5nQhIKEF9sYXN0X3VzZWRfYXRfbXM=');

@$core.Deprecated('Use categoryDescriptor instead')
const Category$json = {
  '1': 'Category',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {'1': 'sort_order', '3': 2, '4': 1, '5': 5, '10': 'sortOrder'},
    {'1': 'flags', '3': 3, '4': 1, '5': 3, '10': 'flags'},
  ],
};

/// Descriptor for `Category`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List categoryDescriptor = $convert.base64Decode(
    'CghDYXRlZ29yeRISCgRuYW1lGAEgASgJUgRuYW1lEh0KCnNvcnRfb3JkZXIYAiABKAVSCXNvcn'
    'RPcmRlchIUCgVmbGFncxgDIAEoA1IFZmxhZ3M=');

@$core.Deprecated('Use bookDescriptor instead')
const Book$json = {
  '1': 'Book',
  '2': [
    {'1': 'source_id', '3': 1, '4': 1, '5': 16, '10': 'sourceId'},
    {'1': 'key', '3': 2, '4': 1, '5': 9, '10': 'key'},
    {'1': 'title', '3': 3, '4': 1, '5': 9, '10': 'title'},
    {
      '1': 'subtitle',
      '3': 4,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'subtitle',
      '17': true
    },
    {
      '1': 'description',
      '3': 5,
      '4': 1,
      '5': 9,
      '9': 1,
      '10': 'description',
      '17': true
    },
    {
      '1': 'cover_url',
      '3': 6,
      '4': 1,
      '5': 9,
      '9': 2,
      '10': 'coverUrl',
      '17': true
    },
    {
      '1': 'series_name',
      '3': 7,
      '4': 1,
      '5': 9,
      '9': 3,
      '10': 'seriesName',
      '17': true
    },
    {
      '1': 'series_index',
      '3': 8,
      '4': 1,
      '5': 1,
      '9': 4,
      '10': 'seriesIndex',
      '17': true
    },
    {'1': 'genres', '3': 9, '4': 3, '5': 9, '10': 'genres'},
    {
      '1': 'language',
      '3': 10,
      '4': 1,
      '5': 9,
      '9': 5,
      '10': 'language',
      '17': true
    },
    {
      '1': 'publisher',
      '3': 11,
      '4': 1,
      '5': 9,
      '9': 6,
      '10': 'publisher',
      '17': true
    },
    {
      '1': 'published_date',
      '3': 12,
      '4': 1,
      '5': 9,
      '9': 7,
      '10': 'publishedDate',
      '17': true
    },
    {'1': 'isbn', '3': 13, '4': 1, '5': 9, '9': 8, '10': 'isbn', '17': true},
    {
      '1': 'abridged',
      '3': 14,
      '4': 1,
      '5': 8,
      '9': 9,
      '10': 'abridged',
      '17': true
    },
    {
      '1': 'status',
      '3': 15,
      '4': 1,
      '5': 9,
      '9': 10,
      '10': 'status',
      '17': true
    },
    {
      '1': 'content_rating',
      '3': 16,
      '4': 1,
      '5': 9,
      '9': 11,
      '10': 'contentRating',
      '17': true
    },
    {
      '1': 'total_duration_ms',
      '3': 17,
      '4': 1,
      '5': 3,
      '9': 12,
      '10': 'totalDurationMs',
      '17': true
    },
    {
      '1': 'web_url',
      '3': 18,
      '4': 1,
      '5': 9,
      '9': 13,
      '10': 'webUrl',
      '17': true
    },
    {'1': 'user_overrides', '3': 19, '4': 3, '5': 9, '10': 'userOverrides'},
    {
      '1': 'contributors',
      '3': 20,
      '4': 3,
      '5': 11,
      '6': '.kikuyomi.backup.Contributor',
      '10': 'contributors'
    },
    {'1': 'in_library', '3': 21, '4': 1, '5': 8, '10': 'inLibrary'},
    {
      '1': 'date_added_at_ms',
      '3': 22,
      '4': 1,
      '5': 3,
      '9': 14,
      '10': 'dateAddedAtMs',
      '17': true
    },
    {
      '1': 'last_refreshed_at_ms',
      '3': 23,
      '4': 1,
      '5': 3,
      '9': 15,
      '10': 'lastRefreshedAtMs',
      '17': true
    },
    {'1': 'details_fetched', '3': 24, '4': 1, '5': 8, '10': 'detailsFetched'},
    {
      '1': 'playback_speed',
      '3': 25,
      '4': 1,
      '5': 1,
      '9': 16,
      '10': 'playbackSpeed',
      '17': true
    },
    {'1': 'created_at_ms', '3': 26, '4': 1, '5': 3, '10': 'createdAtMs'},
    {'1': 'updated_at_ms', '3': 27, '4': 1, '5': 3, '10': 'updatedAtMs'},
    {
      '1': 'media_files',
      '3': 28,
      '4': 3,
      '5': 11,
      '6': '.kikuyomi.backup.MediaFile',
      '10': 'mediaFiles'
    },
    {
      '1': 'chapters',
      '3': 29,
      '4': 3,
      '5': 11,
      '6': '.kikuyomi.backup.Chapter',
      '10': 'chapters'
    },
    {
      '1': 'playback_state',
      '3': 30,
      '4': 1,
      '5': 11,
      '6': '.kikuyomi.backup.PlaybackState',
      '10': 'playbackState'
    },
    {
      '1': 'listening_sessions',
      '3': 31,
      '4': 3,
      '5': 11,
      '6': '.kikuyomi.backup.ListeningSession',
      '10': 'listeningSessions'
    },
    {
      '1': 'bookmarks',
      '3': 32,
      '4': 3,
      '5': 11,
      '6': '.kikuyomi.backup.Bookmark',
      '10': 'bookmarks'
    },
    {'1': 'categories', '3': 33, '4': 3, '5': 9, '10': 'categories'},
    {
      '1': 'kind',
      '3': 34,
      '4': 1,
      '5': 14,
      '6': '.kikuyomi.backup.BookKind',
      '10': 'kind'
    },
    {
      '1': 'reading_state',
      '3': 35,
      '4': 1,
      '5': 11,
      '6': '.kikuyomi.backup.ReadingState',
      '10': 'readingState'
    },
    {
      '1': 'reading_sessions',
      '3': 36,
      '4': 3,
      '5': 11,
      '6': '.kikuyomi.backup.ReadingSession',
      '10': 'readingSessions'
    },
  ],
  '8': [
    {'1': '_subtitle'},
    {'1': '_description'},
    {'1': '_cover_url'},
    {'1': '_series_name'},
    {'1': '_series_index'},
    {'1': '_language'},
    {'1': '_publisher'},
    {'1': '_published_date'},
    {'1': '_isbn'},
    {'1': '_abridged'},
    {'1': '_status'},
    {'1': '_content_rating'},
    {'1': '_total_duration_ms'},
    {'1': '_web_url'},
    {'1': '_date_added_at_ms'},
    {'1': '_last_refreshed_at_ms'},
    {'1': '_playback_speed'},
  ],
};

/// Descriptor for `Book`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List bookDescriptor = $convert.base64Decode(
    'CgRCb29rEhsKCXNvdXJjZV9pZBgBIAEoEFIIc291cmNlSWQSEAoDa2V5GAIgASgJUgNrZXkSFA'
    'oFdGl0bGUYAyABKAlSBXRpdGxlEh8KCHN1YnRpdGxlGAQgASgJSABSCHN1YnRpdGxliAEBEiUK'
    'C2Rlc2NyaXB0aW9uGAUgASgJSAFSC2Rlc2NyaXB0aW9uiAEBEiAKCWNvdmVyX3VybBgGIAEoCU'
    'gCUghjb3ZlclVybIgBARIkCgtzZXJpZXNfbmFtZRgHIAEoCUgDUgpzZXJpZXNOYW1liAEBEiYK'
    'DHNlcmllc19pbmRleBgIIAEoAUgEUgtzZXJpZXNJbmRleIgBARIWCgZnZW5yZXMYCSADKAlSBm'
    'dlbnJlcxIfCghsYW5ndWFnZRgKIAEoCUgFUghsYW5ndWFnZYgBARIhCglwdWJsaXNoZXIYCyAB'
    'KAlIBlIJcHVibGlzaGVyiAEBEioKDnB1Ymxpc2hlZF9kYXRlGAwgASgJSAdSDXB1Ymxpc2hlZE'
    'RhdGWIAQESFwoEaXNibhgNIAEoCUgIUgRpc2JuiAEBEh8KCGFicmlkZ2VkGA4gASgISAlSCGFi'
    'cmlkZ2VkiAEBEhsKBnN0YXR1cxgPIAEoCUgKUgZzdGF0dXOIAQESKgoOY29udGVudF9yYXRpbm'
    'cYECABKAlIC1INY29udGVudFJhdGluZ4gBARIvChF0b3RhbF9kdXJhdGlvbl9tcxgRIAEoA0gM'
    'Ug90b3RhbER1cmF0aW9uTXOIAQESHAoHd2ViX3VybBgSIAEoCUgNUgZ3ZWJVcmyIAQESJQoOdX'
    'Nlcl9vdmVycmlkZXMYEyADKAlSDXVzZXJPdmVycmlkZXMSQAoMY29udHJpYnV0b3JzGBQgAygL'
    'Mhwua2lrdXlvbWkuYmFja3VwLkNvbnRyaWJ1dG9yUgxjb250cmlidXRvcnMSHQoKaW5fbGlicm'
    'FyeRgVIAEoCFIJaW5MaWJyYXJ5EiwKEGRhdGVfYWRkZWRfYXRfbXMYFiABKANIDlINZGF0ZUFk'
    'ZGVkQXRNc4gBARI0ChRsYXN0X3JlZnJlc2hlZF9hdF9tcxgXIAEoA0gPUhFsYXN0UmVmcmVzaG'
    'VkQXRNc4gBARInCg9kZXRhaWxzX2ZldGNoZWQYGCABKAhSDmRldGFpbHNGZXRjaGVkEioKDnBs'
    'YXliYWNrX3NwZWVkGBkgASgBSBBSDXBsYXliYWNrU3BlZWSIAQESIgoNY3JlYXRlZF9hdF9tcx'
    'gaIAEoA1ILY3JlYXRlZEF0TXMSIgoNdXBkYXRlZF9hdF9tcxgbIAEoA1ILdXBkYXRlZEF0TXMS'
    'OwoLbWVkaWFfZmlsZXMYHCADKAsyGi5raWt1eW9taS5iYWNrdXAuTWVkaWFGaWxlUgptZWRpYU'
    'ZpbGVzEjQKCGNoYXB0ZXJzGB0gAygLMhgua2lrdXlvbWkuYmFja3VwLkNoYXB0ZXJSCGNoYXB0'
    'ZXJzEkUKDnBsYXliYWNrX3N0YXRlGB4gASgLMh4ua2lrdXlvbWkuYmFja3VwLlBsYXliYWNrU3'
    'RhdGVSDXBsYXliYWNrU3RhdGUSUAoSbGlzdGVuaW5nX3Nlc3Npb25zGB8gAygLMiEua2lrdXlv'
    'bWkuYmFja3VwLkxpc3RlbmluZ1Nlc3Npb25SEWxpc3RlbmluZ1Nlc3Npb25zEjcKCWJvb2ttYX'
    'JrcxggIAMoCzIZLmtpa3V5b21pLmJhY2t1cC5Cb29rbWFya1IJYm9va21hcmtzEh4KCmNhdGVn'
    'b3JpZXMYISADKAlSCmNhdGVnb3JpZXMSLQoEa2luZBgiIAEoDjIZLmtpa3V5b21pLmJhY2t1cC'
    '5Cb29rS2luZFIEa2luZBJCCg1yZWFkaW5nX3N0YXRlGCMgASgLMh0ua2lrdXlvbWkuYmFja3Vw'
    'LlJlYWRpbmdTdGF0ZVIMcmVhZGluZ1N0YXRlEkoKEHJlYWRpbmdfc2Vzc2lvbnMYJCADKAsyHy'
    '5raWt1eW9taS5iYWNrdXAuUmVhZGluZ1Nlc3Npb25SD3JlYWRpbmdTZXNzaW9uc0ILCglfc3Vi'
    'dGl0bGVCDgoMX2Rlc2NyaXB0aW9uQgwKCl9jb3Zlcl91cmxCDgoMX3Nlcmllc19uYW1lQg8KDV'
    '9zZXJpZXNfaW5kZXhCCwoJX2xhbmd1YWdlQgwKCl9wdWJsaXNoZXJCEQoPX3B1Ymxpc2hlZF9k'
    'YXRlQgcKBV9pc2JuQgsKCV9hYnJpZGdlZEIJCgdfc3RhdHVzQhEKD19jb250ZW50X3JhdGluZ0'
    'IUChJfdG90YWxfZHVyYXRpb25fbXNCCgoIX3dlYl91cmxCEwoRX2RhdGVfYWRkZWRfYXRfbXNC'
    'FwoVX2xhc3RfcmVmcmVzaGVkX2F0X21zQhEKD19wbGF5YmFja19zcGVlZA==');

@$core.Deprecated('Use contributorDescriptor instead')
const Contributor$json = {
  '1': 'Contributor',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {
      '1': 'role',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.kikuyomi.backup.ContributorRole',
      '10': 'role'
    },
    {'1': 'ordinal', '3': 3, '4': 1, '5': 5, '10': 'ordinal'},
  ],
};

/// Descriptor for `Contributor`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List contributorDescriptor = $convert.base64Decode(
    'CgtDb250cmlidXRvchISCgRuYW1lGAEgASgJUgRuYW1lEjQKBHJvbGUYAiABKA4yIC5raWt1eW'
    '9taS5iYWNrdXAuQ29udHJpYnV0b3JSb2xlUgRyb2xlEhgKB29yZGluYWwYAyABKAVSB29yZGlu'
    'YWw=');

@$core.Deprecated('Use mediaFileDescriptor instead')
const MediaFile$json = {
  '1': 'MediaFile',
  '2': [
    {'1': 'file_key', '3': 1, '4': 1, '5': 9, '10': 'fileKey'},
    {'1': 'format', '3': 2, '4': 1, '5': 9, '9': 0, '10': 'format', '17': true},
    {
      '1': 'duration_ms',
      '3': 3,
      '4': 1,
      '5': 3,
      '9': 1,
      '10': 'durationMs',
      '17': true
    },
    {
      '1': 'duration_is_estimate',
      '3': 4,
      '4': 1,
      '5': 8,
      '10': 'durationIsEstimate'
    },
    {
      '1': 'size_bytes',
      '3': 5,
      '4': 1,
      '5': 3,
      '9': 2,
      '10': 'sizeBytes',
      '17': true
    },
    {
      '1': 'embedded_markers',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.kikuyomi.backup.MarkerList',
      '10': 'embeddedMarkers'
    },
    {
      '1': 'local_path',
      '3': 7,
      '4': 1,
      '5': 9,
      '9': 3,
      '10': 'localPath',
      '17': true
    },
    {
      '1': 'downloaded_at_ms',
      '3': 8,
      '4': 1,
      '5': 3,
      '9': 4,
      '10': 'downloadedAtMs',
      '17': true
    },
  ],
  '8': [
    {'1': '_format'},
    {'1': '_duration_ms'},
    {'1': '_size_bytes'},
    {'1': '_local_path'},
    {'1': '_downloaded_at_ms'},
  ],
};

/// Descriptor for `MediaFile`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List mediaFileDescriptor = $convert.base64Decode(
    'CglNZWRpYUZpbGUSGQoIZmlsZV9rZXkYASABKAlSB2ZpbGVLZXkSGwoGZm9ybWF0GAIgASgJSA'
    'BSBmZvcm1hdIgBARIkCgtkdXJhdGlvbl9tcxgDIAEoA0gBUgpkdXJhdGlvbk1ziAEBEjAKFGR1'
    'cmF0aW9uX2lzX2VzdGltYXRlGAQgASgIUhJkdXJhdGlvbklzRXN0aW1hdGUSIgoKc2l6ZV9ieX'
    'RlcxgFIAEoA0gCUglzaXplQnl0ZXOIAQESRgoQZW1iZWRkZWRfbWFya2VycxgGIAEoCzIbLmtp'
    'a3V5b21pLmJhY2t1cC5NYXJrZXJMaXN0Ug9lbWJlZGRlZE1hcmtlcnMSIgoKbG9jYWxfcGF0aB'
    'gHIAEoCUgDUglsb2NhbFBhdGiIAQESLQoQZG93bmxvYWRlZF9hdF9tcxgIIAEoA0gEUg5kb3du'
    'bG9hZGVkQXRNc4gBAUIJCgdfZm9ybWF0Qg4KDF9kdXJhdGlvbl9tc0INCgtfc2l6ZV9ieXRlc0'
    'INCgtfbG9jYWxfcGF0aEITChFfZG93bmxvYWRlZF9hdF9tcw==');

@$core.Deprecated('Use markerListDescriptor instead')
const MarkerList$json = {
  '1': 'MarkerList',
  '2': [
    {
      '1': 'markers',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.kikuyomi.backup.Marker',
      '10': 'markers'
    },
  ],
};

/// Descriptor for `MarkerList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List markerListDescriptor = $convert.base64Decode(
    'CgpNYXJrZXJMaXN0EjEKB21hcmtlcnMYASADKAsyFy5raWt1eW9taS5iYWNrdXAuTWFya2VyUg'
    'dtYXJrZXJz');

@$core.Deprecated('Use markerDescriptor instead')
const Marker$json = {
  '1': 'Marker',
  '2': [
    {'1': 'title', '3': 1, '4': 1, '5': 9, '10': 'title'},
    {'1': 'start_ms', '3': 2, '4': 1, '5': 3, '10': 'startMs'},
  ],
};

/// Descriptor for `Marker`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List markerDescriptor = $convert.base64Decode(
    'CgZNYXJrZXISFAoFdGl0bGUYASABKAlSBXRpdGxlEhkKCHN0YXJ0X21zGAIgASgDUgdzdGFydE'
    '1z');

@$core.Deprecated('Use chapterDescriptor instead')
const Chapter$json = {
  '1': 'Chapter',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'title', '3': 2, '4': 1, '5': 9, '10': 'title'},
    {'1': 'source_index', '3': 3, '4': 1, '5': 5, '10': 'sourceIndex'},
    {
      '1': 'group_name',
      '3': 4,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'groupName',
      '17': true
    },
    {
      '1': 'duration_ms',
      '3': 5,
      '4': 1,
      '5': 3,
      '9': 1,
      '10': 'durationMs',
      '17': true
    },
    {
      '1': 'published_at_ms',
      '3': 6,
      '4': 1,
      '5': 3,
      '9': 2,
      '10': 'publishedAtMs',
      '17': true
    },
    {'1': 'is_listened', '3': 7, '4': 1, '5': 8, '10': 'isListened'},
    {
      '1': 'listened_at_ms',
      '3': 8,
      '4': 1,
      '5': 3,
      '9': 3,
      '10': 'listenedAtMs',
      '17': true
    },
    {'1': 'last_position_ms', '3': 9, '4': 1, '5': 3, '10': 'lastPositionMs'},
    {
      '1': 'removed_from_source',
      '3': 10,
      '4': 1,
      '5': 8,
      '10': 'removedFromSource'
    },
    {'1': 'created_at_ms', '3': 11, '4': 1, '5': 3, '10': 'createdAtMs'},
    {'1': 'updated_at_ms', '3': 12, '4': 1, '5': 3, '10': 'updatedAtMs'},
    {
      '1': 'segments',
      '3': 13,
      '4': 3,
      '5': 11,
      '6': '.kikuyomi.backup.Segment',
      '10': 'segments'
    },
  ],
  '8': [
    {'1': '_group_name'},
    {'1': '_duration_ms'},
    {'1': '_published_at_ms'},
    {'1': '_listened_at_ms'},
  ],
};

/// Descriptor for `Chapter`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List chapterDescriptor = $convert.base64Decode(
    'CgdDaGFwdGVyEhAKA2tleRgBIAEoCVIDa2V5EhQKBXRpdGxlGAIgASgJUgV0aXRsZRIhCgxzb3'
    'VyY2VfaW5kZXgYAyABKAVSC3NvdXJjZUluZGV4EiIKCmdyb3VwX25hbWUYBCABKAlIAFIJZ3Jv'
    'dXBOYW1liAEBEiQKC2R1cmF0aW9uX21zGAUgASgDSAFSCmR1cmF0aW9uTXOIAQESKwoPcHVibG'
    'lzaGVkX2F0X21zGAYgASgDSAJSDXB1Ymxpc2hlZEF0TXOIAQESHwoLaXNfbGlzdGVuZWQYByAB'
    'KAhSCmlzTGlzdGVuZWQSKQoObGlzdGVuZWRfYXRfbXMYCCABKANIA1IMbGlzdGVuZWRBdE1ziA'
    'EBEigKEGxhc3RfcG9zaXRpb25fbXMYCSABKANSDmxhc3RQb3NpdGlvbk1zEi4KE3JlbW92ZWRf'
    'ZnJvbV9zb3VyY2UYCiABKAhSEXJlbW92ZWRGcm9tU291cmNlEiIKDWNyZWF0ZWRfYXRfbXMYCy'
    'ABKANSC2NyZWF0ZWRBdE1zEiIKDXVwZGF0ZWRfYXRfbXMYDCABKANSC3VwZGF0ZWRBdE1zEjQK'
    'CHNlZ21lbnRzGA0gAygLMhgua2lrdXlvbWkuYmFja3VwLlNlZ21lbnRSCHNlZ21lbnRzQg0KC1'
    '9ncm91cF9uYW1lQg4KDF9kdXJhdGlvbl9tc0ISChBfcHVibGlzaGVkX2F0X21zQhEKD19saXN0'
    'ZW5lZF9hdF9tcw==');

@$core.Deprecated('Use segmentDescriptor instead')
const Segment$json = {
  '1': 'Segment',
  '2': [
    {'1': 'file_key', '3': 1, '4': 1, '5': 9, '10': 'fileKey'},
    {'1': 'start_ms', '3': 2, '4': 1, '5': 3, '10': 'startMs'},
    {'1': 'end_ms', '3': 3, '4': 1, '5': 3, '9': 0, '10': 'endMs', '17': true},
  ],
  '8': [
    {'1': '_end_ms'},
  ],
};

/// Descriptor for `Segment`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List segmentDescriptor = $convert.base64Decode(
    'CgdTZWdtZW50EhkKCGZpbGVfa2V5GAEgASgJUgdmaWxlS2V5EhkKCHN0YXJ0X21zGAIgASgDUg'
    'dzdGFydE1zEhoKBmVuZF9tcxgDIAEoA0gAUgVlbmRNc4gBAUIJCgdfZW5kX21z');

@$core.Deprecated('Use playbackStateDescriptor instead')
const PlaybackState$json = {
  '1': 'PlaybackState',
  '2': [
    {'1': 'chapter_key', '3': 1, '4': 1, '5': 9, '10': 'chapterKey'},
    {
      '1': 'chapter_position_ms',
      '3': 2,
      '4': 1,
      '5': 3,
      '10': 'chapterPositionMs'
    },
    {
      '1': 'global_position_ms',
      '3': 3,
      '4': 1,
      '5': 3,
      '10': 'globalPositionMs'
    },
    {'1': 'updated_at_ms', '3': 4, '4': 1, '5': 3, '10': 'updatedAtMs'},
    {'1': 'device_id', '3': 5, '4': 1, '5': 9, '10': 'deviceId'},
  ],
};

/// Descriptor for `PlaybackState`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List playbackStateDescriptor = $convert.base64Decode(
    'Cg1QbGF5YmFja1N0YXRlEh8KC2NoYXB0ZXJfa2V5GAEgASgJUgpjaGFwdGVyS2V5Ei4KE2NoYX'
    'B0ZXJfcG9zaXRpb25fbXMYAiABKANSEWNoYXB0ZXJQb3NpdGlvbk1zEiwKEmdsb2JhbF9wb3Np'
    'dGlvbl9tcxgDIAEoA1IQZ2xvYmFsUG9zaXRpb25NcxIiCg11cGRhdGVkX2F0X21zGAQgASgDUg'
    't1cGRhdGVkQXRNcxIbCglkZXZpY2VfaWQYBSABKAlSCGRldmljZUlk');

@$core.Deprecated('Use readingStateDescriptor instead')
const ReadingState$json = {
  '1': 'ReadingState',
  '2': [
    {'1': 'chapter_key', '3': 1, '4': 1, '5': 9, '10': 'chapterKey'},
    {'1': 'progress', '3': 2, '4': 1, '5': 1, '10': 'progress'},
    {'1': 'updated_at_ms', '3': 3, '4': 1, '5': 3, '10': 'updatedAtMs'},
  ],
};

/// Descriptor for `ReadingState`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List readingStateDescriptor = $convert.base64Decode(
    'CgxSZWFkaW5nU3RhdGUSHwoLY2hhcHRlcl9rZXkYASABKAlSCmNoYXB0ZXJLZXkSGgoIcHJvZ3'
    'Jlc3MYAiABKAFSCHByb2dyZXNzEiIKDXVwZGF0ZWRfYXRfbXMYAyABKANSC3VwZGF0ZWRBdE1z');

@$core.Deprecated('Use readingSessionDescriptor instead')
const ReadingSession$json = {
  '1': 'ReadingSession',
  '2': [
    {
      '1': 'chapter_key',
      '3': 1,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'chapterKey',
      '17': true
    },
    {'1': 'started_at_ms', '3': 2, '4': 1, '5': 3, '10': 'startedAtMs'},
    {'1': 'ended_at_ms', '3': 3, '4': 1, '5': 3, '10': 'endedAtMs'},
    {'1': 'device_id', '3': 4, '4': 1, '5': 9, '10': 'deviceId'},
  ],
  '8': [
    {'1': '_chapter_key'},
  ],
};

/// Descriptor for `ReadingSession`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List readingSessionDescriptor = $convert.base64Decode(
    'Cg5SZWFkaW5nU2Vzc2lvbhIkCgtjaGFwdGVyX2tleRgBIAEoCUgAUgpjaGFwdGVyS2V5iAEBEi'
    'IKDXN0YXJ0ZWRfYXRfbXMYAiABKANSC3N0YXJ0ZWRBdE1zEh4KC2VuZGVkX2F0X21zGAMgASgD'
    'UgllbmRlZEF0TXMSGwoJZGV2aWNlX2lkGAQgASgJUghkZXZpY2VJZEIOCgxfY2hhcHRlcl9rZX'
    'k=');

@$core.Deprecated('Use listeningSessionDescriptor instead')
const ListeningSession$json = {
  '1': 'ListeningSession',
  '2': [
    {
      '1': 'chapter_key',
      '3': 1,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'chapterKey',
      '17': true
    },
    {'1': 'started_at_ms', '3': 2, '4': 1, '5': 3, '10': 'startedAtMs'},
    {'1': 'ended_at_ms', '3': 3, '4': 1, '5': 3, '10': 'endedAtMs'},
    {'1': 'start_global_ms', '3': 4, '4': 1, '5': 3, '10': 'startGlobalMs'},
    {'1': 'end_global_ms', '3': 5, '4': 1, '5': 3, '10': 'endGlobalMs'},
    {'1': 'speed', '3': 6, '4': 1, '5': 1, '10': 'speed'},
    {'1': 'device_id', '3': 7, '4': 1, '5': 9, '10': 'deviceId'},
  ],
  '8': [
    {'1': '_chapter_key'},
  ],
};

/// Descriptor for `ListeningSession`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listeningSessionDescriptor = $convert.base64Decode(
    'ChBMaXN0ZW5pbmdTZXNzaW9uEiQKC2NoYXB0ZXJfa2V5GAEgASgJSABSCmNoYXB0ZXJLZXmIAQ'
    'ESIgoNc3RhcnRlZF9hdF9tcxgCIAEoA1ILc3RhcnRlZEF0TXMSHgoLZW5kZWRfYXRfbXMYAyAB'
    'KANSCWVuZGVkQXRNcxImCg9zdGFydF9nbG9iYWxfbXMYBCABKANSDXN0YXJ0R2xvYmFsTXMSIg'
    'oNZW5kX2dsb2JhbF9tcxgFIAEoA1ILZW5kR2xvYmFsTXMSFAoFc3BlZWQYBiABKAFSBXNwZWVk'
    'EhsKCWRldmljZV9pZBgHIAEoCVIIZGV2aWNlSWRCDgoMX2NoYXB0ZXJfa2V5');

@$core.Deprecated('Use bookmarkDescriptor instead')
const Bookmark$json = {
  '1': 'Bookmark',
  '2': [
    {'1': 'chapter_key', '3': 1, '4': 1, '5': 9, '10': 'chapterKey'},
    {'1': 'position_ms', '3': 2, '4': 1, '5': 3, '10': 'positionMs'},
    {'1': 'title', '3': 3, '4': 1, '5': 9, '9': 0, '10': 'title', '17': true},
    {'1': 'note', '3': 4, '4': 1, '5': 9, '9': 1, '10': 'note', '17': true},
    {'1': 'created_at_ms', '3': 5, '4': 1, '5': 3, '10': 'createdAtMs'},
  ],
  '8': [
    {'1': '_title'},
    {'1': '_note'},
  ],
};

/// Descriptor for `Bookmark`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List bookmarkDescriptor = $convert.base64Decode(
    'CghCb29rbWFyaxIfCgtjaGFwdGVyX2tleRgBIAEoCVIKY2hhcHRlcktleRIfCgtwb3NpdGlvbl'
    '9tcxgCIAEoA1IKcG9zaXRpb25NcxIZCgV0aXRsZRgDIAEoCUgAUgV0aXRsZYgBARIXCgRub3Rl'
    'GAQgASgJSAFSBG5vdGWIAQESIgoNY3JlYXRlZF9hdF9tcxgFIAEoA1ILY3JlYXRlZEF0TXNCCA'
    'oGX3RpdGxlQgcKBV9ub3Rl');
