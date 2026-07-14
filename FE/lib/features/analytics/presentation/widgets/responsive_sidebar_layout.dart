import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import 'analytics_sidebar.dart';

/// Responsive wrapper that renders an [AnalyticsSidebar] beside the page
/// content on wide screens (>= 900px).
///
/// Mobile uses the normal page content only so the filter panel does not
/// slide over the dashboard.
class ResponsiveSidebarLayout extends StatelessWidget {
  const ResponsiveSidebarLayout({
    super.key,
    required this.content,
    this.breakpoint = 900,
  });

  final Widget content;

  /// Pixel width at which the layout switches to inline desktop filters.
  /// Below this width the page renders without the analytics filter panel.
  final double breakpoint;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= breakpoint;
        return isWide ? _WideLayout(content: content) : content;
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
      color: isDark
          ? AppColors.surfaceContainerDark
          : AppColors.surfaceContainerLight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnalyticsSidebar(
            expanded: expanded,
            onToggle: () => ref.read(sidebarExpandedProvider.notifier).toggle(),
          ),
          Expanded(child: content),
        ],
      ),
    );
  }
}
