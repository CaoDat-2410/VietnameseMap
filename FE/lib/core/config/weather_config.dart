class WeatherConfig {
  static const apiKey = String.fromEnvironment('WEATHER_API_KEY');

  static bool get hasApiKey => apiKey.isNotEmpty;

  static const baseUrl = 'https://api.weatherapi.com/v1';
}
