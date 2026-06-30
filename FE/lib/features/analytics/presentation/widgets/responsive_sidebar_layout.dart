import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import 'analytics_sidebar.dart';

/// Responsive wrapper that renders an [AnalyticsSidebar] beside the page
/// content on wide screens (>= 900px) and as a `Drawer` on mobile.
///
/// Mobile users tap the menu button to slide the sidebar in. Wide users get
/// the sidebar inline; the collapse state survives restarts via the
/// underlying `sidebarExpandedProvider`.
class ResponsiveSidebarLayout extends StatelessWidget {
  const ResponsiveSidebarLayout({
    super.key,
    required this.content,
    this.breakpoint = 900,
  });

  final Widget content;

  /// Pixel width at which the layout switches from drawer (mobile) to
  /// inline (desktop). Default 900.
  final double breakpoint;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= breakpoint;
        return isWide ? _WideLayout(content: content) : _MobileLayout(content: content);
      },
    );
  }
}

class _WideLayout extends ConsumerWidget {
  const _WideLayout({required this.content});
  final Widget content;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expanded = ref.watch(sidebarExpandedProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainerLight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnalyticsSidebar(
            expanded: expanded,
            onToggle: () =>
                ref.read(sidebarExpandedProvider.notifier).toggle(),
          ),
          Expanded(child: content),
        ],
      ),
    );
  }
}

class _MobileLayout extends ConsumerStatefulWidget {
  const _MobileLayout({required this.content});
  final Widget content;

  @override
  ConsumerState<_MobileLayout> createState() => _MobileLayoutState();
}

class _MobileLayoutState extends ConsumerState<_MobileLayout> {
  final GlobalKey<ScaffoldState> _scaffoldKey =
      GlobalKey<ScaffoldState>(debugLabel: 'analytics_mobile_scaffold');

  @override
  Widget build(BuildContext context) {
    final expanded = ref.watch(sidebarExpandedProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainerLight,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.transparent,
        drawer: Drawer(
          width: kAnalyticsSidebarExpandedWidth,
          child: AnalyticsSidebar(
            expanded: expanded,
            onToggle: () =>
                ref.read(sidebarExpandedProvider.notifier).toggle(),
            showToggleButton: false,
          ),
        ),
        body: Column(
          children: [
            Material(
              color: Theme.of(context).colorScheme.surface,
              elevation: 1,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: 'Menu',
                        icon: const Icon(Icons.menu),
                        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                      ),
                      Expanded(
                        child: Text(
                          'Analytics',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(child: widget.content),
          ],
        ),
      ),
    );
  }
}