class CampaignReportRequest {
  const CampaignReportRequest({
    this.reportType = 'CAMPAIGN',
    this.campaignId,
    this.eventId,
    this.fromDate,
    this.toDate,
    this.eventStatus,
    this.eventType,
    this.provinceCode,
    this.schoolUid,
    this.employeeId,
    this.registrationStatus,
    this.interactionOutcome,
    this.includeArchived = false,
    required this.sections,
    this.chartImages = const {},
  });

  static const String typeCampaign = 'CAMPAIGN';
  static const String typeEvent = 'EVENT';
  static const String typeSchool = 'SCHOOL';
  static const String typeRegion = 'REGION';

  static const List<String> allTypes = [typeCampaign, typeEvent, typeSchool, typeRegion];

  static const List<String> campaignSections = [
    'summary',
    'events',
    'schools',
    'assignments',
    'registrations',
    'interactions',
    'analytics',
  ];

  static const List<String> eventSections = [
    'summary',
    'schools',
    'assignments',
    'interactions',
    'analytics',
  ];

  static const List<String> schoolSections = [
    'summary',
    'events',
    'interactions',
  ];

  static const List<String> regionSections = [
    'summary',
    'events',
    'schools',
    'interactions',
    'analytics',
  ];

  final String reportType;
  final int? campaignId;
  final int? eventId;
  final DateTime? fromDate;
  final DateTime? toDate;
  final String? eventStatus;
  final String? eventType;
  final String? provinceCode;
  final String? schoolUid;
  final int? employeeId;
  final String? registrationStatus;
  final String? interactionOutcome;
  final bool includeArchived;
  final List<String> sections;
  final Map<String, String> chartImages;

  Map<String, dynamic> toJson() => {
        'reportType': reportType,
        if (campaignId != null) 'campaignId': campaignId,
        if (eventId != null) 'eventId': eventId,
        if (fromDate != null) 'fromDate': _date(fromDate!),
        if (toDate != null) 'toDate': _date(toDate!),
        if (_hasText(eventStatus)) 'eventStatus': eventStatus,
        if (_hasText(eventType)) 'eventType': eventType,
        if (_hasText(provinceCode)) 'provinceCode': provinceCode,
        if (_hasText(schoolUid)) 'schoolUid': schoolUid,
        if (employeeId != null) 'employeeId': employeeId,
        if (_hasText(registrationStatus)) 'registrationStatus': registrationStatus,
        if (_hasText(interactionOutcome)) 'interactionOutcome': interactionOutcome,
        'includeArchived': includeArchived,
        'sections': sections,
        if (chartImages.isNotEmpty) 'chartImages': chartImages,
      };

  static String _date(DateTime value) => value.toIso8601String().split('T').first;
  static bool _hasText(String? value) => value != null && value.trim().isNotEmpty;
}

class ReportExport {
  const ReportExport({
    required this.reportId,
    required this.reportType,
    required this.status,
    this.fileName,
    this.storagePath,
    this.downloadUrl,
    this.errorMessage,
    this.createdAt,
    this.completedAt,
  });

  final int reportId;
  final String reportType;
  final String status;
  final String? fileName;
  final String? storagePath;
  final String? downloadUrl;
  final String? errorMessage;
  final DateTime? createdAt;
  final DateTime? completedAt;

  bool get isPending => status == 'PENDING';
  bool get isReady => status == 'READY';
  bool get isFailed => status == 'FAILED';

  factory ReportExport.fromJson(Map<String, dynamic> json) {
    return ReportExport(
      reportId: (json['reportId'] as num).toInt(),
      reportType: json['reportType']?.toString() ?? 'CAMPAIGN',
      status: json['status']?.toString() ?? 'PENDING',
      fileName: json['fileName']?.toString(),
      storagePath: json['storagePath']?.toString(),
      downloadUrl: json['downloadUrl']?.toString(),
      errorMessage: json['errorMessage']?.toString(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      completedAt: DateTime.tryParse(json['completedAt']?.toString() ?? ''),
    );
  }
}