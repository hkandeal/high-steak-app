import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import 'cached_api_image.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.displayName,
    this.avatarUrl,
    this.avatarThumbnailUrl,
    this.radius = 24,
  });

  final String displayName;
  final String? avatarUrl;
  final String? avatarThumbnailUrl;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final resolved = avatarThumbnailUrl ?? avatarUrl ?? '';
    final initial = displayName.isNotEmpty ? displayName.characters.first.toUpperCase() : '?';
    final diameter = radius * 2;
    final provider = cachedApiImageProvider(
      context,
      imageUrl: resolved.isNotEmpty ? resolved : null,
      logicalSize: diameter,
    );

    return CircleAvatar(
      radius: radius,
      backgroundColor: palette.accentSelectedBg,
      backgroundImage: provider,
      child: provider == null
          ? Text(
              initial,
              style: TextStyle(
                fontSize: radius * 0.72,
                fontWeight: FontWeight.w600,
                color: palette.gold,
              ),
            )
          : null,
    );
  }
}
