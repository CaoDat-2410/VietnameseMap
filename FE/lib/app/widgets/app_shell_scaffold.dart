import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/providers/locale_provider.dart';
import '../../core/providers/theme_provider.dart';
import 'app_sidebar.dart';

const _kSidebarPrefKey = 'app.nav.sidebar.expanded';

/// Persists the sidebar expanded/collapsed state across sessions.
class SidebarExpandedNotifier extends StateNotifier<bool> {
  SidebarExpandedNotifier() : super(true) { _load(); }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    state = p.getBool(_kSidebarPrefKey) ?? true;
  }

  Future<void> toggle() async {
    state = !state;
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kSidebarPrefKey, state);
  }
}

final sidebarExpandedProvider =
    StateNotifierProvider<SidebarExpandedNotifier, bool>(
        (_) => SidebarExpandedNotifier());

/// Layout scaffold that switches between:
/// - Desktop (>=900px): Row([240px sidebar | divider | content])
/// - Mobile (<900px): Scaffold(drawer, body) with hamburger AppBar
class AppShellScaffold extends ConsumerWidget {
  const AppShellScaffold({
    super.key,
    required this.items,
    required this.selectedPath,
    required this.onSelected,
    required this.body,
  });
  final List<AppNavItem> items;
  final String selectedPath;
  final ValueChanged<AppNavItem> onSelected;
  final Widget body;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expanded = ref.watch(sidebarExpandedProvider);
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);

    return LayoutBuilder(
      builder: (context, c) {
        // Desktop: sidebar + content row
        if (c.maxWidth >= 900) {
          return Scaffold(
            body: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  width: expanded ? 240 : 72,
                  child: AppSidebar(
                    items: items,
                    selectedPath: selectedPath,
                    onSelected: onSelected,
                    collapsed: !expanded,
                    onToggleCollapsed: () =>
                        ref.read(sidebarExpandedProvider.notifier).toggle(),
                  ),
                ),
                Container(width: 1, color: Theme.of(context).dividerColor),
                Expanded(child: body),
              ],
            ),
          );
        }

        // Mobile: hamburger AppBar + drawer
        return Scaffold(
          appBar: AppBar(
            title: Text(_labelFor(selectedPath, items)),
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                tooltip: 'Đổi ngôn ngữ',
                icon: Text(
                  locale.languageCode.toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: () =>
                    ref.read(localeProvider.notifier).toggleLocale(),
              ),
              IconButton(
                tooltip:
                    themeMode == ThemeMode.dark ? 'Chế độ sáng' : 'Chế độ tối',
                icon: Icon(
                  themeMode == ThemeMode.dark
                      ? Icons.light_mode
                      : Icons.dark_mode,
                ),
                onPressed: () =>
                    ref.read(themeModeProvider.notifier).toggleTheme(),
              ),
            ],
          ),
          drawer: AppDrawer(
            items: items,
            selectedPath: selectedPath,
            onSelected: onSelected,
          ),
          body: body,
        );
      },
    );
  }

  String _labelFor(String path, List<AppNavItem> items) {
    return items
        .firstWhere(
          (i) => i.path == path,
          orElse: () => const AppNavItem(
            path: '/map', label: 'VN Map',
            icon: Icons.map, selectedIcon: Icons.map,
          ),
        )
        .label;
  }
}
