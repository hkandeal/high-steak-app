/// Field limits aligned with apps/high-steak-api/openapi/openapi.yaml
abstract final class ApiConstraints {
  static const postTitleMin = 1;
  static const postTitleMax = 120;
  static const postCommentMax = 65535;
  static const restaurantNameMax = 120;
  static const restaurantLocationMax = 255;
  static const displayNameMin = 2;
  static const displayNameMax = 100;
  static const emailMax = 255;
  static const searchQueryMin = 2;
  static const searchQueryMax = 100;
  static const maxReviewTags = 12;
  static const maxImageBytes = 1048576;
  static const maxImageMb = 1;
}
