import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../attendance/data/models/attendance_models.dart';
import '../../../attendance/presentation/providers/attendance_providers.dart';

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
    int? employeeId,
    int? campaignId,
    String? status,
    DateTime? from,
    DateTime? to,
  }) {
    return AttendanceReportFilter(
      employeeId: employeeId ?? this.employeeId,
      campaignId: campaignId ?? this.campaignId,
      status: status ?? this.status,
      from: from ?? this.from,
      to: to ?? this.to,
    );
  }
}

final attendanceReportFilterProvider = StateProvider<AttendanceReportFilter>(
    (ref) => const AttendanceReportFilter());

final attendanceReportDataProvider =
    FutureProvider.autoDispose<List<AttendanceRecord>>((ref) async {
  final f = ref.watch(attendanceReportFilterProvider);
  final repo = ref.read(attendanceRepositoryProvider);
  
  // We use a large limit (e.g. 500) to fetch data for reporting.
  // In a real huge app, we might need pagination in the report or aggregate endpoints.
  final page = await repo.listAttendance(
    employeeId: f.employeeId,
    status: f.status,
    from: f.from,
    to: f.to,
    limit: 500,
  );

  var items = page.items;
  
  // Client-side filtering for campaignId since backend listAttendance doesn't filter by it.
  if (f.campaignId != null) {
    items = items.where((e) => e.campaignId == f.campaignId).toList();
  }
  
  return items;
});
