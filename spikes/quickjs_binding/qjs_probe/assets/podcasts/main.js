// Podcasts, as a Kikuyomi source (SourceAPI 1.0).
//
// A great many audiobooks are published as podcasts. Serialised novels, public-domain readings,
// fiction anthologies, whole web novels narrated a batch of chapters at a time: a podcast feed is
// often just an audiobook with an RSS document in front of it. This source plays them.
//
// ## What a book is here
//
// One show, whatever its feed says its name is. Each episode is a chapter, in publication order —
// oldest first, which is the reverse of how a feed is written, because a serial is meant to be
// listened to from the start.
//
// That is the opposite of the Storynory source's decision, and for the opposite reason. Storynory
// is an anthology: its episodes have nothing to do with each other, so each is its own book. A show
// that narrates one novel is a serial: its episodes are a book, and filing each as a book of its
// own would scatter a single story across a hundred spines. Neither answer is right for both, so a
// listener who adds an anthology here will see it as one long book. That is the honest cost of
// having one source for every feed.
//
// ## How a listener adds a show
//
// Through search, because SourceAPI 1.0 gives an extension no other way to be told anything. There
// is no per-source settings screen in this version of the contract, so the search box is the input,
// and it takes four kinds of thing:
//
//   - an RSS feed address, used as it stands;
//   - an Apple Podcasts link, looked up by its numeric id, which is exact;
//   - a Spotify show link, whose public page gives the show's name, which is then matched against
//     Apple's index — a best-effort match, since Spotify publishes no feed address;
//   - anything else, searched for by name in Apple's public podcast index.
//
// Opening a show remembers it, so `getPopular` is the shelf of shows this listener has opened
// rather than a chart nobody computed. Nothing is lost if that store is cleared: a book's key *is*
// its feed address, so every book already knows where to find itself.
//
// ## Spotify links work; Spotify audio does not
//
// A Spotify link is read for one thing only — the name of the show — and everything after that
// comes from the podcast's own feed. Spotify's own streams are encrypted and only its apps can
// decrypt them, so there is nothing here that touches them, and there never will be. Most shows on
// Spotify are ordinary RSS podcasts that Spotify lists; those are the ones this source can play. A
// show that exists only inside Spotify is not reachable from here, and the search will say so
// rather than pretend.
//
// ## Why the domains are a list
//
// An extension declares the hosts it may contact, so that the permissions screen can tell a
// listener what installing it means, and there is no way to declare "anywhere" — deliberately. So
// this names the podcast hosts feeds actually live on. A feed somewhere else will not load, and the
// message says which host was refused, which is the useful thing to report when asking for it to be
// added in the next version.
//
// `*.cloudfront.net` is in that list and is broader than the rest. It has to be: Anchor, which is
// the largest podcast host there is, serves every one of its audio files from a CloudFront address,
// and an allowlist that cannot reach them could not play most of what it can find.
//
// The list also names measurement services -- Podtrac, Podsights, Chartable, Podscribe and the
// rest. Those are not hosts this source chooses to use. Publishers put them in front of their own
// audio as a redirect, so the address in the feed points at the tracker and the tracker points at
// the file, and a player that will not follow the hop cannot play the episode at all. Every podcast
// app follows them for the same reason. Sampling real feeds, refusing them cost about one show in
// nine.
//
// ## Parsing
//
// By pattern rather than by parser, like the Storynory source. The host's `html.parse` returns a
// promise and is built for HTML rather than for namespaced XML like `itunes:duration`, and a feed
// is regular enough that matching it directly is both simpler and more predictable.

/** Apple's public podcast index: no key, no account, and it gives feed addresses outright. */
var APPLE_SEARCH = 'https://itunes.apple.com/search';
var APPLE_LOOKUP = 'https://itunes.apple.com/lookup';

/** How many shows a page of search results holds. */
var PAGE_SIZE = 20;

/** How many shows the shelf remembers. Oldest opened falls off the end. */
var SHELF_LIMIT = 200;

var SHELF_KEY = 'shelf';

/**
 * The hosts this extension may contact, as its manifest declares them.
 *
 * Kept here as well so that a feed somewhere else can be refused with a sentence naming the host,
 * rather than by the host bridge with a sentence about the extension. The two lists must agree;
 * `podcasts_extension_test.dart` checks that they do.
 */
var HOSTS = [
  'itunes.apple.com',
  'podcasts.apple.com',
  '*.mzstatic.com',
  'open.spotify.com',
  'podcasters.spotify.com',
  'anchor.fm',
  '*.anchor.fm',
  '*.cloudfront.net',
  '*.libsyn.com',
  '*.libsynpro.com',
  '*.megaphone.fm',
  '*.buzzsprout.com',
  '*.podbean.com',
  '*.podbean.net',
  '*.simplecast.com',
  '*.simplecastaudio.com',
  '*.captivate.fm',
  '*.transistor.fm',
  '*.acast.com',
  '*.acast.cloud',
  '*.art19.com',
  '*.omny.fm',
  'rss.com',
  '*.rss.com',
  '*.fireside.fm',
  '*.blubrry.com',
  '*.blubrry.net',
  '*.spreaker.com',
  '*.redcircle.com',
  '*.soundcloud.com',
  'feeds.feedburner.com',
  '*.podtrac.com',
  '*.pinecast.com',
  '*.castos.com',
  '*.podigee.io',
  '*.substack.com',
  '*.amperwave.net',
  '*.pdrl.fm',
  '*.omnycontent.com',
  '*.feedblitz.com',
  'audioboom.com',
  '*.audioboom.com',
  '*.castbox.fm',
  '*.zencast.fm',
  '*.squarespace.com',
  'pdst.fm',
  '*.pdst.fm',
  'pscrb.fm',
  '*.pscrb.fm',
  'chrt.fm',
  '*.chrt.fm',
  'chtbl.com',
  '*.chtbl.com',
  'mgln.ai',
  '*.mgln.ai',
  '*.podscribe.com',
  'claritaspod.com',
  '*.claritaspod.com',
  '*.byspotify.com',
  'arttrk.com',
  '*.arttrk.com',
  'archive.org',
  '*.archive.org'
];

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

/** A field's contents, with the CDATA wrapper feeds put round most of them taken off. */
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
 * Written `15:35`, or `1:02:33` for anything over an hour, or as plain seconds. All three appear in
 * the wild, often in the same feed.
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

/** An RFC 822 date as epoch milliseconds, for a chapter's `publishedAt`. */
function msFromDate(value) {
  var text = textOf(value);
  if (!text) return undefined;
  var at = Date.parse(text);
  return isFinite(at) ? at : undefined;
}

/** The year something was published, which is all the app shows. */
function yearOf(pubDate) {
  var found = /\b(\d{4})\b/.exec(textOf(pubDate));
  return found ? found[1] : undefined;
}

// ------------------------------------------------------------------------------------- hosts

/** The host part of [url], lower-cased, or '' when it is not an address at all. */
function hostOf(url) {
  var found = /^https?:\/\/([^/?#]+)/i.exec(textOf(url));
  if (!found) return '';
  return found[1].split('@').pop().split(':')[0].toLowerCase().replace(/\.$/, '');
}

/** Whether this extension is allowed to contact [url], by the same rule the app applies. */
function reachable(url) {
  var host = hostOf(url);
  if (!host) return false;
  for (var i = 0; i < HOSTS.length; i++) {
    var entry = HOSTS[i];
    if (entry.indexOf('*.') === 0) {
      var suffix = entry.slice(1);
      if (host.length > suffix.length && host.slice(-suffix.length) === suffix) return true;
    } else if (host === entry) {
      return true;
    }
  }
  return false;
}

/**
 * A URL only if the app would be allowed to fetch it, and nothing otherwise.
 *
 * The allowlist covers every URL an extension *hands over*, not only the ones it fetches itself: a
 * cover and a book's web page are both checked, and one on a host this extension never declared
 * fails the whole call. That is fine for a source that reads one site and knows where its images
 * live. It is not fine here, where the feed belongs to a stranger and its artwork and homepage can
 * be anywhere at all -- a show whose cover sits on its own domain would make every call fail.
 *
 * So a URL out of a feed is offered only when it is reachable, and quietly dropped when it is not.
 * A missing cover is a worse-looking screen; a refused one is no screen.
 */
function offerable(url) {
  return url && reachable(url) ? url : undefined;
}

/**
 * Refuses a feed this extension may not fetch, before the host bridge does.
 *
 * `NotFound` rather than `Parse`: the show is genuinely unavailable through this source, which is
 * what the app should record, and it is not a fault in the feed or in this code that retrying would
 * fix. The message names the host, because that is the one fact worth reporting back.
 */
function requireReachable(url, what) {
  if (reachable(url)) return;
  var host = hostOf(url);
  throw sourceError(
    'NotFound',
    what + ' is hosted at ' + (host || 'an address this source cannot read') +
      ', which this extension is not allowed to contact. It can reach the common podcast hosts ' +
      'only; ask for this one to be added.'
  );
}

// -------------------------------------------------------------------------------------- http

async function getJson(url, what) {
  var response = await kikuyomi.http.fetch({ url: url, responseType: 'json' });
  checkStatus(response, what, hostOf(url));
  var body = response.body;
  if (!body || typeof body !== 'object') {
    throw sourceError('Parse', what + ' did not answer with an object');
  }
  return body;
}

async function getText(url, what) {
  var response = await kikuyomi.http.fetch({ url: url, responseType: 'text' });
  checkStatus(response, what, hostOf(url));
  return textOf(response.body);
}

function checkStatus(response, what, host) {
  var status = response.status;
  if (status === 429 || status === 503) {
    var after = parseInt(textOf(response.headers && response.headers['retry-after']), 10);
    throw sourceError('RateLimited', host + ' asked for a pause (' + status + ')',
      isFinite(after) && after > 0 ? { retryAfterMs: after * 1000 } : null);
  }
  if (status >= 500) throw sourceError('Network', host + ' answered ' + status);
  if (status === 404) throw sourceError('NotFound', what + ' is not there any more');
  if (status !== 200) throw sourceError('Parse', host + ' answered ' + status + ' for ' + what);
}

// -------------------------------------------------------------------------------------- feed

/**
 * Feeds, kept for a few minutes, by address.
 *
 * Every call here reads a whole feed: the details, the chapter list and resolving each episode's
 * audio. A show with four hundred episodes is a large document to fetch three times over for one
 * tap, and a listener moving between a book and its chapters does exactly that.
 *
 * Only the extracted data is held, never a parsed document, which the contract does not allow
 * beyond the call that made it.
 */
var CACHE_MS = 5 * 60 * 1000;
var held = {};

async function show(feedUrl) {
  var url = textOf(feedUrl);
  if (!url) throw sourceError('NotFound', 'no feed was named');
  requireReachable(url, 'that show');

  var now = Date.now();
  var cached = held[url];
  if (cached && now - cached.at < CACHE_MS) return cached.value;

  var xml = await getText(url, 'the feed');
  if (xml.indexOf('<item') < 0) {
    throw sourceError('Parse', 'what ' + hostOf(url) + ' served is not a podcast feed');
  }
  var value = read(url, xml);
  held[url] = { at: now, value: value };
  return value;
}

/** A feed, as the one show it describes. */
function read(feedUrl, xml) {
  var channel = xml.split('<item')[0];
  var cover = tagAttr(channel, 'itunes:image', 'href') || rssImage(channel) || '';
  var author = decodeEntities(tagText(channel, 'itunes:author')) ||
    decodeEntities(tagText(channel, 'managingEditor')) || '';

  var episodes = [];
  var pattern = /<item(?:\s[^>]*)?>([\s\S]*?)<\/item>/g;
  var match;
  while ((match = pattern.exec(xml)) !== null) {
    var item = match[1];
    var audio = tagAttr(item, 'enclosure', 'url');
    if (!audio) continue;
    episodes.push({
      // The guid is what a feed means by a stable identifier. Falling back to the audio address
      // keeps an episode findable in the feeds that leave it out.
      key: tagText(item, 'guid') || audio,
      title: decodeEntities(tagText(item, 'title')) || 'An episode',
      url: audio,
      durationMs: msFromDuration(tagText(item, 'itunes:duration')),
      publishedAt: msFromDate(tagText(item, 'pubDate')),
      publishedYear: yearOf(tagText(item, 'pubDate'))
    });
  }
  if (!episodes.length) {
    throw sourceError('Parse', hostOf(feedUrl) + ' served a feed with no playable episodes in it');
  }
  // A feed is written newest first. A serial is listened to from the start, so the chapter list is
  // turned round: episode one is chapter one.
  episodes.reverse();

  var total = 0;
  for (var i = 0; i < episodes.length; i++) {
    if (!episodes[i].durationMs) { total = 0; break; }
    total += episodes[i].durationMs;
  }

  return {
    key: feedUrl,
    title: decodeEntities(tagText(channel, 'title')) || 'A podcast',
    author: author,
    description: plainText(tagText(channel, 'itunes:summary')) ||
      plainText(tagText(channel, 'description')),
    coverUrl: offerable(cover),
    genres: categoriesOf(channel),
    language: textOf(tagText(channel, 'language')) || undefined,
    publisher: ownerName(channel) || author || undefined,
    publishedDate: episodes.length ? episodes[0].publishedYear : undefined,
    webUrl: offerable(tagText(channel, 'link')),
    explicit: /^(yes|true)$/i.test(tagText(channel, 'itunes:explicit')),
    complete: /^(yes|true)$/i.test(tagText(channel, 'itunes:complete')),
    totalDurationMs: total || undefined,
    episodes: episodes
  };
}

/**
 * The cover a feed gives the old way: `<image><url>...</url></image>` on the channel.
 *
 * Read only when `itunes:image` is missing, which is rare but happens in feeds written before that
 * tag existed and never rewritten since.
 */
function rssImage(channel) {
  var image = /<image(?:\s[^>]*)?>([\s\S]*?)<\/image>/i.exec(channel);
  return image ? tagText(image[1], 'url') : '';
}

/** The name inside `<itunes:owner>`, which is a show's publisher when it names one. */
function ownerName(channel) {
  var owner = /<itunes:owner(?:\s[^>]*)?>([\s\S]*?)<\/itunes:owner>/i.exec(channel);
  return owner ? decodeEntities(tagText(owner[1], 'itunes:name')) : '';
}

/** A feed's own iTunes categories, as genres. Feeds categorise the show, not the episode. */
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

// ------------------------------------------------------------------------------------- shelf

/**
 * The shows this listener has opened, newest first.
 *
 * A convenience, not a record: the app's library is the record. This exists so that the source's
 * front page is the shows you use rather than an empty screen, and so a show you added yesterday is
 * findable without pasting its address again. Losing it costs nothing, because a book's key is its
 * feed address.
 */
async function shelf() {
  try {
    var stored = await kikuyomi.storage.get(SHELF_KEY);
    if (!stored) return [];
    var parsed = JSON.parse(stored);
    return Array.isArray(parsed) ? parsed : [];
  } catch (error) {
    kikuyomi.log.warn('the shelf could not be read, starting an empty one: ' + error);
    return [];
  }
}

async function remember(entry) {
  try {
    var kept = await shelf();
    var without = [entry];
    for (var i = 0; i < kept.length && without.length < SHELF_LIMIT; i++) {
      if (kept[i] && kept[i].key !== entry.key) without.push(kept[i]);
    }
    await kikuyomi.storage.set(SHELF_KEY, JSON.stringify(without));
  } catch (error) {
    // Never worth failing a call the listener asked for. The book opens either way.
    kikuyomi.log.warn('the shelf could not be written: ' + error);
  }
}

// ------------------------------------------------------------------------------- finding one

/** Whether what was typed is an address rather than words to search for. */
function looksLikeUrl(text) {
  return /^https?:\/\/\S+$/i.test(text) || /^[a-z0-9.-]+\.[a-z]{2,}\/\S*$/i.test(text);
}

function withScheme(text) {
  return /^https?:\/\//i.test(text) ? text : 'https://' + text;
}

/**
 * The shows an address names.
 *
 * Three kinds of address, and a feed is the only one used as it stands. The other two are lookups:
 * Apple's index answers by id, exactly, and Spotify's page gives a name to look that show up by.
 */
async function showsAt(typed) {
  var url = withScheme(typed);
  var host = hostOf(url);

  if (host === 'podcasts.apple.com' || host === 'itunes.apple.com') {
    var id = /\/id(\d+)/.exec(url);
    if (!id) throw sourceError('NotFound', 'that Apple Podcasts link carries no show id');
    return appleShows(APPLE_LOOKUP + '?id=' + id[1] + '&entity=podcast');
  }

  if (host === 'open.spotify.com' || host === 'podcasters.spotify.com') {
    return spotifyShow(url);
  }

  // Anything else is taken to be the feed itself. If it is not, reading it says so.
  requireReachable(url, 'that feed');
  var found = await show(url);
  return [summaryOf(found)];
}

/**
 * A Spotify show link, by way of its name.
 *
 * Spotify publishes no feed address, so there is nothing to follow directly. What its public page
 * does carry is the show's title, and almost every show on Spotify is an ordinary RSS podcast that
 * Apple's index also lists. So the title is read from the page and searched for.
 *
 * This is a match by name and is admitted as one. Two shows with the same name will be offered
 * together and the listener picks; a show that exists only inside Spotify will not be found at all,
 * which is the truth rather than a failure — its audio is encrypted and no player but Spotify's own
 * can decode it.
 */
async function spotifyShow(url) {
  var page = await getText(url, 'that Spotify page');
  var title = /<meta\s+property="og:title"\s+content="([^"]*)"/i.exec(page) ||
    /<title>([^<]*)<\/title>/i.exec(page);
  var name = title ? decodeEntities(title[1]).replace(/\s*\|\s*Podcast on Spotify\s*$/i, '').trim()
    : '';
  if (!name) {
    throw sourceError('NotFound', 'that Spotify page does not say what the show is called');
  }
  kikuyomi.log.info('looking for "' + name + '" in the podcast index');
  var found = await appleShows(
    APPLE_SEARCH + '?media=podcast&limit=25&term=' + encodeURIComponent(name)
  );
  if (!found.length) {
    throw sourceError(
      'NotFound',
      'no podcast feed for "' + name + '" could be found. If it is only on Spotify there is no ' +
        'feed to play: its audio is encrypted and only Spotify can decode it.'
    );
  }
  return found;
}

/** Apple's index, as shows. Entries with no feed address are no use here and are dropped. */
async function appleShows(url) {
  var body = await getJson(url, 'the podcast index');
  var results = body.results;
  if (!Array.isArray(results)) return [];
  var shows = [];
  for (var i = 0; i < results.length; i++) {
    var found = results[i];
    var feed = textOf(found && found.feedUrl);
    if (!feed) continue;
    shows.push({
      key: feed,
      title: textOf(found.collectionName) || textOf(found.trackName) || 'A podcast',
      authors: [textOf(found.artistName)].filter(Boolean),
      coverUrl: offerable(textOf(found.artworkUrl600) || textOf(found.artworkUrl100))
    });
  }
  return shows;
}

function summaryOf(found) {
  return {
    key: found.key,
    title: found.title,
    authors: found.author ? [found.author] : [],
    coverUrl: offerable(found.coverUrl)
  };
}

/** One page of [shows], as the contract's `PageResult<BookSummary>`. */
function pageOf(shows, page) {
  var from = (page - 1) * PAGE_SIZE;
  var items = [];
  for (var i = from; i < shows.length && i < from + PAGE_SIZE; i++) items.push(shows[i]);
  return { items: items, hasNextPage: from + PAGE_SIZE < shows.length };
}

// ------------------------------------------------------------------------------------- source

var podcasts = {
  async getPopular(page) {
    // Nothing here ranks anything, and inventing a chart would be a lie. What a listener wants on
    // this screen is the shows they already follow.
    return pageOf(await shelf(), page);
  },

  async search(query, page) {
    var text = textOf(query && query.text);
    if (!text) return pageOf(await shelf(), page);

    if (looksLikeUrl(text)) {
      // An address is one answer, not a list, so paging past the first page is empty rather than
      // the same answer again.
      return page > 1
        ? { items: [], hasNextPage: false }
        : { items: await showsAt(text), hasNextPage: false };
    }

    var found = await appleShows(
      APPLE_SEARCH + '?media=podcast&limit=' + (PAGE_SIZE * 3) +
        '&term=' + encodeURIComponent(text)
    );
    return pageOf(found, page);
  },

  async getBookDetails(bookKey) {
    var found = await show(bookKey);
    await remember(summaryOf(found));
    return {
      key: found.key,
      title: found.title,
      // A feed names whoever publishes it, and does not separate writing from reading. Claiming the
      // same person for both would be inventing a credit, so the author is given and the narrator
      // is left empty.
      authors: found.author ? [found.author] : [],
      narrators: [],
      genres: found.genres,
      description: found.description,
      coverUrl: found.coverUrl,
      language: languageOf(found.language),
      publisher: found.publisher,
      publishedDate: found.publishedDate,
      totalDurationMs: found.totalDurationMs,
      // `itunes:complete` is a feed saying it will publish nothing more. Without it a podcast is
      // ongoing, which is what a podcast is.
      status: found.complete ? 'complete' : 'ongoing',
      contentRating: found.explicit ? 'mature' : 'everyone',
      webUrl: found.webUrl
    };
  },

  async getChapters(bookKey) {
    var found = await show(bookKey);
    var chapters = [];
    for (var i = 0; i < found.episodes.length; i++) {
      var episode = found.episodes[i];
      chapters.push({
        key: episode.key,
        title: episode.title,
        durationMs: episode.durationMs,
        publishedAt: episode.publishedAt
      });
    }
    return chapters;
  },

  async resolveMedia(chapterRef) {
    var found = await show(chapterRef && chapterRef.bookKey);
    var wanted = textOf(chapterRef && chapterRef.chapterKey);
    for (var i = 0; i < found.episodes.length; i++) {
      var episode = found.episodes[i];
      if (episode.key !== wanted) continue;
      requireReachable(episode.url, 'that episode');
      // The enclosure address is a permalink: podcast hosts redirect it to wherever the file is
      // served from today, and there is no token and no expiry, so the app may keep this.
      return {
        segments: [
          {
            fileKey: episode.key,
            request: { url: episode.url },
            format: formatOf(episode.url),
            durationMs: episode.durationMs
          }
        ]
      };
    }
    // An episode a feed no longer carries is gone as far as this source is concerned. The app keeps
    // the chapter and its progress rather than losing them (§4.4).
    throw sourceError('NotFound', found.title + ' no longer carries that episode');
  }
};

/**
 * A feed's `<language>` as a BCP 47 tag, or nothing.
 *
 * Feeds write this well ("en", "en-us") and badly ("English", "en_US", "EN"). The contract wants a
 * tag, and a language the app cannot read is worse than none, so anything that is not already a tag
 * after the obvious tidying is dropped rather than guessed at.
 */
function languageOf(value) {
  var text = textOf(value).replace(/_/g, '-').toLowerCase();
  return /^[a-z]{2,3}(-[a-z0-9]{2,8})*$/.test(text) ? text : undefined;
}

/** What the app should call the file, from its address. */
function formatOf(url) {
  var found = /\.([a-z0-9]+)(?:[?#]|$)/i.exec(textOf(url));
  if (!found) return undefined;
  var extension = found[1].toLowerCase();
  if (extension === 'mp3') return 'mp3';
  if (extension === 'm4a') return 'm4a';
  if (extension === 'm4b') return 'm4b';
  if (extension === 'aac') return 'aac';
  if (extension === 'flac') return 'flac';
  if (extension === 'ogg' || extension === 'oga') return 'ogg';
  if (extension === 'opus') return 'opus';
  return undefined;
}

module.exports = { sources: { podcasts: podcasts } };
