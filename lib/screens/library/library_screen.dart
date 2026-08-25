import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/article.dart';
import '../../services/article_service.dart';
import 'article_detail_screen.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Parent library')),
      body: StreamBuilder<List<Article>>(
        stream: context.read<ArticleService>().watchAll(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final articles = snapshot.data ?? const [];
          if (articles.isEmpty) {
            return const Center(child: Text('No articles yet — check back soon!'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: articles.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final article = articles[index];
              return _ArticleCard(article: article);
            },
          );
        },
      ),
    );
  }
}

class _ArticleCard extends StatelessWidget {
  const _ArticleCard({required this.article});

  final Article article;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ArticleDetailScreen(articleId: article.id),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(article.title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(
                DateFormat('d MMM yyyy').format(article.publishedAt),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Text(
                article.summary,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
