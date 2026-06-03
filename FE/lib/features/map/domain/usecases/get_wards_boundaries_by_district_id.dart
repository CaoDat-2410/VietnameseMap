import '../../../../core/utils/result.dart';
import '../entities/geo_json_feature.dart';
import '../repositories/geo_repository.dart';

class GetWardsBoundariesByDistrictId {
  const GetWardsBoundariesByDistrictId(this._repo);

  final GeoRepository _repo;

  Future<Result<List<GeoJsonFeature>>> call(int districtId) =>
      _repo.getWardsBoundariesByDistrictId(districtId);
}
