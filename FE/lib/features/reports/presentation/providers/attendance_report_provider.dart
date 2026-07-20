import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../attendance/data/models/attendance_models.dart';
import '../../../attendance/presentation/providers/attendance_providers.dart';

const _reportUnset = Object();

class AttendanceReportFilter {
  const AttendanceReportFilter({
    this.employeeId,
    this.campaignId,
    this.status,
    this.from,
    this.to,
  });

  final int? employeeId;
  final int? campaignId;
  final String? status;
  final DateTime? from;
  final DateTime? to;

  AttendanceReportFilter copyWith({
    Object? employeeId = _reportUnset,
    Object? campaignId = _reportUnset,
    Object? status = _reportUnset,
    Object? from = _reportUnset,
    Object? to = _reportUnset,
  }) {
    return AttendanceReportFilter(
      employeeId: identical(employeeId, _reportUnset)
          ? this.employeeId
          : employeeId as int?,
      campaignId: identical(campaignId, _reportUnset)
          ? this.campaignId
          : campaignId as int?,
      status: identical(status, _reportUnset) ? this.status : status as String?,
      from: identical(from, _reportUnset) ? this.from : from as DateTime?,
      to: identical(to, _reportUnset) ? this.to : to as DateTime?,
    );
  }
}

final attendanceReportFilterProvider = StateProvider<AttendanceReportFilter>(
    (ref) => const AttendanceReportFilter());

final attendanceReportDataProvider =
    FutureProvider.autoDispose<List<AttendanceRecord>>((ref) async {
  final f = ref.watch(attendanceReportFilterProvider);
  final repo = ref.read(attendanceRepositoryProvider);

  final items = <AttendanceRecord>[];
  var pageNumber = 0;
  while (true) {
    final page = await repo.listAttendance(
      employeeId: f.employeeId,
      campaignId: f.campaignId,
      status: f.status,
      from: f.from,
      to: f.to,
      page: pageNumber,
      limit: 200,
    );
    items.addAll(page.items);
    pageNumber += 1;
    if (pageNumber >= page.totalPages) {
      break;
    }
  }

  return items;
});
