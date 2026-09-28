import 'package:kikuyomi_source_api/kikuyomi_source_api.dart';

import '../services.dart';
import 'source_registry.dart';

/// What a book at a source looks like before it is in the library: its details and its chapters.
typedef SourceBookPreview = ({BookDetails details, List<ChapterInfo> chapters});

/// Everything the Browse screens need of the rest of the app.
///
/// An interface rather than [AppServices] itself, for one reason: a widget test can stand in for it
/// with a fake source and no database, no engine and no network, which is the only way the screens'
/// own wiring — a search submitted, a filter applied, a book added and then opened — can be tested
/// at all. §2.8 keeps the real implementation in the composition root.
abstract interface class SourceGateway {
  /// Every source the app offers, from manifests alone (§3.6). Reading it runs no extension code.
  List<SourceDescription> get sources;

  /// The sources again, after every extension installed or removed, so a list of them follows what the
  /// listener does on the Extensions screen.
  Stream<List<SourceDescription>> get sourceChanges;

  /// The source with [sourceId], as the contract describes one, starting its extension's runtime on
  /// first use.
  ///
  /// Fails with an `ExtensionLoadException` for an extension that will not load.
  Future<ContentSource> open(int sourceId);

  /// What the source says about one of its books, and what is in it.
  Future<SourceBookPreview> preview(int sourceId, String bookKey);

  /// Puts the book in the library and returns its id. From then on it is a book like any other.
  Future<int> addToLibrary({
    required int sourceId,
    required BookDetails details,
    required List<ChapterInfo> chapters,
  });

  /// The source with [sourceId], or null when this app does not know it.
  SourceDescription? describe(int sourceId) =>
      sources.where((source) => source.id == sourceId).firstOrNull;

  /// What to call the source in a message. A source the app does not know still has to be talked
  /// about, because a location can name one.
  String nameOf(int sourceId) => describe(sourceId)?.name ?? 'This source';
}

/// The gateway over the running app.
final class AppSourceGateway implements SourceGateway {
  const AppSourceGateway(this._services);

  final AppServices _services;

  @override
  List<SourceDescription> get sources => _services.sources.sources;

  @override
  Stream<List<SourceDescription>> get sourceChanges =>
      _services.sources.changes;

  @override
  Future<ContentSource> open(int sourceId) => _services.openSource(sourceId);

  @override
  Future<SourceBookPreview> preview(int sourceId, String bookKey) =>
      _services.previewSourceBook(sourceId, bookKey);

  @override
  Future<int> addToLibrary({
    required int sourceId,
    required BookDetails details,
    required List<ChapterInfo> chapters,
  }) => _services.publishesWholeBooks(sourceId)
      // The book is one file: adding it downloads it, and its chapters are the file's own.
      ? _services.addSourceBookFile(sourceId: sourceId, details: details)
      : _services.addSourceBook(
          sourceId: sourceId,
          details: details,
          chapters: chapters,
        );

  @override
  SourceDescription? describe(int sourceId) =>
      _services.sources.describe(sourceId);

  @override
  String nameOf(int sourceId) => describe(sourceId)?.name ?? 'This source';
}
