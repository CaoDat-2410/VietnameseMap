import '../../../../core/utils/failure_mapper.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/administrative_unit.dart';
import '../../domain/entities/administrative_unit_summary.dart';
import '../../domain/entities/geo_json_feature.dart';
import '../../domain/repositories/geo_repository.dart';
import '../datasources/geo_remote_datasource.dart';
import '../models/committee_model.dart';

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
  Future<Result<List<AdministrativeUnitSummary>>> getCommunes(
          String provinceCode) =>
      _wrap(() async {
        final models = await _dataSource.getCommunes(provinceCode);
        return models.map((m) => m.toEntity()).toList();
      });

  @override
  Future<Result<List<GeoJsonFeature>>> getCommunesBoundaries(
          String provinceCode) =>
      _wrap(() async {
        final models = await _dataSource.getCommunesBoundaries(provinceCode);
        return models.map((m) => m.toEntity()).toList();
      });

  @override
  Future<Result<List<AdministrativeUnitSummary>>> getCommunesPaginated(
          String provinceCode, int page, int size) =>
      _wrap(() async {
        final models =
            await _dataSource.getCommunesPaginated(provinceCode, page, size);
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
  Future<Result<GeoJsonFeature>> getCommuneBoundary(String code) =>
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

  @override
  Future<Result<List<CommitteeModel>>> getCommittees() =>
      _wrap(() => _dataSource.getCommittees());

  @override
  Future<Result<List<CommitteeModel>>> getCommitteesByProvince(
          String provinceCode) =>
      _wrap(() => _dataSource.getCommitteesByProvince(provinceCode));

  Future<Result<T>> _wrap<T>(Future<T> Function() fn) async {
    try {
      return Ok(await fn());
    } catch (e) {
      return Err(mapExceptionToFailure(e));
    }
  }
}
