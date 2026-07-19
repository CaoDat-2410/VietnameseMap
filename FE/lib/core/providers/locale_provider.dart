import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>(
  (ref) => LocaleNotifier(),
);

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('vi'));

  void setLocale(Locale locale) {
    state = locale;
  }

  void toggleLocale() {
    state = state.languageCode == 'vi' ? const Locale('en') : const Locale('vi');
  }
}
