import 'package:flutter/material.dart';

import '../theme/app_palette.dart';

class StarRating extends StatelessWidget {
  const StarRating({
    super.key,
    required this.value,
    this.size = 16,
    this.onChanged,
  });

  final int value;
  final double size;
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final interactive = onChanged != null;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final filled = index < value;
        final star = Padding(
          padding: EdgeInsets.only(right: index == 4 ? 0 : 2),
          child: Icon(
            filled ? Icons.star_rounded : Icons.star_outline_rounded,
            size: size,
            color: filled
                ? palette.gold
                : palette.cream.withValues(alpha: 0.25),
            shadows: filled
                ? [Shadow(color: palette.gold.withValues(alpha: 0.6), blurRadius: 6)]
                : null,
          ),
        );

        if (!interactive) return star;

        return InkWell(
          onTap: () => onChanged!(index + 1),
          borderRadius: BorderRadius.circular(size),
          child: star,
        );
      }),
    );
  }
}
