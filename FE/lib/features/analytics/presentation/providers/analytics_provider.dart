import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/analytics_repository.dart';
import '../../domain/models/analytics_models.dart';
import '../../../campaign/shared/models/campaign_models.dart';
import '../../../map/presentation/providers/map_provider.dart'
    show dioClientProvider;

final analyticsRepositoryProvider = Provider<AnalyticsRepository>(
  (ref) => AnalyticsRepository(ref.watch(dioClientProvider)),
);

// Filter state
enum AnalyticsFilterType { none, campaign, school }

final selectedFilterTypeProvider = StateProvider<AnalyticsFilterType>(
  (ref) => AnalyticsFilterType.none,
);

final selectedCampaignIdProvider = StateProvider<int?>((ref) => null);
final selectedCampaignNameProvider = StateProvider<String?>((ref) => null);
final selectedSchoolUidProvider = StateProvider<String?>((ref) => null);
final selectedSchoolNameProvider = StateProvider<String?>((ref) => null);

/// Immutable record describing the currently-active analytics filter.
/// Used as the family key so the provider auto-rebuilds when any field changes.
@immutable
class AnalyticsFilter {
  const AnalyticsFilter({this.campaignId, this.schoolUid});
  final int? campaignId;
  final String? schoolUid;

  static const empty = AnalyticsFilter();

  @override
  bool operator ==(Object other) =>
      other is AnalyticsFilter &&
      other.campaignId == campaignId &&
      other.schoolUid == schoolUid;

  @override
  int get hashCode => Object.hash(campaignId, schoolUid);
}

/// Combines the currently-selected filter state into a single record so any
/// downstream provider can `ref.watch(analyticsFilterProvider)` and re-fetch
/// automatically when the filter changes.
final analyticsFilterProvider = Provider<AnalyticsFilter>((ref) {
  final filterType = ref.watch(selectedFilterTypeProvider);
  final campaignId = ref.watch(selectedCampaignIdProvider);
  final schoolUid = ref.watch(selectedSchoolUidProvider);

  return switch (filterType) {
    AnalyticsFilterType.campaign => AnalyticsFilter(campaignId: campaignId),
    AnalyticsFilterType.school => AnalyticsFilter(schoolUid: schoolUid),
    AnalyticsFilterType.none => AnalyticsFilter.empty,
  };
});

// Data providers
final aggregateDashboardProvider =
    FutureProvider.family<AggregateDashboardModel, AnalyticsFilter>(
        (ref, filter) async {
  return ref.watch(analyticsRepositoryProvider).getAggregateDashboard(
        campaignId: filter.campaignId,
        schoolUid: filter.schoolUid,
      );
});

final trendProvider =
    FutureProvider.family<List<TrendPointModel>, AnalyticsFilter>(
        (ref, filter) async {
  return ref.watch(analyticsRepositoryProvider).getInteractionsTrend(
        campaignId: filter.campaignId,
        schoolUid: filter.schoolUid,
      );
});

final channelProvider =
    FutureProvider.family<List<ChannelBreakdownModel>, AnalyticsFilter>(
        (ref, filter) async {
  return ref.watch(analyticsRepositoryProvider).getChannelBreakdown(
        campaignId: filter.campaignId,
        schoolUid: filter.schoolUid,
      );
});

final employeeProvider =
    FutureProvider.family<List<EmployeeRankingModel>, AnalyticsFilter>(
        (ref, filter) async {
  return ref.watch(analyticsRepositoryProvider).getTopEmployees(
        campaignId: filter.campaignId,
        schoolUid: filter.schoolUid,
      );
});

final campaignsListProvider = FutureProvider<List<CampaignModel>>((ref) async {
  return ref.watch(analyticsRepositoryProvider).getCampaigns();
});

final schoolsListProvider = FutureProvider<List<SchoolSummary>>((ref) async {
  final page = await ref.watch(analyticsRepositoryProvider).getSchools();
  return page.items;
});

// Filtered campaign data (single-campaign dashboard ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â used elsewhere)
final filteredCampaignDashboardProvider =
    FutureProvider.family<FilteredDashboardData?, ({int id, String name})>(
        (ref, params) async {
  return ref
      .watch(analyticsRepositoryProvider)
      .getCampaignDashboard(params.id, params.name);
});
