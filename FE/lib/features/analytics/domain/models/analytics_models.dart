import '../../../campaign/shared/models/campaign_models.dart';

enum FilterType { none, campaign, school }

class AggregateDashboardModel {
  const AggregateDashboardModel({
    required this.totalCampaigns,
    required this.totalEvents,
    required this.totalSchools,
    required this.totalEmployees,
    required this.totalInteractions,
    required this.interactionsByOutcome,
    required this.interactionsByProvince,
    required this.topSchools,
  });

  final int totalCampaigns;
  final int totalEvents;
  final int totalSchools;
  final int totalEmployees;
  final int totalInteractions;
  final Map<String, int> interactionsByOutcome;
  final List<ProvinceInteractionModel> interactionsByProvince;
  final List<TopSchoolModel> topSchools;

  factory AggregateDashboardModel.fromJson(Map<String, dynamic> json) {
    final outcomes = (json['interactionsByOutcome'] as Map<String, dynamic>?)
            ?.map((k, v) => MapEntry(k, v as int? ?? 0)) ??
        {};
    return AggregateDashboardModel(
      totalCampaigns: json['totalCampaigns'] as int? ?? 0,
      totalEvents: json['totalEvents'] as int? ?? 0,
      totalSchools: json['totalSchools'] as int? ?? 0,
      totalEmployees: json['totalEmployees'] as int? ?? 0,
      totalInteractions: json['totalInteractions'] as int? ?? 0,
      interactionsByOutcome: outcomes,
      interactionsByProvince: (json['interactionsByProvince'] as List<dynamic>?)
              ?.map((e) => ProvinceInteractionModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      topSchools: (json['topSchools'] as List<dynamic>?)
              ?.map((e) => TopSchoolModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class FilteredDashboardData {
  const FilteredDashboardData({
    required this.type,
    required this.id,
    required this.name,
    required this.totalEvents,
    required this.totalInteractions,
    required this.interactionsByOutcome,
    required this.interactionsByProvince,
    required this.topSchools,
  });

  final String type;
  final String id;
  final String name;
  final int totalEvents;
  final int totalInteractions;
  final Map<String, int> interactionsByOutcome;
  final List<ProvinceInteractionModel> interactionsByProvince;
  final List<TopSchoolModel> topSchools;

  factory FilteredDashboardData.fromCampaignJson(int id, String name, Map<String, dynamic> json) {
    final outcomes = (json['interactionsByOutcome'] as Map<String, dynamic>?)
            ?.map((k, v) => MapEntry(k, v as int? ?? 0)) ??
        {};
    return FilteredDashboardData(
      type: 'campaign',
      id: id.toString(),
      name: name,
      totalEvents: json['totalEvents'] as int? ?? 0,
      totalInteractions: json['totalInteractions'] as int? ?? 0,
      interactionsByOutcome: outcomes,
      interactionsByProvince: (json['interactionsByProvince'] as List<dynamic>?)
              ?.map((e) => ProvinceInteractionModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      topSchools: (json['topSchools'] as List<dynamic>?)
              ?.map((e) => TopSchoolModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// One point in the interactions-over-time line chart.
class TrendPointModel {
  const TrendPointModel({required this.date, required this.total});
  final DateTime date;
  final int total;

  factory TrendPointModel.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    final dateValue = json['date'];
    
    if (dateValue is String) {
      // Standard ISO format: "2024-01-15"
      parsedDate = DateTime.parse(dateValue);
    } else if (dateValue is List) {
      // Array format from Jackson default: [2024, 1, 15]
      parsedDate = DateTime(dateValue[0], dateValue[1], dateValue[2]);
    } else {
      // Fallback
      parsedDate = DateTime.now();
    }
    
    return TrendPointModel(
      date: parsedDate,
      total: (json['total'] as num?)?.toInt() ?? 0,
    );
  }
}

/// One slice of the interactions-by-channel donut chart.
class ChannelBreakdownModel {
  const ChannelBreakdownModel({required this.channel, required this.total});
  final String channel;
  final int total;

  factory ChannelBreakdownModel.fromJson(Map<String, dynamic> json) =>
      ChannelBreakdownModel(
        channel: json['channel'] as String? ?? 'UNKNOWN',
        total: (json['total'] as num?)?.toInt() ?? 0,
      );
}

/// One row of the top-employees bar chart.
class EmployeeRankingModel {
  const EmployeeRankingModel({
    required this.employeeId,
    required this.employeeName,
    required this.totalInteractions,
  });
  final int employeeId;
  final String employeeName;
  final int totalInteractions;

  factory EmployeeRankingModel.fromJson(Map<String, dynamic> json) =>
      EmployeeRankingModel(
        employeeId: (json['employeeId'] as num?)?.toInt() ?? 0,
        employeeName: json['employeeName'] as String? ?? '',
        totalInteractions: (json['totalInteractions'] as num?)?.toInt() ?? 0,
      );
}