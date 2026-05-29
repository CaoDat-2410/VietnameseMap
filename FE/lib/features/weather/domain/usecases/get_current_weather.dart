import '../../../../core/utils/result.dart';
import '../entities/current_weather.dart';
import '../repositories/weather_repository.dart';

class GetCurrentWeather {
  const GetCurrentWeather(this._repo);

  final WeatherRepository _repo;

  Future<Result<CurrentWeather>> call(double lat, double lng) =>
      _repo.getCurrentWeather(lat, lng);
}
