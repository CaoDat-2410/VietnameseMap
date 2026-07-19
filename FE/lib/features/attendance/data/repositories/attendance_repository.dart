import '../../../../core/network/dio_client.dart';
import '../models/attendance_models.dart';

class AttendanceRepository {
  AttendanceRepository({DioClient? client}) : _client = client ?? DioClient();
  final DioClient _client;

  Future<AttendanceRecord> checkIn({
    required int campaignId,
    int? eventId,
    String? note,
    double? lat,
    double? lng,
  }) async {
    final res = await _client.post<Map<String, dynamic>>(
      '/api/v1/attendance/check-in',
      data: {
        'campaignId': campaignId,
        'eventId': eventId,
        'note': note,
        'lat': lat,
        'lng': lng,
      },
    );
    return AttendanceRecord.fromJson(res.data!['data'] as Map<String, dynamic>);
  }

  Future<AttendanceRecord> checkOut({
    String? note,
    double? lat,
    double? lng,
  }) async {
    final res = await _client.post<Map<String, dynamic>>(
      '/api/v1/attendance/check-out',
      data: {
        'note': note,
        'lat': lat,
        'lng': lng,
      },
    );
    return AttendanceRecord.fromJson(res.data!['data'] as Map<String, dynamic>);
  }

  /// Manual entry by MANAGER/ADMIN (e.g. correcting a forgotten check-in).
  Future<AttendanceRecord> createManual({
    required int employeeId,
    required int campaignId,
    int? eventId,
    DateTime? checkInAt,
    DateTime? checkOutAt,
    String? checkInNote,
    String? checkOutNote,
  }) async {
    final res = await _client.post<Map<String, dynamic>>(
      '/api/v1/attendance',
      data: {
        'employeeId': employeeId,
        'campaignId': campaignId,
        'eventId': eventId,
        'checkInAt': checkInAt?.toIso8601String(),
        'checkOutAt': checkOutAt?.toIso8601String(),
        'checkInNote': checkInNote,
        'checkOutNote': checkOutNote,
      },
    );
    return AttendanceRecord.fromJson(res.data!['data'] as Map<String, dynamic>);
  }

  Future<AttendancePage> myAttendance({int page = 0, int limit = 20}) async {
    final res = await _client.get<Map<String, dynamic>>(
      '/api/v1/attendance/me',
      queryParameters: {'page': page, 'limit': limit},
    );
    return AttendancePage.fromJson(res.data!['data'] as Map<String, dynamic>);
  }

  Future<AttendancePage> listAttendance({
    int? employeeId,
    String? status,
    DateTime? from,
    DateTime? to,
    int page = 0,
    int limit = 20,
  }) async {
    final res = await _client.get<Map<String, dynamic>>(
      '/api/v1/attendance',
      queryParameters: {
        if (employeeId != null) 'employeeId': employeeId,
        if (status != null && status.isNotEmpty) 'status': status,
        if (from != null) 'from': from.toIso8601String(),
        if (to != null) 'to': to.toIso8601String(),
        'page': page,
        'limit': limit,
      },
    );
    return AttendancePage.fromJson(res.data!['data'] as Map<String, dynamic>);
  }

  Future<AttendanceRecord> update(
    int id, {
    int? campaignId,
    int? eventId,
    DateTime? checkInAt,
    DateTime? checkOutAt,
    String? checkInNote,
    String? checkOutNote,
  }) async {
    final res = await _client.put<Map<String, dynamic>>(
      '/api/v1/attendance/$id',
      data: {
        if (campaignId != null) 'campaignId': campaignId,
        if (eventId != null) 'eventId': eventId,
        if (checkInAt != null) 'checkInAt': checkInAt.toIso8601String(),
        if (checkOutAt != null) 'checkOutAt': checkOutAt.toIso8601String(),
        if (checkInNote != null) 'checkInNote': checkInNote,
        if (checkOutNote != null) 'checkOutNote': checkOutNote,
      },
    );
    return AttendanceRecord.fromJson(res.data!['data'] as Map<String, dynamic>);
  }

  Future<void> delete(int id) => _client.delete('/api/v1/attendance/$id');
}
