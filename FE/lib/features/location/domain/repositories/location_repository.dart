import '../../../../core/utils/result.dart';
import '../entities/location.dart';

abstract interface class LocationRepository {
  Future<Result<Location>> getCurrentLocation();
}
