import '../../../../core/utils/result.dart';
import '../entities/administrative_unit_summary.dart';
import '../repositories/geo_repository.dart';

class GetWards {
  const GetWards(this._repo);

  final GeoRepository _repo;

  Future<Result<List<AdministrativeUnitSummary>>> call(String districtCode) =>
      _repo.getWards(districtCode);
}
