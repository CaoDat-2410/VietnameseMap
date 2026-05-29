import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/dio_client.dart';
import '../models/current_weather_model.dart';

abstract interface class WeatherRemoteDataSource {
  Future<CurrentWeatherModel> getCurrentWeather(double lat, double lng);
  Future<CurrentWeatherModel> getWeatherByUnit(String unitCode);
}

class WeatherRemoteDataSourceImpl implements WeatherRemoteDataSource {
  const WeatherRemoteDataSourceImpl(this._client);

  final DioClient _client;

  @override
  Future<CurrentWeatherModel> getCurrentWeather(double lat, double lng) async {
    final res = await _client.get<Map<String, dynamic>>(
      ApiConstants.weather,
      queryParameters: {'lat': lat, 'lng': lng},
    );
    final api = ApiResponse.fromJson(
      res.data!,
      (json) =>
          CurrentWeatherModel.fromJson(json as Map<String, dynamic>),
    );
    _assertSuccess(api);
    return api.data!;
  }

  @override
  Future<CurrentWeatherModel> getWeatherByUnit(String unitCode) async {
    final res = await _client
        .get<Map<String, dynamic>>(ApiConstants.weatherByUnit(unitCode));
    final api = ApiResponse.fromJson(
      res.data!,
      (json) =>
          CurrentWeatherModel.fromJson(json as Map<String, dynamic>),
    );
    _assertSuccess(api);
    return api.data!;
  }

  void _assertSuccess(ApiResponse api) {
    if (!api.success) {
      throw ApiException(message: api.message);
    }
  }
}
