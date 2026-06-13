import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/providers/campaign_provider.dart';

class EventInteractionsTab extends ConsumerWidget {
  const EventInteractionsTab({super.key, required this.eventId});

  final int eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final interactions = ref.watch(eventInteractionsProvider(eventId));
    return interactions.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text(error.toString())),
      data: (items) {
        if (items.isEmpty) {
          return const Center(child: Text('No interactions yet'));
        }
        return ListView.separated(
          itemCount: items.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final interaction = items[index];
            return ListTile(
              title: Text(
                  '${interaction.participantType} #${interaction.participantId}'),
              subtitle: Text(
                  '${interaction.channel} | ${interaction.outcome}\n${interaction.note}'),
              trailing: Text('#${interaction.id}'),
            );
          },
        );
      },
    );
  }
}
