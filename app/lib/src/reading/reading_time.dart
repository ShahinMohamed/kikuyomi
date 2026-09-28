/// How long a chapter of a book to read takes, in the only terms that mean anything for text.
///
/// An audiobook chapter is twelve minutes long for everyone, because that is a fact about the
/// recording. A chapter of text is four thousand words long for everyone and twelve minutes long
/// only for someone who reads at that pace, so the words are what is stored and the minutes are
/// worked out for whoever is reading. Every figure it produces is prefixed "about", because it is.
library;

import '../format.dart';

/// The same idea of a word the EPUB reader counts with: letters and digits, kept together by an
/// apostrophe or a hyphen. Counting "don't" and "well-meaning" as one word each is what a reading
/// pace in words a minute is measured against.
final _word = RegExp(r"[\p{L}\p{N}][\p{L}\p{N}'’-]*", unicode: true);

/// How many words [text] holds.
int wordsIn(String text) => _word.allMatches(text).length;

/// How long [words] takes at [wordsPerMinute], or null when there is nothing to say.
///
/// Null for a chapter whose words have not been counted, and for a reader who has turned the
/// estimate off, which is what a pace of zero means.
Duration? readingTime(int? words, {required int wordsPerMinute}) {
  if (words == null || words <= 0 || wordsPerMinute <= 0) return null;
  return Duration(seconds: (words * 60 / wordsPerMinute).round());
}

/// [time] as a person says it, hedged: `about 42 m`, shortened to `~42 m` beside a chapter.
String formatReadingTime(Duration time) => '~${formatDuration(time)}';
