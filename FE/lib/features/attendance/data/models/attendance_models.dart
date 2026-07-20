class AttendanceRecord {
  AttendanceRecord({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    this.campaignId,
    this.campaignName,
    this.eventId,
    this.eventName,
    required this.checkInAt,
    this.checkOutAt,
    this.checkInNote,
    this.checkOutNote,
    this.checkInLat,
    this.checkInLng,
    this.checkOutLat,
    this.checkOutLng,
    required this.status,
    this.workedMinutes,
  });

  final int id;
  final int employeeId;
  final String employeeName;
  final int? campaignId;
  final String? campaignName;
  final int? eventId;
  final String? eventName;
  final DateTime checkInAt;
  final DateTime? checkOutAt;
  final String? checkInNote;
  final String? checkOutNote;
  final double? checkInLat;
  final double? checkInLng;
  final double? checkOutLat;
  final double? checkOutLng;
  final String status; // OPEN | CLOSED
  final int? workedMinutes;

  bool get isOpen => status == 'OPEN';

  factory AttendanceRecord.fromJson(Map<String, dynamic> j) => AttendanceRecord(
        id: (j['id'] as num).toInt(),
        employeeId: (j['employeeId'] as num).toInt(),
        employeeName: j['employeeName']?.toString() ?? '',
        campaignId: (j['campaignId'] as num?)?.toInt(),
        campaignName: j['campaignName']?.toString(),
        eventId: (j['eventId'] as num?)?.toInt(),
        eventName: j['eventName']?.toString(),
        checkInAt: DateTime.parse(j['checkInAt'] as String).toLocal(),
        checkOutAt: j['checkOutAt'] != null
            ? DateTime.parse(j['checkOutAt'] as String).toLocal()
            : null,
        checkInNote: j['checkInNote']?.toString(),
        checkOutNote: j['checkOutNote']?.toString(),
        checkInLat: (j['checkInLat'] as num?)?.toDouble(),
        checkInLng: (j['checkInLng'] as num?)?.toDouble(),
        checkOutLat: (j['checkOutLat'] as num?)?.toDouble(),
        checkOutLng: (j['checkOutLng'] as num?)?.toDouble(),
        status: j['status'] as String,
        workedMinutes: (j['workedMinutes'] as num?)?.toInt(),
      );
}

class AttendancePage {
  AttendancePage({
    required this.items,
    required this.page,
    required this.totalItems,
    required this.totalPages,
  });

  final List<AttendanceRecord> items;
  final int page;
  final int totalItems;
  final int totalPages;

  factory AttendancePage.fromJson(Map<String, dynamic> j) => AttendancePage(
        items: (j['items'] as List)
            .map((e) => AttendanceRecord.fromJson(e as Map<String, dynamic>))
            .toList(),
        page: (j['page'] as num).toInt(),
        totalItems: (j['totalItems'] as num).toInt(),
        totalPages: (j['totalPages'] as num).toInt(),
      );
}

class AttendanceTarget {
  const AttendanceTarget({
    required this.campaignId,
    required this.campaignName,
    this.campaignStartDate,
    this.campaignEndDate,
    required this.eventId,
    required this.eventName,
    this.eventStartsAt,
    this.eventEndsAt,
  });

  final int campaignId;
  final String campaignName;
  final DateTime? campaignStartDate;
  final DateTime? campaignEndDate;
  final int eventId;
  final String eventName;
  final DateTime? eventStartsAt;
  final DateTime? eventEndsAt;

  factory AttendanceTarget.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(Object? value) =>
        value == null ? null : DateTime.parse(value.toString()).toLocal();

    return AttendanceTarget(
      campaignId: (json['campaignId'] as num).toInt(),
      campaignName: json['campaignName']?.toString() ?? '',
      campaignStartDate: parseDate(json['campaignStartDate']),
      campaignEndDate: parseDate(json['campaignEndDate']),
      eventId: (json['eventId'] as num).toInt(),
      eventName: json['eventName']?.toString() ?? '',
      eventStartsAt: parseDate(json['eventStartsAt']),
      eventEndsAt: parseDate(json['eventEndsAt']),
    );
  }
}
