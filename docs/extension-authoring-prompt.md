# A prompt for having an AI write a Kikuyomi audiobook extension

For a source of books to **read** rather than listen to, use its counterpart,
[`ebook-extension-authoring-prompt.md`](ebook-extension-authoring-prompt.md): the contract is
different enough that one prompt covering both would serve neither.

Paste the text below into a coding assistant, attach
[`docs/writing-an-extension.md`](writing-an-extension.md), and give it the site's URL. Everything
between the rules is the prompt; nothing above or below it needs to go across.

The prompt is built around the one failure mode that matters. A model asked to write a scraper for a
site it cannot see will produce a plausible file full of invented selectors — `article, .post,
.entry`, `.entry-title a`, `a[href$=".mp3"]` — that compiles, installs, and returns nothing. It looks
finished and is worthless. So the prompt's central rule is: **do not guess markup; ask for it.** Most
of what follows exists to enforce that, and to hold the result to the parts of the contract a model
will otherwise get wrong from habit.

---

  You are writing a **source extension for Kikuyomi**, a cross-platform audiobook player whose sources
  come from installable JavaScript extensions. I have attached `writing-an-extension.md`. That document
  is the complete and authoritative contract: every type, every host function, every validation rule and
  every limit. Treat it as the specification and do not infer anything from other extension systems you
  know — Mihon, Tachiyomi, Kodi, browser extensions, Calibre — because the shapes are different and the
  differences are silent.

  **The site is:** `<URL>`

  ## How to work, in this order

  **Step 1 — investigate before you write anything.**

  Do not write code yet. First establish, from the site itself:

  1. Whether it has a JSON API. Check for `/wp-json/wp/v2/` (WordPress), `/api/`, `/graphql`, a sitemap,
    an RSS feed, or an `application/ld+json` block in the page source. An API is always preferable to
    scraping: fewer requests, stable field names, no selector rot.
  2. The URL patterns for: a browse or listing page, page 2 of that listing, a search, a category or
    genre filter, and one individual audiobook.
  3. For a listing page: the element that wraps one result, and within it the link, the title, the
    cover image, the author, and the duration if shown.
  4. For a book page: title, author, narrator, description, cover, genres, language, year, and the
    chapter or track list.
  5. **How the audio is actually addressed.** This is the part that decides whether the extension works
    at all: whether the page contains direct file URLs, or a player that is given them another way, and
    whether one book is one file or many.
  6. Whether anything is paginated, lazily loaded, or rendered only after scripts run. The app's HTML
    parser does not run scripts, so anything injected by JavaScript is invisible to it — if the content
    only appears after scripts, say so, because that changes the approach entirely.

  **If you cannot fetch the site, say so and ask me for what you need.** Ask for specific things: the
  HTML of a listing page, the HTML of one book page, a sample API response. I will paste them. Asking me
  for markup is correct and expected. Inventing markup is the one failure that makes the whole exercise
  worthless, and I would rather answer three questions than debug a file of guesses.

  When you have finished investigating, report what you found — the URL patterns, the selectors or JSON
  paths, and how audio is addressed — and note anything you could not determine. Then move on.

  **Step 2 — write the two files.**

  Produce complete files, not fragments:

  - `manifest.json`
  - `main.js`

  Follow the guide's field tables exactly. Some specifics it is easy to get wrong:

  - `domains` must list **every** host you touch — the pages, the audio, and the cover images. They are
    often different hosts. `*.example.org` does **not** match `example.org`; list both if you need both.
  - Declare a capability (`latest`, `filters`, `imageRequest`) **only** if you implement its method, and
    implement the method if you declare it.
  - `versionCode` is the number that orders releases, not `version`.
  - Do not set `"author"` to the name of the app or of its project. Use the extension's actual author.
  - You may omit `files` entirely; a folder install does not verify hashes.

  **Step 3 — check your own work against the guide before showing it to me.**

  Walk the guide's §8 ("What fails a call") and §11 (the checklist) and confirm each line. Then state
  explicitly which of these you have verified:

  - All five required methods exist: `getPopular`, `search`, `getBookDetails`, `getChapters`,
    `resolveMedia`.
  - `hasNextPage` is genuinely derived from the page — a real "next" link or a known page count — and is
    `false` on the last page. A hardcoded `true` makes the app scroll forever.
  - Book, chapter and file keys are stable site identifiers. **Never a title. Never a URL carrying a
    token or an expiry.** They are the identities the app matches a listener's progress against, so if
    they change between versions, every bookmark detaches from its book.
  - No chapter key repeats within one book.
  - `BookDetails` includes `authors`, `narrators`, `genres` and `status` even when empty — they are
    required, so use `[]` and `'unknown'` rather than omitting them.
  - `durationMs` is set on chapters wherever the site reveals it, so the book can be scrubbed before
    anything is resolved.
  - The description is plain text: HTML unwound, control characters stripped, under 20,000 characters.
  - Nothing returns `0` to mean "unknown" — a `0` duration or size is read as *not known*, so omit the
    field instead. Never a fraction where a whole number is required.
  - Failures throw a kind: `NotFound` when gone, `RateLimited` on 429 with `retryAfterMs` when the
    response gives one, `Network` on 5xx, `Parse` on markup you could not read. **An empty result is not
    an error** — return `{ items: [], hasNextPage: false }`.
  - An M4B-style book — one file, many chapters — shares one `fileKey` across chapters with a `range`
    each, rather than pretending to be one file per chapter.
  - No ES2021-or-later syntax. This is QuickJS held to ES2020: no `String.replaceAll`, no `Array.at`, no
    `Object.hasOwn`, no `Array.findLast`, no `||=` / `&&=` / `??=`, no top-level `await`.
  - No `undefined` inside an array, and no `Date`, `Map`, `Set` or class instance in anything returned.
  - No global `fetch`, no `require`, no `import`. Everything goes through `kikuyomi.http`,
    `kikuyomi.html`, `kikuyomi.storage`, `kikuyomi.crypto`, `kikuyomi.log`, `kikuyomi.host`.
  - Nothing keeps a parsed document past the call that parsed it. `html.parse` hands back a handle the
    host frees when the call returns, so a cache must hold the **extracted data** or the response
    **text**, never the document itself. Caching the document is the one mistake that looks correct,
    passes review, and fails on the second call with "that document has been let go".
  - Selectors avoid `:has()`, `:nth-child()`, `:nth-last-child()`, `:nth-of-type()`, `:only-of-type` and
    `:empty` — the app's parser **throws** on these rather than answering wrongly.

  **Be polite to the server.** If one request returns a book's details, its chapter list and its audio
  addresses — which is common — cache what you extracted from it, keyed by book, for a few minutes, with
  a small bound (four books) and least-recently-used eviction, so opening a book costs one request
  rather than one per chapter. Cache the extracted values or the response text, never the parsed
  document, for the reason given above. Do not let such a cache grow with the catalogue: the runtime lives as long as the
  app, inside a 64 MB ceiling. Fetch no more pages than a screen needs; a page size of 24–50 is right.

  ## What to hand back

  1. What you found in Step 1, including anything still unknown.
  2. `manifest.json`, complete.
  3. `main.js`, complete, with comments on anything the site forced on you — an endpoint that reports
    "not found" as HTTP 200, a title search that needs a prefix marker, descriptions that arrive as
    HTML, a language given as a name rather than a tag. These oddities are the real content of an
    extension and the next person needs them written down.
  4. Your Step 3 self-check, stated rather than assumed.
  5. A list of every assumption you made that you could not verify against the site, so it can be tested
    first.

  ## How I will test it, so aim for this

  The extension is a folder holding `manifest.json` and `main.js`. It installs from that folder, and
  after editing `main.js` I press Reload, which restarts the runtime so the next use runs the new code.
  The app has an extension console showing everything `kikuyomi.log` writes and every failure the app
  records. So: **log usefully**. A `log.debug` naming the URL fetched and the number of items parsed
  turns a silent empty grid into an obvious diagnosis. Do not log inside a tight loop; the console is
  rate-limited to 100 messages per 10 seconds.
