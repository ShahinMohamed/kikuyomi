# Progress against the roadmap

Every scope item from `architecture.md` §8, ticked or not. It is the at-a-glance view;
`status.md` is the detailed one and says *how* each piece works and what has never been run.

A box is ticked only when the thing is built **and** believed to work. "Built but never run on a
device" is not ticked — that distinction is the whole reason this file is worth keeping. Seven real
defects have now been found in code that a green test suite and a clean build both passed: a
download queue that stopped at four of fifteen, downloaded files the player could not find, HTML
left in descriptions, two extensions missing a field the contract requires, a settings key that
threw on every read and made Browse untappable, chapter rows that did nothing when tapped, and a
chapter list that rebuilt all four hundred of its rows several times a second while a download ran.
Every one was found by running the app, and none by the suite — the last one could not have been,
because a test has no frame rate.

Phases are not being done strictly in order. Some Phase 4 work has been pulled forward because the
library is the screen used daily, and Phase 2 and Phase 3 both still have holes.

`[~]` marks a roadmap item that was **decided against** rather than left undone, with the reason
beside it. An empty box that will never be ticked is worth telling apart from one that is waiting.

---

## Phase 0 — Environment and spikes

- [x] Dev environment: `flutter doctor` clean for Android and Windows
- [x] CI skeleton producing an Android APK, a Windows build and an unsigned iOS IPA
- [x] Spike (a): QuickJS binding selection against §3.1, plus HTML selector coverage in the Dart parser
- [x] Spike (b): playback with `just_audio` and `audio_service` — multi-file, headers, speed, controls, background, audio focus
- [x] Spike (c): downloads with `background_downloader` — expiring URLs, process kill, foreground-service limits
- [x] Spike (d): M4B chapter extraction
- [x] Spike (e): sideload the iOS canary and confirm it launches and plays audio in the background
- [x] ADRs written and approved (17 of them)

**Exit: everything works on Android and Windows, the iOS canary runs, ADRs approved.** Met, with the
caveat that the Android proofs are the emulator probes in CI rather than the app itself.

---

## Phase 1 — Foundation and local player

- [x] Workspace and package structure
- [x] Drift schema with migration tests
- [x] Domain entities and the Timeline
- [x] Design system
- [x] Adaptive shell — five tabs, a bottom bar on a phone and a rail on a wide window. §2.6 asks
      for four; History and Downloads were given tabs of their own rather than living under More,
      because both were reached through the library's app bar and neither is about the library
- [ ] Local source — Windows folders and drag-and-drop, tags and M4B chapters work; the Android folder picker has never been driven by the running app, and local files is not a real `ContentSource` (§3.10)
- [x] Library
- [x] Book details
- [x] Full player: play/pause, seek, speed, sleep timer, background, system media controls, remembered position
- [x] Progress, chapter-relative and derived through the Timeline
- [x] Continue Listening
- [x] Automatic backups to a chosen folder, with restore on a fresh install

**Exit (M1): used daily on PC and on an Android device, and an uninstall-reinstall loses nothing.**
Not met — the app has never been run on Android at all.

---

## Phase 2 — Extension system and first public release

- [x] SourceAPI 1.0
- [ ] TypeScript SDK and CLI — does not exist. `docs/writing-an-extension.md` is the whole of the
      author's story, alongside two prompts for having an assistant write one:
      `docs/extension-authoring-prompt.md` for audiobooks and
      `docs/ebook-extension-authoring-prompt.md` for books to read
- [x] QuickJS runtime with worker isolates and bridges
- [x] ExtensionManager: install, uninstall and reload from a folder (ADR-0017)
- [x] ExtensionManager: repositories — the format and its parser (ADR-0018), the address handling,
      fetching with ETag caching, the `repository` table with its pinned key, a Repositories screen
      that adds one after showing its fingerprint, and downloading, verifying and installing a
      package from one. Used for real on Windows against the official repository
- [x] ExtensionManager: update checks — every repository re-read on demand, a newer `versionCode`
      offered rather than installed, a withdrawn version stopped and a reinstated one started again,
      and one repository being down never losing what the others said
- [x] ExtensionManager: signatures and trust — an index is refused unless the repository's published
      key signed every entry, and a package unless the **pinned** key signed the hash the index
      lists, checked before the download starts. A repository install is recorded `active`; a folder
      install stays `untrusted`, which is what a folder deserves (ADR-0018)
- [x] Rolling back to an earlier installed version, off the disk and without the network
- [x] Browse, and per-source search
- [x] Extension-backed details and chapters
- [x] Streaming, with re-resolve when an address goes stale
- [x] A LibriVox extension, bundled with the app
- [x] An Internet Archive extension, a Storynory one, and a Podcasts one that plays any show from
      the podcast hosts it declares -- pasted as a feed address, an Apple Podcasts link or a
      Spotify show link, or found by name through Apple's public index
- [x] An official repository for them to live in, built and signed by
      `packages/extension_manager/tool/build_repository.dart`
- [x] Extension icons, which §3.3 always listed among a package's files and nothing read: the
      package carries one, the install writes it beside the code, and both lists draw it from disk
- [x] Browse in two halves, Sources and Extensions, with sources grouped by last used, pinned and
      language
- [ ] GitHub Releases for Android and Windows
- [ ] In-app update checker
- [ ] Android developer account

**Exit (M2, the MVP): browse → details → stream from an installed extension, end to end, installed
by a tester from a public release.** The end-to-end path works; nothing has ever been released.

The extension system itself is finished: the contract, the runtime, both doors in, signatures,
updates, rollback, and four extensions in a signed repository. What is left of this phase is not
extension work at all. The TypeScript SDK and CLI is a project of its own, and the last three items
are release engineering, which needs a signing keystore created once and backed up in two safe
places (§5.1) and a Play-independent release pipeline — and, for the last of them, an Android
developer account only the project's owner can open.

---

## Phase 3 — Offline

- [x] Download engine on Windows: queue, scheduler, state machine, backoff, post-processing
- [ ] Download engine on Android — needs a foreground service in the manifest, with the service type Android 14 and later requires. None of this fails at compile time
- [x] Queue UI: the Downloads screen, with total usage, per-book sizes and a book opened to its files
- [x] Pause, resume, stop, retry, and remove in any state
- [x] Whole-book downloads
- [x] Per-chapter downloads — each row has its own arrow and its own state, the Download button
      offers next / next 5 / next 10 / all unlistened / all, and chapters can be held to pick
      several out. A chapter reads as downloaded only when every file it needs is here, and
      downloading one chapter of an M4B downloads its neighbours because it is the same bytes
- [x] Storage management: delete a file, delete a book, what it all comes to
- [ ] Per-chapter delete — a file can hold thirty chapters and a chapter can span three files, so one that quietly took a neighbour with it would be worse than none
- [ ] Auto-delete finished chapters
- [ ] "Keep the next N chapters downloaded"
- [ ] Automatic downloads of new chapters on an unmetered connection
- [ ] Download notifications
- [ ] Battery-optimisation guidance
- [x] Airplane-mode test pass — confirmed on iOS: a downloaded book plays through with the network
      off. Not repeated on Windows or Android
- [ ] Diagnostics export
- [ ] Probing a kept file for its real duration, format and markers
- [ ] Repairing a task orphaned by a chapter-layout rewrite
- [ ] A download-aware resolution, so a fetch asks its source as a download rather than as a stream

**Exit (M3): a full book downloaded and finished with no network. Met**, on iOS. That is the first
time the offline path has been proved end to end rather than argued from green tests.

What it also turned up: downloading a chapter made the page it was downloaded from crawl. Two
causes, both now fixed. Every `bytes_done` write — many a second — became a new reading of every
chapter's state and a rebuild of the list, though none of those writes moves a chapter between
states; and the list was a `Column` of every row inside a `ListView`, so a four-hundred-chapter
podcast built all four hundred rows each time. The stream now emits only when something actually
changes, and the list is a sliver that builds a row as it comes into view.

---

## Phase 4 — Library power features

- [x] Categories — make, rename, reorder and delete them under More; file a book under any number
      of them from its own page; and narrow the library to one from the bar above the shelf. A name
      is what identifies a category, because that is what a backup matches on, so names are unique
- [ ] Per-category settings — `category.flags` is written down in §4.3 and nothing sets it. Each
      category should carry its own sort, filter and display
- [ ] Smart collections
- [ ] Series grouping
- [x] Sorting: title, recently added, longest, kept in settings
- [ ] Filtering
- [x] Library search by title, subtitle and series
- [ ] Full-text library search
- [x] History, with per-entry and per-book deletion, on a tab of its own
- [x] Playing from any chapter by tapping it, and from an embedded marker in a single-file book
- [ ] Statistics
- [x] Bookmarks
- [ ] Manual backup and restore with selective restore and retention
- [ ] Metadata editing
- [~] Library updates — **decided against as a background job.** A book's page pulls down to ask
      its source again, and §4.4's merge keeps progress, bookmarks and listened state. The sweep of
      the whole library on a schedule, and the Updates feed it would fill, were declined as far more
      machinery than the question deserves. The Home feed is still open if one is ever wanted
- [ ] Global search across sources
- [ ] Source migration

**Exit (M4): public beta.**

---

## Phase 5 — Ecosystem and robustness

- [ ] Source settings and login
- [ ] WebView challenge flow
- [ ] Platform-native HTTP clients
- [x] Extension health and logs — the extension console (§3.11)
- [ ] Developer mode: LAN repository and live reload
- [ ] SDK documentation
- [ ] Template repository
- [ ] Contract test suite
- [ ] Synthetic 300-source load test
- [ ] Revocation and obsolescence handling
- [ ] Built-in Audiobookshelf and OPDS

---

## Phase 6 — Production hardening

- [ ] Accessibility: TalkBack, Windows Narrator, text scaling
- [ ] Localisation, including right-to-left
- [ ] Android Auto
- [ ] Sync backends: folder, WebDAV, Audiobookshelf
- [ ] Trackers: Audiobookshelf, Hardcover
- [ ] Skip-silence on Android
- [ ] Home-screen widget
- [ ] Desktop polish: tray, shortcuts, window state
- [ ] Windows installer and code signing
- [ ] Verified Android developer registration

**Exit (M5): 1.0 released.**

---

## Phase 7 — iOS

- [x] The canary builds in CI and has been sideloaded and played on a device
- [ ] iOS adapter configuration and the fixes in Appendix A
- [ ] On-device QA
- [ ] An AltStore or SideStore feed

---

## Phase 8 — Optional

- [ ] macOS and Linux builds
- [ ] Store editions through `DistributionPolicy`

---

## Asked for, not in the roadmap

- [ ] A theme picker in settings, which would make the accent colour a choice rather than a decision
- [x] An ebook reader alongside the audiobook player, as Aniyomi does manga and anime (ADR-0019,
      ADR-0020). Done in five slices:
  - [x] SourceAPI 1.1: a source's kind, `getChapterContent`, and HTML or text decoded into a closed
        set of blocks, never rendered
  - [x] Schema version 5: `book.kind` and `reading_state`, a chapter and a fraction through it;
        backups carry both (format version 3)
  - [x] Local EPUBs: read, titled from their own table of contents, and refused when locked with
        DRM, naming the lock
  - [x] A Read tab beside Listen, with Continue Reading, and the reader: scrolled, text size, a
        chapter list, place saved and restored, chapters finished by reading to the end
  - [x] Browse split into audio and ebook sources and extensions; Standard Ebooks as the first
        source of books to read, shipped and run on the real engine by the probe
  - [x] What the first run on an iPhone found: the ebook side still said "mark as listened" and drew
        a waveform; History and categories did not cover reading; the back swipe was unusable
  - [x] SourceAPI 1.2: `resolveBook` and the `bookFile` capability (ADR-0021), because most ebook
        sites publish an EPUB to download rather than a page per chapter. Schema version 8's
        `book.file_path` is where the downloaded file lives, and Project Gutenberg is the second
        shipped source of books to read
  - [x] An arrow to turn a chapter list round, remembered per book (schema version 9's
        `book.chapters_reversed`, nullable so a restore cannot overwrite a choice made since)
  - [x] Tabs the listener arranges: six is more than fits, and which matter depends on whether
        somebody mostly reads or mostly listens
  - [ ] Not yet: paged layout, themes and fonts for reading, and reading chapters offline
- [ ] **Link Up**: link an audiobook and an ebook of the same book, and carry the place between
      them. Discussed, not started. The decisions so far:
  - **Design.** The two stay separate books, each from its own source with its own chapters and its
    own progress. A link sits above them. They are not merged into one internal book: most books
    will never be linked, and ADR-0019 already made a book one thing from one source
  - **Tabs.** Both stay. A linked book sits on the Listen shelf and the Read shelf alike
  - **Sync method.** A chapter map, not "chapter N = chapter N": ebooks carry front matter,
    audiobooks carry credits, and both split and merge chapters freely. Within a chapter, the
    same proportion (60% of the text is about 60% of the audio), landing 15–30 seconds early so
    nothing is missed. Whole-book percentage only as a fallback, for a book with no usable map
  - **Offered, never silent.** Opening the other copy offers to jump ("You read to Chapter 5, about
    60%. Continue listening from there?"). Whichever copy was used most recently is the one ahead
  - Steps, in order:
    - [ ] A link table (one audiobook and one ebook, each book in at most one link) and a chapter
          map table (ordered pairs of chapters, either side allowed empty, one-to-many allowed).
          Progress stays in `playback_state` and `reading_state`; sync translates between them
    - [ ] "Link up" in a book page's menu: pick the other copy from the library, likely matches
          first by title and author, then review the proposed chapter map ("38 of 40 matched") and
          fix what it got wrong. A warning when the match is poor. Unlink from the same menu
    - [ ] The map proposed automatically: normalised titles first ("Chapter IV" = "Chapter 4"), then
          order and length. Re-proposed for new chapters after a refresh
    - [ ] The "continue from" offer when opening the other copy, with Continue and Stay here
    - [ ] The reader's place as a position in the text for syncing. It is saved as a scroll
          fraction, which headings and pictures make drift from the text
    - [ ] A linked mark on both covers, and "Also as an ebook / audiobook" on each book's page
    - [ ] Backups carry links by source and key and chapter keys, never database ids. Additive:
          an older build loses only the link, so `min_reader_version` does not rise
    - [ ] Finishing one copy offers to finish the other; a Continue card for the copy left behind
          says so ("Ahead in the ebook")
    - [ ] The whole-book percentage fallback, for a single-file audiobook with no markers
    - [ ] A combined view on a linked book's page: a Read | Listen switcher, one "where you are"
          line, and one Continue button that knows which copy was used last
    - [ ] Links follow a book through source migration, as progress does
    - [ ] Later, perhaps: precise alignment of text and audio (speech recognition or EPUB 3 media
          overlays), which would only sharpen the within-chapter step
  - Pitfalls to design against: mismatched editions (abridged, other translations), chapter lists
    that change on refresh, positions pulled backwards by the copy that is behind, and future
    cross-device sync bouncing positions between the two
