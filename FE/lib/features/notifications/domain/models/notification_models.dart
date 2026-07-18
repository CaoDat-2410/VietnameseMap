import 'package:flutter/foundation.dart';

@immutable
class NotificationRecipient {
  const NotificationRecipient({
    required this.id,
    required this.email,
    required this.role,
    required this.status,
  });

  final int id;
  final String email;
  final String role;
  final String status;

  String get label => '$email - $role';

  factory NotificationRecipient.fromJson(Map<String, dynamic> json) {
    return NotificationRecipient(
      id: ((json['id'] ?? 0) as num).toInt(),
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
    );
  }
}

@immutable
class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.triggerType,
    required this.status,
    required this.createdAt,
    this.readAt,
    this.data = const {},
  });

  final int id;
  final String title;
  final String body;
  final String triggerType;
  final String status;
  final DateTime createdAt;
  final DateTime? readAt;
  final Map<String, String> data;

  bool get isUnread => readAt == null;

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    final dataMap = <String, String>{};
    if (rawData is Map) {
      rawData.forEach((k, v) {
        dataMap[k.toString()] = v?.toString() ?? '';
      });
    }

    return NotificationItem(
      id: ((json['id'] ?? 0) as num).toInt(),
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      triggerType:
          json['triggerType']?.toString() ?? json['type']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      createdAt: _dateTimeFromJson(json['createdAt']) ?? DateTime.now(),
      readAt: _dateTimeFromJson(json['readAt']),
      data: dataMap,
    );
  }

  static DateTime? _dateTimeFromJson(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is num) {
      final millis =
          value > 1000000000000 ? value.toInt() : (value * 1000).toInt();
      return DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true);
    }
    return DateTime.tryParse(value.toString());
  }
}
