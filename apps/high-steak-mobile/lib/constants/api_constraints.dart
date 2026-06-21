/// Field limits aligned with the API OpenAPI spec and database columns.
/// Image size default: 5 MB. Override at build time: `--dart-define=MAX_IMAGE_SIZE_MB=5`
/// At runtime the app also loads the live limit from `GET /api/config`.
class ApiConstraints {
  ApiConstraints._();

  static int _maxImageMb = int.fromEnvironment('MAX_IMAGE_SIZE_MB', defaultValue: 5);

  static int get maxImageMb => _maxImageMb;

  static void applyRemoteConfig(int maxImageSizeMb) {
    if (maxImageSizeMb > 0) {
      _maxImageMb = maxImageSizeMb;
    }
  }

  static int get maxImageBytes => maxImageMb * 1048576;

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
  static const maxImagesPerPost = 10;
}
