import '../../domain/entities/current_weather.dart';

class CurrentWeatherModel {
  const CurrentWeatherModel({
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

  factory CurrentWeatherModel.fromJson(Map<String, dynamic> json) {
    return CurrentWeatherModel(
      temperature: (json['temperature'] as num).toDouble(),
      feelsLike: (json['feelsLike'] as num).toDouble(),
      humidity: json['humidity'] as int,
      windSpeed: (json['windSpeed'] as num).toDouble(),
      description: json['description'] as String,
      iconCode: json['iconCode'] as String,
      locationName: json['locationName'] as String,
      pressure: json['pressure'] as int?,
      visibility: json['visibility'] as int?,
      tempMin: (json['tempMin'] as num?)?.toDouble(),
      tempMax: (json['tempMax'] as num?)?.toDouble(),
      timestamp: _parseTimestamp(json['timestamp']),
      source: json['source'] as String?,
      cached: json['cached'] as bool? ?? false,
    );
  }

  static DateTime _parseTimestamp(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is num) {
      return DateTime.fromMillisecondsSinceEpoch(
        (value * 1000).toInt(),
        isUtc: true,
      );
    }
    return DateTime.parse(value as String).toUtc();
  }

  CurrentWeather toEntity() => CurrentWeather(
        temperature: temperature,
        feelsLike: feelsLike,
        humidity: humidity,
        windSpeed: windSpeed,
        description: description,
        iconCode: iconCode,
        locationName: locationName,
        pressure: pressure,
        visibility: visibility,
        tempMin: tempMin,
        tempMax: tempMax,
        timestamp: timestamp,
        source: source,
        cached: cached,
      );
}
