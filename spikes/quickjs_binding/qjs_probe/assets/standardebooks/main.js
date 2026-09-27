// Standard Ebooks, as a Kikuyomi source of books to read (SourceAPI 1.1).
//
// Standard Ebooks is a volunteer project that takes public-domain books, corrects and typesets
// them with care, and gives them away. Its own work is dedicated to the public domain under CC0,
// on top of texts that already were.
//
// ## What a book is here
//
// One ebook, keyed by its path on the site after `/ebooks/`: `mary-shelley/frankenstein`, or
// `gustave-flaubert/sentimental-education/m-walter-dunne` where a translator tells two editions
// apart. The path is the site's own permanent address for the book, so it is what stays stable.
//
// ## What a chapter is
//
// One page of the book's text. The site publishes every book a section at a time under
// `/ebooks/<book>/text/<section>`, with a table of contents at `/ebooks/<book>/text` that names
// them in reading order. Each is a chapter, keyed by its last path segment. The title page, the
// imprint and the like are left out: they are the edition's paperwork, not the book.
//
// ## Parsing
//
// With the host's HTML parser. The pages are clean, semantic markup, and a chapter's `<main>` is
// handed to the app as HTML, which turns it into blocks and draws nothing it has not checked.

var BASE = 'https://standardebooks.org';

/** Books a page of the catalogue holds. The site offers 12, 24 and 48. */
var PER_PAGE = 48;

/** Sections of an edition that are about the edition rather than the book. */
var PAPERWORK = {
  titlepage: true,
  halftitlepage: true,
  imprint: true,
  colophon: true,
  uncopyright: true
};

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
 * One page of the site, as text.
 *
 * `http.fetch` returns any status rather than throwing, so the statuses that mean something are read
 * here: 429 and 503 are the site asking for a pause, 404 is a book or section that is not there, 5xx
 * is the site being unwell. Only a failure to connect throws by itself, already as `Network`.
 */
async function getPage(url) {
  var response = await kikuyomi.http.fetch({ url: url, responseType: 'text' });
  var status = response.status;
  if (status === 429 || status === 503) {
    var after = parseInt(textOf(response.headers && response.headers['retry-after']), 10);
    throw sourceError('RateLimited', 'standardebooks.org asked for a pause (' + status + ')',
      isFinite(after) && after > 0 ? { retryAfterMs: after * 1000 } : null);
  }
  if (status === 404) throw sourceError('NotFound', 'standardebooks.org has nothing at ' + url);
  if (status >= 500) throw sourceError('Network', 'standardebooks.org answered ' + status);
  if (status !== 200) {
    throw sourceError('Parse', 'standardebooks.org answered ' + status + ' for ' + url);
  }
  return textOf(response.body) ? response.body : '';
}

/** The key of a book from an address on the site: its path after `/ebooks/`. */
function bookKeyOf(href) {
  var found = /\/ebooks\/([^?#]+?)\/?(?:[?#]|$)/.exec(textOf(href));
  return found ? found[1] : '';
}

/** A book's address, from its key. Each segment is the site's own slug, so nothing is escaped. */
function bookUrl(bookKey) {
  var key = textOf(bookKey);
  if (!/^[a-z0-9-]+(\/[a-z0-9-]+)+$/.test(key)) {
    throw sourceError('NotFound', 'not a Standard Ebooks book: ' + key);
  }
  return BASE + '/ebooks/' + key;
}

// ----------------------------------------------------------------------------------- catalogue

/** One page of the catalogue at [url], as the contract's `PageResult<BookSummary>`. */
async function listing(url) {
  var doc = await kikuyomi.html.parse(await getPage(url), url);
  var items = [];
  var books = doc.select('li[typeof="schema:Book"]');
  for (var i = 0; i < books.length; i++) {
    var book = books[i];
    var key = bookKeyOf(book.attr('about'));
    if (!key) continue;
    var title = book.selectFirst('[property="schema:name"]');
    var authors = [];
    var names = book.select('.author [property="schema:name"]');
    for (var j = 0; j < names.length; j++) {
      var name = names[j].text();
      if (name && authors.indexOf(name) < 0) authors.push(name);
    }
    var cover = book.selectFirst('img');
    items.push({
      key: key,
      title: (title && title.text()) || key,
      authors: authors,
      coverUrl: (cover && cover.absUrl('src')) || undefined
    });
  }
  return { items: items, hasNextPage: doc.selectFirst('a[rel="next"]') !== null };
}

function catalogueUrl(params, page) {
  var query = ['per-page=' + PER_PAGE, 'page=' + Math.max(1, page | 0)];
  for (var name in params) {
    if (Object.prototype.hasOwnProperty.call(params, name) && params[name]) {
      query.push(name + '=' + encodeURIComponent(params[name]));
    }
  }
  return BASE + '/ebooks?' + query.join('&');
}

// ------------------------------------------------------------------------------------- a book

/** The paragraphs of an element as plain text, a blank line between each. */
function paragraphsOf(element) {
  if (!element) return undefined;
  var paragraphs = element.select('p');
  var texts = [];
  for (var i = 0; i < paragraphs.length; i++) {
    var text = paragraphs[i].text();
    if (text) texts.push(text);
  }
  var joined = texts.length ? texts.join('\n\n') : element.text();
  return joined || undefined;
}

/**
 * The book's cover, not its banner.
 *
 * A book's page shows a wide "hero" crop of the cover at its head; the cover itself sits beside it
 * under the same folder as `cover.jpg`, and is what a shelf wants.
 */
function coverOf(doc) {
  var images = doc.select('img');
  for (var i = 0; i < images.length; i++) {
    var src = images[i].absUrl('src');
    if (src && /\/images\/covers\/[^/]+\/[^/]+\/cover(@2x)?\.jpg$/.test(src)) return src;
  }
  var hero = doc.selectFirst('header img');
  var heroSrc = hero && hero.absUrl('src');
  return heroSrc ? heroSrc.replace(/hero(@2x)?\.jpg$/, 'cover.jpg') : undefined;
}

// --------------------------------------------------------------------------------------- source

var standardEbooks = {
  async getPopular(page) {
    return listing(catalogueUrl({ sort: 'popularity' }, page));
  },

  async search(query, page) {
    var text = textOf(query && query.text);
    return listing(catalogueUrl(text ? { query: text } : { sort: 'popularity' }, page));
  },

  async getBookDetails(bookKey) {
    var url = bookUrl(bookKey);
    var doc = await kikuyomi.html.parse(await getPage(url), url);
    var header = doc.selectFirst('article.ebook header') || doc.selectFirst('header');
    var title = doc.selectFirst('h1[property="schema:name"]');
    var authors = [];
    var names = header ? header.select('[property="schema:author"] [property="schema:name"]') : [];
    for (var i = 0; i < names.length; i++) {
      var name = names[i].text();
      if (name && authors.indexOf(name) < 0) authors.push(name);
    }
    var genres = [];
    var subjects = doc.select('a[href^="/subjects/"]');
    for (var j = 0; j < subjects.length; j++) {
      var subject = subjects[j].text();
      if (subject && genres.indexOf(subject) < 0) genres.push(subject);
    }
    return {
      key: textOf(bookKey),
      title: (title && title.text()) || textOf(bookKey),
      authors: authors,
      narrators: [],
      genres: genres,
      description: paragraphsOf(doc.selectFirst('#description [property="schema:description"]')),
      coverUrl: coverOf(doc),
      // Standard Ebooks publishes in English only.
      language: 'en',
      publisher: 'Standard Ebooks',
      // A book here is finished before it is published; nothing arrives a chapter at a time.
      status: 'complete',
      webUrl: url
    };
  },

  async getChapters(bookKey) {
    var url = bookUrl(bookKey) + '/text';
    var doc = await kikuyomi.html.parse(await getPage(url), url);
    var links = doc.select('nav#toc a');
    var chapters = [];
    var seen = {};
    for (var i = 0; i < links.length; i++) {
      var found = /\/text\/([a-z0-9-]+)(?:[?#]|$)/.exec(links[i].absUrl('href') || '');
      if (!found) continue;
      var key = found[1];
      if (PAPERWORK[key] || seen[key]) continue;
      seen[key] = true;
      chapters.push({ key: key, title: links[i].text() || key });
    }
    if (!chapters.length) {
      throw sourceError('Parse', 'standardebooks.org listed no sections for ' + bookKey);
    }
    return chapters;
  },

  async getChapterContent(chapter) {
    var section = textOf(chapter && chapter.chapterKey);
    if (!/^[a-z0-9-]+$/.test(section)) {
      throw sourceError('NotFound', 'not a section of a Standard Ebooks book: ' + section);
    }
    var url = bookUrl(chapter && chapter.bookKey) + '/text/' + section;
    var doc = await kikuyomi.html.parse(await getPage(url), url);
    var main = doc.selectFirst('main');
    if (!main) throw sourceError('Parse', 'standardebooks.org sent no text at ' + url);
    // The section's own markup: the app decodes it into blocks and draws only what it checked.
    return { html: main.html(), baseUrl: url };
  }
};

module.exports = { sources: { standardebooks: standardEbooks } };
