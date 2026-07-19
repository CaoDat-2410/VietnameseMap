import '../../../../core/network/dio_client.dart';
import '../../domain/models/analytics_models.dart';
import '../../../campaign/shared/models/campaign_models.dart';

class AnalyticsRepository {
  AnalyticsRepository(this._client);
  final DioClient _client;

  Future<AggregateDashboardModel> getAggregateDashboard({
    int? campaignId,
    String? schoolUid,
  }) async {
    final queryParams = <String, dynamic>{};
    if (campaignId != null) queryParams['campaignId'] = campaignId;
    if (schoolUid != null && schoolUid.isNotEmpty) {
      queryParams['schoolUid'] = schoolUid;
    }
    final response = await _client.get(
      '/api/analytics/aggregate',
      queryParameters: queryParams.isEmpty ? null : queryParams,
    );
    final data = response.data['data'] as Map<String, dynamic>? ?? {};
    return AggregateDashboardModel.fromJson(data);
  }

  Future<List<TrendPointModel>> getInteractionsTrend({
    int days = 30,
    int? campaignId,
    String? schoolUid,
  }) async {
    final queryParams = <String, dynamic>{'days': days};
    if (campaignId != null) queryParams['campaignId'] = campaignId;
    if (schoolUid != null && schoolUid.isNotEmpty) {
      queryParams['schoolUid'] = schoolUid;
    }
    final response = await _client.get(
      '/api/analytics/trend',
      queryParameters: queryParams,
    );
    final list = response.data['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => TrendPointModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ChannelBreakdownModel>> getChannelBreakdown({
    int? campaignId,
    String? schoolUid,
  }) async {
    final queryParams = <String, dynamic>{};
    if (campaignId != null) queryParams['campaignId'] = campaignId;
    if (schoolUid != null && schoolUid.isNotEmpty) {
      queryParams['schoolUid'] = schoolUid;
    }
    final response = await _client.get(
      '/api/analytics/channels',
      queryParameters: queryParams.isEmpty ? null : queryParams,
    );
    final list = response.data['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => ChannelBreakdownModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<EmployeeRankingModel>> getTopEmployees({
    int limit = 10,
    int? campaignId,
    String? schoolUid,
  }) async {
    final queryParams = <String, dynamic>{'limit': limit};
    if (campaignId != null) queryParams['campaignId'] = campaignId;
    if (schoolUid != null && schoolUid.isNotEmpty) {
      queryParams['schoolUid'] = schoolUid;
    }
    final response = await _client.get(
      '/api/analytics/employees',
      queryParameters: queryParams,
    );
    final list = response.data['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => EmployeeRankingModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<FilteredDashboardData> getCampaignDashboard(
      int campaignId, String name) async {
    final response =
        await _client.get('/api/v1/campaigns/$campaignId/dashboard');
    final data = response.data['data'] as Map<String, dynamic>? ?? {};
    return FilteredDashboardData.fromCampaignJson(campaignId, name, data);
  }

  Future<List<CampaignModel>> getCampaigns() async {
    final response = await _client.get('/api/v1/campaigns');
    final data = response.data['data'] as List<dynamic>? ?? [];
    return data
        .map((e) => CampaignModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<SchoolSummaryPage> getSchools({
    int page = 0,
    int limit = 50,
    String? query,
  }) async {
    final queryParameters = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    final trimmedQuery = query?.trim();
    if (trimmedQuery != null && trimmedQuery.isNotEmpty) {
      queryParameters['q'] = trimmedQuery;
    }

    final response = await _client.get(
      '/api/v1/schools',
      queryParameters: queryParameters,
    );
    final payload = response.data['data'];

    if (payload is Map<String, dynamic>) {
      final items = (payload['items'] as List<dynamic>? ?? [])
          .map((e) => SchoolSummary.fromJson(e as Map<String, dynamic>))
          .where((school) => school.uid.isNotEmpty && school.name.isNotEmpty)
          .toList();
      return SchoolSummaryPage(
        items: items,
        page: payload['page'] as int? ?? page,
        limit: payload['limit'] as int? ?? limit,
        totalItems: payload['totalItems'] as int? ?? items.length,
        totalPages: payload['totalPages'] as int? ?? 1,
      );
    }

    final items = switch (payload) {
      final List<dynamic> list => list,
      _ => const <dynamic>[],
    };
    final schools = items
        .map((e) => SchoolSummary.fromJson(e as Map<String, dynamic>))
        .where((school) => school.uid.isNotEmpty && school.name.isNotEmpty)
        .toList();
    return SchoolSummaryPage(
      items: schools,
      page: page,
      limit: limit,
      totalItems: schools.length,
      totalPages: schools.isEmpty ? 0 : 1,
    );
  }
}

class SchoolSummaryPage {
  const SchoolSummaryPage({
    required this.items,
    required this.page,
    required this.limit,
    required this.totalItems,
    required this.totalPages,
  });

  final List<SchoolSummary> items;
  final int page;
  final int limit;
  final int totalItems;
  final int totalPages;

  bool get hasMore => page + 1 < totalPages;
}

class SchoolSummary {
  const SchoolSummary({
    required this.uid,
    required this.name,
    this.provinceName,
  });

  final String uid;
  final String name;
  final String? provinceName;

  String get displayName => provinceName == null || provinceName!.isEmpty
      ? name
      : '$name - $provinceName';

  factory SchoolSummary.fromJson(Map<String, dynamic> json) {
    return SchoolSummary(
      uid: json['schoolUid'] as String? ?? json['uid'] as String? ?? '',
      name: json['schoolName'] as String? ?? json['name'] as String? ?? '',
      provinceName: json['provinceName'] as String?,
    );
  }
}
