import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/product.dart';
import '../../services/product_service.dart';

class ProductFormScreen extends StatefulWidget {
  const ProductFormScreen({super.key, this.existingProduct});

  final Product? existingProduct;

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _stockController;
  late final TextEditingController _imageUrlController;
  late bool _active;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingProduct;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _descriptionController =
        TextEditingController(text: existing?.description ?? '');
    _priceController = TextEditingController(
      text: existing != null ? existing.priceMajor.toStringAsFixed(2) : '',
    );
    _stockController =
        TextEditingController(text: (existing?.stock ?? 10).toString());
    _imageUrlController =
        TextEditingController(text: existing?.imageUrl ?? '');
    _active = existing?.active ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final priceCents =
        (double.parse(_priceController.text.trim()) * 100).round();
    final stock = int.parse(_stockController.text.trim());
    final imageUrl = _imageUrlController.text.trim();
    final productService = context.read<ProductService>();
    final existing = widget.existingProduct;

    try {
      if (existing == null) {
        await productService.createProduct(Product(
          id: '',
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          priceCents: priceCents,
          currency: 'bgn',
          stock: stock,
          active: _active,
          imageUrl: imageUrl.isEmpty ? null : imageUrl,
        ));
      } else {
        await productService.updateProduct(existing.copyWith(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          priceCents: priceCents,
          stock: stock,
          active: _active,
          imageUrl: imageUrl.isEmpty ? null : imageUrl,
        ));
      }
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingProduct != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit product' : 'New product')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(labelText: 'Price (BGN)'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    final n = double.tryParse(v?.trim() ?? '');
                    if (n == null || n <= 0) return 'Enter a positive price';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _stockController,
                  decoration: const InputDecoration(labelText: 'Stock'),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    final n = int.tryParse(v?.trim() ?? '');
                    if (n == null || n < 0) return 'Enter a non-negative number';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _imageUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Image URL (optional)',
                  ),
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Visible in the shop'),
                  subtitle: const Text('Turn off to hide without deleting'),
                  value: _active,
                  onChanged: (value) => setState(() => _active = value),
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
                      : Text(isEditing ? 'Save changes' : 'Create product'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
