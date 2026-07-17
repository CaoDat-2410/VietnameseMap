import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/monitoring/crashlytics_service.dart';
import '../../../../core/providers/analytics_consent_provider.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../core/providers/remote_config_provider.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../l10n/app_localizations.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final analyticsEnabled = ref.watch(analyticsConsentProvider);
    final remoteConfig = ref.watch(remoteConfigProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(pinned: true, title: Text(l10n.settings)),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _SectionHeader(title: l10n.appearance),
                const SizedBox(height: 8),
                _ThemeTile(
                  currentMode: themeMode,
                  onChanged: ref.read(themeModeProvider.notifier).setTheme,
                ),
                const SizedBox(height: 24),
                _SectionHeader(title: l10n.language),
                const SizedBox(height: 8),
                _LanguageTile(
                  currentLocale: locale,
                  onChanged: ref.read(localeProvider.notifier).setLocale,
                ),
                const SizedBox(height: 24),
                _SectionHeader(title: l10n.privacyAnalytics),
                const SizedBox(height: 8),
                _AnalyticsConsentTile(
                  currentConsent: analyticsEnabled,
                  onChanged:
                      ref.read(analyticsConsentProvider.notifier).setConsent,
                ),
                const SizedBox(height: 24),
                _SectionHeader(title: l10n.appInformation),
                const SizedBox(height: 8),
                _FirebaseDemoTile(snapshot: remoteConfig),
                const SizedBox(height: 24),
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
  Widget build(BuildContext context) => Padding(
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

class _ThemeTile extends StatelessWidget {
  const _ThemeTile({required this.currentMode, required this.onChanged});
  final ThemeMode currentMode;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          RadioListTile(
            title: Text(l10n.lightTheme),
            secondary: const Icon(Icons.light_mode_outlined),
            value: ThemeMode.light,
            groupValue: currentMode,
            onChanged: (value) => onChanged(value!),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          RadioListTile(
            title: Text(l10n.darkTheme),
            secondary: const Icon(Icons.dark_mode_outlined),
            value: ThemeMode.dark,
            groupValue: currentMode,
            onChanged: (value) => onChanged(value!),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          RadioListTile(
            title: Text(l10n.systemTheme),
            secondary: const Icon(Icons.settings_suggest_outlined),
            value: ThemeMode.system,
            groupValue: currentMode,
            onChanged: (value) => onChanged(value!),
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
  Widget build(BuildContext context) => Card(
        margin: EdgeInsets.zero,
        child: Column(
          children: [
            RadioListTile(
              title: const Text('Tiếng Việt'),
              secondary: const Text('🇻🇳', style: TextStyle(fontSize: 20)),
              value: const Locale('vi'),
              groupValue: currentLocale,
              onChanged: (value) => onChanged(value!),
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            RadioListTile(
              title: const Text('English'),
              secondary: const Text('🇬🇧', style: TextStyle(fontSize: 20)),
              value: const Locale('en'),
              groupValue: currentLocale,
              onChanged: (value) => onChanged(value!),
            ),
          ],
        ),
      );
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
    final l10n = AppLocalizations.of(context)!;
    return Card(
      margin: EdgeInsets.zero,
      child: SwitchListTile(
        secondary: Icon(
          Icons.analytics_outlined,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(l10n.allowAnalytics),
        subtitle: Text(
          currentConsent
              ? l10n.allowAnalyticsDescription
              : l10n.analyticsDisabledDescription,
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

class _FirebaseDemoTile extends ConsumerWidget {
  const _FirebaseDemoTile({required this.snapshot});
  final dynamic snapshot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final enabled = l10n.enabled;
    final disabled = l10n.disabled;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.firebaseDemo,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.remoteConfigStatus(
                snapshot.googleSignInEnabled ? enabled : disabled,
                snapshot.maintenanceMode ? enabled : disabled,
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () async {
                await ref.read(remoteConfigProvider.notifier).refresh();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.remoteConfigRefreshed)),
                );
              },
              icon: const Icon(Icons.refresh),
              label: Text(l10n.refreshRemoteConfig),
            ),
            const Divider(),
            Text(l10n.crashlyticsDemoDescription),
            const SizedBox(height: 8),
            FilledButton.tonalIcon(
              onPressed: () async {
                final sent = await recordCrashlyticsDemo();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      sent
                          ? l10n.crashlyticsEventSent
                          : l10n.crashlyticsUnavailable,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.bug_report_outlined),
              label: Text(l10n.sendNonFatalDemo),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppInfoTile extends StatelessWidget {
  const _AppInfoTile({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) => Card(
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
                        l10n.version('1.0.0'),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color:
                                  Theme.of(context).colorScheme.onSurfaceVariant,
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
                    l10n.campaignModule,
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