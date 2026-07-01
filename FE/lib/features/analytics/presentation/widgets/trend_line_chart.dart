import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/models/analytics_models.dart';

/// Smoothed line chart of daily interactions over time.
class TrendLineChart extends StatelessWidget {
  const TrendLineChart({super.key, required this.points});

  final List<TrendPointModel> points;

  @override
  Widget build(BuildContext context) {
    // Always render - even if empty, show test data
    final testData = points.isEmpty;
    
    // Build data - use test data if real data is empty
    final displayPoints = testData 
        ? _createTestData() 
        : points;
    
    // Calculate maxY
    double maxTotal = 0;
    for (final p in displayPoints) {
      if (p.total > maxTotal) maxTotal = p.total.toDouble();
    }
    
    // Ensure min value of 1 for chart to be visible
    if (maxTotal < 1) maxTotal = 10;
    
    final double maxY = maxTotal * 1.2;
    final double maxX = (displayPoints.length - 1).toDouble();
    final color = testData ? Colors.orange : AppColors.chartColors[0];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Build spots
    final spots = <FlSpot>[];
    for (int i = 0; i < displayPoints.length; i++) {
      spots.add(FlSpot(i.toDouble(), displayPoints[i].total.toDouble()));
    }

    // Calculate interval for x-axis labels
    final int interval = (displayPoints.length / 6).ceil().clamp(1, 30);

    return Column(
      children: [
        if (testData)
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.orange.withValues(alpha: 0.2),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.warning, size: 16, color: Colors.orange),
                SizedBox(width: 8),
                Text('TEST DATA - API returned empty', style: TextStyle(color: Colors.orange, fontSize: 12)),
              ],
            ),
          ),
        Expanded(
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: maxX,
              minY: 0,
              maxY: maxY,
              lineBarsData: [
                LineChartBarData(
                  isCurved: true,
                  curveSmoothness: 0.25,
                  spots: spots,
                  color: color,
                  barWidth: 3,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        color.withValues(alpha: 0.25),
                        color.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ],
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    interval: interval.toDouble(),
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();
                      if (i < 0 || i >= displayPoints.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          DateFormat('d/M').format(displayPoints[i].date),
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark
                                ? AppColors.textTertiaryDark
                                : AppColors.textTertiaryLight,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    interval: maxY / 4,
                    getTitlesWidget: (value, meta) => Text(
                      value.toInt().toString(),
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark
                            ? AppColors.textTertiaryDark
                            : AppColors.textTertiaryLight,
                      ),
                    ),
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) =>
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                  tooltipRoundedRadius: 8,
                  getTooltipItems: (touchedSpots) => touchedSpots.map((s) {
                    final idx = s.x.toInt();
                    if (idx < 0 || idx >= displayPoints.length) return null;
                    final pt = displayPoints[idx];
                    if (pt.total == 0) return null;
                    return LineTooltipItem(
                      '${DateFormat('d MMM').format(pt.date)}\n${pt.total} tương tác',
                      TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  /// Create test data to verify chart rendering
  List<TrendPointModel> _createTestData() {
    final now = DateTime.now();
    return List.generate(7, (i) {
      return TrendPointModel(
        date: now.subtract(Duration(days: 6 - i)),
        total: (i + 1) * 5, // 5, 10, 15, 20, 25, 30, 35
      );
    });
  }
}
