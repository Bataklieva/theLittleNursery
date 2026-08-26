import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/product.dart';

class ProductService {
  ProductService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _products =>
      _firestore.collection('products');

  /// Products shown in the shop.
  Stream<List<Product>> watchActive() {
    return _products.where('active', isEqualTo: true).snapshots().map(
          (snap) =>
              snap.docs.map((d) => Product.fromMap(d.id, d.data())).toList(),
        );
  }

  /// All products, including unpublished ones — for the admin list.
  Stream<List<Product>> watchAllForAdmin() {
    return _products.snapshots().map(
          (snap) =>
              snap.docs.map((d) => Product.fromMap(d.id, d.data())).toList(),
        );
  }

  Future<Product?> getById(String productId) async {
    final doc = await _products.doc(productId).get();
    if (!doc.exists) return null;
    return Product.fromMap(doc.id, doc.data()!);
  }

  Future<void> createProduct(Product product) {
    return _products.add(product.toMap());
  }

  Future<void> updateProduct(Product product) {
    return _products.doc(product.id).update(product.toMap());
  }

  Future<void> deleteProduct(String productId) {
    return _products.doc(productId).delete();
  }
}
