import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/bento_card.dart';
import '../../../analytics/presentation/widgets/trend_line_chart.dart';
import '../../../campaign/dashboard/widgets/outcome_donut_chart.dart';
import '../../../campaign/dashboard/widgets/province_bar_chart.dart';
import '../../../campaign/dashboard/widgets/top_schools_bar_chart.dart';
import '../../data/providers/manager_home_provider.dart';
import '../widgets/home_page_shell.dart';

class ManagerHomePage extends ConsumerWidget {
  const ManagerHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeData = ref.watch(managerHomeProvider);

    return homeData.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _ErrorView(
        error: error,
        onRetry: () => ref.invalidate(managerHomeProvider),
      ),
      data: (model) => Scaffold(
        body: HomePageShell(
          title: 'Bảng điều khiển',
          subtitle: 'Tổng quan hoạt động chiến dịch',
          badge: HomeBadge(
            label: '${model.totalCampaigns} chiến dịch đang hoạt động',
            color: AppColors.primary,
            icon: Icons.campaign,
          ),
          actions: [
            HomeAction(
              label: 'Tạo chiến dịch',
              icon: Icons.add,
              isPrimary: true,
              onPressed: () => context.go('/campaigns'),
            ),
            HomeAction(
              label: 'Xem Analytics',
              icon: Icons.analytics_outlined,
              onPressed: () => context.go('/analytics'),
            ),
            HomeAction(
              label: 'Xem bản đồ',
              icon: Icons.map_outlined,
              onPressed: () => context.go('/map'),
            ),
          ],
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.base),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _KpiRow(model: model),
                const SizedBox(height: AppSpacing.base),
                _HomeGridRow(
                  spans: const [8, 4],
                  children: [
                    _TrendCard(trend: model.trend),
                    _ActivityFeedCard(),
                  ],
                ),
                const SizedBox(height: AppSpacing.base),
                _HomeGridRow(
                  spans: const [6, 6],
                  children: [
                    _OutcomeCard(outcomes: model.interactionsByOutcome),
                    _ProvinceCard(provinces: model.interactionsByProvince),
                  ],
                ),
                const SizedBox(height: AppSpacing.base),
                _HomeGridRow(
                  spans: const [8, 4],
                  children: [
                    _TopSchoolsCard(schools: model.topSchools),
                    _QuickLinksCard(),
                  ],
                ),
                const SizedBox(height: AppSpacing.base),
                _RecentRegistrationsCard(registrations: model.recentRegistrations),
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
  final ManagerHomeModel model;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        final cardWidth = isWide
            ? (constraints.maxWidth - AppSpacing.bentoGap * 3) / 4
            : (constraints.maxWidth - AppSpacing.bentoGap) / 2;
        return Wrap(
          spacing: AppSpacing.bentoGap,
          runSpacing: AppSpacing.bentoGap,
          children: [
            KpiCard(
              title: 'Chiến dịch',
              value: '${model.totalCampaigns}',
              icon: Icons.campaign_outlined,
              accentColor: AppColors.primary,
              subtitle: 'Tổng số',
            ),
            KpiCard(
              title: 'Sự kiện',
              value: '${model.totalEvents}',
              icon: Icons.event_outlined,
              accentColor: AppColors.chartColors[1],
              subtitle: 'Tổng số',
            ),
            KpiCard(
              title: 'Tương tác',
              value: '${model.totalInteractions}',
              icon: Icons.chat_outlined,
              accentColor: AppColors.chartColors[2],
              subtitle: 'Tất cả thời gian',
              trend: '+12%',
              trendUp: true,
            ),
            KpiCard(
              title: 'Trường học',
              value: '${model.totalSchools}',
              icon: Icons.school_outlined,
              accentColor: AppColors.chartColors[3],
              subtitle: 'Đã tham gia',
            ),
          ].map((k) => SizedBox(width: cardWidth, child: k)).toList(),
        );
      },
    );
  }
}

class _TrendCard extends StatelessWidget {
  const _TrendCard({required this.trend});
  final List<dynamic> trend;

  @override
  Widget build(BuildContext context) {
    return BentoCard(
      size: BentoSize.wide,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up, size: 20, color: AppColors.chartColors[0]),
              const SizedBox(width: 8),
              Text(
                'Xu hướng tương tác (30 ngày)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: TrendLineChart(points: trend.cast()),
          ),
        ],
      ),
    );
  }
}

class _ActivityFeedCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activities = [
      ('5 phút trước', 'Nguyễn Văn A ghi nhận tương tác tại Hà Nội', Icons.chat),
      ('12 phút trước', 'Trần Thị B thêm sự kiện mới', Icons.event),
      ('1 giờ trước', 'Lê Văn C duyệt 3 đăng ký', Icons.check_circle),
      ('2 giờ trước', 'Phạm Thị D cập nhật trường học', Icons.school),
    ];

    return BentoCard(
      size: BentoSize.large,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.notifications_outlined, size: 20, color: AppColors.chartColors[4]),
              const SizedBox(width: 8),
              Text(
                'Hoạt động gần đây',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              itemCount: activities.length,
              separatorBuilder: (_, __) => const Divider(height: 16),
              itemBuilder: (context, index) {
                final (time, text, icon) = activities[index];
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.chartColors[4].withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(icon, size: 14, color: AppColors.chartColors[4]),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            text,
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            time,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isDark
                                  ? AppColors.textTertiaryDark
                                  : AppColors.textTertiaryLight,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _OutcomeCard extends StatelessWidget {
  const _OutcomeCard({required this.outcomes});
  final Map<String, int> outcomes;

  @override
  Widget build(BuildContext context) {
    return BentoCard(
      size: BentoSize.large,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kết quả tương tác',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: OutcomeDonutChart(outcomes: outcomes),
          ),
        ],
      ),
    );
  }
}

class _ProvinceCard extends StatelessWidget {
  const _ProvinceCard({required this.provinces});
  final List<dynamic> provinces;

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
            height: 200,
            child: ProvinceBarChart(items: provinces.cast()),
          ),
        ],
      ),
    );
  }
}

class _TopSchoolsCard extends StatelessWidget {
  const _TopSchoolsCard({required this.schools});
  final List<dynamic> schools;

  @override
  Widget build(BuildContext context) {
    return BentoCard(
      size: BentoSize.wide,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Top trường học',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => context.go('/schools'),
                child: const Text('Xem tất cả'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: TopSchoolsBarChart(items: schools.cast()),
          ),
        ],
      ),
    );
  }
}

class _QuickLinksCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BentoCard(
      size: BentoSize.large,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Liên kết nhanh',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _QuickLink(
            icon: Icons.campaign,
            label: 'Quản lý chiến dịch',
            onTap: () => context.go('/campaigns'),
          ),
          _QuickLink(
            icon: Icons.analytics,
            label: 'Phân tích chi tiết',
            onTap: () => context.go('/analytics'),
          ),
          _QuickLink(
            icon: Icons.school,
            label: 'Danh sách trường',
            onTap: () => context.go('/schools'),
          ),
          _QuickLink(
            icon: Icons.admin_panel_settings,
            label: 'Quản trị người dùng',
            onTap: () => context.go('/admin/users'),
          ),
        ],
      ),
    );
  }
}

class _QuickLink extends StatelessWidget {
  const _QuickLink({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(child: Text(label)),
            const Icon(Icons.chevron_right, size: 18),
          ],
        ),
      ),
    );
  }
}

class _RecentRegistrationsCard extends ConsumerWidget {
  const _RecentRegistrationsCard({required this.registrations});
  final List<dynamic> registrations;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BentoCard(
      size: BentoSize.xl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Đăng ký gần đây',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          if (registrations.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'Chưa có đăng ký nào',
                  style: TextStyle(
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
              ),
            )
          else
            SizedBox(
              height: 200,
              child: ListView.separated(
                itemCount: registrations.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final r = registrations[index];
                  final studentName = r.student?.fullName ?? 'N/A';
                  final schoolName = r.school?.schoolName ?? 'N/A';
                  final createdAt = r.createdAt != null
                      ? DateFormat('d/M/yyyy').format(r.createdAt!)
                      : 'N/A';
                  return ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      child: Text(
                        studentName.isNotEmpty ? studentName[0].toUpperCase() : '?',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    title: Text(studentName, style: const TextStyle(fontSize: 14)),
                    subtitle: Text(
                      '$schoolName · $createdAt',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                    trailing: StatusChip(
                      label: r.status,
                      status: _statusType(r.status),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  StatusType _statusType(String status) {
    return switch (status.toUpperCase()) {
      'APPROVED' => StatusType.active,
      'REJECTED' => StatusType.error,
      'PENDING' => StatusType.pending,
      _ => StatusType.draft,
    };
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
            Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text('Không thể tải dữ liệu', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 13),
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
