import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/bento_card.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../domain/models/analytics_models.dart';
import '../providers/analytics_provider.dart';
import 'channel_donut_chart.dart';
import 'employee_bar_chart.dart';
import 'trend_line_chart.dart';
import '../../../campaign/dashboard/widgets/outcome_donut_chart.dart';
import '../../../campaign/dashboard/widgets/province_bar_chart.dart';
import '../../../campaign/dashboard/widgets/top_schools_bar_chart.dart';

/// Breakpoints for responsive layout
class _ResponsiveBreakpoints {
  static const double mobile = 600;
  static const double tablet = 900;
}

/// Responsive chart section widget that adapts to screen size
class ChartsSection extends ConsumerWidget {
  const ChartsSection({super.key, required this.data});

  final AggregateDashboardModel data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(analyticsFilterProvider);
    final trendAsync = ref.watch(trendProvider(filter));
    final channelsAsync = ref.watch(channelProvider(filter));
    final employeesAsync = ref.watch(employeeProvider(filter));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Responsive values based on screen width
    final isMobile = screenWidth < _ResponsiveBreakpoints.mobile;
    final isTablet = screenWidth >= _ResponsiveBreakpoints.mobile && 
                    screenWidth < _ResponsiveBreakpoints.tablet;
    
    // Chart dimensions
    final chartHeight = isMobile ? 180.0 : (isTablet ? 200.0 : 220.0);
    final spacing = isMobile ? 12.0 : 16.0;
    final sectionPadding = isMobile ? 12.0 : (isTablet ? 16.0 : 20.0);

    return Column(
      children: [
        // Row 1: Trend line (full width)
        _buildCard(
          context: context,
          isDark: isDark,
          title: 'Xu hướng tương tác',
          subtitle: '30 ngày qua',
          padding: sectionPadding,
          child: trendAsync.when(
            loading: () => SizedBox(
              height: chartHeight,
              child: const Center(child: CircularProgressIndicator()),
            ),
            error: (e, stack) => SizedBox(
              height: chartHeight,
              child: Center(child: Text('Lỗi: $e')),
            ),
            data: (pts) => SizedBox(
              height: chartHeight,
              child: TrendLineChart(points: pts),
            ),
          ),
        ),
        SizedBox(height: spacing),

        // Row 2: Outcome donut + Channel donut
        if (screenWidth >= _ResponsiveBreakpoints.tablet)
          _buildRow(
            isDark: isDark,
            spacing: spacing,
            padding: sectionPadding,
            chartHeight: chartHeight,
            children: [
              _buildDonutCard(
                context: context,
                isDark: isDark,
                padding: sectionPadding,
                chartHeight: chartHeight,
                title: 'Tương tác theo kết quả',
                child: OutcomeDonutChart(outcomes: data.interactionsByOutcome),
              ),
              _buildDonutCard(
                context: context,
                isDark: isDark,
                padding: sectionPadding,
                chartHeight: chartHeight,
                title: 'Tương tác theo kênh',
                subtitle: 'PHONE / EMAIL / ZALO / VISIT / EVENT',
                child: channelsAsync.when(
                  loading: () => const _ChartSkeleton(),
                  error: (e, _) => _ChartError(
                    message: '$e',
                    onRetry: () => ref.invalidate(channelProvider(filter)),
                  ),
                  data: (cs) => ChannelDonutChart(channels: cs),
                ),
              ),
            ],
          )
        else
          Column(
            children: [
              _buildDonutCard(
                context: context,
                isDark: isDark,
                padding: sectionPadding,
                chartHeight: chartHeight,
                title: 'Tương tác theo kết quả',
                child: OutcomeDonutChart(outcomes: data.interactionsByOutcome),
              ),
              SizedBox(height: spacing),
              _buildDonutCard(
                context: context,
                isDark: isDark,
                padding: sectionPadding,
                chartHeight: chartHeight,
                title: 'Tương tác theo kênh',
                subtitle: 'PHONE / EMAIL / ZALO / VISIT / EVENT',
                child: channelsAsync.when(
                  loading: () => const _ChartSkeleton(),
                  error: (e, _) => _ChartError(
                    message: '$e',
                    onRetry: () => ref.invalidate(channelProvider(filter)),
                  ),
                  data: (cs) => ChannelDonutChart(channels: cs),
                ),
              ),
            ],
          ),
        SizedBox(height: spacing),

        // Row 3: Province bar + Top schools
        if (screenWidth >= _ResponsiveBreakpoints.tablet)
          _buildRow(
            isDark: isDark,
            spacing: spacing,
            padding: sectionPadding,
            chartHeight: chartHeight,
            children: [
              _buildBarChartCard(
                context: context,
                isDark: isDark,
                padding: sectionPadding,
                chartHeight: chartHeight,
                title: 'Tương tác theo tỉnh/thành',
                child: ProvinceBarChart(items: data.interactionsByProvince),
              ),
              _buildBarChartCard(
                context: context,
                isDark: isDark,
                padding: sectionPadding,
                chartHeight: chartHeight,
                title: 'Top trường học',
                child: TopSchoolsBarChart(items: data.topSchools),
              ),
            ],
          )
        else
          Column(
            children: [
              _buildBarChartCard(
                context: context,
                isDark: isDark,
                padding: sectionPadding,
                chartHeight: chartHeight,
                title: 'Tương tác theo tỉnh/thành',
                child: ProvinceBarChart(items: data.interactionsByProvince),
              ),
              SizedBox(height: spacing),
              _buildBarChartCard(
                context: context,
                isDark: isDark,
                padding: sectionPadding,
                chartHeight: chartHeight,
                title: 'Top trường học',
                child: TopSchoolsBarChart(items: data.topSchools),
              ),
            ],
          ),
        SizedBox(height: spacing),

        // Row 4: Top employees (full width)
        _buildCard(
          context: context,
          isDark: isDark,
          title: 'Top nhân viên',
          subtitle: 'Xếp hạng theo số tương tác',
          padding: sectionPadding,
          child: employeesAsync.when(
            loading: () => const _ChartSkeleton(),
            error: (e, _) => _ChartError(
              message: '$e',
              onRetry: () => ref.invalidate(employeeProvider(filter)),
            ),
            data: (emps) => SizedBox(
              height: chartHeight,
              child: EmployeeBarChart(employees: emps),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRow({
    required bool isDark,
    required double spacing,
    required double padding,
    required double chartHeight,
    required List<Widget> children,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < children.length; i++) ...[
          Expanded(child: children[i]),
          if (i < children.length - 1) SizedBox(width: spacing),
        ],
      ],
    );
  }

  Widget _buildCard({
    required BuildContext context,
    required bool isDark,
    required String title,
    String? subtitle,
    required double padding,
    required Widget child,
  }) {
    return BentoCard(
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
                  ),
            ),
          ],
          SizedBox(height: padding),
          child,
        ],
      ),
    );
  }

  Widget _buildDonutCard({
    required BuildContext context,
    required bool isDark,
    required double padding,
    required double chartHeight,
    required String title,
    String? subtitle,
    required Widget child,
  }) {
    return _buildCard(
      context: context,
      isDark: isDark,
      title: title,
      subtitle: subtitle,
      padding: padding,
      child: SizedBox(
        height: chartHeight,
        child: child,
      ),
    );
  }

  Widget _buildBarChartCard({
    required BuildContext context,
    required bool isDark,
    required double padding,
    required double chartHeight,
    required String title,
    required Widget child,
  }) {
    return _buildCard(
      context: context,
      isDark: isDark,
      title: title,
      padding: padding,
      child: SizedBox(
        height: chartHeight,
        child: child,
      ),
    );
  }
}

class _ChartSkeleton extends StatelessWidget {
  const _ChartSkeleton();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 200,
      child: ShimmerCard(),
    );
  }
}

class _ChartError extends ConsumerWidget {
  const _ChartError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 200,
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Lỗi: $message',
              style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}
