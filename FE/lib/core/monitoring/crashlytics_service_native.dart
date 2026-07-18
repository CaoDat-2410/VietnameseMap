import 'dart:io' show Platform;
import 'dart:ui' show PlatformDispatcher;

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/widgets.dart';

bool get shouldInitializeCrashlytics => Platform.isAndroid || Platform.isIOS;

Future<void> initializeCrashlytics({String? userId, String? role}) async {
  if (!shouldInitializeCrashlytics) return;
  final crashlytics = FirebaseCrashlytics.instance;
  await crashlytics.setCrashlyticsCollectionEnabled(true);
  if (userId != null) await crashlytics.setUserIdentifier(userId);
  if (role != null) await crashlytics.setCustomKey('role', role);
  FlutterError.onError = crashlytics.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stackTrace) {
    crashlytics.recordError(error, stackTrace, fatal: true);
    return true;
  };
}

Future<bool> recordCrashlyticsDemo() async {
  if (!shouldInitializeCrashlytics) return false;
  await FirebaseCrashlytics.instance.recordError(
    StateError('Settings non-fatal demo'),
    StackTrace.current,
    reason: 'manual_settings_demo',
    fatal: false,
  );
  return true;
}
