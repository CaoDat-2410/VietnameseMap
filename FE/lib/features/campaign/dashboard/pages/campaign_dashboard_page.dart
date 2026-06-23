import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/shared/providers/auth_provider.dart';
import '../../shared/models/campaign_models.dart';
import '../../shared/providers/campaign_provider.dart';
import '../widgets/outcome_donut_chart.dart';
import '../widgets/province_bar_chart.dart';
import '../widgets/top_schools_bar_chart.dart';

class CampaignDashboardPage extends ConsumerWidget {
  const CampaignDashboardPage({super.key, required this.campaignId});

  final int campaignId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final campaign = ref.watch(campaignDetailProvider(campaignId));
    final dashboard = ref.watch(campaignDashboardProvider(campaignId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Campaign Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () {
              ref.invalidate(campaignDetailProvider(campaignId));
              ref.invalidate(campaignDashboardProvider(campaignId));
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: campaign.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorBlock(
          error: error,
          onRetry: () => ref.invalidate(campaignDetailProvider(campaignId)),
        ),
        data: (campaignData) => dashboard.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _ErrorBlock(
            error: error,
            onRetry: () =>
                ref.invalidate(campaignDashboardProvider(campaignId)),
          ),
          data: (dashboardData) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _Header(campaign: campaignData),
              const SizedBox(height: 16),
              _KpiGrid(dashboard: dashboardData),
              const SizedBox(height: 16),
              _OutcomeChart(outcomes: dashboardData.interactionsByOutcome),
              const SizedBox(height: 16),
              _ProvinceChart(items: dashboardData.interactionsByProvince),
              const SizedBox(height: 16),
              _TopSchoolsChart(items: dashboardData.topSchools),
              const SizedBox(height: 16),
              _RegistrationsSection(campaignId: campaignId),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.campaign});

  final CampaignModel campaign;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                campaign.name,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            Chip(label: Text(campaign.status)),
          ],
        ),
        const SizedBox(height: 8),
        Text(campaign.objective.isEmpty ? '-' : campaign.objective),
        const SizedBox(height: 8),
        Text('${campaign.startDate} - ${campaign.endDate}'),
      ],
    );
  }
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.dashboard});

  final CampaignDashboardModel dashboard;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Events', dashboard.totalEvents, Icons.event_outlined),
      ('Schools', dashboard.totalTargetSchools, Icons.school_outlined),
      ('Employees', dashboard.totalAssignedEmployees, Icons.people_outline),
      ('Interactions', dashboard.totalInteractions, Icons.chat_outlined),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 700 ? 4 : 2;
        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 2.1,
          children: [
            for (final item in items)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(item.$3),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(item.$1),
                            Text(
                              '${item.$2}',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _OutcomeChart extends StatelessWidget {
  const _OutcomeChart({required this.outcomes});

  final Map<String, int> outcomes;

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'Tương tác theo kết quả',
      child: OutcomeDonutChart(outcomes: outcomes),
    );
  }
}

class _ProvinceChart extends StatelessWidget {
  const _ProvinceChart({required this.items});

  final List<ProvinceInteractionModel> items;

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'Tương tác theo tỉnh/thành',
      child: ProvinceBarChart(items: items),
    );
  }
}

class _TopSchoolsChart extends StatelessWidget {
  const _TopSchoolsChart({required this.items});

  final List<TopSchoolModel> items;

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'Top trường',
      child: TopSchoolsBarChart(items: items),
    );
  }
}

class _RegistrationsSection extends ConsumerWidget {
  const _RegistrationsSection({required this.campaignId});

  final int campaignId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final registrations = ref.watch(campaignRegistrationsProvider(campaignId));
    final role = ref.watch(activeUserProvider).valueOrNull?.role;
    final canManage = role == 'MANAGER' || role == 'ADMIN';
    return _Section(
      title: 'Student Registrations',
      child: registrations.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(16),
          child: LinearProgressIndicator(),
        ),
        error: (error, _) => Padding(
          padding: const EdgeInsets.all(16),
          child: Text(error.toString()),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No registrations yet'),
            );
          }
          return Column(
            children: [
              for (final item in items)
                ListTile(
                  title: Text(item.student.fullName),
                  subtitle: Text(
                    '${item.school.schoolName}\n${item.student.email} | ${item.student.phone}',
                  ),
                  isThreeLine: true,
                  trailing: canManage
                      ? Wrap(
                          spacing: 8,
                          children: [
                            _StatusButton(item.id, 'APPROVED', campaignId),
                            _StatusButton(item.id, 'REJECTED', campaignId),
                          ],
                        )
                      : Chip(label: Text(item.status)),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _StatusButton extends ConsumerWidget {
  const _StatusButton(this.registrationId, this.status, this.campaignId);

  final int registrationId;
  final String status;
  final int campaignId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TextButton(
      onPressed: () async {
        await ref
            .read(campaignRepositoryProvider)
            .updateRegistrationStatus(registrationId, status);
        ref.invalidate(campaignRegistrationsProvider(campaignId));
      },
      child: Text(status),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: child,
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
