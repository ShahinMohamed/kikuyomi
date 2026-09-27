import 'dart:convert';
import 'dart:io';

import 'package:kikuyomi_sources_builtin/kikuyomi_sources_builtin.dart';
import 'package:test/test.dart';

import 'support/image_bytes.dart';
import 'support/mp3_bytes.dart';
import 'support/vorbis_bytes.dart';

/// An MP3 carrying whichever tags are given.
List<int> mp3({
  String? title,
  String? album,
  String? artist,
  String? albumArtist,
  String? composer,
  String? track,
  int frames = 20,
}) => [
  ...id3(3, [
    if (title != null) ...frame3('TIT2', latin1.encode(title)),
    if (album != null) ...frame3('TALB', latin1.encode(album)),
    if (artist != null) ...frame3('TPE1', latin1.encode(artist)),
    if (albumArtist != null) ...frame3('TPE2', latin1.encode(albumArtist)),
    if (composer != null) ...frame3('TCOM', latin1.encode(composer)),
    if (track != null) ...frame3('TRCK', latin1.encode(track)),
  ]),
  ...audio(frames),
];

/// A FLAC file of [seconds] at 44.1 kHz carrying [comments].
List<int> flacFile(List<String> comments, {int seconds = 10}) => flac(
  info: streamInfo(totalSamples: 44100 * seconds),
  blocks: [(4, vorbisComments(comments))],
);

/// An Ogg Opus file of [seconds] carrying [comments].
List<int> opusFile(List<String> comments, {int seconds = 10}) => oggFile(
  identification: opusHead(),
  comments: opusTags(comments),
  endGranule: 312 + 48000 * seconds,
);

/// An Ogg Vorbis file of [seconds] carrying [comments].
List<int> vorbisFile(List<String> comments, {int seconds = 10}) => oggFile(
  identification: vorbisId(),
  comments: vorbisCommentHeader(comments),
  setup: vorbisSetup(),
  endGranule: 44100 * seconds,
);

void main() {
  group('the image a folder takes as its cover', () {
    // The three names that were here found cover.jpg, folder.jpg and front.jpg. Real folders also
    // hold what Windows Media Player and the common rippers leave behind, and a folder whose only
    // image is named after the book cannot be matched by name at all.
    Future<Directory> folderWith(
      Directory temp,
      List<String> names, {
      String audio = 'one.mp3',
    }) async {
      final folder = await Directory(
        '${temp.path}${Platform.pathSeparator}book',
      ).create(recursive: true);
      await File('${folder.path}${Platform.pathSeparator}$audio')
          .writeAsBytes(const [0]);
      for (final name in names) {
        await File('${folder.path}${Platform.pathSeparator}$name')
            .writeAsBytes(const [0]);
      }
      return folder;
    }

    late Directory temp;

    setUp(() async {
      temp = await Directory.systemTemp.createTemp('kikuyomi_covers');
    });

    tearDown(() async {
      if (await temp.exists()) await temp.delete(recursive: true);
    });

    for (final name in const [
      'cover.jpg',
      'folder.png',
      'front.jpeg',
      'artwork.jpg',
      'AlbumArt.jpg',
      'albumartsmall.jpg',
      'poster.png',
      'thumb.jpg',
    ]) {
      test('takes $name', () async {
        final folder = await folderWith(temp, [name]);

        final found = await findFolderCoverImage(folder);

        expect(found?.path, endsWith(name));
      });
    }

    test("takes a folder's only image whatever it is called", () async {
      // A cover saved under the book's own title is common and cannot be matched by name.
      final folder = await folderWith(temp, ['The Hobbit.jpg']);

      final found = await findFolderCoverImage(folder);

      expect(found?.path, endsWith('The Hobbit.jpg'));
    });

    test('prefers a known name over the others', () async {
      final folder = await folderWith(temp, [
        'scan-of-the-back.jpg',
        'cover.jpg',
      ]);

      final found = await findFolderCoverImage(folder);

      expect(found?.path, endsWith('cover.jpg'));
    });

    test('takes none when several are unnamed', () async {
      // Guessing between them would be a coin toss, and the picture embedded in the audio is a
      // better answer than that.
      final folder = await folderWith(temp, ['page-1.jpg', 'page-2.jpg']);

      expect(await findFolderCoverImage(folder), isNull);
    });
  });

  late Directory root;
  late Directory folder;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('kikuyomi_folder_');
    folder = await Directory('${root.path}/The Folder Name').create();
  });

  tearDown(() => root.delete(recursive: true));

  Future<void> put(String name, List<int> bytes) =>
      File('${folder.path}/$name').writeAsBytes(bytes);

  Future<FolderBook> read() async => (await readFolderBook(folder))!;

  List<String> names(FolderBook book) => [
    for (final track in book.tracks) track.fileName,
  ];

  List<String> titles(FolderBook book) => [
    for (final track in book.tracks) track.title,
  ];

  group('order', () {
    test('follows the track numbers when every file has its own', () async {
      await put('z.mp3', mp3(title: 'Opening', track: '1'));
      await put('a.mp3', mp3(title: 'Middle', track: '2/3'));
      await put('m.mp3', mp3(title: 'End', track: '3'));

      final book = await read();
      expect(names(book), ['z.mp3', 'a.mp3', 'm.mp3']);
      expect(titles(book), ['Opening', 'Middle', 'End']);
    });

    test('follows the file names, naturally, when numbers repeat', () async {
      await put('Chapter 10.mp3', mp3(track: '1'));
      await put('Chapter 2.mp3', mp3(track: '1'));
      await put('Chapter 1.mp3', mp3(track: '1'));

      expect(names(await read()), [
        'Chapter 1.mp3',
        'Chapter 2.mp3',
        'Chapter 10.mp3',
      ]);
    });

    test('follows the file names when some files have no number', () async {
      await put('02 Two.mp3', mp3(track: '1'));
      await put('01 One.mp3', mp3());

      expect(names(await read()), ['01 One.mp3', '02 Two.mp3']);
    });
  });

  group('names', () {
    test('the book from its album tag, with author and narrator', () async {
      await put(
        '1.mp3',
        mp3(album: 'A Book', albumArtist: 'An Author', composer: 'A Narrator'),
      );
      await put(
        '2.mp3',
        mp3(album: 'A Book', albumArtist: 'An Author', composer: 'A Narrator'),
      );

      final book = await read();
      expect(book.title, 'A Book');
      expect(book.authors, ['An Author']);
      expect(book.narrators, ['A Narrator']);
    });

    test('the author from the artist when no album artist is set', () async {
      await put('1.mp3', mp3(artist: 'An Author'));
      expect((await read()).authors, ['An Author']);
    });

    test('the book from its folder, and chapters from file names', () async {
      await put('Part One.mp3', mp3());
      await put('Part Two.mp3', mp3());

      final book = await read();
      expect(book.title, 'The Folder Name');
      expect(book.authors, isEmpty);
      expect(titles(book), ['Part One', 'Part Two']);
    });

    test('a title every file shares does not name a chapter', () async {
      await put('Part One.mp3', mp3(title: 'A Book'));
      await put('Part Two.mp3', mp3(title: 'A Book'));
      expect(titles(await read()), ['Part One', 'Part Two']);
    });
  });

  test('carries each track\'s duration, and whether it is estimated', () async {
    await put('1.mp3', [...xingFrame(1000), ...audio(20)]);
    await put('2.mp3', mp3(frames: 100));

    final tracks = (await read()).tracks;
    expect(tracks[0].durationMs, counted(1000));
    expect(tracks[0].durationIsEstimate, isFalse);
    expect(tracks[1].durationIsEstimate, isTrue);
    expect(tracks[1].format, 'mp3');
  });

  group('cover', () {
    test('is the image named cover, before folder, front or any other, in any case', () async {
      await put('01.mp3', mp3());
      await put('back.jpg', jpegBytes());
      await put('Front.png', pngBytes());
      await put('FOLDER.JPG', jpegBytes());
      await put('Cover.jpeg', jpegBytes());
      expect((await read()).coverFileName, 'Cover.jpeg');
    });

    test('is the image named folder, before front', () async {
      await put('01.mp3', mp3());
      await put('front.jpg', jpegBytes());
      await put('Folder.png', pngBytes());
      await put('back.jpg', jpegBytes());
      expect((await read()).coverFileName, 'Folder.png');
    });

    test(
      'is the image named front when none is named cover or folder',
      () async {
        await put('01.mp3', mp3());
        await put('Front.JPG', jpegBytes());
        await put('back.png', pngBytes());
        expect((await read()).coverFileName, 'Front.JPG');
      },
    );

    test('is the folder\'s only image, whatever its name', () async {
      await put('01.mp3', mp3());
      await put('artwork.png', pngBytes());
      await put('cover.txt', utf8.encode('Not an image.'));
      expect((await read()).coverFileName, 'artwork.png');
    });

    test(
      'is unknown among several images with none named as a cover',
      () async {
        await put('01.mp3', mp3());
        await put('back.jpg', jpegBytes());
        await put('disc.png', pngBytes());
        expect((await read()).coverFileName, isNull);
      },
    );

    test('is unknown when the only image is hidden', () async {
      await put('01.mp3', mp3());
      await put('._cover.jpg', jpegBytes());
      expect((await read()).coverFileName, isNull);
    });
  });

  group('FLAC and Ogg tracks', () {
    test('are read with their durations and tags', () async {
      await put(
        '01.flac',
        flacFile([
          'TITLE=Opening',
          'ALBUM=A Book',
          'ALBUMARTIST=An Author',
          'COMPOSER=A Narrator',
          'TRACKNUMBER=1',
        ], seconds: 30),
      );
      await put(
        '02.opus',
        opusFile([
          'TITLE=Middle',
          'ALBUM=A Book',
          'TRACKNUMBER=2',
        ], seconds: 40),
      );
      await put(
        '03.ogg',
        vorbisFile(['TITLE=End', 'ALBUM=A Book', 'TRACKNUMBER=3'], seconds: 50),
      );

      final book = await read();
      expect(book.title, 'A Book');
      expect(book.authors, ['An Author']);
      expect(book.narrators, ['A Narrator']);
      expect(titles(book), ['Opening', 'Middle', 'End']);
      expect(
        [for (final track in book.tracks) track.durationMs],
        [30000, 40000, 50000],
      );
      expect(
        [for (final track in book.tracks) track.format],
        ['flac', 'opus', 'ogg'],
      );
      expect(book.tracks.every((track) => !track.durationIsEstimate), isTrue);
    });

    test('that are damaged are reported as unreadable', () async {
      await put('01.flac', flacFile(const []));
      await put('02.ogg', opusFile(const []).sublist(0, 60));
      final book = await read();
      expect(names(book), ['01.flac']);
      expect(book.unreadable, ['02.ogg']);
    });
  });

  group('formats the device cannot play', () {
    bool noOgg(LocalAudioFormat format) =>
        format != LocalAudioFormat.oggVorbis &&
        format != LocalAudioFormat.oggOpus;

    test(
      'are left out, named with their formats, and the book made of the rest',
      () async {
        // An archive's folder may hold each chapter twice, in two formats. Counted together, the
        // repeated numbers and titles would be distrusted; counted without the files left out, they
        // order and name the book.
        await put('b.mp3', mp3(title: 'One', album: 'A Book', track: '1'));
        await put('a.mp3', mp3(title: 'Two', album: 'A Book', track: '2'));
        await put(
          'b.ogg',
          vorbisFile(['TITLE=One', 'ALBUM=Other', 'TRACKNUMBER=1']),
        );
        await put(
          'a.opus',
          opusFile(['TITLE=Two', 'ALBUM=Other', 'TRACKNUMBER=2']),
        );
        await put(
          'c.flac',
          flacFile(['TITLE=Three', 'ALBUM=A Book', 'TRACKNUMBER=3']),
        );

        final book = (await readFolderBook(folder, canPlay: noOgg))!;
        expect(names(book), ['b.mp3', 'a.mp3', 'c.flac']);
        expect(titles(book), ['One', 'Two', 'Three']);
        expect(book.title, 'A Book');
        expect(book.unplayable, const [
          UnplayableFile(fileName: 'a.opus', format: LocalAudioFormat.oggOpus),
          UnplayableFile(fileName: 'b.ogg', format: LocalAudioFormat.oggVorbis),
        ]);
        expect(book.unreadable, isEmpty);
      },
    );

    test('alone give a book with no tracks, naming them all', () async {
      await put('01.ogg', vorbisFile(const []));
      await put('02.ogg', opusFile(const []));
      await put('03.ogg', List.filled(4096, 0));

      final book = (await readFolderBook(folder, canPlay: noOgg))!;
      expect(book.tracks, isEmpty);
      expect(book.unplayable, const [
        UnplayableFile(fileName: '01.ogg', format: LocalAudioFormat.oggVorbis),
        UnplayableFile(fileName: '02.ogg', format: LocalAudioFormat.oggOpus),
      ]);
      expect(book.unreadable, ['03.ogg']);
    });

    test('are all taken when nothing is said about playing them', () async {
      await put('01.ogg', vorbisFile(const []));
      expect(names(await read()), ['01.ogg']);
    });
  });

  group('other files', () {
    test('are ignored, and unreadable audio is reported', () async {
      await put('01.mp3', mp3());
      await put('cover.jpg', [0xFF, 0xD8, 0xFF, 0xE0]);
      await put('notes.txt', utf8.encode('Read by a volunteer.'));
      await put('._01.mp3', List.filled(4096, 0));
      await put('broken.mp3', List.filled(4096, 0));

      final book = await read();
      expect(names(book), ['01.mp3']);
      expect(book.unreadable, ['broken.mp3']);
    });

    test('alone do not make a book', () async {
      await put('cover.jpg', [0xFF, 0xD8, 0xFF, 0xE0]);
      expect(await readFolderBook(folder), isNull);
    });

    test('in subfolders are not read', () async {
      await Directory('${folder.path}/extras').create();
      await File('${folder.path}/extras/bonus.mp3').writeAsBytes(mp3());
      expect(await readFolderBook(folder), isNull);
    });
  });
}
