class ApiConstants {
  ApiConstants._();

  static const String provinces = '/api/v1/geo/provinces';
  static const String provincesBoundaries = '/api/v1/geo/provinces-boundaries';
  static String communes(String provinceCode) =>
      '/api/v1/geo/provinces/$provinceCode/communes';
  static String communesBoundaries(String provinceCode) =>
      '/api/v1/geo/provinces/$provinceCode/communes-boundaries';
  static String communesPaginated(String provinceCode) =>
      '/api/v1/geo/provinces/$provinceCode/communes-paginated';
  static String unitByCode(String code) => '/api/v1/geo/units/$code';
  static String unitBoundary(String code) => '/api/v1/geo/units/$code/boundary';
  static const String reverseGeocode = '/api/v1/geo/reverse';
  static const String committees = '/api/v1/geo/committees';
  static String committeesByProvince(String provinceCode) =>
      '/api/v1/geo/committees/$provinceCode';

  static const String weather = '/api/v1/weather/current';
  static String weatherByUnit(String unitCode) =>
      '/api/v1/weather/unit/$unitCode';
}
