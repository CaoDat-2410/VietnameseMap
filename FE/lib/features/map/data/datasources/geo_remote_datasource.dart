import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/dio_client.dart';
import '../models/administrative_unit_model.dart';
import '../models/administrative_unit_summary_model.dart';
import '../models/committee_model.dart';
import '../models/geo_json_feature_model.dart';

abstract interface class GeoRemoteDataSource {
  Future<List<AdministrativeUnitSummaryModel>> getProvinces();
  Future<Map<String, dynamic>> getAllProvincesBoundaries();
  Future<GeoJsonFeatureModel> getProvinceBoundary(String code);
  Future<List<AdministrativeUnitSummaryModel>> getCommunes(String provinceCode);
  Future<List<GeoJsonFeatureModel>> getCommunesBoundaries(String provinceCode);
  Future<List<AdministrativeUnitSummaryModel>> getCommunesPaginated(String provinceCode, int page, int size);
  Future<AdministrativeUnitModel> getUnitByCode(String code);
  Future<GeoJsonFeatureModel> getUnitBoundary(String code);
  Future<AdministrativeUnitModel> reverseGeocode(double lat, double lng);
  Future<List<CommitteeModel>> getCommittees();
  Future<List<CommitteeModel>> getCommitteesByProvince(String provinceCode);
}

class GeoRemoteDataSourceImpl implements GeoRemoteDataSource {
  const GeoRemoteDataSourceImpl(this._client);

  final DioClient _client;

  @override
  Future<List<AdministrativeUnitSummaryModel>> getProvinces() async {
    final res = await _client.get<Map<String, dynamic>>(ApiConstants.provinces);
    final api = ApiResponse.fromJson(
      res.data!,
      (json) => (json as List)
          .map((e) => AdministrativeUnitSummaryModel.fromJson(
              e as Map<String, dynamic>))
          .toList(),
    );
    _assertSuccess(api);
    return api.data!;
  }

  @override
  Future<Map<String, dynamic>> getAllProvincesBoundaries() async {
    final res = await _client.get<Map<String, dynamic>>(
        ApiConstants.provincesBoundaries);
    final api = ApiResponse.fromJson(
      res.data!,
      (json) => json as Map<String, dynamic>,
    );
    _assertSuccess(api);
    return api.data!;
  }

  @override
  Future<GeoJsonFeatureModel> getProvinceBoundary(String code) async {
    final res = await _client
        .get<Map<String, dynamic>>(ApiConstants.unitBoundary(code));
    final api = ApiResponse.fromJson(
      res.data!,
      (json) =>
          GeoJsonFeatureModel.fromJson(json as Map<String, dynamic>),
    );
    _assertSuccess(api);
    return api.data!;
  }

  @override
  Future<List<AdministrativeUnitSummaryModel>> getCommunes(
      String provinceCode) async {
    final res = await _client.get<Map<String, dynamic>>(
      ApiConstants.communes(provinceCode),
    );
    final api = ApiResponse.fromJson(
      res.data!,
      (json) => (json as List)
          .map((e) => AdministrativeUnitSummaryModel.fromJson(
              e as Map<String, dynamic>))
          .toList(),
    );
    _assertSuccess(api);
    return api.data!;
  }

  @override
  Future<List<GeoJsonFeatureModel>> getCommunesBoundaries(
      String provinceCode) async {
    final res = await _client.get<Map<String, dynamic>>(
        ApiConstants.communesBoundaries(provinceCode));
    final api = ApiResponse.fromJson(
      res.data!,
      (json) => (json as List)
          .map((e) =>
              GeoJsonFeatureModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    _assertSuccess(api);
    return api.data!;
  }

  @override
  Future<List<AdministrativeUnitSummaryModel>> getCommunesPaginated(
      String provinceCode, int page, int size) async {
    final res = await _client.get<Map<String, dynamic>>(
      ApiConstants.communesPaginated(provinceCode),
      queryParameters: {'page': page, 'size': size},
    );
    final api = ApiResponse.fromJson(
      res.data!,
      (json) => (json as List)
          .map((e) => AdministrativeUnitSummaryModel.fromJson(
              e as Map<String, dynamic>))
          .toList(),
    );
    _assertSuccess(api);
    return api.data!;
  }

  @override
  Future<AdministrativeUnitModel> getUnitByCode(String code) async {
    final res = await _client
        .get<Map<String, dynamic>>(ApiConstants.unitByCode(code));
    final api = ApiResponse.fromJson(
      res.data!,
      (json) =>
          AdministrativeUnitModel.fromJson(json as Map<String, dynamic>),
    );
    _assertSuccess(api);
    return api.data!;
  }

  @override
  Future<GeoJsonFeatureModel> getUnitBoundary(String code) async {
    final res = await _client
        .get<Map<String, dynamic>>(ApiConstants.unitBoundary(code));
    final api = ApiResponse.fromJson(
      res.data!,
      (json) =>
          GeoJsonFeatureModel.fromJson(json as Map<String, dynamic>),
    );
    _assertSuccess(api);
    return api.data!;
  }

  @override
  Future<AdministrativeUnitModel> reverseGeocode(
      double lat, double lng) async {
    final res = await _client.get<Map<String, dynamic>>(
      ApiConstants.reverseGeocode,
      queryParameters: {'lat': lat, 'lng': lng},
    );
    final api = ApiResponse.fromJson(
      res.data!,
      (json) =>
          AdministrativeUnitModel.fromJson(json as Map<String, dynamic>),
    );
    _assertSuccess(api);
    return api.data!;
  }

  @override
  Future<List<CommitteeModel>> getCommittees() async {
    final res = await _client.get<Map<String, dynamic>>(ApiConstants.committees);
    final api = ApiResponse.fromJson(
      res.data!,
      (json) => (json as List)
          .map((e) => CommitteeModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    _assertSuccess(api);
    return api.data!;
  }

  @override
  Future<List<CommitteeModel>> getCommitteesByProvince(String provinceCode) async {
    final res = await _client.get<Map<String, dynamic>>(
        ApiConstants.committeesByProvince(provinceCode));
    final api = ApiResponse.fromJson(
      res.data!,
      (json) => (json as List)
          .map((e) => CommitteeModel.fromJson(e as Map<String, dynamic>))
          .toList(),
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
