import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/remote_config_keys.dart';
import '../config/remote_config_service.dart';

/// Provider that exposes the current Remote Config snapshot.
///
/// Use this to guard feature flags in ViewModels:
/// ```dart
/// final flags = ref.watch(remoteConfigProvider);
/// if (flags.googleSignInEnabled) { ... }
/// ```
final remoteConfigProvider = StateNotifierProvider<RemoteConfigNotifier, RemoteConfigSnapshot>((ref) {
  return RemoteConfigNotifier();
});

class RemoteConfigNotifier extends StateNotifier<RemoteConfigSnapshot> {
  RemoteConfigNotifier() : super(const RemoteConfigSnapshot({})) {
    _load();
  }

  Future<void> _load() async {
    await RemoteConfigService.instance.initialize();
    if (RemoteConfigService.instance.snapshot != null) {
      state = RemoteConfigService.instance.snapshot!;
    }
  }

  Future<void> refresh() async {
    final changed = await RemoteConfigService.instance.fetch();
    if (changed) {
      state = RemoteConfigService.instance.snapshot!;
    }
  }
}
