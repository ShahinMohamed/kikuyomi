/// Repositories, index fetching, install and update, signatures, trust store, `SourceRegistry`.
///
/// Registration is manifest-first: runtimes are created lazily and pooled rather than started for
/// every installed extension at launch (§3.6).
///
/// So far it holds the manifest — what an extension says about itself before any of its code runs,
/// and whether this app's contract version can run it — the package around that manifest,
/// installing one into the app's own storage, and the repository door: reading an index, checking
/// that the repository's pinned key signed what it offers, and taking a package from it (§3.8,
/// §3.9).
///
/// Pure Dart. This package must never import Flutter or a platform plugin.
library;

export 'src/install.dart';
export 'src/manifest.dart';
export 'src/package.dart';
export 'src/repository/fetch.dart';
export 'src/repository/index.dart';
export 'src/repository/package_zip.dart';
export 'src/repository/signature.dart';
export 'src/repository/location.dart';
