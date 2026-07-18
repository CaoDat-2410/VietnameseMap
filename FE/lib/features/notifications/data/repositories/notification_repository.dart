import '../../../../core/network/api_exception.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/models/notification_models.dart';

class NotificationRepository {
  const NotificationRepository(this._client);

  final DioClient _client;

  Future<List<NotificationRecipient>> listRecipients() async {
    final res = await _client.get<Map<String, dynamic>>('/api/v1/users');
    final api = ApiResponse.fromJson(
      res.data ?? const <String, dynamic>{},
      (json) => (json as List<dynamic>)
          .whereType<Map>()
          .map((item) => NotificationRecipient.fromJson(
                Map<String, dynamic>.from(item),
              ))
          .toList(),
    );
    _assertSuccess(api);
    return (api.data ?? <NotificationRecipient>[])
        .where((recipient) =>
            recipient.id > 0 &&
            recipient.email.isNotEmpty &&
            recipient.status == 'ACTIVE')
        .toList();
  }

  Future<String?> sendManual({
    required int? targetUserId,
    required String title,
    required String body,
    required String type,
  }) async {
    final res = await _client.post<Map<String, dynamic>>(
      '/api/v1/notifications/send',
      data: {
        'targetUserId': targetUserId,
        'title': title,
        'body': body,
        'data': {'type': type},
      },
    );
    final api = ApiResponse.fromJson(
      res.data ?? const <String, dynamic>{},
      (json) => json?.toString() ?? '',
    );
    _assertSuccess(api);
    final messageId = api.data;
    return messageId == null || messageId.isEmpty ? null : messageId;
  }

  Future<List<NotificationItem>> listMy({int limit = 10}) async {
    final res = await _client.get<Map<String, dynamic>>(
      '/api/v1/notifications',
      queryParameters: {'limit': limit},
    );
    final api = ApiResponse.fromJson(
      res.data ?? const <String, dynamic>{},
      _parseNotificationList,
    );
    _assertSuccess(api);
    return api.data ?? <NotificationItem>[];
  }

  Future<int> unreadCount() async {
    final res = await _client.get<Map<String, dynamic>>(
      '/api/v1/notifications/unread-count',
    );
    final api = ApiResponse.fromJson(
      res.data ?? const <String, dynamic>{},
      _parseCount,
    );
    _assertSuccess(api);
    return api.data ?? 0;
  }

  Future<bool> markRead(int id) async {
    final res = await _client.put<Map<String, dynamic>>(
      '/api/v1/notifications/$id/read',
    );
    final api = ApiResponse.fromJson(
      res.data ?? const <String, dynamic>{},
      (json) {
        if (json is Map) return (json['updated'] as bool?) ?? false;
        if (json is bool) return json;
        return false;
      },
    );
    _assertSuccess(api);
    return api.data ?? false;
  }

  Future<int> markAllRead() async {
    final res = await _client.post<Map<String, dynamic>>(
      '/api/v1/notifications/read-all',
    );
    final api = ApiResponse.fromJson(
      res.data ?? const <String, dynamic>{},
      _parseCount,
    );
    _assertSuccess(api);
    return api.data ?? 0;
  }

  List<NotificationItem> _parseNotificationList(Object? json) {
    final items = switch (json) {
      final List<dynamic> list => list,
      final Map map => (map['items'] ?? map['content'] ?? map['data']) is List
          ? (map['items'] ?? map['content'] ?? map['data']) as List<dynamic>
          : const <dynamic>[],
      _ => const <dynamic>[],
    };

    return items
        .whereType<Map>()
        .map((e) => NotificationItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  int _parseCount(Object? json) {
    if (json is num) return json.toInt();
    if (json is Map) {
      final value = json['count'] ?? json['unreadCount'] ?? json['updated'];
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }
    return int.tryParse(json?.toString() ?? '') ?? 0;
  }

  void _assertSuccess(ApiResponse api) {
    if (!api.success) {
      throw ApiException(message: api.message);
    }
  }
}
