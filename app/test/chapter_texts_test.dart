// Fetching what a chapter of a book to read says (ADR-0019): out of a local EPUB on this device, or
// from the source a book came from.

import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikuyomi/src/reading/chapter_texts.dart';
import 'package:kikuyomi_data/kikuyomi_data.dart';
import 'package:kikuyomi_source_api/kikuyomi_source_api.dart' hide BookDetails;
import 'package:kikuyomi_source_api/kikuyomi_source_api.dart'
    as api
    show BookDetails;
import 'package:kikuyomi_test_support/kikuyomi_test_support.dart';

List<int> epubBytes() {
  final archive = Archive();
  void add(String path, String text) {
    final bytes = utf8.encode(text);
    archive.addFile(ArchiveFile(path, bytes.length, bytes));
  }

  add(
    'META-INF/container.xml',
    '<container xmlns="urn:oasis:names:tc:opendocument:xmlns:container"><rootfiles>'
        '<rootfile full-path="content.opf" media-type="application/oebps-package+xml"/>'
        '</rootfiles></container>',
  );
  add(
    'content.opf',
    '<package xmlns="http://www.idpf.org/2007/opf" version="3.0">'
        '<metadata xmlns:dc="http://purl.org/dc/elements/1.1/"><dc:title>A Novel</dc:title></metadata>'
        '<manifest><item id="c1" href="one.xhtml" media-type="application/xhtml+xml"/></manifest>'
        '<spine><itemref idref="c1"/></spine></package>',
  );
  add('one.xhtml', '<html><body><p>Once upon a time.</p></body></html>');
  return ZipEncoder().encode(archive);
}

void main() {
  late KikuyomiDatabase db;
  late Directory folder;
  final clock = FakeClock(DateTime.utc(2026, 9, 28));

  setUp(() async {
    db = KikuyomiDatabase(NativeDatabase.memory());
    folder = await Directory.systemTemp.createTemp('kikuyomi-texts-');
  });

  tearDown(() async {
    await db.close();
    await folder.delete(recursive: true);
  });

  Future<int> chapterOf(int bookId) async => (await (db.select(
    db.chapters,
  )..where((c) => c.bookId.equals(bookId))).getSingle()).id;

  test('a local book is read out of its EPUB', () async {
    final file = File('${folder.path}/novel.epub');
    await file.writeAsBytes(epubBytes());
    final bookId = await importLocalEpub(
      db,
      LocalEpubImport(
        path: file.path,
        title: 'A Novel',
        chapters: const [LocalEpubChapter(key: 'one.xhtml', title: 'One')],
      ),
      clock: clock,
    );

    final texts = ChapterTexts(
      db,
      mediaRoot: folder,
      openSource: (_) => throw StateError('a local book has no source'),
    );
    final text = await texts.load(bookId, await chapterOf(bookId));
    expect(text.content.blocks, const [
      ParagraphBlock([TextRun('Once upon a time.')]),
    ]);
  });

  test('a local book whose file has gone says so, and where it was', () async {
    final bookId = await importLocalEpub(
      db,
      LocalEpubImport(
        path: '${folder.path}/gone.epub',
        title: 'Gone',
        chapters: const [LocalEpubChapter(key: 'one.xhtml', title: 'One')],
      ),
      clock: clock,
    );
    final texts = ChapterTexts(
      db,
      mediaRoot: folder,
      openSource: (_) => throw StateError('unused'),
    );
    await expectLater(
      texts.load(bookId, await chapterOf(bookId)),
      throwsA(
        isA<ChapterTextException>().having(
          (e) => e.message,
          'message',
          contains('gone.epub'),
        ),
      ),
    );
  });

  test('a book from a source is asked of the source', () async {
    await db
        .into(db.sources)
        .insert(
          const SourcesCompanion(
            id: Value(7),
            key: Value('novels'),
            name: Value('Novels'),
            lang: Value('en'),
          ),
        );
    final saved = await saveSourceBook(
      db,
      sourceId: 7,
      details: api.BookDetails(key: 'a-novel', title: 'A Novel'),
      chapters: [const ChapterInfo(key: 'ch-1', title: 'One')],
      clock: clock,
      addToLibrary: true,
      kind: SourceKind.text,
    );
    final source = FakeContentSource(
      kind: SourceKind.text,
      texts: {
        'ch-1': const ChapterContent([
          ParagraphBlock([TextRun('From the web.')]),
        ]),
      },
    );
    final texts = ChapterTexts(
      db,
      mediaRoot: folder,
      openSource: (_) async => source,
    );

    final text = await texts.load(saved.bookId, await chapterOf(saved.bookId));
    expect(text.content.blocks, const [
      ParagraphBlock([TextRun('From the web.')]),
    ]);
    expect(text.pictures, isEmpty);
  });
}
