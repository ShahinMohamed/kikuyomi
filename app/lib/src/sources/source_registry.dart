import 'dart:async';

import 'package:kikuyomi_data/kikuyomi_data.dart';
import 'package:kikuyomi_extension_manager/kikuyomi_extension_manager.dart';
import 'package:kikuyomi_networking/kikuyomi_networking.dart';
import 'package:kikuyomi_source_api/kikuyomi_source_api.dart';
import 'package:kikuyomi_source_runtime/kikuyomi_source_runtime.dart';

import 'extension_packages.dart';

/// One source the app knows of, from its manifest alone.
///
/// §3.6: "The `SourceRegistry` knows every installed source from manifests alone. App launch never
/// executes extension code, which is what keeps hundreds of installed sources cheap." So everything
/// a source list shows is here, and nothing here has run a line of JavaScript.
final class SourceDescription {
  const SourceDescription({
    required this.id,
    required this.key,
    required this.name,
    required this.lang,
    required this.capabilities,
    this.extensionId,
    this.contentRating,
    this.isMissing = false,
    this.kind = SourceKind.audio,
  });

  /// The §3.7 id: the first 8 bytes of SHA-256 over `{extensionId}/{sourceKey}/{lang}/{versionId}`,
  /// or [localSourceId] for the built-in Local files source.
  final int id;
  final String key;
  final String name;

  /// A BCP 47 tag, or `multi` for a catalogue that is not one language.
  final String lang;

  /// What the manifest says the source can do. What it really has is asked of the extension when it
  /// is first opened, so a manifest that over-claims costs a tab, never a failed tap.
  ///
  /// Empty for a source whose extension is gone: nothing is left to ask.
  final Set<SourceCapability> capabilities;

  /// Null for a built-in source.
  final String? extensionId;
  final String? contentRating;

  /// Whether the extension this source came from is no longer installed.
  ///
  /// §3.9: uninstalling keeps the listener's data, and "library books from that source keep their
  /// metadata, progress, and downloads, and point to a stub source until the extension returns or the
  /// books are migrated". This is that stub. It exists so the library can still name the source a book
  /// came from, and so opening it fails with a sentence rather than with nothing.
  final bool isMissing;

  /// Books to listen to or books to read (ADR-0019), as the manifest declares. Browse lists the two
  /// under tabs of their own.
  ///
  /// A stub's is not known, since the manifest that said is gone; it reads as audio, which is what
  /// every source was before 1.1 and what its books will say they are in any case.
  final SourceKind kind;

  /// Whether a listener can browse this source's catalogue.
  ///
  /// False for Local files, whose books come from the device and are the library itself. The Local
  /// source proper (§3.10) will implement the contract and browse folders; until it does, Browse lists
  /// it and sends the listener to the library rather than pretending to have a catalogue.
  bool get canBrowse => extensionId != null && !isMissing;
}

/// A source whose extension is no longer installed (§3.9).
///
/// Not an [ExtensionLoadException]: nothing failed to load, and there is nothing to retry. The one
/// thing that helps is installing the extension again, and the message says so.
final class ExtensionMissingException implements Exception {
  const ExtensionMissingException(this.extensionId);

  final String extensionId;

  @override
  String toString() => 'the extension $extensionId is not installed';
}

/// Every source the app offers, and the runtimes behind them (§3.6).
///
/// **What it does at start.** Takes the extensions the app has read — the bundled ones and those
/// installed — works out each source's id, and writes a `source` row for each (§4.3). No extension
/// code runs. Sources whose extension is no longer installed are listed too, as §3.9's stubs.
///
/// **What it does on first use.** [open] starts that extension's runtime in a worker isolate of its
/// own and keeps it. One worker per extension, as §3.6 has it; the pool with least-recently-used
/// eviction goes in front of this, not inside it.
///
/// **What it does when the listener installs or removes one.** [adopt] and [forget] take an extension
/// in or out while the app runs, stopping its runtime and telling everything that watches [changes].
final class SourceRegistry {
  SourceRegistry._(
    this._database,
    this._network,
    this._store,
    this._log,
    this._host,
    this._engineFactory,
    this._appVersion,
    List<LoadedExtension> extensions,
  ) : _extensions = {for (final e in extensions) e.manifest.id: e};

  /// Registers every source of [extensions], and the built-in Local one.
  ///
  /// An extension this app cannot run (§3.7) is left out with a word to [onError], rather than offered
  /// and then failing when it is tapped. It stays installed: an app update may be what it is waiting
  /// for.
  static Future<SourceRegistry> start({
    required KikuyomiDatabase database,
    required NetworkService network,
    required ExtensionStore store,
    required ExtensionLogSink log,
    required HostFacts host,
    required ScriptEngineFactory engineFactory,
    required String appVersion,
    required List<LoadedExtension> extensions,
    void Function(String extensionId, Object error, StackTrace stack)? onError,
  }) async {
    final usable = <LoadedExtension>[];
    for (final extension in extensions) {
      final refusal = refusalFor(extension, appVersion);
      if (refusal != null) {
        onError?.call(extension.id, refusal, StackTrace.current);
        continue;
      }
      usable.add(extension);
    }
    final registry = SourceRegistry._(
      database,
      network,
      store,
      log,
      host,
      engineFactory,
      appVersion,
      usable,
    );
    for (final extension in usable) {
      await registry._registerSourcesOf(extension);
    }
    await registry._refreshSources();
    return registry;
  }

  /// Why this app cannot run [extension], or null when it can (§3.7, §3.8).
  ///
  /// The installer asks this before writing anything, so an extension is refused with the reason
  /// rather than installed and then quietly skipped.
  static ExtensionLoadException? refusalFor(
    LoadedExtension extension,
    String appVersion,
  ) {
    final manifest = extension.manifest;
    if (!extension.status.canRun) {
      return ExtensionLoadException(
        manifest.id,
        'it is marked ${extension.status.name}',
      );
    }
    final reason = switch (manifest.compatibility()) {
      ApiCompatibility.supported => null,
      ApiCompatibility.needsNewerApp =>
        'it targets SourceAPI ${manifest.apiVersion}, and this app implements '
            '$apiVersion',
      ApiCompatibility.obsolete =>
        'it targets SourceAPI ${manifest.apiVersion}, which this app no longer '
            'supports',
    };
    if (reason != null) return ExtensionLoadException(manifest.id, reason);
    // The app's own version may carry a build number, which is not part of the comparison.
    final version = SoftwareVersion.parse(appVersion.split('+').first);
    if (!manifest.runsOn(version)) {
      return ExtensionLoadException(
        manifest.id,
        'it needs Kikuyomi ${manifest.minAppVersion} or newer, and this is '
        '$version',
      );
    }
    return null;
  }

  final KikuyomiDatabase _database;
  final NetworkService _network;
  final ExtensionStore _store;
  final ExtensionLogSink _log;
  final HostFacts _host;
  final ScriptEngineFactory _engineFactory;
  final String _appVersion;
  final Map<String, LoadedExtension> _extensions;
  var _sources = const <SourceDescription>[];

  /// The worker of each extension that has been used, and the one being started. Kept as a future, so
  /// two screens opening a source at once join one start rather than racing to make two runtimes.
  final _workers = <String, Future<ExtensionWorker>>{};
  final _opened = <int, ContentSource>{};
  final _changed = StreamController<List<SourceDescription>>.broadcast();

  /// Every source, Local first, then the extensions' in manifest order, then the stubs of extensions
  /// that are gone.
  List<SourceDescription> get sources => _sources;

  /// The sources a listener can browse.
  List<SourceDescription> get browsable => [
    for (final source in _sources)
      if (source.canBrowse) source,
  ];

  /// The sources, again, after every install and removal. A screen listing them watches this.
  Stream<List<SourceDescription>> get changes => _changed.stream;

  /// Every extension the app is running sources from.
  List<LoadedExtension> get extensions => List.of(_extensions.values);

  SourceDescription? describe(int sourceId) =>
      _sources.where((source) => source.id == sourceId).firstOrNull;

  /// Takes [extension] into the registry, or replaces the version of it that was there.
  ///
  /// Its runtime is stopped if one was running, so the next use starts the code just installed. This
  /// is what makes reloading an edited folder work without restarting the app (§3.11).
  ///
  /// Throws [ExtensionLoadException] for an extension this app cannot run, having changed nothing.
  Future<void> adopt(LoadedExtension extension) async {
    final refusal = refusalFor(extension, _appVersion);
    if (refusal != null) throw refusal;
    await _stopRuntimeOf(extension.id);
    _extensions[extension.id] = extension;
    await _registerSourcesOf(extension);
    await _refreshSources();
  }

  /// Takes the extension [extensionId] out of the registry and stops its runtime.
  ///
  /// Its `source` rows stay, and so become §3.9's stubs: the books that came from them keep their
  /// metadata, their progress and their place in the library, and say so when they are opened.
  Future<void> forget(String extensionId) async {
    await _stopRuntimeOf(extensionId);
    _extensions.remove(extensionId);
    await _refreshSources();
  }

  /// Opens the source with [sourceId], starting its extension's runtime if this is its first use.
  ///
  /// Throws [ExtensionMissingException] for a source whose extension has been removed,
  /// [ExtensionLoadException] when the extension will not load, [ArgumentError] for a source this app
  /// does not know, and [UnsupportedError] for one that has no `ContentSource` yet, which today is
  /// only Local files.
  Future<ContentSource> open(int sourceId) async {
    final opened = _opened[sourceId];
    if (opened != null) return opened;

    final description = describe(sourceId);
    if (description == null) {
      throw ArgumentError.value(sourceId, 'sourceId', 'no such source');
    }
    final extensionId = description.extensionId;
    if (extensionId == null) {
      throw UnsupportedError(
        '"${description.name}" has no catalogue to browse: its books come from '
        'this device',
      );
    }
    if (description.isMissing) throw ExtensionMissingException(extensionId);
    final worker = await _workerFor(extensionId);
    final source = await JsSourceAdapter.open(
      runtime: worker,
      sourceKey: description.key,
      kind: description.kind,
    );
    return _opened[sourceId] = source;
  }

  Future<ExtensionWorker> _workerFor(String extensionId) {
    final running = _workers[extensionId];
    if (running != null) return running;
    final extension = _extensions[extensionId];
    if (extension == null) {
      throw ExtensionMissingException(extensionId);
    }
    final starting = ExtensionWorker.start(
      engineFactory: _engineFactory,
      bundle: ExtensionBundle(
        extensionId: extensionId,
        code: extension.code,
        domains: extension.manifest.domains,
      ),
      host: _host,
      bridges: [
        HttpBridge(
          client: httpClientFor(extensionId),
          domains: extension.manifest.domains,
        ),
        StorageBridge(extensionId: extensionId, store: _store),
        LogBridge(extensionId: extensionId, sink: _log),
      ],
    );
    // A start that fails is not remembered, so the next attempt tries again rather than handing back
    // the same failure for the life of the app.
    _workers[extensionId] = starting.catchError((Object error) {
      _workers.remove(extensionId);
      throw error;
    });
    return _workers[extensionId]!;
  }

  /// The transport one extension sees: its own cookie jar and its own rate limits (§2.7). Also what
  /// fetches its covers, so a cover is asked for as politely as a page.
  SourceHttpClient httpClientFor(String extensionId) =>
      _network.clientFor(extensionId);

  /// The extension behind [sourceId], or null for a built-in source.
  String? extensionIdOf(int sourceId) => describe(sourceId)?.extensionId;

  /// Every URL the extension behind [sourceId] may be fetched at, or null for a built-in source and
  /// for one whose extension is gone.
  ///
  /// SourceAPI 1.0 holds cover URLs to the manifest's domains as it holds `http.fetch`, "so the
  /// domains shown on the permissions screen before install are every domain the source can make the
  /// app contact". A cover the app fetches is the app contacting a domain, so it is checked here too,
  /// and again on every redirect.
  DomainAllowlist? domainsOf(int sourceId) {
    final extensionId = extensionIdOf(sourceId);
    return extensionId == null
        ? null
        : _extensions[extensionId]?.manifest.domains;
  }

  /// How to fetch the cover at [url] for a book of [sourceId]: through the source's own
  /// `getImageRequest` when it declares one, and a plain GET otherwise.
  ///
  /// §6.3: "Many sources require specific headers (a referer, a token, cookies)." A source that needs
  /// none declares no `imageRequest` capability, and then nothing is asked of the extension at all —
  /// which is the whole point of declaring capabilities rather than calling to find out.
  Future<HttpRequest> imageRequestFor(int sourceId, Uri url) async {
    final description = describe(sourceId);
    if (description == null ||
        !description.capabilities.contains(SourceCapability.imageRequest)) {
      return HttpRequest(url: url);
    }
    final source = await open(sourceId);
    if (!source.capabilities.contains(SourceCapability.imageRequest)) {
      return HttpRequest(url: url);
    }
    return source.getImageRequest(url);
  }

  /// Stops every runtime. The app does this as it closes; a pool will do it on eviction.
  Future<void> dispose() async {
    final workers = List.of(_workers.values);
    _workers.clear();
    _opened.clear();
    for (final worker in workers) {
      await _stop(worker);
    }
    await _changed.close();
  }

  /// The database rows are written by [open]; kept for callers that want the same connection.
  KikuyomiDatabase get database => _database;

  /// The app's own version, which §3.7's compatibility check needs. An install asks for it, so that a
  /// refusal at install and a refusal at start are the same sentence about the same extension.
  String get appVersion => _appVersion;

  /// Writes a `source` row for each source [extension] declares (§4.3).
  Future<void> _registerSourcesOf(LoadedExtension extension) async {
    final manifest = extension.manifest;
    for (final source in manifest.sources) {
      await registerSource(
        _database,
        id: source.idWithin(manifest.id),
        key: source.key,
        name: source.name,
        lang: source.lang,
        extensionId: manifest.id,
        contentRating: manifest.contentRating.name,
      );
    }
  }

  /// Works out the source list afresh, from the extensions in hand and the rows in the database, and
  /// tells everything that is watching.
  ///
  /// The rows are what make §3.9's stubs possible: a source registered by an extension that is no
  /// longer installed is still a source the library can name.
  Future<void> _refreshSources() async {
    final sources = <SourceDescription>[
      const SourceDescription(
        id: localSourceId,
        key: 'local',
        name: 'Local files',
        lang: 'und',
        capabilities: {},
      ),
    ];
    for (final extension in _extensions.values) {
      final manifest = extension.manifest;
      for (final source in manifest.sources) {
        sources.add(
          SourceDescription(
            id: source.idWithin(manifest.id),
            key: source.key,
            name: source.name,
            lang: source.lang,
            capabilities: manifest.declaredCapabilities,
            extensionId: manifest.id,
            contentRating: manifest.contentRating.name,
            kind: source.kind,
          ),
        );
      }
    }
    final known = {for (final source in sources) source.id};
    // Before listing the stubs, throw away the ones that are not stubs any more. A source row
    // outlives its extension so that the library's books still point somewhere; once the last of
    // those books has gone there is nothing to point, and what is left is a dead row a listener
    // cannot get rid of. Three of them turned up in one library from extensions installed under ids
    // their author has since changed.
    await pruneUnusedSources(_database, keep: known);
    for (final row in await readRegisteredSources(_database)) {
      if (known.contains(row.id) || row.extensionId == null) continue;
      sources.add(
        SourceDescription(
          id: row.id,
          key: row.key,
          name: row.name,
          lang: row.lang,
          capabilities: const {},
          extensionId: row.extensionId,
          contentRating: row.contentRating,
          isMissing: true,
        ),
      );
    }
    _sources = List.unmodifiable(sources);
    if (!_changed.isClosed) _changed.add(_sources);
  }

  /// Stops the runtime of [extensionId], and forgets the sources opened through it, so that the next
  /// use starts afresh.
  Future<void> _stopRuntimeOf(String extensionId) async {
    for (final source in _sources) {
      if (source.extensionId == extensionId) _opened.remove(source.id);
    }
    final worker = _workers.remove(extensionId);
    if (worker != null) await _stop(worker);
  }

  Future<void> _stop(Future<ExtensionWorker> worker) async {
    try {
      await (await worker).dispose();
    } catch (_) {
      // A worker that never started has nothing to stop.
    }
  }
}
