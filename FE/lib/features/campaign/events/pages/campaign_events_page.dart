import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/shared/providers/auth_provider.dart';
import '../../shared/models/campaign_models.dart';
import '../../shared/providers/campaign_provider.dart';
import '../widgets/event_form_dialog.dart';

class CampaignEventsPage extends ConsumerWidget {
  const CampaignEventsPage({super.key, required this.campaignId});

  final int campaignId;

  Future<void> _createEvent(BuildContext context, WidgetRef ref) async {
    try {
      await showDialog<void>(
        context: context,
        builder: (context) => EventFormDialog(
          onSubmit: (data) async {
            await ref
                .read(campaignRepositoryProvider)
                .createEvent(campaignId, data);
            ref.invalidate(campaignEventsProvider(campaignId));
            ref.invalidate(campaignDashboardProvider(campaignId));
          },
        ),
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event saved')),
        );
      }
    } catch (error) {
      if (context.mounted) _showError(context, error);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final campaign = ref.watch(campaignDetailProvider(campaignId));
    final events = ref.watch(campaignEventsProvider(campaignId));
    final role = ref.watch(activeUserProvider).valueOrNull?.role;
    final canManage = role == 'MANAGER' || role == 'ADMIN';

    return Scaffold(
      appBar: AppBar(
        title: campaign.maybeWhen(
          data: (item) => Text('${item.name} Events'),
          orElse: () => const Text('Campaign Events'),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(campaignEventsProvider(campaignId)),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: () => _createEvent(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Create Event'),
            )
          : null,
      body: events.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorBlock(
          error: error,
          onRetry: () => ref.invalidate(campaignEventsProvider(campaignId)),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('No events yet'));
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: items.length,
            itemBuilder: (context, index) {
              return _EventCard(event: items[index]);
            },
          );
        },
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event});

  final CampaignEventModel event;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: () => context.go('/events/${event.id}'),
        leading: const Icon(Icons.event_outlined),
        title: Text(event.name),
        subtitle: Text(
          '${event.eventType} | ${event.status}\n'
          '${event.startsAt.isEmpty ? '-' : event.startsAt} - '
          '${event.endsAt.isEmpty ? '-' : event.endsAt}\n'
          '${event.note.isEmpty ? '-' : event.note}',
        ),
        trailing: Text('#${event.id}'),
        isThreeLine: true,
      ),
    );
  }
}

class _ErrorBlock extends StatelessWidget {
  const _ErrorBlock({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        color: Theme.of(context).colorScheme.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(error.toString()),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void _showError(BuildContext context, Object error) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(error.toString())),
  );
}
