import 'dart:io';

import 'package:flutter/material.dart';

import 'sources/source_registry.dart';

/// The sources, grouped the way a listener looks for one (§2.6).
///
/// Three groups, in this order. **Last used** is one row, and it is the one most taps go to: coming
/// back to Browse usually means going back where you were. **Pinned** is what the listener said
/// they want near the top. Then everything else, **by language**, because a list of thirty sources
/// is unreadable in one run and language is what actually divides them.
///
/// A source appears in every group it belongs to rather than being removed from the ones below.
/// That looks like duplication and is not: the groups answer different questions — "where was I",
/// "what did I choose", "what is there" — and a pinned source vanishing from its language would
/// make the language list wrong.
///
/// Fed with descriptions rather than watching the registry, so it can be tested without one.
class SourcesView extends StatelessWidget {
  const SourcesView({
    super.key,
    required this.sources,
    required this.onOpen,
    this.icons = const {},
    this.pinned = const [],
    this.recent = const [],
    this.onTogglePin,
  });

  final List<SourceDescription> sources;

  /// Where each extension's icon is on this device, by extension id. A source whose extension has
  /// none falls back to a glyph.
  final Map<String, String> icons;

  /// Source ids the listener pinned, most recently pinned first.
  final List<int> pinned;

  /// Source ids most recently browsed, most recent first.
  final List<int> recent;

  final ValueChanged<SourceDescription> onOpen;

  /// Pins a source, or unpins one already pinned. Null where pinning is not offered.
  final ValueChanged<SourceDescription>? onTogglePin;

  @override
  Widget build(BuildContext context) {
    if (sources.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No sources yet. Extensions you install will appear here.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final byId = {for (final source in sources) source.id: source};
    final lastUsed = recent
        .map((id) => byId[id])
        .whereType<SourceDescription>()
        .take(1)
        .toList();
    final pinnedSources = pinned
        .map((id) => byId[id])
        .whereType<SourceDescription>()
        .toList();

    // Grouped by language, and each group in the order the registry gave, which is by name.
    final byLanguage = <String, List<SourceDescription>>{};
    for (final source in sources) {
      (byLanguage[source.lang] ??= []).add(source);
    }
    final languages = byLanguage.keys.toList()
      ..sort((a, b) => _languageName(a).compareTo(_languageName(b)));

    return ListView(
      children: [
        if (lastUsed.isNotEmpty) ...[
          const _Heading('Last used'),
          for (final source in lastUsed) _row(source),
        ],
        if (pinnedSources.isNotEmpty) ...[
          const _Heading('Pinned'),
          for (final source in pinnedSources) _row(source),
        ],
        for (final language in languages) ...[
          _Heading(_languageName(language)),
          for (final source in byLanguage[language]!) _row(source),
        ],
      ],
    );
  }

  Widget _row(SourceDescription source) => _SourceTile(
    source: source,
    iconPath: source.extensionId == null ? null : icons[source.extensionId],
    pinned: pinned.contains(source.id),
    onOpen: () => onOpen(source),
    onTogglePin: onTogglePin == null ? null : () => onTogglePin!(source),
  );

  /// A language tag as a heading. `multi` is a real answer a manifest gives, not a missing one.
  static String _languageName(String lang) =>
      lang == 'multi' ? 'Several languages' : lang.toUpperCase();
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
    child: Text(
      text,
      style: Theme.of(context).textTheme.titleSmall
          ?.copyWith(color: Theme.of(context).colorScheme.primary),
    ),
  );
}

class _SourceTile extends StatelessWidget {
  const _SourceTile({
    required this.source,
    required this.iconPath,
    required this.pinned,
    required this.onOpen,
    required this.onTogglePin,
  });

  final SourceDescription source;
  final String? iconPath;
  final bool pinned;
  final VoidCallback onOpen;
  final VoidCallback? onTogglePin;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: _SourceIcon(source: source, iconPath: iconPath),
    title: Text(source.name),
    subtitle: Text(_describe(source)),
    trailing: onTogglePin == null || !source.canBrowse
        ? const Icon(Icons.chevron_right)
        : IconButton(
            icon: Icon(pinned ? Icons.push_pin : Icons.push_pin_outlined),
            tooltip: pinned ? 'Unpin ${source.name}' : 'Pin ${source.name}',
            onPressed: onTogglePin,
          ),
    onTap: onOpen,
  );

  static String _describe(SourceDescription source) => source.canBrowse
      ? '${SourcesView._languageName(source.lang)} · ${source.extensionId}'
      : 'Books you added from this device';
}

/// A source's icon: its extension's, or a glyph for the ones that have none.
///
/// The local files source is not an extension and never will have one, so its folder glyph is the
/// right answer rather than a missing icon.
class _SourceIcon extends StatelessWidget {
  const _SourceIcon({required this.source, required this.iconPath});

  final SourceDescription source;
  final String? iconPath;

  @override
  Widget build(BuildContext context) {
    final path = iconPath;
    if (path == null) {
      return Icon(source.canBrowse ? Icons.public : Icons.folder_outlined);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Image.file(
        File(path),
        width: 32,
        height: 32,
        errorBuilder: (context, _, _) => const Icon(Icons.public),
      ),
    );
  }
}
