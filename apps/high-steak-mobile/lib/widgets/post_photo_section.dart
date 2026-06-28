import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../theme/app_palette.dart';
import '../utils/api_image_url.dart';
import '../utils/post_form_images.dart';
import 'image_lightbox.dart';

class PostPhotoSection extends StatefulWidget {
  const PostPhotoSection({
    super.key,
    required this.images,
    required this.picking,
    required this.onPick,
    required this.onImagesChanged,
  });

  final List<FormImage> images;
  final bool picking;
  final VoidCallback onPick;
  final ValueChanged<List<FormImage>> onImagesChanged;

  @override
  State<PostPhotoSection> createState() => _PostPhotoSectionState();
}

class _PostPhotoSectionState extends State<PostPhotoSection> {
  int _activeIndex = 0;

  @override
  void didUpdateWidget(covariant PostPhotoSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_activeIndex >= widget.images.length) {
      _activeIndex = widget.images.isEmpty ? 0 : widget.images.length - 1;
    }
  }

  void _updateImages(List<FormImage> next) {
    widget.onImagesChanged(next);
  }

  void _setActiveIndex(int index) {
    if (index < 0 || index >= widget.images.length) return;
    setState(() => _activeIndex = index);
  }

  void _removeAt(int index) {
    final next = List<FormImage>.of(widget.images)..removeAt(index);
    setState(() {
      _activeIndex = index <= _activeIndex ? (_activeIndex - 1).clamp(0, next.length - 1) : _activeIndex;
      if (next.isEmpty) _activeIndex = 0;
    });
    _updateImages(next);
  }

  void _setCover(int index) {
    if (index == 0 || index >= widget.images.length) return;
    final next = List<FormImage>.of(widget.images);
    final item = next.removeAt(index);
    next.insert(0, item);
    setState(() => _activeIndex = 0);
    _updateImages(next);
  }

  void _openLightbox() {
    ImageLightbox.showFormImages(
      context,
      images: widget.images,
      initialIndex: _activeIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final isEmpty = widget.images.isEmpty;
    final hasMultiple = widget.images.length > 1;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.cardBorderStrong),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isEmpty)
            Column(
              children: [
                Icon(Icons.photo_camera_outlined, size: 40, color: palette.gold),
                const SizedBox(height: 8),
                Text(
                  'Take a photo or choose from your library',
                  style: TextStyle(color: palette.creamMuted),
                  textAlign: TextAlign.center,
                ),
              ],
            )
          else ...[
            AspectRatio(
              aspectRatio: 4 / 3,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    GestureDetector(
                      onTap: _openLightbox,
                      child: _EditorImagePreview(image: widget.images[_activeIndex]),
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
                                ? () => _setActiveIndex(_activeIndex - 1)
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
                            onPressed: _activeIndex < widget.images.length - 1
                                ? () => _setActiveIndex(_activeIndex + 1)
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
                            '${_activeIndex + 1} / ${widget.images.length}',
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
                  itemCount: widget.images.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final selected = index == _activeIndex;
                    final isCover = index == 0;
                    return GestureDetector(
                      onTap: () => _setActiveIndex(index),
                      child: Stack(
                        children: [
                          AnimatedContainer(
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
                              child: SizedBox(
                                width: 68,
                                height: 68,
                                child: _EditorImagePreview(image: widget.images[index]),
                              ),
                            ),
                          ),
                          if (isCover)
                            Positioned(
                              left: 4,
                              right: 4,
                              bottom: 4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.black87,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'COVER',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: palette.gold,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (_activeIndex != 0)
                  OutlinedButton(
                    onPressed: () => _setCover(_activeIndex),
                    child: const Text('Set as cover'),
                  ),
                TextButton(
                  onPressed: () => _removeAt(_activeIndex),
                  style: TextButton.styleFrom(foregroundColor: palette.ember),
                  child: const Text('Remove photo'),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: widget.picking ? null : widget.onPick,
            icon: widget.picking
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: palette.gold),
                  )
                : const Icon(Icons.add_photo_alternate_outlined),
            label: Text(
              widget.picking
                  ? 'Opening…'
                  : (isEmpty ? 'Add photos' : 'Add more'),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditorImagePreview extends StatelessWidget {
  const _EditorImagePreview({required this.image});

  final FormImage image;

  @override
  Widget build(BuildContext context) {
    if (image.isExisting) {
      return Image.network(
        resolveApiImageUrl(image.url!),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => Container(
          color: context.palette.charcoalLight,
          alignment: Alignment.center,
          child: const Icon(Icons.image_not_supported_outlined),
        ),
      );
    }

    final file = image.file!;
    final path = file.path;
    if (!kIsWeb && path.isNotEmpty) {
      return Image.file(
        File(path),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => _BytesPreview(file: file),
      );
    }
    return _BytesPreview(file: file);
  }
}

class _BytesPreview extends StatelessWidget {
  const _BytesPreview({required this.file});

  final XFile file;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<int>>(
      future: file.readAsBytes(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            color: context.palette.charcoalLight,
            alignment: Alignment.center,
            child: const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }
        return Image.memory(
          Uint8List.fromList(snapshot.data!),
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        );
      },
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
