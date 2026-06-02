class ApiConstants {
  ApiConstants._();

  static const String provinces = '/api/v1/geo/provinces';
  static const String provincesBoundaries = '/api/v1/geo/provinces-boundaries';
  static const String districts = '/api/v1/geo/districts';
  static const String wards = '/api/v1/geo/wards';
  static String unitByCode(String code) => '/api/v1/geo/units/$code';
  static String unitBoundary(String code) => '/api/v1/geo/units/$code/boundary';
  static const String reverseGeocode = '/api/v1/geo/reverse';

  static const String weather = '/api/v1/weather';
  static String weatherByUnit(String unitCode) => '/api/v1/weather/unit/$unitCode';
}
