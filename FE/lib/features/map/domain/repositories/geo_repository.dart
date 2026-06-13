import '../../../../core/utils/result.dart';
import '../../data/models/committee_model.dart';
import '../entities/administrative_unit.dart';
import '../entities/administrative_unit_summary.dart';
import '../entities/geo_json_feature.dart';

abstract interface class GeoRepository {
  Future<Result<List<AdministrativeUnitSummary>>> getProvinces();

  Future<Result<Map<String, dynamic>>> getAllProvincesBoundaries();

  Future<Result<GeoJsonFeature>> getProvinceBoundary(String code);

  Future<Result<List<AdministrativeUnitSummary>>> getCommunes(String provinceCode);

  Future<Result<List<GeoJsonFeature>>> getCommunesBoundaries(String provinceCode);

  Future<Result<List<AdministrativeUnitSummary>>> getCommunesPaginated(
      String provinceCode, int page, int size);

  Future<Result<AdministrativeUnit>> getUnitByCode(String code);

  Future<Result<GeoJsonFeature>> getUnitBoundary(String code);

  Future<Result<GeoJsonFeature>> getCommuneBoundary(String code);

  Future<Result<AdministrativeUnit>> reverseGeocode(double lat, double lng);

  Future<Result<List<CommitteeModel>>> getCommittees();

  Future<Result<List<CommitteeModel>>> getCommitteesByProvince(String provinceCode);
}
