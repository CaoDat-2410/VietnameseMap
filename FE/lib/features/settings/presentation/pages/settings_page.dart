import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/analytics_consent_provider.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../l10n/app_localizations.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final analyticsEnabled = ref.watch(analyticsConsentProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            title: Text(l10n.settings),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _SectionHeader(title: 'Giao diện'),
                const SizedBox(height: 8),
                _ThemeTile(
                  currentMode: themeMode,
                  onChanged: (mode) {
                    ref.read(themeModeProvider.notifier).setTheme(mode);
                  },
                ),
                const SizedBox(height: 24),
                _SectionHeader(title: 'Ngôn ngữ'),
                const SizedBox(height: 8),
                _LanguageTile(
                  currentLocale: locale,
                  onChanged: (locale) {
                    ref.read(localeProvider.notifier).setLocale(locale);
                  },
                ),
                const SizedBox(height: 24),
                _SectionHeader(title: 'Quyền riêng tư & Phân tích'),
                const SizedBox(height: 8),
                _AnalyticsConsentTile(
                  currentConsent: analyticsEnabled,
                  onChanged: (value) {
                    ref.read(analyticsConsentProvider.notifier).setConsent(value);
                  },
                ),
                const SizedBox(height: 24),
                _SectionHeader(title: 'Thông tin ứng dụng'),
                const SizedBox(height: 8),
                _AppInfoTile(l10n: l10n),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _ThemeTile extends StatelessWidget {
  const _ThemeTile({required this.currentMode, required this.onChanged});
  final ThemeMode currentMode;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          RadioListTile<ThemeMode>(
            title: const Text('Sáng'),
            secondary: const Icon(Icons.light_mode_outlined),
            value: ThemeMode.light,
            groupValue: currentMode,
            onChanged: (v) => onChanged(v!),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          RadioListTile<ThemeMode>(
            title: const Text('Tối'),
            secondary: const Icon(Icons.dark_mode_outlined),
            value: ThemeMode.dark,
            groupValue: currentMode,
            onChanged: (v) => onChanged(v!),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          RadioListTile<ThemeMode>(
            title: const Text('Hệ thống'),
            secondary: const Icon(Icons.settings_suggest_outlined),
            value: ThemeMode.system,
            groupValue: currentMode,
            onChanged: (v) => onChanged(v!),
          ),
        ],
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({required this.currentLocale, required this.onChanged});
  final Locale currentLocale;
  final ValueChanged<Locale> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          RadioListTile<Locale>(
            title: const Text('Tiếng Việt'),
            secondary: const Text('🇻🇳', style: TextStyle(fontSize: 20)),
            value: const Locale('vi'),
            groupValue: currentLocale,
            onChanged: (v) => onChanged(v!),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          RadioListTile<Locale>(
            title: const Text('English'),
            secondary: const Text('🇬🇧', style: TextStyle(fontSize: 20)),
            value: const Locale('en'),
            groupValue: currentLocale,
            onChanged: (v) => onChanged(v!),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsConsentTile extends StatelessWidget {
  const _AnalyticsConsentTile({
    required this.currentConsent,
    required this.onChanged,
  });

  final bool currentConsent;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: SwitchListTile(
        secondary: Icon(
          Icons.analytics_outlined,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: const Text('Cho phép phân tích'),
        subtitle: Text(
          currentConsent
              ? 'Gửi dữ liệu sử dụng ẩn danh để cải thiện ứng dụng'
              : 'Tắt theo dõi phân tích sử dụng',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        value: currentConsent,
        onChanged: onChanged,
      ),
    );
  }
}

class _AppInfoTile extends StatelessWidget {
  const _AppInfoTile({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.map_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'VN Map',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    Text(
                      'Version 1.0.0',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Campaign Module',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                Text(
                  'PRM393 - CP1',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
