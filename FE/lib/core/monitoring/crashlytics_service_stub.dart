import 'package:flutter/foundation.dart';

bool get shouldInitializeCrashlytics => false;

Future<void> initializeCrashlytics({String? userId, String? role}) async {
  debugPrint('[Crashlytics] unavailable on this platform.');
}

Future<bool> recordCrashlyticsDemo() async => false;