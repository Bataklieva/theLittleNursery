import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/location.dart';
import '../../models/workshop_event.dart';
import '../../services/event_service.dart';

class EventFormScreen extends StatefulWidget {
  const EventFormScreen({super.key, this.existingEvent});

  final WorkshopEvent? existingEvent;

  @override
  State<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends State<EventFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _capacityController;
  late String _locationId;
  late DateTime _startTime;
  late DateTime _endTime;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingEvent;
    final now = DateTime.now();
    final defaultStart = DateTime(now.year, now.month, now.day + 1, 10);

    _titleController = TextEditingController(text: existing?.title ?? '');
    _descriptionController =
        TextEditingController(text: existing?.description ?? '');
    _capacityController = TextEditingController(
      text: (existing?.capacity ?? 8).toString(),
    );
    _locationId = existing?.locationId ?? Locations.center.id;
    _startTime = existing?.startTime ?? defaultStart;
    _endTime = existing?.endTime ?? defaultStart.add(const Duration(hours: 1));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  Future<DateTime?> _pickDateTime(DateTime initial) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _pickStart() async {
    final picked = await _pickDateTime(_startTime);
    if (picked == null) return;
    setState(() {
      _startTime = picked;
      if (!_endTime.isAfter(_startTime)) {
        _endTime = _startTime.add(const Duration(hours: 1));
      }
    });
  }

  Future<void> _pickEnd() async {
    final picked = await _pickDateTime(_endTime);
    if (picked == null) return;
    setState(() => _endTime = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_endTime.isAfter(_startTime)) {
      setState(() => _error = 'End time must be after the start time.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });

    final capacity = int.parse(_capacityController.text.trim());
    final eventService = context.read<EventService>();
    final existing = widget.existingEvent;

    try {
      if (existing == null) {
        await eventService.createEvent(WorkshopEvent(
          id: '',
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          locationId: _locationId,
          startTime: _startTime,
          endTime: _endTime,
          capacity: capacity,
          bookedCount: 0,
        ));
      } else {
        await eventService.updateEvent(existing.copyWith(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          locationId: _locationId,
          startTime: _startTime,
          endTime: _endTime,
          capacity: capacity,
        ));
      }
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingEvent != null;
    final dateFormat = DateFormat('EEE, d MMM yyyy · HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit workshop' : 'New workshop'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
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
                DropdownButtonFormField<String>(
                  value: _locationId,
                  decoration: const InputDecoration(labelText: 'Location'),
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
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Starts'),
                  subtitle: Text(dateFormat.format(_startTime)),
                  trailing: const Icon(Icons.edit_calendar_outlined),
                  onTap: _pickStart,
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Ends'),
                  subtitle: Text(dateFormat.format(_endTime)),
                  trailing: const Icon(Icons.edit_calendar_outlined),
                  onTap: _pickEnd,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _capacityController,
                  decoration: const InputDecoration(labelText: 'Capacity'),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    final n = int.tryParse(v?.trim() ?? '');
                    if (n == null || n < 1) return 'Enter a positive number';
                    if (isEditing &&
                        n < (widget.existingEvent!.bookedCount)) {
                      return 'Below current bookings (${widget.existingEvent!.bookedCount})';
                    }
                    return null;
                  },
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _saving ? null : _submit,
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(isEditing ? 'Save changes' : 'Create workshop'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
