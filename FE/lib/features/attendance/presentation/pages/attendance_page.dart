import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/providers/auth_viewmodel.dart';
import '../providers/attendance_providers.dart';
import '../widgets/attendance_history_panel.dart';
import '../widgets/attendance_self_card.dart';
import '../widgets/attendance_table.dart';

class AttendancePage extends ConsumerStatefulWidget {
  const AttendancePage({super.key});

  @override
  ConsumerState<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends ConsumerState<AttendancePage> {
  Timer? _clock;

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  Future<void> _refresh({
    required bool canSelfService,
    required bool canSeeTeam,
  }) async {
    if (canSelfService) {
      ref.invalidate(myAttendanceProvider);
      ref.invalidate(eligibleAttendanceTargetsProvider);
    }
    if (canSeeTeam) {
      ref.invalidate(teamAttendanceProvider);
    }
    await Future<void>.delayed(const Duration(milliseconds: 350));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final shellUsesAppBar =
        MediaQuery.sizeOf(context).width < AppSpacing.breakpointTablet;
    final user = ref.watch(activeUserProvider).valueOrNull;
    final role = user?.role;
    final canSelfService = role == 'STAFF' || role == 'MANAGER';
    final canManage = role == 'MANAGER' || role == 'ADMIN';
    final canSeeTeam = role == 'MANAGER' || role == 'ADMIN';

    return Scaffold(
      appBar: shellUsesAppBar ? null : AppBar(title: Text(l10n.attendance)),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= AppSpacing.breakpointTablet;
          final horizontalPadding = switch (constraints.maxWidth) {
            >= AppSpacing.breakpointDesktop => AppSpacing.screenPaddingDesktop,
            >= AppSpacing.breakpointMobile => AppSpacing.screenPaddingTablet,
            _ => AppSpacing.screenPaddingMobile,
          };
          final now = DateTime.now();
          final locale = Localizations.localeOf(context).toLanguageTag();
          final dayText = DateFormat('EEEE, dd/MM/yyyy', locale).format(now);
          final timeText = DateFormat('HH:mm').format(now);

          return RefreshIndicator(
            onRefresh: () => _refresh(
              canSelfService: canSelfService,
              canSeeTeam: canSeeTeam,
            ),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                AppSpacing.xl,
                horizontalPadding,
                AppSpacing.xxxl,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1320),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _PageHeader(
                        title: l10n.attendanceSubtitle,
                        date: dayText,
                        time: timeText,
                        isDesktop: isDesktop,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      if (canSelfService)
                        if (isDesktop)
                          const Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 7,
                                child: AttendanceSelfCard(),
                              ),
                              SizedBox(width: AppSpacing.lg),
                              Expanded(
                                flex: 5,
                                child: AttendanceHistoryPanel(),
                              ),
                            ],
                          )
                        else
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              AttendanceSelfCard(),
                              SizedBox(height: AppSpacing.base),
                              AttendanceHistoryPanel(compact: true),
                            ],
                          ),
                      if (canSelfService && canSeeTeam)
                        const SizedBox(height: AppSpacing.xxl),
                      if (canSeeTeam) ...[
                        Row(
                          children: [
                            Icon(
                              Icons.groups_2_outlined,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              l10n.attendanceTeamTitle,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        SizedBox(
                          height: isDesktop ? 620 : 580,
                          child: AttendanceTable(canManage: canManage),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({
    required this.title,
    required this.date,
    required this.time,
    required this.isDesktop,
  });

  final String title;
  final String date;
  final String time;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final clock = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 18,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            date,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          Container(
            width: 1,
            height: 18,
            margin: const EdgeInsets.symmetric(horizontal: 10),
            color: theme.colorScheme.outlineVariant,
          ),
          Text(
            time,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );

    if (!isDesktop) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: clock,
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 24),
        clock,
      ],
    );
  }
}
