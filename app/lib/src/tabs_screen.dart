import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_shell.dart';

/// Arranging the tabs of the shell.
///
/// Which tabs matter is not the same for everyone: someone who only reads wants Read first, and
/// someone who never downloads wants Downloads last. Nothing is hidden here, only moved — a tab
/// that could be hidden would be a screen with no way back to it, and everything a tab reaches is
/// worth reaching.
///
/// The order is the order of the bar along the bottom of a phone, and of the rail down the side of
/// a wide window.
class TabsScreen extends ConsumerWidget {
  const TabsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabs = ref.watch(tabOrderProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tabs'),
        actions: [
          TextButton(
            onPressed: tabs == AppTab.values
                ? null
                : () => ref.read(tabOrderProvider.notifier).reset(),
            child: const Text('Reset'),
          ),
        ],
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Drag a tab to move it. The first is where the app opens.',
            ),
          ),
          Expanded(
            child: ReorderableListView(
              padding: const EdgeInsets.only(bottom: 24),
              onReorderItem: (from, to) {
                final moved = [...tabs];
                moved.insert(to, moved.removeAt(from));
                ref.read(tabOrderProvider.notifier).reorder(moved);
              },
              children: [
                for (final (position, tab) in tabs.indexed)
                  ListTile(
                    key: ValueKey(tab),
                    leading: Icon(tab.selectedIcon),
                    title: Text(tab.label),
                    trailing: ReorderableDragStartListener(
                      index: position,
                      child: const Icon(Icons.drag_handle),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
