# A prompt for having an AI write a Kikuyomi ebook extension

The counterpart to [`extension-authoring-prompt.md`](extension-authoring-prompt.md), which is for
sources of books to **listen to**. This one is for sources of books to **read**.

Paste the text below into a coding assistant, attach
[`docs/writing-an-extension.md`](writing-an-extension.md), and give it the site's URL. Everything
between the rules is the prompt; nothing above or below it needs to go across.

It is built around two failure modes rather than one.

The first is the same as for audiobooks: a model asked to write a scraper for a site it cannot see
will produce a plausible file full of invented selectors that compiles, installs, and returns
nothing. So the central rule is again **do not guess markup; ask for it.**

The second is particular to books you read. A source of text can take one of three shapes, and the
shape is not a detail to be settled while writing — it decides which methods exist, which contract
version the manifest targets, and whether the app fetches chapters or downloads a file. A model that
starts writing before deciding will produce an extension for the shape it has seen most often, which
for most sites is the wrong one. So the prompt makes that decision Step 0, and asks for it to be
stated and justified before a line is written.

The three shapes, since they are the whole of it:

| The site publishes | Shape | Contract |
| --- | --- | --- |
| A page per chapter | **A** | 1.1, `getChapterContent` |
| The whole book on one page | **B** | 1.1, chapters found inside that page |
| An EPUB to download, and no readable text | **C** | 1.2, `resolveBook` behind `bookFile` |

Shape B is the one worth knowing about in advance, because it looks like shape A from a distance
and is not. Project Gutenberg is shape B: seventy-nine thousand books, each one HTML file with the
chapters inside it. The extension for it finds the chapters by splitting that file, and the rules
for doing that safely are in the prompt.

---

  You are writing a **source extension for Kikuyomi**, a cross-platform player and reader whose
  sources come from installable JavaScript extensions. This source is for books to **read**. I have
  attached `writing-an-extension.md`. That document is the complete and authoritative contract:
  every type, every host function, every validation rule and every limit. Treat it as the
  specification and do not infer anything from other extension systems you know — Mihon, Tachiyomi,
  Calibre, Readium, KOReader plugins — because the shapes are different and the differences are
  silent.

  **The site is:** `<URL>`

  ## Step 0 — decide what shape this source is, before anything else

  A source of text takes one of three shapes. Work out which, say which, and say why. Everything
  else follows from it, and getting it wrong is not a bug you fix later — it is a different
  extension.

  **Shape A — a page per chapter.** The site has a readable page for each chapter, at its own URL.
  Target `apiVersion` `"1.1"`, declare `"kind": "text"`, implement `getChapters` and
  `getChapterContent`.

  **Shape B — the whole book on one page.** The site publishes each book as a single document with
  every chapter in it. Same contract as A, but `getChapters` finds the chapters *inside* that
  document and `getChapterContent` returns a slice of it. Read the rules for this below; it has
  traps the other shapes do not.

  **Shape C — a file to download.** The site offers an EPUB and no readable text on the site
  itself. Target `apiVersion` `"1.2"`, declare `"kind": "text"` **and** the `bookFile` capability,
  and implement `resolveBook`. Do **not** implement `getChapterContent`. `getChapters` will never be
  called: the chapters are the ones inside the file, and the app reads them from its spine.

  If a site offers both readable pages and an EPUB, prefer A or B. Chapters arrive as they are read,
  where a file must be downloaded whole before the first page.

  ## Step 1 — investigate before you write anything

  Do not write code yet. First establish, from the site itself:

  1. Whether it has a JSON API, or an **OPDS** feed — an ebook catalogue format many of these sites
     publish and few advertise. Try `/opds`, `/catalog.atom`, `/feed`, `/wp-json/wp/v2/`, `/api/`,
     a sitemap, or an `application/ld+json` block in the page source. A feed is always preferable to
     scraping: fewer requests, stable field names, no selector rot.
  2. The URL patterns for a listing page, page 2 of that listing, a search, a category, and one
     individual book.
  3. For a listing: the element wrapping one result, and within it the link, title, cover and
     author.
  4. For a book page: title, authors, description, cover, language, publisher, year, subjects — and
     then either the chapter list or the download link.
  5. **How the text is actually addressed.** This is what decides the shape and therefore the whole
     extension. Answer it explicitly.
  6. Whether anything is paginated, lazily loaded, or rendered only after scripts run. The app's
     HTML parser does not run scripts, so anything a script injects is invisible to it. Several of
     these sites render their search results client-side; if that is the case here, find the request
     the script makes and use that instead, or say that you could not.
  7. **Whether the site has a search at all.** Many do not, and their search box posts to Google. If
     there is none, say so plainly. Do not invent one, and do not make `search` quietly return
     something else — a source that answers every query with the same popular list is worse than one
     that returns nothing, because nothing is at least true.

  **If you cannot fetch the site, say so and ask me for what you need.** Ask for specific things:
  the HTML of a listing page, the HTML of one book page, a chapter page, a sample API response. I
  will paste them. Asking me for markup is correct and expected. Inventing markup is the one failure
  that makes the whole exercise worthless, and I would rather answer three questions than debug a
  file of guesses.

  When you have finished, report the shape you chose and why, the URL patterns, the selectors or
  JSON paths, and anything you could not determine. Then move on.

  ## Step 2 — write the two files

  Produce complete files, not fragments: `manifest.json` and `main.js`.

  Follow the guide's field tables exactly. The ones easy to get wrong here:

  - The source needs `"kind": "text"`. Without it the app reads your source as an audiobook source
    and calls `resolveMedia` on books that have no audio.
  - `apiVersion` must be at least `"1.1"`, and `"1.2"` if you declare `bookFile`. A manifest that
    declares either without the version that has it is refused at install — deliberately, so the
    source never reaches an app that would misread it.
  - `domains` must list **every** host you touch: the pages, the cover images, and the EPUB. They
    are often three different hosts. `*.example.org` does **not** match `example.org`; list both if
    you need both.
  - Declare a capability (`latest`, `filters`, `imageRequest`, `bookFile`) **only** if you implement
    its method, and implement the method if you declare it.
  - `versionCode` is the number that orders releases, not `version`.
  - Do not set `"author"` to the name of the app or of its project.

  ## What a model gets wrong about text, from habit

  - **Return HTML.** Not markdown, not prose with the tags stripped, not your own summary. Send the
    element that holds the chapter — `<main>`, `<article>`, the chapter `<div>` — and let the app do
    the rest.
  - **Do not sanitise.** The app decodes your HTML into a closed set of blocks and never renders it.
    `script`, `style`, `iframe`, `form`, `svg` and `nav` are dropped whole, content and all; every
    other element keeps its text. Stripping the page's chrome is fine, but there is nothing to gain
    from cleaning what is already being decoded, and a hand-rolled sanitiser is a way to lose
    italics.
  - **Give `baseUrl`** when the markup has relative addresses, or every relative image is dropped.
    An image is kept only if its resolved address is on a host you declared.
  - Exactly one of `html` and `text` per chapter. Both is an error; neither is an error.
  - An empty chapter is `{ html: '' }` and not a failure. A source that has not published a
    chapter's text yet is saying so, not breaking.
  - **No durations anywhere.** A chapter of text has no length in minutes — it has a length in
    words, and how long that takes is the reader's own pace, which the app works out for itself.
    Leave `durationMs` and `totalDurationMs` unset. Do not invent a reading time.
  - `BookDetails` still requires `narrators`; for a book to read it is `[]`.
  - Chapter keys are stable site identifiers — a path, a slug, an anchor. **Never a title**, never a
    URL carrying a token or an expiry. They are what a reader's place is matched against, so if they
    change between versions every reading position detaches from its chapter.

  ## If you chose shape B — the whole book on one page

  You are guessing where the chapters are, for every book on the site at once, from transcriptions
  that may span decades. Guess in a way that fails safely:

  - Trim the site's own header and footer first — the licence block, the navigation, the "about this
    edition" matter. They are not part of the book.
  - Split on headings of **one** level. Use the level that appears often enough to be the chapters
    (usually `h2`); fall back to the next level only if there are fewer than two of the first. Parts
    and chapters are different levels, and mixing them makes a list nobody can read.
  - Drop the table of contents, the list of illustrations, and the title page or byline. Do **not**
    drop the preface, the introduction or the epilogue: those are the book.
  - Key each chapter by the transcription's own anchor id where it has one, and by position where it
    does not.
  - **Offer every section you did not recognise.** The worst outcome of a bad guess must be a
    chapter list that reads oddly — never text that goes missing. Do not discard what you could not
    classify.
  - **Cache the document's text per book**, so that reading a second chapter of the book in hand
    costs no request. Cache the response **text**, never the parsed document; see below.
  - Say in a comment how you decided, so the next person can tell a bad heading from a bad site.

  ## If you chose shape C — a file to download

  - `resolveBook(bookKey)` returns `{ request: { url }, format: 'epub', sizeBytes }`. Give
    `sizeBytes` when the site states it, so the reader is told the size before the download rather
    than during it.
  - Implement `getBookDetails` as usual: the title, author, cover, description and language are
    still yours. The chapters are not.
  - Do not implement `getChapters` or `getChapterContent`, and do not invent a chapter list. A list
    from you that disagreed with the file would be a list whose entries cannot be opened.
  - The app refuses a book locked with DRM when it reads the file. That is the app's job and not
    yours: do not attempt to unwrap, decrypt or work around any protection, and if a site offers
    only locked files, say so and stop.

  ## Step 3 — check your own work against the guide before showing it to me

  Walk the guide's §8 ("What fails a call") and §11 (the checklist) and confirm each line. Then
  state explicitly which of these you have verified:

  - The methods your shape requires all exist, and none that it forbids.
  - `hasNextPage` is genuinely derived from the page — a real "next" link or a known page count —
    and is `false` on the last page. A hardcoded `true` makes the app scroll forever.
  - No chapter key repeats within one book.
  - `BookDetails` includes `authors`, `narrators`, `genres` and `status` even when empty.
  - The description is plain text: HTML unwound, control characters stripped, under 20,000
    characters. A description that arrives as markup on the site must be unwound by you; it is the
    one field the app does not decode for you.
  - Nothing returns `0` to mean "unknown" — omit the field instead.
  - Failures throw a kind: `NotFound` when gone, `RateLimited` on 429 with `retryAfterMs` when the
    response gives one, `Network` on 5xx, `Parse` on markup you could not read. **An empty result is
    not an error** — return `{ items: [], hasNextPage: false }`.
  - Author names are as a person says them, not as a catalogue files them. Several of these sites
    publish "Shelley, Mary Wollstonecraft"; turn it round, and strip the birth–death years a
    catalogue appends.
  - No ES2021-or-later syntax. This is QuickJS held to ES2020: no `String.replaceAll`, no
    `Array.at`, no `Object.hasOwn`, no `Array.findLast`, no `||=` / `&&=` / `??=`, no top-level
    `await`.
  - No `undefined` inside an array, and no `Date`, `Map`, `Set` or class instance in anything
    returned.
  - No global `fetch`, no `require`, no `import`. Everything goes through `kikuyomi.http`,
    `kikuyomi.html`, `kikuyomi.storage`, `kikuyomi.crypto`, `kikuyomi.log`, `kikuyomi.host`.
  - Nothing keeps a parsed document past the call that parsed it. `html.parse` hands back a handle
    the host frees when the call returns, so a cache must hold the **extracted data** or the
    response **text**, never the document itself. Caching the document is the one mistake that looks
    correct, passes review, and fails on the second call with "that document has been let go".
  - Selectors avoid `:has()`, `:nth-child()`, `:nth-last-child()`, `:nth-of-type()`,
    `:only-of-type` and `:empty` — the app's parser **throws** on these rather than answering
    wrongly.

  **Be polite to the server.** A book's details and its chapter list often come from one request;
  cache what you extracted, keyed by book, with a small bound and least-recently-used eviction. For
  shape B the document is the whole book and may be a megabyte or more: keep one, not a catalogue's
  worth, and drop it when another book is opened. The runtime lives as long as the app, inside a
  64 MB ceiling. Fetch no more pages than a screen needs; a page size of 24–50 is right.

  ## What to hand back

  1. The shape you chose and why, and what you found in Step 1, including anything still unknown.
  2. `manifest.json`, complete.
  3. `main.js`, complete, with comments on anything the site forced on you — an endpoint that
     reports "not found" as HTTP 200, a catalogue that files author names, descriptions that arrive
     as HTML, a language given as a name rather than a tag, a heading level that changes halfway
     through the catalogue. These oddities are the real content of an extension and the next person
     needs them written down.
  4. Your Step 3 self-check, stated rather than assumed.
  5. Every assumption you could not verify against the site, so it can be tested first.

  ## How I will test it, so aim for this

  The extension is a folder holding `manifest.json` and `main.js`. It installs from that folder, and
  after editing `main.js` I press Reload, which restarts the runtime so the next use runs the new
  code. Then I will browse the source, open a book, add it, and read it — the chapter list, the
  first chapter, and a chapter in the middle, because shape B goes wrong in the middle rather than
  at the start.

  The app has an extension console showing everything `kikuyomi.log` writes and every failure the
  app records. So: **log usefully.** A `log.debug` naming the URL fetched and the number of items or
  sections parsed turns a silent empty grid into an obvious diagnosis. Do not log inside a tight
  loop; the console is rate-limited to 100 messages per 10 seconds.
