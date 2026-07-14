import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/bento_card.dart';
import '../providers/analytics_provider.dart';
import 'filter_section.dart';

/// Width of the sidebar when expanded.
const double kAnalyticsSidebarExpandedWidth = 280;

/// Width of the sidebar when collapsed (icon-only).
const double kAnalyticsSidebarCollapsedWidth = 72;

/// Sidebar for the Analytics page. On wide screens the page wraps it
/// inline; on mobile it is rendered as a `Drawer` by `ResponsiveSidebarLayout`.
///
/// When collapsed the sidebar shows only icon buttons (filter, reset). When
/// expanded it shows the filter section in full plus a header and reset button.
///
/// Collapse state is persisted in SharedPreferences so the user's preferred
/// layout survives app restarts.
class AnalyticsSidebar extends ConsumerStatefulWidget {
  const AnalyticsSidebar({
    super.key,
    required this.expanded,
    required this.onToggle,
    this.showToggleButton = true,
  });

  /// Whether the sidebar should render in expanded (full) form.
  final bool expanded;

  /// Toggles collapsed/expanded state. No-op when [showToggleButton] is false.
  final VoidCallback onToggle;

  /// Whether to show the inline collapse/expand toggle inside the sidebar.
  /// Hide it when the sidebar is rendered inside a Drawer (mobile).
  final bool showToggleButton;

  @override
  ConsumerState<AnalyticsSidebar> createState() => _AnalyticsSidebarState();
}

class _AnalyticsSidebarState extends ConsumerState<AnalyticsSidebar> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final w = widget.expanded
        ? kAnalyticsSidebarExpandedWidth
        : kAnalyticsSidebarCollapsedWidth;

    return Container(
      width: w,
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surfaceContainerDark
            : AppColors.surfaceContainerLight,
        border: Border(
          right: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: SafeArea(
        child: widget.expanded
            ? _buildExpanded(context, isDark)
            : _buildCollapsed(context, isDark),
      ),
    );
  }

  Widget _buildExpanded(BuildContext context, bool isDark) {
    final filterType = ref.watch(selectedFilterTypeProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header row with title + collapse button
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
          child: Row(
            children: [
              const Icon(Icons.tune, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Bộ lọc',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                ),
              ),
              if (widget.showToggleButton)
                IconButton(
                  icon: const Icon(Icons.menu_open),
                  tooltip: 'Thu gọn',
                  onPressed: widget.onToggle,
                ),
            ],
          ),
        ),
        const Divider(height: 1),
        // Filter body
        Expanded(child: SingleChildScrollView(child: FilterSection())),
        // Footer: reset button
        if (filterType != AnalyticsFilterType.none)
          Padding(
            padding: const EdgeInsets.all(16),
            child: BentoCard(
              padding: const EdgeInsets.symmetric(
                  vertical: 8, horizontal: 12),
              child: InkWell(
                onTap: () {
                  ref.read(selectedFilterTypeProvider.notifier).state =
                      AnalyticsFilterType.none;
                  ref.read(selectedCampaignIdProvider.notifier).state = null;
                  ref.read(selectedCampaignNameProvider.notifier).state = null;
                  ref.read(selectedSchoolUidProvider.notifier).state = null;
                },
                child: Row(
                  children: [
                    Icon(Icons.refresh,
                        size: 18,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight),
                    const SizedBox(width: 8),
                    Text(
                      'Đặt lại bộ lọc',
                      style: TextStyle(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCollapsed(BuildContext context, bool isDark) {
    return Column(
      children: [
        const SizedBox(height: 12),
        if (widget.showToggleButton)
          IconButton(
            icon: const Icon(Icons.menu),
            tooltip: 'Mở rộng',
            onPressed: widget.onToggle,
          ),
        const SizedBox(height: 8),
        const Divider(height: 1),
        IconButton(
          icon: const Icon(Icons.tune),
          tooltip: 'Bộ lọc',
          onPressed: widget.onToggle,
        ),
        const Spacer(),
      ],
    );
  }
}

/// StateNotifier that persists the sidebar's expanded/collapsed state in
/// SharedPreferences. Used by [ResponsiveSidebarLayout].
class SidebarExpandedNotifier extends StateNotifier<bool> {
  SidebarExpandedNotifier() : super(true) {
    _load();
  }

  static const _key = 'analytics.sidebar.expanded';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getBool(_key);
    if (stored != null && stored != state) {
      state = stored;
    }
  }

  Future<void> set(bool value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);
  }

  Future<void> toggle() => set(!state);
}

final sidebarExpandedProvider =
    StateNotifierProvider<SidebarExpandedNotifier, bool>(
        (ref) => SidebarExpandedNotifier());