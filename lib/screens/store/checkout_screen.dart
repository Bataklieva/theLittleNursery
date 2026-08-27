import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:provider/provider.dart';

import '../../models/location.dart';
import '../../services/auth_service.dart';
import '../../services/cart_service.dart';
import '../../services/order_service.dart';
import '../../utils/money.dart';
import '../profile/orders_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _locationId = Locations.center.id;
  bool _paying = false;
  String? _error;

  Future<void> _pay() async {
    final cart = context.read<CartService>();
    final auth = context.read<AuthService>();
    final orderService = context.read<OrderService>();

    setState(() {
      _paying = true;
      _error = null;
    });

    try {
      final orderId = await orderService.createPendingOrder(
        parentUid: auth.user!.uid,
        cartItems: cart.items,
        fulfillmentLocationId: cart.hasPhysicalItems ? _locationId : null,
      );

      final clientSecret =
          await orderService.requestPaymentIntentClientSecret(orderId);

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'The Little Nursery',
        ),
      );
      await Stripe.instance.presentPaymentSheet();

      cart.clear();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const OrdersScreen()),
          (route) => route.isFirst,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment received — thank you!')),
        );
      }
    } on StripeException catch (e) {
      // The user backed out of the payment sheet — not an error worth
      // showing red text for, just let them try again.
      if (e.error.code != FailureCode.Canceled) {
        setState(() => _error = e.error.localizedMessage ?? 'Payment failed.');
      }
    } catch (e) {
      setState(() => _error = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Order summary', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              for (final item in cart.items)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text('${item.name} × ${item.quantity}')),
                      Text(formatCents(item.subtotalCents, item.currency)),
                    ],
                  ),
                ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total', style: Theme.of(context).textTheme.titleMedium),
                  Text(
                    formatCents(cart.totalCents, cart.items.first.currency),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
              if (cart.hasPhysicalItems) ...[
                const SizedBox(height: 20),
                Text('Pick up from', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _locationId,
                  items: [
                    for (final location in Locations.all)
                      DropdownMenuItem(
                        value: location.id,
                        child: Text(location.name),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _locationId = value);
                  },
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _paying ? null : _pay,
                child: _paying
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text('Pay ${formatCents(cart.totalCents, cart.items.first.currency)}'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
