import '../../../../core/network/api_exception.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/dio_client.dart';
import '../../../school/shared/models/school_model.dart';
import '../models/campaign_models.dart';

class CampaignRepository {
  const CampaignRepository(this._client);

  final DioClient _client;

  Future<List<CampaignModel>> getCampaigns(
      {bool includeArchived = false}) async {
    final res = await _client.get<Map<String, dynamic>>(
      '/api/v1/campaigns',
      queryParameters: {'includeArchived': includeArchived},
    );
    final api = ApiResponse.fromJson(
      res.data!,
      (json) => (json as List<dynamic>)
          .map((e) => CampaignModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    _assertSuccess(api);
    return api.data!;
  }

  Future<CampaignModel> getCampaign(int campaignId) async {
    final res = await _client.get<Map<String, dynamic>>('/api/v1/campaigns/$campaignId');
    final api = ApiResponse.fromJson(
      res.data!,
      (json) => CampaignModel.fromJson(json as Map<String, dynamic>),
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



  Future<CampaignModel> updateCampaign(
    int campaignId,
    Map<String, dynamic> data,
  ) async {
    final res = await _client.put<Map<String, dynamic>>(
      '/api/v1/campaigns/$campaignId',
      data: data,
    );
    final api = ApiResponse.fromJson(
      res.data!,
      (json) => CampaignModel.fromJson(json as Map<String, dynamic>),
    );
    _assertSuccess(api);
    return api.data!;
  }

  Future<void> archiveCampaign(int campaignId) async {
    await _client.delete<Map<String, dynamic>>('/api/v1/campaigns/$campaignId');
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

  Future<List<CampaignEventModel>> getEvents(
    int campaignId, {
    bool includeArchived = false,
  }) async {
    final res = await _client.get<Map<String, dynamic>>(
      '/api/v1/campaigns/$campaignId/events',
      queryParameters: {'includeArchived': includeArchived},
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

  Future<void> archiveEvent(int eventId) async {
    await _client.delete<Map<String, dynamic>>('/api/v1/events/$eventId');
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

  Future<CampaignEventModel> getEvent(int eventId) async {
    final res = await _client.get<Map<String, dynamic>>(
      '/api/v1/events/$eventId',
    );
    final api = ApiResponse.fromJson(
      res.data!,
      (json) => CampaignEventModel.fromJson(json as Map<String, dynamic>),
    );
    _assertSuccess(api);
    return api.data!;
  }

  Future<CampaignEventModel> updateEvent(
    int eventId,
    Map<String, dynamic> data,
  ) async {
    final res = await _client.put<Map<String, dynamic>>(
      '/api/v1/events/$eventId',
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

  Future<void> removeSchool(int eventId, String schoolUid) async {
    await _client.delete<Map<String, dynamic>>(
      '/api/v1/events/$eventId/schools/$schoolUid',
    );
  }

  Future<List<SchoolModel>> getEventSchools(int eventId) async {
    final res = await _client.get<Map<String, dynamic>>(
      '/api/v1/events/$eventId/schools',
    );
    final api = ApiResponse.fromJson(
      res.data!,
      (json) => (json as List<dynamic>)
          .map((e) => SchoolModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    _assertSuccess(api);
    return api.data!;
  }

  Future<void> assignEmployee(int eventId, int employeeId) async {
    await _client.post<Map<String, dynamic>>(
      '/api/v1/events/$eventId/assignments',
      data: {'employeeId': employeeId},
    );
  }

  Future<void> removeEmployee(int eventId, int employeeId) async {
    await _client.delete<Map<String, dynamic>>(
      '/api/v1/events/$eventId/assignments/$employeeId',
    );
  }

  Future<List<EmployeeModel>> getEmployees() async {
    final res = await _client.get<Map<String, dynamic>>('/api/v1/employees');
    final api = ApiResponse.fromJson(
      res.data!,
      (json) => (json as List<dynamic>)
          .map((e) => EmployeeModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    _assertSuccess(api);
    return api.data!;
  }

  Future<List<EmployeeModel>> getEventAssignments(int eventId) async {
    final res = await _client.get<Map<String, dynamic>>(
      '/api/v1/events/$eventId/assignments',
    );
    final api = ApiResponse.fromJson(
      res.data!,
      (json) => (json as List<dynamic>)
          .map((e) => EmployeeModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    _assertSuccess(api);
    return api.data!;
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

  Future<List<StudentRegistrationModel>> getCampaignRegistrations(
    int campaignId,
  ) async {
    final res = await _client.get<Map<String, dynamic>>(
      '/api/v1/campaigns/$campaignId/student-registrations',
    );
    final api = ApiResponse.fromJson(
      res.data!,
      (json) => (json as List<dynamic>)
          .map((e) =>
              StudentRegistrationModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    _assertSuccess(api);
    return api.data!;
  }

  Future<List<StudentRegistrationModel>> getMyRegistrations() async {
    final res = await _client.get<Map<String, dynamic>>(
      '/api/v1/student-registrations/my',
    );
    final api = ApiResponse.fromJson(
      res.data!,
      (json) => (json as List<dynamic>)
          .map((e) =>
              StudentRegistrationModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    _assertSuccess(api);
    return api.data!;
  }

  Future<StudentRegistrationModel> registerStudent(
    int campaignId,
    Map<String, dynamic> data,
  ) async {
    final res = await _client.post<Map<String, dynamic>>(
      '/api/v1/campaigns/$campaignId/student-registrations',
      data: data,
    );
    final api = ApiResponse.fromJson(
      res.data!,
      (json) => StudentRegistrationModel.fromJson(json as Map<String, dynamic>),
    );
    _assertSuccess(api);
    return api.data!;
  }

  Future<StudentRegistrationModel> updateRegistrationStatus(
    int id,
    String status,
  ) async {
    final res = await _client.put<Map<String, dynamic>>(
      '/api/v1/student-registrations/$id/status',
      data: {'status': status},
    );
    final api = ApiResponse.fromJson(
      res.data!,
      (json) => StudentRegistrationModel.fromJson(json as Map<String, dynamic>),
    );
    _assertSuccess(api);
    return api.data!;
  }

  Future<Map<String, dynamic>> listStaffRegistrations({
    int? campaignId,
    String? schoolUid,
    String? status,
    String? q,
    int page = 0,
    int limit = 25,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (campaignId != null) query['campaignId'] = campaignId;
    if (schoolUid != null && schoolUid.isNotEmpty) query['schoolUid'] = schoolUid;
    if (status != null && status.isNotEmpty) query['status'] = status;
    if (q != null && q.isNotEmpty) query['q'] = q;
    final res = await _client.get<Map<String, dynamic>>(
      '/api/v1/staff/student-registrations',
      queryParameters: query,
    );
    final api = ApiResponse.fromJson(res.data!, (json) {
      final m = json as Map<String, dynamic>;
      return {
        'items': (m['items'] as List<dynamic>)
            .map((e) => StudentRegistrationModel.fromJson(
                e as Map<String, dynamic>))
            .toList(),
        'totalItems': m['totalItems'] ?? 0,
        'page': m['page'] ?? 0,
        'limit': m['limit'] ?? limit,
        'totalPages': m['totalPages'] ?? 0,
      };
    });
    _assertSuccess(api);
    return api.data!;
  }

  Future<int> bulkUpdateRegistrationStatus(List<int> ids, String status) async {
    final res = await _client.post<Map<String, dynamic>>(
      '/api/v1/student-registrations/bulk-status',
      data: {'ids': ids, 'status': status},
    );
    final api = ApiResponse.fromJson(
      res.data!,
      (json) => (json as Map<String, dynamic>)['updated'] as int? ?? 0,
    );
    _assertSuccess(api);
    return api.data!;
  }

  Future<List<Map<String, dynamic>>> getUsers() async {
    final res = await _client.get<Map<String, dynamic>>('/api/v1/users');
    final api = ApiResponse.fromJson(
      res.data!,
      (json) => (json as List<dynamic>)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
    );
    _assertSuccess(api);
    return api.data!;
  }

  Future<void> updateUserRole(int userId, String role) async {
    await _client.put<Map<String, dynamic>>(
      '/api/v1/users/$userId/role',
      data: {'role': role},
    );
  }

  Future<void> updateUserStatus(int userId, String status) async {
    await _client.put<Map<String, dynamic>>(
      '/api/v1/users/$userId/status',
      data: {'status': status},
    );
  }

  Future<Map<String, dynamic>> createUser(Map<String, dynamic> data) async {
    final res = await _client.post<Map<String, dynamic>>(
      '/api/v1/users',
      data: data,
    );
    final api = ApiResponse.fromJson(
      res.data!,
      (json) => Map<String, dynamic>.from(json as Map),
    );
    _assertSuccess(api);
    return api.data!;
  }

  Future<Map<String, dynamic>> updateUser(int userId, Map<String, dynamic> data) async {
    final res = await _client.put<Map<String, dynamic>>(
      '/api/v1/users/$userId',
      data: data,
    );
    final api = ApiResponse.fromJson(
      res.data!,
      (json) => Map<String, dynamic>.from(json as Map),
    );
    _assertSuccess(api);
    return api.data!;
  }

  Future<void> deleteUser(int userId) async {
    await _client.delete<Map<String, dynamic>>('/api/v1/users/$userId');
  }

  void _assertSuccess(ApiResponse api) {
    if (!api.success) {
      throw ApiException(message: api.message);
    }
  }
}
