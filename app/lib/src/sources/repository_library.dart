/// The repositories the listener has added, and what they offer (§3.8, §3.9).
///
/// The app's side of the repository door: it holds the fetcher and the table together, and it is
/// where trust on first use actually happens. §3.8 asks for a fingerprint to be shown and accepted
/// before a repository is kept, so adding one is deliberately two steps — [look] reads what is there
/// and returns without writing anything, and [accept] is what pins the key. Nothing else stores a
/// key, so a key can only ever arrive by somebody agreeing to it.
///
/// **What the pinned key then does.** Every index the fetcher reads must be signed by the key it
/// publishes, and every package installed must be signed by the key in the row — the one the
/// listener actually agreed to. That is the whole of what trust on first use buys: the listener
/// judges a repository once, and afterwards the app holds it to that, so a repository that changes
/// hands cannot quietly start shipping other people's code.
///
/// **An index is held in memory, not in the database.** §4.3's `repository` row keeps where a
/// repository is, who it is and its key; what it offers is a listing, re-read rather than stored.
/// That means the stored ETag is only sent when there is a cached index to compare against — sending
/// it on a cold start would invite a 304 answering a question the app cannot then answer, leaving it
/// holding nothing. So a refresh within a session is cheap and the first browse after a restart is
/// a full fetch. Persisting the listing is what would change that, and it needs a table §4.3 does
/// not have.
library;

import 'package:kikuyomi_data/kikuyomi_data.dart';
import 'package:kikuyomi_domain/kikuyomi_domain.dart';
import 'package:kikuyomi_extension_manager/kikuyomi_extension_manager.dart';

/// What was found at an address, before anything has been kept.
final class RepositoryOffer {
  const RepositoryOffer({
    required this.at,
    required this.info,
    required this.index,
    required this.alreadyAdded,
  });

  /// Where its documents are, as the listener's address was understood.
  final RepositoryLocation at;

  /// Who it says it is, and the key it signs with.
  final RepositoryInfo info;

  /// What it offers.
  final RepositoryIndex index;

  /// Whether this address is already in the list, so the screen can say so rather than showing the
  /// database refusing a second row.
  final bool alreadyAdded;

  /// What the listener is being asked to accept (§3.8).
  String get fingerprint => info.fingerprint;

  /// How many extensions are on offer, leaving out the versions that have been withdrawn.
  int get offers => index.offered.length;
}

/// The repositories, and what can be done with them.
final class RepositoryLibrary {
  RepositoryLibrary({
    required this._database,
    required this._fetcher,
    required this._clock,
  });

  final KikuyomiDatabase _database;
  final RepositoryFetcher _fetcher;
  final Clock _clock;

  /// The last listing read from each repository, by row id. See this library's note.
  final _indexes = <int, RepositoryIndex>{};

  /// Every repository, watched, so a screen follows an add or a removal (§2.5).
  Stream<List<RepositoryRow>> watch() => watchRepositories(_database);

  /// Reads what is at [typed] without keeping any of it.
  ///
  /// The first of adding a repository's two steps: this is what produces the fingerprint §3.8 shows
  /// the listener. Throws [RepositoryException] when the address names nowhere, nowhere safe, or
  /// nothing that is a repository.
  Future<RepositoryOffer> look(String typed) async {
    final at = RepositoryLocation.parse(typed);
    final fetched = await _fetcher.fetch(at);
    final index = fetched.index;
    if (index == null) {
      // Nothing was sent to compare against, so a repository answering "unchanged" is answering a
      // question nobody asked.
      throw const RepositoryException(
        'that repository answered that nothing had changed, without being asked',
      );
    }
    return RepositoryOffer(
      at: at,
      info: fetched.info,
      index: index,
      alreadyAdded:
          await readRepositoryAt(_database, at.base.toString()) != null,
    );
  }

  /// Keeps [offer], pinning the key the listener has just accepted, and gives its id.
  ///
  /// The second step, and the only thing anywhere that writes a key for a repository that had none.
  Future<int> accept(RepositoryOffer offer) async {
    final id = await addRepository(
      _database,
      url: offer.at.base.toString(),
      name: offer.info.name,
      publicKey: offer.info.publicKey,
      fingerprint: offer.info.fingerprint,
    );
    _indexes[id] = offer.index;
    await recordRepositoryFetch(_database, id, at: _clock.now());
    return id;
  }

  /// What [repository] offers, fetching it if this run has not already.
  Future<RepositoryIndex> browse(RepositoryRow repository) async {
    final held = _indexes[repository.id];
    if (held != null) return held;
    return refresh(repository);
  }

  /// Reads [repository] again and keeps what it says.
  ///
  /// The stored tag is sent only when there is a listing to fall back on, so an unchanged answer
  /// always has something to mean.
  Future<RepositoryIndex> refresh(RepositoryRow repository) async {
    final held = _indexes[repository.id];
    final fetched = await _fetcher.fetch(
      RepositoryLocation(Uri.parse(repository.url)),
      etag: held == null ? null : repository.etag,
    );

    // §3.8: a key that has changed is either a rotation the operator meant or a repository that is
    // not the one it was, and nothing here may decide which. Verifying signatures does not help:
    // the new key verifies the new index perfectly, which is exactly what someone who had taken the
    // repository over would arrange. Telling the two apart needs the new key signed by the old one,
    // and the format has nowhere to put that (ADR-0018). So the safe answer is to stop.
    if (fetched.info.publicKey != repository.publicKey) {
      throw RepositoryException(
        '${repository.name} is signing with a different key than the one you '
        'accepted. Remove it and add it again only if you know why it changed.',
      );
    }

    final index = fetched.index ?? held!;
    _indexes[repository.id] = index;
    await recordRepositoryFetch(
      _database,
      repository.id,
      at: _clock.now(),
      etag: fetched.etag,
      name: fetched.info.name,
    );
    return index;
  }

  /// Downloads [entry]'s package, checking [repository]'s pinned key signed it and that the bytes
  /// are the ones the listing named (§3.8).
  ///
  /// The key comes from the row rather than from the last fetch, because the row is where the
  /// listener's decision was written down. A fetch reads whatever the repository is serving today;
  /// only one of the two was ever agreed to.
  ///
  /// Stops short of installing it, which is `ExtensionLibrary`'s: the package is a package whatever
  /// door it came through, and there should be one path that unpacks, checks and records one.
  Future<ZipExtensionFiles> fetchPackage(
    RepositoryRow repository,
    RepositoryEntry entry,
  ) => _fetcher.downloadPackage(
    entry,
    publicKey: repository.publicKey,
    description: '${entry.manifest.name} ${entry.manifest.version}',
  );

  /// Forgets [repository]. Extensions installed from it stay installed (§3.9); what is lost is
  /// updates.
  Future<void> remove(RepositoryRow repository) async {
    _indexes.remove(repository.id);
    await removeRepository(_database, repository.id);
  }
}
