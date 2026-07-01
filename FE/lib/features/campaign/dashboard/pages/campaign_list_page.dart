import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../auth/shared/providers/auth_provider.dart';
import '../../shared/models/campaign_models.dart';
import '../../shared/providers/campaign_provider.dart';
import '../widgets/campaign_form_dialog.dart';

class CampaignListPage extends ConsumerStatefulWidget {
  const CampaignListPage({super.key});

  @override
  ConsumerState<CampaignListPage> createState() => _CampaignListPageState();
}

class _CampaignListPageState extends ConsumerState<CampaignListPage> {
  final _searchController = TextEditingController();
  String _status = 'ALL';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _showCampaignForm([CampaignModel? campaign]) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => CampaignFormDialog(
        campaign: campaign,
        onSubmit: (data) async {
          final repo = ref.read(campaignRepositoryProvider);
          if (campaign != null) {
            await repo.updateCampaign(campaign.id, data);
          } else {
            final user = await ref.read(currentUserProvider.future);
            await repo.createCampaign({
              ...data,
              'ownerEmployeeId': user?.employeeId,
            });
          }
          ref.invalidate(campaignsProvider);
        },
      ),
    );
  }

  Future<void> _archiveCampaign(CampaignModel campaign) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.confirmArchive),
        content: Text('${l10n.archive} "${campaign.name}"?'),
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
        await ref.read(campaignRepositoryProvider).archiveCampaign(campaign.id);
        ref.invalidate(campaignsProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.archived)),
          );
        }
      } catch (e) {
        if (mounted) _showError(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final campaigns = ref.watch(campaignsProvider);
    final role = ref.watch(activeUserProvider).valueOrNull?.role;
    final canManage = role == 'MANAGER' || role == 'ADMIN';

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.campaignsTitle),
        actions: [
          IconButton(
            tooltip: l10n.refresh,
            onPressed: () => ref.invalidate(campaignsProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: () => _showCampaignForm(),
              icon: const Icon(Icons.add),
              label: Text(l10n.create),
            )
          : null,
      body: campaigns.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorBlock(
          error: error,
          onRetry: () => ref.invalidate(campaignsProvider),
        ),
        data: (items) {
          final query = _searchController.text.trim().toLowerCase();
          final filtered = items.where((campaign) {
            final matchesSearch =
                query.isEmpty || campaign.name.toLowerCase().contains(query);
            final matchesStatus =
                _status == 'ALL' || campaign.status == _status;
            return matchesSearch && matchesStatus;
          }).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _CampaignFilters(
                searchController: _searchController,
                status: _status,
                onStatusChanged: (value) => setState(() => _status = value),
                onChanged: () => setState(() {}),
              ),
              const SizedBox(height: 16),
              if (filtered.isEmpty)
                _EmptyBlock(message: l10n.noCampaignsYet)
              else
                for (final campaign in filtered)
                  _CampaignCard(
                    campaign: campaign,
                    canManage: canManage,
                    onEdit: () => _showCampaignForm(campaign),
                    onArchive: () => _archiveCampaign(campaign),
                  ),
              const SizedBox(height: 80),
            ],
          );
        },
      ),
    );
  }
}

class _CampaignFilters extends StatelessWidget {
  const _CampaignFilters({
    required this.searchController,
    required this.status,
    required this.onStatusChanged,
    required this.onChanged,
  });

  final TextEditingController searchController;
  final String status;
  final ValueChanged<String> onStatusChanged;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 280,
          child: TextField(
            controller: searchController,
            decoration: InputDecoration(
              labelText: l10n.search,
              prefixIcon: const Icon(Icons.search),
            ),
            onChanged: (_) => onChanged(),
          ),
        ),
        SizedBox(
          width: 170,
          child: DropdownButtonFormField<String>(
            initialValue: status,
            decoration: InputDecoration(labelText: l10n.status),
            items: [
              DropdownMenuItem(value: 'ALL', child: Text(l10n.allStatuses)),
              const DropdownMenuItem(value: 'DRAFT', child: Text('DRAFT')),
              const DropdownMenuItem(value: 'ACTIVE', child: Text('ACTIVE')),
              const DropdownMenuItem(value: 'DONE', child: Text('DONE')),
              const DropdownMenuItem(value: 'CANCELLED', child: Text('CANCELLED')),
            ],
            onChanged: (value) {
              if (value != null) onStatusChanged(value);
            },
          ),
        ),
      ],
    );
  }
}

class _CampaignCard extends StatelessWidget {
  const _CampaignCard({
    required this.campaign,
    required this.canManage,
    required this.onEdit,
    required this.onArchive,
  });

  final CampaignModel campaign;
  final bool canManage;
  final VoidCallback onEdit;
  final VoidCallback onArchive;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    campaign.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Chip(label: Text(campaign.status)),
                if (canManage) ...[
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: l10n.edit,
                    onPressed: onEdit,
                  ),
                  IconButton(
                    icon: const Icon(Icons.archive_outlined),
                    tooltip: l10n.archive,
                    onPressed: onArchive,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Text(campaign.objective.isEmpty ? '-' : campaign.objective),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                Text('${l10n.start}: ${campaign.startDate}'),
                Text('${l10n.end}: ${campaign.endDate}'),
                Text('${l10n.owner}: ${campaign.ownerEmployeeId}'),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () =>
                      context.go('/campaigns/${campaign.id}/events'),
                  icon: const Icon(Icons.event_outlined),
                  label: Text(l10n.events),
                ),
              ],
            ),
          ],
        ),
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

class _EmptyBlock extends StatelessWidget {
  const _EmptyBlock({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(child: Text(message)),
    );
  }
}

void _showError(BuildContext context, Object error) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(error.toString())),
  );
}
