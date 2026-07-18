import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../network/dio_client.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp();
  }
  debugPrint('[MessagingService] Background message: ${message.messageId}');
}

void registerFirebaseBackgroundMessageHandler() {
  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }
}

/// Owns the authenticated device's FCM lifecycle.
///
/// The token is registered only after login because the backend associates each
/// token with the authenticated user. FCM delivery itself uses Google's network
/// and does not depend on adb, USB debugging, or the local API tunnel.
class MessagingService {
  MessagingService._();

  static final MessagingService instance = MessagingService._();

  final DioClient _client = DioClient();
  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _openedAppSubscription;
  String? _registeredToken;
  bool _initializing = false;
  void Function(Map<String, dynamic> data)? onNotificationOpened;

  Future<void> initializeAuthenticatedSession() async {
    if (kIsWeb || _initializing) return;
    _initializing = true;
    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission();
      final allowed =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
              settings.authorizationStatus == AuthorizationStatus.provisional;
      if (!allowed) {
        debugPrint('[MessagingService] Notification permission denied');
        return;
      }

      final token = await messaging.getToken();
      if (token == null || token.isEmpty) {
        debugPrint('[MessagingService] FCM token unavailable');
        return;
      }
      await _registerToken(token);

      await _tokenRefreshSubscription?.cancel();
      _tokenRefreshSubscription = messaging.onTokenRefresh.listen(
        (newToken) => _registerToken(newToken),
        onError: (Object error) =>
            debugPrint('[MessagingService] Token refresh failed: $error'),
      );

      await _foregroundSubscription?.cancel();
      _foregroundSubscription =
          FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      await _openedAppSubscription?.cancel();
      _openedAppSubscription =
          FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleMessageOpenedApp(initialMessage);
      }
      debugPrint('[MessagingService] Android FCM session ready');
    } catch (error) {
      debugPrint('[MessagingService] Failed to initialize: $error');
    } finally {
      _initializing = false;
    }
  }

  Future<void> unregisterAuthenticatedSession() async {
    final token = _registeredToken;
    if (token != null && token.isNotEmpty) {
      try {
        await _client.delete<Map<String, dynamic>>(
          '/api/v1/notifications/token',
          queryParameters: {'token': token},
        );
      } catch (error) {
        debugPrint('[MessagingService] Token unregister failed: $error');
      }
    }
    _registeredToken = null;
    await _tokenRefreshSubscription?.cancel();
    await _foregroundSubscription?.cancel();
    await _openedAppSubscription?.cancel();
    _tokenRefreshSubscription = null;
    _foregroundSubscription = null;
    _openedAppSubscription = null;
    NotificationCenter.instance.clear();
  }

  Future<void> _registerToken(String token) async {
    if (_registeredToken == token) return;
    await _client.post<Map<String, dynamic>>(
      '/api/v1/notifications/token',
      data: {
        'token': token,
        'platform': _platformName,
      },
    );
    _registeredToken = token;
    debugPrint(
      '[MessagingService] FCM token registered (${token.substring(0, 8)}...)',
    );
  }

  String get _platformName => switch (defaultTargetPlatform) {
        TargetPlatform.android => 'ANDROID',
        TargetPlatform.iOS => 'IOS',
        _ => 'MOBILE',
      };

  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('[MessagingService] Notification opened: ${message.messageId}');
    NotificationCenter.instance.add(message);
    onNotificationOpened?.call(message.data);
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('[MessagingService] Foreground message: ${message.messageId}');
    NotificationCenter.instance.add(message);
  }
}

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
