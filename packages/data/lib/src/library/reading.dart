/// Where a reader is in a book, and the books being read (ADR-0019).
///
/// The reading counterpart of playback progress, and deliberately simpler. Playback progress is
/// chapter-relative milliseconds that the Timeline turns into a place in a whole book, because an
/// audiobook's chapters are laid over files and a book-wide position has to be derived. A text
/// book's chapters are the book, so a place is a chapter and a fraction through it, and that is
/// all.
///
/// A fraction rather than characters or pixels, because it has to survive the reader changing the
/// font size or turning the phone round. Neither should move anyone's place.
library;

import 'dart:math' as math;

import 'package:drift/drift.dart';
import 'package:kikuyomi_domain/kikuyomi_domain.dart';
import 'package:kikuyomi_source_api/kikuyomi_source_api.dart' show SourceKind;

import '../database/database.dart';
import 'watch_tables.dart';

/// A book being read, as Continue Reading shows it.
final class ContinueReadingBook {
  const ContinueReadingBook({
    required this.bookId,
    required this.title,
    required this.author,
    required this.chapterTitle,
    required this.chapterIndex,
    required this.chapterCount,
    required this.progress,
    required this.lastReadAt,
    required this.coverFileName,
  });

  final int bookId;
  final String title;

  /// The first credited author, or null for a book credited with none.
  final String? author;

  /// The chapter the reader is in.
  final String chapterTitle;

  /// Which chapter that is, from 0, and how many there are: "chapter 4 of 30" is how a reader
  /// judges how far through a book they are.
  final int chapterIndex;
  final int chapterCount;

  /// How far through that chapter, from 0 to 1.
  final double progress;

  final DateTime lastReadAt;

  /// The name of the book's cover in the covers folder, or null for a book with no cover.
  final String? coverFileName;

  /// How far through the whole book, from 0 to 1, counting chapters as equal.
  ///
  /// An approximation, and an honest one: chapters differ in length, and nothing here knows by how
  /// much until each has been fetched. It moves the right way and ends at 1, which is what a bar on
  /// a card needs.
  double get bookProgress => chapterCount == 0
      ? 0
      : math.min(1, (chapterIndex + progress) / chapterCount);
}

/// Records that the reader of [bookId] is [progress] of the way through [chapterId].
///
/// [progress] is clamped to 0 to 1: a scroll position read a frame late can land a hair outside
/// it, and a stored 1.0000003 would read as past the end of the chapter.
Future<void> saveReadingPosition(
  KikuyomiDatabase db, {
  required int bookId,
  required int chapterId,
  required double progress,
  required Clock clock,
}) => db
    .into(db.readingStates)
    .insertOnConflictUpdate(
      ReadingStatesCompanion.insert(
        bookId: Value(bookId),
        chapterId: chapterId,
        progress: progress.isNaN ? 0 : progress.clamp(0.0, 1.0),
        updatedAt: clock.now(),
      ),
    );

/// Where the reader of [bookId] is, or null for a book not yet opened.
Future<ReadingStateRow?> readReadingPosition(KikuyomiDatabase db, int bookId) =>
    (db.select(
      db.readingStates,
    )..where((r) => r.bookId.equals(bookId))).getSingleOrNull();

/// Records that chapter [chapterId] holds [words] words, for the reading time shown beside it.
///
/// Written once, the first time a chapter's text is fetched, and left alone after: the figure is
/// about the text, which does not change, and rewriting it on every read would wake every stream
/// watching the chapter list for nothing.
Future<void> saveChapterWordCount(
  KikuyomiDatabase db,
  int chapterId,
  int words,
) async {
  await (db.update(db.chapters)
        ..where((c) => c.id.equals(chapterId) & c.wordCount.isNull()))
      .write(ChaptersCompanion(wordCount: Value(words)));
}

/// Where the reader of [bookId] is, watched: null until it is first opened.
Stream<ReadingStateRow?> watchReadingPosition(
  KikuyomiDatabase db,
  int bookId,
) => (db.select(
  db.readingStates,
)..where((r) => r.bookId.equals(bookId))).watchSingleOrNull();

/// The books in the library of [kind], newest added first, watched.
///
/// The shelf of one tab. Listening and reading are separate tabs, so each asks for its own kind
/// rather than filtering a shared list — which would rebuild the audiobook shelf every time a
/// reader turned a page.
Stream<List<BookRow>> watchShelf(KikuyomiDatabase db, SourceKind kind) =>
    (db.select(db.books)
          ..where((b) => b.inLibrary.equals(true) & b.kind.equalsValue(kind))
          ..orderBy([(b) => OrderingTerm.desc(b.dateAdded)]))
        .watch();

/// Continue Reading: the books in the library being read and not finished, most recently read
/// first.
///
/// A book is being read when it has a reading position. It is finished when its last chapter is
/// recorded as listened — `is_listened` meaning finished however it was consumed, which ADR-0019
/// chose over a second column meaning the same thing.
Stream<List<ContinueReadingBook>> watchContinueReading(KikuyomiDatabase db) =>
    watchTables(db, [
      db.readingStates,
      db.books,
      db.chapters,
      db.bookPeople,
      db.people,
    ], () => _loadContinueReading(db));

Future<List<ContinueReadingBook>> _loadContinueReading(
  KikuyomiDatabase db,
) async {
  final rows =
      await (db.select(db.readingStates).join([
              innerJoin(
                db.books,
                db.books.id.equalsExp(db.readingStates.bookId),
              ),
              innerJoin(
                db.chapters,
                db.chapters.id.equalsExp(db.readingStates.chapterId),
              ),
            ])
            ..where(
              db.books.inLibrary.equals(true) &
                  db.books.kind.equalsValue(SourceKind.text),
            )
            ..orderBy([OrderingTerm.desc(db.readingStates.updatedAt)]))
          .get();

  final shelf = <ContinueReadingBook>[];
  for (final row in rows) {
    final book = row.readTable(db.books);
    final state = row.readTable(db.readingStates);
    final chapter = row.readTable(db.chapters);

    final chapters =
        await (db.select(db.chapters)
              ..where(
                (c) =>
                    c.bookId.equals(book.id) &
                    c.removedFromSource.equals(false),
              )
              ..orderBy([
                (c) => OrderingTerm.asc(c.sourceIndex),
                (c) => OrderingTerm.asc(c.id),
              ]))
            .get();
    if (chapters.isEmpty) continue;
    // Finished: its last chapter is recorded as done. It leaves the shelf, and comes back if that
    // is ever undone, exactly as a finished audiobook does.
    if (chapters.last.isListened) continue;

    final author =
        await (db.select(db.bookPeople).join([
                innerJoin(
                  db.people,
                  db.people.id.equalsExp(db.bookPeople.personId),
                ),
              ])
              ..where(
                db.bookPeople.bookId.equals(book.id) &
                    db.bookPeople.role.equalsValue(ContributorRole.author),
              )
              ..orderBy([OrderingTerm.asc(db.bookPeople.ordinal)])
              ..limit(1))
            .getSingleOrNull();

    final index = chapters.indexWhere((c) => c.id == chapter.id);
    shelf.add(
      ContinueReadingBook(
        bookId: book.id,
        title: book.title,
        author: author?.readTable(db.people).name,
        chapterTitle: chapter.title,
        chapterIndex: math.max(0, index),
        chapterCount: chapters.length,
        progress: state.progress,
        lastReadAt: state.updatedAt,
        coverFileName: book.coverLocalPath,
      ),
    );
  }
  return shelf;
}
