/// Turning HTML or plain text into a chapter's blocks (SourceAPI 1.1, ADR-0019).
///
/// Both kinds of text source come through here: a JavaScript extension's `getChapterContent`,
/// decoded by `PlainDataDecoder`, and a local EPUB's chapters, which are XHTML. One converter, so a
/// paragraph means the same thing whichever door it came in by.
///
/// **This is where untrusted markup stops.** The walk below knows a short list of elements and what
/// each becomes. An element it does not know contributes its text and nothing else. An element on
/// the dropped list contributes nothing at all, content included — a `<script>`'s body is not prose,
/// and neither is a `<style>`'s or a form's. Attributes are never read except `src`, `data-src` and
/// `alt` on an image and `start` on a list, so there is no `onclick`, no inline style, no link
/// target, nowhere for markup to do anything but be read.
///
/// **Whitespace is collapsed as a browser collapses it**, across element boundaries, because that is
/// what the author of the HTML saw. `<pre>` keeps its own.
library;

import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html;

import '../models/text.dart';

/// Resolves an image's `src` to what an [ImageBlock] should point at, or null to leave it out.
///
/// The caller decides, because only the caller knows what an address means. For an extension it
/// resolves against the page the chapter came from and holds the result to the declared domains.
/// For an EPUB it names a file inside the book.
typedef ImageResolver = Uri? Function(String src);

/// [markup] as blocks.
ChapterContent contentFromHtml(
  String markup, {
  required ImageResolver resolveImage,
}) {
  final document = html.parse(markup);
  final root = document.body ?? document.documentElement;
  final builder = _Builder(resolveImage);
  if (root != null) builder.walkChildren(root, const _Style());
  builder.flush();
  return ChapterContent(List.unmodifiable(builder.blocks));
}

/// [text] as blocks.
///
/// Plain text arrives shaped two ways, and they want opposite handling. Text with blank lines
/// between its paragraphs — a Project Gutenberg file, most things typed by hand — is usually hard
/// wrapped as well, so a single newline inside a paragraph is only the end of a line and becomes a
/// space. Text with no blank lines anywhere uses each newline to end a paragraph. Guessing wrongly
/// either way produces either one enormous paragraph or a paragraph per line of a sonnet, so the
/// text is asked which shape it is.
ChapterContent contentFromText(String text) {
  final normalised = text.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
  final blankLine = RegExp(r'\n[ \t]*\n');
  final paragraphs = blankLine.hasMatch(normalised)
      ? normalised.split(blankLine).map((p) => p.replaceAll('\n', ' '))
      : normalised.split('\n');
  final blocks = <ContentBlock>[];
  for (final paragraph in paragraphs) {
    final collapsed = paragraph.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (collapsed.isEmpty) continue;
    blocks.add(
      _isSceneBreak(collapsed)
          ? const RuleBlock()
          : ParagraphBlock([TextRun(collapsed)]),
    );
  }
  return ChapterContent(List.unmodifiable(blocks));
}

/// Elements that contribute nothing, not even their text.
const _dropped = {
  'script',
  'style',
  'noscript',
  'template',
  'head',
  'title',
  'meta',
  'link',
  'base', //
  'iframe', 'frame', 'frameset', 'object', 'embed', 'applet', 'canvas', //
  'form',
  'input',
  'button',
  'select',
  'option',
  'optgroup',
  'textarea',
  'label',
  'datalist', //
  'svg',
  'math',
  'video',
  'audio',
  'source',
  'track',
  'map',
  'area',
  'dialog',
  'nav',
};

/// Elements that begin and end a block of prose.
const _blocks = {
  'p',
  'div',
  'section',
  'article',
  'main',
  'body',
  'html',
  'header',
  'footer',
  'aside', //
  'figure',
  'figcaption',
  'center',
  'address',
  'details',
  'summary',
  'caption', //
  'table', 'thead', 'tbody', 'tfoot', 'tr', 'td', 'th', 'dl', 'dt', 'dd', 'li',
};

const _bold = {'b', 'strong'};
const _italic = {'i', 'em', 'cite', 'dfn', 'var'};

/// A paragraph that is only a scene-break mark: `* * *`, `***`, `#`, `~ ~ ~` and the like.
///
/// Not dashes. A paragraph of one em dash is sometimes dialogue broken off, and reading it as a
/// scene break would throw words away.
bool _isSceneBreak(String paragraph) =>
    paragraph.length <= 20 &&
    RegExp(r'^[*#~•·◇◆ ]*[*#~•·◇◆][*#~•·◇◆ ]*$').hasMatch(paragraph);

/// How the text being walked is emphasised.
final class _Style {
  const _Style({this.bold = false, this.italic = false});

  final bool bold;
  final bool italic;

  _Style with_({bool? bold, bool? italic}) =>
      _Style(bold: bold ?? this.bold, italic: italic ?? this.italic);
}

/// What the runs being gathered will become when they are flushed.
sealed class _Pending {
  const _Pending();
}

final class _AsParagraph extends _Pending {
  const _AsParagraph();
}

final class _AsQuote extends _Pending {
  const _AsQuote();
}

final class _AsListItem extends _Pending {
  const _AsListItem(this.number, this.depth);

  final int? number;
  final int depth;
}

final class _Builder {
  _Builder(this._resolveImage);

  final ImageResolver _resolveImage;
  final blocks = <ContentBlock>[];
  final _runs = <TextRun>[];

  /// What the runs become. A stack because a quotation can hold a list and a list can hold a list.
  final _pending = <_Pending>[const _AsParagraph()];

  /// How deeply lists are nested right now, for an item's indent.
  var _listDepth = 0;

  void walkChildren(dom.Node parent, _Style style) {
    for (final child in parent.nodes) {
      walk(child, style);
    }
  }

  void walk(dom.Node node, _Style style) {
    if (node is dom.Text) {
      _addText(node.text, style);
      return;
    }
    if (node is! dom.Element) return;
    final tag = (node.localName ?? '').toLowerCase();
    if (_dropped.contains(tag)) return;

    switch (tag) {
      case 'br':
        _lineBreak(style);
      case 'hr':
        flush();
        blocks.add(const RuleBlock());
      case 'img':
        _image(node);
      case 'h1' || 'h2' || 'h3' || 'h4' || 'h5' || 'h6':
        _heading(int.parse(tag.substring(1)), node, style);
      case 'pre':
        flush();
        final text = node.text.replaceAll('\r\n', '\n').trimRight();
        if (text.trim().isNotEmpty) blocks.add(PreformattedBlock(text));
      case 'blockquote':
        flush();
        _pending.add(const _AsQuote());
        walkChildren(node, style);
        flush();
        _pending.removeLast();
      case 'ul' || 'ol':
        _list(node, ordered: tag == 'ol', style: style);
      case _ when _bold.contains(tag):
        walkChildren(node, style.with_(bold: true));
      case _ when _italic.contains(tag):
        walkChildren(node, style.with_(italic: true));
      case _ when _blocks.contains(tag):
        flush();
        walkChildren(node, style);
        flush();
      default:
        // Anything else — span, a, font, u, small, sup, mark — is its text and nothing more.
        walkChildren(node, style);
    }
  }

  void _heading(int level, dom.Element node, _Style style) {
    flush();
    final heading = _Builder(_resolveImage)..walkChildren(node, style);
    final runs = heading._finishedRuns();
    if (runs.isNotEmpty) blocks.add(HeadingBlock(level, runs));
  }

  void _list(dom.Element node, {required bool ordered, required _Style style}) {
    flush();
    _listDepth++;
    var number = ordered
        ? int.tryParse(node.attributes['start'] ?? '') ?? 1
        : null;
    for (final child in node.children) {
      if ((child.localName ?? '').toLowerCase() != 'li') {
        walk(child, style);
        continue;
      }
      _pending.add(_AsListItem(number, _listDepth - 1));
      walkChildren(child, style);
      flush();
      _pending.removeLast();
      if (number != null) number++;
    }
    _listDepth--;
  }

  void _image(dom.Element node) {
    final src = node.attributes['src'] ?? node.attributes['data-src'];
    if (src == null || src.trim().isEmpty) return;
    final url = _resolveImage(src.trim());
    if (url == null) return;
    // An illustration is a block of its own even when the markup put it mid-sentence, because a
    // picture cannot flow inside a line of text on a phone.
    flush();
    final alt = node.attributes['alt']?.trim();
    blocks.add(ImageBlock(url, alt: alt == null || alt.isEmpty ? null : alt));
  }

  void _addText(String text, _Style style) {
    var collapsed = text.replaceAll(RegExp(r'\s+'), ' ');
    if (collapsed.isEmpty) return;
    // A space at the start of a paragraph, or straight after a line break or another space, is not
    // one a browser would show.
    if (collapsed.startsWith(' ') && _endsInSpaceOrNothing()) {
      collapsed = collapsed.substring(1);
    }
    if (collapsed.isEmpty) return;
    _append(TextRun(collapsed, bold: style.bold, italic: style.italic));
  }

  void _lineBreak(_Style style) {
    // Strip the space a line break makes redundant, then break.
    if (_runs.isNotEmpty && _runs.last.text.endsWith(' ')) {
      final last = _runs.removeLast();
      final trimmed = last.text.substring(0, last.text.length - 1);
      if (trimmed.isNotEmpty) {
        _runs.add(TextRun(trimmed, bold: last.bold, italic: last.italic));
      }
    }
    // A break at the very start of a paragraph is a gap above it, which the paragraph already has.
    if (_runs.isEmpty) return;
    _append(TextRun('\n', bold: style.bold, italic: style.italic));
  }

  bool _endsInSpaceOrNothing() {
    if (_runs.isEmpty) return true;
    final last = _runs.last.text;
    return last.endsWith(' ') || last.endsWith('\n');
  }

  /// Adds [run], merging it into the last one when they are emphasised alike.
  void _append(TextRun run) {
    if (_runs.isNotEmpty) {
      final last = _runs.last;
      if (last.bold == run.bold && last.italic == run.italic) {
        _runs[_runs.length - 1] = TextRun(
          last.text + run.text,
          bold: run.bold,
          italic: run.italic,
        );
        return;
      }
    }
    _runs.add(run);
  }

  /// The gathered runs with the whitespace at their ends trimmed, and nothing if nothing is left.
  List<TextRun> _finishedRuns() {
    final runs = [..._runs];
    _runs.clear();
    while (runs.isNotEmpty) {
      final first = runs.first;
      final trimmed = first.text.trimLeft();
      if (trimmed.isEmpty) {
        runs.removeAt(0);
        continue;
      }
      runs[0] = TextRun(trimmed, bold: first.bold, italic: first.italic);
      break;
    }
    while (runs.isNotEmpty) {
      final last = runs.last;
      final trimmed = last.text.trimRight();
      if (trimmed.isEmpty) {
        runs.removeLast();
        continue;
      }
      runs[runs.length - 1] = TextRun(
        trimmed,
        bold: last.bold,
        italic: last.italic,
      );
      break;
    }
    return List.unmodifiable(runs);
  }

  /// Ends the block being gathered, if it holds anything.
  void flush() {
    final runs = _finishedRuns();
    if (runs.isEmpty) return;
    final text = runs.map((r) => r.text).join();
    blocks.add(switch (_pending.last) {
      _ when _isSceneBreak(text) => const RuleBlock(),
      _AsParagraph() => ParagraphBlock(runs),
      _AsQuote() => QuoteBlock(runs),
      _AsListItem(:final number, :final depth) => ListItemBlock(
        runs,
        number: number,
        depth: depth,
      ),
    });
  }
}
