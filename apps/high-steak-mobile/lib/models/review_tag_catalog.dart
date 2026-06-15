import 'steak_post.dart';

class ReviewTagCatalog {
  const ReviewTagCatalog({
    required this.positive,
    required this.negative,
  });

  final List<ReviewTag> positive;
  final List<ReviewTag> negative;

  factory ReviewTagCatalog.fromJson(Map<String, dynamic> json) {
    final positiveList = json['positive'] as List<dynamic>? ?? [];
    final negativeList = json['negative'] as List<dynamic>? ?? [];
    return ReviewTagCatalog(
      positive: positiveList
          .whereType<Map<String, dynamic>>()
          .map(ReviewTag.fromJson)
          .toList(growable: false),
      negative: negativeList
          .whereType<Map<String, dynamic>>()
          .map(ReviewTag.fromJson)
          .toList(growable: false),
    );
  }
}
