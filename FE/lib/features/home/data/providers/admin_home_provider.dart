import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../analytics/presentation/providers/analytics_provider.dart';
import '../../../campaign/shared/providers/campaign_provider.dart';

/// System health status for admin monitoring panel.
enum SystemHealthStatus {
  healthy,
  warning,
  error,
}

/// Home data for the Admin role.
class AdminHomeModel {
  const AdminHomeModel({
    required this.totalUsers,
    required this.totalCampaigns,
    required this.totalEvents,
    required this.totalSchools,
    required this.totalInteractions,
    required this.pendingActivations,
    required this.usersByRole,
    required this.systemHealth,
  });

  final int totalUsers;
  final int totalCampaigns;
  final int totalEvents;
  final int totalSchools;
  final int totalInteractions;
  final int pendingActivations;
  final Map<String, int> usersByRole;
  final Map<String, SystemHealthStatus> systemHealth;
}

/// Admin home — combines existing data sources + mock system health.
final adminHomeProvider = FutureProvider<AdminHomeModel>((ref) async {
  // Fetch users list (raw maps)
  final users = await ref.watch(usersProvider.future);

  // Count by role
  final roleCounts = <String, int>{};
  int pendingCount = 0;
  for (final u in users) {
    final role = (u['role'] as String?) ?? 'UNKNOWN';
    roleCounts[role] = (roleCounts[role] ?? 0) + 1;
    final status = (u['status'] as String?) ?? '';
    if (status.toUpperCase() == 'PENDING') pendingCount++;
  }

  // Aggregate dashboard
  final filter = const AnalyticsFilter();
  final aggregate = await ref.watch(aggregateDashboardProvider(filter).future);

  // NOTE: System health is mocked until backend provides
  //   GET /api/v1/admin/system-stats
  const systemHealth = <String, SystemHealthStatus>{
    'Backend API': SystemHealthStatus.healthy,
    'Database': SystemHealthStatus.healthy,
    'Redis Cache': SystemHealthStatus.healthy,
    'Weather API': SystemHealthStatus.warning,
  };

  return AdminHomeModel(
    totalUsers: users.length,
    totalCampaigns: aggregate.totalCampaigns,
    totalEvents: aggregate.totalEvents,
    totalSchools: aggregate.totalSchools,
    totalInteractions: aggregate.totalInteractions,
    pendingActivations: pendingCount,
    usersByRole: roleCounts,
    systemHealth: systemHealth,
  );
});
