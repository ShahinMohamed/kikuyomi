/// Fetching what a repository publishes (§3.8, §3.9).
///
/// Two documents: `repo.json`, which says who the repository is and what key it signs with, and
/// `index.json`, which says what it offers. Both go through the app's one transport, so a repository
/// gets the same User-Agent, timeouts, body limits and per-host rate limiting everything else does,
/// and a repository that stops answering fails the same way a source does.
///
/// **The index is cached by its ETag.** A listener with a dozen repositories refreshes all of them
/// on the same schedule, and an index that has not changed is the ordinary case. Sending the ETag
/// back turns that into a 304 and no body at all, which is the difference between a refresh costing
/// a few hundred bytes and costing a megabyte of JSON nobody needed.
///
/// **`repo.json` is fetched every time.** It is tiny, and it carries the signing key: a key rotation
/// is precisely the thing that must not be missed because a cached index looked unchanged (§3.8).
library;

import 'dart:convert';

import 'package:kikuyomi_networking/kikuyomi_networking.dart';

import 'index.dart';
import 'location.dart';
import 'package_zip.dart';

/// What a refresh came back with.
final class RepositoryFetch {
  const RepositoryFetch({required this.info, this.index, this.etag});

  /// Who the repository says it is, and the key it signs with. Always read afresh.
  final RepositoryInfo info;

  /// What it offers, or null when it answered that nothing has changed since [etag] was issued.
  /// Null means keep what was stored, not that the repository is empty.
  final RepositoryIndex? index;

  /// What to send back next time, when the repository gave one.
  final String? etag;

  /// Whether the index is the one already held.
  bool get unchanged => index == null;
}

/// Reads a repository over HTTPS.
final class RepositoryFetcher {
  const RepositoryFetcher(this._http);

  final SourceHttpClient _http;

  /// Reads [at], sending [etag] back so an unchanged index costs nothing.
  ///
  /// Throws [RepositoryException] for anything that leaves the app without a readable repository:
  /// a status that is not an answer, a body that is not the document it should be, a host that
  /// never replied.
  Future<RepositoryFetch> fetch(RepositoryLocation at, {String? etag}) async {
    final info = RepositoryInfo.parse(
      await _read(at.repoJson, what: 'repo.json'),
    );

    final response = await _send(
      at.indexJson,
      // Only when there is something to compare against. An `If-None-Match` of nothing is a header
      // some servers answer 304 to, which would leave the app holding an index it never had.
      headers: etag == null ? const {} : {'if-none-match': etag},
    );
    if (response.status == 304) {
      return RepositoryFetch(info: info, etag: etag);
    }
    return RepositoryFetch(
      info: info,
      index: RepositoryIndex.parse(_bodyOf(response, 'index.json')),
      // A repository that stopped sending one is not an error; it means asking again next time.
      etag: response.headers['etag'],
    );
  }

  /// Downloads the package at [where] and checks it is the one the index named (§3.8).
  ///
  /// The hash is what catches a truncated or corrupted download, and it is all it catches: it proves
  /// the bytes are the ones the index listed and nothing about who wrote the index. Verifying that
  /// is what the signature is for, and nothing does it yet (ADR-0018).
  ///
  /// Throws [RepositoryException] when it could not be fetched, and [PackageRefused] when what
  /// arrived is not what was listed.
  Future<ZipExtensionFiles> downloadPackage(
    PackageLocation where, {
    required String description,
  }) async {
    final response = await _send(Uri.parse(where.url));
    if (response.status != 200) {
      throw RepositoryException(
        '${where.url} answered ${response.status} for the package',
      );
    }
    return ZipExtensionFiles.verified(
      response.body,
      expected: where,
      description: description,
    );
  }

  Future<String> _read(Uri url, {required String what}) async =>
      _bodyOf(await _send(url), what);

  Future<NetworkResponse> _send(
    Uri url, {
    Map<String, String> headers = const {},
  }) async {
    try {
      return await _http.send(NetworkRequest(url: url, headers: headers));
    } on NetworkFailure catch (error) {
      throw RepositoryException('${url.host} did not answer: ${error.message}');
    } on NetworkLimitReached catch (error) {
      throw RepositoryException('${url.host} answered too much: $error');
    }
  }

  /// The body, once the status says there is one worth reading.
  ///
  /// A 404 is worth its own sentence: it is what a listener gets for pasting a page that is not a
  /// repository at all, which is the most likely thing to go wrong here and the least obvious from
  /// a bare status code.
  String _bodyOf(NetworkResponse response, String what) {
    if (response.status == 404) {
      throw RepositoryException(
        'there is no $what at ${response.url}, so this does not look like a '
        'repository',
      );
    }
    if (response.status != 200) {
      throw RepositoryException(
        '${response.url} answered ${response.status} for $what',
      );
    }
    try {
      return utf8.decode(response.body);
    } on FormatException {
      throw RepositoryException('$what is not text');
    }
  }
}
