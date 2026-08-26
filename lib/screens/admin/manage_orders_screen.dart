import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/location.dart';
import '../../models/order.dart';
import '../../services/order_service.dart';
import '../../utils/money.dart';

class ManageOrdersScreen extends StatelessWidget {
  const ManageOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Orders')),
      body: StreamBuilder<List<Order>>(
        stream: context.read<OrderService>().watchAllForAdmin(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final orders = (snapshot.data ?? const [])
              .where((o) => o.status != OrderStatus.pendingPayment)
              .toList();
          if (orders.isEmpty) {
            return const Center(child: Text('No paid orders yet.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) => _OrderCard(order: orders[index]),
          );
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final location = order.fulfillmentLocationId == null
        ? null
        : Locations.all.firstWhere(
            (l) => l.id == order.fulfillmentLocationId,
            orElse: () => Locations.center,
          );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final line in order.lines)
              Text('${line.name} × ${line.quantity}'),
            const SizedBox(height: 6),
            Text(
              '${DateFormat('d MMM yyyy · HH:mm').format(order.createdAt)} · '
              '${formatCents(order.totalCents, order.currency)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (location != null)
              Text('Pickup: ${location.name}',
                  style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: [
                for (final status in [
                  OrderStatus.paid,
                  OrderStatus.readyForPickup,
                  OrderStatus.completed,
                  OrderStatus.cancelled,
                ])
                  ChoiceChip(
                    label: Text(_label(status)),
                    selected: order.status == status,
                    onSelected: (_) => context
                        .read<OrderService>()
                        .updateFulfillmentStatus(order.id, status),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _label(OrderStatus status) {
    return switch (status) {
      OrderStatus.pendingPayment => 'Pending',
      OrderStatus.paid => 'Paid',
      OrderStatus.readyForPickup => 'Ready for pickup',
      OrderStatus.completed => 'Completed',
      OrderStatus.cancelled => 'Cancelled',
    };
  }
}
