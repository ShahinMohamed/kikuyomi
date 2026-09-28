/// Audio files and folders read as books for the library (§3.10), with those this device cannot
/// play refused (§7.3), and the words that tell the listener what was left out and why.
///
/// Plain Dart with no plugin, widget or database in it, so it can be tested on its own. The device's
/// playable formats are handed in, as `EngineFormats` gives them.
library;

import 'dart:io';
import 'dart:isolate';

import 'package:kikuyomi_data/kikuyomi_data.dart'
    show CoverImage, LocalEpubChapter, LocalEpubImport;
import 'package:kikuyomi_domain/kikuyomi_domain.dart';
import 'package:kikuyomi_sources_builtin/kikuyomi_sources_builtin.dart';

/// What reading one audio file found: enough to add it to the library as a book of its own.
typedef ProbedBook = ({
  int durationMs,
  bool durationIsEstimate,
  int sizeBytes,
  String? bookTitle,
  String? author,
  String? narrator,
  List<TimelineMarker> markers,
  CoverImage? cover,
});

/// The domain's name for a format the local readers found.
AudioFormat audioFormatOf(LocalAudioFormat format) => switch (format) {
  LocalAudioFormat.mp3 => AudioFormat.mp3,
  LocalAudioFormat.mp4 => AudioFormat.mp4,
  LocalAudioFormat.flac => AudioFormat.flac,
  LocalAudioFormat.oggVorbis => AudioFormat.oggVorbis,
  LocalAudioFormat.oggOpus => AudioFormat.oggOpus,
};

/// Reads [file] as a book of its own, cover included.
///
/// Throws a [FormatException] when the file is not audio of the format its extension names, or is
/// damaged; and an [UnplayableFormatException] naming its format when it is audio [playable] says
/// this device cannot play, so that a book that would not play never enters the library.
Future<ProbedBook> probeBookFile(File file, PlayableFormats playable) async {
  final extension = _extension(file.path);
  final source = await FileByteSource.open(file);
  try {
    final info = await readLocalAudioInfo(
      source,
      extension: extension,
      withCover: true,
    );
    if (info == null) {
      final expected = switch (extension) {
        'mp3' => 'an MP3 file',
        'flac' => 'a FLAC file',
        'ogg' || 'oga' || 'opus' => 'an Ogg Vorbis or Opus file',
        _ => 'an MP4 or M4B file',
      };
      throw FormatException('${file.path} is not $expected');
    }
    final format = audioFormatOf(info.format);
    if (!playable.canPlay(format)) throw UnplayableFormatException([format]);
    return (
      durationMs: info.durationMs,
      durationIsEstimate: info.durationIsEstimate,
      sizeBytes: source.length,
      bookTitle: info.bookTitle,
      author: info.author,
      narrator: info.composer,
      markers: [
        for (final chapter in info.chapters)
          TimelineMarker(title: chapter.title, startMs: chapter.startMs),
      ],
      cover: switch (info.cover) {
        final picture? => CoverImage(
          mimeType: picture.mimeType,
          bytes: picture.bytes,
        ),
        null => null,
      },
    );
  } finally {
    await source.close();
  }
}

/// Reads [folder] as a book of the audio files in it that [playable] says this device can play.
///
/// Files it cannot play are left out, as damaged ones are, and listed in [FolderBook.unplayable]:
/// a folder that mixes formats, as an archive's folder holding each chapter in two formats does,
/// gives the book the device can play. Returns null when the folder holds no audio this app can
/// read. Throws an [UnplayableFormatException] naming the formats when it holds audio, but none of
/// it in a format this device can play.
Future<FolderBook?> readPlayableFolder(
  Directory folder,
  PlayableFormats playable,
) async {
  final book = await readFolderBook(
    folder,
    canPlay: (format) => playable.canPlay(audioFormatOf(format)),
  );
  if (book != null && book.tracks.isEmpty) {
    throw UnplayableFormatException([
      for (final file in book.unplayable) audioFormatOf(file.format),
    ]);
  }
  return book;
}

/// An audio file left out of its book because this device cannot play its format.
typedef UnplayableTrack = ({String fileName, AudioFormat format});

/// The audio files of a folder that were left out of its book, and why.
final class LeftOut {
  const LeftOut({this.unreadable = const [], this.unplayable = const []});

  /// What [book] left out.
  factory LeftOut.of(FolderBook book) => LeftOut(
    unreadable: book.unreadable,
    unplayable: [
      for (final file in book.unplayable)
        (fileName: file.fileName, format: audioFormatOf(file.format)),
    ],
  );

  static const none = LeftOut();

  /// Files, by name, that could not be read.
  final List<String> unreadable;

  /// Files in a format this device cannot play.
  final List<UnplayableTrack> unplayable;

  bool get isEmpty => unreadable.isEmpty && unplayable.isEmpty;

  /// What was left out and why, to follow "leaving out", such as "files it could not read: 03.mp3,
  /// and Ogg Vorbis files this device cannot play: 04.ogg". Empty when nothing was.
  String describe() {
    final labels = [
      for (final format in AudioFormat.values)
        if (unplayable.any((track) => track.format == format)) format.label,
    ];
    return [
      if (unreadable.isNotEmpty)
        'files it could not read: ${unreadable.join(', ')}',
      if (unplayable.isNotEmpty)
        '${_inWords(labels)} files this device cannot play: '
            '${[for (final track in unplayable) track.fileName].join(', ')}',
    ].join(', and ');
  }
}

/// What looking in the import folder did: how many books it added, and the files and folders it
/// left there because this device cannot play them, each by name with the reason.
typedef ImportScan = ({
  int added,
  List<({String name, UnplayableFormatException reason})> unplayable,
});

/// The one message that tells the listener what looking in the import folder did.
String summarizeImportScan(ImportScan scan) => [
  switch (scan.added) {
    0 => 'No new books in the Import folder',
    1 => 'Added a book from the Import folder',
    final added => 'Added $added books from the Import folder',
  },
  for (final (:name, :reason) in scan.unplayable)
    'Could not add $name: ${reason.message}',
].join('. ');

/// Why adding a book failed, in words for the listener: an [UnplayableFormatException]'s own
/// message, which names the format, and otherwise the error as it describes itself.
String describeAddError(Object error) => switch (error) {
  UnplayableFormatException(:final message) => message,
  EpubProtectedException(:final scheme) =>
    'it is locked with $scheme. Kikuyomi does not open locked books; the app of the store it came '
        'from does',
  EpubFormatException(:final message) =>
    'it is not an EPUB this app can read: $message',
  _ => '$error',
};

/// Whether [path] names an EPUB, by its extension.
bool isEpubPath(String path) => _extension(path) == 'epub';

/// Reads the EPUB [file] into what adding it to the library needs, with the book keyed by the
/// file's own path.
///
/// On another isolate: a large EPUB takes long enough to unzip and parse to drop frames if the
/// interface waited on it. Throws [EpubProtectedException] for a book locked with DRM, and
/// [EpubFormatException] for a file that is not an EPUB this app can read.
Future<LocalEpubImport> readEpubFile(File file) => Isolate.run(() async {
  final book = EpubBook.read(await file.readAsBytes());
  // Counted here, in the isolate that already has the book open, so that a chapter list can say
  // how long each chapter takes from the moment the book is added.
  final words = book.wordCounts();
  return LocalEpubImport(
    path: file.path,
    title: book.title,
    authors: book.authors,
    language: book.language,
    description: book.description,
    publisher: book.publisher,
    chapters: [
      for (final chapter in book.chapters)
        LocalEpubChapter(
          key: chapter.path,
          title: chapter.title,
          wordCount: words[chapter.path],
        ),
    ],
    cover: switch (book.cover) {
      final picture? => CoverImage(
        mimeType: picture.mimeType,
        bytes: picture.bytes,
      ),
      null => null,
    },
  );
});

/// What is inside the EPUB [file]: its chapters, in reading order, with their words counted.
///
/// For a book downloaded whole from a source (ADR-0021), where the title, author and cover come
/// from the source and only the chapters come from the file. On another isolate, as
/// [readEpubFile] is, and refusing a book locked with DRM in the same way.
Future<List<LocalEpubChapter>> readEpubChapters(File file) =>
    Isolate.run(() async {
      final book = EpubBook.read(await file.readAsBytes());
      final words = book.wordCounts();
      return [
        for (final chapter in book.chapters)
          LocalEpubChapter(
            key: chapter.path,
            title: chapter.title,
            wordCount: words[chapter.path],
          ),
      ];
    });

/// [words] as a phrase: "A", "A and B", "A, B and C".
String _inWords(List<String> words) => words.length < 2
    ? words.join()
    : '${words.sublist(0, words.length - 1).join(', ')} and ${words.last}';

String _extension(String path) {
  final name = path.split(RegExp(r'[\\/]')).last;
  final dot = name.lastIndexOf('.');
  return dot < 0 ? '' : name.substring(dot + 1).toLowerCase();
}
