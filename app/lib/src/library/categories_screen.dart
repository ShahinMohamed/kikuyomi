import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikuyomi_data/kikuyomi_data.dart';

import '../providers.dart';
import '../snack_bars.dart';

/// Making, renaming, reordering and deleting the listener's shelves (Phase 4).
///
/// Everything is watched, so a change appears without a refresh (§2.5), and every write goes
/// straight to the database rather than being held here and saved at the end — there is no Save
/// button, so there is nothing to lose by leaving.
class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider).value ?? const [];
    final counts = ref.watch(categoryCountsProvider).value ?? const {};
    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _create(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('New category'),
      ),
      body: categories.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No categories yet. Make one, then file books under it from '
                  'a book’s page.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ReorderableListView.builder(
              padding: const EdgeInsets.only(bottom: 96),
              itemCount: categories.length,
              onReorderItem: (from, to) => _reorder(ref, categories, from, to),
              itemBuilder: (context, index) {
                final category = categories[index];
                final held = counts[category.id] ?? 0;
                return ListTile(
                  key: ValueKey(category.id),
                  leading: const Icon(Icons.drag_handle),
                  title: Text(category.name),
                  subtitle: Text(held == 1 ? '1 book' : '$held books'),
                  trailing: PopupMenuButton<VoidCallback>(
                    tooltip: 'Options for ${category.name}',
                    onSelected: (action) => action(),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: () => _rename(context, ref, category),
                        child: const Text('Rename'),
                      ),
                      PopupMenuItem(
                        value: () => _delete(context, ref, category),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final name = await _askForName(context, title: 'New category');
    if (name == null || !context.mounted) return;
    await _write(
      context,
      () => createCategory(ref.read(servicesProvider).database, name),
    );
  }

  Future<void> _rename(
    BuildContext context,
    WidgetRef ref,
    CategoryRow category,
  ) async {
    final name = await _askForName(
      context,
      title: 'Rename ${category.name}',
      initial: category.name,
    );
    if (name == null || !context.mounted) return;
    await _write(
      context,
      () => renameCategory(
        ref.read(servicesProvider).database,
        category.id,
        name,
      ),
    );
  }

  /// Deletes [category], having said what that does and what it does not.
  ///
  /// The sentence matters: a listener about to delete a shelf does not know whether the books go
  /// with it, and the answer is no. Asking without saying so would make Delete a leap.
  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    CategoryRow category,
  ) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Delete ${category.name}?'),
            content: const Text(
              'The books in it stay in your library, with their progress and '
              'their downloads. They stop being in this category, and that is '
              'all.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !context.mounted) return;
    await deleteCategory(ref.read(servicesProvider).database, category.id);
  }

  Future<void> _reorder(
    WidgetRef ref,
    List<CategoryRow> categories,
    int from,
    int to,
  ) async {
    // `onReorderItem` gives the index the row lands at once it has been taken out, so [to] is used
    // as it comes. Its predecessor `onReorder` reported the index before the removal and needed
    // adjusting for a move downwards, which is the mistake this callback exists to stop.
    final ids = [for (final category in categories) category.id];
    ids.insert(to, ids.removeAt(from));
    await reorderCategories(ref.read(servicesProvider).database, ids);
  }

  Future<void> _write(BuildContext context, Future<void> Function() run) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await run();
    } on CategoryNameRefused catch (error) {
      tellInSnackBar(messenger, error.message);
    }
  }

  Future<String?> _askForName(
    BuildContext context, {
    required String title,
    String initial = '',
  }) {
    final controller = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Name'),
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
