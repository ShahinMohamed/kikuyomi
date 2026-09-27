// Storynory, as a Kikuyomi source (SourceAPI 1.0).
//
// One RSS feed and nothing else. Storynory has published read-aloud stories for children since
// 2005, and its feed carries everything this app needs: a title, a summary, a duration, artwork and
// an enclosure pointing at the audio.
//
// ## What a book is here
//
// One story. Storynory is an anthology, not a serial: "Birdy's Grudge" has nothing to do with the
// story published the week before it, and listing them as chapters of one book would be filing
// sixty unrelated things under a single spine. So each item is a book with one chapter, which is
// what §4.5 already handles for any single-file book.
//
// ## What the feed does not have
//
// Its own archive. A podcast feed is a window on the most recent episodes — sixty of them here —
// and the several hundred older stories on the site are not in it. There is no paging to ask for
// more: the feed is the whole answer, so `hasNextPage` is only ever true while this extension is
// still handing out what it already has.
//
// ## Parsing
//
// By pattern rather than by parser. The host offers `html.parse`, which returns a promise and is
// built for HTML rather than for namespaced XML like `itunes:duration`; a feed is regular enough
// that matching it directly is both simpler and more predictable. The LibriVox extension reads its
// HTML summaries the same way and for much the same reason.

var FEED = 'https://www.storynory.com/feeds/stories';

/** How many stories a page of the listing holds. */
var PAGE_SIZE = 20;

// ------------------------------------------------------------------------------------- errors

function sourceError(kind, message, extra) {
  var error = new Error(message);
  error.kind = kind;
  if (extra) {
    for (var field in extra) {
      if (Object.prototype.hasOwnProperty.call(extra, field)) error[field] = extra[field];
    }
  }
  return error;
}

// ------------------------------------------------------------------------------------ reading

function textOf(value) {
  if (typeof value === 'string') return value.trim();
  if (typeof value === 'number' && isFinite(value)) return String(value);
  return '';
}

var ENTITIES = {
  amp: '&', lt: '<', gt: '>', quot: '"', apos: "'",
  nbsp: ' ', hellip: '…', mdash: '—', ndash: '–',
  lsquo: '‘', rsquo: '’', ldquo: '“', rdquo: '”',
  eacute: 'é', egrave: 'è', agrave: 'à', ccedil: 'ç',
  uuml: 'ü', ouml: 'ö', auml: 'ä', szlig: 'ß',
  copy: '©', reg: '®', trade: '™'
};

function decodeEntities(text) {
  return text.replace(/&(#x?[0-9a-fA-F]+|[a-zA-Z]+);/g, function (whole, body) {
    if (body.charAt(0) === '#') {
      var hex = body.charAt(1) === 'x' || body.charAt(1) === 'X';
      var code = parseInt(hex ? body.slice(2) : body.slice(1), hex ? 16 : 10);
      if (!isFinite(code) || code <= 0 || code > 0x10ffff) return whole;
      try {
        return String.fromCodePoint(code);
      } catch (error) {
        return whole;
      }
    }
    var named = ENTITIES[body.toLowerCase()];
    return named === undefined ? whole : named;
  });
}

/** A field's contents, with the CDATA wrapper this feed puts round most of them taken off. */
function unwrap(value) {
  var text = textOf(value);
  var cdata = /^<!\[CDATA\[([\s\S]*?)\]\]>$/.exec(text);
  return cdata ? cdata[1].trim() : text;
}

/** The text of the first `<tag>` in [xml], or '' when there is none. */
function tagText(xml, tag) {
  var found = new RegExp('<' + tag + '(?:\\s[^>]*)?>([\\s\\S]*?)</' + tag + '>').exec(xml);
  return found ? unwrap(found[1]) : '';
}

/** An attribute of the first `<tag ...>` in [xml]. */
function tagAttr(xml, tag, attribute) {
  var element = new RegExp('<' + tag + '(\\s[^>]*?)/?>').exec(xml);
  if (!element) return '';
  var found = new RegExp(attribute + '\\s*=\\s*"([^"]*)"').exec(element[1]);
  return found ? decodeEntities(found[1].trim()) : '';
}

/** HTML as the app shows it: plain text. */
function plainText(value) {
  var html = unwrap(value);
  if (!html) return undefined;
  var text = html
    .replace(/\r\n?/g, '\n')
    .replace(/<\s*br\s*\/?\s*>/gi, '\n')
    .replace(/<\s*\/\s*(p|div|li|tr|h[1-6]|blockquote)\s*>/gi, '\n')
    .replace(/<[^>]*>/g, '');
  text = decodeEntities(text).replace(/[\u0000-\u0009\u000b-\u001f\u007f]/g, ' ');
  var lines = text.split('\n');
  for (var i = 0; i < lines.length; i++) lines[i] = lines[i].replace(/\s+/g, ' ').trim();
  text = lines.join('\n').replace(/\n{3,}/g, '\n\n').trim();
  return text || undefined;
}

/**
 * An iTunes duration, in milliseconds.
 *
 * Written `15:35` here and `1:02:33` for anything over an hour; the tag also allows plain seconds,
 * which this feed does not use and which costs nothing to accept.
 */
function msFromDuration(value) {
  var text = textOf(value);
  if (!text) return undefined;
  var parts = text.split(':');
  var seconds = 0;
  for (var i = 0; i < parts.length; i++) {
    var part = parseFloat(parts[i]);
    if (!isFinite(part)) return undefined;
    seconds = seconds * 60 + part;
  }
  if (seconds <= 0) return undefined;
  return Math.round(seconds * 1000);
}

/** The year an item was published, which is all the app shows. */
function yearOf(pubDate) {
  var found = /\b(\d{4})\b/.exec(textOf(pubDate));
  return found ? found[1] : undefined;
}

// -------------------------------------------------------------------------------------- feed

/**
 * The feed, kept for a few minutes.
 *
 * Every call here reads the same document: a listing, a search, a story's details and resolving its
 * audio. Without this, opening one story would fetch the whole feed three times over.
 */
var CACHE_MS = 5 * 60 * 1000;
var held = null;

async function feed() {
  var now = Date.now();
  if (held && now - held.at < CACHE_MS) return held.value;

  var response = await kikuyomi.http.fetch({ url: FEED, responseType: 'text' });
  var status = response.status;
  if (status === 429 || status === 503) {
    var after = parseInt(textOf(response.headers && response.headers['retry-after']), 10);
    throw sourceError('RateLimited', 'storynory.com asked for a pause (' + status + ')',
      isFinite(after) && after > 0 ? { retryAfterMs: after * 1000 } : null);
  }
  if (status >= 500) throw sourceError('Network', 'storynory.com answered ' + status);
  if (status !== 200) {
    throw sourceError('Parse', 'storynory.com answered ' + status + ' for its feed');
  }

  var xml = textOf(response.body);
  if (xml.indexOf('<item') < 0) {
    throw sourceError('Parse', 'what storynory.com served is not a feed');
  }
  var value = read(xml);
  held = { at: now, value: value };
  return value;
}

/** The feed as stories, newest first, which is the order it is written in. */
function read(xml) {
  var channel = xml.split('<item')[0];
  var cover = tagAttr(channel, 'itunes:image', 'href');
  var genres = categoriesOf(channel);
  var author = tagText(channel, 'itunes:author') || 'Storynory';
  var language = textOf(tagText(channel, 'language')) || undefined;

  var stories = [];
  var pattern = /<item(?:\s[^>]*)?>([\s\S]*?)<\/item>/g;
  var match;
  while ((match = pattern.exec(xml)) !== null) {
    var item = match[1];
    var url = tagAttr(item, 'enclosure', 'url');
    if (!url) {
      kikuyomi.log.warn('skipping a story with no audio: ' + tagText(item, 'title'));
      continue;
    }
    // The guid, which this feed gives as a stable identifier rather than a URL. Falling back to the
    // audio address keeps a story readable if the feed ever stops carrying one.
    var key = tagText(item, 'guid') || url;
    stories.push({
      key: key,
      title: decodeEntities(tagText(item, 'title')) || 'A story',
      description: plainText(tagText(item, 'itunes:summary')) ||
        plainText(tagText(item, 'description')),
      coverUrl: tagAttr(item, 'itunes:image', 'href') || cover || undefined,
      durationMs: msFromDuration(tagText(item, 'itunes:duration')),
      publishedDate: yearOf(tagText(item, 'pubDate')),
      author: author,
      genres: genres,
      language: language,
      url: url
    });
  }
  if (!stories.length) throw sourceError('Parse', 'storynory.com listed no stories');
  return stories;
}

/**
 * The feed's own categories, as genres.
 *
 * On the channel rather than on an item: this feed categorises itself once and its stories not at
 * all, which is the ordinary shape of a podcast feed. Every story therefore carries the same two,
 * which is honest — they are all children's stories — and better than sending none at all.
 */
function categoriesOf(channel) {
  var genres = [];
  var pattern = /<itunes:category[^>]*text="([^"]*)"/g;
  var match;
  while ((match = pattern.exec(channel)) !== null) {
    var name = decodeEntities(match[1]).trim();
    if (name && genres.indexOf(name) < 0) genres.push(name);
  }
  return genres;
}

function summaryOf(story) {
  return {
    key: story.key,
    title: story.title,
    authors: [story.author],
    coverUrl: story.coverUrl
  };
}

/** One page of [stories], as the contract's `PageResult<BookSummary>`. */
function pageOf(stories, page) {
  var from = (page - 1) * PAGE_SIZE;
  var items = [];
  for (var i = from; i < stories.length && i < from + PAGE_SIZE; i++) {
    items.push(summaryOf(stories[i]));
  }
  return { items: items, hasNextPage: from + PAGE_SIZE < stories.length };
}

async function storyByKey(bookKey) {
  var wanted = textOf(bookKey);
  var stories = await feed();
  for (var i = 0; i < stories.length; i++) {
    if (stories[i].key === wanted) return stories[i];
  }
  // A story that has fallen out of the feed's window is gone as far as this source is concerned,
  // and the app keeps the book and its progress (§4.4) rather than losing them.
  throw sourceError('NotFound', 'storynory.com no longer lists ' + wanted);
}

/** What the app should call the file, from its address. */
function formatOf(url) {
  var found = /\.([a-z0-9]+)(?:[?#]|$)/i.exec(url);
  if (!found) return undefined;
  var extension = found[1].toLowerCase();
  if (extension === 'mp3') return 'mp3';
  if (extension === 'm4a' || extension === 'm4b') return 'm4b';
  if (extension === 'ogg' || extension === 'oga') return 'ogg';
  return undefined;
}

// ------------------------------------------------------------------------------------- source

var storynory = {
  async getPopular(page) {
    // Storynory ranks nothing and the feed is in publication order, so newest first is the honest
    // answer and the one a listener coming back for what is new actually wants.
    return pageOf(await feed(), page);
  },

  async search(query, page) {
    var text = textOf(query && query.text).toLowerCase();
    var stories = await feed();
    if (!text) return pageOf(stories, page);
    // Matched here rather than asked of the site: the feed is the whole catalogue this source has,
    // and it is already in hand.
    var found = [];
    for (var i = 0; i < stories.length; i++) {
      if (stories[i].title.toLowerCase().indexOf(text) >= 0) found.push(stories[i]);
    }
    return pageOf(found, page);
  },

  async getBookDetails(bookKey) {
    var story = await storyByKey(bookKey);
    return {
      key: story.key,
      title: story.title,
      authors: [story.author],
      // Required by the contract, and empty because the feed names no reader. Storynory's stories
      // are read by people whose names the feed does not carry, so nothing is claimed for them.
      narrators: [],
      genres: story.genres,
      description: story.description,
      coverUrl: story.coverUrl,
      language: story.language,
      publisher: 'Storynory',
      publishedDate: story.publishedDate,
      totalDurationMs: story.durationMs,
      // One story, published whole. Nothing here arrives a part at a time.
      status: 'complete'
    };
  },

  async getChapters(bookKey) {
    var story = await storyByKey(bookKey);
    // One story is one recording. The chapter carries the book's own title rather than a made-up
    // "Part 1", which is what a single-chapter book reads best as.
    return [{ key: story.key, title: story.title, durationMs: story.durationMs }];
  },

  async resolveMedia(chapter) {
    var story = await storyByKey(chapter && chapter.bookKey);
    // The enclosure address is a permalink that redirects to wherever the file is served from
    // today, so there is no token and no expiry: the app may keep this for as long as it likes.
    return {
      segments: [
        {
          fileKey: story.key,
          request: { url: story.url },
          format: formatOf(story.url),
          durationMs: story.durationMs
        }
      ]
    };
  }
};

module.exports = { sources: { storynory: storynory } };
