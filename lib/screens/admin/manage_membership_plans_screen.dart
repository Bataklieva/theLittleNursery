import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/membership_plan.dart';
import '../../services/membership_service.dart';
import '../../utils/money.dart';
import 'membership_plan_form_screen.dart';

class ManageMembershipPlansScreen extends StatelessWidget {
  const ManageMembershipPlansScreen({super.key});

  Future<void> _confirmDelete(BuildContext context, MembershipPlan plan) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete plan?'),
        content: Text('"${plan.name}" will no longer be purchasable.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<MembershipService>().deletePlan(plan.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final membershipService = context.read<MembershipService>();
    return Scaffold(
      appBar: AppBar(title: const Text('Manage membership plans')),
      body: StreamBuilder<List<MembershipPlan>>(
        stream: membershipService.watchAllForAdmin(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final plans = snapshot.data ?? const [];
          if (plans.isEmpty) {
            return const Center(child: Text('No plans yet — add one below.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: plans.length,
            itemBuilder: (context, index) {
              final plan = plans[index];
              return Card(
                child: ListTile(
                  title: Text(plan.name),
                  subtitle: Text(
                    '${formatCents(plan.priceCents, plan.currency)} · '
                    '${plan.durationDays} days'
                    '${plan.active ? '' : ' · hidden'}',
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => MembershipPlanFormScreen(existingPlan: plan),
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _confirmDelete(context, plan),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('New plan'),
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const MembershipPlanFormScreen()),
        ),
      ),
    );
  }
}
