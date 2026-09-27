# Progress against the roadmap

Every scope item from `architecture.md` §8, ticked or not. It is the at-a-glance view;
`status.md` is the detailed one and says *how* each piece works and what has never been run.

A box is ticked only when the thing is built **and** believed to work. "Built but never run on a
device" is not ticked — that distinction is the whole reason this file is worth keeping, because
this project has twice found real defects in code that a green test suite and a clean build both
passed.

Phases are not being done strictly in order. Some Phase 4 work has been pulled forward because the
library is the screen used daily, and Phase 2 and Phase 3 both still have holes.

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
- [ ] Adaptive shell — two tabs of §2.6's four; Settings, Downloads and History sit in the app bar because More does not exist
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
- [ ] TypeScript SDK and CLI — does not exist; `docs/writing-an-extension.md` is the whole of the author's story
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

The extension system itself is finished: the contract, the runtime, both doors in, signatures,
updates, rollback, and four extensions in a signed repository. What is left of this phase is not
extension work at all. The TypeScript SDK and CLI is a project of its own, and the last three items
are release engineering, which needs a signing keystore that must be created once and backed up in
two safe places (§5.1) and a Play-independent release pipeline -- and, for the last of them, an
Android developer account only the project's owner can open.

---

## Phase 3 — Offline

- [x] Download engine on Windows: queue, scheduler, state machine, backoff, post-processing
- [ ] Download engine on Android — needs a foreground service in the manifest, with the service type Android 14 and later requires. None of this fails at compile time
- [x] Queue UI: the Downloads screen, with total usage, per-book sizes and a book opened to its files
- [x] Pause, resume, stop, retry, and remove in any state
- [x] Whole-book downloads
- [ ] Per-chapter downloads
- [x] Storage management: delete a file, delete a book, what it all comes to
- [ ] Per-chapter delete — a file can hold thirty chapters and a chapter can span three files, so one that quietly took a neighbour with it would be worse than none
- [ ] Auto-delete finished chapters
- [ ] "Keep the next N chapters downloaded"
- [ ] Automatic downloads of new chapters on an unmetered connection
- [ ] Download notifications
- [ ] Battery-optimisation guidance
- [ ] Airplane-mode test pass
- [ ] Diagnostics export
- [ ] Probing a kept file for its real duration, format and markers
- [ ] Repairing a task orphaned by a chapter-layout rewrite
- [ ] A download-aware resolution, so a fetch asks its source as a download rather than as a stream

**Exit (M3): a full book downloaded and finished with no network.** Everything it needs is built;
nothing has confirmed it.

---

## Phase 4 — Library power features

- [ ] Categories, with per-category settings — tables and backup support exist, no UI
- [ ] Smart collections
- [ ] Series grouping
- [x] Sorting: title, recently added, longest, kept in settings
- [ ] Filtering
- [x] Library search by title, subtitle and series
- [ ] Full-text library search
- [x] History, with per-entry and per-book deletion
- [ ] Statistics
- [x] Bookmarks
- [ ] Manual backup and restore with selective restore and retention
- [ ] Metadata editing
- [ ] Library updates and a Home feed
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
- [ ] An ebook reader alongside the audiobook player, as Aniyomi does manga and anime. The largest single item on any of these lists: `source_api` would need a content kind, the progress model does not carry over from audio, and the reader itself is a screen with no equivalent here
