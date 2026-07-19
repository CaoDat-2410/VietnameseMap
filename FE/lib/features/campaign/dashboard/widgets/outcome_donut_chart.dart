import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class OutcomeDonutChart extends StatelessWidget {
  const OutcomeDonutChart({super.key, required this.outcomes});

  final Map<String, int> outcomes;

  @override
  Widget build(BuildContext context) {
    final entries = outcomes.entries.where((e) => e.value > 0).toList();
    if (entries.isEmpty) {
      return const _EmptyState(message: 'Chưa có dữ liệu kết quả');
    }

    final total = entries.fold<int>(0, (sum, e) => sum + e.value);

    return LayoutBuilder(
      builder: (context, c) {
        final isNarrow = c.maxWidth < 300;
        if (isNarrow) {
          // Stack: pie on top, legend below
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 140,
                child: AspectRatio(
                  aspectRatio: 1,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 30,
                      sections: [
                        for (int i = 0; i < entries.length; i++)
                          PieChartSectionData(
                            value: entries[i].value.toDouble(),
                            color: AppColors
                                .chartColors[i % AppColors.chartColors.length],
                            radius: 50,
                            title:
                                '${((entries[i].value / total) * 100).round()}%',
                            titleStyle: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ...entries.map((e) => _LegendItem(
                    entry: e,
                    total: total,
                    color: AppColors.chartColors[
                        entries.indexOf(e) % AppColors.chartColors.length],
                  )),
            ],
          );
        }

        // Side by side: pie left, legend right
        return Row(
          children: [
            Expanded(
              child: AspectRatio(
                aspectRatio: 1,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                    sections: [
                      for (int i = 0; i < entries.length; i++)
                        PieChartSectionData(
                          value: entries[i].value.toDouble(),
                          color: AppColors
                              .chartColors[i % AppColors.chartColors.length],
                          radius: 50,
                          title:
                              '${((entries[i].value / total) * 100).round()}%',
                          titleStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (int i = 0; i < entries.length; i++)
                    _LegendItem(
                      entry: entries[i],
                      total: total,
                      color: AppColors
                          .chartColors[i % AppColors.chartColors.length],
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.entry, required this.total, required this.color});
  final MapEntry<String, int> entry;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              entry.key,
              style: const TextStyle(fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '${entry.value}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.donut_small,
            size: 32,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(color: Theme.of(context).colorScheme.outline),
          ),
        ],
      ),
    );
  }
}