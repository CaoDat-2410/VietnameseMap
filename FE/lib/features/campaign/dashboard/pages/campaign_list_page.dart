import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/shared/providers/auth_provider.dart';
import '../../shared/models/campaign_models.dart';
import '../../shared/providers/campaign_provider.dart';

class CampaignListPage extends ConsumerStatefulWidget {
  const CampaignListPage({super.key});

  @override
  ConsumerState<CampaignListPage> createState() => _CampaignListPageState();
}

class _CampaignListPageState extends ConsumerState<CampaignListPage> {
  final _searchController = TextEditingController();
  String _status = 'ALL';
  bool _creating = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _createCampaign() async {
    setState(() => _creating = true);
    try {
      final user = await ref.read(currentUserProvider.future);
      await ref.read(campaignRepositoryProvider).createCampaign({
        'name': 'Campaign ${DateTime.now().millisecondsSinceEpoch}',
        'status': 'DRAFT',
        'objective': 'New campaign objective',
        'startDate': '2026-06-01',
        'endDate': '2026-07-31',
        'ownerEmployeeId': user?.employeeId,
      });
      ref.invalidate(campaignsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Campaign created')),
        );
      }
    } catch (error) {
      if (mounted) _showError(context, error);
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final campaigns = ref.watch(campaignsProvider);
    final role = ref.watch(activeUserProvider).valueOrNull?.role;
    final canManage = role == 'MANAGER' || role == 'ADMIN';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Campaigns'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(campaignsProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: _creating ? null : _createCampaign,
              icon: _creating
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add),
              label: const Text('Create'),
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
                const _EmptyBlock(message: 'No campaigns yet')
              else
                for (final campaign in filtered)
                  _CampaignCard(campaign: campaign),
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
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 280,
          child: TextField(
            controller: searchController,
            decoration: const InputDecoration(
              labelText: 'Search',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (_) => onChanged(),
          ),
        ),
        SizedBox(
          width: 170,
          child: DropdownButtonFormField<String>(
            initialValue: status,
            decoration: const InputDecoration(labelText: 'Status'),
            items: const [
              DropdownMenuItem(value: 'ALL', child: Text('ALL')),
              DropdownMenuItem(value: 'DRAFT', child: Text('DRAFT')),
              DropdownMenuItem(value: 'ACTIVE', child: Text('ACTIVE')),
              DropdownMenuItem(value: 'DONE', child: Text('DONE')),
              DropdownMenuItem(value: 'CANCELLED', child: Text('CANCELLED')),
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
  const _CampaignCard({required this.campaign});

  final CampaignModel campaign;

  @override
  Widget build(BuildContext context) {
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
              ],
            ),
            const SizedBox(height: 8),
            Text(campaign.objective.isEmpty ? '-' : campaign.objective),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                Text('Start: ${campaign.startDate}'),
                Text('End: ${campaign.endDate}'),
                Text('Owner: ${campaign.ownerEmployeeId}'),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: () =>
                      context.go('/campaigns/${campaign.id}/dashboard'),
                  icon: const Icon(Icons.dashboard_outlined),
                  label: const Text('Dashboard'),
                ),
                OutlinedButton.icon(
                  onPressed: () =>
                      context.go('/campaigns/${campaign.id}/events'),
                  icon: const Icon(Icons.event_outlined),
                  label: const Text('Events'),
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
