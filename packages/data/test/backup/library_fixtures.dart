// A library seeded straight into the database's tables, with something in every column, and a way to
// compare two databases row for row.

import 'dart:convert';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:kikuyomi_data/kikuyomi_data.dart';
import 'package:kikuyomi_domain/kikuyomi_domain.dart';
import 'package:kikuyomi_source_api/kikuyomi_source_api.dart' show SourceKind;

/// [minutes] after the seed time, with milliseconds, so that anything rounding to seconds shows up.
DateTime at(int minutes) => DateTime.utc(
  2026,
  9,
  1,
  12,
).add(Duration(minutes: minutes, milliseconds: 250));

KikuyomiDatabase openDatabase() => KikuyomiDatabase(NativeDatabase.memory());

const catalogSourceId = -4242424242424242424;
const browsedSourceId = 99;
const aBook = '/books/a-book';
const startedBook = r'C:\Books\Started.m4b';

/// Seeds a library that sets every column of every table at least once:
///
/// - [aBook], in the library, with credits, edited details, three chapters over two files, progress,
///   sessions, bookmarks and a category;
/// - [startedBook], never added to the library but listened to;
/// - a book only browsed past, from a source nothing else uses, which backups leave out.
Future<void> seedLibrary(KikuyomiDatabase db) async {
  await db
      .into(db.sources)
      .insert(
        const SourcesCompanion(
          id: Value(localSourceId),
          key: Value('local'),
          name: Value('Local files'),
          lang: Value('und'),
        ),
      );
  await db
      .into(db.sources)
      .insert(
        SourcesCompanion(
          id: const Value(catalogSourceId),
          extensionId: const Value('org.example.catalog'),
          key: const Value('catalog'),
          name: const Value('A Catalog'),
          lang: const Value('en'),
          contentRating: const Value('everyone'),
          isEnabled: const Value(false),
          isPinned: const Value(true),
          lastUsedAt: Value(at(1)),
        ),
      );
  await db
      .into(db.sources)
      .insert(
        const SourcesCompanion(
          id: Value(browsedSourceId),
          key: Value('browsed'),
          name: Value('Browsed'),
          lang: Value('en'),
        ),
      );

  final nextUp = await db
      .into(db.categories)
      .insert(
        const CategoriesCompanion(
          name: Value('Next up'),
          sortOrder: Value(0),
          flags: Value(5),
        ),
      );
  await db
      .into(db.categories)
      .insert(
        const CategoriesCompanion(name: Value('Empty'), sortOrder: Value(1)),
      );

  final book = await db
      .into(db.books)
      .insert(
        BooksCompanion(
          sourceId: const Value(catalogSourceId),
          key: const Value(aBook),
          title: const Value('A Book'),
          subtitle: const Value('A Subtitle'),
          description: const Value('A description.'),
          coverUrl: const Value('https://example.org/cover.jpg'),
          coverLocalPath: const Value('covers/a-book.jpg'),
          coverUpdatedAt: Value(at(2)),
          seriesName: const Value('A Series'),
          seriesIndex: const Value(2.5),
          genres: const Value(['Fiction', 'Classics']),
          language: const Value('en'),
          publisher: const Value('A Publisher'),
          publishedDate: const Value('1900'),
          isbn: const Value('0000000000'),
          abridged: const Value(false),
          status: const Value('complete'),
          contentRating: const Value('everyone'),
          totalDurationMs: const Value(500000),
          webUrl: const Value('https://example.org/a-book'),
          inLibrary: const Value(true),
          dateAdded: Value(at(3)),
          lastRefreshedAt: Value(at(4)),
          detailsFetched: const Value(true),
          userOverrides: const Value({BookField.title}),
          playbackSpeed: const Value(1.25),
          createdAt: Value(at(5)),
          updatedAt: Value(at(6)),
        ),
      );

  for (final (name, role, ordinal) in [
    ('An Author', ContributorRole.author, 0),
    ('A Narrator', ContributorRole.narrator, 0),
    ('Another Narrator', ContributorRole.narrator, 1),
  ]) {
    final person = await db
        .into(db.people)
        .insert(PeopleCompanion(name: Value(name)));
    await db
        .into(db.bookPeople)
        .insert(
          BookPeopleCompanion(
            bookId: Value(book),
            personId: Value(person),
            role: Value(role),
            ordinal: Value(ordinal),
          ),
        );
  }

  final part1 = await db
      .into(db.mediaFiles)
      .insert(
        MediaFilesCompanion(
          bookId: Value(book),
          fileKey: const Value('part1.mp3'),
          format: const Value('mp3'),
          durationMs: const Value(300000),
          durationIsEstimate: const Value(false),
          sizeBytes: const Value(4800000),
          embeddedMarkers: const Value([
            TimelineMarker(title: 'Opening', startMs: 0),
            TimelineMarker(title: 'Middle', startMs: 150000),
          ]),
          localPath: const Value('Import/part1.mp3'),
          downloadedAt: Value(at(7)),
        ),
      );
  final part2 = await db
      .into(db.mediaFiles)
      .insert(
        MediaFilesCompanion(
          bookId: Value(book),
          fileKey: const Value('part2.mp3'),
          durationMs: const Value(200000),
        ),
      );

  final one = await db
      .into(db.chapters)
      .insert(
        ChaptersCompanion(
          bookId: Value(book),
          key: const Value('one'),
          title: const Value('Chapter One'),
          sourceIndex: const Value(0),
          groupName: const Value('Part One'),
          durationMs: const Value(290000),
          publishedAt: Value(at(8)),
          isListened: const Value(true),
          listenedAt: Value(at(9)),
          lastPositionMs: const Value(290000),
          createdAt: Value(at(10)),
          updatedAt: Value(at(11)),
        ),
      );
  final two = await db
      .into(db.chapters)
      .insert(
        ChaptersCompanion(
          bookId: Value(book),
          key: const Value('two'),
          title: const Value('Chapter Two'),
          sourceIndex: const Value(1),
          lastPositionMs: const Value(12345),
          createdAt: Value(at(10)),
          updatedAt: Value(at(20)),
        ),
      );
  await db
      .into(db.chapters)
      .insert(
        ChaptersCompanion(
          bookId: Value(book),
          key: const Value('gone'),
          title: const Value('A Chapter the Source Dropped'),
          sourceIndex: const Value(2),
          removedFromSource: const Value(true),
          createdAt: Value(at(10)),
          updatedAt: Value(at(12)),
        ),
      );

  for (final (chapter, ordinal, file, startMs, endMs) in [
    (one, 0, part1, 0, 290000),
    (two, 0, part1, 290000, null),
    (two, 1, part2, 0, null),
  ]) {
    await db
        .into(db.chapterSegments)
        .insert(
          ChapterSegmentsCompanion(
            chapterId: Value(chapter),
            ordinal: Value(ordinal),
            mediaFileId: Value(file),
            startMs: Value(startMs),
            endMs: Value(endMs),
          ),
        );
  }

  await db
      .into(db.playbackStates)
      .insert(
        PlaybackStatesCompanion(
          bookId: Value(book),
          chapterId: Value(two),
          chapterPositionMs: const Value(12345),
          globalPositionMs: const Value(302345),
          updatedAt: Value(at(20)),
          deviceId: const Value('this-pc'),
        ),
      );

  for (final (chapter, start, end, device) in [
    (one, 13, 15, 'this-pc'),
    (null, 16, 17, 'phone'),
  ]) {
    await db
        .into(db.listeningSessions)
        .insert(
          ListeningSessionsCompanion(
            bookId: Value(book),
            chapterId: Value(chapter),
            startedAt: Value(at(start)),
            endedAt: Value(at(end)),
            startGlobalMs: const Value(1000),
            endGlobalMs: const Value(121000),
            speed: const Value(1.25),
            deviceId: Value(device),
          ),
        );
  }

  await db
      .into(db.bookmarks)
      .insert(
        BookmarksCompanion(
          bookId: Value(book),
          chapterId: Value(two),
          positionMs: const Value(1000),
          title: const Value('A bookmark'),
          note: const Value('A note.'),
          createdAt: Value(at(18)),
        ),
      );
  await db
      .into(db.bookmarks)
      .insert(
        BookmarksCompanion(
          bookId: Value(book),
          chapterId: Value(one),
          positionMs: const Value(5),
          createdAt: Value(at(19)),
        ),
      );

  await db
      .into(db.bookCategories)
      .insert(
        BookCategoriesCompanion(bookId: Value(book), categoryId: Value(nextUp)),
      );

  final started = await addStartedBook(db, updatedAt: at(30));
  await db
      .into(db.playbackStates)
      .insert(
        PlaybackStatesCompanion(
          bookId: Value(started.book),
          chapterId: Value(started.chapter),
          chapterPositionMs: const Value(5000),
          globalPositionMs: const Value(5000),
          updatedAt: Value(at(30)),
          deviceId: const Value('this-pc'),
        ),
      );
  await (db.update(db.chapters)..where((c) => c.id.equals(started.chapter)))
      .write(const ChaptersCompanion(lastPositionMs: Value(5000)));

  // A book to read, part way through a chapter (ADR-0019).
  final novel = await db
      .into(db.books)
      .insert(
        BooksCompanion(
          sourceId: const Value(localSourceId),
          key: const Value('a-novel.epub'),
          title: const Value('A Novel'),
          kind: const Value(SourceKind.text),
          inLibrary: const Value(true),
          dateAdded: Value(at(31)),
          createdAt: Value(at(31)),
          updatedAt: Value(at(31)),
        ),
      );
  final novelChapter = await db
      .into(db.chapters)
      .insert(
        ChaptersCompanion(
          bookId: Value(novel),
          key: const Value('chapter-1.xhtml'),
          title: const Value('Chapter 1'),
          sourceIndex: const Value(0),
          createdAt: Value(at(31)),
          updatedAt: Value(at(31)),
        ),
      );
  await db
      .into(db.readingStates)
      .insert(
        ReadingStatesCompanion(
          bookId: Value(novel),
          chapterId: Value(novelChapter),
          progress: const Value(0.375),
          updatedAt: Value(at(32)),
        ),
      );

  final browsed = await db
      .into(db.books)
      .insert(
        BooksCompanion(
          sourceId: const Value(browsedSourceId),
          key: const Value('browsed'),
          title: const Value('Browsed Past'),
          createdAt: Value(at(40)),
          updatedAt: Value(at(40)),
        ),
      );
  await db
      .into(db.chapters)
      .insert(
        ChaptersCompanion(
          bookId: Value(browsed),
          key: const Value('c1'),
          title: const Value('Chapter 1'),
          sourceIndex: const Value(0),
          createdAt: Value(at(40)),
          updatedAt: Value(at(40)),
        ),
      );
}

/// [startedBook], a single file with one chapter, not in the library, without progress. The local
/// source must exist.
Future<({int book, int chapter})> addStartedBook(
  KikuyomiDatabase db, {
  required DateTime updatedAt,
  bool inLibrary = false,
}) async {
  final book = await db
      .into(db.books)
      .insert(
        BooksCompanion(
          sourceId: const Value(localSourceId),
          key: const Value(startedBook),
          title: const Value('Started'),
          inLibrary: Value(inLibrary),
          createdAt: Value(updatedAt),
          updatedAt: Value(updatedAt),
        ),
      );
  final file = await db
      .into(db.mediaFiles)
      .insert(
        MediaFilesCompanion(
          bookId: Value(book),
          fileKey: const Value(startedBook),
          durationMs: const Value(60000),
          localPath: const Value(startedBook),
        ),
      );
  final chapter = await db
      .into(db.chapters)
      .insert(
        ChaptersCompanion(
          bookId: Value(book),
          key: const Value('whole'),
          title: const Value('Started'),
          sourceIndex: const Value(0),
          createdAt: Value(updatedAt),
          updatedAt: Value(updatedAt),
        ),
      );
  await db
      .into(db.chapterSegments)
      .insert(
        ChapterSegmentsCompanion(
          chapterId: Value(chapter),
          ordinal: const Value(0),
          mediaFileId: Value(file),
        ),
      );
  return (book: book, chapter: chapter);
}

Future<BookRow> bookByKey(KikuyomiDatabase db, String key) =>
    (db.select(db.books)..where((b) => b.key.equals(key))).getSingle();

Future<ChapterRow> chapterByKey(KikuyomiDatabase db, int bookId, String key) =>
    (db.select(
      db.chapters,
    )..where((c) => c.bookId.equals(bookId) & c.key.equals(key))).getSingle();

/// Every row of every table in [db], with database ids replaced by the identities they stand for, so
/// that two databases holding the same library dump identically however their rows were numbered.
///
/// Every other column is included, as the generated `toJson` lists them. A column added to the
/// schema therefore shows up here, and fails a round trip until backups carry it.
Future<Map<String, List<Map<String, Object?>>>> dumpLibrary(
  KikuyomiDatabase db,
) async {
  final serializer = _Plain();
  Map<String, Object?> json(DataClass row, List<String> ids) =>
      row.toJson(serializer: serializer)
        ..removeWhere((column, _) => ids.contains(column));
  List<Map<String, Object?>> sorted(Iterable<Map<String, Object?>> rows) =>
      rows.toList()..sort((a, b) => jsonEncode(a).compareTo(jsonEncode(b)));

  final books = await db.select(db.books).get();
  final bookOf = {for (final b in books) b.id: '${b.sourceId}/${b.key}'};
  final chapters = await db.select(db.chapters).get();
  final chapterOf = {
    for (final c in chapters) c.id: '${bookOf[c.bookId]}#${c.key}',
  };
  final files = await db.select(db.mediaFiles).get();
  final fileOf = {
    for (final f in files) f.id: '${bookOf[f.bookId]}@${f.fileKey}',
  };
  final people = await db.select(db.people).get();
  final personOf = {for (final p in people) p.id: p.name};
  final categories = await db.select(db.categories).get();
  final categoryOf = {for (final c in categories) c.id: c.name};

  return {
    'sources': sorted([
      for (final row in await db.select(db.sources).get()) json(row, []),
    ]),
    'books': sorted([
      for (final row in books) json(row, ['id']),
    ]),
    'people': sorted([
      for (final row in people) json(row, ['id']),
    ]),
    'bookPeople': sorted([
      for (final row in await db.select(db.bookPeople).get())
        {
          ...json(row, ['bookId', 'personId']),
          'book': bookOf[row.bookId],
          'person': personOf[row.personId],
        },
    ]),
    'chapters': sorted([
      for (final row in chapters)
        {
          ...json(row, ['id', 'bookId']),
          'book': bookOf[row.bookId],
        },
    ]),
    'mediaFiles': sorted([
      for (final row in files)
        {
          ...json(row, ['id', 'bookId']),
          'book': bookOf[row.bookId],
        },
    ]),
    'chapterSegments': sorted([
      for (final row in await db.select(db.chapterSegments).get())
        {
          ...json(row, ['chapterId', 'mediaFileId']),
          'chapter': chapterOf[row.chapterId],
          'file': fileOf[row.mediaFileId],
        },
    ]),
    'playbackStates': sorted([
      for (final row in await db.select(db.playbackStates).get())
        {
          ...json(row, ['bookId', 'chapterId']),
          'book': bookOf[row.bookId],
          'chapter': chapterOf[row.chapterId],
        },
    ]),
    'readingStates': sorted([
      for (final row in await db.select(db.readingStates).get())
        {
          ...json(row, ['bookId', 'chapterId']),
          'book': bookOf[row.bookId],
          'chapter': chapterOf[row.chapterId],
        },
    ]),
    'listeningSessions': sorted([
      for (final row in await db.select(db.listeningSessions).get())
        {
          ...json(row, ['id', 'bookId', 'chapterId']),
          'book': bookOf[row.bookId],
          'chapter': chapterOf[row.chapterId],
        },
    ]),
    'bookmarks': sorted([
      for (final row in await db.select(db.bookmarks).get())
        {
          ...json(row, ['id', 'bookId', 'chapterId']),
          'book': bookOf[row.bookId],
          'chapter': chapterOf[row.chapterId],
        },
    ]),
    'categories': sorted([
      for (final row in categories) json(row, ['id']),
    ]),
    'bookCategories': sorted([
      for (final row in await db.select(db.bookCategories).get())
        {
          ...json(row, ['bookId', 'categoryId']),
          'book': bookOf[row.bookId],
          'category': categoryOf[row.categoryId],
        },
    ]),
  };
}

/// Turns column values into plain, comparable JSON: times into instants, whatever their time zone,
/// and the typed columns into lists.
final class _Plain extends ValueSerializer {
  @override
  dynamic toJson<T>(T value) => switch (value) {
    final DateTime time => time.millisecondsSinceEpoch,
    final Set<BookField> fields => [for (final f in fields) f.name]..sort(),
    final List<TimelineMarker> markers => [
      for (final m in markers) [m.title, m.startMs],
    ],
    _ => value,
  };

  @override
  T fromJson<T>(dynamic json) =>
      throw UnsupportedError('a dump is only ever written');
}
