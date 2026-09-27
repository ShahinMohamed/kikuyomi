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

import 'package:protobuf/protobuf.dart' as $pb;

class BookKind extends $pb.ProtobufEnum {
  static const BookKind BOOK_KIND_AUDIO =
      BookKind._(0, _omitEnumNames ? '' : 'BOOK_KIND_AUDIO');
  static const BookKind BOOK_KIND_TEXT =
      BookKind._(1, _omitEnumNames ? '' : 'BOOK_KIND_TEXT');

  static const $core.List<BookKind> values = <BookKind>[
    BOOK_KIND_AUDIO,
    BOOK_KIND_TEXT,
  ];

  static final $core.List<BookKind?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 1);
  static BookKind? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const BookKind._(super.value, super.name);
}

class ContributorRole extends $pb.ProtobufEnum {
  static const ContributorRole CONTRIBUTOR_ROLE_UNSPECIFIED = ContributorRole._(
      0, _omitEnumNames ? '' : 'CONTRIBUTOR_ROLE_UNSPECIFIED');
  static const ContributorRole CONTRIBUTOR_ROLE_AUTHOR =
      ContributorRole._(1, _omitEnumNames ? '' : 'CONTRIBUTOR_ROLE_AUTHOR');
  static const ContributorRole CONTRIBUTOR_ROLE_NARRATOR =
      ContributorRole._(2, _omitEnumNames ? '' : 'CONTRIBUTOR_ROLE_NARRATOR');

  static const $core.List<ContributorRole> values = <ContributorRole>[
    CONTRIBUTOR_ROLE_UNSPECIFIED,
    CONTRIBUTOR_ROLE_AUTHOR,
    CONTRIBUTOR_ROLE_NARRATOR,
  ];

  static final $core.List<ContributorRole?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static ContributorRole? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const ContributorRole._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
