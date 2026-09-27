import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikuyomi_domain/kikuyomi_domain.dart';
import 'package:kikuyomi_source_api/kikuyomi_source_api.dart' show SourceKind;

import 'app_shell.dart';
import 'extensions_screen.dart';
import 'providers.dart';
import 'routes.dart';
import 'sources/source_registry.dart';
import 'sources_view.dart';

/// The sources a Browse tab of [kind] lists.
///
/// Those of that kind, and those with no catalogue, which are Local files and sources whose extension
/// has gone: Local files offers both kinds, since a folder of audio and an EPUB are both books from
/// this device, and a missing source is listed wherever its books might be looked for.
List<SourceDescription> sourcesOfKind(
  List<SourceDescription> sources,
  SourceKind kind,
) => [
  for (final source in sources)
    if (source.kind == kind || !source.canBrowse) source,
];

/// Browse: the sources you can read from, and the extensions they come from (§2.6, §3.9).
///
/// Two tabs, because they are two different questions. Sources is "where shall I look for something
/// to listen to", which is what a listener opens Browse for. Extensions is "what is installed", which
/// is housekeeping — and it used to be a button in this screen's app bar, which made the thing you
/// want most and the thing you want rarely look equally important.
///
/// Each split again by kind (ADR-0019), as Aniyomi splits anime from manga: sources and extensions
/// for listening, and sources and extensions for reading. Four tabs rather than a filter, so that
/// someone who only reads never has to wade through audiobook sources to find their novels.
///
/// The list of sources is read from manifests alone, so opening this screen runs no extension code
/// (§3.6).
class BrowseScreen extends ConsumerStatefulWidget {
  const BrowseScreen({super.key});

  @override
  ConsumerState<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends ConsumerState<BrowseScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 4, vsync: this)
    ..addListener(() => setState(() {}));

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final onExtensions = _tabs.index >= 2;
    final sources = ref.watch(sourceListProvider).value ?? const [];
    return AppShell(
      tab: AppTab.browse,
      appBar: AppBar(
        title: const Text('Browse'),
        // The actions belong to whichever tab is showing. Repositories and the console are about
        // extensions and mean nothing beside a list of sources.
        actions: onExtensions
            ? [
                IconButton(
                  icon: const Icon(Icons.cloud_outlined),
                  tooltip: 'Repositories',
                  onPressed: () =>
                      const RepositoriesRoute().push<void>(context),
                ),
                IconButton(
                  icon: const Icon(Icons.terminal),
                  tooltip: 'Console',
                  onPressed: () =>
                      const ExtensionConsoleRoute().push<void>(context),
                ),
              ]
            : const [],
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(text: 'Audio sources'),
            Tab(text: 'Ebook sources'),
            Tab(text: 'Audio extensions'),
            Tab(text: 'Ebook extensions'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          for (final kind in SourceKind.values)
            SourcesView(
              // Watched, so a source installed on another tab is here when the listener comes back.
              sources: sourcesOfKind(sources, kind),
              extensions: ref.watch(extensionsByIdProvider),
              pinned: ref.watch(pinnedSourcesProvider).value ?? const [],
              recent: ref.watch(recentSourcesProvider).value ?? const [],
              onOpen: (source) => _open(source, kind),
              onTogglePin: _togglePin,
              emptyMessage: switch (kind) {
                SourceKind.audio =>
                  'No sources yet. Extensions you install will appear here.',
                SourceKind.text =>
                  'No sources of books to read yet. Extensions that offer them will '
                      'appear here.',
              },
            ),
          for (final kind in SourceKind.values) ExtensionsPanel(kind: kind),
        ],
      ),
    );
  }

  /// Opens a source, and remembers that it was the last one used.
  ///
  /// Recorded here rather than in the source's own screen: what this list wants to know is which
  /// sources the listener reaches for, and reaching for one is this tap.
  Future<void> _open(SourceDescription source, SourceKind kind) async {
    if (!source.canBrowse) {
      // Local files has no catalogue: its books are the shelf of the kind being browsed.
      switch (kind) {
        case SourceKind.audio:
          const HomeRoute().go(context);
        case SourceKind.text:
          const ReadingRoute().go(context);
      }
      return;
    }
    await _remember(source.id);
    if (mounted) SourceRoute(sourceId: source.id).push<void>(context);
  }

  Future<void> _remember(int sourceId) async {
    final settings = ref.read(servicesProvider).settings;
    final kept = settings.read(AppSettings.recentSources) ?? const <int>[];
    // Most recent first, and short: this is a shortcut to the two or three a listener actually
    // uses, not a record of everywhere they have been.
    final next = [sourceId, ...kept.where((id) => id != sourceId)].take(4);
    await settings.write(AppSettings.recentSources, next.toList());
  }

  Future<void> _togglePin(SourceDescription source) async {
    final settings = ref.read(servicesProvider).settings;
    final kept = settings.read(AppSettings.pinnedSources) ?? const <int>[];
    await settings.write(
      AppSettings.pinnedSources,
      kept.contains(source.id)
          ? [
              for (final id in kept)
                if (id != source.id) id,
            ]
          : [source.id, ...kept],
    );
  }
}
