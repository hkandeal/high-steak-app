import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../navigation/app_navigator.dart';
import '../theme/app_palette.dart';
import '../utils/api_image_url.dart';
import '../utils/post_form_images.dart';

/// Full-screen photo viewer with swipe between images (matches web lightbox).
class ImageLightbox {
  ImageLightbox._();

  static Future<void> show(
    BuildContext context, {
    required List<String> imageUrls,
    int initialIndex = 0,
    String? title,
  }) {
    final items = imageUrls
        .map(_LightboxImage.network)
        .where((item) => item.url != null && item.url!.isNotEmpty)
        .toList(growable: false);
    return _show(context, items: items, initialIndex: initialIndex, title: title);
  }

  /// Opens a lightbox for post create/edit previews (kept URLs + newly picked files).
  static Future<void> showPostPhotos(
    BuildContext context, {
    required List<String> existingImageUrls,
    required List<XFile> newImages,
    int initialIndex = 0,
    String? title,
  }) {
    final items = <_LightboxImage>[
      ...existingImageUrls.map(_LightboxImage.network),
      ...newImages.map(_LightboxImage.file),
    ];
    return _show(context, items: items, initialIndex: initialIndex, title: title);
  }

  static Future<void> showFormImages(
    BuildContext context, {
    required List<FormImage> images,
    int initialIndex = 0,
    String? title,
  }) {
    final items = images
        .map(
          (image) => image.isExisting
              ? _LightboxImage.network(image.url!)
              : _LightboxImage.file(image.file!),
        )
        .toList(growable: false);
    return _show(context, items: items, initialIndex: initialIndex, title: title);
  }

  static Future<void> _show(
    BuildContext context, {
    required List<_LightboxImage> items,
    int initialIndex = 0,
    String? title,
  }) {
    if (items.isEmpty) return Future.value();

    final startIndex = initialIndex.clamp(0, items.length - 1);
    final dialogContext = rootNavigatorContext ?? context;

    return showGeneralDialog(
      context: dialogContext,
      useRootNavigator: true,
      barrierDismissible: true,
      barrierLabel: 'Close photo viewer',
      barrierColor: Colors.black.withValues(alpha: 0.92),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, _, __) {
        return _ImageLightboxPage(
          items: items,
          initialIndex: startIndex,
          title: title,
        );
      },
      transitionBuilder: (context, animation, _, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }
}

class _LightboxImage {
  _LightboxImage.network(String rawUrl)
      : url = resolveApiImageUrl(rawUrl),
        file = null;

  _LightboxImage.file(this.file) : url = null;

  final String? url;
  final XFile? file;
}

class _ImageLightboxPage extends StatefulWidget {
  const _ImageLightboxPage({
    required this.items,
    required this.initialIndex,
    this.title,
  });

  final List<_LightboxImage> items;
  final int initialIndex;
  final String? title;

  @override
  State<_ImageLightboxPage> createState() => _ImageLightboxPageState();
}

class _ImageLightboxPageState extends State<_ImageLightboxPage> {
  late final PageController _pageController;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goTo(int next) {
    if (next < 0 || next >= widget.items.length) return;
    _pageController.animateToPage(
      next,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final hasMultiple = widget.items.length > 1;

    return SizedBox.expand(
      child: Material(
        color: Colors.transparent,
        child: SafeArea(
          child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Row(
                children: [
                  if (hasMultiple)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_index + 1} / ${widget.items.length}',
                        style: TextStyle(
                          color: palette.cream,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else if (widget.title != null)
                    Expanded(
                      child: Text(
                        widget.title!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: palette.cream),
                      ),
                    )
                  else
                    const Spacer(),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () =>
                        Navigator.of(context, rootNavigator: true).pop(),
                    icon: Icon(Icons.close, color: palette.cream),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PageView.builder(
                    controller: _pageController,
                    itemCount: widget.items.length,
                    onPageChanged: (page) => setState(() => _index = page),
                    itemBuilder: (context, index) {
                      return InteractiveViewer(
                        minScale: 1,
                        maxScale: 4,
                        child: Center(
                          child: _LightboxImageContent(item: widget.items[index]),
                        ),
                      );
                    },
                  ),
                  if (hasMultiple) ...[
                    Positioned(
                      left: 4,
                      child: _NavButton(
                        icon: Icons.chevron_left,
                        onPressed: _index > 0 ? () => _goTo(_index - 1) : null,
                      ),
                    ),
                    Positioned(
                      right: 4,
                      child: _NavButton(
                        icon: Icons.chevron_right,
                        onPressed:
                            _index < widget.items.length - 1 ? () => _goTo(_index + 1) : null,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (hasMultiple)
              Padding(
                padding: const EdgeInsets.only(bottom: 16, top: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(widget.items.length, (dotIndex) {
                    final selected = dotIndex == _index;
                    return GestureDetector(
                      onTap: () => _goTo(dotIndex),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: selected ? 10 : 8,
                        height: selected ? 10 : 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: selected ? palette.gold : palette.creamMuted.withValues(alpha: 0.45),
                        ),
                      ),
                    );
                  }),
                ),
              ),
          ],
        ),
      ),
      ),
    );
  }
}

class _LightboxImageContent extends StatelessWidget {
  const _LightboxImageContent({required this.item});

  final _LightboxImage item;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final url = item.url;
    if (url != null && url.isNotEmpty) {
      return Image.network(
        url,
        fit: BoxFit.contain,
        loadingBuilder: (_, child, progress) {
          if (progress == null) return child;
          return const Center(child: CircularProgressIndicator());
        },
        errorBuilder: (_, __, ___) => Icon(
          Icons.broken_image_outlined,
          color: palette.creamMuted,
          size: 48,
        ),
      );
    }

    final file = item.file;
    if (file == null) {
      return Icon(Icons.broken_image_outlined, color: palette.creamMuted, size: 48);
    }

    return _PickedFileImage(file: file, fit: BoxFit.contain);
  }
}

class _PickedFileImage extends StatelessWidget {
  const _PickedFileImage({required this.file, this.fit = BoxFit.cover});

  final XFile file;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final path = file.path;
    if (!kIsWeb && path.isNotEmpty) {
      return Image.file(
        File(path),
        fit: fit,
        errorBuilder: (_, __, ___) => _bytesPreview(context),
      );
    }
    return _bytesPreview(context);
  }

  Widget _bytesPreview(BuildContext context) {
    return FutureBuilder<List<int>>(
      future: file.readAsBytes(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return Image.memory(
          Uint8List.fromList(snapshot.data!),
          fit: fit,
        );
      },
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.45),
      shape: const CircleBorder(),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
      ),
    );
  }
}
