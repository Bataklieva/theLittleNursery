import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/article.dart';
import '../../services/article_service.dart';
import 'article_form_screen.dart';

class ManageArticlesScreen extends StatelessWidget {
  const ManageArticlesScreen({super.key});

  Future<void> _confirmDelete(BuildContext context, Article article) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete article?'),
        content: Text('"${article.title}" will be removed from the library.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<ArticleService>().deleteArticle(article.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final articleService = context.read<ArticleService>();
    return Scaffold(
      appBar: AppBar(title: const Text('Manage parent library')),
      body: StreamBuilder<List<Article>>(
        stream: articleService.watchAll(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final articles = snapshot.data ?? const [];
          if (articles.isEmpty) {
            return const Center(child: Text('No articles yet — add one below.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: articles.length,
            itemBuilder: (context, index) {
              final article = articles[index];
              return Card(
                child: ListTile(
                  title: Text(article.title),
                  subtitle: Text(
                    DateFormat('d MMM yyyy').format(article.publishedAt),
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ArticleFormScreen(existingArticle: article),
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _confirmDelete(context, article),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('New article'),
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ArticleFormScreen()),
        ),
      ),
    );
  }
}
