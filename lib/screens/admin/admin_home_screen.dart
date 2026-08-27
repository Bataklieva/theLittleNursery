import 'package:flutter/material.dart';

import 'manage_articles_screen.dart';
import 'manage_events_screen.dart';
import 'manage_membership_plans_screen.dart';
import 'manage_orders_screen.dart';
import 'manage_products_screen.dart';

/// Landing screen for the "Admin" tab, only shown to signed-in parents
/// whose account has an `admins/{uid}` document (see AuthService.isAdmin).
class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Studio admin')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.calendar_month_outlined),
              title: const Text('Manage workshops'),
              subtitle: const Text('Add, edit, or remove calendar events'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ManageEventsScreen()),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.menu_book_outlined),
              title: const Text('Manage parent library'),
              subtitle: const Text('Add, edit, or remove articles'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ManageArticlesScreen(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.storefront_outlined),
              title: const Text('Manage products'),
              subtitle: const Text('Add, edit, or remove store items'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ManageProductsScreen(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.star_outline),
              title: const Text('Manage membership plans'),
              subtitle: const Text('Edit premium membership pricing & perks'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ManageMembershipPlansScreen(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.receipt_long_outlined),
              title: const Text('Orders'),
              subtitle: const Text('Track and fulfill paid orders'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ManageOrdersScreen()),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
