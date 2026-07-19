import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/bento_card.dart';
import '../../../auth/shared/providers/auth_provider.dart';
import '../../../campaign/dashboard/widgets/outcome_donut_chart.dart';
import '../../data/providers/staff_home_provider.dart';
import '../widgets/home_page_shell.dart';

class StaffHomePage extends ConsumerWidget {
  const StaffHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeData = ref.watch(staffHomeProvider);
    final user = ref.watch(activeUserProvider).valueOrNull;

    return homeData.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _ErrorView(
        error: error,
        onRetry: () => ref.invalidate(staffHomeProvider),
      ),
      data: (model) => Scaffold(
        body: HomePageShell(
          title: 'Tổng quan',
          subtitle: 'Chào buổi sáng, ${user?.email ?? 'Nhân viên'}!',
          actions: [
            HomeAction(
              label: 'Xem sự kiện',
              icon: Icons.event_outlined,
              onPressed: () => context.go('/campaigns'),
            ),
            HomeAction(
              label: 'Xem bản đồ',
              icon: Icons.map_outlined,
              onPressed: () => context.go('/map'),
            ),
          ],
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.base),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _KpiRow(model: model),
                const SizedBox(height: AppSpacing.base),
                _HomeGridRow(
                  spans: const [8, 4],
                  children: [
                    _AssignedEventsCard(events: model.assignedEvents),
                    _PersonalTrendCard(interactions: model.interactionsLogged),
                  ],
                ),
                const SizedBox(height: AppSpacing.base),
                _HomeGridRow(
                  spans: const [6, 6],
                  children: [
                    _CampaignBreakdownCard(),
                    _PersonalOutcomeCard(),
                  ],
                ),
                const SizedBox(height: AppSpacing.base),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeGridRow extends StatelessWidget {
  const _HomeGridRow({required this.spans, required this.children});
  final List<int> spans;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (int i = 0; i < children.length; i++) ...[
                if (i > 0) const SizedBox(height: AppSpacing.bentoGap),
                children[i],
              ],
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int i = 0; i < children.length; i++) ...[
              if (i > 0) const SizedBox(width: AppSpacing.bentoGap),
              Expanded(flex: spans[i], child: children[i]),
            ],
          ],
        );
      },
    );
  }
}

class _KpiRow extends StatelessWidget {
  const _KpiRow({required this.model});
  final StaffHomeModel model;
  @override
  Widget build(BuildContext context) => HomeKpiGrid(desktopColumns: 3, children: [
    KpiCard(title: 'Sự kiện đã tham gia', value: '${model.eventsJoined}', icon: Icons.event_outlined, accentColor: AppColors.primary, subtitle: 'Tổng số sự kiện'),
    KpiCard(title: 'Tương tác đã ghi nhận', value: '${model.interactionsLogged}', icon: Icons.chat_outlined, accentColor: AppColors.chartColors[3], subtitle: 'Tương tác', trend: '+8%'),
    KpiCard(title: 'Trường đã thăm', value: '${model.schoolsVisited}', icon: Icons.school_outlined, accentColor: AppColors.success, subtitle: 'Trường học'),
  ]);
}

class _AssignedEventsCard extends StatelessWidget {
  const _AssignedEventsCard({required this.events});
  final List<dynamic> events;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BentoCard(
      size: BentoSize.wide,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.event, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Sự kiện được phân công',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            child: events.isEmpty
                ? Center(
                    child: Text(
                      'Không có sự kiện nào được phân công',
                      style: TextStyle(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: events.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final e = events[index];
                      final date = _formatDate(e.startsAt);
                      final day = date.split('/').first;
                      final month = date.split('/').skip(1).first;
                      return ListTile(
                        dense: true,
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                day,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppColors.primary,
                                ),
                              ),
                              Text(
                                month,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        title: Text(
                          e.name ?? 'N/A',
                          style: const TextStyle(fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          e.eventType ?? 'N/A',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                        trailing: StatusChip(
                          label: e.status ?? 'ACTIVE',
                          status: _eventStatus(e.status),
                        ),
                        onTap: () => context.go('/events/${e.id}'),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? iso) {
    if (iso == null) return 'N/A';
    try {
      return DateFormat('d/M').format(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
  }

  StatusType _eventStatus(String? status) {
    return switch (status?.toUpperCase()) {
      'ACTIVE' || 'ONGOING' => StatusType.active,
      'COMPLETED' || 'FINISHED' => StatusType.done,
      'PLANNED' || 'UPCOMING' => StatusType.pending,
      _ => StatusType.draft,
    };
  }
}

class _PersonalTrendCard extends StatelessWidget {
  const _PersonalTrendCard({required this.interactions});
  final int interactions;

  @override
  Widget build(BuildContext context) {
    return BentoCard(
      size: BentoSize.large,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up,
                  size: 20, color: AppColors.chartColors[0]),
              const SizedBox(width: 8),
              Text(
                'Xu hướng cá nhân (7 ngày)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(height: 180, child: _PersonalTrendBars()),
        ],
      ),
    );
  }
}

class _PersonalTrendBars extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final days = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    final values = [12, 8, 15, 6, 20, 10, 4];
    final maxVal = values.reduce((a, b) => a > b ? a : b);

    return Column(
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(7, (i) {
              final ratio = values[i] / maxVal;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: FractionallySizedBox(
                    heightFactor: ratio.clamp(0.05, 1.0),
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      decoration: BoxDecoration(
                        color: i == 4
                            ? AppColors.primary
                            : AppColors.primary.withValues(alpha: 0.3),
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4)),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: days
              .map((d) => Expanded(
                    child: Text(
                      d,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark
                            ? AppColors.textTertiaryDark
                            : AppColors.textTertiaryLight,
                      ),
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

class _CampaignBreakdownCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final campaigns = <({String name, int count, Color color})>[
      (
        name: 'Chiến dịch mùa xuân 2026',
        count: 45,
        color: AppColors.chartColors[0]
      ),
      (name: 'Chiến dịch hè 2026', count: 28, color: AppColors.chartColors[1]),
      (
        name: 'Chiến dịch QTBD 2026',
        count: 14,
        color: AppColors.chartColors[2]
      ),
    ];
    final total = campaigns.fold<int>(0, (s, c) => s + c.count);

    return BentoCard(
      size: BentoSize.large,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Phân bổ theo chiến dịch',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 160,
            child: SingleChildScrollView(
              child: Column(
                children: campaigns.map((c) {
                  final pct = total > 0 ? c.count / total : 0.0;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                c.name,
                                style: const TextStyle(fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '${c.count} tương tác',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: pct,
                          backgroundColor: c.color.withValues(alpha: 0.15),
                          valueColor: AlwaysStoppedAnimation(c.color),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PersonalOutcomeCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const outcomes = <String, int>{
      'THÀNH CÔNG': 45,
      'CẦN THEO DÕI': 20,
      'TỪ CHỐI': 8,
    };

    return BentoCard(
      size: BentoSize.large,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kết quả cá nhân',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          const SizedBox(
            height: 200,
            child: OutcomeDonutChart(outcomes: outcomes),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});
  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                size: 48, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text('Không thể tải dữ liệu',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.error, fontSize: 13),
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