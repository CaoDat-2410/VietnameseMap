import '../../../../core/network/dio_client.dart';
import '../../domain/models/report_models.dart';

class ReportRepository {
  ReportRepository({DioClient? client}) : _client = client ?? DioClient();

  final DioClient _client;

  Future<ReportExport> createCampaignPdf(CampaignReportRequest request) async {
    final res = await _client.post<Map<String, dynamic>>(
      '/api/v1/reports/campaigns/pdf',
      data: request.toJson(),
    );
    return ReportExport.fromJson(res.data!['data'] as Map<String, dynamic>);
  }

  Future<ReportExport> getReport(int reportId) async {
    final res = await _client.get<Map<String, dynamic>>('/api/v1/reports/$reportId');
    return ReportExport.fromJson(res.data!['data'] as Map<String, dynamic>);
  }

  Future<ReportExport> getDownloadUrl(int reportId) async {
    final res = await _client.get<Map<String, dynamic>>('/api/v1/reports/$reportId/download-url');
    return ReportExport.fromJson(res.data!['data'] as Map<String, dynamic>);
  }

  Future<List<CampaignSummary>> getCampaigns() async {
    final res = await _client.get<Map<String, dynamic>>('/api/v1/campaigns');
    final items = _itemsFromEnvelope(res.data);
    return items.map((e) {
      final map = e as Map<String, dynamic>;
      return CampaignSummary(
        id: ((map['id'] ?? map['campaignId']) as num).toInt(),
        name: map['name']?.toString() ?? map['campaignName']?.toString() ?? map['title']?.toString() ?? 'N/A',
        status: map['status']?.toString() ?? 'DRAFT',
      );
    }).toList();
  }

  Future<PagedSchoolsResponse> getSchools({required int page, String? query}) async {
    final params = <String, dynamic>{
      'page': page,
      'limit': 50,
    };
    if (query != null && query.isNotEmpty) params['q'] = query;
    final res = await _client.get<Map<String, dynamic>>('/api/v1/schools', queryParameters: params);
    final data = res.data?['data'];
    final content = _itemsFromEnvelope(res.data);
    final total = data is Map<String, dynamic>
        ? ((data['totalElements'] ?? data['totalItems'] ?? content.length) as num).toInt()
        : content.length;
    return PagedSchoolsResponse(
      items: content.map((s) => SchoolSummary(
        uid: s['uid'] ?? s['schoolUid'] ?? '',
        name: s['name'] ?? s['schoolName'] ?? 'N/A',
        provinceCode: s['provinceCode']?.toString(),
        provinceName: s['provinceName']?.toString(),
      )).toList(),
      page: page,
      totalItems: total,
      totalPages: (total / 50).ceil(),
    );
  }

  Future<List<EmployeeSummary>> getEmployees() async {
    final res = await _client.get<Map<String, dynamic>>('/api/v1/employees');
    final items = _itemsFromEnvelope(res.data);
    return items.map((e) {
      final map = e as Map<String, dynamic>;
      return EmployeeSummary(
        id: (map['id'] as num).toInt(),
        name: map['fullName']?.toString() ?? map['name']?.toString() ?? 'N/A',
        role: map['role']?.toString() ?? 'STAFF',
      );
    }).toList();
  }

  List<dynamic> _itemsFromEnvelope(Map<String, dynamic>? envelope) {
    final data = envelope?['data'];
    if (data is List) return data;
    if (data is Map<String, dynamic>) {
      final items = data['items'] ?? data['content'] ?? data['data'];
      if (items is List) return items;
    }
    return const <dynamic>[];
  }
}

class CampaignSummary {
  final int id;
  final String name;
  final String status;
  CampaignSummary({required this.id, required this.name, required this.status});
}

class SchoolSummary {
  final String uid;
  final String name;
  final String? provinceCode;
  final String? provinceName;
  SchoolSummary({required this.uid, required this.name, this.provinceCode, this.provinceName});
}

class PagedSchoolsResponse {
  final List<SchoolSummary> items;
  final int page;
  final int totalItems;
  final int totalPages;
  PagedSchoolsResponse({
    required this.items,
    required this.page,
    required this.totalItems,
    required this.totalPages,
  });
}

class EmployeeSummary {
  final int id;
  final String name;
  final String role;
  EmployeeSummary({required this.id, required this.name, required this.role});
}
