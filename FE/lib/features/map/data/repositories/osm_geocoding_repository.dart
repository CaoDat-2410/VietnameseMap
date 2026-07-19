import 'package:dio/dio.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/dio_client.dart';

class SchoolGeocode {
  const SchoolGeocode({
    required this.schoolUid,
    required this.schoolName,
    this.latitude,
    this.longitude,
    required this.source,
    required this.isExact,
  });

  final String schoolUid;
  final String schoolName;
  final double? latitude;
  final double? longitude;
  final String source; // "OSM" or "FALLBACK"
  final bool isExact;

  bool get hasCoordinates => latitude != null && longitude != null;

  factory SchoolGeocode.fromJson(Map<String, dynamic> json) {
    return SchoolGeocode(
      schoolUid: json['schoolUid'] as String? ?? '',
      schoolName: json['schoolName'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      source: json['source'] as String? ?? 'FALLBACK',
      isExact: json['isExact'] as bool? ?? false,
    );
  }
}

class OsmGeocodingRepository {
  const OsmGeocodingRepository(this._client);

  final DioClient _client;

  /// Geocode the given school UIDs using the backend's OSM service.
  /// Returns coordinates for the current request only — they are NOT
  /// persisted to the database.
  Future<List<SchoolGeocode>> geocodeSchools(List<String> schoolUids) async {
    if (schoolUids.isEmpty) return const [];
    final Response<Map<String, dynamic>> res = await _client.post(
      '/api/v1/schools/geocode',
      data: schoolUids,
    );
    final api = ApiResponse.fromJson(
      res.data!,
      (json) => (json as List<dynamic>)
          .map((e) => SchoolGeocode.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    if (!api.success) {
      throw ApiException(message: api.message);
    }
    return api.data ?? const [];
  }
}
