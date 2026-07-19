import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/attendance_models.dart';
import '../../data/repositories/attendance_repository.dart';

final attendanceRepositoryProvider = Provider((ref) => AttendanceRepository());

// --- Self-service (STAFF/MANAGER) ---
final myAttendanceProvider = FutureProvider.autoDispose<AttendancePage>((ref) {
  return ref.read(attendanceRepositoryProvider).myAttendance(limit: 20);
});

// --- Team view (MANAGER/ADMIN) ---
class AttendanceFilter {
  const AttendanceFilter({this.employeeId, this.status, this.from, this.to});
  final int? employeeId;
  final String? status;
  final DateTime? from;
  final DateTime? to;

  AttendanceFilter copyWith({
    int? employeeId,
    String? status,
    DateTime? from,
    DateTime? to,
  }) =>
      AttendanceFilter(
        employeeId: employeeId ?? this.employeeId,
        status: status ?? this.status,
        from: from ?? this.from,
        to: to ?? this.to,
      );
}

final attendanceFilterProvider =
    StateProvider<AttendanceFilter>((ref) => const AttendanceFilter());

final teamAttendanceProvider =
    FutureProvider.autoDispose<AttendancePage>((ref) {
  final f = ref.watch(attendanceFilterProvider);
  return ref.read(attendanceRepositoryProvider).listAttendance(
        employeeId: f.employeeId,
        status: f.status,
        from: f.from,
        to: f.to,
        limit: 50,
      );
});

// --- Actions (call then invalidate the relevant provider(s) to refresh UI) ---
final attendanceActionsProvider = Provider((ref) => _AttendanceActions(ref));

class _AttendanceActions {
  _AttendanceActions(this._ref);
  final Ref _ref;
  AttendanceRepository get _repo => _ref.read(attendanceRepositoryProvider);

  Future<void> checkIn({
    required int campaignId,
    int? eventId,
    String? note,
  }) async {
    await _repo.checkIn(campaignId: campaignId, eventId: eventId, note: note);
    _ref.invalidate(myAttendanceProvider);
  }

  Future<void> checkOut({String? note}) async {
    await _repo.checkOut(note: note);
    _ref.invalidate(myAttendanceProvider);
  }

  Future<void> createManual({
    required int employeeId,
    required int campaignId,
    int? eventId,
    DateTime? checkInAt,
    DateTime? checkOutAt,
    String? checkInNote,
    String? checkOutNote,
  }) async {
    await _repo.createManual(
      employeeId: employeeId,
      campaignId: campaignId,
      eventId: eventId,
      checkInAt: checkInAt,
      checkOutAt: checkOutAt,
      checkInNote: checkInNote,
      checkOutNote: checkOutNote,
    );
    _ref.invalidate(teamAttendanceProvider);
  }

  Future<void> update(
    int id, {
    int? campaignId,
    int? eventId,
    DateTime? checkInAt,
    DateTime? checkOutAt,
    String? checkInNote,
    String? checkOutNote,
  }) async {
    await _repo.update(
      id,
      campaignId: campaignId,
      eventId: eventId,
      checkInAt: checkInAt,
      checkOutAt: checkOutAt,
      checkInNote: checkInNote,
      checkOutNote: checkOutNote,
    );
    _ref.invalidate(teamAttendanceProvider);
  }

  Future<void> delete(int id) async {
    await _repo.delete(id);
    _ref.invalidate(teamAttendanceProvider);
  }
}
