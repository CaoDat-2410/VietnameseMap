import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'firebase_options.dart';

class FirebaseInitializer {
  FirebaseInitializer._();

  static Future<void> initialize() async {
    if (Firebase.apps.isNotEmpty) return;
    if (kIsWeb) {
      await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform);
      return;
    }
    await Firebase.initializeApp();
  }
}
