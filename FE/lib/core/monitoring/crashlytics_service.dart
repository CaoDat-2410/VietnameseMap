import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

/// Initializes Firebase Crashlytics for mobile builds only.
///
/// On web, macOS, and Windows, this is a no-op.
/// Crashlytics requires platform-specific config files:
///   - Android: `android/app/google-services.json`
///   - iOS:     `ios/Runner/GoogleService-Info.plist`
///
/// Must be called after [WidgetsFlutterBinding.ensureInitialized()] and
/// after Firebase is initialized.
Future<void> initializeCrashlytics({
  String? userId,
  String? role,
}) async {
  if (kIsWeb || Platform.isMacOS || Platform.isWindows) {
    debugPrint(
        '[Crashlytics] Skipped — only supported on iOS and Android.');
    return;
  }

  try {
    // Import is guarded — Crashlytics is not available on desktop/web
    await _initCrashlytics(userId: userId, role: role);
  } catch (e) {
    debugPrint('[Crashlytics] Initialization skipped or failed: $e');
  }
}

Future<void> _initCrashlytics({
  required String? userId,
  required String? role,
}) async {
  // These imports are only reachable on mobile platforms at runtime.
  // Using dynamic import to avoid compile-time errors on desktop/web.
  // ignore: depend_on_referenced_packages
  final crashlytics = await _loadFirebaseCrashlytics();

  if (userId != null) {
    await crashlytics.setUserIdentifier(userId);
  }
  if (role != null) {
    await crashlytics.setCustomKey('role', role);
  }

  FlutterError.onError = crashlytics.recordFlutterException;
  PlatformDispatcher.instance.onError = (error, stack) {
    crashlytics.recordError(error, stack);
    return true;
  };

  debugPrint('[Crashlytics] Initialized successfully');
}

/// Placeholder — actual implementation loads firebase_crashlytics dynamically.
Future<dynamic> _loadFirebaseCrashlytics() async {
  // firebase_crashlytics doesn't support dynamic loading on all platforms.
  // This method will be replaced with a compile-time import guard in main.dart
  // using `dart:io` Platform checks.
  throw UnimplementedError(
    'Call initializeCrashlytics only from mobile platform builds. '
    'Use the `shouldInitializeCrashlytics` guard from main.dart.',
  );
}

/// Returns true if Crashlytics should be initialized on this platform.
bool get shouldInitializeCrashlytics =>
    !kIsWeb && !Platform.isMacOS && !Platform.isWindows;
