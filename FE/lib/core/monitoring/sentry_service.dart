import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Whether Sentry should be initialized (production/staging builds only).
bool get shouldInitializeSentry {
  final env = dotenv.env['ENV_MODE'];
  return env == 'production' || env == 'staging';
}

/// Initializes Sentry for crash reporting on production builds.
///
/// Must be called after [WidgetsFlutterBinding.ensureInitialized()] and
/// after Firebase is initialized. Safe to call in dev mode (no-op in non-prod).
Future<void> initializeSentry({
  required String environment,
  String? userId,
  String? role,
}) async {
  final dsn = dotenv.env['SENTRY_DSN'];
  if (dsn == null || dsn.isEmpty || dsn.startsWith('REPLACE_')) {
    debugPrint('[Sentry] DSN not configured — skipping Sentry initialization.');
    return;
  }

  await SentryFlutter.init(
    (options) {
      options.dsn = dsn;
      options.environment = environment;
      options.release = dotenv.env['APP_VERSION'] ?? '1.0.0';

      // Sample 100% in prod, 0% in dev
      options.tracesSampleRate =
          environment == 'production' ? 1.0 : 0.0;
    },
    appRunner: () {
      debugPrint('[Sentry] Initialized for environment: $environment');
    },
  );

  // Set user context after init
  if (userId != null) {
    await Sentry.configureScope((scope) {
      scope.setUser(SentryUser(id: userId));
      scope.setTag('role', role ?? 'unknown');
      scope.setTag('env', environment);
    });
  }
}
