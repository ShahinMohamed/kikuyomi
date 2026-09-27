import 'dart:io';

import 'package:drift/drift.dart';
import 'package:kikuyomi_domain/kikuyomi_domain.dart';

import '../database/database.dart';
import 'local_import.dart' show localSourceId;
import 'local_media_resolver.dart' show resolveLocalPath;

/// A cover image found in a book's files, ready to be kept.
final class CoverImage {
  const CoverImage({required this.mimeType, required this.bytes});

  /// Such as `image/jpeg`. It decides the extension the image is kept with.
  final String mimeType;

  /// The encoded image, written out as it is.
  final Uint8List bytes;
}

/// The folder where the covers of books in the library are kept, and the files in it that book rows
/// name.
///
/// §5.1 keeps library covers in app-internal storage. A book row records its cover in
/// `cover_local_path` as a file name within [directory], never as an absolute path: on iOS the
/// app's container can move when the app is updated or reinstalled, which would leave every
/// absolute path into it pointing nowhere. The name comes from the book's id and never from its
/// title, as §5.1 names downloads, so no title has to be made safe as a file name.
final class CoverFiles {
  const CoverFiles(this.directory);

  final Directory directory;

  /// The file of the cover a book row names [fileName], or null for a book with no cover.
  File? fileOf(String? fileName) =>
      fileName == null ? null : File('${directory.path}/$fileName');

  /// Writes [image] as the cover of book [bookId] and returns the file name to record it under, or
  /// returns null, writing nothing, for an image of a type the app does not show.
  ///
  /// The image goes to a temporary file first and is renamed into place, so a cover file is never
  /// seen half-written, even when the app is stopped partway through. Throws a
  /// [FileSystemException] when it cannot be written.
  Future<String?> write(int bookId, CoverImage image) async {
    final extension = _extensions[image.mimeType];
    if (extension == null) return null;
    final fileName = '$bookId.$extension';
    await directory.create(recursive: true);
    // Numbered, so two writes under way at once never share a temporary file.
    final partial = File('${directory.path}/.$fileName.${_writes++}.part');
    try {
      await partial.writeAsBytes(image.bytes, flush: true);
      await partial.rename('${directory.path}/$fileName');
    } catch (_) {
      try {
        await partial.delete();
      } on FileSystemException {
        // Never created, so there is nothing to clear away.
      }
      rethrow;
    }
    return fileName;
  }

  static var _writes = 0;
}

/// The image types kept, with the extension each is kept under: those Flutter decodes on every
/// platform the app runs on. Anything else could only ever show as a placeholder.
const _extensions = {
  'image/jpeg': 'jpg',
  'image/png': 'png',
  'image/gif': 'gif',
  'image/webp': 'webp',
  'image/bmp': 'bmp',
};

/// Records the cover of book [bookId]: keeps [image] in [covers] and names it on the book, or, when
/// [image] is null, records that the book has none.
///
/// The same for a cover read out of a local book's files and one fetched from a source's `coverUrl`:
/// where the image came from is the caller's business, and what happens to it is the same.
///
/// Either way `cover_updated_at` is set. That is what marks a book's cover as looked for, so a book
/// whose files carry no cover is not read again for one at every start. The file is written before
/// the row names it, so a row never names a cover that is not there.
///
/// Nothing is recorded for a book whose cover has already been looked for or that already has one,
/// and nothing ever replaces a cover the user chose. §4.4: "a custom cover always survives". A
/// custom cover is one the book already has when this runs, and a user's edit of the cover is
/// recorded in `user_overrides` as an edit of any field is, which `mergeBookDetails` respects the
/// same way.
///
/// Does nothing for a book that does not exist. Throws a [FileSystemException] when the image cannot
/// be written, leaving the book's cover still to be looked for.
Future<void> keepBookCover(
  KikuyomiDatabase db,
  int bookId,
  CoverImage? image, {
  required CoverFiles covers,
  required Clock clock,
}) async {
  final book = await (db.select(
    db.books,
  )..where((b) => b.id.equals(bookId))).getSingleOrNull();
  if (book == null || !_awaitsCover(book)) return;
  final fileName = image == null ? null : await covers.write(bookId, image);
  // Checked again as it is written, in case another look at the same book got there first.
  await (db.update(db.books)..where(
        (b) =>
            b.id.equals(bookId) &
            b.coverUpdatedAt.isNull() &
            b.coverLocalPath.isNull(),
      ))
      .write(
        BooksCompanion(
          coverLocalPath: Value(fileName),
          coverUpdatedAt: Value(clock.now()),
        ),
      );
}

bool _awaitsCover(BookRow book) =>
    book.coverUpdatedAt == null &&
    book.coverLocalPath == null &&
    !book.userOverrides.contains(BookField.coverUrl);

/// A local book whose cover has never been looked for, and where to look for it.
final class LocalBookAwaitingCover {
  const LocalBookAwaitingCover({
    required this.bookId,
    required this.audioPath,
    this.folderPath,
  });

  final int bookId;

  /// The book's file, or the first of its files in playing order, as file paths are stored: absolute,
  /// or relative to the media root.
  final String audioPath;

  /// For a book in a folder of files, the folder, stored the same way. Null for a book in one file.
  final String? folderPath;
}

/// The local books in the library whose cover has never been looked for, the most recently added
/// first.
///
/// They are books added before covers were kept, and any whose cover could not be written when they
/// were added. A book out of the library is left until it is added again, which looks for its cover
/// then, so a removed book whose files are gone is not looked for at every start.
Future<List<LocalBookAwaitingCover>> localBooksAwaitingCover(
  KikuyomiDatabase db,
) async {
  final books =
      await (db.select(db.books)
            ..where(
              (b) =>
                  b.sourceId.equals(localSourceId) &
                  b.inLibrary.equals(true) &
                  b.coverUpdatedAt.isNull() &
                  b.coverLocalPath.isNull(),
            )
            // By id rather than by date added: the order matters little, and ids never tie.
            ..orderBy([(b) => OrderingTerm.desc(b.id)]))
          .get();
  final awaiting = <LocalBookAwaitingCover>[];
  for (final book in books) {
    if (!_awaitsCover(book)) continue;
    final first =
        await (db.select(db.mediaFiles).join([
                innerJoin(
                  db.chapterSegments,
                  db.chapterSegments.mediaFileId.equalsExp(db.mediaFiles.id),
                ),
                innerJoin(
                  db.chapters,
                  db.chapters.id.equalsExp(db.chapterSegments.chapterId),
                ),
              ])
              ..where(
                db.mediaFiles.bookId.equals(book.id) &
                    db.mediaFiles.localPath.isNotNull() &
                    db.chapters.removedFromSource.equals(false),
              )
              ..orderBy([
                OrderingTerm.asc(db.chapters.sourceIndex),
                OrderingTerm.asc(db.chapters.id),
                OrderingTerm.asc(db.chapterSegments.ordinal),
              ])
              ..limit(1))
            .getSingleOrNull();
    if (first == null) continue;
    final audioPath = first.readTable(db.mediaFiles).localPath!;
    awaiting.add(
      LocalBookAwaitingCover(
        bookId: book.id,
        audioPath: audioPath,
        // The local import keys a book in one file by the file's path and a book in a folder by the
        // folder's, so a key that is not the first file's path is a folder.
        folderPath: audioPath == book.key ? null : book.key,
      ),
    );
  }
  return awaiting;
}

/// Forgets that a book was looked at and found to have no cover, so it will be looked at again.
///
/// A book is recorded as having no cover so that every start does not read every file again. That is
/// right, and it also means the answer is permanent: a listener who adds artwork beside their files,
/// or who updates to a build that reads a format better than the one that looked, has no way to ask
/// again. This is that way.
///
/// Only books with no cover kept. One that has an image is left alone, including a custom one §4.4
/// protects.
Future<int> forgetMissingCovers(KikuyomiDatabase db) =>
    (db.update(db.books)..where(
          (b) => b.coverLocalPath.isNull() & b.coverUpdatedAt.isNotNull(),
        ))
        .write(const BooksCompanion(coverUpdatedAt: Value(null)));

/// Reads a book's cover from its files: [audio], its file or first file, and for a book in a folder
/// the [folder], both where they are on this device.
///
/// Returns the cover, or null when the files hold none. Throws a [FileSystemException] when they
/// cannot be read.
typedef LocalCoverReader = Future<CoverImage?> Function(
  File audio,
  Directory? folder,
);

/// Looks for [book]'s cover with [read] and records what it finds, as [keepBookCover] does, so that
/// a book with no cover is not looked for again.
///
/// A book whose file is missing or cannot be read is skipped quietly and left to be looked for
/// another time, since its files may come back, as they do when a drive is plugged in again. So is
/// one whose cover cannot be written.
Future<void> lookForLocalCover(
  KikuyomiDatabase db,
  LocalBookAwaitingCover book, {
  required Directory mediaRoot,
  required LocalCoverReader read,
  required CoverFiles covers,
  required Clock clock,
}) async {
  final audio = File(resolveLocalPath(book.audioPath, mediaRoot: mediaRoot));
  if (!await audio.exists()) return;
  final folderPath = book.folderPath;
  try {
    final image = await read(
      audio,
      folderPath == null
          ? null
          : Directory(resolveLocalPath(folderPath, mediaRoot: mediaRoot)),
    );
    await keepBookCover(db, book.bookId, image, covers: covers, clock: clock);
  } on FileSystemException {
    // Left for another time.
  }
}
