/// Physical merchandise sold through the in-app store (art kits, studio
/// merch, supplies). Money is stored as integer minor units (stotinki, the
/// Bulgarian lev's cents) to avoid floating-point rounding on prices.
class Product {
  final String id;
  final String name;
  final String description;
  final int priceCents;
  final String currency;
  final String? imageUrl;
  final int stock;
  final bool active;

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.priceCents,
    required this.currency,
    required this.stock,
    required this.active,
    this.imageUrl,
  });

  bool get inStock => stock > 0;
  double get priceMajor => priceCents / 100;

  factory Product.fromMap(String id, Map<String, dynamic> map) {
    return Product(
      id: id,
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      priceCents: map['priceCents'] as int? ?? 0,
      currency: map['currency'] as String? ?? 'bgn',
      imageUrl: map['imageUrl'] as String?,
      stock: map['stock'] as int? ?? 0,
      active: map['active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'priceCents': priceCents,
      'currency': currency,
      'imageUrl': imageUrl,
      'stock': stock,
      'active': active,
    };
  }

  Product copyWith({
    String? name,
    String? description,
    int? priceCents,
    String? imageUrl,
    int? stock,
    bool? active,
  }) {
    return Product(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      priceCents: priceCents ?? this.priceCents,
      currency: currency,
      imageUrl: imageUrl ?? this.imageUrl,
      stock: stock ?? this.stock,
      active: active ?? this.active,
    );
  }
}
