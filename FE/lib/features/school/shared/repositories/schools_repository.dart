import '../../../../core/network/api_exception.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/dio_client.dart';
import '../models/school_model.dart';

class SchoolCoordinates {
  const SchoolCoordinates({
    required this.schoolUid,
    required this.schoolName,
    required this.provinceName,
    required this.communeName,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.geocodeStatus,
    this.geocodeNote,
  });

  final String schoolUid;
  final String schoolName;
  final String provinceName;
  final String communeName;
  final String address;
  final double? latitude;
  final double? longitude;
  final String geocodeStatus;
  final String? geocodeNote;

  factory SchoolCoordinates.fromJson(Map<String, dynamic> json) {
    return SchoolCoordinates(
      schoolUid: json['schoolUid'] as String? ?? '',
      schoolName: json['schoolName'] as String? ?? '',
      provinceName: json['provinceName'] as String? ?? '',
      communeName: json['communeName'] as String? ?? '',
      address: json['address'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      geocodeStatus: json['geocodeStatus'] as String? ?? 'PENDING',
      geocodeNote: json['geocodeNote'] as String?,
    );
  }

  bool get hasCoordinates => latitude != null && longitude != null;

  bool get isFull => geocodeStatus == 'FULL';

  bool get isApproximate => geocodeStatus == 'APPROXIMATE';

  bool get isPending => geocodeStatus == 'PENDING';

  String get fullAddress {
    final parts = <String>[];
    if (address.isNotEmpty) parts.add(address);
    if (communeName.isNotEmpty) parts.add(communeName);
    if (provinceName.isNotEmpty) parts.add(provinceName);
    return parts.join(', ');
  }
}

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
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SchoolSearchParams &&
            other.page == page &&
            other.limit == limit &&
            other.provinceCode == provinceCode &&
            other.communeCode == communeCode &&
            other.area == area &&
            other.query == query;
  }

  @override
  int get hashCode => Object.hash(
        page,
        limit,
        provinceCode,
        communeCode,
        area,
        query,
      );
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

  Future<List<SchoolCoordinates>> getSchoolCoordinates({
    String? provinceCode,
    String? communeCode,
  }) async {
    final queryParams = <String, dynamic>{};
    if (provinceCode != null && provinceCode.isNotEmpty) {
      queryParams['provinceCode'] = provinceCode;
    }
    if (communeCode != null && communeCode.isNotEmpty) {
      queryParams['communeCode'] = communeCode;
    }

    final res = await _client.get<Map<String, dynamic>>(
      '/api/v1/schools/coordinates',
      queryParameters: queryParams.isEmpty ? null : queryParams,
    );
    final api = ApiResponse.fromJson(
      res.data!,
      (json) => (json as List<dynamic>)
          .map((e) => SchoolCoordinates.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    _assertSuccess(api);
    return api.data!;
  }

  Future<SchoolCoordinates> getSchoolCoordinate(String schoolUid) async {
    final res = await _client.get<Map<String, dynamic>>(
      '/api/v1/schools/$schoolUid/coordinates',
    );
    final api = ApiResponse.fromJson(
      res.data!,
      (json) => SchoolCoordinates.fromJson(json as Map<String, dynamic>),
    );
    _assertSuccess(api);
    return api.data!;
  }

  Future<SchoolCoordinates> updateSchoolCoordinates(
    String schoolUid, {
    required double latitude,
    required double longitude,
  }) async {
    final res = await _client.put<Map<String, dynamic>>(
      '/api/v1/schools/$schoolUid/coordinates',
      data: {
        'latitude': latitude,
        'longitude': longitude,
      },
    );
    final api = ApiResponse.fromJson(
      res.data!,
      (json) => SchoolCoordinates.fromJson(json as Map<String, dynamic>),
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
