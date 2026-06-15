import 'package:flutter/material.dart';

import '../models/steak_post.dart';
import '../theme/app_palette.dart';

class VisibilityPicker extends StatelessWidget {
  const VisibilityPicker({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final PostVisibility value;
  final ValueChanged<PostVisibility> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Who can see this post?',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 10),
        _OptionCard(
          icon: Icons.public,
          title: 'Public',
          description: 'Shows on the everyone feed',
          selected: value == PostVisibility.public,
          palette: palette,
          onTap: () => onChanged(PostVisibility.public),
        ),
        const SizedBox(height: 8),
        _OptionCard(
          icon: Icons.group_outlined,
          title: 'Followers only',
          description: 'Only people who follow you',
          selected: value == PostVisibility.followersOnly,
          palette: palette,
          onTap: () => onChanged(PostVisibility.followersOnly),
        ),
      ],
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.selected,
    required this.palette,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool selected;
  final AppPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? palette.accentSelectedBg : palette.cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: selected ? palette.gold : palette.cardBorder,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(icon, color: palette.gold),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: palette.cream,
                      ),
                    ),
                    Text(description, style: TextStyle(color: palette.creamMuted)),
                  ],
                ),
              ),
              if (selected)
                Icon(Icons.check_circle, color: palette.gold, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

String postVisibilityToApi(PostVisibility visibility) {
  return visibility == PostVisibility.followersOnly
      ? 'FOLLOWERS_ONLY'
      : 'PUBLIC';
}
