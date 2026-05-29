import '../../../../core/utils/result.dart';
import '../entities/administrative_unit.dart';
import '../entities/administrative_unit_summary.dart';
import '../entities/geo_json_feature.dart';

abstract interface class GeoRepository {
  Future<Result<List<AdministrativeUnitSummary>>> getProvinces();

  Future<Result<GeoJsonFeature>> getProvinceBoundary(String code);

  Future<Result<List<AdministrativeUnitSummary>>> getDistricts(
      String provinceCode);

  Future<Result<List<AdministrativeUnitSummary>>> getWards(String districtCode);

  Future<Result<AdministrativeUnit>> getUnitByCode(String code);

  Future<Result<GeoJsonFeature>> getUnitBoundary(String code);

  Future<Result<AdministrativeUnit>> reverseGeocode(double lat, double lng);
}
