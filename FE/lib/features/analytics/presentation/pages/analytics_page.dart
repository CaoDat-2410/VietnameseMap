import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../providers/analytics_provider.dart';
import '../widgets/aggregate_stats_section.dart';
import '../widgets/base_chart_card.dart';
import '../widgets/charts_section.dart';
import '../widgets/responsive_sidebar_layout.dart';

class AnalyticsPage extends ConsumerWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(analyticsFilterProvider);
    final aggregateData = ref.watch(aggregateDashboardProvider(filter));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final content = Scaffold(
      backgroundColor: isDark
          ? AppColors.surfaceContainerDark
          : AppColors.surfaceContainerLight,
      body: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Analytics',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tổng quan về chiến dịch và tương tác',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                  ),
                ],
              ),
            ),
          ),

          // KPI Stats
          SliverToBoxAdapter(
            child: aggregateData.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => Padding(
                padding: const EdgeInsets.all(24),
                child: _ErrorDisplay(error: error.toString()),
              ),
              data: (data) => AggregateStatsSection(data: data),
            ),
          ),

          // Charts Grid (filter now lives in the sidebar)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: aggregateData.when(
                loading: () => const _ChartsLoadingPlaceholder(),
                error: (e, _) => _ChartsErrorPlaceholder(
                  error: e.toString(),
                  onRetry: () => ref.invalidate(analyticsFilterProvider),
                ),
                data: (data) => ChartsSection(data: data),
              ),
            ),
          ),
        ],
      ),
    );

    return ResponsiveSidebarLayout(content: content);
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

/// Shimmer placeholder shown while chart data loads.
class _ChartsLoadingPlaceholder extends StatelessWidget {
  const _ChartsLoadingPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        2,
        (i) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: BaseChartCard(
            title: 'Đang tải…',
            height: 200,
            child: const ChartEmptyState(
              message: 'Đang tải dữ liệu phân tích…',
            ),
          ),
        ),
      ),
    );
  }
}

/// Error card with retry button. Shown when chart API fails.
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