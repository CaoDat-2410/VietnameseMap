import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
            leading: Builder(
              builder: (ctx) => IconButton(
                tooltip: 'Menu',
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(ctx).openDrawer(),
              ),
            ),
            title: Text(_labelFor(selectedPath, items)),
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                tooltip: 'Cài đặt',
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => context.go('/settings'),
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
