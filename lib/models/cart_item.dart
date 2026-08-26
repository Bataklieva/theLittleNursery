enum CartItemType { product, membership }

/// A line in the local shopping cart. Cents-based pricing is snapshotted
/// at add-to-cart time so a later admin price edit can't silently change
/// what's already in someone's cart.
class CartItem {
  final CartItemType type;
  final String refId;
  final String name;
  final int unitPriceCents;
  final String currency;
  final int quantity;
  final int? maxQuantity;

  const CartItem({
    required this.type,
    required this.refId,
    required this.name,
    required this.unitPriceCents,
    required this.currency,
    required this.quantity,
    this.maxQuantity,
  });

  int get subtotalCents => unitPriceCents * quantity;

  CartItem copyWith({int? quantity}) {
    return CartItem(
      type: type,
      refId: refId,
      name: name,
      unitPriceCents: unitPriceCents,
      currency: currency,
      quantity: quantity ?? this.quantity,
      maxQuantity: maxQuantity,
    );
  }
}
