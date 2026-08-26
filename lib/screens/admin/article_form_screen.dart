import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/article.dart';
import '../../services/article_service.dart';

class ArticleFormScreen extends StatefulWidget {
  const ArticleFormScreen({super.key, this.existingArticle});

  final Article? existingArticle;

  @override
  State<ArticleFormScreen> createState() => _ArticleFormScreenState();
}

class _ArticleFormScreenState extends State<ArticleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _summaryController;
  late final TextEditingController _bodyController;
  late final TextEditingController _imageUrlController;
  late DateTime _publishedAt;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingArticle;
    _titleController = TextEditingController(text: existing?.title ?? '');
    _summaryController = TextEditingController(text: existing?.summary ?? '');
    _bodyController = TextEditingController(text: existing?.body ?? '');
    _imageUrlController =
        TextEditingController(text: existing?.imageUrl ?? '');
    _publishedAt = existing?.publishedAt ?? DateTime.now();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _summaryController.dispose();
    _bodyController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickPublishedDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _publishedAt,
      firstDate: DateTime.now().subtract(const Duration(days: 3650)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _publishedAt = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final articleService = context.read<ArticleService>();
    final existing = widget.existingArticle;
    final imageUrl = _imageUrlController.text.trim();

    try {
      if (existing == null) {
        await articleService.createArticle(Article(
          id: '',
          title: _titleController.text.trim(),
          summary: _summaryController.text.trim(),
          body: _bodyController.text.trim(),
          imageUrl: imageUrl.isEmpty ? null : imageUrl,
          publishedAt: _publishedAt,
        ));
      } else {
        await articleService.updateArticle(existing.copyWith(
          title: _titleController.text.trim(),
          summary: _summaryController.text.trim(),
          body: _bodyController.text.trim(),
          imageUrl: imageUrl.isEmpty ? null : imageUrl,
          publishedAt: _publishedAt,
        ));
      }
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingArticle != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit article' : 'New article')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _summaryController,
                  decoration: const InputDecoration(
                    labelText: 'Summary (shown in the list)',
                  ),
                  maxLines: 2,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _bodyController,
                  decoration: const InputDecoration(labelText: 'Article text'),
                  maxLines: 10,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _imageUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Cover image URL (optional)',
                  ),
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Publish date'),
                  subtitle: Text(DateFormat('d MMMM yyyy').format(_publishedAt)),
                  trailing: const Icon(Icons.edit_calendar_outlined),
                  onTap: _pickPublishedDate,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _saving ? null : _submit,
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(isEditing ? 'Save changes' : 'Publish article'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
