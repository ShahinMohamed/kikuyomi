# ADR-0020: Backups that hold books to read

- **Status:** Accepted
- **Date:** 2026-09-28
- **Relates to:** ADR-0008, ADR-0019; `packages/backup/proto/backup.proto`

## Context

ADR-0019 gives a book a kind, audio or text, and gives a book being read a reading position. Both
have to survive a backup, so format version 3 adds `Book.kind` (field 34) and `Book.reading_state`
(field 35).

Adding fields is normally all ADR-0008 asks: an older build skips what it does not know, and the
backup still restores. This time skipping is not harmless. A version 2 build reading a backup with a
book to read skips `kind`, takes the default, and restores the book as an audiobook: on the
listening shelf, with chapters the player cannot play, and nothing to say anything went wrong. That
is exactly the case `min_reader_version` exists for, and `packages/backup/README.md` asks for an
ADR whenever it rises.

## Decision

`min_reader_version` is 3 **for a backup that holds a book to read**, and stays at 1 for a backup of
audiobooks alone.

The rule is on the content, not the build, because the silent mistake can only happen in a backup
that holds a text book. Raising it for every backup would make an older build refuse a library of
audiobooks it restores perfectly, which costs the listener something and protects them from nothing.

The rest of format version 3:

- `BookKind`'s zero value is audio, so every backup written before version 3 reads correctly: every
  book in it was an audiobook.
- A reading position is validated like a playback position. One in a chapter the backup lacks, or
  outside 0 to 1, is left out and listed in the restore's skipped items; the book is kept.
- A restore merges reading positions by the rule playback progress follows: the side saved more
  recently wins, and a tie keeps the library's.
- A book's kind is never merged. The same book always comes from the same source, so the library
  and the backup can only disagree about it if the backup was tampered with, and the library's own
  record wins.

## Consequences

- An older build lists a backup with a book to read as needing a newer app, and refuses to restore
  it, instead of restoring it wrongly. A backup of audiobooks from the same build still restores on
  the older one.
- A future kind follows the same pattern: a new `BookKind` value arrives at an older reader as the
  default, so a backup holding one must name a `min_reader_version` that reader cannot meet.
