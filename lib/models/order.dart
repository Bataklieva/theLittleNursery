import 'package:cloud_firestore/cloud_firestore.dart';

import 'cart_item.dart';

enum OrderStatus {
  pendingPayment,
  paid,
  readyForPickup,
  completed,
  cancelled,
}

class OrderLine {
  final CartItemType type;
  final String refId;
  final String name;
  final int unitPriceCents;
  final int quantity;

  const OrderLine({
    required this.type,
    required this.refId,
    required this.name,
    required this.unitPriceCents,
    required this.quantity,
  });

  int get subtotalCents => unitPriceCents * quantity;

  factory OrderLine.fromCartItem(CartItem item) {
    return OrderLine(
      type: item.type,
      refId: item.refId,
      name: item.name,
      unitPriceCents: item.unitPriceCents,
      quantity: item.quantity,
    );
  }

  factory OrderLine.fromMap(Map<String, dynamic> map) {
    return OrderLine(
      type: (map['type'] as String? ?? 'product') == 'membership'
          ? CartItemType.membership
          : CartItemType.product,
      refId: map['refId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      unitPriceCents: map['unitPriceCents'] as int? ?? 0,
      quantity: map['quantity'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'refId': refId,
      'name': name,
      'unitPriceCents': unitPriceCents,
      'quantity': quantity,
    };
  }
}

class Order {
  final String id;
  final String parentUid;
  final List<OrderLine> lines;
  final int totalCents;
  final String currency;
  final String? fulfillmentLocationId;
  final OrderStatus status;
  final String? stripePaymentIntentId;
  final DateTime createdAt;

  const Order({
    required this.id,
    required this.parentUid,
    required this.lines,
    required this.totalCents,
    required this.currency,
    required this.status,
    required this.createdAt,
    this.fulfillmentLocationId,
    this.stripePaymentIntentId,
  });

  bool get hasPhysicalItems => lines.any((l) => l.type == CartItemType.product);

  factory Order.fromMap(String id, Map<String, dynamic> map) {
    return Order(
      id: id,
      parentUid: map['parentUid'] as String? ?? '',
      lines: (map['lines'] as List? ?? [])
          .map((e) => OrderLine.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
      totalCents: map['totalCents'] as int? ?? 0,
      currency: map['currency'] as String? ?? 'bgn',
      fulfillmentLocationId: map['fulfillmentLocationId'] as String?,
      status: _OrderStatusParsing.fromName(map['status'] as String? ?? ''),
      stripePaymentIntentId: map['stripePaymentIntentId'] as String?,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toCreateMap() {
    return {
      'parentUid': parentUid,
      'lines': lines.map((l) => l.toMap()).toList(),
      'totalCents': totalCents,
      'currency': currency,
      'fulfillmentLocationId': fulfillmentLocationId,
      'status': status.name,
      'stripePaymentIntentId': stripePaymentIntentId,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}

extension _OrderStatusParsing on OrderStatus {
  static OrderStatus fromName(String name) {
    return OrderStatus.values.firstWhere(
      (s) => s.name == name,
      orElse: () => OrderStatus.pendingPayment,
    );
  }
}
