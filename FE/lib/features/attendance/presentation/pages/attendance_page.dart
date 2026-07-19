import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/providers/auth_viewmodel.dart';
import '../widgets/attendance_self_card.dart';
import '../widgets/attendance_table.dart';

class AttendancePage extends ConsumerWidget {
  const AttendancePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(activeUserProvider).valueOrNull;
    final role = user?.role;

    final canSelfService = role == 'STAFF' || role == 'MANAGER';
    final canManage = role == 'MANAGER' || role == 'ADMIN';
    final canSeeTeam = role == 'MANAGER' || role == 'ADMIN';

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.attendance),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 800;

          if (isWide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (canSelfService)
                  const SizedBox(
                    width: 400,
                    child: SingleChildScrollView(
                      child: AttendanceSelfCard(),
                    ),
                  ),
                if (canSeeTeam)
                  Expanded(
                    child: AttendanceTable(canManage: canManage),
                  ),
              ],
            );
          }

          // Mobile view
          return CustomScrollView(
            slivers: [
              if (canSelfService)
                const SliverToBoxAdapter(
                  child: AttendanceSelfCard(),
                ),
              if (canSeeTeam)
                SliverFillRemaining(
                  child: AttendanceTable(canManage: canManage),
                ),
            ],
          );
        },
      ),
    );
  }
}
