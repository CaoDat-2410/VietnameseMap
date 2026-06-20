import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/date_time_utils.dart';
import '../../../school/shared/models/school_model.dart';
import '../../shared/providers/campaign_provider.dart';
import 'create_interaction_dialog.dart';

class EventInteractionsTab extends ConsumerWidget {
  const EventInteractionsTab({
    super.key,
    required this.eventId,
    this.availableSchools = const [],
  });

  final int eventId;
  final List<SchoolModel> availableSchools;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final interactions = ref.watch(eventInteractionsProvider(eventId));
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: () =>
                    ref.invalidate(eventInteractionsProvider(eventId)),
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: () => _create(context, ref),
                icon: const Icon(Icons.add),
                label: const Text('Create Interaction'),
              ),
            ],
          ),
        ),
        Expanded(
          child: interactions.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(error.toString(), textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () =>
                        ref.invalidate(eventInteractionsProvider(eventId)),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
            data: (items) {
              if (items.isEmpty) {
                return const Center(child: Text('No interactions yet.'));
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final interaction = items[index];
                  final followUpAt = parseDateTime(interaction.nextFollowUpAt);
                  final createdAt = parseDateTime(interaction.createdAt);
                  return Card(
                    child: ListTile(
                      title: Text(
                        '${interaction.participantType} '
                        '#${interaction.participantId}',
                      ),
                      subtitle: Text(
                        'School: ${interaction.schoolUid}\n'
                        '${interaction.channel} • ${interaction.outcome}\n'
                        '${interaction.note.isEmpty ? 'No note' : interaction.note}\n'
                        'Follow-up: ${formatDateTime(followUpAt)}\n'
                        'Created: ${formatDateTime(createdAt)}',
                      ),
                      isThreeLine: true,
                      trailing: Text('#${interaction.id}'),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final data = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => CreateInteractionDialog(
        availableSchools: availableSchools,
      ),
    );
    if (data == null || !context.mounted) return;
    try {
      await ref
          .read(campaignRepositoryProvider)
          .createInteraction(eventId, data);
      ref.invalidate(eventInteractionsProvider(eventId));
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Interaction created.')));
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
