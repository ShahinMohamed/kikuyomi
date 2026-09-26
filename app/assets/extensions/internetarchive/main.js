// The Internet Archive, as a Kikuyomi source (SourceAPI 1.0).
//
// The Archive is not a catalogue of audiobooks; it is a catalogue of everything, some of which is
// audiobooks. Two of its endpoints do all the work here:
//
//   * `advancedsearch.php` takes a Lucene-ish query and returns JSON. It ranks by downloads, which
//     is a real measure of what people listen to — unlike LibriVox, which ranks nothing.
//   * `/metadata/<identifier>` returns an item's metadata and every file in it.
//
// Files are served from `/download/<identifier>/<name>` at a fixed address with no token and no
// expiry, so a resolution never goes stale.
//
// ## The one hard problem
//
// An item holds the same audio several times over. A fifteen-chapter recording is sixty files: a
// VBR MP3, a 128kbps MP3, a 64kbps MP3 and an Ogg Vorbis of each. Listing files naively would give
// a book with sixty chapters, four of which are chapter one.
//
// The Archive says which is which. Every derivative carries `original`, naming the file it was made
// from; the source file carries none. So the files of one chapter are those sharing an
// `original ?? name`, and picking one format per group is what turns sixty files into fifteen
// chapters. Everything else here is reading fields carefully.
//
// ## What is not here
//
// LibriVox items appear in the Archive too, and its own extension reads them from the LibriVox API,
// which knows about sections, readers and projects in a way the Archive's file list does not. Both
// are worth having: this one reaches the far larger part of the Archive that LibriVox never touched.

var SEARCH = 'https://archive.org/advancedsearch.php';
var METADATA = 'https://archive.org/metadata/';
var DOWNLOAD = 'https://archive.org/download/';
var THUMBNAIL = 'https://archive.org/services/img/';

/** What one page of a listing holds. The Archive allows far more; fifty is a screen or two. */
var PAGE_SIZE = 50;

/**
 * The fields a listing asks for.
 *
 * Only what a summary shows. An `advancedsearch` answer carries whatever is asked for and nothing
 * else, so a listing of fifty costs a few kilobytes rather than fifty items' worth of metadata.
 */
var LIST_FIELDS = ['identifier', 'title', 'creator', 'year', 'downloads'];

/**
 * Which audio to take when an item offers the same recording several ways.
 *
 * In order of preference. VBR MP3 first: on the Archive it is usually the best balance of quality
 * against size, and size is not idle here, because §5.2 will download these. Ogg last, because it
 * is the derivative most often missing its track number and title.
 */
var FORMATS = ['VBR MP3', '128Kbps MP3', '64Kbps MP3', 'Ogg Vorbis', 'MP3'];

/**
 * Formats that are a whole book in one file rather than one chapter.
 *
 * Only used when an item has no tracks at all. An item with both would otherwise list its book
 * twice: once in chapters and once entire.
 */
var WHOLE_BOOK_FORMATS = ['Audiobook'];

// ------------------------------------------------------------------------------------ errors

/**
 * One of the contract's error kinds, as a thrown value.
 *
 * The app reads `kind` off whatever is thrown and reacts to it (§3.4); anything it cannot read is
 * `Parse`.
 */
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

/** A value as trimmed text, or '' for anything that is not text worth keeping. */
function textOf(value) {
  if (typeof value === 'string') return value.trim();
  if (typeof value === 'number' && isFinite(value)) return String(value);
  return '';
}

/**
 * The Archive's habit of giving a field as either one value or a list of them, as a list.
 *
 * `creator` is one name on most items and several on some; `collection` is nearly always several.
 * Reading both shapes here means nothing below has to ask which it got.
 */
function listOf(value) {
  if (Array.isArray(value)) {
    var kept = [];
    for (var i = 0; i < value.length; i++) {
      var text = textOf(value[i]);
      if (text) kept.push(text);
    }
    return kept;
  }
  var single = textOf(value);
  return single ? [single] : [];
}

/**
 * A file's `length`, in milliseconds.
 *
 * The Archive writes it three ways and one item uses more than one of them: `70.69` seconds on the
 * source file, `01:10` on a derivative, `1:02:33` on anything over an hour. Reading only one shape
 * would leave most chapters with no duration, and §4.5 would then estimate a book whose real length
 * was sitting in the answer all along.
 */
function msFromLength(value) {
  var text = textOf(value);
  if (!text) return undefined;
  var parts = text.split(':');
  var seconds = 0;
  if (parts.length === 1) {
    seconds = parseFloat(parts[0]);
  } else {
    for (var i = 0; i < parts.length; i++) {
      var part = parseFloat(parts[i]);
      if (!isFinite(part)) return undefined;
      seconds = seconds * 60 + part;
    }
  }
  if (!isFinite(seconds) || seconds <= 0) return undefined;
  return Math.round(seconds * 1000);
}

/** The named entities an Archive description actually uses, plus the five any document may. */
var ENTITIES = {
  amp: '&', lt: '<', gt: '>', quot: '"', apos: "'",
  nbsp: ' ', hellip: '\u2026', mdash: '\u2014', ndash: '\u2013',
  lsquo: '\u2018', rsquo: '\u2019', ldquo: '\u201c', rdquo: '\u201d',
  laquo: '\u00ab', raquo: '\u00bb', deg: '\u00b0', middot: '\u00b7',
  eacute: '\u00e9', egrave: '\u00e8', agrave: '\u00e0', ccedil: '\u00e7',
  uuml: '\u00fc', ouml: '\u00f6', auml: '\u00e4', szlig: '\u00df',
  ntilde: '\u00f1', copy: '\u00a9', reg: '\u00ae', trade: '\u2122'
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

/**
 * A description as plain text.
 *
 * The Archive's descriptions are HTML as often as not, and the app shows this as text.
 *
 * Stripped here rather than parsed, for one blunt reason: `kikuyomi.html.parse` returns a promise,
 * and a description is read inside `getBookDetails` where awaiting one more round trip to the host
 * for every book is not worth it. Reading it synchronously would give back a promise and quietly
 * show the markup. The LibriVox extension does the same, and this follows it.
 */
function plainText(value) {
  var html = textOf(value);
  if (!html) return undefined;
  var text = html
    .replace(/\r\n?/g, '\n')
    .replace(/<\s*br\s*\/?\s*>/gi, '\n')
    .replace(/<\s*\/\s*(p|div|li|tr|h[1-6]|blockquote)\s*>/gi, '\n')
    .replace(/<[^>]*>/g, '');
  text = decodeEntities(text);
  // Every control character but the newlines just introduced becomes a space.
  text = text.replace(/[\u0000-\u0009\u000b-\u001f\u007f]/g, ' ');
  var lines = text.split('\n');
  for (var i = 0; i < lines.length; i++) {
    lines[i] = lines[i].replace(/\s+/g, ' ').trim();
  }
  text = lines.join('\n').replace(/\n{3,}/g, '\n\n').trim();
  if (text.length > 20000) text = text.slice(0, 20000).trim();
  return text || undefined;
}

/**
 * The Archive's subjects, as separate genres.
 *
 * `subject` arrives as a list on some items and as one semicolon-separated string on others —
 * `librivox; audiobooks; poetry; satire` is one field, not four, until it is split. Left whole it
 * would draw as a single chip the width of the screen.
 *
 * Only semicolons. Commas appear inside subjects that are names, and splitting `Melville, Herman`
 * into two genres would be worse than leaving a long one alone.
 */
function genresOf(value) {
  var genres = [];
  var listed = listOf(value);
  for (var i = 0; i < listed.length; i++) {
    var parts = listed[i].split(';');
    for (var j = 0; j < parts.length; j++) {
      var genre = parts[j].trim();
      if (genre && genres.indexOf(genre) < 0) genres.push(genre);
    }
  }
  return genres;
}

/** The first four digits of a date, which is all the app shows and all the Archive agrees on. */
function yearOf(item) {
  var date = textOf(item.year) || textOf(item.date);
  var found = /\d{4}/.exec(date);
  return found ? found[0] : undefined;
}

/**
 * A language tag the app can read.
 *
 * The Archive writes languages as it finds them: `eng`, `English`, `en`. The app wants a tag, so
 * the handful that actually appear are mapped and anything else is passed through only if it
 * already looks like one. A wrong tag is worse than none.
 */
var LANGUAGES = {
  eng: 'en', english: 'en', ger: 'de', deu: 'de', german: 'de',
  fre: 'fr', fra: 'fr', french: 'fr', spa: 'es', spanish: 'es',
  ita: 'it', italian: 'it', por: 'pt', portuguese: 'pt',
  rus: 'ru', russian: 'ru', dut: 'nl', nld: 'nl', dutch: 'nl',
  lat: 'la', latin: 'la', chi: 'zh', zho: 'zh', chinese: 'zh',
  jpn: 'ja', japanese: 'ja', kor: 'ko', korean: 'ko', ara: 'ar', arabic: 'ar'
};

function languageTagOf(value) {
  var languages = listOf(value);
  if (!languages.length) return undefined;
  var first = languages[0].toLowerCase();
  if (Object.prototype.hasOwnProperty.call(LANGUAGES, first)) return LANGUAGES[first];
  return /^[a-z]{2}(-[A-Za-z0-9]+)*$/.test(languages[0]) ? languages[0] : undefined;
}

// -------------------------------------------------------------------------------------- http

/**
 * One GET, as JSON.
 *
 * `http.fetch` returns any status rather than throwing, so the statuses that mean something are
 * read here. Only a failure to connect throws by itself, already as `Network`.
 */
async function getJson(url) {
  var response = await kikuyomi.http.fetch({ url: url, responseType: 'json' });
  var status = response.status;
  if (status === 429 || status === 503) {
    var after = parseInt(textOf(response.headers && response.headers['retry-after']), 10);
    throw sourceError('RateLimited', 'archive.org asked for a pause (' + status + ')',
      isFinite(after) && after > 0 ? { retryAfterMs: after * 1000 } : null);
  }
  if (status === 404) throw sourceError('NotFound', 'archive.org has nothing at ' + url);
  if (status >= 500) throw sourceError('Network', 'archive.org answered ' + status);
  if (status !== 200) {
    throw sourceError('Parse', 'archive.org answered ' + status + ' for ' + url);
  }
  var body = response.body;
  if (!body || typeof body !== 'object') {
    throw sourceError('Parse', 'the answer from archive.org is not an object');
  }
  return body;
}

// ------------------------------------------------------------------------------------ listing

var COLLECTION_FIELD = 'collection';

/**
 * Which part of the Archive to look in.
 *
 * The Archive holds five million audio items and most of them are not books. A listener opening
 * this source wants the audiobooks, so that is the default; the other two are the collections
 * people actually come to the Archive for after that.
 */
var COLLECTIONS = {
  books: 'collection:(audio_bookspoetry)',
  radio: 'collection:(oldtimeradio)',
  everything: 'mediatype:(audio)'
};

function chosenCollection(query) {
  var filters = query && query.filters;
  var chosen = filters ? textOf(filters[COLLECTION_FIELD]) : '';
  return Object.prototype.hasOwnProperty.call(COLLECTIONS, chosen)
    ? COLLECTIONS[chosen]
    : COLLECTIONS.books;
}

/**
 * The text a listener typed, as something the Archive will match.
 *
 * Quoted and matched against title and creator rather than passed through. The search box is not a
 * query language: somebody typing `AND` or a stray bracket means those characters, and an
 * unbalanced one would otherwise fail the whole request rather than find nothing.
 */
function textQuery(text) {
  var quoted = '"' + text.replace(/"/g, ' ') + '"';
  return '(title:(' + quoted + ') OR creator:(' + quoted + '))';
}

function listUrl(query, page, sorted) {
  var url = SEARCH + '?q=' + encodeURIComponent(query) +
    '&rows=' + PAGE_SIZE + '&page=' + page + '&output=json';
  for (var i = 0; i < LIST_FIELDS.length; i++) {
    url += '&fl%5B%5D=' + encodeURIComponent(LIST_FIELDS[i]);
  }
  if (sorted) url += '&sort%5B%5D=' + encodeURIComponent(sorted);
  return url;
}

/**
 * The documents in a search answer.
 *
 * A search matching nothing is a normal thing to do and comes back as an empty `docs`, not an
 * error. An answer with no `response` at all is the Archive being unwell in a way this cannot read.
 */
function docsOf(body) {
  var response = body.response;
  if (!response || typeof response !== 'object') {
    throw sourceError('Parse', 'archive.org answered without a response');
  }
  return Array.isArray(response.docs) ? response.docs : [];
}

function summaryOf(doc) {
  var key = textOf(doc.identifier);
  if (!key) return null;
  var authors = listOf(doc.creator);
  return {
    key: key,
    title: textOf(doc.title) || key,
    authors: authors.length ? authors : undefined,
    coverUrl: THUMBNAIL + encodeURIComponent(key)
  };
}

function summariesOf(docs) {
  var items = [];
  for (var i = 0; i < docs.length; i++) {
    var summary = summaryOf(docs[i]);
    if (summary) items.push(summary);
    else kikuyomi.log.warn('skipping a search result with no identifier');
  }
  return items;
}

async function listPage(query, page, sorted) {
  var docs = docsOf(await getJson(listUrl(query, page, sorted)));
  return { items: summariesOf(docs), hasNextPage: docs.length >= PAGE_SIZE };
}

// --------------------------------------------------------------------------------------- item

/**
 * One item's metadata, kept for as long as the listener is looking at it.
 *
 * Details, chapters and every one of a book's `resolveMedia` calls all read the same document, and
 * without this a fifteen-chapter book would fetch it sixteen times. Kept small and briefly: this is
 * a cache for one screen, not a store.
 */
var CACHE_MS = 5 * 60 * 1000;
var CACHE_MAX = 8;
var items = Object.create(null);

function cachedItem(key, now) {
  var held = items[key];
  if (!held) return null;
  if (now - held.at > CACHE_MS) {
    delete items[key];
    return null;
  }
  return held.value;
}

function keepItem(key, value) {
  var keys = Object.keys(items);
  // Oldest out first, so a listener moving through a catalogue does not grow this without bound.
  while (keys.length >= CACHE_MAX) {
    var oldest = keys[0];
    for (var i = 1; i < keys.length; i++) {
      if (items[keys[i]].at < items[oldest].at) oldest = keys[i];
    }
    delete items[oldest];
    keys = Object.keys(items);
  }
  items[key] = { at: Date.now(), value: value };
}

async function itemById(bookKey) {
  var key = textOf(bookKey);
  if (!key) throw sourceError('NotFound', 'no item was named');
  var held = cachedItem(key, Date.now());
  if (held) return held;

  var body = await getJson(METADATA + encodeURIComponent(key));
  // The metadata endpoint answers 200 with `{}` for an identifier that does not exist, rather than
  // 404. Without this a missing item would read as one with no files and no title.
  if (!body.metadata || typeof body.metadata !== 'object') {
    throw sourceError('NotFound', 'archive.org has no item called ' + key);
  }
  keepItem(key, body);
  return body;
}

// -------------------------------------------------------------------------------------- files

function isAudio(file, formats) {
  return formats.indexOf(textOf(file && file.format)) >= 0;
}

/**
 * The item's audio files, one group per chapter, in playing order.
 *
 * The group key is `original ?? name`: a derivative names the file it was made from, and the source
 * file names none, so every rendering of one chapter shares a key. Within a group the best format
 * available wins, and the fields that describe the chapter — its track number, its title — are taken
 * from whichever file in the group has them, because the Ogg derivative usually has neither.
 */
function chaptersOf(body) {
  var files = Array.isArray(body.files) ? body.files : [];
  var groups = Object.create(null);
  var order = [];

  for (var i = 0; i < files.length; i++) {
    var file = files[i];
    if (!isAudio(file, FORMATS)) continue;
    var name = textOf(file.name);
    if (!name) continue;
    var key = textOf(file.original) || name;
    if (!groups[key]) {
      groups[key] = { key: key, files: [], track: undefined, title: '', durationMs: undefined };
      order.push(key);
    }
    var group = groups[key];
    group.files.push(file);
    if (group.track === undefined) {
      var track = parseInt(textOf(file.track), 10);
      if (isFinite(track)) group.track = track;
    }
    if (!group.title) group.title = textOf(file.title);
    if (group.durationMs === undefined) group.durationMs = msFromLength(file.length);
  }

  var chapters = [];
  for (var j = 0; j < order.length; j++) chapters.push(groups[order[j]]);

  // By track where the item numbers its files, which is most of them, and by name where it does
  // not. Sorting by name alone would put chapter 10 before chapter 2.
  chapters.sort(function (a, b) {
    if (a.track !== undefined && b.track !== undefined && a.track !== b.track) {
      return a.track - b.track;
    }
    if (a.track !== undefined && b.track === undefined) return -1;
    if (a.track === undefined && b.track !== undefined) return 1;
    return a.key < b.key ? -1 : a.key > b.key ? 1 : 0;
  });
  return chapters;
}

/**
 * An item with no tracks, as one chapter holding the whole book.
 *
 * Some items are published as a single M4B and nothing else. Listing nothing for those would hide a
 * book the Archive plainly has; §4.5 reads the file's own markers once it is played.
 */
function wholeBookOf(body) {
  var files = Array.isArray(body.files) ? body.files : [];
  for (var i = 0; i < files.length; i++) {
    if (!isAudio(files[i], WHOLE_BOOK_FORMATS)) continue;
    var name = textOf(files[i].name);
    if (!name) continue;
    return {
      key: name,
      files: [files[i]],
      track: 1,
      title: textOf(body.metadata && body.metadata.title) || name,
      durationMs: msFromLength(files[i].length)
    };
  }
  return null;
}

function partsOf(body) {
  var chapters = chaptersOf(body);
  if (chapters.length) return chapters;
  var whole = wholeBookOf(body);
  return whole ? [whole] : [];
}

/** The best-rated file of a group, and what format it is. */
function bestFile(group) {
  for (var i = 0; i < FORMATS.length; i++) {
    for (var j = 0; j < group.files.length; j++) {
      if (textOf(group.files[j].format) === FORMATS[i]) return group.files[j];
    }
  }
  for (var k = 0; k < WHOLE_BOOK_FORMATS.length; k++) {
    for (var l = 0; l < group.files.length; l++) {
      if (textOf(group.files[l].format) === WHOLE_BOOK_FORMATS[k]) return group.files[l];
    }
  }
  return group.files[0];
}

/** What the app should call a file's container, from its name. */
function formatOf(name) {
  var found = /\.([a-z0-9]+)$/i.exec(name);
  if (!found) return undefined;
  var extension = found[1].toLowerCase();
  if (extension === 'mp3') return 'mp3';
  if (extension === 'ogg' || extension === 'oga') return 'ogg';
  if (extension === 'm4b' || extension === 'm4a') return 'm4b';
  if (extension === 'flac') return 'flac';
  if (extension === 'wav') return 'wav';
  return undefined;
}

/** A file's address. Each segment is encoded, because Archive file names hold spaces and brackets. */
function urlOf(identifier, name) {
  var parts = name.split('/');
  for (var i = 0; i < parts.length; i++) parts[i] = encodeURIComponent(parts[i]);
  return DOWNLOAD + encodeURIComponent(identifier) + '/' + parts.join('/');
}

/** A chapter's title, when the file did not carry one. */
function titleOf(group, index) {
  if (group.title) return group.title;
  var name = group.key.split('/').pop();
  var withoutExtension = name.replace(/\.[a-z0-9]+$/i, '');
  return withoutExtension || ('Part ' + (index + 1));
}

// ------------------------------------------------------------------------------------- source

var internetarchive = {
  async getPopular(page) {
    // Downloads, descending. Unlike most catalogues the Archive counts these honestly and publishes
    // them, so this is a real answer to "what do people listen to" rather than a stand-in.
    return listPage(COLLECTIONS.books, page, 'downloads desc');
  },

  getFilters() {
    return [
      { kind: 'header', label: 'Search the Internet Archive' },
      {
        kind: 'select',
        key: COLLECTION_FIELD,
        label: 'Look in',
        options: [
          { value: 'books', label: 'Audio books and poetry' },
          { value: 'radio', label: 'Old time radio' },
          { value: 'everything', label: 'All audio' }
        ],
        default: 'books'
      }
    ];
  },

  async search(query, page) {
    var where = chosenCollection(query);
    var text = textOf(query && query.text);
    // Only a collection was chosen, which narrows nothing on its own: show what is most listened to
    // in it, which is the same thing the source opens on.
    if (!text) return listPage(where, page, 'downloads desc');
    // Ranked by the Archive's own relevance, which is what a search should be ordered by; asking
    // for downloads as well would bury an exact match under a popular near-miss.
    return listPage(where + ' AND ' + textQuery(text), page);
  },

  async getBookDetails(bookKey) {
    var body = await itemById(bookKey);
    var item = body.metadata;
    var title = textOf(item.title);
    if (!title) throw sourceError('Parse', 'item ' + bookKey + ' has no title');

    var parts = partsOf(body);
    var total = 0;
    var timed = true;
    for (var i = 0; i < parts.length; i++) {
      if (parts[i].durationMs === undefined) timed = false;
      else total += parts[i].durationMs;
    }

    return {
      key: textOf(item.identifier) || textOf(bookKey),
      title: title,
      authors: listOf(item.creator),
      // The Archive has no narrator field. Some items name a reader in `creator` alongside the
      // author and there is no way to tell which is which, so nothing is claimed.
      description: plainText(item.description),
      coverUrl: THUMBNAIL + encodeURIComponent(textOf(item.identifier) || textOf(bookKey)),
      genres: genresOf(item.subject),
      language: languageTagOf(item.language),
      publisher: textOf(item.publisher) || undefined,
      publishedDate: yearOf(item),
      // Only when every part was timed. A part-total would read as a short book rather than an
      // unknown one, and §4.5 would take it as fact.
      totalDurationMs: timed && total > 0 ? total : undefined,
      // An Archive item is uploaded whole. Nothing there is released a chapter at a time.
      status: 'complete',
      webUrl: 'https://archive.org/details/' +
        encodeURIComponent(textOf(item.identifier) || textOf(bookKey))
    };
  },

  async getChapters(bookKey) {
    var body = await itemById(bookKey);
    var parts = partsOf(body);
    if (!parts.length) {
      throw sourceError('NotFound',
        'archive.org item ' + bookKey + ' holds no audio this app can play');
    }
    var chapters = [];
    for (var i = 0; i < parts.length; i++) {
      chapters.push({
        key: parts[i].key,
        title: titleOf(parts[i], i),
        durationMs: parts[i].durationMs
      });
    }
    return chapters;
  },

  async resolveMedia(chapter) {
    var bookKey = textOf(chapter && chapter.bookKey);
    var body = await itemById(bookKey);
    var wanted = textOf(chapter && chapter.chapterKey);
    var parts = partsOf(body);
    var group = null;
    for (var i = 0; i < parts.length; i++) {
      if (parts[i].key === wanted) {
        group = parts[i];
        break;
      }
    }
    if (!group) {
      throw sourceError('NotFound', 'item ' + bookKey + ' has no part ' + wanted);
    }
    var file = bestFile(group);
    var name = textOf(file && file.name);
    if (!name) {
      throw sourceError('NotFound', 'part ' + wanted + ' of ' + bookKey + ' has no file');
    }
    // The Archive serves these from a fixed address with no token and no expiry, so there is no
    // `expiresAt`: the app may keep this resolution for as long as it likes.
    return {
      segments: [
        {
          fileKey: name,
          request: { url: urlOf(bookKey, name) },
          format: formatOf(name),
          durationMs: group.durationMs
        }
      ]
    };
  }
};

module.exports = { sources: { internetarchive: internetarchive } };
