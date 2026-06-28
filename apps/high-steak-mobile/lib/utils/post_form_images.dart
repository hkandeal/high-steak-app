import 'package:image_picker/image_picker.dart';

class FormImage {
  const FormImage.existing(this.url) : file = null;

  const FormImage.newFile(this.file) : url = null;

  final String? url;
  final XFile? file;

  bool get isExisting => url != null;
  bool get isNew => file != null;
}

class PostFormImagePayload {
  const PostFormImagePayload({
    required this.keepImageUrls,
    required this.newImages,
    this.imageOrder,
  });

  final List<String> keepImageUrls;
  final List<XFile> newImages;
  final List<String>? imageOrder;

  static PostFormImagePayload fromFormImages(
    List<FormImage> images, {
    required bool forEdit,
  }) {
    final keepImageUrls = <String>[];
    final newImages = <XFile>[];
    final imageOrder = <String>[];

    for (final image in images) {
      if (image.isExisting) {
        keepImageUrls.add(image.url!);
        imageOrder.add(image.url!);
      } else {
        final index = newImages.length;
        newImages.add(image.file!);
        imageOrder.add('__new__:$index');
      }
    }

    return PostFormImagePayload(
      keepImageUrls: keepImageUrls,
      newImages: newImages,
      imageOrder: forEdit ? imageOrder : null,
    );
  }

  static List<FormImage> fromUrls(List<String> urls) {
    return urls.map(FormImage.existing).toList(growable: false);
  }

  static bool isDirty(List<FormImage> images, List<String> initialUrls) {
    if (images.any((image) => image.isNew)) return true;
    if (images.length != initialUrls.length) return true;
    for (var index = 0; index < images.length; index++) {
      final image = images[index];
      if (!image.isExisting || image.url != initialUrls[index]) {
        return true;
      }
    }
    return false;
  }
}
