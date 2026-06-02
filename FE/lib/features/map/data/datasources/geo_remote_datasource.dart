import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/dio_client.dart';
import '../models/administrative_unit_model.dart';
import '../models/administrative_unit_summary_model.dart';
import '../models/geo_json_feature_model.dart';

abstract interface class GeoRemoteDataSource {
  Future<List<AdministrativeUnitSummaryModel>> getProvinces();
  /// Fetches all province boundaries as a GeoJSON FeatureCollection in one call.
  Future<Map<String, dynamic>> getAllProvincesBoundaries();
  Future<GeoJsonFeatureModel> getProvinceBoundary(String code);
  Future<List<AdministrativeUnitSummaryModel>> getDistricts(String provinceCode);
  Future<List<AdministrativeUnitSummaryModel>> getWards(String districtCode);
  Future<AdministrativeUnitModel> getUnitByCode(String code);
  Future<GeoJsonFeatureModel> getUnitBoundary(String code);
  Future<AdministrativeUnitModel> reverseGeocode(double lat, double lng);
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
  Future<List<AdministrativeUnitSummaryModel>> getDistricts(
      String provinceCode) async {
    final res = await _client.get<Map<String, dynamic>>(
      ApiConstants.districts,
      queryParameters: {'provinceCode': provinceCode},
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
  Future<List<AdministrativeUnitSummaryModel>> getWards(
      String districtCode) async {
    final res = await _client.get<Map<String, dynamic>>(
      ApiConstants.wards,
      queryParameters: {'districtCode': districtCode},
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

  void _assertSuccess(ApiResponse api) {
    if (!api.success) {
      throw ApiException(message: api.message);
    }
  }
}
