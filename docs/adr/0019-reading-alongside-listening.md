# ADR-0019: Reading alongside listening

- **Status:** Accepted
- **Date:** 2026-09-28
- **Relates to:** `docs/architecture.md` §1.2, §1.3, §3.4 to §3.7, §4.3 and §4.5; ADR-0016

## Context

The owner asked for an ebook reader beside the audiobook player, the way Aniyomi reads manga
beside playing anime: its own library tab, and its own extensions in Browse.

This reverses a written decision, and that has to be said before anything else. §1.3 ends "this
project stays audiobook-specific", and §1.2 records the reason with Aniyomi as the example:
*"adding a second media type by duplicating tables, repositories, and screens produced a large
parallel codebase."* The owner has decided to add the second type anyway. What this record can
still do is take the warning seriously — the lesson of §1.2 is not "never add a second kind", it is
"do not do it by copying everything".

What carries over unchanged, and is most of the app: sources and extensions, repositories and
signatures, the library, categories, search and sorting, book details, chapters and their listened
state, history, backups. What does not:

- **The contract.** A source today answers "where is the audio of this chapter". A text source has
  to answer "what does this chapter say".
- **Progress.** Playback progress is chapter-relative milliseconds, derived through the Timeline
  from files and durations (§4.5). None of that exists for text.
- **The screen that consumes a chapter.** The player has no equivalent in reading.

## Options considered

| Question | Options | Verdict |
|---|---|---|
| How the second kind is modelled | A parallel set of tables, repositories and screens, as Aniyomi did; or one model with a kind | **One model with a kind.** §1.2's warning, taken literally. Separate *tabs* are a view decision and do not conflict with it |
| Where kind lives | On the extension, on the source, or on the book | **On the source in the contract, on the book in the database.** An extension may offer both. And the Local source serves both — a folder of MP3s and an EPUB are both "books from this device" — so a book cannot inherit its kind from its source |
| What a text source returns | Blocks the author assembles; plain text; or HTML | **HTML or plain text.** A web-novel page is HTML, and making every author translate it into a structure of ours would be the contract doing their parsing badly. The app does the translating, once, correctly |
| How HTML is shown | A general HTML renderer package; or decoded into a small block model the reader draws | **Decoded, never rendered.** Extension output is untrusted (CLAUDE.md), and a general renderer is a large surface for input nobody controls. Paragraphs, headings, quotes, lists, rules, preformatted text, images, and bold, italic and line breaks inside them. Everything else — scripts, styles, forms, frames, handlers — is dropped at the boundary, not filtered at render time |
| Where the converter lives | In the reader; in `sources_builtin`; or in `source_api` | **In `source_api`, beside the decoder.** Turning untrusted output into strict types is what the decoder is for, and both kinds of text source need it: the JavaScript adapter (`source_runtime`) and local EPUB files (`sources_builtin`) both depend on `source_api` already |
| Reading progress | Characters, pixels, or a fraction of the chapter | **A fraction, 0 to 1, within a chapter.** It survives a change of font size or window width, which characters counted on screen and pixels scrolled do not |
| Where it is stored | In `playback_state`, or a table of its own | **A table of its own.** `playback_state` is shaped for audio — speed, a global position, a queue — and forcing text into it would leave half its columns meaningless for half its rows |
| A chapter being finished | A new column, or `chapter.is_listened` | **`is_listened`, documented as finished however it was consumed.** Renaming it is a migration touching every row to change a word |
| Layout | Paginated or scrolled | **Scrolled.** It behaves the same at every width and font size, and it is what web-novel readers expect. Paginated is a later addition, not a different design |
| Protected EPUBs | Decrypt, or refuse | **Refuse.** A file with `META-INF/encryption.xml` naming a DRM scheme — Adobe ADEPT, Readium LCP, Apple FairPlay — is not imported, and the listener is told why. CLAUDE.md: the app never removes or bypasses DRM. Font obfuscation, which that same file can describe and which protects nothing a reader needs, is not DRM and does not refuse the book |

## Decision

**SourceAPI 1.1**, additive, so every 1.0 extension keeps working:

- A source entry in the manifest may say `"kind": "text"`. Absent means `"audio"`, which is every
  source that exists today.
- A text source implements `getChapterContent(chapterRef)`, returning `{ html }` or `{ text }`.
  It never implements `resolveMedia`, and an audio source never implements `getChapterContent`.
- `"kind": "text"` is refused in a manifest that targets 1.0. A 1.0 app would ignore the field and
  call `resolveMedia` on a source that has none; requiring 1.1 means such a source cannot reach an
  app that would do that, because that app refuses 1.1 as needing a newer one.
- Image URLs in text obey the declared domains, as every other URL an extension hands over does.

**The data model** gains `book.kind` and a `reading_state` table (book, chapter, fraction, when),
with a migration and a migration test. Chapters, sources, categories, history and downloads are
shared.

**Local EPUB** — EPUB 2 and 3 — in `sources_builtin`: the spine is the chapters, the navigation
document or NCX names them, the OPF gives title, authors, language and cover.

**The screens:** a Reading tab beside Library, a reader screen, and Browse split so reading
sources and reading extensions have tabs of their own.

## Consequences

The kind is a discriminator on shared tables, so every query that lists books has to know which it
wants. That is the price of not having a parallel codebase, and it is paid once, in the queries,
rather than in every feature twice.

A general HTML renderer is never needed, and never becomes a dependency. The price is that text
the converter does not understand is shown plainly or not at all — a table, for instance, reads as
its cells in order. That is the right way round for untrusted input: what is missing can be added,
what is rendered wrongly cannot be taken back from a listener's screen.

Downloading text for offline reading, reading aloud, paginated layout and annotations are not in
this record. Each fits the model above without changing it.

**Escape hatch.** Kind is an enum on the contract and a column in the database. A third kind —
comics, say — is a third value, a third content method, and a third screen, and nothing already
built has to change shape to make room for it.
