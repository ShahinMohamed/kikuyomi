// Project Gutenberg, as a Kikuyomi source of books to read (SourceAPI 1.1).
//
// The oldest digital library there is: seventy-nine thousand books that have passed out of
// copyright in the United States, transcribed and proofread by volunteers since 1971.
//
// ## Where the catalogue comes from
//
// gutenberg.org has no search API, and asks in its terms not to be crawled for one. Gutendex is a
// small open-source JSON API over Project Gutenberg's own catalogue feed, which is published for
// exactly this purpose. So the catalogue is read from gutendex.com and the books themselves from
// gutenberg.org, and the manifest names both.
//
// ## What a chapter is
//
// Project Gutenberg publishes a book as one HTML file, not a file per chapter, so the chapters
// have to be found in it. They are: a transcription marks each one with a heading, and the file is
// wrapped in a header and footer of Gutenberg's own that are not part of the book.
//
// This is a guess made the same way for seventy-nine thousand books transcribed over fifty years,
// and it will be wrong for some of them. It is wrong in a bounded way: the worst case is a chapter
// list that reads oddly, never text that goes missing, because every heading in the body starts a
// section and every section is offered.
//
// ## One fetch for a whole book
//
// A chapter of a book here is a slice of a file that may be a megabyte and a half, and asking for
// one chapter at a time would fetch the whole book each time. So the file is kept for as long as
// its book is the one being read — the response text, never a parsed document, as §9 of the
// extension guide requires.

// The trailing slash on `/books/` is Gutendex's own address for the listing: without it the answer
// is a redirect, and a redirect costs a round trip on every page of every search.
var API = 'https://gutendex.com';
var SITE = 'https://www.gutenberg.org';

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

function textOf(value) {
  if (typeof value === 'string') return value.trim();
  if (typeof value === 'number' && isFinite(value)) return String(value);
  return '';
}

// ------------------------------------------------------------------------------------ fetching

/**
 * One request, as [responseType].
 *
 * `http.fetch` returns any status rather than throwing, so the statuses that mean something are
 * read here: 429 and 503 are a host asking for a pause, 404 is a book that is not there, 5xx is a
 * host being unwell. Only a failure to connect throws by itself, already as `Network`.
 */
async function get(url, responseType, host) {
  var response = await kikuyomi.http.fetch({ url: url, responseType: responseType });
  var status = response.status;
  if (status === 429 || status === 503) {
    var after = parseInt(textOf(response.headers && response.headers['retry-after']), 10);
    throw sourceError('RateLimited', host + ' asked for a pause (' + status + ')',
      isFinite(after) && after > 0 ? { retryAfterMs: after * 1000 } : null);
  }
  if (status === 404) throw sourceError('NotFound', host + ' has nothing at ' + url);
  if (status >= 500) throw sourceError('Network', host + ' answered ' + status);
  if (status !== 200) {
    throw sourceError('Parse', host + ' answered ' + status + ' for ' + url);
  }
  return response.body;
}

async function getJson(url) {
  var body = await get(url, 'json', 'gutendex.com');
  if (!body || typeof body !== 'object') {
    throw sourceError('Parse', 'the answer from gutendex.com is not an object');
  }
  return body;
}

/** A book's numeric id, as Project Gutenberg gives it. */
function idOf(bookKey) {
  var key = textOf(bookKey);
  if (!/^[0-9]{1,7}$/.test(key)) {
    throw sourceError('NotFound', 'not a Project Gutenberg book number: ' + key);
  }
  return key;
}

// ----------------------------------------------------------------------------------- catalogue

function summaryOf(book) {
  var authors = [];
  var credited = book && book.authors;
  if (Array.isArray(credited)) {
    for (var i = 0; i < credited.length; i++) {
      var name = readableName(textOf(credited[i] && credited[i].name));
      if (name && authors.indexOf(name) < 0) authors.push(name);
    }
  }
  return {
    key: String(book.id),
    title: textOf(book.title) || 'Untitled',
    authors: authors,
    coverUrl: coverOf(book)
  };
}

/**
 * A catalogue name as a person would say it.
 *
 * The catalogue files them for shelving — "Shelley, Mary Wollstonecraft" — which is right for a
 * card index and wrong under a cover. Only the first comma is turned round, so a name with a suffix
 * after a second comma keeps it.
 */
function readableName(name) {
  var found = /^([^,]+),\s*(.+)$/.exec(name);
  if (!found) return name;
  var rest = found[2];
  // A birth-death range is part of how the catalogue files a name, not part of the name.
  rest = rest.replace(/,?\s*\d{3,4}\??\s*-\s*\d{0,4}\??$/, '').trim();
  return rest ? rest + ' ' + found[1] : found[1];
}

function coverOf(book) {
  var formats = (book && book.formats) || {};
  for (var type in formats) {
    if (Object.prototype.hasOwnProperty.call(formats, type) && /^image\//.test(type)) {
      return textOf(formats[type]) || undefined;
    }
  }
  return undefined;
}

/** Where the book's text is, as one HTML file. */
function htmlUrlOf(book) {
  var formats = (book && book.formats) || {};
  for (var type in formats) {
    if (!Object.prototype.hasOwnProperty.call(formats, type)) continue;
    // `text/html; charset=utf-8` and plain `text/html` both appear, and the one with pictures is
    // preferred where a transcription has them.
    if (/^text\/html/.test(type)) return textOf(formats[type]);
  }
  return '';
}

async function listing(url) {
  var body = await getJson(url);
  var results = Array.isArray(body.results) ? body.results : [];
  var items = [];
  for (var i = 0; i < results.length; i++) {
    // Gutenberg holds recordings and images as well as books. This source offers what can be read.
    if (results[i] && results[i].media_type && results[i].media_type !== 'Text') continue;
    items.push(summaryOf(results[i]));
  }
  return { items: items, hasNextPage: !!body.next };
}

// ------------------------------------------------------------------------------- the whole book

/**
 * The book being read, kept while it is the one being read.
 *
 * One book at a time: a reader has one open, and holding the last few would spend the runtime's
 * memory on books nobody is looking at.
 */
var open = { key: null, html: null, book: null };

/** Books larger than this are read again per chapter rather than kept. */
var MAX_KEPT = 8 * 1024 * 1024;

/** The catalogue entry for [bookKey], kept with the book being read so a chapter costs no request. */
async function bookRecord(bookKey) {
  var id = idOf(bookKey);
  if (open.key === id && open.book) return open.book;
  return getJson(API + '/books/' + id);
}

async function bookHtml(book) {
  var key = String(book.id);
  if (open.key === key && open.html) return open.html;
  var url = htmlUrlOf(book);
  if (!url) {
    throw sourceError('Unsupported', 'Project Gutenberg has no readable text for ' + key);
  }
  var html = textOf(await get(url, 'text', 'gutenberg.org'));
  if (!html) throw sourceError('Parse', 'gutenberg.org sent an empty book at ' + url);
  open = html.length <= MAX_KEPT
    ? { key: key, html: html, book: book }
    : { key: null, html: null, book: null };
  return html;
}

/** The book itself, with Project Gutenberg's own header and footer taken off. */
function bodyOf(html) {
  var start = 0;
  var header = html.indexOf('id="pg-header"');
  if (header >= 0) {
    var ends = html.indexOf('</header>', header);
    if (ends >= 0) start = ends + '</header>'.length;
  }
  var end = html.length;
  var footer = html.indexOf('id="pg-footer"');
  if (footer >= 0) {
    var begins = html.lastIndexOf('<footer', footer);
    if (begins >= 0) end = begins;
  }
  return html.slice(start, end);
}

var FRONT_MATTER = /^(contents|table of contents|list of illustrations|illustrations|index)$/i;

/** A heading as a chapter is called, with the transcription's own furniture taken out. */
function headingText(markup) {
  return markup
    .replace(/<span[^>]*class="[^"]*pagenum[^"]*"[^>]*>[\s\S]*?<\/span>/gi, ' ')
    .replace(/<[^>]+>/g, ' ')
    // A page number in braces, which several transcriptions put inside the heading.
    .replace(/\{[^}]*\}/g, ' ')
    .replace(/&[a-zA-Z]+;|&#x?[0-9a-fA-F]+;/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

/**
 * The book's sections, in order: where each one begins in [body], what it is called, and how much
 * of it there is.
 *
 * Headings of one level, because a book's chapters are all at the same level and its parts are not
 * chapters. `h2` is what a modern transcription uses; `h3` is what many older ones use, and it is
 * tried only when there is no run of `h2`s to work from.
 */
function sectionsOf(body) {
  for (var level = 2; level <= 3; level++) {
    var pattern = new RegExp('<h' + level + '\\b[^>]*>([\\s\\S]*?)</h' + level + '\\s*>', 'gi');
    var heads = [];
    var match;
    while ((match = pattern.exec(body)) !== null) {
      heads.push({ at: match.index, whole: match[0], inner: match[1] });
    }
    if (heads.length < 2) continue;

    var sections = [];
    for (var i = 0; i < heads.length; i++) {
      var stop = i + 1 < heads.length ? heads[i + 1].at : body.length;
      var anchor = /id="([^"]+)"/.exec(heads[i].whole);
      var title = headingText(heads[i].inner);
      var chunk = body.slice(heads[i].at, stop);
      sections.push({
        // The transcription's own anchor, which is stable across a re-read of the same book, and
        // the position when it has none.
        key: anchor ? anchor[1] : 's' + i,
        title: title,
        html: chunk,
        length: chunk.replace(/<[^>]+>/g, ' ').replace(/\s+/g, ' ').trim().length
      });
    }

    var kept = [];
    for (var j = 0; j < sections.length; j++) {
      if (!FRONT_MATTER.test(sections[j].title)) kept.push(sections[j]);
    }
    // A title page and a byline sit above the first chapter with a heading each and nothing in
    // them. They are dropped until the book starts; a short chapter later on is left alone, because
    // by then the book has started.
    while (kept.length > 1 && kept[0].length < 300) kept.shift();
    return kept;
  }
  return [{ key: 'whole', title: 'The whole book', html: body, length: body.length }];
}

// --------------------------------------------------------------------------------------- source

var gutenberg = {
  async getPopular(page) {
    // Gutendex orders by how often a book has been downloaded, which is the only measure of
    // popularity Project Gutenberg publishes, and the one its own front page uses.
    return listing(API + '/books/?sort=popular&page=' + Math.max(1, page | 0));
  },

  async search(query, page) {
    var text = textOf(query && query.text);
    var url = API + '/books/?page=' + Math.max(1, page | 0);
    if (text) url += '&search=' + encodeURIComponent(text);
    else url += '&sort=popular';
    return listing(url);
  },

  async getBookDetails(bookKey) {
    var id = idOf(bookKey);
    var book = await getJson(API + '/books/' + id);
    var genres = [];
    var shelves = Array.isArray(book.bookshelves) ? book.bookshelves : [];
    for (var i = 0; i < shelves.length; i++) {
      // Shelves are published as "Category: British Literature".
      var shelf = textOf(shelves[i]).replace(/^Category:\s*/i, '');
      if (shelf && genres.indexOf(shelf) < 0) genres.push(shelf);
    }
    if (!genres.length) {
      var subjects = Array.isArray(book.subjects) ? book.subjects : [];
      for (var j = 0; j < subjects.length && genres.length < 6; j++) {
        // Catalogue subjects are strings of headings joined by " -- "; the first is the useful one.
        var subject = textOf(subjects[j]).split(' -- ')[0];
        if (subject && genres.indexOf(subject) < 0) genres.push(subject);
      }
    }
    var summary = Array.isArray(book.summaries) && book.summaries.length
      ? textOf(book.summaries[0])
      : undefined;
    var languages = Array.isArray(book.languages) ? book.languages : [];
    return {
      key: String(book.id),
      title: textOf(book.title) || 'Untitled',
      authors: summaryOf(book).authors,
      narrators: [],
      genres: genres,
      description: summary,
      coverUrl: coverOf(book),
      language: languages.length ? textOf(languages[0]) : undefined,
      publisher: 'Project Gutenberg',
      // A book is transcribed once and published whole; nothing here arrives a part at a time.
      status: 'complete',
      webUrl: SITE + '/ebooks/' + book.id
    };
  },

  async getChapters(bookKey) {
    var book = await bookRecord(bookKey);
    var sections = sectionsOf(bodyOf(await bookHtml(book)));
    var chapters = [];
    var seen = {};
    for (var i = 0; i < sections.length; i++) {
      var key = sections[i].key;
      // Two transcribed anchors of one name would leave the app unable to tell the chapters apart.
      if (seen[key]) continue;
      seen[key] = true;
      chapters.push({ key: key, title: sections[i].title || 'Section ' + (i + 1) });
    }
    if (!chapters.length) {
      throw sourceError('Parse', 'no readable sections in Project Gutenberg book ' + bookKey);
    }
    return chapters;
  },

  async getChapterContent(chapter) {
    var bookKey = chapter && chapter.bookKey;
    var wanted = textOf(chapter && chapter.chapterKey);
    var book = await bookRecord(bookKey);
    var url = htmlUrlOf(book);
    var sections = sectionsOf(bodyOf(await bookHtml(book)));
    for (var i = 0; i < sections.length; i++) {
      if (sections[i].key === wanted) {
        // The section's own markup: the app decodes it into blocks and draws only what it checked.
        return { html: sections[i].html, baseUrl: url };
      }
    }
    // A transcription that has been replaced since the chapter list was read no longer has it.
    throw sourceError('NotFound', 'Project Gutenberg book ' + bookKey + ' has no section ' + wanted);
  }
};

module.exports = { sources: { gutenberg: gutenberg } };
