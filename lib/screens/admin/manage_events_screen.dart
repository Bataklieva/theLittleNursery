import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/workshop_event.dart';
import '../../services/event_service.dart';
import 'event_form_screen.dart';

class ManageEventsScreen extends StatelessWidget {
  const ManageEventsScreen({super.key});

  Future<void> _confirmDelete(BuildContext context, WorkshopEvent event) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete workshop?'),
        content: Text(
          '"${event.title}" will be removed from the calendar'
          '${event.bookedCount > 0 ? ' along with its ${event.bookedCount} booking(s)' : ''}.',
        ),
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
      await context.read<EventService>().deleteEvent(event.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventService = context.read<EventService>();
    return Scaffold(
      appBar: AppBar(title: const Text('Manage workshops')),
      body: StreamBuilder<List<WorkshopEvent>>(
        stream: eventService.watchAllForAdmin(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final events = snapshot.data ?? const [];
          if (events.isEmpty) {
            return const Center(child: Text('No workshops yet — add one below.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return Card(
                child: ListTile(
                  title: Text(event.title),
                  subtitle: Text(
                    '${DateFormat('EEE, d MMM · HH:mm').format(event.startTime)}'
                    ' · ${event.bookedCount}/${event.capacity} booked',
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => EventFormScreen(existingEvent: event),
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _confirmDelete(context, event),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('New workshop'),
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const EventFormScreen()),
        ),
      ),
    );
  }
}
