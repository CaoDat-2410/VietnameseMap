class WeatherModel {
  const WeatherModel({
    required this.locationName,
    required this.region,
    required this.country,
    required this.localtime,
    required this.tempC,
    required this.feelslikeC,
    required this.conditionText,
    required this.conditionIcon,
    required this.humidity,
    required this.windKph,
    required this.cloud,
    required this.uv,
    required this.lastUpdated,
  });

  final String locationName;
  final String region;
  final String country;
  final String localtime;
  final double tempC;
  final double feelslikeC;
  final String conditionText;
  final String conditionIcon;
  final int humidity;
  final double windKph;
  final int cloud;
  final double uv;
  final String lastUpdated;

  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    final location = json['location'] as Map<String, dynamic>? ?? const {};
    final current = json['current'] as Map<String, dynamic>? ?? const {};
    final condition = current['condition'] as Map<String, dynamic>? ?? const {};
    final icon = _readString(condition['icon']);

    return WeatherModel(
      locationName: _readString(location['name']),
      region: _readString(location['region']),
      country: _readString(location['country']),
      localtime: _readString(location['localtime']),
      tempC: _readDouble(current['temp_c']),
      feelslikeC: _readDouble(current['feelslike_c']),
      conditionText: _readString(condition['text']),
      conditionIcon: icon.startsWith('//') ? 'https:$icon' : icon,
      humidity: _readInt(current['humidity']),
      windKph: _readDouble(current['wind_kph']),
      cloud: _readInt(current['cloud']),
      uv: _readDouble(current['uv']),
      lastUpdated: _readString(current['last_updated']),
    );
  }

  static String _readString(dynamic value) => value?.toString() ?? '';

  static double _readDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int _readInt(dynamic value) {
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
