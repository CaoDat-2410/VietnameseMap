import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/analytics/analytics_service.dart';
import '../../domain/models/notification_models.dart';
import '../providers/notification_provider.dart';

class NotificationBellButton extends ConsumerWidget {
  const NotificationBellButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadAsync = ref.watch(notificationUnreadCountProvider);
    final unread = unreadAsync.maybeWhen(data: (v) => v, orElse: () => 0);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          tooltip: 'Thông báo',
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () {
            AnalyticsService.logEvent('notification_bell_opened');
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              showDragHandle: true,
              builder: (sheetCtx) => NotificationPreviewModal(
                onMarkChanged: () =>
                    invalidateNotifications(ref),
              ),
            );
          },
        ),
        if (unread > 0)
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Theme.of(context).colorScheme.surface,
                  width: 1.5,
                ),
              ),
              child: Text(
                unread > 99 ? '99+' : '$unread',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onError,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class NotificationPreviewModal extends ConsumerStatefulWidget {
  const NotificationPreviewModal({super.key, required this.onMarkChanged});

  final VoidCallback onMarkChanged;

  @override
  ConsumerState<NotificationPreviewModal> createState() =>
      _NotificationPreviewModalState();
}

class _NotificationPreviewModalState
    extends ConsumerState<NotificationPreviewModal> {
  bool _markingAll = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final recentAsync = ref.watch(recentNotificationsProvider);

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 8, 8),
              child: Row(
                children: [
                  Icon(Icons.notifications, color: cs.primary, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'Thông báo',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _markingAll
                        ? null
                        : () async {
                            setState(() => _markingAll = true);
                            try {
                              final repo = ref.read(
                                  notificationRepositoryProvider);
                              await repo.markAllRead();
                              widget.onMarkChanged();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Đã đánh dấu tất cả là đã đọc')),
                                );
                              }
                            } catch (_) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Không thể đánh dấu, vui lòng thử lại')),
                                );
                              }
                            } finally {
                              if (mounted) setState(() => _markingAll = false);
                            }
                          },
                    icon: const Icon(Icons.done_all, size: 18),
                    label: const Text('Đọc tất cả'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: recentAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline, color: cs.error, size: 36),
                      const SizedBox(height: 8),
                      Text('Không thể tải thông báo',
                          style: theme.textTheme.bodyMedium),
                      const SizedBox(height: 4),
                      TextButton(
                        onPressed: () =>
                            invalidateNotifications(ref),
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                ),
                data: (items) {
                  if (items.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.notifications_off_outlined,
                              color: cs.outline, size: 48),
                          const SizedBox(height: 12),
                          Text('Chưa có thông báo',
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(color: cs.outline)),
                        ],
                      ),
                    );
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    itemCount: items.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, indent: 64),
                    itemBuilder: (_, i) {
                      final item = items[i] as NotificationItem;
                      final outerContext = context;
                      return _NotificationRow(
                        item: item,
                        onTap: () async {
                          Navigator.of(context).pop();
                          if (item.isUnread) {
                            try {
                              await ref
                                  .read(notificationRepositoryProvider)
                                  .markRead(item.id);
                              widget.onMarkChanged();
                            } catch (_) {}
                          }
                          if (outerContext.mounted) {
                            _deepLink(outerContext, item);
                          }
                        },
                      );
                    },
                  );
                },
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: TextButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.go('/notifications');
                },
                icon: const Icon(Icons.list_alt, size: 18),
                label: const Text('Xem tất cả'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _deepLink(BuildContext context, NotificationItem item) {
    final data = item.data;
    final type = data['type'] ?? item.triggerType;
    final campaignId = data['campaignId'];
    final eventId = data['eventId'];

    switch (type) {
      case 'event_reminder':
        if (eventId != null && eventId.isNotEmpty) {
          context.go('/events/$eventId');
          AnalyticsService.logEvent('notification_tapped',
              {'type': type, 'event_id': eventId});
          return;
        }
        break;
      case 'campaign_update':
        if (campaignId != null && campaignId.isNotEmpty) {
          context.go('/campaigns/$campaignId/dashboard');
          AnalyticsService.logEvent('notification_tapped',
              {'type': type, 'campaign_id': campaignId});
          return;
        }
        break;
    }
    context.go('/notifications');
  }
}

class _NotificationRow extends StatelessWidget {
  const _NotificationRow({required this.item, required this.onTap});

  final NotificationItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: item.isUnread
            ? cs.primaryContainer
            : cs.surfaceContainerHighest,
        child: Icon(
          _iconForType(item.triggerType),
          color: item.isUnread ? cs.primary : cs.outline,
          size: 20,
        ),
      ),
      title: Text(
        item.title.isEmpty ? 'Thông báo' : item.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: item.isUnread ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      subtitle: item.body.isEmpty
          ? null
          : Text(
              item.body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(_formatTime(item.createdAt),
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: cs.outline)),
          if (item.isUnread)
            Container(
              margin: const EdgeInsets.only(top: 4),
              width: 8,
              height: 8,
              decoration:
                  BoxDecoration(color: cs.primary, shape: BoxShape.circle),
            ),
        ],
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'event_reminder':
        return Icons.event;
      case 'campaign_update':
        return Icons.campaign;
      case 'registration_update':
        return Icons.assignment_turned_in_outlined;
      default:
        return Icons.notifications;
    }
  }

  String _formatTime(DateTime time) {
    final local = time.toLocal();
    final diff = DateTime.now().difference(local);
    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes}p';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${local.day}/${local.month}';
  }
}