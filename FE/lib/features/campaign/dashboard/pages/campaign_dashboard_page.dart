import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/providers/campaign_provider.dart';
import '../widgets/campaign_kpi_card.dart';
import '../widgets/campaign_status_chip.dart';
import '../widgets/outcome_summary_table.dart';
import '../widgets/province_interaction_table.dart';
import '../widgets/top_school_table.dart';

class CampaignDashboardPage extends ConsumerWidget {
  const CampaignDashboardPage({super.key, required this.campaignId});

  final int campaignId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final campaignAsync = ref.watch(campaignDetailProvider(campaignId));
    final dashboardAsync = ref.watch(campaignDashboardProvider(campaignId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Campaign Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Campaign events',
            icon: const Icon(Icons.event_note),
            onPressed: () => context.push('/campaigns/$campaignId/events'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(campaignDetailProvider(campaignId));
              ref.invalidate(campaignDashboardProvider(campaignId));
            },
          ),
        ],
      ),
      body: campaignAsync.when(
        data: (campaign) {
          return dashboardAsync.when(
            data: (dashboard) {
              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(campaignDetailProvider(campaignId));
                  ref.invalidate(campaignDashboardProvider(campaignId));
                },
                child: ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    // Header
                    Text(
                      campaign.name,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      campaign.objective,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontStyle: FontStyle.italic,
                            color: Colors.grey.shade700,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        CampaignStatusChip(status: campaign.status),
                        const SizedBox(width: 16),
                        Text('${campaign.startDate} - ${campaign.endDate}'),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // KPIs
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final columnCount = constraints.maxWidth >= 900
                            ? 4
                            : constraints.maxWidth >= 520
                                ? 2
                                : 1;

                        return GridView.count(
                          crossAxisCount: columnCount,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisExtent: 112,
                          children: [
                            CampaignKpiCard(
                              title: 'Total Events',
                              value: dashboard.totalEvents.toString(),
                              icon: Icons.event,
                              color: Colors.blue,
                            ),
                            CampaignKpiCard(
                              title: 'Target Schools',
                              value: dashboard.totalTargetSchools.toString(),
                              icon: Icons.school,
                              color: Colors.green,
                            ),
                            CampaignKpiCard(
                              title: 'Assigned Emps',
                              value:
                                  dashboard.totalAssignedEmployees.toString(),
                              icon: Icons.people,
                              color: Colors.orange,
                            ),
                            CampaignKpiCard(
                              title: 'Interactions',
                              value: dashboard.totalInteractions.toString(),
                              icon: Icons.forum,
                              color: Colors.purple,
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // Outcomes
                    OutcomeSummaryTable(
                      outcomes: dashboard.interactionsByOutcome,
                    ),
                    const SizedBox(height: 24),

                    // By Province
                    ProvinceInteractionTable(
                      provinces: dashboard.interactionsByProvince,
                    ),
                    const SizedBox(height: 24),

                    // Top Schools
                    TopSchoolTable(schools: dashboard.topSchools),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error loading dashboard: $err'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () =>
                        ref.invalidate(campaignDashboardProvider(campaignId)),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error loading campaign: $err'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    ref.invalidate(campaignDetailProvider(campaignId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
