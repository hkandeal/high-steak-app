/// Field limits aligned with the API OpenAPI spec and database columns.
/// Override at build time: `--dart-define=MAX_IMAGE_SIZE_MB=3`
class ApiConstraints {
  ApiConstraints._();

  static const usernameMin = 3;
  static const usernameMax = 50;
  static const emailMax = 255;
  static const passwordMin = 8;
  static const passwordMax = 100;
  static const displayNameMin = 2;
  static const displayNameMax = 100;
  static const postTitleMax = 120;
  static const postCommentMax = 65535;
  static const restaurantNameMax = 120;
  static const restaurantLocationMax = 255;
  static const commentBodyMax = 2000;
  static const searchQueryMin = 2;
  static const searchQueryMax = 100;
  static const maxReviewTags = 12;

  static const int maxImageMb = int.fromEnvironment('MAX_IMAGE_SIZE_MB', defaultValue: 3);

  static int get maxImageBytes => maxImageMb * 1048576;
}
