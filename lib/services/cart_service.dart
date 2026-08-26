import 'package:flutter/foundation.dart';

import '../models/cart_item.dart';
import '../models/membership_plan.dart';
import '../models/product.dart';

/// Local, ephemeral shopping cart — cleared on checkout or sign-out, never
/// synced to Firestore. The authoritative purchase record is the `orders`
/// document created at checkout.
class CartService extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);
  bool get isEmpty => _items.isEmpty;
  int get totalCents => _items.fold(0, (sum, item) => sum + item.subtotalCents);
  bool get hasPhysicalItems =>
      _items.any((i) => i.type == CartItemType.product);

  void addProduct(Product product, {int quantity = 1}) {
    final index = _items.indexWhere(
      (i) => i.type == CartItemType.product && i.refId == product.id,
    );
    if (index == -1) {
      _items.add(CartItem(
        type: CartItemType.product,
        refId: product.id,
        name: product.name,
        unitPriceCents: product.priceCents,
        currency: product.currency,
        quantity: quantity.clamp(1, product.stock),
        maxQuantity: product.stock,
      ));
    } else {
      final existing = _items[index];
      final newQuantity =
          (existing.quantity + quantity).clamp(1, product.stock);
      _items[index] = existing.copyWith(quantity: newQuantity);
    }
    notifyListeners();
  }

  /// Replaces any membership already in the cart — buying two premium
  /// passes in one order doesn't make sense for a fixed-term pass.
  void setMembership(MembershipPlan plan) {
    _items.removeWhere((i) => i.type == CartItemType.membership);
    _items.add(CartItem(
      type: CartItemType.membership,
      refId: plan.id,
      name: plan.name,
      unitPriceCents: plan.priceCents,
      currency: plan.currency,
      quantity: 1,
    ));
    notifyListeners();
  }

  void updateQuantity(CartItem item, int quantity) {
    final index = _items.indexOf(item);
    if (index == -1) return;
    final max = item.maxQuantity ?? quantity;
    final clamped = quantity.clamp(1, max < 1 ? 1 : max);
    _items[index] = item.copyWith(quantity: clamped);
    notifyListeners();
  }

  void removeItem(CartItem item) {
    _items.remove(item);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
