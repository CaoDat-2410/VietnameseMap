import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/bento_card.dart';
import '../../../campaign/shared/providers/campaign_provider.dart';
import '../../data/providers/admin_home_provider.dart';
import '../widgets/home_page_shell.dart';

class AdminHomePage extends ConsumerWidget {
  const AdminHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeData = ref.watch(adminHomeProvider);

    return homeData.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _ErrorView(
        error: error,
        onRetry: () => ref.invalidate(adminHomeProvider),
      ),
      data: (model) => Scaffold(
        body: HomePageShell(
          title: 'Quản trị hệ thống',
          subtitle: 'Giám sát toàn bộ hệ thống',
          badge: model.pendingActivations > 0
              ? const HomeBadge(
                  label: 'cảnh báo',
                  color: AppColors.error,
                  icon: Icons.warning_amber,
                )
              : const HomeBadge(
                  label: 'Hệ thống hoạt động tốt',
                  color: AppColors.success,
                  icon: Icons.check_circle,
                ),
          actions: [
            HomeAction(
              label: 'Tạo người dùng',
              icon: Icons.person_add_outlined,
              isPrimary: true,
              onPressed: () => context.go('/admin/users'),
            ),
            HomeAction(
              label: 'Tạo chiến dịch',
              icon: Icons.campaign_outlined,
              onPressed: () => context.go('/campaigns'),
            ),
            HomeAction(
              label: 'Báo cáo hệ thống',
              icon: Icons.assessment_outlined,
              onPressed: () => context.go('/analytics'),
            ),
          ],
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.base),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _KpiGrid(model: model),
                const SizedBox(height: AppSpacing.base),
                _HomeGridRow(
                  spans: const [6, 6],
                  children: [
                    _UserRoleCard(
                      usersByRole: model.usersByRole,
                      total: model.totalUsers,
                    ),
                    _CampaignStatusCard(total: model.totalCampaigns),
                  ],
                ),
                const SizedBox(height: AppSpacing.base),
                _HomeGridRow(
                  spans: const [8, 4],
                  children: [
                    _RecentUsersCard(model: model),
                    _SystemHealthCard(health: model.systemHealth),
                  ],
                ),
                const SizedBox(height: AppSpacing.base),
                if (model.pendingActivations > 0)
                  _PendingActivationsCard(
                    pendingCount: model.pendingActivations,
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

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.model});
  final AdminHomeModel model;

  @override
  Widget build(BuildContext context) {
    final kpis = [
      ('Người dùng', model.totalUsers, Icons.people, AppColors.primary),
      ('Chiến dịch', model.totalCampaigns, Icons.campaign, AppColors.chartColors[1]),
      ('Sự kiện', model.totalEvents, Icons.event, AppColors.chartColors[3]),
      ('Trường học', model.totalSchools, Icons.school, AppColors.success),
      ('Tương tác', model.totalInteractions, Icons.chat, AppColors.warning),
      ('Chờ kích hoạt', model.pendingActivations, Icons.hourglass_empty, AppColors.error),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 900
            ? 6
            : constraints.maxWidth > 600
                ? 3
                : 2;
        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: AppSpacing.bentoGap,
          mainAxisSpacing: AppSpacing.bentoGap,
          childAspectRatio: columns >= 4 ? 1.4 : 1.6,
          children: kpis.map((k) {
            return KpiCard(
              title: k.$1,
              value: '${k.$2}',
              icon: k.$3,
              accentColor: k.$4,
              subtitle: '',
            );
          }).toList(),
        );
      },
    );
  }
}

class _UserRoleCard extends StatelessWidget {
  const _UserRoleCard({required this.usersByRole, required this.total});
  final Map<String, int> usersByRole;
  final int total;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final roles = [
      ('ADMIN', usersByRole['ADMIN'] ?? 0, AppColors.error),
      ('MANAGER', usersByRole['MANAGER'] ?? 0, AppColors.warning),
      ('STAFF', usersByRole['STAFF'] ?? 0, AppColors.info),
      ('STUDENT', usersByRole['STUDENT'] ?? 0, AppColors.success),
    ];

    return BentoCard(
      size: BentoSize.large,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.pie_chart_outline, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Phân bổ vai trò người dùng',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 120,
                        height: 120,
                        child: CircularProgressIndicator(
                          value: 1.0,
                          strokeWidth: 12,
                          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                          valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$total',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Tổng',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                ...roles.map((r) {
                  final pct = total > 0 ? r.$2 / total : 0.0;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: r.$3,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(r.$1, style: const TextStyle(fontSize: 12)),
                        const Spacer(),
                        Text(
                          '${r.$2}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                        const SizedBox(width: 4),
                        SizedBox(
                          width: 40,
                          child: LinearProgressIndicator(
                            value: pct,
                            backgroundColor: r.$3.withValues(alpha: 0.15),
                            valueColor: AlwaysStoppedAnimation(r.$3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CampaignStatusCard extends StatelessWidget {
  const _CampaignStatusCard({required this.total});
  final int total;

  @override
  Widget build(BuildContext context) {
    final statuses = [
      (name: 'Đang hoạt động', count: (total * 0.4).round(), color: AppColors.success),
      (name: 'Đã hoàn thành', count: (total * 0.3).round(), color: AppColors.info),
      (name: 'Sắp diễn ra', count: (total * 0.2).round(), color: AppColors.warning),
      (name: 'Đã hủy', count: (total * 0.1).round(), color: AppColors.error),
    ];

    return BentoCard(
      size: BentoSize.large,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trạng thái chiến dịch',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: statuses.map((s) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: s.color,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          s.name,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      Text(
                        '${s.count}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: s.color,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentUsersCard extends ConsumerWidget {
  const _RecentUsersCard({required this.model});
  final AdminHomeModel model;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(usersProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BentoCard(
      size: BentoSize.wide,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.people_outline, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Người dùng gần đây',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => context.go('/admin/users'),
                child: const Text('Quản lý'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: usersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => Center(
                child: Text(
                  'Không thể tải người dùng',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
              data: (users) {
                if (users.isEmpty) {
                  return Center(
                    child: Text(
                      'Chưa có người dùng',
                      style: TextStyle(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: users.length.clamp(0, 8),
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final u = users[index];
                    final name = (u['email'] as String?) ?? 'N/A';
                    final role = (u['role'] as String?) ?? 'UNKNOWN';
                    final status = (u['status'] as String?) ?? 'ACTIVE';
                    return ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor: _roleColor(role).withValues(alpha: 0.1),
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: TextStyle(
                            color: _roleColor(role),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      title: Text(name, style: const TextStyle(fontSize: 14)),
                      subtitle: Text(
                        role,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                      trailing: StatusChip(
                        label: status,
                        status: _statusType(status),
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

  Color _roleColor(String role) {
    return switch (role.toUpperCase()) {
      'ADMIN' => AppColors.error,
      'MANAGER' => AppColors.warning,
      'STAFF' => AppColors.info,
      'STUDENT' => AppColors.success,
      _ => AppColors.primary,
    };
  }

  StatusType _statusType(String status) {
    return switch (status.toUpperCase()) {
      'ACTIVE' => StatusType.active,
      'INACTIVE' => StatusType.draft,
      'PENDING' => StatusType.pending,
      _ => StatusType.draft,
    };
  }
}

class _SystemHealthCard extends StatelessWidget {
  const _SystemHealthCard({required this.health});
  final Map<String, SystemHealthStatus> health;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BentoCard(
      size: BentoSize.large,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.monitor_heart_outlined, size: 20, color: AppColors.success),
              const SizedBox(width: 8),
              Text(
                'Tình trạng hệ thống',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Column(
              children: health.entries.map((e) {
                final color = _healthColor(e.value);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: color.withValues(alpha: 0.4),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          e.key,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      Text(
                        _healthLabel(e.value),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const Divider(),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.access_time, size: 14, color: AppColors.textTertiaryLight),
              const SizedBox(width: 4),
              Text(
                'Cập nhật: ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark
                      ? AppColors.textTertiaryDark
                      : AppColors.textTertiaryLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _healthColor(SystemHealthStatus status) {
    return switch (status) {
      SystemHealthStatus.healthy => AppColors.success,
      SystemHealthStatus.warning => AppColors.warning,
      SystemHealthStatus.error => AppColors.error,
    };
  }

  String _healthLabel(SystemHealthStatus status) {
    return switch (status) {
      SystemHealthStatus.healthy => 'Tốt',
      SystemHealthStatus.warning => 'Cảnh báo',
      SystemHealthStatus.error => 'Lỗi',
    };
  }
}

class _PendingActivationsCard extends StatelessWidget {
  const _PendingActivationsCard({required this.pendingCount});
  final int pendingCount;

  @override
  Widget build(BuildContext context) {
    return BentoCard(
      size: BentoSize.xl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person_off_outlined, size: 20, color: AppColors.warning),
              const SizedBox(width: 8),
              Text(
                'Chờ kích hoạt ($pendingCount)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              FilledButton(
                onPressed: () => context.go('/admin/users'),
                child: const Text('Xử lý ngay'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Có $pendingCount tài khoản đang chờ được kích hoạt. Vui lòng xác minh và phê duyệt.',
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
              fontSize: 13,
            ),
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
