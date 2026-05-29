import '../../../../core/utils/result.dart';
import '../entities/location.dart';
import '../repositories/location_repository.dart';

class GetCurrentLocation {
  const GetCurrentLocation(this._repo);

  final LocationRepository _repo;

  Future<Result<Location>> call() => _repo.getCurrentLocation();
}
