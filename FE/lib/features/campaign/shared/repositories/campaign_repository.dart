import '../../../../core/network/api_exception.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/dio_client.dart';
import '../models/campaign_models.dart';

class CampaignRepository {
  const CampaignRepository(this._client);

  final DioClient _client;

  Future<List<CampaignModel>> getCampaigns() async {
    final res = await _client.get<Map<String, dynamic>>('/api/v1/campaigns');
    final api = ApiResponse.fromJson(
      res.data!,
      (json) => (json as List<dynamic>)
          .map((e) => CampaignModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    _assertSuccess(api);
    return api.data!;
  }

  Future<CampaignModel> createCampaign(Map<String, dynamic> data) async {
    final res = await _client.post<Map<String, dynamic>>(
      '/api/v1/campaigns',
      data: data,
    );
    final api = ApiResponse.fromJson(
      res.data!,
      (json) => CampaignModel.fromJson(json as Map<String, dynamic>),
    );
    _assertSuccess(api);
    return api.data!;
  }

  Future<CampaignDashboardModel> getDashboard(int campaignId) async {
    final res = await _client.get<Map<String, dynamic>>(
      '/api/v1/campaigns/$campaignId/dashboard',
    );
    final api = ApiResponse.fromJson(
      res.data!,
      (json) => CampaignDashboardModel.fromJson(json as Map<String, dynamic>),
    );
    _assertSuccess(api);
    return api.data!;
  }

  Future<List<CampaignEventModel>> getEvents(int campaignId) async {
    final res = await _client.get<Map<String, dynamic>>(
      '/api/v1/campaigns/$campaignId/events',
    );
    final api = ApiResponse.fromJson(
      res.data!,
      (json) => (json as List<dynamic>)
          .map((e) => CampaignEventModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    _assertSuccess(api);
    return api.data!;
  }

  Future<CampaignEventModel> createEvent(
    int campaignId,
    Map<String, dynamic> data,
  ) async {
    final res = await _client.post<Map<String, dynamic>>(
      '/api/v1/campaigns/$campaignId/events',
      data: data,
    );
    final api = ApiResponse.fromJson(
      res.data!,
      (json) => CampaignEventModel.fromJson(json as Map<String, dynamic>),
    );
    _assertSuccess(api);
    return api.data!;
  }

  Future<void> assignSchool(int eventId, String schoolUid) async {
    await _client.post<Map<String, dynamic>>(
      '/api/v1/events/$eventId/schools',
      data: {'schoolUid': schoolUid},
    );
  }

  Future<void> assignEmployee(int eventId, int employeeId) async {
    await _client.post<Map<String, dynamic>>(
      '/api/v1/events/$eventId/assignments',
      data: {'employeeId': employeeId},
    );
  }

  Future<List<InteractionModel>> getInteractions(int eventId) async {
    final res = await _client.get<Map<String, dynamic>>(
      '/api/v1/events/$eventId/interactions',
    );
    final api = ApiResponse.fromJson(
      res.data!,
      (json) => (json as List<dynamic>)
          .map((e) => InteractionModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    _assertSuccess(api);
    return api.data!;
  }

  Future<InteractionModel> createInteraction(
    int eventId,
    Map<String, dynamic> data,
  ) async {
    final res = await _client.post<Map<String, dynamic>>(
      '/api/v1/events/$eventId/interactions',
      data: data,
    );
    final api = ApiResponse.fromJson(
      res.data!,
      (json) => InteractionModel.fromJson(json as Map<String, dynamic>),
    );
    _assertSuccess(api);
    return api.data!;
  }

  void _assertSuccess(ApiResponse api) {
    if (!api.success) {
      throw ApiException(message: api.message);
    }
  }
}
