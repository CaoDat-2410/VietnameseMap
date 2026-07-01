import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../providers/analytics_provider.dart';
import '../widgets/aggregate_stats_section.dart';
import '../widgets/base_chart_card.dart';
import '../widgets/charts_section.dart';
import '../widgets/filter_section.dart';
import '../widgets/responsive_sidebar_layout.dart';

class AnalyticsPage extends ConsumerWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(analyticsFilterProvider);
    final aggregateData = ref.watch(aggregateDashboardProvider(filter));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    final horizontalPadding = isMobile ? 12.0 : 24.0;
    final verticalPadding = isMobile ? 16.0 : 24.0;

    return ResponsiveSidebarLayout(
      content: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                verticalPadding,
                horizontalPadding,
                8,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Analytics',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: isMobile ? 24 : null,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tổng quan về chiến dịch và tương tác',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: isMobile ? 13 : null,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: aggregateData.when(
              loading: () => Padding(
                padding: EdgeInsets.all(horizontalPadding),
                child: const Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => Padding(
                padding: EdgeInsets.all(horizontalPadding),
                child: _ErrorDisplay(error: error.toString()),
              ),
              data: (data) => Padding(
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 24),
                child: AggregateStatsSection(data: data),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                16,
                horizontalPadding,
                0,
              ),
              child: const FilterSection(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(horizontalPadding),
              child: aggregateData.when(
                loading: () => const _ChartsLoadingPlaceholder(),
                error: (e, _) => _ChartsErrorPlaceholder(
                  error: e.toString(),
                  onRetry: () {
                    ref.invalidate(aggregateDashboardProvider(filter));
                    ref.invalidate(trendProvider(filter));
                    ref.invalidate(channelProvider(filter));
                    ref.invalidate(employeeProvider(filter));
                  },
                ),
                data: (data) => ChartsSection(data: data),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorDisplay extends StatelessWidget {
  const _ErrorDisplay({required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Lỗi tải dữ liệu: $error',
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartsLoadingPlaceholder extends StatelessWidget {
  const _ChartsLoadingPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        2,
        (i) => const Padding(
          padding: EdgeInsets.only(bottom: 16),
          child: BaseChartCard(
            title: 'Đang tải...',
            height: 200,
            child: ChartEmptyState(
              message: 'Đang tải dữ liệu phân tích...',
            ),
          ),
        ),
      ),
    );
  }
}

class _ChartsErrorPlaceholder extends StatelessWidget {
  const _ChartsErrorPlaceholder({
    required this.error,
    required this.onRetry,
  });

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return BaseChartCard(
      title: 'Lỗi tải biểu đồ',
      subtitle: error,
      height: 200,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const ChartEmptyState(
            message: 'Không thể tải dữ liệu. Vui lòng thử lại.',
            icon: Icons.error_outline,
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }
}
