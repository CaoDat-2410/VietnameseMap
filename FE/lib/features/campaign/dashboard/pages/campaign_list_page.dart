import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/models/campaign_models.dart';
import '../../shared/providers/campaign_provider.dart';
import '../widgets/campaign_status_chip.dart';

class CampaignListPage extends ConsumerStatefulWidget {
  const CampaignListPage({super.key});

  @override
  ConsumerState<CampaignListPage> createState() => _CampaignListPageState();
}

class _CampaignListPageState extends ConsumerState<CampaignListPage> {
  String _searchQuery = '';
  String _statusFilter = 'ALL';

  final List<String> _statuses = [
    'ALL',
    'DRAFT',
    'ACTIVE',
    'DONE',
    'CANCELLED',
  ];

  @override
  Widget build(BuildContext context) {
    final campaignsAsync = ref.watch(campaignsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Campaigns'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(campaignsProvider),
          ),
        ],
      ),
      body: campaignsAsync.when(
        data: (campaigns) {
          final filteredCampaigns = campaigns.where((c) {
            final matchesStatus =
                _statusFilter == 'ALL' || c.status == _statusFilter;
            final matchesSearch = c.name.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                );
            return matchesStatus && matchesSearch;
          }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final searchField = TextField(
                      decoration: const InputDecoration(
                        hintText: 'Search campaigns...',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    );

                    final dropdownField = DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: _statusFilter,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      items: _statuses.map((status) {
                        return DropdownMenuItem(
                          value: status,
                          child: Text(status, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _statusFilter = value!;
                        });
                      },
                    );

                    if (constraints.maxWidth > 600) {
                      return Row(
                        children: [
                          Expanded(flex: 2, child: searchField),
                          const SizedBox(width: 16),
                          Expanded(flex: 1, child: dropdownField),
                        ],
                      );
                    } else {
                      return Column(
                        children: [
                          searchField,
                          const SizedBox(height: 12),
                          dropdownField,
                        ],
                      );
                    }
                  },
                ),
              ),
              Expanded(
                child: filteredCampaigns.isEmpty
                    ? Center(
                        child: Text(
                          campaigns.isEmpty
                              ? 'No campaigns yet.'
                              : 'No campaigns found.',
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          ref.invalidate(campaignsProvider);
                        },
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            if (constraints.maxWidth > 1000) {
                              return _buildTableView(filteredCampaigns);
                            } else {
                              return _buildCardView(filteredCampaigns);
                            }
                          },
                        ),
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $err'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(campaignsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTableView(List<CampaignModel> campaigns) {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      physics: const AlwaysScrollableScrollPhysics(),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          showCheckboxColumn: false,
          columns: const [
            DataColumn(
              label: Text(
                'Name',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Status',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Objective',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Duration',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Owner ID',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
          rows: campaigns.map((c) {
            return DataRow(
              onSelectChanged: (_) {
                context.push('/campaigns/${c.id}/dashboard');
              },
              cells: [
                DataCell(Text(c.name)),
                DataCell(CampaignStatusChip(status: c.status)),
                DataCell(Text(c.objective)),
                DataCell(Text('${c.startDate} - ${c.endDate}')),
                DataCell(Text('${c.ownerEmployeeId}')),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildCardView(List<CampaignModel> campaigns) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: campaigns.length,
      itemBuilder: (context, index) {
        final c = campaigns[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16.0),
          child: InkWell(
            onTap: () {
              context.push('/campaigns/${c.id}/dashboard');
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          c.name,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      const SizedBox(width: 8),
                      CampaignStatusChip(status: c.status),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Objective: ${c.objective}'),
                  const SizedBox(height: 4),
                  Text('Duration: ${c.startDate} - ${c.endDate}'),
                  const SizedBox(height: 4),
                  Text('Owner ID: ${c.ownerEmployeeId}'),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
