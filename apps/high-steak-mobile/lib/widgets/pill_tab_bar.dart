import 'package:flutter/material.dart';

import '../theme/app_palette.dart';

class PillTabBar<T> extends StatelessWidget {
  const PillTabBar({
    super.key,
    required this.tabs,
    required this.selected,
    required this.onSelected,
  });

  final List<PillTab<T>> tabs;
  final T selected;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: tabs.map((tab) {
          final active = tab.value == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Material(
              color: active ? palette.accentSelectedBg : Colors.transparent,
              shape: StadiumBorder(
                side: BorderSide(
                  color: active ? palette.gold : palette.cardBorderStrong,
                ),
              ),
              child: InkWell(
                onTap: () => onSelected(tab.value),
                customBorder: const StadiumBorder(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Text(
                    tab.label,
                    style: TextStyle(
                      color: active ? palette.gold : palette.creamMuted,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class PillTab<T> {
  const PillTab({required this.value, required this.label});

  final T value;
  final String label;
}
