import '../../../school/shared/models/school_model.dart';

class CampaignModel {
  const CampaignModel({
    required this.id,
    required this.name,
    required this.status,
    required this.objective,
    required this.startDate,
    required this.endDate,
    required this.ownerEmployeeId,
  });

  final int id;
  final String name;
  final String status;
  final String objective;
  final String startDate;
  final String endDate;
  final int ownerEmployeeId;

  factory CampaignModel.fromJson(Map<String, dynamic> json) => CampaignModel(
        id: json['id'] as int? ?? 0,
        name: json['name'] as String? ?? '',
        status: json['status'] as String? ?? '',
        objective: json['objective'] as String? ?? '',
        startDate: json['startDate'] as String? ?? '',
        endDate: json['endDate'] as String? ?? '',
        ownerEmployeeId: json['ownerEmployeeId'] as int? ?? 0,
      );

  Map<String, dynamic> toRequest() => {
        'name': name,
        'status': status,
        'objective': objective,
        'startDate': startDate,
        'endDate': endDate,
        'ownerEmployeeId': ownerEmployeeId,
      };
}

class CampaignEventModel {
  const CampaignEventModel({
    required this.id,
    required this.campaignId,
    required this.name,
    required this.eventType,
    required this.status,
    required this.startsAt,
    required this.endsAt,
    required this.note,
    this.locationLabel = '',
    this.latitude,
    this.longitude,
    this.schoolUid = '',
    this.provinceCode = '',
  });

  final int id;
  final int campaignId;
  final String name;
  final String eventType;
  final String status;
  final String startsAt;
  final String endsAt;
  final String note;
  final String locationLabel;
  final double? latitude;
  final double? longitude;
  final String schoolUid;
  final String provinceCode;

  bool get hasLocation => latitude != null && longitude != null;

  factory CampaignEventModel.fromJson(Map<String, dynamic> json) =>
      CampaignEventModel(
        id: json['id'] as int? ?? 0,
        campaignId: json['campaignId'] as int? ?? 0,
        name: json['name'] as String? ?? '',
        eventType: json['eventType'] as String? ?? '',
        status: json['status'] as String? ?? '',
        startsAt: json['startsAt'] as String? ?? '',
        endsAt: json['endsAt'] as String? ?? '',
        note: json['note'] as String? ?? '',
        locationLabel: json['locationLabel'] as String? ?? '',
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        schoolUid: json['schoolUid'] as String? ?? '',
        provinceCode: json['provinceCode'] as String? ?? '',
      );
}

class EmployeeModel {
  const EmployeeModel({
    required this.id,
    required this.fullName,
    required this.role,
  });

  final int id;
  final String fullName;
  final String role;

  factory EmployeeModel.fromJson(Map<String, dynamic> json) => EmployeeModel(
        id: json['id'] as int? ?? 0,
        fullName: json['fullName'] as String? ?? '',
        role: json['role'] as String? ?? '',
      );
}

class ProvinceInteractionModel {
  const ProvinceInteractionModel({
    required this.provinceCode,
    required this.provinceName,
    required this.totalInteractions,
  });

  final String provinceCode;
  final String provinceName;
  final int totalInteractions;

  factory ProvinceInteractionModel.fromJson(Map<String, dynamic> json) =>
      ProvinceInteractionModel(
        provinceCode: json['provinceCode'] as String? ?? '',
        provinceName: json['provinceName'] as String? ?? '',
        totalInteractions: json['totalInteractions'] as int? ?? 0,
      );
}

class TopSchoolModel {
  const TopSchoolModel({
    required this.schoolUid,
    required this.schoolName,
    required this.totalInteractions,
  });

  final String schoolUid;
  final String schoolName;
  final int totalInteractions;

  factory TopSchoolModel.fromJson(Map<String, dynamic> json) => TopSchoolModel(
        schoolUid: json['schoolUid'] as String? ?? '',
        schoolName: json['schoolName'] as String? ?? '',
        totalInteractions: json['totalInteractions'] as int? ?? 0,
      );
}

class CampaignDashboardModel {
  const CampaignDashboardModel({
    required this.campaignId,
    required this.totalEvents,
    required this.totalTargetSchools,
    required this.totalAssignedEmployees,
    required this.totalInteractions,
    required this.interactionsByOutcome,
    required this.interactionsByProvince,
    required this.topSchools,
  });

  final int campaignId;
  final int totalEvents;
  final int totalTargetSchools;
  final int totalAssignedEmployees;
  final int totalInteractions;
  final Map<String, int> interactionsByOutcome;
  final List<ProvinceInteractionModel> interactionsByProvince;
  final List<TopSchoolModel> topSchools;

  factory CampaignDashboardModel.fromJson(Map<String, dynamic> json) {
    final outcomes =
        (json['interactionsByOutcome'] as Map<String, dynamic>? ?? {})
            .map((key, value) => MapEntry(key, value as int? ?? 0));
    return CampaignDashboardModel(
      campaignId: json['campaignId'] as int? ?? 0,
      totalEvents: json['totalEvents'] as int? ?? 0,
      totalTargetSchools: json['totalTargetSchools'] as int? ?? 0,
      totalAssignedEmployees: json['totalAssignedEmployees'] as int? ?? 0,
      totalInteractions: json['totalInteractions'] as int? ?? 0,
      interactionsByOutcome: outcomes,
      interactionsByProvince:
          (json['interactionsByProvince'] as List<dynamic>? ?? [])
              .map((e) =>
                  ProvinceInteractionModel.fromJson(e as Map<String, dynamic>))
              .toList(),
      topSchools: (json['topSchools'] as List<dynamic>? ?? [])
          .map((e) => TopSchoolModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class InteractionModel {
  const InteractionModel({
    required this.id,
    required this.campaignId,
    required this.eventId,
    required this.employeeId,
    required this.schoolUid,
    required this.participantType,
    required this.participantId,
    required this.channel,
    required this.outcome,
    required this.note,
    required this.nextFollowUpAt,
    required this.createdAt,
  });

  final int id;
  final int campaignId;
  final int eventId;
  final int employeeId;
  final String schoolUid;
  final String participantType;
  final int participantId;
  final String channel;
  final String outcome;
  final String note;
  final String nextFollowUpAt;
  final String createdAt;

  factory InteractionModel.fromJson(Map<String, dynamic> json) =>
      InteractionModel(
        id: json['id'] as int? ?? 0,
        campaignId: json['campaignId'] as int? ?? 0,
        eventId: json['eventId'] as int? ?? 0,
        employeeId: json['employeeId'] as int? ?? 0,
        schoolUid: json['schoolUid'] as String? ?? '',
        participantType: json['participantType'] as String? ?? '',
        participantId: json['participantId'] as int? ?? 0,
        channel: json['channel'] as String? ?? '',
        outcome: json['outcome'] as String? ?? '',
        note: json['note'] as String? ?? '',
        nextFollowUpAt: json['nextFollowUpAt'] as String? ?? '',
        createdAt: json['createdAt'] as String? ?? '',
      );
}

class StudentRegistrationModel {
  const StudentRegistrationModel({
    required this.id,
    required this.campaignId,
    required this.studentId,
    required this.schoolUid,
    required this.status,
    required this.note,
    required this.createdAt,
    required this.updatedAt,
    required this.student,
    required this.school,
  });

  final int id;
  final int campaignId;
  final int studentId;
  final String schoolUid;
  final String status;
  final String note;
  final String createdAt;
  final String updatedAt;
  final StudentModel student;
  final SchoolModel school;

  factory StudentRegistrationModel.fromJson(Map<String, dynamic> json) =>
      StudentRegistrationModel(
        id: json['id'] as int? ?? 0,
        campaignId: json['campaignId'] as int? ?? 0,
        studentId: json['studentId'] as int? ?? 0,
        schoolUid: json['schoolUid'] as String? ?? '',
        status: json['status'] as String? ?? '',
        note: json['note'] as String? ?? '',
        createdAt: json['createdAt'] as String? ?? '',
        updatedAt: json['updatedAt'] as String? ?? '',
        student: StudentModel.fromJson(json['student'] as Map<String, dynamic>),
        school: SchoolModel.fromJson(json['school'] as Map<String, dynamic>),
      );
}
