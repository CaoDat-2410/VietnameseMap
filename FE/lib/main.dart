import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/router.dart';
import 'core/config/app_config.dart';
import 'core/config/firebase_initializer.dart';
import 'core/messaging/messaging_service.dart';
import 'core/monitoring/crashlytics_service.dart';
import 'core/monitoring/sentry_service.dart';
import 'core/providers/locale_provider.dart';
import 'core/providers/theme_provider.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/providers/auth_viewmodel.dart';
import 'features/notifications/presentation/notification_navigation.dart';
import 'features/notifications/presentation/providers/notification_provider.dart';
import 'l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load();
  } catch (_) {
    debugPrint('[Config] .env asset not found; using dart-define/defaults.');
  }

  // Firebase: Web only (throws on mobile unless platform files are present)
  try {
    await FirebaseInitializer.initialize();
    registerFirebaseBackgroundMessageHandler();
  } on UnsupportedError catch (e) {
    debugPrint('[Firebase] ${e.message}');
  }

  // Sentry: Production only
  if (shouldInitializeSentry) {
    final env = AppConfig.envMode;
    await initializeSentry(environment: env);
  }

  runApp(const ProviderScope(child: VietnameseMapApp()));
}

class VietnameseMapApp extends ConsumerStatefulWidget {
  const VietnameseMapApp({super.key});

  @override
  ConsumerState<VietnameseMapApp> createState() => _VietnameseMapAppState();
}

class _VietnameseMapAppState extends ConsumerState<VietnameseMapApp> {
  @override
  void initState() {
    super.initState();
    _initializeCrashlyticsIfMobile();
    MessagingService.instance.onNotificationOpened = _openNotification;
    NotificationCenter.instance.onNewMessage = (_) => _refreshNotifications();
  }

  void _openNotification(Map<String, dynamic> data) {
    _refreshNotifications();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      router.go(notificationDestination(data));
    });
  }

  void _refreshNotifications() {
    ref.invalidate(recentNotificationsProvider);
    ref.invalidate(allNotificationsProvider);
    ref.invalidate(notificationUnreadCountProvider);
  }

  @override
  void dispose() {
    MessagingService.instance.onNotificationOpened = null;
    NotificationCenter.instance.onNewMessage = null;
    super.dispose();
  }

  void _initializeCrashlyticsIfMobile() {
    if (!shouldInitializeCrashlytics) return;
    final user = ref.read(activeUserProvider).valueOrNull;
    initializeCrashlytics(
      userId: user?.id.toString(),
      role: user?.role,
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'Vietnamese Map',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
    );
  }
}
