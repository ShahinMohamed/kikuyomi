# The Kikuyomi repository

A repository Kikuyomi can install extensions from (§3.2, §3.8; ADR-0018). It is static files served
over HTTPS, so GitHub hosts it with nothing running.

- `repo.json` — what this repository is called and the Ed25519 key it signs with.
- `index.json` — what it offers: enough metadata for the app to show each extension and its
  permissions summary without downloading any code.
- `packages/` — one zip per extension version.

## Adding it to Kikuyomi

Browse → Extensions → the cloud icon → Add, and paste the address of this folder. The app shows the
signing key's fingerprint before it keeps anything; check it against the one below.

## Building it

Generated, never edited by hand. From `packages/extension_manager`:

    dart run tool/build_repository.dart --name "Kikuyomi official"

It packages every extension folder under `app/assets/extensions`, hashes each package, signs it, and
writes the two documents. It then reads them back through the app's own parser, so a repository this
project cannot read never gets published.

The private signing key lives at `repository-signing-key.txt` in the project root and is gitignored.
Whoever has it can sign packages as this repository. Losing it means generating another and every
listener accepting the new fingerprint — trust on first use working as designed rather than a
disaster.

## What is not true yet

Nothing verifies these signatures. The app checks each package's SHA-256, which proves the bytes are
the ones this index named and says nothing about who wrote the index. Until the install path verifies
signatures (ADR-0018), an extension from here is recorded `untrusted` and the app says so.
