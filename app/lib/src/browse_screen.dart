import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikuyomi_domain/kikuyomi_domain.dart';

import 'app_shell.dart';
import 'extensions_screen.dart';
import 'providers.dart';
import 'routes.dart';
import 'sources/source_registry.dart';
import 'sources_view.dart';

/// Browse: the sources you can read from, and the extensions they come from (§2.6, §3.9).
///
/// Two tabs, because they are two different questions. Sources is "where shall I look for something
/// to listen to", which is what a listener opens Browse for. Extensions is "what is installed", which
/// is housekeeping — and it used to be a button in this screen's app bar, which made the thing you
/// want most and the thing you want rarely look equally important.
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
  late final TabController _tabs = TabController(length: 2, vsync: this)
    ..addListener(() => setState(() {}));

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final onExtensions = _tabs.index == 1;
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
          tabs: const [
            Tab(text: 'Sources'),
            Tab(text: 'Extensions'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          SourcesView(
            // Watched, so a source installed on the other tab is here when the listener comes back.
            sources: ref.watch(sourceListProvider).value ?? const [],
            extensions: ref.watch(extensionsByIdProvider),
            pinned: ref.watch(pinnedSourcesProvider).value ?? const [],
            recent: ref.watch(recentSourcesProvider).value ?? const [],
            onOpen: _open,
            onTogglePin: _togglePin,
          ),
          const ExtensionsPanel(),
        ],
      ),
    );
  }

  /// Opens a source, and remembers that it was the last one used.
  ///
  /// Recorded here rather than in the source's own screen: what this list wants to know is which
  /// sources the listener reaches for, and reaching for one is this tap.
  Future<void> _open(SourceDescription source) async {
    if (!source.canBrowse) {
      const HomeRoute().go(context);
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
