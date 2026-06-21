import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

import '../constants/api_constraints.dart';
import '../theme/app_palette.dart';

enum _PhotoSource { camera, gallery }

/// Phones/tablets show camera + library; desktop/web use the library picker only.
bool get showNativePhotoSourceChooser => !kIsWeb && !isDesktopPicker;

/// Builds a multipart image part for post uploads (`images` field).
Future<http.MultipartFile> buildPostImagePart(XFile file) =>
    buildMultipartImagePart(file, fieldName: 'images');

/// Builds a multipart image part for profile avatar uploads.
Future<http.MultipartFile> buildAvatarPart(XFile file) =>
    buildMultipartImagePart(file, fieldName: 'avatar');

Future<http.MultipartFile> buildMultipartImagePart(
  XFile file, {
  required String fieldName,
}) async {
  final bytes = await file.readAsBytes();
  final name = _resolveFilename(file);
  return http.MultipartFile.fromBytes(
    fieldName,
    bytes,
    filename: name,
    contentType: _contentTypeForFilename(name),
  );
}

String _resolveFilename(XFile file) {
  final fromName = file.name.trim();
  if (fromName.isNotEmpty) return fromName;

  final path = file.path.trim();
  if (path.isNotEmpty) {
    final segment = path.split('/').last;
    if (segment.isNotEmpty) return segment;
  }

  return 'photo.jpg';
}

MediaType _contentTypeForFilename(String filename) {
  final dot = filename.lastIndexOf('.');
  if (dot == -1 || dot == filename.length - 1) {
    return MediaType('image', 'jpeg');
  }

  switch (filename.substring(dot + 1).toLowerCase()) {
    case 'png':
      return MediaType('image', 'png');
    case 'webp':
      return MediaType('image', 'webp');
    case 'heic':
    case 'heif':
      return MediaType('image', 'heic');
    case 'gif':
      return MediaType('image', 'gif');
    default:
      return MediaType('image', 'jpeg');
  }
}

/// Shows camera vs library on mobile; returns picked files (may be empty if cancelled).
Future<List<XFile>> pickPostImagesInteractive(
  BuildContext context,
  ImagePicker picker, {
  required int remainingSlots,
}) async {
  if (remainingSlots <= 0) return [];

  final source = await _resolvePhotoSource(context, forAvatar: false);
  if (source == null) return [];

  return _pickPostImages(
    picker,
    source: source,
    galleryLimit: remainingSlots,
  );
}

/// Shows camera vs library on mobile for a single avatar image.
Future<XFile?> pickAvatarImageInteractive(
  BuildContext context,
  ImagePicker picker,
) async {
  final source = await _resolvePhotoSource(context, forAvatar: true);
  if (source == null) return null;

  if (source == _PhotoSource.camera) {
    return _pickCameraImage(picker);
  }
  return _pickGalleryAvatar(picker);
}

Future<_PhotoSource?> _resolvePhotoSource(
  BuildContext context, {
  required bool forAvatar,
}) async {
  if (!showNativePhotoSourceChooser) {
    return _PhotoSource.gallery;
  }
  return _showPhotoSourceSheet(context, forAvatar: forAvatar);
}

Future<_PhotoSource?> _showPhotoSourceSheet(
  BuildContext context, {
  required bool forAvatar,
}) {
  final palette = context.palette;

  return showModalBottomSheet<_PhotoSource>(
    context: context,
    backgroundColor: palette.charcoalLight,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                forAvatar ? 'Profile photo' : 'Add steak photos',
                style: Theme.of(sheetContext).textTheme.titleMedium?.copyWith(
                      color: palette.cream,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              _PhotoSourceTile(
                icon: Icons.photo_camera_outlined,
                title: 'Take photo',
                subtitle: forAvatar ? 'Use your camera' : 'Snap at the restaurant',
                onTap: () => Navigator.pop(sheetContext, _PhotoSource.camera),
              ),
              const SizedBox(height: 8),
              _PhotoSourceTile(
                icon: Icons.photo_library_outlined,
                title: 'Choose from library',
                subtitle: forAvatar ? null : 'Select one or more photos',
                onTap: () => Navigator.pop(sheetContext, _PhotoSource.gallery),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _PhotoSourceTile extends StatelessWidget {
  const _PhotoSourceTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Material(
      color: palette.cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: palette.cardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        leading: Icon(icon, color: palette.gold),
        title: Text(title, style: TextStyle(color: palette.cream)),
        subtitle: subtitle == null
            ? null
            : Text(
                subtitle!,
                style: TextStyle(color: palette.creamMuted, fontSize: 13),
              ),
        onTap: onTap,
      ),
    );
  }
}

Future<List<XFile>> _pickPostImages(
  ImagePicker picker, {
  required _PhotoSource source,
  required int galleryLimit,
}) async {
  if (source == _PhotoSource.camera) {
    final file = await _pickCameraImage(picker);
    return file == null ? [] : [file];
  }

  if (isDesktopPicker) {
    return picker.pickMultiImage();
  }

  return picker.pickMultiImage(
    imageQuality: 85,
    limit: galleryLimit.clamp(1, ApiConstraints.maxImagesPerPost),
  );
}

Future<XFile?> _pickCameraImage(ImagePicker picker) {
  return picker.pickImage(
    source: ImageSource.camera,
    imageQuality: 85,
    preferredCameraDevice: CameraDevice.rear,
  );
}

Future<XFile?> _pickGalleryAvatar(ImagePicker picker) async {
  if (isDesktopPicker) {
    return picker.pickImage(source: ImageSource.gallery);
  }

  return picker.pickImage(
    source: ImageSource.gallery,
    imageQuality: 85,
  );
}

String? pickerErrorMessage(Object error) {
  if (error is PlatformException) {
    if (error.code == 'photo_access_denied' ||
        error.code == 'camera_access_denied') {
      return 'Camera or photo access was denied. Enable it in Settings and try again.';
    }
    return error.message ?? 'Could not open the camera or photo library.';
  }
  return error.toString();
}

bool get isDesktopPicker =>
    !kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux);
