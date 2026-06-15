import 'package:flutter/material.dart';

import '../constants/api_constraints.dart';
import '../models/review_tag_catalog.dart';
import '../models/steak_post.dart';
import '../theme/app_palette.dart';

class ReviewTagPicker extends StatelessWidget {
  const ReviewTagPicker({
    super.key,
    required this.catalog,
    required this.selectedIds,
    required this.onChanged,
  });

  final ReviewTagCatalog catalog;
  final List<String> selectedIds;
  final ValueChanged<List<String>> onChanged;

  void _toggle(String tagId) {
    if (selectedIds.contains(tagId)) {
      onChanged(selectedIds.where((id) => id != tagId).toList(growable: false));
      return;
    }
    if (selectedIds.length >= ApiConstraints.maxReviewTags) return;
    onChanged([...selectedIds, tagId]);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick tags', style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          'Tap what stood out — good or bad',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        _TagGroup(
          title: 'What was great',
          tags: catalog.positive,
          selectedIds: selectedIds,
          negative: false,
          onToggle: _toggle,
        ),
        const SizedBox(height: 12),
        _TagGroup(
          title: 'What missed',
          tags: catalog.negative,
          selectedIds: selectedIds,
          negative: true,
          onToggle: _toggle,
        ),
        if (selectedIds.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            '${selectedIds.length} tag${selectedIds.length == 1 ? '' : 's'} selected',
            style: TextStyle(color: palette.gold, fontWeight: FontWeight.w600),
          ),
        ],
      ],
    );
  }
}

class _TagGroup extends StatelessWidget {
  const _TagGroup({
    required this.title,
    required this.tags,
    required this.selectedIds,
    required this.negative,
    required this.onToggle,
  });

  final String title;
  final List<ReviewTag> tags;
  final List<String> selectedIds;
  final bool negative;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: palette.cream,
              ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: tags.map((tag) {
            final selected = selectedIds.contains(tag.id);
            return FilterChip(
              label: Text('#${tag.label}'),
              selected: selected,
              onSelected: (_) => onToggle(tag.id),
              selectedColor: palette.accentSelectedBg,
              checkmarkColor: palette.gold,
              side: BorderSide(
                color: selected
                    ? palette.gold
                    : (negative ? palette.ember.withValues(alpha: 0.4) : palette.cardBorderStrong),
              ),
              labelStyle: TextStyle(
                color: selected
                    ? palette.gold
                    : (negative ? palette.emberDark : palette.creamMuted),
                fontWeight: FontWeight.w600,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
