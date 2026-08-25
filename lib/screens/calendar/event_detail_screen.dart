import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/child.dart';
import '../../models/location.dart';
import '../../models/workshop_event.dart';
import '../../services/auth_service.dart';
import '../../services/booking_service.dart';
import '../../services/event_service.dart';

class EventDetailScreen extends StatefulWidget {
  const EventDetailScreen({super.key, required this.eventId});

  final String eventId;

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  WorkshopEvent? _event;
  bool _loading = true;
  bool _booking = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final event =
        await context.read<EventService>().getById(widget.eventId);
    if (!mounted) return;
    setState(() {
      _event = event;
      _loading = false;
    });
  }

  Future<void> _bookFor(Child child) async {
    final auth = context.read<AuthService>();
    setState(() {
      _booking = true;
      _error = null;
    });
    try {
      await context.read<BookingService>().book(
            eventId: widget.eventId,
            parentUid: auth.user!.uid,
            childId: child.id,
            childName: child.name,
          );
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Booked a spot for ${child.name}!')),
        );
      }
    } on AlreadyBookedException {
      setState(() => _error = '${child.name} is already booked for this workshop.');
    } on BookingFullException {
      setState(() => _error = 'Sorry, this workshop just filled up.');
    } finally {
      if (mounted) setState(() => _booking = false);
    }
  }

  void _showChildPicker() {
    final children = context.read<AuthService>().children;
    if (children.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add a child in your profile before booking.'),
        ),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Who is this booking for?'),
            ),
            for (final child in children)
              ListTile(
                title: Text(child.name),
                onTap: () {
                  Navigator.of(context).pop();
                  _bookFor(child);
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final event = _event;
    if (event == null) {
      return const Scaffold(body: Center(child: Text('Workshop not found.')));
    }

    final location = Locations.all.firstWhere(
      (l) => l.id == event.locationId,
      orElse: () => Locations.center,
    );
    final dateFormat = DateFormat('EEEE, d MMMM · HH:mm');

    return Scaffold(
      appBar: AppBar(title: Text(event.title)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(event.title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.schedule, size: 18),
                  const SizedBox(width: 6),
                  Text(dateFormat.format(event.startTime)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.place_outlined, size: 18),
                  const SizedBox(width: 6),
                  Expanded(child: Text(location.name)),
                ],
              ),
              const SizedBox(height: 16),
              Text(event.description),
              const SizedBox(height: 16),
              Text(
                event.isFull
                    ? 'This workshop is fully booked.'
                    : '${event.spotsLeft} of ${event.capacity} spots left',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed:
                    (event.isFull || _booking) ? null : _showChildPicker,
                child: _booking
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(event.isFull ? 'Fully booked' : 'Reserve a spot'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
