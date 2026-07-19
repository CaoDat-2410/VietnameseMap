import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../data/repositories/notification_repository.dart';
import '../../domain/models/notification_models.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>(
  (ref) => NotificationRepository(ref.watch(dioClientProvider)),
);

final notificationUnreadCountProvider = FutureProvider.autoDispose<int>(
  (ref) async => ref.watch(notificationRepositoryProvider).unreadCount(),
);

final recentNotificationsProvider =
    FutureProvider.autoDispose<List<NotificationItem>>(
  (ref) async => ref.watch(notificationRepositoryProvider).listMy(),
);

final allNotificationsProvider =
    FutureProvider.autoDispose<List<NotificationItem>>(
  (ref) async => ref.watch(notificationRepositoryProvider).listMy(limit: 200),
);

/// Forces a refresh of notification lists and the unread count after a
/// notification is received, marked read, or marked-all-read.
void invalidateNotifications(WidgetRef ref) {
  ref.invalidate(recentNotificationsProvider);
  ref.invalidate(allNotificationsProvider);
  ref.invalidate(notificationUnreadCountProvider);
}

final dioClientProvider = Provider<DioClient>((_) => DioClient());
