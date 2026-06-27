import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import '../utils/feed_layout_controller.dart';

class FeedLayoutToggle extends StatelessWidget {
  const FeedLayoutToggle({super.key, required this.controller});

  final FeedLayoutController controller;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final useGrid = controller.useGrid;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.cardBorderStrong),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LayoutOption(
            tooltip: 'Grid view',
            icon: Icons.grid_view_rounded,
            selected: useGrid,
            palette: palette,
            onTap: () => controller.setUseGrid(true),
          ),
          _LayoutOption(
            tooltip: 'List view',
            icon: Icons.view_list_rounded,
            selected: !useGrid,
            palette: palette,
            onTap: () => controller.setUseGrid(false),
          ),
        ],
      ),
    );
  }
}

class _LayoutOption extends StatelessWidget {
  const _LayoutOption({
    required this.tooltip,
    required this.icon,
    required this.selected,
    required this.palette,
    required this.onTap,
  });

  final String tooltip;
  final IconData icon;
  final bool selected;
  final AppPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: selected ? palette.accentSelectedBg : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(
              icon,
              size: 18,
              color: selected ? palette.gold : palette.creamMuted,
            ),
          ),
        ),
      ),
    );
  }
}
