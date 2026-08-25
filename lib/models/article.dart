import 'package:cloud_firestore/cloud_firestore.dart';

/// A parent-library / blog article, mirroring the "Библиотека за родители"
/// section of thelittlenursery.bg.
class Article {
  final String id;
  final String title;
  final String summary;
  final String body;
  final String? imageUrl;
  final DateTime publishedAt;

  const Article({
    required this.id,
    required this.title,
    required this.summary,
    required this.body,
    required this.publishedAt,
    this.imageUrl,
  });

  factory Article.fromMap(String id, Map<String, dynamic> map) {
    return Article(
      id: id,
      title: map['title'] as String? ?? '',
      summary: map['summary'] as String? ?? '',
      body: map['body'] as String? ?? '',
      imageUrl: map['imageUrl'] as String?,
      publishedAt: (map['publishedAt'] as Timestamp).toDate(),
    );
  }
}
