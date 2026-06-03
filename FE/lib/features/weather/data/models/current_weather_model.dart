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
      temperature: _readDouble(json['temperature']),
      feelsLike: _readDouble(json['feelsLike'] ?? json['temperature']),
      humidity: _readInt(json['humidity']),
      windSpeed: _readDouble(json['windSpeed']),
      description: _readString(json['description'], fallback: 'Không có mô tả'),
      iconCode: _readString(json['iconCode'], fallback: '02d'),
      locationName: _readString(json['locationName'], fallback: ''),
      pressure: _readNullableInt(json['pressure']),
      visibility: _readNullableInt(json['visibility']),
      tempMin: _readNullableDouble(json['tempMin']),
      tempMax: _readNullableDouble(json['tempMax']),
      timestamp: _parseTimestamp(json['timestamp']),
      source: json['source'] as String?,
      cached: json['cached'] as bool? ?? false,
    );
  }

  static double _readDouble(dynamic value, {double fallback = 0}) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  static double? _readNullableDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static int _readInt(dynamic value, {int fallback = 0}) {
    if (value is num) return value.round();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  static int? _readNullableInt(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.round();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static String _readString(dynamic value, {required String fallback}) {
    if (value is String && value.trim().isNotEmpty) return value;
    return fallback;
  }

  static DateTime _parseTimestamp(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is num) {
      return DateTime.fromMillisecondsSinceEpoch(
        (value * 1000).toInt(),
        isUtc: true,
      );
    }
    if (value is String) {
      return DateTime.tryParse(value)?.toUtc() ?? DateTime.now();
    }
    return DateTime.now();
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
