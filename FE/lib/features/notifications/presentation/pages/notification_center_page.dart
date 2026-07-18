import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/analytics/analytics_service.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/models/notification_models.dart';
import '../notification_navigation.dart';
import '../providers/notification_provider.dart';

/// Persistent in-app inbox backed by the notification audit API.
class NotificationCenterPage extends ConsumerStatefulWidget {
  const NotificationCenterPage({super.key});

  @override
  ConsumerState<NotificationCenterPage> createState() =>
      _NotificationCenterPageState();
}

class _NotificationCenterPageState
    extends ConsumerState<NotificationCenterPage> {
  bool _markingAll = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final notifications = ref.watch(allNotificationsProvider);
    final hasUnread =
        notifications.valueOrNull?.any((item) => item.isUnread) ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notifications),
        actions: [
          IconButton(
            tooltip: l10n.refresh,
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
          if (hasUnread)
            TextButton.icon(
              onPressed: _markingAll ? null : _markAllRead,
              icon: _markingAll
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.done_all, size: 18),
              label: Text(l10n.markAllNotificationsRead),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 920),
              child: notifications.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => _InboxState(
                  icon: Icons.cloud_off_outlined,
                  title: l10n.notificationLoadFailed,
                  actionLabel: l10n.retry,
                  onAction: _refresh,
                ),
                data: (items) {
                  if (items.isEmpty) {
                    return _InboxState(
                      icon: Icons.notifications_none_rounded,
                      title: l10n.noNotifications,
                      subtitle: l10n.notificationInboxDescription,
                      actionLabel: l10n.refresh,
                      onAction: _refresh,
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        constraints.maxWidth < 600 ? 12 : 24,
                        16,
                        constraints.maxWidth < 600 ? 12 : 24,
                        32,
                      ),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, index) => _NotificationCard(
                        item: items[index],
                        justNowLabel: l10n.notificationJustNow,
                        onTap: () => _open(items[index]),
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _refresh() async {
    invalidateNotifications(ref);
    await ref.read(allNotificationsProvider.future);
  }

  Future<void> _markAllRead() async {
    setState(() => _markingAll = true);
    try {
      await ref.read(notificationRepositoryProvider).markAllRead();
      invalidateNotifications(ref);
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.allNotificationsRead)),
        );
      }
    } finally {
      if (mounted) setState(() => _markingAll = false);
    }
  }

  Future<void> _open(NotificationItem item) async {
    if (item.isUnread) {
      try {
        await ref.read(notificationRepositoryProvider).markRead(item.id);
        invalidateNotifications(ref);
      } catch (_) {
        // Navigation remains available if the read receipt cannot be saved.
      }
    }
    if (!mounted) return;
    final data = <String, dynamic>{
      ...item.data,
      'type': item.data['type'] ?? item.triggerType,
    };
    await AnalyticsService.logEvent('notification_tapped', {
      'type': data['type']?.toString() ?? '',
      'notification_id': item.id,
    });
    if (mounted) context.go(notificationDestination(data));
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.item,
    required this.justNowLabel,
    required this.onTap,
  });

  final NotificationItem item;
  final String justNowLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final type = item.data['type'] ?? item.triggerType;

    return Card(
      elevation: item.isUnread ? 1 : 0,
      color: item.isUnread
          ? colors.primaryContainer.withValues(alpha: 0.28)
          : colors.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: item.isUnread
                    ? colors.primaryContainer
                    : colors.surfaceContainerHighest,
                child: Icon(
                  _iconForType(type),
                  color: item.isUnread ? colors.primary : colors.outline,
                  size: 21,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: item.isUnread
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _formatTime(item.createdAt, justNowLabel),
                          style: theme.textTheme.labelSmall
                              ?.copyWith(color: colors.outline),
                        ),
                      ],
                    ),
                    if (item.body.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        item.body,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: colors.onSurfaceVariant),
                      ),
                    ],
                  ],
                ),
              ),
              if (item.isUnread) ...[
                const SizedBox(width: 10),
                Container(
                  width: 9,
                  height: 9,
                  margin: const EdgeInsets.only(top: 5),
                  decoration: BoxDecoration(
                    color: colors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type.toLowerCase()) {
      case 'event_reminder':
        return Icons.event_available_outlined;
      case 'campaign_update':
        return Icons.campaign_outlined;
      case 'registration_approved':
        return Icons.task_alt_outlined;
      case 'registration_rejected':
      case 'registration_cancelled':
        return Icons.assignment_late_outlined;
      case 'account_deactivated':
        return Icons.person_off_outlined;
      case 'system_notice':
        return Icons.info_outline;
      default:
        return Icons.notifications_outlined;
    }
  }

  String _formatTime(DateTime time, String justNow) {
    final local = time.toLocal();
    final diff = DateTime.now().difference(local);
    if (diff.inMinutes < 1) return justNow;
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    return '$day/$month/${local.year}';
  }
}

class _InboxState extends StatelessWidget {
  const _InboxState({
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: colors.outline),
            const SizedBox(height: 16),
            Text(title, style: theme.textTheme.titleMedium),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: colors.onSurfaceVariant),
              ),
            ],
            if (onAction != null && actionLabel != null) ...[
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.refresh),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
