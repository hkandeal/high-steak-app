import 'steak_post.dart';

class PostComment {
  const PostComment({
    required this.id,
    required this.body,
    required this.createdAt,
    required this.author,
  });

  final String id;
  final String body;
  final DateTime createdAt;
  final PostAuthor author;

  factory PostComment.fromJson(Map<String, dynamic> json) {
    return PostComment(
      id: json['id'] as String,
      body: json['body'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      author: PostAuthor.fromJson(
        json['author'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
}
