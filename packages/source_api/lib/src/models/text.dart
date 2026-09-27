/// What a text source's chapter says: SourceAPI 1.1's `ChapterContent` (ADR-0019).
///
/// A text source hands the app HTML or plain text. The app does not show either: it decodes them
/// here into a small, closed set of blocks, and the reader draws those. That is the whole security
/// model for text — a general HTML renderer is never pointed at a stranger's markup, because what
/// reaches the screen is only ever one of the types below.
///
/// The set is deliberately small. It is what prose needs — paragraphs, headings, quotations, lists,
/// a scene break, an illustration, a block of preformatted text — and the emphasis inside them. A
/// table reads as its cells in order, and anything the converter does not recognise is kept as its
/// text or dropped. What is missing can be added in a later minor version; what was rendered
/// wrongly on a listener's screen cannot be taken back.
library;

/// What kind of book a source offers.
///
/// Per source, not per extension: one extension may offer both. And per *book* in the app, because
/// the Local source serves both — a folder of audio files and an EPUB are both books from this
/// device.
enum SourceKind {
  /// Audiobooks, played. Every source that targets 1.0 is this.
  audio,

  /// Books to read. Needs 1.1: a 1.0 app would call `resolveMedia` on it.
  text,
}

/// A run of text and how it is emphasised.
///
/// A line break inside a paragraph is a `\n` in [text]. Whitespace is already collapsed the way a
/// browser collapses it, so what is here is what is shown.
final class TextRun {
  const TextRun(this.text, {this.bold = false, this.italic = false});

  final String text;
  final bool bold;
  final bool italic;

  @override
  bool operator ==(Object other) =>
      other is TextRun &&
      other.text == text &&
      other.bold == bold &&
      other.italic == italic;

  @override
  int get hashCode => Object.hash(text, bold, italic);

  @override
  String toString() =>
      'TextRun("$text"${bold ? ', bold' : ''}${italic ? ', italic' : ''})';
}

/// One block of a chapter. Closed: the reader switches over every case, and the analyzer says so
/// when a case is added.
sealed class ContentBlock {
  const ContentBlock();
}

/// A paragraph of prose.
final class ParagraphBlock extends ContentBlock {
  const ParagraphBlock(this.runs);

  final List<TextRun> runs;

  @override
  bool operator ==(Object other) =>
      other is ParagraphBlock && _sameRuns(other.runs, runs);

  @override
  int get hashCode => Object.hashAll(runs);

  @override
  String toString() => 'ParagraphBlock($runs)';
}

/// A heading, levels 1 to 6 as HTML numbers them.
final class HeadingBlock extends ContentBlock {
  const HeadingBlock(this.level, this.runs);

  final int level;
  final List<TextRun> runs;

  @override
  bool operator ==(Object other) =>
      other is HeadingBlock &&
      other.level == level &&
      _sameRuns(other.runs, runs);

  @override
  int get hashCode => Object.hash(level, Object.hashAll(runs));

  @override
  String toString() => 'HeadingBlock($level, $runs)';
}

/// A paragraph set off as a quotation. A quotation of several paragraphs is several of these, one
/// after another, which is how it reads anyway.
final class QuoteBlock extends ContentBlock {
  const QuoteBlock(this.runs);

  final List<TextRun> runs;

  @override
  bool operator ==(Object other) =>
      other is QuoteBlock && _sameRuns(other.runs, runs);

  @override
  int get hashCode => Object.hashAll(runs);

  @override
  String toString() => 'QuoteBlock($runs)';
}

/// One item of a list.
final class ListItemBlock extends ContentBlock {
  const ListItemBlock(this.runs, {this.number, this.depth = 0});

  final List<TextRun> runs;

  /// Its number in an ordered list, or null in an unordered one.
  final int? number;

  /// How deeply it is nested, from 0.
  final int depth;

  @override
  bool operator ==(Object other) =>
      other is ListItemBlock &&
      other.number == number &&
      other.depth == depth &&
      _sameRuns(other.runs, runs);

  @override
  int get hashCode => Object.hash(number, depth, Object.hashAll(runs));

  @override
  String toString() => 'ListItemBlock(${number ?? '•'}, $runs)';
}

/// Text whose spacing matters: set in a fixed-width face, its line breaks kept as they are.
final class PreformattedBlock extends ContentBlock {
  const PreformattedBlock(this.text);

  final String text;

  @override
  bool operator ==(Object other) =>
      other is PreformattedBlock && other.text == text;

  @override
  int get hashCode => text.hashCode;

  @override
  String toString() => 'PreformattedBlock(${text.length} characters)';
}

/// An illustration.
///
/// Its URL has been through the same checks as every other URL a source hands over, so it is on a
/// host the source declared. For a local book it names a file inside the book instead, which the
/// source that made it knows how to read.
final class ImageBlock extends ContentBlock {
  const ImageBlock(this.url, {this.alt});

  final Uri url;

  /// What the picture shows, for a screen reader and for when it will not load.
  final String? alt;

  @override
  bool operator ==(Object other) =>
      other is ImageBlock && other.url == url && other.alt == alt;

  @override
  int get hashCode => Object.hash(url, alt);

  @override
  String toString() => 'ImageBlock($url)';
}

/// A scene break: `<hr>`, or the row of asterisks a novel puts between scenes.
final class RuleBlock extends ContentBlock {
  const RuleBlock();

  @override
  bool operator ==(Object other) => other is RuleBlock;

  @override
  int get hashCode => (RuleBlock).hashCode;

  @override
  String toString() => 'RuleBlock()';
}

/// A chapter's text, as blocks.
final class ChapterContent {
  const ChapterContent(this.blocks);

  final List<ContentBlock> blocks;

  bool get isEmpty => blocks.isEmpty;

  /// Its text with no formatting, for search and for counting.
  String get plainText => [
    for (final block in blocks)
      switch (block) {
        ParagraphBlock(:final runs) ||
        HeadingBlock(:final runs) ||
        QuoteBlock(:final runs) ||
        ListItemBlock(:final runs) => runs.map((r) => r.text).join(),
        PreformattedBlock(:final text) => text,
        ImageBlock(:final alt) => alt ?? '',
        RuleBlock() => '',
      },
  ].where((text) => text.isNotEmpty).join('\n\n');

  @override
  bool operator ==(Object other) =>
      other is ChapterContent &&
      other.blocks.length == blocks.length &&
      Iterable.generate(blocks.length)
          .every((i) => other.blocks[i] == blocks[i]);

  @override
  int get hashCode => Object.hashAll(blocks);

  @override
  String toString() => 'ChapterContent(${blocks.length} blocks)';
}

bool _sameRuns(List<TextRun> a, List<TextRun> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
