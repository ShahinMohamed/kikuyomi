# Kikuyomi

An audiobook player and ebook reader whose content comes from installable JavaScript extensions.
Cross-platform, open source, and not in any app store.

If you have used [Mihon](https://github.com/mihonapp/mihon) or Aniyomi, the shape will be familiar:
the app is a reader and a player, and where the books come from is up to you. Kikuyomi reads and
listens side by side — one library, with each book knowing whether it is something to hear or
something to read.

## Status

**Early, and honest about it.** The app works: you can add local books or browse a source, see a
book's chapters and where you left off, and play or read it with seeking, chapter navigation, speed,
a sleep timer, system media controls, downloads for offline use, and automatic backups. Extensions
run for real, each in an isolate of its own.

What that sentence hides is how unevenly it has been exercised. It has been used most on iOS,
some on Windows, and — at the time of writing — **never on Android outside CI**. Treat early
releases accordingly. [`docs/status.md`](docs/status.md) is kept current and says exactly what has
been run where, including the things that are built but unconfirmed.

## Installing

Releases carry an Android APK, a Windows zip and an unsigned iOS IPA. There is no store and there
will not be one: a store holds a developer answerable for everything a plug-in does, and this app
cannot make promises about extensions it does not write. That trade-off is written down in
[ADR-0010](docs/adr/0010-sideload-first-distribution.md).

- **Android** — open the APK and allow installation from this source.
- **Windows** — unpack the zip and run `kikuyomi.exe`. SmartScreen will warn you: the executable is
  unsigned, which is the cost of shipping outside a store.
- **iOS** — sideload with AltStore or SideStore, which re-sign it. A free Apple ID signs for seven
  days at a time.

## Extensions

An extension is a `manifest.json` and one ES2020 `main.js`, run in a QuickJS sandbox with no access
to the filesystem, the network beyond the domains it declared, or anything else the host does not
hand it. They can be installed from a folder while you are writing one, or from a repository.

The app ships knowing only its own official repository, and **neither the app nor this project's
documentation lists or recommends any other**. What you add is your business; what we publish is
ours.

Writing one: [`docs/writing-an-extension.md`](docs/writing-an-extension.md) is the reference, and
there are two prompts for having an assistant do the first draft —
[for audiobooks](docs/extension-authoring-prompt.md) and
[for books to read](docs/ebook-extension-authoring-prompt.md).

## Building from source

You need the Flutter SDK. The repository is a Dart pub workspace, so one resolution covers every
package.

```
flutter pub get           # at the repository root, not `dart pub get`
flutter run -d windows    # from app/; needs rustup, for smtc_windows
flutter run -d <emulator> # see `flutter devices`
```

Checks, scoped to the app and the packages because `spikes/` is deliberately throwaway:

```
dart format app packages
flutter analyze app packages
```

## How it is put together

[`docs/architecture.md`](docs/architecture.md) is the design. Individual decisions — and the
arguments that were had before them — are in [`docs/adr/`](docs/adr/), which is the honest record:
what was chosen, what was rejected, and what it will cost.

A few rules the code actually keeps to, in case you are reading it:

- Pure-Dart packages never import Flutter. Platform differences live behind interfaces in
  `platform_adapters`, so no feature contains a `Platform.isX`.
- The database is the single source of truth, and the interface watches it rather than holding
  copies.
- Extension output is untrusted: it is decoded into strict types and validated at the boundary.
- Nothing here removes or bypasses DRM, and nothing ever will.

## Licence

[Apache 2.0](LICENSE.txt).
