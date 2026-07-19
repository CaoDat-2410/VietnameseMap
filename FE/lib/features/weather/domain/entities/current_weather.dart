class CurrentWeather {
  const CurrentWeather({
    required this.temperature,
    required this.feelsLike,
    required this.humidity,
    required this.windSpeed,
    required this.description,
    required this.iconCode,
    required this.locationName,
    this.pressure,
    this.visibility,
    this.tempMin,
    this.tempMax,
    required this.timestamp,
    this.source,
    this.cached = false,
  });

  final double temperature;
  final double feelsLike;
  final int humidity;
  final double windSpeed;
  final String description;
  final String iconCode;
  final String locationName;
  final int? pressure;
  final int? visibility;
  final double? tempMin;
  final double? tempMax;
  final DateTime timestamp;
  final String? source;
  final bool cached;

  String get iconUrl => 'https://openweathermap.org/img/wn/$iconCode@2x.png';
}
