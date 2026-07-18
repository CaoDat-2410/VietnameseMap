import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/bento_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/shared/providers/auth_provider.dart';
import '../../data/providers/student_home_provider.dart';
import '../widgets/home_page_shell.dart';

class StudentHomePage extends ConsumerWidget {
  const StudentHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final homeData = ref.watch(studentHomeProvider);
    final user = ref.watch(activeUserProvider).valueOrNull;
    final campaigns = ref.watch(availableCampaignsProvider);

    return homeData.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _ErrorView(
        error: error,
        onRetry: () => ref.invalidate(studentHomeProvider),
      ),
      data: (model) {
        return Scaffold(
          body: HomePageShell(
            title: 'Xin chào, ${user?.email ?? 'Sinh viên'}!',
            subtitle: 'Theo dõi hoạt động đăng ký của bạn',
            actions: [
              HomeAction(
                label: l10n.registerForEvent,
                icon: Icons.add,
                isPrimary: true,
                onPressed: () => context.go('/campaigns'),
              ),
              HomeAction(
                label: l10n.schools,
                icon: Icons.school_outlined,
                onPressed: () => context.go('/schools'),
              ),
              HomeAction(
                label: l10n.myRegistrations,
                icon: Icons.assignment_ind_outlined,
                onPressed: () => context.go('/student/my-registrations'),
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
                      _RegistrationsCard(registrations: model.registrations),
                      _ProfileCard(user: user),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.base),
                  campaigns.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (list) => list.isEmpty
                        ? const SizedBox.shrink()
                        : _CampaignsCard(campaigns: list),
                  ),
                  const SizedBox(height: AppSpacing.base),
                ],
              ),
            ),
          ),
        );
      },
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
  final StudentHomeModel model;
  @override
  Widget build(BuildContext context) => HomeKpiGrid(desktopColumns: 2, children: [
    KpiCard(title: 'Đăng ký của tôi', value: '${model.registrations.length}', icon: Icons.assignment_ind_outlined, accentColor: AppColors.primary, subtitle: 'Tổng số đăng ký'),
    KpiCard(title: 'Đã duyệt', value: '${model.approvedCount}', icon: Icons.check_circle_outline, accentColor: AppColors.success, subtitle: 'Được chấp nhận', trend: '${model.pendingCount} đang chờ', trendUp: false),
  ]);
}

class _RegistrationsCard extends StatelessWidget {
  const _RegistrationsCard({required this.registrations});
  final List<dynamic> registrations;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BentoCard(
      size: BentoSize.wide,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Đăng ký của tôi',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => context.go('/student/my-registrations'),
                child: const Text('Xem tất cả'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 220,
            child: registrations.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.assignment_outlined,
                          size: 48,
                          color: isDark
                              ? AppColors.textTertiaryDark
                              : AppColors.textTertiaryLight,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Bạn chưa đăng ký chiến dịch nào',
                          style: TextStyle(
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: registrations.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final r = registrations[index];
                      final schoolName =
                          (r.school?.schoolName?.toString().isNotEmpty == true)
                              ? r.school.schoolName.toString()
                              : 'N/A';
                      final status = r.status?.toString() ?? 'PENDING';
                      final createdAt = _formatDate(r.createdAt);
                      return ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor:
                              AppColors.primary.withValues(alpha: 0.1),
                          child: const Icon(
                            Icons.school,
                            size: 16,
                            color: AppColors.primary,
                          ),
                        ),
                        title: Text(schoolName,
                            style: const TextStyle(fontSize: 14)),
                        subtitle: Text(
                          'Ngày đăng ký: $createdAt',
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
                  ),
          ),
        ],
      ),
    );
  }

  String _formatDate(Object? value) {
    if (value == null) return 'N/A';
    if (value is DateTime) return DateFormat('d/M/yyyy').format(value);
    final raw = value.toString();
    if (raw.isEmpty) return 'N/A';
    try {
      return DateFormat('d/M/yyyy').format(DateTime.parse(raw).toLocal());
    } catch (_) {
      return raw.length > 10 ? raw.substring(0, 10) : raw;
    }
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

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.user});
  final dynamic user;

  @override
  Widget build(BuildContext context) {
    return BentoCard(
      size: BentoSize.large,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hồ sơ',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 16),
          Center(
            child: CircleAvatar(
              radius: 32,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              child: Text(
                _avatarInitial(user?.email),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              user?.email ?? 'N/A',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: StatusChip(
              label: user?.role ?? 'STUDENT',
              status: StatusType.done,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          _InfoRow(icon: Icons.email_outlined, label: user?.email ?? 'N/A'),
          _InfoRow(
            icon: Icons.badge_outlined,
            label: 'ID: ${user?.id ?? 'N/A'}',
          ),
          _InfoRow(
            icon: Icons.assignment_ind,
            label: 'Vai trò: ${user?.role ?? 'STUDENT'}',
          ),
        ],
      ),
    );
  }
}

  String _avatarInitial(Object? email) {
    final value = email?.toString().trim() ?? '';
    return value.isEmpty ? 'S' : value[0].toUpperCase();
  }
class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _CampaignsCard extends StatelessWidget {
  const _CampaignsCard({required this.campaigns});
  final List<dynamic> campaigns;

  @override
  Widget build(BuildContext context) {
    return BentoCard(
      size: BentoSize.xl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chiến dịch đang tuyển',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 140,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: campaigns.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final c = campaigns[index];
                return SizedBox(
                  width: 240,
                  child: Card(
                    child: InkWell(
                      onTap: () => context.go('/campaigns/${c.id}'),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    c.name ?? 'N/A',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                StatusChip(
                                  label: c.status ?? 'ACTIVE',
                                  status: StatusType.active,
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              c.objective?.isNotEmpty == true
                                  ? c.objective
                                  : 'Không có mô tả',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Spacer(),
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 12,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${c.startDate ?? ''} - ${c.endDate ?? ''}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
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