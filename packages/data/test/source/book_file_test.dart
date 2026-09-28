// A book downloaded whole from its source (ADR-0021): the file it was written to, and the chapters
// that were inside it.

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:kikuyomi_data/kikuyomi_data.dart';
import 'package:kikuyomi_source_api/kikuyomi_source_api.dart' as api;
import 'package:kikuyomi_test_support/kikuyomi_test_support.dart';
import 'package:test/test.dart';

void main() {
  late KikuyomiDatabase db;
  late FakeClock clock;

  setUp(() async {
    db = KikuyomiDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    clock = FakeClock(DateTime.utc(2026, 9, 28, 12));
    await db
        .into(db.sources)
        .insert(
          const SourcesCompanion(
            id: Value(9),
            key: Value('novels'),
            name: Value('Novels'),
            lang: Value('en'),
          ),
        );
  });

  Future<int> addBook() async {
    final saved = await saveSourceBook(
      db,
      sourceId: 9,
      details: api.BookDetails(key: 'leviathan', title: 'Leviathan'),
      chapters: const [],
      clock: clock,
      addToLibrary: true,
      kind: api.SourceKind.text,
    );
    return saved.bookId;
  }

  const spine = [
    LocalEpubChapter(key: 'ch1.xhtml', title: 'Of Sense', wordCount: 2500),
    LocalEpubChapter(key: 'ch2.xhtml', title: 'Of Imagination', wordCount: 900),
  ];

  test('records the file and the chapters that were inside it', () async {
    final bookId = await addBook();

    await saveBookFile(
      db,
      bookId: bookId,
      fileName: '$bookId.epub',
      chapters: spine,
      clock: clock,
    );

    final book = await (db.select(
      db.books,
    )..where((b) => b.id.equals(bookId))).getSingle();
    expect(book.filePath, '$bookId.epub');
    expect(book.kind, api.SourceKind.text);

    final chapters =
        await (db.select(db.chapters)
              ..where((c) => c.bookId.equals(bookId))
              ..orderBy([(c) => OrderingTerm.asc(c.sourceIndex)]))
            .get();
    expect(
      [for (final c in chapters) (c.key, c.title, c.wordCount)],
      [('ch1.xhtml', 'Of Sense', 2500), ('ch2.xhtml', 'Of Imagination', 900)],
    );
  });

  test('downloading the book again keeps the place the reader is at', () async {
    // A file that went missing, or a new edition. The chapter rows are what a reading position
    // points at, so they are written by key rather than replaced.
    final bookId = await addBook();
    await saveBookFile(
      db,
      bookId: bookId,
      fileName: '$bookId.epub',
      chapters: spine,
      clock: clock,
    );
    final first = await (db.select(
      db.chapters,
    )..where((c) => c.key.equals('ch1.xhtml'))).getSingle();
    await saveReadingPosition(
      db,
      bookId: bookId,
      chapterId: first.id,
      progress: 0.5,
      clock: clock,
    );

    await saveBookFile(
      db,
      bookId: bookId,
      fileName: '$bookId.epub',
      chapters: [
        const LocalEpubChapter(
          key: 'ch1.xhtml',
          title: 'Of Sense (revised)',
          wordCount: 2600,
        ),
        spine[1],
      ],
      clock: clock,
    );

    final place = await readReadingPosition(db, bookId);
    expect(place!.chapterId, first.id, reason: 'the same chapter row');
    expect(place.progress, 0.5);
    final again = await (db.select(
      db.chapters,
    )..where((c) => c.id.equals(first.id))).getSingle();
    expect(again.title, 'Of Sense (revised)');
    expect(again.wordCount, 2600);
  });

  test('a book with no file of its own says so by having none', () async {
    // Every other book: an audiobook is made of media files, and a text source that serves chapters
    // has no file at all.
    final bookId = await addBook();

    final book = await (db.select(
      db.books,
    )..where((b) => b.id.equals(bookId))).getSingle();
    expect(book.filePath, null);
  });
}
