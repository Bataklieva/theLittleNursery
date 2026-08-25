import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/location.dart';

class LocationsScreen extends StatelessWidget {
  const LocationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Our locations')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final location in Locations.all) ...[
            _LocationCard(location: location),
            const SizedBox(height: 16),
          ],
          const _ContactCard(),
        ],
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({required this.location});

  final NurseryLocation location;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(location.name, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.place_outlined, size: 18),
                const SizedBox(width: 6),
                Expanded(child: Text(location.address)),
              ],
            ),
            const SizedBox(height: 8),
            Text(location.description),
          ],
        ),
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Contact us', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.phone_outlined),
              title: const Text(Locations.contactPhone),
              onTap: () =>
                  launchUrl(Uri(scheme: 'tel', path: Locations.contactPhone)),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.email_outlined),
              title: const Text(Locations.contactEmail),
              onTap: () =>
                  launchUrl(Uri(scheme: 'mailto', path: Locations.contactEmail)),
            ),
          ],
        ),
      ),
    );
  }
}
