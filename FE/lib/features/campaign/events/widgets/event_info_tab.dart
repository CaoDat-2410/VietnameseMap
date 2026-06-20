import 'package:flutter/material.dart';

import '../../../../core/utils/date_time_utils.dart';
import '../../shared/models/campaign_models.dart';

class EventInfoTab extends StatelessWidget {
  const EventInfoTab({super.key, required this.event, required this.onEdit});

  final CampaignEventModel event;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String)>[
      ('Name', event.name),
      ('Event type', event.eventType),
      ('Status', event.status),
      ('Starts at', formatDateTime(parseDateTime(event.startsAt))),
      ('Ends at', formatDateTime(parseDateTime(event.endsAt))),
      ('Note', event.note),
      ('Campaign ID', event.campaignId.toString()),
      ('Event ID', event.id.toString()),
    ];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit),
            label: const Text('Edit'),
          ),
        ),
        const SizedBox(height: 8),
        ...rows.map(
          (row) => Card(
            child: ListTile(
              title: Text(row.$1),
              subtitle: Text(row.$2.isEmpty ? 'N/A' : row.$2),
            ),
          ),
        ),
      ],
    );
  }
}
