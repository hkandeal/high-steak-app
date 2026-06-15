import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import '../theme/theme_controller.dart';

class ThemeToggle extends StatelessWidget {
  const ThemeToggle({super.key, required this.themeController});

  final ThemeController themeController;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final variant = themeController.variant;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.cardBorderStrong),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ThemeOption(
            label: 'Ember',
            icon: Icons.local_fire_department,
            selected: variant == AppThemeVariant.ember,
            palette: palette,
            onTap: () => themeController.setVariant(AppThemeVariant.ember),
          ),
          _ThemeOption(
            label: 'Steam',
            icon: Icons.wb_sunny_outlined,
            selected: variant == AppThemeVariant.steam,
            palette: palette,
            onTap: () => themeController.setVariant(AppThemeVariant.steam),
          ),
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.palette,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final AppPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? palette.accentSelectedBg : Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? palette.gold : palette.creamMuted,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? palette.gold : palette.creamMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
