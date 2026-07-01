import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/router.dart';
import 'core/config/firebase_initializer.dart';
import 'core/monitoring/crashlytics_service.dart';
import 'core/monitoring/sentry_service.dart';
import 'core/providers/locale_provider.dart';
import 'core/providers/theme_provider.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/shared/providers/auth_provider.dart';
import 'l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();

  // Firebase: Web only (throws on mobile unless platform files are present)
  try {
    await FirebaseInitializer.initialize();
  } on UnsupportedError catch (e) {
    debugPrint('[Firebase] ${e.message}');
  }

  // Sentry: Production only
  if (shouldInitializeSentry) {
    final env = dotenv.env['ENV_MODE'] ?? 'development';
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
