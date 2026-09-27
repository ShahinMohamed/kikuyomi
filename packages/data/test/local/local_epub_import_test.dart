// Adding a local EPUB to the library as a book to read (ADR-0019).

import 'package:drift/drift.dart' show OrderingTerm;
import 'package:drift/native.dart';
import 'package:kikuyomi_data/kikuyomi_data.dart';
import 'package:kikuyomi_source_api/kikuyomi_source_api.dart' show SourceKind;
import 'package:kikuyomi_test_support/kikuyomi_test_support.dart';
import 'package:test/test.dart';

const novel = LocalEpubImport(
  path: r'C:\Books\A Novel.epub',
  title: 'A Novel',
  authors: ['An Author'],
  language: 'en',
  description: 'A description.',
  publisher: 'A Publisher',
  chapters: [
    LocalEpubChapter(key: 'OEBPS/one.xhtml', title: 'One'),
    LocalEpubChapter(key: 'OEBPS/two.xhtml', title: 'Two'),
  ],
);

void main() {
  late KikuyomiDatabase db;
  late FakeClock clock;

  setUp(() {
    db = KikuyomiDatabase(NativeDatabase.memory());
    clock = FakeClock(DateTime.utc(2026, 9, 28, 12));
  });

  tearDown(() => db.close());

  test(
    'adds a book to read, on the reading shelf and not the listening one',
    () async {
      final id = await importLocalEpub(db, novel, clock: clock);

      final book = await db.select(db.books).getSingle();
      expect(book.id, id);
      expect(book.kind, SourceKind.text);
      expect(book.sourceId, localSourceId);
      expect(book.key, r'C:\Books\A Novel.epub');
      expect(book.language, 'en');
      expect(book.description, 'A description.');
      expect(book.publisher, 'A Publisher');
      expect(book.totalDurationMs, isNull);

      expect(await watchShelf(db, SourceKind.text).first, hasLength(1));
      expect(await watchShelf(db, SourceKind.audio).first, isEmpty);
    },
  );

  test(
    'makes each document a chapter, in reading order, with nothing to play',
    () async {
      await importLocalEpub(db, novel, clock: clock);

      final chapters = await (db.select(
        db.chapters,
      )..orderBy([(c) => OrderingTerm.asc(c.sourceIndex)])).get();
      expect(
        [for (final c in chapters) (c.key, c.title, c.sourceIndex)],
        [('OEBPS/one.xhtml', 'One', 0), ('OEBPS/two.xhtml', 'Two', 1)],
      );
      expect(await db.select(db.mediaFiles).get(), isEmpty);
      expect(await db.select(db.chapterSegments).get(), isEmpty);
    },
  );

  test('credits the authors', () async {
    final id = await importLocalEpub(db, novel, clock: clock);

    final overview = await watchBookOverview(db, id).first;
    expect(overview!.authors, ['An Author']);
  });

  test('importing the same file again finds the same book', () async {
    final first = await importLocalEpub(db, novel, clock: clock);
    final second = await importLocalEpub(db, novel, clock: clock);

    expect(second, first);
    expect(await db.select(db.chapters).get(), hasLength(2));
  });

  test('refuses a book with no chapters', () {
    expect(
      () => importLocalEpub(
        db,
        const LocalEpubImport(path: 'empty.epub', title: 'Empty', chapters: []),
        clock: clock,
      ),
      throwsArgumentError,
    );
  });
}
