import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/analytics/analytics_service.dart';
import '../../../../core/messaging/messaging_service.dart';

/// In-app notification center — bell icon in the app shell with unread badge.
class NotificationCenterPage extends StatelessWidget {
  const NotificationCenterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final messages = NotificationCenter.instance.messages;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
        actions: [
          if (messages.isNotEmpty)
            TextButton(
              onPressed: NotificationCenter.instance.clear,
              child: const Text('Xóa tất cả'),
            ),
        ],
      ),
      body: messages.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Không có thông báo',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                return _NotificationTile(message: msg);
              },
            ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.message});
  final RemoteMessage message;

  @override
  Widget build(BuildContext context) {
    final notification = message.notification;
    final data = message.data;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: Icon(
          _iconForType(data['type']),
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      title: Text(notification?.title ?? 'Thông báo'),
      subtitle: Text(
        notification?.body ?? '',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(_formatTime(message.sentTime)),
      onTap: () => _navigate(context, data),
    );
  }

  IconData _iconForType(String? type) {
    switch (type) {
      case 'event_reminder':
        return Icons.event;
      case 'campaign_update':
        return Icons.campaign;
      case 'registration_update':
        return Icons.assignment;
      default:
        return Icons.notifications;
    }
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '';
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Bây giờ';
    if (diff.inMinutes < 60) return '${diff.inMinutes}p';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }

  void _navigate(BuildContext context, Map<String, dynamic> data) {
    final type = data['type'] as String?;
    final campaignId = data['campaignId'] as String?;
    final eventId = data['eventId'] as String?;

    switch (type) {
      case 'event_reminder':
        if (eventId != null) {
          context.go('/events/$eventId');
          AnalyticsService.logEvent('notification_tapped', {'type': type, 'event_id': eventId});
        }
        break;
      case 'campaign_update':
        if (campaignId != null) {
          context.go('/campaigns/$campaignId/dashboard');
          AnalyticsService.logEvent('notification_tapped', {'type': type, 'campaign_id': campaignId});
        }
        break;
      default:
        context.go('/');
    }
  }
}
