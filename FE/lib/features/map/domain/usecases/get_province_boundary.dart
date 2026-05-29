import '../../../../core/utils/result.dart';
import '../entities/geo_json_feature.dart';
import '../repositories/geo_repository.dart';

class GetProvinceBoundary {
  const GetProvinceBoundary(this._repo);

  final GeoRepository _repo;

  Future<Result<GeoJsonFeature>> call(String code) =>
      _repo.getProvinceBoundary(code);
}
