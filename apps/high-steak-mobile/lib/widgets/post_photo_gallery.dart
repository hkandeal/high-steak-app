import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import '../utils/api_image_url.dart';
import 'image_lightbox.dart';

class PostPhotoGallery extends StatefulWidget {
  const PostPhotoGallery({
    super.key,
    required this.imageUrls,
    this.title,
    this.aspectRatio = 16 / 10,
  });

  final List<String> imageUrls;
  final String? title;
  final double aspectRatio;

  @override
  State<PostPhotoGallery> createState() => _PostPhotoGalleryState();
}

class _PostPhotoGalleryState extends State<PostPhotoGallery> {
  late int _activeIndex;

  @override
  void initState() {
    super.initState();
    _activeIndex = 0;
  }

  @override
  void didUpdateWidget(covariant PostPhotoGallery oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_activeIndex >= widget.imageUrls.length) {
      _activeIndex = widget.imageUrls.isEmpty ? 0 : widget.imageUrls.length - 1;
    }
  }

  void _setIndex(int index) {
    if (index < 0 || index >= widget.imageUrls.length) return;
    setState(() => _activeIndex = index);
  }

  void _openLightbox() {
    ImageLightbox.show(
      context,
      imageUrls: widget.imageUrls,
      initialIndex: _activeIndex,
      title: widget.title,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrls.isEmpty) return const SizedBox.shrink();

    final palette = context.palette;
    final hasMultiple = widget.imageUrls.length > 1;
    final currentUrl = resolveApiImageUrl(widget.imageUrls[_activeIndex]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AspectRatio(
          aspectRatio: widget.aspectRatio,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                GestureDetector(
                  onTap: _openLightbox,
                  child: Image.network(
                    currentUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: palette.charcoalLight,
                      alignment: Alignment.center,
                      child: const Icon(Icons.image_not_supported_outlined),
                    ),
                  ),
                ),
                Positioned(
                  right: 10,
                  bottom: 10,
                  child: IgnorePointer(
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.open_in_full, color: Colors.white, size: 16),
                    ),
                  ),
                ),
                if (hasMultiple) ...[
                  Positioned(
                    left: 6,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: _GalleryNavButton(
                        icon: Icons.chevron_left,
                        onPressed: _activeIndex > 0
                            ? () => _setIndex(_activeIndex - 1)
                            : null,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 6,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: _GalleryNavButton(
                        icon: Icons.chevron_right,
                        onPressed: _activeIndex < widget.imageUrls.length - 1
                            ? () => _setIndex(_activeIndex + 1)
                            : null,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 10,
                    bottom: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_activeIndex + 1} / ${widget.imageUrls.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (hasMultiple) ...[
          const SizedBox(height: 10),
          SizedBox(
            height: 68,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: widget.imageUrls.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final selected = index == _activeIndex;
                return GestureDetector(
                  onTap: () => _setIndex(index),
                  onDoubleTap: () {
                    _setIndex(index);
                    _openLightbox();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: selected ? palette.gold : palette.cardBorder,
                        width: selected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        resolveApiImageUrl(widget.imageUrls[index]),
                        width: 68,
                        height: 68,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

class _GalleryNavButton extends StatelessWidget {
  const _GalleryNavButton({
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(
            icon,
            color: onPressed == null ? Colors.white38 : Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }
}
