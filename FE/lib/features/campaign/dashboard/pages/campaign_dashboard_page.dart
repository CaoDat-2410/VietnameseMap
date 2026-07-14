import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/shared/providers/auth_provider.dart';
import '../../../../core/widgets/bento_card.dart';
import '../../shared/models/campaign_models.dart';
import '../../shared/providers/campaign_provider.dart';
import '../widgets/outcome_donut_chart.dart';
import '../widgets/province_bar_chart.dart';
import '../widgets/top_schools_bar_chart.dart';

class _ResponsiveRow extends StatelessWidget {
  const _ResponsiveRow({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth > 700) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < children.length; i++) ...[
                if (i > 0) const SizedBox(width: 12),
                Expanded(child: children[i]),
              ],
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (int i = 0; i < children.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              children[i],
            ],
          ],
        );
      },
    );
  }
}

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
          data: (dashboardData) => SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(campaign: campaignData),
                const SizedBox(height: 16),
                _KpiGrid(dashboard: dashboardData),
                const SizedBox(height: 16),
                _ResponsiveRow(
                  children: [
                    _OutcomeChart(outcomes: dashboardData.interactionsByOutcome),
                    _ProvinceChart(items: dashboardData.interactionsByProvince),
                  ],
                ),
                const SizedBox(height: 16),
                _ResponsiveRow(
                  children: [
                    _TopSchoolsChart(items: dashboardData.topSchools),
                    _RegistrationsSection(campaignId: campaignId),
                  ],
                ),
              ],
            ),
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
    return BentoCard(
      size: BentoSize.wide,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  campaign.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              StatusChip(
                label: campaign.status,
                status: _getCampaignStatus(campaign.status),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            campaign.objective.isEmpty ? 'Không có mô tả' : campaign.objective,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 16, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                '${campaign.startDate} - ${campaign.endDate}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }

  StatusType _getCampaignStatus(String status) {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
      case 'ONGOING':
        return StatusType.active;
      case 'PLANNED':
      case 'UPCOMING':
        return StatusType.pending;
      case 'COMPLETED':
      case 'FINISHED':
        return StatusType.done;
      case 'CANCELLED':
        return StatusType.error;
      default:
        return StatusType.draft;
    }
  }
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.dashboard});

  final CampaignDashboardModel dashboard;

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        title: 'Sự kiện',
        value: '${dashboard.totalEvents}',
        icon: Icons.event_outlined,
        color: AppColors.primary,
      ),
      (
        title: 'Trường học',
        value: '${dashboard.totalTargetSchools}',
        icon: Icons.school_outlined,
        color: AppColors.tertiary,
      ),
      (
        title: 'Nhân viên',
        value: '${dashboard.totalAssignedEmployees}',
        icon: Icons.people_outline,
        color: AppColors.warning,
      ),
      (
        title: 'Tương tác',
        value: '${dashboard.totalInteractions}',
        icon: Icons.chat_outlined,
        color: AppColors.info,
      ),
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
          childAspectRatio: 1.4,
          children: items.map((item) {
            return KpiCard(
              title: item.title,
              value: item.value,
              icon: item.icon,
              accentColor: item.color,
            );
          }).toList(),
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
    return BentoCard(
      size: BentoSize.wide,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tương tác theo kết quả',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            child: OutcomeDonutChart(outcomes: outcomes),
          ),
        ],
      ),
    );
  }
}

class _ProvinceChart extends StatelessWidget {
  const _ProvinceChart({required this.items});

  final List<ProvinceInteractionModel> items;

  @override
  Widget build(BuildContext context) {
    return BentoCard(
      size: BentoSize.large,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tương tác theo tỉnh/thành',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            child: ProvinceBarChart(items: items),
          ),
        ],
      ),
    );
  }
}

class _TopSchoolsChart extends StatelessWidget {
  const _TopSchoolsChart({required this.items});

  final List<TopSchoolModel> items;

  @override
  Widget build(BuildContext context) {
    return BentoCard(
      size: BentoSize.large,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top trường',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            child: TopSchoolsBarChart(items: items),
          ),
          if (items.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'Danh sách',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            ...items.map((school) => _SchoolRowWithMap(item: school)),
          ],
        ],
      ),
    );
  }
}

class _SchoolRowWithMap extends StatelessWidget {
  const _SchoolRowWithMap({required this.item});

  final TopSchoolModel item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.school_outlined, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              item.schoolName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${item.totalInteractions}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.map_outlined),
            tooltip: 'Xem trên bản đồ',
            onPressed: () =>
                GoRouter.of(context).go('/map?schools=${item.schoolUid}'),
          ),
        ],
      ),
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

    return BentoCard(
      size: BentoSize.xl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Đăng ký học sinh',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: registrations.when(
              loading: () => const Center(
                child: LinearProgressIndicator(),
              ),
              error: (error, _) => Center(
                child: Text(error.toString()),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return const Center(
                    child: Text('Chưa có đăng ký nào'),
                  );
                }
                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return ListTile(
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
                          : StatusChip(
                              label: item.status,
                              status: _getStatusType(item.status),
                            ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  StatusType _getStatusType(String status) {
    switch (status.toUpperCase()) {
      case 'APPROVED':
        return StatusType.active;
      case 'REJECTED':
        return StatusType.error;
      case 'PENDING':
        return StatusType.pending;
      default:
        return StatusType.draft;
    }
  }
}

class _StatusButton extends ConsumerWidget {
  const _StatusButton(this.registrationId, this.status, this.campaignId);

  final int registrationId;
  final String status;
  final int campaignId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FilledButton.tonal(
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

class _ErrorBlock extends StatelessWidget {
  const _ErrorBlock({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return BentoCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}
