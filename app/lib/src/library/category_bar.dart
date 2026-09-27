import 'package:flutter/material.dart';
import 'package:kikuyomi_data/kikuyomi_data.dart' show CategoryRow;

/// The shelves above the library, and which one is being shown (Phase 4).
///
/// **"All" is not a category.** It is the absence of a filter, and it is always first, so a listener
/// who has filed nothing sees exactly what they saw before categories existed. A book in no category
/// appears under All and nowhere else, which is what "uncategorised" means without a row having to
/// say it.
///
/// Nothing at all is shown until there is a category to show. A row of one chip saying "All" is a
/// control that cannot do anything, and taking up the width of the window to say so is worse than
/// saying nothing.
class CategoryBar extends StatelessWidget {
  const CategoryBar({
    super.key,
    required this.categories,
    required this.counts,
    required this.selected,
    required this.onSelected,
  });

  final List<CategoryRow> categories;

  /// How many books each holds, by id, for the number beside its name.
  final Map<int, int> counts;

  /// The category being shown, or null for all of them.
  final int? selected;

  final ValueChanged<int?> onSelected;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _Chip(
            label: 'All',
            chosen: selected == null,
            onChosen: () => onSelected(null),
          ),
          for (final category in categories)
            _Chip(
              label: category.name,
              count: counts[category.id] ?? 0,
              chosen: selected == category.id,
              onChosen: () => onSelected(category.id),
            ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.chosen,
    required this.onChosen,
    this.count,
  });

  final String label;

  /// Shown after the name. Null for All, whose count is the library's own and already on screen.
  final int? count;
  final bool chosen;
  final VoidCallback onChosen;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: Center(
      child: ChoiceChip(
        selected: chosen,
        onSelected: (_) => onChosen(),
        label: Text(count == null ? label : '$label  $count'),
      ),
    ),
  );
}
