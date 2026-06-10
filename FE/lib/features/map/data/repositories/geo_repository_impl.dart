import '../../../../core/utils/failure_mapper.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/administrative_unit.dart';
import '../../domain/entities/administrative_unit_summary.dart';
import '../../domain/entities/geo_json_feature.dart';
import '../../domain/repositories/geo_repository.dart';
import '../datasources/geo_remote_datasource.dart';

class GeoRepositoryImpl implements GeoRepository {
  const GeoRepositoryImpl(this._dataSource);

  final GeoRemoteDataSource _dataSource;

  @override
  Future<Result<List<AdministrativeUnitSummary>>> getProvinces() =>
      _wrap(() async {
        final models = await _dataSource.getProvinces();
        return models.map((m) => m.toEntity()).toList();
      });

  @override
  Future<Result<Map<String, dynamic>>> getAllProvincesBoundaries() =>
      _wrap(() async => _dataSource.getAllProvincesBoundaries());

  @override
  Future<Result<GeoJsonFeature>> getProvinceBoundary(String code) =>
      _wrap(() async {
        final model = await _dataSource.getProvinceBoundary(code);
        return model.toEntity();
      });

  @override
  Future<Result<List<AdministrativeUnitSummary>>> getDistricts(
          String provinceCode) =>
      _wrap(() async {
        final models = await _dataSource.getDistricts(provinceCode);
        return models.map((m) => m.toEntity()).toList();
      });

  @override
  Future<Result<List<AdministrativeUnitSummary>>> getWards(
          String districtCode) =>
      _wrap(() async {
        final models = await _dataSource.getWards(districtCode);
        return models.map((m) => m.toEntity()).toList();
      });

  @override
  Future<Result<List<GeoJsonFeature>>> getWardsBoundariesByDistrictId(
          int districtId) =>
      _wrap(() async {
        final models = await _dataSource.getWardsBoundariesByDistrictId(districtId);
        return models.map((m) => m.toEntity()).toList();
      });

  @override
  Future<Result<AdministrativeUnit>> getUnitByCode(String code) =>
      _wrap(() async {
        final model = await _dataSource.getUnitByCode(code);
        return model.toEntity();
      });

  @override
  Future<Result<GeoJsonFeature>> getUnitBoundary(String code) =>
      _wrap(() async {
        final model = await _dataSource.getUnitBoundary(code);
        return model.toEntity();
      });

  @override
  Future<Result<AdministrativeUnit>> reverseGeocode(double lat, double lng) =>
      _wrap(() async {
        final model = await _dataSource.reverseGeocode(lat, lng);
        return model.toEntity();
      });

  Future<Result<T>> _wrap<T>(Future<T> Function() fn) async {
    try {
      return Ok(await fn());
    } catch (e) {
      return Err(mapExceptionToFailure(e));
    }
  }
}
