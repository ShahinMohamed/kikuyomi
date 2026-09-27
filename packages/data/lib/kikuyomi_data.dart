/// Drift schema, migrations, repository implementations, mappers and merge rules.
///
/// The database is the single source of truth. Every schema change ships with a migration and a
/// migration test against the generated schema snapshots.
///
/// Pure Dart. This package must never import Flutter or a platform plugin.
library;

export 'src/backup/backed_up_changes.dart';
export 'src/backup/drift_backup_store.dart';
export 'src/database/converters.dart';
export 'src/database/database.dart';
export 'src/database/tables.dart';
export 'src/downloads/chapter_downloads.dart';
export 'src/downloads/download_queue.dart';
export 'src/downloads/download_storage.dart';
export 'src/downloads/drift_download_store.dart';
export 'src/extensions/extension_preferences.dart';
export 'src/extensions/installed_extensions.dart';
export 'src/extensions/repositories.dart';
export 'src/library/book_overview.dart';
export 'src/library/bookmarks.dart';
export 'src/library/continue_listening.dart';
export 'src/library/listened_chapters.dart';
export 'src/library/listening_history.dart';
export 'src/library/remove_from_library.dart';
export 'src/local/import_folder.dart';
export 'src/local/local_covers.dart';
export 'src/local/local_import.dart';
export 'src/local/local_media_resolver.dart';
export 'src/merge/book_details.dart';
export 'src/merge/chapter_sync.dart';
export 'src/merge/credits.dart';
export 'src/playback/drift_playback_store.dart';
export 'src/playback/stored_playback.dart';
export 'src/source/source_books.dart';
export 'src/source/source_covers.dart';
export 'src/source/source_mapping.dart';
export 'src/source/source_media_resolver.dart';
