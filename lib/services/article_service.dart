import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/article.dart';

/// Reads the "parent library" articles from Firestore's `articles`
/// collection, newest first.
class ArticleService {
  ArticleService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<Article>> watchAll() {
    return _firestore
        .collection('articles')
        .orderBy('publishedAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Article.fromMap(d.id, d.data())).toList());
  }

  Future<Article?> getById(String articleId) async {
    final doc = await _firestore.collection('articles').doc(articleId).get();
    if (!doc.exists) return null;
    return Article.fromMap(doc.id, doc.data()!);
  }

  Future<void> createArticle(Article article) {
    return _firestore.collection('articles').add(article.toMap());
  }

  Future<void> updateArticle(Article article) {
    return _firestore.collection('articles').doc(article.id).update(
          article.toMap(),
        );
  }

  Future<void> deleteArticle(String articleId) {
    return _firestore.collection('articles').doc(articleId).delete();
  }
}
