/// A book that is one file: SourceAPI 1.2's `BookFile` (ADR-0021).
///
/// Most of the free-ebook world publishes a book as one EPUB to download and nothing else — no
/// per-chapter text to ask for, so nothing for `getChapterContent` to fetch. Such a source says
/// where the file is and the app reads it with the reader it already has for books added from the
/// device: same spine, same titles, same refusal of a book locked with DRM.
library;

import 'http_request.dart';

/// How a book's file is packed, as the source says.
///
/// One value so far. It is a field rather than an assumption so that a later version can add
/// another without changing what `resolveBook` means, and [unknown] is what a format this build
/// does not know reads as, so that an older app refuses the file rather than mistaking it for an
/// EPUB.
enum BookFileFormat { epub, unknown }

/// The whole of a book, as `resolveBook` gives it.
final class BookFile {
  const BookFile({
    required this.request,
    this.format = BookFileFormat.epub,
    this.sizeBytes,
  });

  /// How to fetch the file.
  final HttpRequest request;

  final BookFileFormat format;

  /// How large it is, when the source says, so that the size can be shown before the download
  /// rather than discovered during it.
  final int? sizeBytes;

  @override
  bool operator ==(Object other) =>
      other is BookFile &&
      other.request == request &&
      other.format == format &&
      other.sizeBytes == sizeBytes;

  @override
  int get hashCode => Object.hash(request, format, sizeBytes);

  @override
  String toString() => 'BookFile(${format.name}, ${request.url})';
}
