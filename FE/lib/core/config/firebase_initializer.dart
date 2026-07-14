import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';

class FirebaseInitializer {
  FirebaseInitializer._();

  static Future<void> initialize() async {
    if (!kIsWeb && !Platform.isMacOS && !Platform.isWindows) {
      throw UnsupportedError(
        'Firebase web initialization is only supported in this project. '
        'Mobile support requires adding google-services.json (Android) '
        'and GoogleService-Info.plist (iOS) to the respective platform folders.',
      );
    }
    final options = DefaultFirebaseOptions.currentPlatform;
    await Firebase.initializeApp(options: options);
  }
}
