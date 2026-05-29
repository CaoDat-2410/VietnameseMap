import '../../../../core/utils/result.dart';
import '../entities/administrative_unit.dart';
import '../repositories/geo_repository.dart';

class ReverseGeocode {
  const ReverseGeocode(this._repo);

  final GeoRepository _repo;

  Future<Result<AdministrativeUnit>> call(double lat, double lng) =>
      _repo.reverseGeocode(lat, lng);
}
