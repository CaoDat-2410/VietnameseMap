import '../../../../core/utils/failure_mapper.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/location.dart';
import '../../domain/repositories/location_repository.dart';
import '../datasources/location_datasource.dart';

class LocationRepositoryImpl implements LocationRepository {
  const LocationRepositoryImpl(this._dataSource);

  final LocationDataSource _dataSource;

  @override
  Future<Result<Location>> getCurrentLocation() async {
    try {
      final location = await _dataSource.getCurrentLocation();
      return Ok(location);
    } catch (e) {
      return Err(mapExceptionToFailure(e));
    }
  }
}
