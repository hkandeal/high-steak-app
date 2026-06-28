import 'package:flutter/material.dart';

import '../models/steak_post.dart';
import '../theme/app_palette.dart';
import '../utils/open_google_maps.dart';

class PostVenue extends StatelessWidget {
  const PostVenue({
    super.key,
    required this.post,
    this.showLocation = true,
    this.dense = false,
    this.useChip = false,
  });

  final SteakPost post;
  final bool showLocation;
  final bool dense;
  final bool useChip;

  Future<void> _openMaps(BuildContext context) async {
    final place = post.place;
    if (place == null) return;
    final opened = await openGoogleMapsForPlace(place);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Google Maps')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = post.restaurantName;
    if (name == null || name.isEmpty) return const SizedBox.shrink();

    final palette = context.palette;
    final location = showLocation ? post.restaurantLocation : null;
    final label = location != null && location.isNotEmpty ? '$name · $location' : name;
    final canOpenMaps = post.place != null;

    if (useChip) {
      return _VenueChip(
        label: label,
        canOpenMaps: canOpenMaps,
        onTap: canOpenMaps ? () => _openMaps(context) : null,
      );
    }

    final textStyle = dense
        ? Theme.of(context).textTheme.bodySmall?.copyWith(
              color: canOpenMaps ? palette.gold : palette.creamMuted,
              fontSize: 11,
            )
        : Theme.of(context).textTheme.bodyMedium;

    if (dense) {
      final child = Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: textStyle,
      );
      if (!canOpenMaps) return child;
      return InkWell(
        onTap: () => _openMaps(context),
        child: child,
      );
    }

    if (!canOpenMaps) {
      return Row(
        children: [
          if (!dense) Icon(Icons.restaurant, size: 18, color: palette.gold),
          if (!dense) const SizedBox(width: 8),
          Expanded(child: Text(label, style: textStyle)),
        ],
      );
    }

    return InkWell(
      onTap: () => _openMaps(context),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            if (!dense) Icon(Icons.restaurant, size: 18, color: palette.gold),
            if (!dense) const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: textStyle?.copyWith(
                  color: palette.gold,
                  decoration: TextDecoration.underline,
                  decorationColor: palette.gold.withValues(alpha: 0.5),
                ),
              ),
            ),
            Icon(Icons.open_in_new, size: dense ? 12 : 16, color: palette.creamMuted),
          ],
        ),
      ),
    );
  }
}

class _VenueChip extends StatelessWidget {
  const _VenueChip({
    required this.label,
    required this.canOpenMaps,
    this.onTap,
  });

  final String label;
  final bool canOpenMaps;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final child = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: palette.accentSelectedBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.restaurant, size: 14, color: palette.gold),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: palette.cream, fontSize: 13),
            ),
          ),
          if (canOpenMaps) ...[
            const SizedBox(width: 4),
            Icon(Icons.open_in_new, size: 12, color: palette.creamMuted),
          ],
        ],
      ),
    );

    if (onTap == null) return child;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: child,
    );
  }
}
