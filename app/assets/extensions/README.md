# The extensions this project publishes

Each folder is a §3.3 package before it is zipped: a `manifest.json`, a bundled `main.js`, and an
`icon.png`. `packages/extension_manager/tool/build_repository.dart` turns them into the signed
repository under `repository/`.

Only LibriVox is also bundled *inside* the app, as an asset, so that a fresh install has one source
before any repository is added. The rest are installed from the repository like anybody else's.

## Where the icons come from

An icon here says which catalogue a source reads from, so three of them are that catalogue's own
mark, taken from the site itself:

| Extension | Icon | Source |
|---|---|---|
| `librivox` | The LibriVox star | `librivox.org/apple-touch-icon.png`, scaled to 256 |
| `internetarchive` | The Internet Archive's columns | `archive.org/apple-touch-icon.png`, scaled to 512 |
| `storynory` | Bertie, Storynory's frog | `storynory.com/img/bertie-opt.png`, centred on the site's cream |
| `podcasts` | A microphone | Drawn here. A generic feed reader has no owner, so it gets a generic mark rather than somebody else's |

LibriVox is stored at 256 rather than 512 because its source is 57 pixels: a larger file would be no
sharper, only heavier and visibly soft.

**Kikuyomi is not affiliated with LibriVox, the Internet Archive or Storynory.** Their marks are used
to identify which service a source reads from — the same reason a mail client shows a provider's
logo beside an account. If any of them would rather this project did not, replacing the file and
bumping the extension's `versionCode` is the whole of the change.

## Adding or changing an icon

An icon is part of the package, so it is part of what the manifest vouches for. After changing one:

1. put the new `icon.png` in the extension's folder;
2. update `files["icon.png"]` in its `manifest.json` with `sha256-<base64 of the SHA-256>`;
3. bump `version` and `versionCode`, because the package's bytes have changed and nobody is offered
   a release they already have;
4. rebuild the repository, from `packages/extension_manager`:
   `dart run tool/build_repository.dart --out ../../repository`.

`app/test/*_extension_test.dart` checks the hash against the file, and
`app/test/official_repository_test.dart` checks the committed repository against the code that reads
it, so forgetting any of this fails a test rather than a listener's install.
