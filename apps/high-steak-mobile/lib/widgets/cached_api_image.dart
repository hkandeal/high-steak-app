import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import '../utils/api_image_url.dart';

/// Disk- and memory-cached network image for API upload paths.
///
/// See ADR 013 — pair with server `Cache-Control` on `/uploads/**`.
class CachedApiImage extends StatelessWidget {
  const CachedApiImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.cacheWidth,
    this.cacheHeight,
    this.borderRadius,
    this.placeholder,
    this.error,
    this.alignment = Alignment.center,
  });

  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final int? cacheWidth;
  final int? cacheHeight;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? error;
  final Alignment alignment;

  /// Pixel dimension for [memCacheWidth] from a logical width.
  static int? memCacheWidth(BuildContext context, double logicalWidth) {
    if (!logicalWidth.isFinite || logicalWidth <= 0) return null;
    return (logicalWidth * MediaQuery.devicePixelRatioOf(context)).round();
  }

  /// Pixel dimension for [memCacheHeight] from a logical height.
  static int? memCacheHeight(BuildContext context, double logicalHeight) {
    if (!logicalHeight.isFinite || logicalHeight <= 0) return null;
    return (logicalHeight * MediaQuery.devicePixelRatioOf(context)).round();
  }

  @override
  Widget build(BuildContext context) {
    final resolved = resolveApiImageUrl(imageUrl);
    if (resolved.isEmpty) {
      return error ?? const SizedBox.shrink();
    }

    final palette = context.palette;
    final image = CachedNetworkImage(
      imageUrl: resolved,
      fit: fit,
      width: width,
      height: height,
      alignment: alignment,
      memCacheWidth: cacheWidth,
      memCacheHeight: cacheHeight,
      placeholder: (_, __) =>
          placeholder ??
          Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: palette.gold.withValues(alpha: 0.7),
              ),
            ),
          ),
      errorWidget: (_, __, ___) =>
          error ??
          Container(
            color: palette.charcoalLight,
            alignment: Alignment.center,
            child: Icon(
              Icons.image_not_supported_outlined,
              color: palette.creamMuted.withValues(alpha: 0.5),
              size: 40,
            ),
          ),
    );

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: image);
    }
    return image;
  }
}

/// [ImageProvider] for [CircleAvatar] and similar widgets.
ImageProvider<Object>? cachedApiImageProvider(
  BuildContext context, {
  required String? imageUrl,
  required double logicalSize,
}) {
  final resolved = resolveApiImageUrl(imageUrl);
  if (resolved.isEmpty) return null;

  final pixels = memCacheDimension(context, logicalSize);
  return CachedNetworkImageProvider(
    resolved,
    maxWidth: pixels,
    maxHeight: pixels,
  );
}

int? memCacheDimension(BuildContext context, double logicalSize) {
  if (!logicalSize.isFinite || logicalSize <= 0) return null;
  return (logicalSize * MediaQuery.devicePixelRatioOf(context)).round();
}
