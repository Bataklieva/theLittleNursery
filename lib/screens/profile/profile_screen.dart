import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/booking.dart';
import '../../models/child.dart';
import '../../services/auth_service.dart';
import '../../services/booking_service.dart';
import 'child_form_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final profile = auth.profile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: () => context.read<AuthService>().signOut(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (profile != null) ...[
            Text(profile.name, style: Theme.of(context).textTheme.titleLarge),
            Text(profile.email, style: Theme.of(context).textTheme.bodyMedium),
            if (profile.phone != null) Text(profile.phone!),
            const SizedBox(height: 24),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('My children', style: Theme.of(context).textTheme.titleMedium),
              TextButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Add'),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ChildFormScreen()),
                ),
              ),
            ],
          ),
          for (final child in auth.children) _ChildTile(child: child),
          if (auth.children.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('No children added yet.'),
            ),
          const SizedBox(height: 24),
          Text('My bookings', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (auth.user != null)
            StreamBuilder<List<Booking>>(
              stream: context
                  .read<BookingService>()
                  .watchForParent(auth.user!.uid),
              builder: (context, snapshot) {
                final bookings = snapshot.data ?? const [];
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (bookings.isEmpty) {
                  return const Text('No upcoming bookings.');
                }
                return Column(
                  children: [
                    for (final booking in bookings)
                      _BookingTile(booking: booking),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

class _ChildTile extends StatelessWidget {
  const _ChildTile({required this.child});

  final Child child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(child.name),
        subtitle: Text('${child.ageInMonths} months old'),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ChildFormScreen(existingChild: child),
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () => context.read<AuthService>().removeChild(child.id),
        ),
      ),
    );
  }
}

class _BookingTile extends StatelessWidget {
  const _BookingTile({required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(booking.childName),
        subtitle: Text(
          'Booked on ${DateFormat('d MMM yyyy').format(booking.createdAt)}',
        ),
        trailing: TextButton(
          onPressed: () => context.read<BookingService>().cancel(booking),
          child: const Text('Cancel'),
        ),
      ),
    );
  }
}
