import '../library/library_sort.dart';
import 'settings_store.dart';

/// What became of the offer, made when the app first starts with an empty library, to choose a
/// backup folder or restore from one (§5.1).
enum BackupSetup {
  /// A folder was chosen, or a backup restored from one.
  completed,

  /// The listener chose to go without for now. Home keeps reminding them until a folder is chosen.
  skipped,
}

/// Every setting the app keeps, in one place, as §4.3 asks.
///
/// §4.3 also says that preferences which should survive a restore are included in backups
/// explicitly. None of the settings so far should be:
///
/// - [backupFolder] is a permission granted to this installation. Android's tree permissions and
///   iOS's bookmarks mean nothing to another device, or to the same device after a reinstall.
/// - [lastBackupAt] and [backupDue] describe this installation's own backups.
/// - [backupSetup] is this installation's first start.
/// - [listenedBackfilled] is a step taken once on this installation's database. A backup carries
///   each chapter's listened state itself.
///
/// The preferences still to come that shape listening, such as skip intervals, smart rewind and a
/// default speed, should be carried. When one arrives it gets a field in `proto/backup.proto`, whose
/// header already expects them, and a note here saying so.
abstract final class AppSettings {
  /// The folder automatic backups are written to, as the serialised handle a `UserFolders`
  /// implementation gave for it. Not set until the listener chooses one.
  static const backupFolder = Setting<String>(
    'backup.folder',
    encode: _text,
    decode: _text,
  );

  /// When the last backup was successfully written.
  static const lastBackupAt = Setting<DateTime>(
    'backup.lastWrittenAt',
    encode: _encodeTime,
    decode: _decodeTime,
  );

  /// Whether the library has changed since the last backup was written.
  ///
  /// Kept here rather than only in memory, so that changes made just before the app was ended
  /// without warning are still backed up after it next starts.
  static const backupDue = Setting<bool>(
    'backup.due',
    encode: _encodeFlag,
    decode: _decodeFlag,
  );

  /// Whether the first-start offer to set up backups was taken or skipped. Not set until one or the
  /// other.
  static const backupSetup = Setting<BackupSetup>(
    'backup.setup',
    encode: _encodeSetup,
    decode: _decodeSetup,
  );

  /// The order the library is shown in, so a shelf stays as the listener left it.
  ///
  /// Not set until one is chosen, and a value this build does not know reads as not set, which is
  /// what lets an older build open a library a newer one ordered some way it has never heard of.
  static const librarySort = Setting<LibrarySort>(
    'library.sort',
    encode: _encodeSort,
    decode: LibrarySort.byName,
  );

  /// The sources the listener has pinned to the top of Browse, most recently pinned first.
  ///
  /// By §3.7 source id, which is derived from the extension, the source key, the language and the
  /// version id. That is exactly the right key: it survives a reinstall of the same extension, and
  /// it changes when the source's identity does -- at which point a pin for what it used to be
  /// should stop applying.
  ///
  /// An id here that no source has is ignored rather than cleaned up. An extension being reinstalled
  /// should bring its pin back with it, which it cannot do if the pin was thrown away the first time
  /// Browse was opened without it.
  static const pinnedSources = Setting<List<int>>(
    'browse.pinnedSources',
    encode: _encodeIds,
    decode: _decodeIds,
  );

  /// The sources most recently browsed, most recent first, so Browse can offer them first.
  ///
  /// Kept short by whoever writes it. This is a convenience and not history: what a listener
  /// actually listened to is the library's, and this is only about which of a dozen sources they
  /// reach for.
  static const recentSources = Setting<List<int>>(
    'browse.recentSources',
    encode: _encodeIds,
    decode: _decodeIds,
  );

  /// Whether the extensions the app ships with have been installed, which happens once.
  ///
  /// The difference between a fresh install and a listener who removed an extension is invisible in
  /// the extensions table -- both are a row that is not there -- so it has to be remembered here.
  /// Without it, removing a shipped extension would be undone by the next restart.
  static const shippedExtensionsSeeded = Setting<bool>(
    'extensions.shippedSeeded',
    encode: _encodeFlag,
    decode: _decodeFlag,
  );

  /// The extensions shipped with the app that it has already installed once, by folder name.
  ///
  /// [shippedExtensionsSeeded] says whether seeding has happened; this says what it covered, so an
  /// extension shipped by a later version is installed on the next start, while one the listener
  /// removed stays removed. Not set on an install seeded before this existed, which covered the
  /// first four.
  static const shippedExtensionsOffered = Setting<List<String>>(
    'extensions.shippedOffered',
    encode: _encodeNames,
    decode: _decodeNames,
  );

  /// Whether chapters listened to before listened state was recorded (§4.5) have been recorded from
  /// the positions saved in them. Not set until that has been done, which happens once: after it,
  /// a chapter the listener marks not listened stays so, wherever its position is.
  static const listenedBackfilled = Setting<bool>(
    'library.listenedBackfilled',
    encode: _encodeFlag,
    decode: _decodeFlag,
  );

  /// How large the reader draws text, as a multiple of the theme's body size (ADR-0019). Not set
  /// until the reader changes it.
  ///
  /// Not in backups yet, like the rest of the preferences. It belongs with the listening ones when
  /// `proto/backup.proto` gains a message for them.
  static const readerTextScale = Setting<double>(
    'reader.textScale',
    encode: _encodeNumber,
    decode: _decodeScale,
  );

  /// The order the tabs of the shell are shown in, by name, or not set for the order the app
  /// declares them in.
  ///
  /// Names rather than positions, so that a tab added by a later version can be put at the end
  /// rather than silently taking someone else's place, and a name this build does not know — a tab
  /// that has since been removed — is passed over.
  static const tabOrder = Setting<List<String>>(
    'shell.tabOrder',
    encode: _encodeNames,
    decode: _decodeNames,
  );

  /// Every setting above. A store that has to be told its keys in advance, as `shared_preferences`'
  /// cached store does, is told these.
  /// Every setting above, for the stores that need to be told which keys exist.
  ///
  /// `SharedPreferencesWithCache` is opened with these as its allow-list, and it **throws** for a
  /// key outside it. So a setting declared here and left out of this list does not quietly read as
  /// unset -- it fails, and it fails on the first read, which is usually a screen doing nothing at
  /// all. `app_settings_test.dart` reads this file and holds the two together, because the list is
  /// maintained by hand and forgetting it is silent at compile time.
  static const all = <Setting<Object>>[
    backupFolder,
    lastBackupAt,
    backupDue,
    backupSetup,
    librarySort,
    shippedExtensionsSeeded,
    shippedExtensionsOffered,
    pinnedSources,
    recentSources,
    listenedBackfilled,
    readerTextScale,
    tabOrder,
  ];
}

String _text(String value) => value;

String _encodeIds(List<int> ids) => ids.join(',');

/// Ids as stored, dropping anything that is not one.
///
/// A value half this build can read is worth reading: a pin list with one unreadable entry should
/// keep the other five rather than silently unpinning everything.
List<int> _decodeIds(String stored) => [
  for (final part in stored.split(','))
    if (int.tryParse(part.trim()) case final id?) id,
];

String _encodeTime(DateTime time) => '${time.millisecondsSinceEpoch}';

/// Throws [ArgumentError] for a time `DateTime` cannot hold, which reads as not set.
DateTime? _decodeTime(String stored) => switch (int.tryParse(stored)) {
  final ms? => DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true),
  null => null,
};

String _encodeFlag(bool value) => '$value';

bool? _decodeFlag(String stored) => switch (stored) {
  'true' => true,
  'false' => false,
  _ => null,
};

String _encodeSetup(BackupSetup setup) => setup.name;

BackupSetup? _decodeSetup(String stored) =>
    BackupSetup.values.asNameMap()[stored];

String _encodeSort(LibrarySort sort) => sort.name;

String _encodeNumber(double value) => '$value';

String _encodeNames(List<String> names) => names.join(',');

List<String> _decodeNames(String stored) => [
  for (final name in stored.split(','))
    if (name.trim().isNotEmpty) name.trim(),
];

/// A text scale, or null for anything that is not one a reader could have chosen.
double? _decodeScale(String stored) => switch (double.tryParse(stored)) {
  final scale? when scale >= 0.5 && scale <= 3 => scale,
  _ => null,
};
