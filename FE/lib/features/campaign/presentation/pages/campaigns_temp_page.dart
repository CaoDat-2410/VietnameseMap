import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/dev_identity.dart';
import '../../shared/providers/campaign_provider.dart';

class CampaignsTempPage extends ConsumerStatefulWidget {
  const CampaignsTempPage({super.key});

  @override
  ConsumerState<CampaignsTempPage> createState() => _CampaignsTempPageState();
}

class _CampaignsTempPageState extends ConsumerState<CampaignsTempPage> {
  bool _creating = false;

  Future<void> _createCampaign() async {
    setState(() => _creating = true);
    try {
      await ref.read(campaignRepositoryProvider).createCampaign({
        'name': 'Temp Campaign ${DateTime.now().millisecondsSinceEpoch}',
        'status': 'DRAFT',
        'objective': 'Temporary API verification',
        'startDate': '2026-06-01',
        'endDate': '2026-07-31',
        'ownerEmployeeId': devEmployeeId,
      });
      ref.invalidate(campaignsProvider);
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final campaigns = ref.watch(campaignsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Campaigns Temp')),
      body: campaigns.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorBlock(error: error),
        data: (items) {
          final selected = items.isEmpty ? null : items.first;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              FilledButton.icon(
                onPressed: _creating ? null : _createCampaign,
                icon: _creating
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add),
                label: const Text('Create temp campaign'),
              ),
              const SizedBox(height: 16),
              Text(
                'Campaigns: ${items.length}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              for (final campaign in items)
                Card(
                  child: ListTile(
                    title: Text(campaign.name),
                    subtitle: Text(
                      '${campaign.status} | owner ${campaign.ownerEmployeeId}',
                    ),
                    trailing: Text('#${campaign.id}'),
                  ),
                ),
              if (selected != null) ...[
                const SizedBox(height: 24),
                Text(
                  'Dashboard JSON',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                _DashboardJson(campaignId: selected.id),
                const SizedBox(height: 24),
                Text('Events', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                _EventsList(campaignId: selected.id),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _DashboardJson extends ConsumerWidget {
  const _DashboardJson({required this.campaignId});

  final int campaignId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(campaignDashboardProvider(campaignId));
    return dashboard.when(
      loading: () => const LinearProgressIndicator(),
      error: (error, _) => _ErrorBlock(error: error),
      data: (data) => DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            'totalEvents: ${data.totalEvents}\n'
            'totalTargetSchools: ${data.totalTargetSchools}\n'
            'totalAssignedEmployees: ${data.totalAssignedEmployees}\n'
            'totalInteractions: ${data.totalInteractions}\n'
            'interactionsByOutcome: ${data.interactionsByOutcome}',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _EventsList extends ConsumerWidget {
  const _EventsList({required this.campaignId});

  final int campaignId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(campaignEventsProvider(campaignId));
    return events.when(
      loading: () => const LinearProgressIndicator(),
      error: (error, _) => _ErrorBlock(error: error),
      data: (items) => Column(
        children: [
          for (final event in items)
            Card(
              child: ListTile(
                title: Text(event.name),
                subtitle: Text('${event.eventType} | ${event.status}'),
                trailing: Text('#${event.id}'),
              ),
            ),
        ],
      ),
    );
  }
}

class _ErrorBlock extends StatelessWidget {
  const _ErrorBlock({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(error.toString()),
      ),
    );
  }
}
