import '../../../../core/utils/result.dart';
import '../entities/current_weather.dart';

abstract interface class WeatherRepository {
  Future<Result<CurrentWeather>> getCurrentWeather(double lat, double lng);
  Future<Result<CurrentWeather>> getWeatherByUnit(String unitCode);
}
