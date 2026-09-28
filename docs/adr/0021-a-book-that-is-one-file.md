# ADR-0021: A book that is one file

- **Status:** Accepted
- **Date:** 2026-09-28
- **Relates to:** ADR-0016, ADR-0019; `docs/architecture.md` §3.4, §3.7, §5.2

## Context

SourceAPI 1.1 gave a source two ways to hand over a book. An audio source answers `resolveMedia`
with the files of a chapter. A text source answers `getChapterContent` with what a chapter says, as
HTML or plain text, fetched one chapter at a time.

Both assume the source publishes a book *in pieces the app can ask for separately*. Working through
a list of free ebook sites, most of them do not. Global Grey, Faded Page, ManyBooks, Planet eBook,
DigiLibraries and Unglue.it publish a book as one EPUB to download, with a page about the book and
no per-chapter text anywhere. `getChapterContent` has nothing to fetch. Under 1.1 those sites cannot
be reached at all — not because their pages are hard to read, but because the contract has no shape
for what they offer.

The app can already read such a book. ADR-0019 built an EPUB reader for books added from this
device: it reads the spine, titles the chapters from the book's own table of contents, refuses a
book locked with DRM, and counts the words for the reading-time estimate. What is missing is a way
for a source to say "the book is that file", and for the app to treat what it downloads exactly as
it treats a file the reader added themselves.

## Decision

SourceAPI **1.2** adds one optional method and one capability.

```ts
resolveBook(bookKey: string): Promise<BookFile>

interface BookFile {
  request: HttpRequest
  format?: 'epub'
  sizeBytes?: number
}
```

- A source declares `bookFile` in its manifest's `capabilities`, which needs `apiVersion` 1.2 or
  later. A 1.1 app refuses such a manifest as needing a newer app rather than installing a source
  whose books it could never open.
- Only a **text** source may declare it. A book to listen to is not one file to read.
- A text source therefore has one of two shapes: it answers `getChapterContent`, or it declares
  `bookFile` and answers `resolveBook`. Declaring neither is a source with no text in it.
- For a source with `bookFile`, **the app does not call `getChapters`**. The chapters are the ones
  inside the file, read from its spine, because a list from the source that disagreed with the file
  would be a list whose entries could not be opened.
- `format` is `epub` and nothing else for now. It is a field rather than an assumption so that a
  later version can add one without changing what `resolveBook` means.

Adding the book downloads the file into the app's own storage and reads it with the reader
ADR-0019 already built. From then on the book is read exactly as a book added from this device is:
same reader, same reading position, same word counts, same refusal of DRM.

## Consequences

- The EPUB-only half of the free-ebook world becomes reachable, and each such source is a small
  extension: a catalogue to browse and one URL per book.
- Reading one of these books offline falls out for free. The file is already on the device, because
  reading it at all required downloading it.
- A book from such a source takes disk space the moment it is added, where a 1.1 text book takes
  none until it is read. That is what the sites offer, and the size is shown before the download
  where the source says it.
- DRM is refused at the same place it is refused for a local file, so a source cannot get a locked
  book into the library by another door.
- The chapter list appears only once the file is read, which is the same moment the book becomes
  readable, so there is no window where a book has chapters that cannot be opened.
- `min_reader_version` in backups is untouched: what is stored is a text book with a file beside it,
  which older builds already understand as a book to read.
