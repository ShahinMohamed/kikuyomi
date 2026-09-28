/// Fetching what a chapter of a book to read says (ADR-0019).
///
/// Two ways, by where the book came from. A local EPUB is read off this device, a chapter at a time,
/// with the pictures it shows. A book from a source is asked of the source, whose answer SourceAPI
/// has already decoded and checked by the time it gets here.
///
/// Nothing is kept in the database. A chapter's text is the source's, or the file's, and reading it
/// again is how it stays theirs.
library;

import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:kikuyomi_data/kikuyomi_data.dart';
import 'package:kikuyomi_source_api/kikuyomi_source_api.dart' as api;
import 'package:kikuyomi_sources_builtin/kikuyomi_sources_builtin.dart';

/// A chapter, ready to draw: its blocks, and the pictures a local book holds for them.
final class ChapterText {
  const ChapterText(this.content, {this.pictures = const {}});

  final api.ChapterContent content;

  /// The bytes of each picture the chapter shows from inside its own book, by the path its
  /// [api.ImageBlock] names. Empty for a book from a source, whose pictures are on the web.
  final Map<String, Uint8List> pictures;
}

/// A chapter that cannot be read, said in words for the reader.
final class ChapterTextException implements Exception {
  const ChapterTextException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Reads chapters of books to read.
final class ChapterTexts {
  ChapterTexts(
    this._db, {
    required this.mediaRoot,
    required this.bookFiles,
    required this.openSource,
  });

  final KikuyomiDatabase _db;

  /// What a local book's stored path is relative to, when it is not absolute.
  final Directory mediaRoot;

  /// Where a book downloaded whole from a source is kept (ADR-0021).
  final Directory bookFiles;

  /// Opens the source a book came from.
  final Future<api.ContentSource> Function(int sourceId) openSource;

  /// What chapter [chapterId] of book [bookId] says.
  ///
  /// Throws [ChapterTextException] for a chapter that cannot be read, saying why.
  Future<ChapterText> load(int bookId, int chapterId) async {
    final book = await (_db.select(
      _db.books,
    )..where((b) => b.id.equals(bookId))).getSingleOrNull();
    final chapter = await (_db.select(
      _db.chapters,
    )..where((c) => c.id.equals(chapterId))).getSingleOrNull();
    if (book == null || chapter == null || chapter.bookId != bookId) {
      throw const ChapterTextException('This chapter is no longer here.');
    }
    // A book that is one file: one added from this device, whose key is its path, or one
    // downloaded whole from a source (ADR-0021). Either way the text is in the file, not on the web.
    final onDevice = book.sourceId == localSourceId;
    final path = book.filePath ?? (onDevice ? book.key : null);
    if (path != null) {
      final file = File(
        resolveLocalPath(path, mediaRoot: onDevice ? mediaRoot : bookFiles),
      );
      if (!await file.exists()) {
        throw ChapterTextException(
          onDevice
              ? 'The book is no longer at ${file.path}. Add it again from where it is now.'
              : 'This book is no longer on the device. Add it again to download it.',
        );
      }
      return readEpubChapter(file, chapter.key);
    }
    final source = await openSource(book.sourceId);
    return ChapterText(
      await source.getChapterContent(
        api.ChapterRef(bookKey: book.key, chapterKey: chapter.key),
      ),
    );
  }
}

/// Reads chapter [chapterPath] of the EPUB [file], with the pictures it shows, on another isolate:
/// unzipping a book takes long enough to drop frames if the reader waited on it.
Future<ChapterText> readEpubChapter(File file, String chapterPath) =>
    Isolate.run(() async {
      final book = EpubBook.read(await file.readAsBytes());
      final content = book.chapterContent(chapterPath);
      final pictures = <String, Uint8List>{};
      for (final block in content.blocks) {
        // The only pictures a local book shows are its own, named by a path with no scheme.
        if (block is api.ImageBlock && !block.url.hasScheme) {
          final bytes = book.resource(block.url.path);
          if (bytes != null) pictures[block.url.path] = bytes;
        }
      }
      return ChapterText(content, pictures: pictures);
    });
