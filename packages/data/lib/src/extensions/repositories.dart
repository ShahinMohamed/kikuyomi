/// The repositories a listener has added (§3.8, §4.3).
///
/// The row is small and the rules around it are the whole of it. Two matter.
///
/// **One address is one repository.** `RepositoryLocation` normalises what was typed, so a project
/// page and a raw index resolve to the same URL, and the unique key on it is what makes adding the
/// same place twice a refusal rather than two rows that refresh each other's extensions.
///
/// **A key is pinned, not followed.** §3.8's trust is trust on first use: what is stored is what the
/// listener saw and accepted. A repository that comes back with a different key is either rotating
/// it properly or is not the repository it was, and nothing here decides which — [acceptNewKey] is a
/// separate, deliberate act, so a rotation can never happen as a side effect of a refresh.
library;

import 'package:drift/drift.dart';

import '../database/database.dart';

/// Every repository, in the order they were added.
Stream<List<RepositoryRow>> watchRepositories(KikuyomiDatabase db) =>
    (db.select(
      db.repositories,
    )..orderBy([(r) => OrderingTerm.asc(r.id)])).watch();

/// Every repository, once, for a job that is not watching a screen -- an update check reads the
/// list, works through it and is done.
Future<List<RepositoryRow>> readRepositories(KikuyomiDatabase db) => (db.select(
  db.repositories,
)..orderBy([(r) => OrderingTerm.asc(r.id)])).get();

/// The repository at [url], or null when it has not been added.
Future<RepositoryRow?> readRepositoryAt(KikuyomiDatabase db, String url) =>
    (db.select(
      db.repositories,
    )..where((r) => r.url.equals(url))).getSingleOrNull();

/// Adds a repository whose key the listener has just accepted, and gives its id.
///
/// Throws when [url] is already there. The caller checks first so it can say "you already have this
/// one" rather than showing a database error, but the key stays, because a check followed by an
/// insert is two steps and a listener with two windows open is one race.
Future<int> addRepository(
  KikuyomiDatabase db, {
  required String url,
  required String name,
  required String publicKey,
  required String fingerprint,
}) => db
    .into(db.repositories)
    .insert(
      RepositoriesCompanion.insert(
        url: url,
        name: name,
        publicKey: publicKey,
        fingerprint: fingerprint,
      ),
    );

/// Records what a refresh came back with.
///
/// [etag] is written as given, including null: a repository that has stopped sending one must stop
/// being asked conditionally, or every refresh would carry a tag the server no longer knows.
///
/// [name] is taken afresh because a repository may rename itself, which is a thing it is allowed to
/// do and costs the listener nothing.
Future<void> recordRepositoryFetch(
  KikuyomiDatabase db,
  int id, {
  required DateTime at,
  String? etag,
  String? name,
}) async {
  await (db.update(db.repositories)..where((r) => r.id.equals(id))).write(
    RepositoriesCompanion(
      etag: Value(etag),
      lastFetchedAt: Value(at),
      name: name == null ? const Value.absent() : Value(name),
    ),
  );
}

/// Pins a new key for [id], after the listener has been shown it and accepted it (§3.8).
///
/// Its own function, and never part of recording a fetch, so that a key can only change where
/// somebody decided it should. The tag goes with it: an index signed by a new key is not the index
/// that was cached under the old one.
Future<void> acceptNewKey(
  KikuyomiDatabase db,
  int id, {
  required String publicKey,
  required String fingerprint,
}) async {
  await (db.update(db.repositories)..where((r) => r.id.equals(id))).write(
    RepositoriesCompanion(
      publicKey: Value(publicKey),
      fingerprint: Value(fingerprint),
      etag: const Value(null),
    ),
  );
}

/// Forgets repository [id].
///
/// Only the repository. Extensions installed from it stay installed and keep working, for the reason
/// §3.9 gives for uninstalling: the listener's library is not the repository's to take away. What
/// they lose is updates, which is what removing a repository means.
Future<void> removeRepository(KikuyomiDatabase db, int id) =>
    (db.delete(db.repositories)..where((r) => r.id.equals(id))).go();
