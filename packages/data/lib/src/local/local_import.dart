import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:kikuyomi_domain/kikuyomi_domain.dart';
import 'package:kikuyomi_source_api/kikuyomi_source_api.dart' show SourceKind;

import '../database/database.dart';
import 'local_covers.dart';

/// The built-in Local files source (§3.10).
///
/// A fixed id for now. §3 derives source ids from a hash of the extension, source name, language and
/// version, and that scheme arrives with the extension contract in `source_api`. When it does, this
/// constant becomes that hash, by way of a migration.
const localSourceId = 1;

/// One audio file of a local book, as probed from disk.
final class LocalBookFile {
  const LocalBookFile({
    required this.path,
    required this.durationMs,
    this.durationIsEstimate = false,
    this.sizeBytes,
    this.format,
    this.markers = const [],
  });

  /// Where the file is: an absolute path for a file the user keeps, or a path relative to the media
  /// root for a file in the app's own storage, as `LocalMediaResolver` describes. It identifies the
  /// file within its book, and a single-file book by itself, so importing the same file twice finds
  /// the same book.
  final String path;

  /// Probed from the file itself.
  final int durationMs;

  /// True when [durationMs] was estimated, as it is for an MP3 whose frames nothing counts. §4.5
  /// keeps estimated durations apart from known ones.
  final bool durationIsEstimate;
  final int? sizeBytes;
  final String? format;

  /// Embedded chapter markers, as offsets into the file.
  final List<TimelineMarker> markers;
}

/// A single-file local book to add to the library.
final class LocalBookImport {
  const LocalBookImport({
    required this.file,
    required this.title,
    this.authors = const [],
    this.narrators = const [],
    this.cover,
  });

  final LocalBookFile file;
  final String title;
  final List<String> authors;
  final List<String> narrators;

  /// The picture embedded in the file, or null when it has none. See [importLocalBook] for when it
  /// is kept.
  final CoverImage? cover;
}

/// One file of a local book in several files, and the chapter it holds.
final class LocalTrackImport {
  const LocalTrackImport({required this.file, required this.title});

  final LocalBookFile file;

  /// The title of the chapter the file becomes.
  final String title;
}

/// A local book in several files, such as a folder of MP3s, to add to the library.
final class LocalFolderImport {
  const LocalFolderImport({
    required this.key,
    required this.title,
    required this.tracks,
    this.authors = const [],
    this.narrators = const [],
    this.cover,
  });

  /// The folder, written as file paths are: absolute, or relative to the media root. The book's
  /// identity within the Local source.
  final String key;
  final String title;

  /// In playing order.
  final List<LocalTrackImport> tracks;
  final List<String> authors;
  final List<String> narrators;

  /// The cover found beside the files or in them, or null when there is none. See
  /// [importLocalFolderBook] for when it is kept.
  final CoverImage? cover;
}

/// One chapter of a local EPUB: a document of its spine.
final class LocalEpubChapter {
  const LocalEpubChapter({required this.key, required this.title});

  /// The document's path inside the EPUB, which is what the reader opens.
  final String key;
  final String title;
}

/// A local EPUB to add to the library as a book to read (ADR-0019).
final class LocalEpubImport {
  const LocalEpubImport({
    required this.path,
    required this.title,
    required this.chapters,
    this.authors = const [],
    this.language,
    this.description,
    this.publisher,
    this.cover,
  });

  /// Where the file is, written as file paths are: absolute, or relative to the media root. The
  /// book's identity within the Local source, so importing the same file twice finds the same book.
  final String path;
  final String title;

  /// In reading order.
  final List<LocalEpubChapter> chapters;
  final List<String> authors;
  final String? language;
  final String? description;
  final String? publisher;

  /// The book's cover image, or null when it names none. Kept as [importLocalBook] keeps one.
  final CoverImage? cover;
}

/// Adds a single-file local book, such as an M4B, to the library and returns its id.
///
/// It is stored the way §4.5 describes a single file with embedded markers: one source chapter
/// spanning the whole file, with the markers kept on the file so the Timeline presents them as
/// virtual chapters. Progress and bookmarks then anchor to that chapter plus an offset, which stays
/// valid even if the markers are later retagged.
///
/// Importing a file that is already known returns the existing book, putting it back in the library
/// if it had been taken out, so an import can safely be repeated.
///
/// Given [covers], the book's [LocalBookImport.cover] is then kept there, or its lack recorded, as
/// [keepBookCover] does. That happens once the book is saved, since a cover is named after the
/// book's id, and for a book already known only while its cover has never been looked for, which is
/// how adding again a book from before covers were kept brings its cover. Without [covers] the cover
/// is left for [lookForLocalCover] to find later. A cover that cannot be written never fails the
/// import; it is left for later too.
///
/// This is a Phase 1 stand-in for the Local source proper, which will implement the extension
/// contract in `source_api` once that contract is designed.
Future<int> importLocalBook(
  KikuyomiDatabase db,
  LocalBookImport book, {
  required Clock clock,
  CoverFiles? covers,
}) async {
  final now = clock.now();
  final bookId = await db.transaction(() async {
    final existing = await _findBook(db, book.file.path, now);
    if (existing != null) return existing;

    final bookId = await _addBook(
      db,
      key: book.file.path,
      title: book.title,
      totalDurationMs: book.file.durationMs,
      authors: book.authors,
      narrators: book.narrators,
      now: now,
    );
    await _addChapter(
      db,
      bookId: bookId,
      key: 'whole',
      title: book.title,
      index: 0,
      file: book.file,
      now: now,
    );
    return bookId;
  });
  await _keepCover(db, bookId, book.cover, covers: covers, clock: clock);
  return bookId;
}

/// Adds a local book in several files, such as a folder of MP3s, and returns its id.
///
/// Each file becomes one chapter, the first of §1.5's layouts: one file per chapter. The book is
/// identified by [LocalFolderImport.key], so importing the same folder again finds the same book, and
/// puts it back in the library if it had been taken out. Files added to the folder since are not
/// picked up that way; that waits for the Local source proper, which will sync a folder's chapters as
/// §4.4 syncs any source's.
///
/// The cover is kept as [importLocalBook] keeps it, given [covers].
///
/// Fails with an [ArgumentError] for a book with no tracks.
Future<int> importLocalFolderBook(
  KikuyomiDatabase db,
  LocalFolderImport book, {
  required Clock clock,
  CoverFiles? covers,
}) async {
  if (book.tracks.isEmpty) {
    throw ArgumentError.value(book.key, 'book', 'has no tracks');
  }
  final now = clock.now();
  final bookId = await db.transaction(() async {
    final existing = await _findBook(db, book.key, now);
    if (existing != null) return existing;

    final bookId = await _addBook(
      db,
      key: book.key,
      title: book.title,
      totalDurationMs: book.tracks.fold<int>(
        0,
        (total, track) => total + track.file.durationMs,
      ),
      authors: book.authors,
      narrators: book.narrators,
      now: now,
    );
    for (final (index, track) in book.tracks.indexed) {
      await _addChapter(
        db,
        bookId: bookId,
        key: track.file.path,
        title: track.title,
        index: index,
        file: track.file,
        now: now,
      );
    }
    return bookId;
  });
  await _keepCover(db, bookId, book.cover, covers: covers, clock: clock);
  return bookId;
}

/// Adds a local EPUB to the library as a book to read, and returns its id.
///
/// Each document of its spine becomes a chapter, keyed by its path inside the EPUB. There are no
/// media files: a book to read has nothing to play, and its text is read out of the EPUB when a
/// chapter is opened rather than copied into the database, which keeps the database small and the
/// EPUB the one copy of the book.
///
/// Importing a file that is already known returns the existing book, as [importLocalBook] does. The
/// cover is kept as it keeps one, given [covers].
///
/// Fails with an [ArgumentError] for a book with no chapters.
Future<int> importLocalEpub(
  KikuyomiDatabase db,
  LocalEpubImport book, {
  required Clock clock,
  CoverFiles? covers,
}) async {
  if (book.chapters.isEmpty) {
    throw ArgumentError.value(book.path, 'book', 'has no chapters');
  }
  final now = clock.now();
  final bookId = await db.transaction(() async {
    final existing = await _findBook(db, book.path, now);
    if (existing != null) return existing;

    final bookId = await _addBook(
      db,
      key: book.path,
      title: book.title,
      kind: SourceKind.text,
      authors: book.authors,
      narrators: const [],
      now: now,
    );
    await (db.update(db.books)..where((b) => b.id.equals(bookId))).write(
      BooksCompanion(
        language: Value(book.language),
        description: Value(book.description),
        publisher: Value(book.publisher),
      ),
    );
    for (final (index, chapter) in book.chapters.indexed) {
      await db
          .into(db.chapters)
          .insert(
            ChaptersCompanion(
              bookId: Value(bookId),
              key: Value(chapter.key),
              title: Value(chapter.title),
              sourceIndex: Value(index),
              createdAt: Value(now),
              updatedAt: Value(now),
            ),
          );
    }
    return bookId;
  });
  await _keepCover(db, bookId, book.cover, covers: covers, clock: clock);
  return bookId;
}

/// Keeps [image] as the cover of the book just imported, when there is a [covers] folder to keep it
/// in.
Future<void> _keepCover(
  KikuyomiDatabase db,
  int bookId,
  CoverImage? image, {
  required CoverFiles? covers,
  required Clock clock,
}) async {
  if (covers == null) return;
  try {
    await keepBookCover(db, bookId, image, covers: covers, clock: clock);
  } on FileSystemException {
    // The book is in the library, and a cover is not worth failing that for. It is still to be looked
    // for, so a later look can try again.
  }
}

/// The Local book with [key], put back in the library if it had been taken out, or null if there
/// is none yet. Also makes sure the Local source itself exists.
Future<int?> _findBook(KikuyomiDatabase db, String key, DateTime now) async {
  await db
      .into(db.sources)
      .insert(
        const SourcesCompanion(
          id: Value(localSourceId),
          key: Value('local'),
          name: Value('Local files'),
          lang: Value('und'),
        ),
        mode: InsertMode.insertOrIgnore,
      );

  final existing =
      await (db.select(
            db.books,
          )..where((b) => b.sourceId.equals(localSourceId) & b.key.equals(key)))
          .getSingleOrNull();
  if (existing == null) return null;
  if (!existing.inLibrary) {
    await (db.update(db.books)..where((b) => b.id.equals(existing.id))).write(
      BooksCompanion(
        inLibrary: const Value(true),
        dateAdded: Value(now),
        updatedAt: Value(now),
      ),
    );
  }
  return existing.id;
}

/// Inserts the book row and its credits, and returns the book's id.
Future<int> _addBook(
  KikuyomiDatabase db, {
  required String key,
  required String title,
  int? totalDurationMs,
  SourceKind kind = SourceKind.audio,
  required List<String> authors,
  required List<String> narrators,
  required DateTime now,
}) async {
  final bookId = await db
      .into(db.books)
      .insert(
        BooksCompanion(
          sourceId: const Value(localSourceId),
          key: Value(key),
          title: Value(title),
          totalDurationMs: Value(totalDurationMs),
          kind: Value(kind),
          inLibrary: const Value(true),
          dateAdded: Value(now),
          detailsFetched: const Value(true),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );

  Future<void> credit(List<String> names, ContributorRole role) async {
    for (var i = 0; i < names.length; i++) {
      final name = names[i].trim();
      if (name.isEmpty) continue;
      await db
          .into(db.people)
          .insert(
            PeopleCompanion(name: Value(name)),
            mode: InsertMode.insertOrIgnore,
          );
      final person = await (db.select(
        db.people,
      )..where((p) => p.name.equals(name))).getSingle();
      await db
          .into(db.bookPeople)
          .insert(
            BookPeopleCompanion(
              bookId: Value(bookId),
              personId: Value(person.id),
              role: Value(role),
              ordinal: Value(i),
            ),
            mode: InsertMode.insertOrIgnore,
          );
    }
  }

  await credit(authors, ContributorRole.author);
  await credit(narrators, ContributorRole.narrator);
  return bookId;
}

/// Inserts [file] and a chapter spanning the whole of it.
Future<void> _addChapter(
  KikuyomiDatabase db, {
  required int bookId,
  required String key,
  required String title,
  required int index,
  required LocalBookFile file,
  required DateTime now,
}) async {
  final fileId = await db
      .into(db.mediaFiles)
      .insert(
        MediaFilesCompanion(
          bookId: Value(bookId),
          fileKey: Value(file.path),
          format: Value(file.format),
          durationMs: Value(file.durationMs),
          durationIsEstimate: Value(file.durationIsEstimate),
          sizeBytes: Value(file.sizeBytes),
          embeddedMarkers: Value(file.markers.isEmpty ? null : file.markers),
          // A local file is, in §4.3's terms, already downloaded: it is on this device.
          localPath: Value(file.path),
        ),
      );

  final chapterId = await db
      .into(db.chapters)
      .insert(
        ChaptersCompanion(
          bookId: Value(bookId),
          key: Value(key),
          title: Value(title),
          sourceIndex: Value(index),
          durationMs: Value(file.durationMs),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );

  await db
      .into(db.chapterSegments)
      .insert(
        ChapterSegmentsCompanion(
          chapterId: Value(chapterId),
          ordinal: const Value(0),
          mediaFileId: Value(fileId),
        ),
      );
}
