class PostAuthor {
  const PostAuthor({required this.id, required this.displayName});

  final String id;
  final String displayName;

  factory PostAuthor.fromJson(Map<String, dynamic> json) {
    return PostAuthor(
      id: json['id'] as String,
      displayName: json['displayName'] as String? ?? 'Unknown',
    );
  }
}

class ReviewTag {
  const ReviewTag({
    required this.id,
    required this.label,
    required this.sentiment,
  });

  final String id;
  final String label;
  final String sentiment;

  factory ReviewTag.fromJson(Map<String, dynamic> json) {
    return ReviewTag(
      id: json['id'] as String,
      label: json['label'] as String? ?? '',
      sentiment: json['sentiment'] as String? ?? 'POSITIVE',
    );
  }
}

enum PostVisibility { public, followersOnly }

PostVisibility parsePostVisibility(String? value) {
  if (value == 'FOLLOWERS_ONLY') return PostVisibility.followersOnly;
  return PostVisibility.public;
}

class SteakPost {
  const SteakPost({
    required this.id,
    required this.title,
    required this.comment,
    required this.rating,
    required this.imageUrls,
    required this.restaurantName,
    required this.restaurantLocation,
    required this.createdAt,
    required this.hidden,
    required this.visibility,
    required this.author,
    required this.tags,
    this.moderationReason,
    this.moderationRestoredAt,
  });

  final String id;
  final String title;
  final String? comment;
  final int rating;
  final List<String> imageUrls;
  final String? restaurantName;
  final String? restaurantLocation;
  final DateTime createdAt;
  final bool hidden;
  final PostVisibility visibility;
  final PostAuthor author;
  final List<ReviewTag> tags;
  final String? moderationReason;
  final String? moderationRestoredAt;

  String? get primaryImageUrl =>
      imageUrls.isEmpty ? null : imageUrls.first;

  factory SteakPost.fromJson(Map<String, dynamic> json) {
    final images = json['imageUrls'] as List<dynamic>? ?? [];
    final tagList = json['tags'] as List<dynamic>? ?? [];
    return SteakPost(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      comment: json['comment'] as String?,
      rating: json['rating'] as int? ?? 0,
      imageUrls: images.map((e) => e.toString()).toList(growable: false),
      restaurantName: json['restaurantName'] as String?,
      restaurantLocation: json['restaurantLocation'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      hidden: json['hidden'] as bool? ?? false,
      visibility: parsePostVisibility(json['visibility'] as String?),
      author: PostAuthor.fromJson(
        json['author'] as Map<String, dynamic>? ?? {},
      ),
      tags: tagList
          .whereType<Map<String, dynamic>>()
          .map(ReviewTag.fromJson)
          .toList(growable: false),
      moderationReason: json['moderationReason'] as String?,
      moderationRestoredAt: json['moderationRestoredAt'] as String?,
    );
  }
}
