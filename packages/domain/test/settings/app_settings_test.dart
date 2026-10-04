import 'dart:io';

import 'package:kikuyomi_domain/kikuyomi_domain.dart';
import 'package:test/test.dart';

/// [value] as [setting] stores it and reads it back.
T? roundTrip<T extends Object>(Setting<T> setting, T value) =>
    setting.decode(setting.encode(value));

void main() {
  test('every setting declared is in AppSettings.all', () {
    // The list is maintained by hand, and leaving a setting out of it is silent at compile time and
    // loud at runtime: `SharedPreferencesWithCache` is opened with these keys as its allow-list and
    // throws for anything else, so the first read of a forgotten setting fails. That has happened
    // twice -- `librarySort`, and then the two Browse added -- and each time it showed up as a
    // screen doing nothing when tapped, which is a long way from the cause.
    //
    // Read from the source, because Dart cannot ask a class what it declares.
    final source = File('lib/src/settings/app_settings.dart')
        .readAsStringSync();
    final declared = {
      for (final match in RegExp(
        r'static const (\w+) = Setting<',
      ).allMatches(source))
        match.group(1)!,
    };
    expect(declared, isNotEmpty, reason: 'nothing was found to check');

    final listed = source.substring(
      source.indexOf('static const all = <Setting<Object>>['),
    );
    final inAll = {
      for (final match in RegExp(
        r'^ {4}(\w+),',
        multiLine: true,
      ).allMatches(listed.substring(0, listed.indexOf('];'))))
        match.group(1)!,
    };

    expect(
      declared.difference(inAll),
      isEmpty,
      reason:
          'these settings are declared but not in AppSettings.all, so reading '
          'one throws rather than reading as unset',
    );
  });

  test('every setting has a key of its own', () {
    final keys = [for (final setting in AppSettings.all) setting.key];
    expect(keys.toSet(), hasLength(keys.length));
  });

  test('each setting reads back what it stored', () {
    expect(
      roundTrip(AppSettings.backupFolder, '{"kind":"directory"}'),
      '{"kind":"directory"}',
    );
    expect(
      roundTrip(AppSettings.lastBackupAt, DateTime.utc(2026, 9, 14, 15, 30)),
      DateTime.utc(2026, 9, 14, 15, 30),
    );
    expect(roundTrip(AppSettings.backupDue, true), isTrue);
    expect(roundTrip(AppSettings.backupDue, false), isFalse);
    expect(
      roundTrip(AppSettings.readerMode, ReaderMode.horizontalPages),
      ReaderMode.horizontalPages,
    );
    expect(
      roundTrip(AppSettings.backupSetup, BackupSetup.skipped),
      BackupSetup.skipped,
    );
    expect(roundTrip(AppSettings.listenedBackfilled, true), isTrue);
  });

  test('a time is read back as the same instant, in UTC', () {
    final local = DateTime(2026, 9, 14, 18, 30);
    final read = roundTrip(AppSettings.lastBackupAt, local)!;
    expect(read.isAtSameMomentAs(local), isTrue);
    expect(read.isUtc, isTrue);
  });

  test('a stored value this build cannot read reads as not set', () {
    expect(AppSettings.lastBackupAt.decode('yesterday'), isNull);
    expect(AppSettings.lastBackupAt.decode('99999999999999999'), isNull);
    expect(AppSettings.backupDue.decode('yes'), isNull);
    expect(AppSettings.backupSetup.decode('postponed'), isNull);
    expect(AppSettings.readerMode.decode('diagonal'), isNull);
  });
}
