import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

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

/// Picks one or more photos with platform-appropriate options.
Future<List<XFile>> pickPostImages(ImagePicker picker) async {
  if (!kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux)) {
    // Desktop uses file_selector — compression options are unsupported.
    return picker.pickMultiImage();
  }

  return picker.pickMultiImage(
    imageQuality: 85,
    limit: 10,
  );
}

/// Picks a single photo for profile avatar uploads.
Future<XFile?> pickAvatarImage(ImagePicker picker) async {
  if (!kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux)) {
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
      return 'Photo access was denied. Enable it in Settings and try again.';
    }
    return error.message ?? 'Could not open the photo library.';
  }
  return error.toString();
}

bool get isDesktopPicker =>
    !kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux);
