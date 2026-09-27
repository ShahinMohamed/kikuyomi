import 'package:flutter/material.dart';
import 'package:kikuyomi_data/kikuyomi_data.dart' show CategoryRow;

/// Choosing which shelves a book sits on (Phase 4).
///
/// The whole set at once rather than one category at a time, because a book belongs to any number
/// of them and "which shelves is this on" is one question. What comes back is the set to file it
/// under, or null if the listener changed their mind — and an empty set is a real answer, meaning
/// take it off every shelf, which is why it is not conflated with null.
Future<Set<int>?> chooseBookCategories(
  BuildContext context, {
  required String bookTitle,
  required List<CategoryRow> categories,
  required Set<int> chosen,
  required VoidCallback onManageCategories,
}) => showDialog<Set<int>>(
  context: context,
  builder: (context) => _FileBookDialog(
    bookTitle: bookTitle,
    categories: categories,
    chosen: chosen,
    onManageCategories: onManageCategories,
  ),
);

class _FileBookDialog extends StatefulWidget {
  const _FileBookDialog({
    required this.bookTitle,
    required this.categories,
    required this.chosen,
    required this.onManageCategories,
  });

  final String bookTitle;
  final List<CategoryRow> categories;
  final Set<int> chosen;
  final VoidCallback onManageCategories;

  @override
  State<_FileBookDialog> createState() => _FileBookDialogState();
}

class _FileBookDialogState extends State<_FileBookDialog> {
  late final Set<int> _chosen = {...widget.chosen};

  @override
  Widget build(BuildContext context) {
    if (widget.categories.isEmpty) {
      // Nothing to choose between. Offering an empty list with a Save button would be asking a
      // question with no answers; the useful thing is the way to make one.
      return AlertDialog(
        title: const Text('No categories yet'),
        content: const Text(
          'Categories are the shelves you file books under. Make one, then '
          'come back here to put this book on it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onManageCategories();
            },
            child: const Text('Manage categories'),
          ),
        ],
      );
    }

    return AlertDialog(
      title: Text('Categories for ${widget.bookTitle}'),
      content: SizedBox(
        width: 360,
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final category in widget.categories)
              CheckboxListTile(
                value: _chosen.contains(category.id),
                title: Text(category.name),
                onChanged: (on) => setState(() {
                  if (on ?? false) {
                    _chosen.add(category.id);
                  } else {
                    _chosen.remove(category.id);
                  }
                }),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            widget.onManageCategories();
          },
          child: const Text('Manage'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _chosen),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
