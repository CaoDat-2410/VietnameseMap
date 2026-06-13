import '../../../../core/utils/result.dart';
import '../entities/geo_json_feature.dart';
import '../repositories/geo_repository.dart';

class GetCommunesBoundaries {
  const GetCommunesBoundaries(this._repo);

  final GeoRepository _repo;

  Future<Result<List<GeoJsonFeature>>> call(String provinceCode) =>
      _repo.getCommunesBoundaries(provinceCode);
}
