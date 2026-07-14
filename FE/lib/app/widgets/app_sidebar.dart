import 'package:flutter/material.dart';

/// Public navigation item descriptor. Shared by both sidebar and drawer.
class AppNavItem {
  const AppNavItem({
    required this.path,
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });
  final String path;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

/// Converts the private _NavItem record from router.dart to the public type.
AppNavItem navItemFrom(dynamic n) => AppNavItem(
      path: n.path,
      label: n.label,
      icon: n.icon,
      selectedIcon: n.selectedIcon,
    );

/// Sidebar navigation widget.
/// - Expanded (240px): icon + label per item
/// - Collapsed (72px): icon-only with tooltip
/// Used on desktop (>=900px).
class AppSidebar extends StatelessWidget {
  const AppSidebar({
    super.key,
    required this.items,
    required this.selectedPath,
    required this.onSelected,
    this.collapsed = false,
    this.onToggleCollapsed,
  });

  final List<AppNavItem> items;
  final String selectedPath;
  final ValueChanged<AppNavItem> onSelected;
  final bool collapsed;
  final VoidCallback? onToggleCollapsed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      child: SafeArea(
        child: Column(
          children: [
            // Header: collapse toggle only. The product name lives in the app bar,
            // so the sidebar can collapse without the toggle overlapping branding.
            SizedBox(
              height: 64,
              child: Align(
                alignment: collapsed ? Alignment.center : Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: IconButton(
                    tooltip: collapsed ? 'Mở rộng' : 'Thu gọn',
                    icon: Icon(collapsed ? Icons.menu_open : Icons.menu),
                    color: scheme.onSurfaceVariant,
                    onPressed: onToggleCollapsed,
                  ),
                ),
              ),
            ),
            const Divider(height: 1),
            // Nav items list
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  for (final item in items) _SidebarTile(
                    item: item,
                    selected: item.path == selectedPath,
                    collapsed: collapsed,
                    onTap: () => onSelected(item),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarTile extends StatelessWidget {
  const _SidebarTile({
    required this.item,
    required this.selected,
    required this.collapsed,
    required this.onTap,
  });
  final AppNavItem item;
  final bool selected;
  final bool collapsed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = selected ? scheme.primaryContainer : Colors.transparent;
    final fg = selected
        ? scheme.onPrimaryContainer
        : scheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Tooltip(
            message: item.label,
            preferBelow: false,
            waitDuration: const Duration(milliseconds: 500),
            child: SizedBox(
              height: 48,
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  Icon(
                    selected ? item.selectedIcon : item.icon,
                    color: fg,
                    size: 24,
                  ),
                  if (!collapsed) ...[
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        item.label,
                        style: TextStyle(
                          color: fg,
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  const SizedBox(width: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Mobile drawer wrapper. Hosts AppSidebar inside a standard Drawer.
class AppDrawer extends StatelessWidget {
  const AppDrawer({
    super.key,
    required this.items,
    required this.selectedPath,
    required this.onSelected,
  });
  final List<AppNavItem> items;
  final String selectedPath;
  final ValueChanged<AppNavItem> onSelected;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SizedBox(
        width: 280,
        child: AppSidebar(
          items: items,
          selectedPath: selectedPath,
          onSelected: (item) {
            Navigator.of(context).pop(); // close drawer before navigating
            onSelected(item);
          },
        ),
      ),
    );
  }
}
