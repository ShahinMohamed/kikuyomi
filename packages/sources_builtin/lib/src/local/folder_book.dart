/// A folder of audio files read as one book.
///
/// §3.10: "A folder is a book and its files are tracks." This reads a folder into what an import
/// needs: its tracks in playing order with their durations, a title for each, and the book's title
/// and credits, all from the files' own tags where they have them and from names where they do not.
library;

import 'dart:io';
import 'dart:math' as math;

import 'local_audio.dart';
import 'mp4_chapters.dart';

/// The extensions of an image beside a book's audio that may be its cover: the formats rippers and
/// taggers save cover art in, which every platform can decode.
const _imageExtensions = {'jpg', 'jpeg', 'png'};

/// One audio file of a folder book.
final class FolderTrack {
  const FolderTrack({
    required this.fileName,
    required this.format,
    required this.sizeBytes,
    required this.durationMs,
    required this.durationIsEstimate,
    required this.title,
    this.trackNumber,
    this.discNumber,
  });

  /// The file's name within its folder.
  final String fileName;

  /// The file's extension, in lower case.
  final String format;
  final int sizeBytes;
  final int durationMs;
  final bool durationIsEstimate;

  /// The chapter title this file gives the book.
  final String title;
  final int? trackNumber;
  final int? discNumber;
}

/// An audio file of a folder that was read, and left out of its book because the device cannot play
/// its format.
final class UnplayableFile {
  const UnplayableFile({required this.fileName, required this.format});

  /// The file's name within its folder.
  final String fileName;
  final LocalAudioFormat format;

  @override
  bool operator ==(Object other) =>
      other is UnplayableFile &&
      other.fileName == fileName &&
      other.format == format;

  @override
  int get hashCode => Object.hash(fileName, format);

  @override
  String toString() => 'UnplayableFile($fileName, ${format.name})';
}

/// A folder read as a book.
final class FolderBook {
  const FolderBook({
    required this.title,
    required this.authors,
    required this.narrators,
    required this.tracks,
    required this.unreadable,
    this.unplayable = const [],
    this.coverFileName,
  });

  final String title;
  final List<String> authors;
  final List<String> narrators;

  /// In playing order. Empty only when every file that could be read is in [unplayable].
  final List<FolderTrack> tracks;

  /// Audio files, by name, that could not be read. They are left out of the book rather than failing
  /// it, so one damaged file does not cost the rest.
  final List<String> unreadable;

  /// Audio files that were read but are in a format the device cannot play, in natural order of
  /// their names. They are left out of the book, as [unreadable] files are.
  final List<UnplayableFile> unplayable;

  /// The name of the image in the folder to show as the book's cover, or null when there is none
  /// or no telling which one it is. Only the name is known: the image is not read, so it may yet
  /// fail to decode.
  final String? coverFileName;
}

/// Reads [folder] as a book, or returns null when it holds no audio that can be read.
///
/// Files in a format [canPlay] turns down are left out of the book and listed in
/// [FolderBook.unplayable], and the book is made of the rest: its order, its chapter titles and its
/// credits come from the files that will play. Without [canPlay] every format is taken. A folder
/// whose every readable file is turned down still gives a book, with no tracks, so that the caller
/// can say which formats the device cannot play rather than that the folder holds no audio.
///
/// Only the folder's own files are read, not its subfolders. Hidden files are skipped, which also
/// skips the `._` companions macOS leaves beside files copied to other file systems.
///
/// Tracks play in the order of their disc and track numbers when every track has one and no two
/// share one, and otherwise in natural order of their file names, so that "Chapter 2" comes before
/// "Chapter 10". Partial or repeated numbers are common enough in hand-made rips that trusting them
/// would scramble the book.
///
/// The cover is the image named `cover`, `folder` or `front`, tried in that order and in any case,
/// which are the names music players have long looked for; failing those, the folder's only image.
/// Among several images with other names none is chosen, since nothing tells a front cover from a
/// back cover or a disc scan. Only names are looked at here: a cover embedded in the audio comes
/// from [readLocalAudioInfo] when asked for.
Future<FolderBook?> readFolderBook(
  Directory folder, {
  bool Function(LocalAudioFormat format)? canPlay,
}) async {
  final probed = <_Probed>[];
  final unreadable = <String>[];
  final unplayable = <UnplayableFile>[];
  final images = <String>[];
  final files = await folder
      .list(followLinks: false)
      .where((entity) => entity is File)
      .cast<File>()
      .toList();
  for (final file in files) {
    final name = _lastSegment(file.path);
    final format = _extension(name);
    if (name.startsWith('.')) continue;
    if (_imageExtensions.contains(format)) {
      images.add(name);
      continue;
    }
    if (!audioExtensions.contains(format)) continue;
    final info = await _probe(file, name, format);
    if (info == null) {
      unreadable.add(name);
    } else if (canPlay != null && !canPlay(info.audioFormat)) {
      unplayable.add(UnplayableFile(fileName: name, format: info.audioFormat));
    } else {
      probed.add(info);
    }
  }
  if (probed.isEmpty && unplayable.isEmpty) return null;
  unreadable.sort(_compareNatural);
  unplayable.sort((a, b) => _compareNatural(a.fileName, b.fileName));

  final numbered =
      probed.every((track) => track.trackNumber != null) &&
      {for (final track in probed) (track.discNumber ?? 1, track.trackNumber)}
              .length ==
          probed.length;
  probed.sort(
    numbered
        ? (a, b) => switch ((a.discNumber ?? 1).compareTo(b.discNumber ?? 1)) {
            0 => a.trackNumber!.compareTo(b.trackNumber!),
            final byDisc => byDisc,
          }
        : (a, b) => _compareNatural(a.fileName, b.fileName),
  );

  // A title tag names a chapter only if no other file carries it. Some rips tag every file with the
  // book's title, and a chapter list of one name repeated says nothing.
  final titleCounts = <String, int>{};
  for (final track in probed) {
    final title = track.title;
    if (title != null) titleCounts[title] = (titleCounts[title] ?? 0) + 1;
  }

  final author =
      _mostCommon([for (final track in probed) track.albumArtist]) ??
      _mostCommon([for (final track in probed) track.artist]);
  final narrator = _mostCommon([for (final track in probed) track.composer]);
  return FolderBook(
    title:
        _mostCommon([for (final track in probed) track.album]) ??
        _lastSegment(folder.path),
    authors: [?author],
    narrators: [?narrator],
    tracks: [
      for (final track in probed)
        FolderTrack(
          fileName: track.fileName,
          format: track.format,
          sizeBytes: track.sizeBytes,
          durationMs: track.durationMs,
          durationIsEstimate: track.durationIsEstimate,
          title: switch (track.title) {
            final title? when titleCounts[title] == 1 => title,
            _ => _stem(track.fileName),
          },
          trackNumber: track.trackNumber,
          discNumber: track.discNumber,
        ),
    ],
    unreadable: unreadable,
    unplayable: unplayable,
    coverFileName: _coverFileName(images),
  );
}

/// The image in [folder] to take as its book's cover, or null when there is none: the image
/// [readFolderBook] names as [FolderBook.coverFileName], found without reading the folder's audio.
///
/// For a book already in the library, whose tracks need not be probed again to find its cover. Only
/// names are looked at, so the image may yet fail to read as one.
Future<File?> findFolderCoverImage(Directory folder) async {
  final images = <String, File>{};
  await for (final entity in folder.list(followLinks: false)) {
    if (entity is! File) continue;
    final name = _lastSegment(entity.path);
    if (!name.startsWith('.') && _imageExtensions.contains(_extension(name))) {
      images[name] = entity;
    }
  }
  return images[_coverFileName(images.keys.toList())];
}

/// The names a cover image is actually saved under, in the order they are preferred.
///
/// Three of these were here from the start; the rest are what real folders turn out to hold.
/// `albumart` and `albumartsmall` are what Windows Media Player leaves behind, `artwork` and
/// `poster` are what several rippers write, and `folder` is the one Windows itself understands.
/// Nothing here is a guess about a particular listener's folders: each is a name some tool writes
/// by convention.
const _coverStems = [
  'cover',
  'folder',
  'front',
  'artwork',
  'albumart',
  'album art',
  'albumartsmall',
  'poster',
  'thumb',
  'thumbnail',
];

/// The cover among a folder's [images], by name, as [readFolderBook] describes it.
///
/// A folder with exactly one image is taken to mean it, whatever it is called -- a book's cover
/// saved under the book's own title is common and cannot be matched by name. A folder with several
/// images and none of the known names has no cover this can pick without guessing, and the embedded
/// picture is a better answer than a coin toss.
String? _coverFileName(List<String> images) {
  for (final stem in _coverStems) {
    final named = [
      for (final name in images)
        if (_stem(name).toLowerCase() == stem) name,
    ];
    // Several, such as cover.jpg beside cover.png, are told apart only by a fixed order.
    if (named.isNotEmpty) return (named..sort()).first;
  }
  return images.length == 1 ? images.single : null;
}

/// What reading one file found, before the folder is put in order.
final class _Probed {
  const _Probed({
    required this.fileName,
    required this.format,
    required this.sizeBytes,
    required this.info,
  });

  final String fileName;

  /// The file's extension, in lower case.
  final String format;
  final int sizeBytes;
  final LocalAudioInfo info;

  LocalAudioFormat get audioFormat => info.format;
  int get durationMs => info.durationMs;
  bool get durationIsEstimate => info.durationIsEstimate;
  String? get title => info.title;
  String? get artist => info.artist;
  String? get albumArtist => info.albumArtist;
  String? get album => info.album;
  String? get composer => info.composer;
  int? get trackNumber => info.trackNumber;
  int? get discNumber => info.discNumber;
}

/// Reads one file, or returns null when it is not audio this package can read.
///
/// A file's own embedded chapters are not read into the book: each file is one chapter of it, as
/// §3.10 has it.
Future<_Probed?> _probe(File file, String name, String format) async {
  final source = await FileByteSource.open(file);
  try {
    final info = await readLocalAudioInfo(source, extension: format);
    return info == null
        ? null
        : _Probed(
            fileName: name,
            format: format,
            sizeBytes: source.length,
            info: info,
          );
  } on FormatException {
    return null;
  } finally {
    await source.close();
  }
}

/// The value appearing most often, ignoring nulls, with ties going to the first to appear. Null
/// when every value is null.
String? _mostCommon(List<String?> values) {
  final counts = <String, int>{};
  for (final value in values) {
    if (value != null) counts[value] = (counts[value] ?? 0) + 1;
  }
  String? best;
  for (final MapEntry(:key, :value) in counts.entries) {
    if (best == null || value > counts[best]!) best = key;
  }
  return best;
}

/// Orders names as people read them: runs of digits by their value, everything else ignoring case.
int _compareNatural(String a, String b) {
  final pattern = RegExp(r'\d+|\D+');
  final left = [for (final m in pattern.allMatches(a.toLowerCase())) m[0]!];
  final right = [for (final m in pattern.allMatches(b.toLowerCase())) m[0]!];
  for (var i = 0; i < math.min(left.length, right.length); i++) {
    final x = int.tryParse(left[i]);
    final y = int.tryParse(right[i]);
    final order = x != null && y != null
        ? x.compareTo(y)
        : left[i].compareTo(right[i]);
    if (order != 0) return order;
  }
  return left.length.compareTo(right.length);
}

String _lastSegment(String path) {
  final segments = path.split(RegExp(r'[\\/]'))
    ..removeWhere((segment) => segment.isEmpty);
  return segments.isEmpty ? path : segments.last;
}

String _extension(String name) {
  final dot = name.lastIndexOf('.');
  return dot < 0 ? '' : name.substring(dot + 1).toLowerCase();
}

String _stem(String name) {
  final dot = name.lastIndexOf('.');
  return dot > 0 ? name.substring(0, dot) : name;
}
