import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../theme/app_palette.dart';
import '../utils/api_image_url.dart';
import 'image_lightbox.dart';

class PostPhotoSection extends StatelessWidget {
  const PostPhotoSection({
    super.key,
    required this.existingImageUrls,
    required this.newImages,
    required this.picking,
    required this.onPick,
    required this.onRemoveExisting,
    required this.onRemoveNew,
  });

  final List<String> existingImageUrls;
  final List<XFile> newImages;
  final bool picking;
  final VoidCallback onPick;
  final ValueChanged<int> onRemoveExisting;
  final ValueChanged<int> onRemoveNew;

  bool get _isEmpty => existingImageUrls.isEmpty && newImages.isEmpty;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.cardBorderStrong),
      ),
      child: Column(
        children: [
          if (_isEmpty)
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
          else
            SizedBox(
              height: 110,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: existingImageUrls.length + newImages.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  if (index < existingImageUrls.length) {
                    return _ExistingImageThumb(
                      url: existingImageUrls[index],
                      onOpen: () => ImageLightbox.showPostPhotos(
                        context,
                        existingImageUrls: existingImageUrls,
                        newImages: newImages,
                        initialIndex: index,
                      ),
                      onRemove: () => onRemoveExisting(index),
                    );
                  }
                  final newIndex = index - existingImageUrls.length;
                  return _NewImageThumb(
                    file: newImages[newIndex],
                    onOpen: () => ImageLightbox.showPostPhotos(
                      context,
                      existingImageUrls: existingImageUrls,
                      newImages: newImages,
                      initialIndex: index,
                    ),
                    onRemove: () => onRemoveNew(newIndex),
                  );
                },
              ),
            ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: picking ? null : onPick,
            icon: picking
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: palette.gold),
                  )
                : const Icon(Icons.add_photo_alternate_outlined),
            label: Text(
              picking
                  ? 'Opening…'
                  : (_isEmpty ? 'Add photos' : 'Add more'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExistingImageThumb extends StatelessWidget {
  const _ExistingImageThumb({
    required this.url,
    required this.onOpen,
    required this.onRemove,
  });

  final String url;
  final VoidCallback onOpen;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          onTap: onOpen,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              resolveApiImageUrl(url),
              width: 110,
              height: 110,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 110,
                height: 110,
                color: context.palette.charcoalLight,
                alignment: Alignment.center,
                child: const Icon(Icons.image_not_supported_outlined),
              ),
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: _RemoveButton(onTap: onRemove),
        ),
      ],
    );
  }
}

class _NewImageThumb extends StatelessWidget {
  const _NewImageThumb({
    required this.file,
    required this.onOpen,
    required this.onRemove,
  });

  final XFile file;
  final VoidCallback onOpen;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          onTap: onOpen,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _PickedImageThumb(file: file),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: _RemoveButton(onTap: onRemove),
        ),
      ],
    );
  }
}

class _RemoveButton extends StatelessWidget {
  const _RemoveButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: const Padding(
          padding: EdgeInsets.all(4),
          child: Icon(Icons.close, size: 16, color: Colors.white),
        ),
      ),
    );
  }
}

class _PickedImageThumb extends StatelessWidget {
  const _PickedImageThumb({required this.file});

  final XFile file;

  @override
  Widget build(BuildContext context) {
    final path = file.path;
    if (!kIsWeb && path.isNotEmpty) {
      return Image.file(
        File(path),
        width: 110,
        height: 110,
        fit: BoxFit.cover,
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
          return Container(
            width: 110,
            height: 110,
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
          width: 110,
          height: 110,
          fit: BoxFit.cover,
        );
      },
    );
  }
}
