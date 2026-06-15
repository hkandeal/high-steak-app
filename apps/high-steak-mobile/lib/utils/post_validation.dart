import '../constants/api_constraints.dart';

String? validatePostTitle(String title) {
  final trimmed = title.trim();
  if (trimmed.isEmpty) return 'Title is required.';
  if (trimmed.length > ApiConstraints.postTitleMax) {
    return 'Title must be at most ${ApiConstraints.postTitleMax} characters.';
  }
  return null;
}

String? validatePostComment(String comment) {
  if (comment.trim().length > ApiConstraints.postCommentMax) {
    return 'Comment is too long.';
  }
  return null;
}

String? validateRestaurantName(String name) {
  if (name.trim().length > ApiConstraints.restaurantNameMax) {
    return 'Restaurant must be at most ${ApiConstraints.restaurantNameMax} characters.';
  }
  return null;
}

String? validateRestaurantLocation(String location) {
  if (location.trim().length > ApiConstraints.restaurantLocationMax) {
    return 'Location must be at most ${ApiConstraints.restaurantLocationMax} characters.';
  }
  return null;
}

String? validatePostImages(List<String> imagePaths) {
  if (imagePaths.isEmpty) return 'At least one photo is required.';
  return null;
}

String? validatePostImageCount(int count) {
  if (count == 0) return 'At least one photo is required.';
  return null;
}

String? validatePostImageTotals(int existingCount, int newCount) {
  if (existingCount + newCount == 0) return 'At least one photo is required.';
  return null;
}

String? validatePostForm({
  required String title,
  required String comment,
  required String restaurantName,
  required String restaurantLocation,
  required List<String> imagePaths,
}) {
  return validatePostTitle(title) ??
      validatePostComment(comment) ??
      validateRestaurantName(restaurantName) ??
      validateRestaurantLocation(restaurantLocation) ??
      validatePostImages(imagePaths);
}
