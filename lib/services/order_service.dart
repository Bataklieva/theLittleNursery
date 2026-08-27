import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../models/cart_item.dart';
import '../models/order.dart';

class EmptyCartException implements Exception {
  const EmptyCartException();
}

/// Creates orders and hands off to the `createPaymentIntent` Cloud
/// Function for payment. The function — not this client — computes the
/// authoritative charge amount from the order document it reads
/// server-side, so a compromised or modified client can't pay less than
/// the real total. See functions/src/index.ts.
class OrderService {
  OrderService({FirebaseFirestore? firestore, FirebaseFunctions? functions})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  CollectionReference<Map<String, dynamic>> get _orders =>
      _firestore.collection('orders');

  Future<String> createPendingOrder({
    required String parentUid,
    required List<CartItem> cartItems,
    String? fulfillmentLocationId,
  }) async {
    if (cartItems.isEmpty) {
      throw const EmptyCartException();
    }
    final lines = cartItems.map(OrderLine.fromCartItem).toList();
    final total = lines.fold(0, (sum, l) => sum + l.subtotalCents);
    final order = Order(
      id: '',
      parentUid: parentUid,
      lines: lines,
      totalCents: total,
      currency: cartItems.first.currency,
      status: OrderStatus.pendingPayment,
      createdAt: DateTime.now(),
      fulfillmentLocationId: fulfillmentLocationId,
    );
    final ref = await _orders.add(order.toCreateMap());
    return ref.id;
  }

  /// Calls the `createPaymentIntent` Cloud Function and returns the
  /// PaymentIntent client secret to hand to Stripe's payment sheet.
  Future<String> requestPaymentIntentClientSecret(String orderId) async {
    final callable = _functions.httpsCallable('createPaymentIntent');
    final result = await callable.call<Map<String, dynamic>>({
      'orderId': orderId,
    });
    return result.data['clientSecret'] as String;
  }

  Stream<List<Order>> watchForParent(String parentUid) {
    return _orders
        .where('parentUid', isEqualTo: parentUid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Order.fromMap(d.id, d.data())).toList());
  }

  Stream<List<Order>> watchAllForAdmin() {
    return _orders
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Order.fromMap(d.id, d.data())).toList());
  }

  Stream<Order?> watchById(String orderId) {
    return _orders.doc(orderId).snapshots().map(
          (doc) => doc.exists ? Order.fromMap(doc.id, doc.data()!) : null,
        );
  }

  /// Fulfillment-stage updates only (ready for pickup / completed /
  /// cancelled) — the pending-payment → paid transition is owned by
  /// `stripeWebhook`, which also decrements stock and extends membership.
  Future<void> updateFulfillmentStatus(String orderId, OrderStatus status) {
    return _orders.doc(orderId).update({'status': status.name});
  }
}
