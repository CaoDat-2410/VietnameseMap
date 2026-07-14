import '../../../../core/utils/failure_mapper.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/current_weather.dart';
import '../../domain/repositories/weather_repository.dart';
import '../datasources/weather_remote_datasource.dart';

class WeatherRepositoryImpl implements WeatherRepository {
  const WeatherRepositoryImpl(this._dataSource);

  final WeatherRemoteDataSource _dataSource;

  @override
  Future<Result<CurrentWeather>> getCurrentWeather(double lat, double lng) =>
      _wrap(() async {
        final model = await _dataSource.getCurrentWeather(lat, lng);
        return model.toEntity();
      });

  @override
  Future<Result<CurrentWeather>> getWeatherByUnit(String unitCode) =>
      _wrap(() async {
        final model = await _dataSource.getWeatherByUnit(unitCode);
        return model.toEntity();
      });

  Future<Result<T>> _wrap<T>(Future<T> Function() fn) async {
    try {
      return Ok(await fn());
    } catch (e) {
      return Err(mapExceptionToFailure(e));
    }
  }
}
