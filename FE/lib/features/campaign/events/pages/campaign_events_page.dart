import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../auth/shared/providers/auth_provider.dart';
import '../../shared/models/campaign_models.dart';
import '../../shared/providers/campaign_provider.dart';
import '../widgets/event_form_dialog.dart';

class CampaignEventsPage extends ConsumerWidget {
  const CampaignEventsPage({super.key, required this.campaignId});

  final int campaignId;

  Future<void> _createEvent(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
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
          SnackBar(content: Text(l10n.eventSaved)),
        );
      }
    } catch (error) {
      if (context.mounted) _showError(context, error);
    }
  }

  Future<void> _archiveEvent(BuildContext context, WidgetRef ref, CampaignEventModel event) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.confirmArchive),
        content: Text('${l10n.archive} "${event.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.archive),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(campaignRepositoryProvider).archiveEvent(event.id);
        ref.invalidate(campaignEventsProvider(campaignId));
        ref.invalidate(campaignDashboardProvider(campaignId));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.archived)),
          );
        }
      } catch (e) {
        if (context.mounted) _showError(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final campaign = ref.watch(campaignDetailProvider(campaignId));
    final events = ref.watch(campaignEventsProvider(campaignId));
    final role = ref.watch(activeUserProvider).valueOrNull?.role;
    final canManage = role == 'MANAGER' || role == 'ADMIN';

    return Scaffold(
      appBar: AppBar(
        title: campaign.maybeWhen(
          data: (item) => Text('${item.name} ${l10n.events}'),
          orElse: () => Text(l10n.campaignEvents),
        ),
        actions: [
          IconButton(
            tooltip: l10n.refresh,
            onPressed: () => ref.invalidate(campaignEventsProvider(campaignId)),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: () => _createEvent(context, ref),
              icon: const Icon(Icons.add),
              label: Text(l10n.createEvent),
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
            return Center(child: Text(l10n.noEventsYet));
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: items.length,
            itemBuilder: (context, index) {
              return _EventCard(
                event: items[index],
                canManage: canManage,
                onArchive: () => _archiveEvent(context, ref, items[index]),
              );
            },
          );
        },
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({
    required this.event,
    required this.canManage,
    required this.onArchive,
  });

  final CampaignEventModel event;
  final bool canManage;
  final VoidCallback onArchive;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

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
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('#${event.id}'),
            if (canManage) ...[
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.archive_outlined),
                tooltip: l10n.archive,
                onPressed: onArchive,
              ),
            ],
          ],
        ),
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
    final l10n = AppLocalizations.of(context)!;

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
                label: Text(l10n.retry),
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
