import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/workshop_event.dart';
import '../../services/auth_service.dart';
import '../../services/event_service.dart';
import '../calendar/event_detail_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final firstName = auth.profile?.name.split(' ').first ?? 'there';

    return Scaffold(
      appBar: AppBar(title: const Text('The Little Nursery')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Hi, $firstName 👋',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          Text(
            'Here\'s what\'s coming up at the studio.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          Text('Upcoming workshops',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          StreamBuilder<List<WorkshopEvent>>(
            stream: context.read<EventService>().watchUpcoming(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final events = snapshot.data ?? const [];
              if (events.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('No upcoming workshops yet — check back soon!'),
                );
              }
              return Column(
                children: [
                  for (final event in events.take(5))
                    _EventTile(event: event),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  const _EventTile({required this.event});

  final WorkshopEvent event;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEE, d MMM · HH:mm');
    return Card(
      child: ListTile(
        title: Text(event.title),
        subtitle: Text(dateFormat.format(event.startTime)),
        trailing: event.isFull
            ? const Chip(label: Text('Full'))
            : Text('${event.spotsLeft} spots left'),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => EventDetailScreen(eventId: event.id),
          ),
        ),
      ),
    );
  }
}
