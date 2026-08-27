import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/membership_plan.dart';
import '../../services/membership_service.dart';

class MembershipPlanFormScreen extends StatefulWidget {
  const MembershipPlanFormScreen({super.key, this.existingPlan});

  final MembershipPlan? existingPlan;

  @override
  State<MembershipPlanFormScreen> createState() =>
      _MembershipPlanFormScreenState();
}

class _MembershipPlanFormScreenState extends State<MembershipPlanFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _durationController;
  late final TextEditingController _perksController;
  late bool _active;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingPlan;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _descriptionController =
        TextEditingController(text: existing?.description ?? '');
    _priceController = TextEditingController(
      text: existing != null ? existing.priceMajor.toStringAsFixed(2) : '',
    );
    _durationController = TextEditingController(
      text: (existing?.durationDays ?? 90).toString(),
    );
    _perksController =
        TextEditingController(text: (existing?.perks ?? []).join('\n'));
    _active = existing?.active ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    _perksController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final priceCents =
        (double.parse(_priceController.text.trim()) * 100).round();
    final durationDays = int.parse(_durationController.text.trim());
    final perks = _perksController.text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    final membershipService = context.read<MembershipService>();
    final existing = widget.existingPlan;

    try {
      if (existing == null) {
        await membershipService.createPlan(MembershipPlan(
          id: '',
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          priceCents: priceCents,
          currency: 'bgn',
          durationDays: durationDays,
          perks: perks,
          active: _active,
        ));
      } else {
        await membershipService.updatePlan(existing.copyWith(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          priceCents: priceCents,
          durationDays: durationDays,
          perks: perks,
          active: _active,
        ));
      }
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingPlan != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit plan' : 'New plan')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Plan name'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(labelText: 'Price (BGN)'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    final n = double.tryParse(v?.trim() ?? '');
                    if (n == null || n <= 0) return 'Enter a positive price';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _durationController,
                  decoration: const InputDecoration(
                    labelText: 'Duration (days)',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    final n = int.tryParse(v?.trim() ?? '');
                    if (n == null || n <= 0) return 'Enter a positive number';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _perksController,
                  decoration: const InputDecoration(
                    labelText: 'Perks (one per line)',
                  ),
                  maxLines: 5,
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Purchasable'),
                  subtitle: const Text('Turn off to hide without deleting'),
                  value: _active,
                  onChanged: (value) => setState(() => _active = value),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _saving ? null : _submit,
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(isEditing ? 'Save changes' : 'Create plan'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
