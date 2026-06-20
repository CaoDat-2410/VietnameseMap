import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/providers/campaign_provider.dart';
import '../widgets/event_form_dialog.dart';
import '../widgets/event_status_chip.dart';
import '../widgets/event_type_chip.dart';

class CampaignEventsPage extends ConsumerWidget {
  const CampaignEventsPage({super.key, required this.campaignId});

  final int campaignId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(campaignEventsProvider(campaignId));
    final campaignAsync = ref.watch(campaignDetailProvider(campaignId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Campaign Events'),
        actions: [
          IconButton(
            onPressed: () => ref.invalidate(campaignEventsProvider(campaignId)),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _create(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Create Event'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              campaignAsync.valueOrNull?.name ?? 'Campaign #$campaignId',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          Expanded(
            child: eventsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _ErrorState(
                error: error,
                onRetry: () =>
                    ref.invalidate(campaignEventsProvider(campaignId)),
              ),
              data: (events) {
                if (events.isEmpty) {
                  return const Center(child: Text('No events yet.'));
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(campaignEventsProvider(campaignId));
                    await ref.read(campaignEventsProvider(campaignId).future);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                    itemCount: events.length,
                    itemBuilder: (context, index) {
                      final event = events[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () => context.push('/events/${event.id}'),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  event.name,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    EventTypeChip(eventType: event.eventType),
                                    EventStatusChip(status: event.status),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text('${event.startsAt} → ${event.endsAt}'),
                                if (event.note.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    event.note,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final data = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const EventFormDialog(),
    );
    if (data == null || !context.mounted) return;
    try {
      await ref.read(campaignRepositoryProvider).createEvent(campaignId, data);
      ref.invalidate(campaignEventsProvider(campaignId));
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Event created.')));
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Create failed: $error')));
      }
    }
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(error.toString(), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
