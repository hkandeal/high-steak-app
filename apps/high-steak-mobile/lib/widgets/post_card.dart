import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/steak_post.dart';
import '../theme/app_palette.dart';
import '../utils/api_image_url.dart';
import '../utils/date_format.dart';
import 'star_rating.dart';
import 'user_avatar.dart';

class PostCard extends StatelessWidget {
  const PostCard({super.key, required this.post});

  final SteakPost post;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final imageUrl = resolveApiImageUrl(post.primaryImageUrl);
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        onTap: () => context.push('/posts/${post.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl.isNotEmpty)
              _PostHeroImage(
                imageUrl: imageUrl,
                extraCount: post.imageUrls.length - 1,
                followersOnly: post.visibility == PostVisibility.followersOnly,
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      UserAvatar(
                        displayName: post.author.displayName,
                        radius: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: InkWell(
                          onTap: () => context.push('/users/${post.author.id}'),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                post.author.displayName,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontSize: 14,
                                  color: palette.gold,
                                ),
                              ),
                              Text(
                                formatPostDate(post.createdAt),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: palette.creamMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    post.title,
                    style: theme.textTheme.headlineMedium?.copyWith(fontSize: 20),
                  ),
                  const SizedBox(height: 8),
                  StarRating(value: post.rating, size: 18),
                  if (post.restaurantName != null) ...[
                    const SizedBox(height: 10),
                    _InfoChip(
                      icon: Icons.restaurant,
                      label: post.restaurantLocation != null
                          ? '${post.restaurantName} · ${post.restaurantLocation}'
                          : post.restaurantName!,
                    ),
                  ],
                  if (post.comment != null && post.comment!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      post.comment!,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontSize: 15,
                        color: palette.cream.withValues(alpha: 0.92),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PostHeroImage extends StatelessWidget {
  const _PostHeroImage({
    required this.imageUrl,
    required this.extraCount,
    required this.followersOnly,
  });

  final String imageUrl;
  final int extraCount;
  final bool followersOnly;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return AspectRatio(
      aspectRatio: 16 / 10,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: palette.charcoalLight,
              alignment: Alignment.center,
              child: Icon(
                Icons.image_not_supported_outlined,
                color: palette.creamMuted.withValues(alpha: 0.5),
                size: 40,
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  palette.charcoal.withValues(alpha: 0.55),
                ],
                stops: const [0.55, 1.0],
              ),
            ),
          ),
          if (followersOnly)
            Positioned(
              left: 10,
              top: 10,
              child: _Badge(
                label: 'Followers only',
                icon: Icons.lock_outline,
              ),
            ),
          if (extraCount > 0)
            Positioned(
              right: 10,
              bottom: 10,
              child: _Badge(
                label: '+$extraCount photos',
                icon: Icons.photo_library_outlined,
              ),
            ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: palette.gold),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: palette.cream,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Row(
      children: [
        Icon(icon, size: 16, color: palette.gold),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: palette.creamMuted,
                ),
          ),
        ),
      ],
    );
  }
}
