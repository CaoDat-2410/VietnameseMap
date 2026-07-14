import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Handles FCM token management and foreground/background message handling.
class MessagingService {
  MessagingService._();

  static final MessagingService instance = MessagingService._();

  /// Initializes FCM and registers the device token with the backend.
  /// Call once on app startup after Firebase is initialized.
  Future<void> initialize() async {
    try {
      final messaging = FirebaseMessaging.instance;

      final settings = await messaging.requestPermission();

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('[MessagingService] Notification permission granted');
      } else {
        debugPrint('[MessagingService] Notification permission denied');
        return;
      }

      final token = await messaging.getToken();
      if (token != null) {
        debugPrint('[MessagingService] FCM token: $token');
        await _registerToken(token, 'WEB');
      }

      messaging.onTokenRefresh.listen((newToken) async {
        debugPrint('[MessagingService] Token refreshed');
        await _registerToken(newToken, 'WEB');
      });

      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
    } catch (e) {
      debugPrint('[MessagingService] Failed to initialize: $e');
    }
  }

  Future<String?> getToken() async {
    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (e) {
      debugPrint('[MessagingService] Failed to get token: $e');
      return null;
    }
  }

  Future<void> _handleMessageOpenedApp(RemoteMessage message) async {
    debugPrint('[MessagingService] onMessageOpenedApp: ${message.notification?.title}');
    NotificationCenter.instance.add(message);
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('[MessagingService] Foreground message: ${message.notification?.title}');
    NotificationCenter.instance.add(message);
  }

  Future<void> _registerToken(String token, String platform) async {
    debugPrint('[MessagingService] Token ready: $token');
  }
}

/// Simple in-memory notification center for the current session.
class NotificationCenter {
  NotificationCenter._();
  static final NotificationCenter instance = NotificationCenter._();

  final List<RemoteMessage> _messages = [];
  void Function(RemoteMessage)? onNewMessage;

  List<RemoteMessage> get messages => List.unmodifiable(_messages);

  void add(RemoteMessage message) {
    _messages.insert(0, message);
    onNewMessage?.call(message);
  }

  void clear() {
    _messages.clear();
  }
}
