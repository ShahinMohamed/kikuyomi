# ADR-0018: The repository index format, and keeping its signatures

- **Status:** Accepted
- **Date:** 2026-09-26
- **Relates to:** `docs/architecture.md` §3.2, §3.3, §3.8, §3.9 and §4.3; ADR-0016, ADR-0017

## Context

ADR-0017 opened the first door for an extension: a folder, chosen by the author, reloaded fifty
times a day. It said plainly that this was the right first door for an author and the wrong one for
a listener, and that the listener's door is a repository. This is that door.

§3.2 and §3.9 describe it: a repository is an HTTPS location serving a `repo.json` (name, website,
public signing key), an `index.json` listing what it offers, the packages themselves, and icons.
§3.9 adds that the index "repeats the essential metadata — id, version, API version, languages,
sources, content rating, package URL, package hash, icon URL — so that the app can present and
filter available extensions without downloading any code". That last clause is the whole point of
the format: browsing a repository must cost nothing but one JSON fetch, and must run no code at all.

Two things had to be settled before writing it down.

**Whether packages are signed.** `docs/status.md` carried a proposal to ship without signing — the
index fetched over HTTPS with each package's SHA-256 pinned, so that a repository is as trustworthy
as whoever runs it — and recorded it as "not yet decided". Reading §3.8 settles it differently: the
approved design already decided. "Each repository has an Ed25519 signing key published in
`repo.json`. On first add, the app shows the key fingerprint and pins it (trust on first use)."
Shipping unsigned would not be filling in an open question; it would be reversing a decision that is
already made, in the direction of less safety, for a format that is public and versioned and
therefore expensive to change afterwards.

The argument for going unsigned was that key distribution is work nobody needs before the first
extension is published. That is true of *verification*, and not true of the *format*: a signature
field costs one string now and cannot be added later without a format version bump and every
existing repository breaking.

**What a hash proves, and what it does not.** A package's SHA-256 in the index proves the bytes
that arrived are the bytes the index named. It says nothing about who wrote the index. Against a
compromised or hostile repository, a hash is worth nothing at all: whoever can change the package
can change the hash beside it. Only a signature over a pinned key answers that, which is why §3.8
asks for one and why this ADR does not treat the hash as a substitute.

## Options considered

1. **Unsigned, HTTPS and pinned hashes only.** Least work. Reverses §3.8 and leaves a compromised
   repository able to ship any code it likes. Rejected.
2. **Signed, with verification before anything else ships.** Faithful to §3.8, but it puts key
   generation, signing tooling and a repository operator's workflow in front of a format nobody has
   written an index in yet.
3. **The format carries signatures from version 1; verification lands with the install path.**
   Chosen.

## Decision

The format is as §3.9 describes, with a `formatVersion` of its own so it can be evolved the way the
contract is, and carries every field a signed repository needs from version 1:

`repo.json` — `formatVersion`, `name`, `website`, `publicKey` (base64 Ed25519).

`index.json` — `formatVersion` and `extensions`, each entry repeating the manifest fields the app
needs to present and filter, plus the repository's own: `package` (`url`, `sha256`, `size`),
`iconUrl`, `signature`, and `revoked`.

An entry's manifest fields are decoded by the manifest's own decoder, which already accepts a
manifest without `files` — those hashes belong to a package, not to an index. So an entry is
validated by exactly the code that validates a manifest, and a field the two share cannot drift
apart.

`publicKey` and `signature` are **required by the format and not yet verified**. A repository must
carry them; this slice reads and preserves them, and the install path will verify them. Until it
does, a repository is trusted no further than ADR-0017 trusts a folder, and an extension from one
stays `untrusted`.

A package's `sha256` is required, and is verified at install regardless of signatures, because it is
what catches a truncated or corrupted download.

`revoked` on an entry disables that version on the next index refresh (§3.8).

## Consequences

The format is publishable now and will not need a version bump to add signing, which is the whole
reason for writing the fields down before they are enforced.

There is a window in which a repository is only as trustworthy as HTTPS and whoever runs it. That
window is a deliberate stage, not a decision, and it is recorded here so it cannot quietly become
one: the install path is not finished until it verifies the signature, and `status.md` should not
say Phase 2 is done before then.

Nothing can be signed until there is tooling to sign with. §3.10's SDK CLI has `sign` and `index`
commands in its scope; neither exists, and the official repository cannot be published until they
do.

`status.md`'s proposal to ship unsigned is superseded by this ADR and should be removed from it
rather than left as an open question, since leaving it invites the same decision being made twice.

## Update, 2026-09-27: the window is closed

Verification landed with the install path, as option 3 said it would. Two checks, in two places, and
each answers something the other cannot.

`RepositoryFetcher.fetch` refuses an index unless the key `repo.json` publishes signed every entry in
it. One bad signature fails the whole document rather than that entry: a listener accepted one key,
not an extension at a time, so a listing carrying something that key did not sign is one the app has
no way to reason about, and picking the good entries out of it would be the app deciding which half
of a tampered file to believe. Doing it in the fetcher means there is no moment above it where an
unverified listing exists to be shown, browsed or filtered.

`RepositoryFetcher.downloadPackage` then refuses a package unless the **pinned** key — the one in the
repository's row, which is where the listener's decision was written down, not the one this morning's
fetch happened to read — signed the hash the entry lists. That check runs before a byte is
downloaded. The package's own SHA-256 is still verified over the bytes that arrive, because a
signature over a hash proves nothing about a download that was truncated on the way.

So an extension installed from a repository is recorded `active`, and the word is earned: the app can
say who published the code and that it is unaltered. It is not a claim that the code is any good.

Signing is `packages/extension_manager/tool/build_repository.dart` rather than §3.10's SDK CLI, which
still does not exist. What it signs is the package's SHA-256 as the lowercase hex the index lists it
in — not the listing around it, because what an extension is *allowed* to do is read from the
manifest inside the verified package, never from the listing beside it.

### What is still not covered

Three things, written here rather than half-built.

**Rollback.** An entry is signed on its own, so a repository under someone else's control can
re-offer an older version its key genuinely did sign, and the app will take it. Catching that needs
the index signed as one document, with a time in it, so that an old index can be recognised as old.
That is a format version 2 change.

**Withdrawal by omission.** For the same reason, dropping an entry is indistinguishable from a
repository that no longer offers it. `revoked` is honest signalling, not a defence.

**Key rotation.** §3.8 supposes a rotation is signed by the old key; the format has nowhere to put
that. So a changed key is still refused outright — a rotation and a takeover look identical, and the
new key verifies the new index perfectly in both cases, which is precisely what makes verification no
help here. Adding a `previousKey`/`rotationSignature` pair to `repo.json` is additive and can go into
a version 2 alongside the signed index.
