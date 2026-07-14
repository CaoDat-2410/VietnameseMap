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

final recentNotificationsProvider = FutureProvider.autoDispose<List<NotificationItem>>(
  (ref) async => ref.watch(notificationRepositoryProvider).listMy(),
);

/// Forces a refresh of both the recent list and the unread count after a
/// notification is marked read or marked-all-read.
void invalidateNotifications(WidgetRef ref) {
  ref.invalidate(recentNotificationsProvider);
  ref.invalidate(notificationUnreadCountProvider);
}

final dioClientProvider = Provider<DioClient>((_) => DioClient());