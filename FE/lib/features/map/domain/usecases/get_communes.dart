import '../../../../core/utils/result.dart';
import '../entities/administrative_unit_summary.dart';
import '../repositories/geo_repository.dart';

class GetCommunes {
  const GetCommunes(this._repo);

  final GeoRepository _repo;

  Future<Result<List<AdministrativeUnitSummary>>> call(String provinceCode) =>
      _repo.getCommunes(provinceCode);
}
