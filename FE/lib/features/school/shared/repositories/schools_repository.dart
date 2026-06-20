import '../../../../core/network/api_exception.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/dio_client.dart';
import '../models/school_model.dart';

class SchoolSearchParams {
  const SchoolSearchParams({
    this.page = 0,
    this.limit = 50,
    this.provinceCode,
    this.communeCode,
    this.area,
    this.query,
  });

  final int page;
  final int limit;
  final String? provinceCode;
  final String? communeCode;
  final String? area;
  final String? query;

  Map<String, dynamic> toQuery() {
    return {
      'page': page,
      'limit': limit,
      if (provinceCode?.isNotEmpty ?? false) 'provinceCode': provinceCode,
      if (communeCode?.isNotEmpty ?? false) 'communeCode': communeCode,
      if (area?.isNotEmpty ?? false) 'area': area,
      if (query?.isNotEmpty ?? false) 'q': query,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SchoolSearchParams &&
          page == other.page &&
          limit == other.limit &&
          provinceCode == other.provinceCode &&
          communeCode == other.communeCode &&
          area == other.area &&
          query == other.query;

  @override
  int get hashCode =>
      Object.hash(page, limit, provinceCode, communeCode, area, query);
}

class SchoolsRepository {
  const SchoolsRepository(this._client);

  final DioClient _client;

  Future<PagedResponse<SchoolModel>> searchSchools(
    SchoolSearchParams params,
  ) async {
    final res = await _client.get<Map<String, dynamic>>(
      '/api/v1/schools',
      queryParameters: params.toQuery(),
    );
    final api = ApiResponse.fromJson(
      res.data!,
      (json) => PagedResponse.fromJson(
        json as Map<String, dynamic>,
        (item) => SchoolModel.fromJson(item as Map<String, dynamic>),
      ),
    );
    _assertSuccess(api);
    return api.data!;
  }

  Future<SchoolDetailModel> getSchool(String schoolUid) async {
    final res = await _client.get<Map<String, dynamic>>(
      '/api/v1/schools/$schoolUid',
    );
    final api = ApiResponse.fromJson(
      res.data!,
      (json) => SchoolDetailModel.fromJson(json as Map<String, dynamic>),
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
