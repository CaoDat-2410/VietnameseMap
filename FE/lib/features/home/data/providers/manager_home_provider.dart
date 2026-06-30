import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../analytics/domain/models/analytics_models.dart';
import '../../../analytics/presentation/providers/analytics_provider.dart';
import '../../../campaign/shared/models/campaign_models.dart';
import '../../../campaign/shared/providers/campaign_provider.dart';

/// Home data for the Manager role — aggregates cross-campaign data.
class ManagerHomeModel {
  const ManagerHomeModel({
    required this.totalCampaigns,
    required this.totalEvents,
    required this.totalInteractions,
    required this.totalSchools,
    required this.totalEmployees,
    required this.interactionsByOutcome,
    required this.interactionsByProvince,
    required this.topSchools,
    required this.trend,
    required this.recentRegistrations,
  });

  final int totalCampaigns;
  final int totalEvents;
  final int totalInteractions;
  final int totalSchools;
  final int totalEmployees;
  final Map<String, int> interactionsByOutcome;
  final List<ProvinceInteractionModel> interactionsByProvince;
  final List<TopSchoolModel> topSchools;
  final List<TrendPointModel> trend;
  final List<StudentRegistrationModel> recentRegistrations;

  int get activeCampaigns => 0; // computed from campaigns if needed
}

/// Combines aggregate dashboard + trend + registrations for manager home.
final managerHomeProvider = FutureProvider<ManagerHomeModel>((ref) async {
  final filter = const AnalyticsFilter();

  final aggregate = await ref.watch(aggregateDashboardProvider(filter).future);
  final trend = await ref.watch(trendProvider(filter).future);
  final campaigns = await ref.watch(campaignsProvider.future);

  // Fetch registrations for all campaigns (up to 5 most recent)
  final registrations = <StudentRegistrationModel>[];
  for (final c in campaigns.take(5)) {
    try {
      final regList = await ref
          .watch(campaignRegistrationsProvider(c.id).future);
      registrations.addAll(regList.take(5));
    } catch (_) {
      // skip campaigns that fail
    }
  }

  // Sort by createdAt desc (createdAt is a String ISO date)
  registrations.sort((a, b) {
    int ts(String? s) {
      if (s == null) return 0;
      try { return DateTime.parse(s).millisecondsSinceEpoch; }
      catch (_) { return 0; }
    }
    return ts(b.createdAt).compareTo(ts(a.createdAt));
  });

  return ManagerHomeModel(
    totalCampaigns: aggregate.totalCampaigns,
    totalEvents: aggregate.totalEvents,
    totalInteractions: aggregate.totalInteractions,
    totalSchools: aggregate.totalSchools,
    totalEmployees: aggregate.totalEmployees,
    interactionsByOutcome: aggregate.interactionsByOutcome,
    interactionsByProvince: aggregate.interactionsByProvince,
    topSchools: aggregate.topSchools,
    trend: trend,
    recentRegistrations: registrations.take(10).toList(),
  );
});
