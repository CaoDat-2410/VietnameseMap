import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/attendance_models.dart';
import '../../data/repositories/attendance_repository.dart';

const _unset = Object();

final attendanceRepositoryProvider = Provider((ref) => AttendanceRepository());

// --- Self-service (STAFF/MANAGER) ---
final myAttendanceProvider = FutureProvider.autoDispose<AttendancePage>((ref) {
  return ref.read(attendanceRepositoryProvider).myAttendance(limit: 20);
});
final eligibleAttendanceTargetsProvider =
    FutureProvider.autoDispose<List<AttendanceTarget>>((ref) {
  return ref.read(attendanceRepositoryProvider).eligibleTargets();
});

// --- Team view (MANAGER/ADMIN) ---
class AttendanceFilter {
  const AttendanceFilter({this.employeeId, this.status, this.from, this.to});
  final int? employeeId;
  final String? status;
  final DateTime? from;
  final DateTime? to;

  AttendanceFilter copyWith({
    Object? employeeId = _unset,
    Object? status = _unset,
    Object? from = _unset,
    Object? to = _unset,
  }) =>
      AttendanceFilter(
        employeeId: identical(employeeId, _unset)
            ? this.employeeId
            : employeeId as int?,
        status: identical(status, _unset) ? this.status : status as String?,
        from: identical(from, _unset) ? this.from : from as DateTime?,
        to: identical(to, _unset) ? this.to : to as DateTime?,
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
    try {
      await _repo.checkIn(campaignId: campaignId, eventId: eventId, note: note);
    } finally {
      _ref.invalidate(myAttendanceProvider);
    }
  }

  Future<void> checkOut({String? note}) async {
    try {
      await _repo.checkOut(note: note);
    } finally {
      _ref.invalidate(myAttendanceProvider);
    }
  }

  Future<void> createManual({
    required int employeeId,
    required int campaignId,
    int? eventId,
    DateTime? checkInAt,
    DateTime? checkOutAt,
    String? checkInNote,
    String? checkOutNote,
    required String correctionReason,
  }) async {
    await _repo.createManual(
      employeeId: employeeId,
      campaignId: campaignId,
      eventId: eventId,
      checkInAt: checkInAt,
      checkOutAt: checkOutAt,
      checkInNote: checkInNote,
      checkOutNote: checkOutNote,
      correctionReason: correctionReason,
    );
    _ref.invalidate(teamAttendanceProvider);
  }

  Future<void> update(
    int id, {
    int? campaignId,
    int? eventId,
    bool clearEvent = false,
    DateTime? checkInAt,
    DateTime? checkOutAt,
    bool clearCheckOutAt = false,
    String? checkInNote,
    bool clearCheckInNote = false,
    String? checkOutNote,
    bool clearCheckOutNote = false,
    required String correctionReason,
  }) async {
    await _repo.update(
      id,
      campaignId: campaignId,
      clearEvent: clearEvent,
      eventId: eventId,
      checkInAt: checkInAt,
      clearCheckOutAt: clearCheckOutAt,
      checkOutAt: checkOutAt,
      clearCheckInNote: clearCheckInNote,
      checkInNote: checkInNote,
      clearCheckOutNote: clearCheckOutNote,
      correctionReason: correctionReason,
      checkOutNote: checkOutNote,
    );
    _ref.invalidate(teamAttendanceProvider);
  }

  Future<void> delete(int id, {required String reason}) async {
    await _repo.delete(id, reason: reason);
    _ref.invalidate(teamAttendanceProvider);
  }
}
