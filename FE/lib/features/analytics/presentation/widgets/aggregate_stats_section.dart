import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/bento_card.dart';
import '../../domain/models/analytics_models.dart';

class AggregateStatsSection extends StatelessWidget {
  const AggregateStatsSection({super.key, required this.data});

  final AggregateDashboardModel data;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final isWide = c.maxWidth > 600;
        final stats = [
          _StatItem('Chiến dịch', '${data.totalCampaigns}', Icons.campaign_outlined, AppColors.chartColors[0]),
          _StatItem('Sự kiện', '${data.totalEvents}', Icons.event_outlined, AppColors.chartColors[1]),
          _StatItem('Trường học', '${data.totalSchools}', Icons.school_outlined, AppColors.chartColors[2]),
          _StatItem('Tương tác', '${data.totalInteractions}', Icons.chat_outlined, AppColors.chartColors[3]),
        ];

        if (isWide) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final s in stats)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minWidth: 120),
                        child: _StatCard(item: s),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }

        // Mobile: horizontal stat row — compact bars
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              for (final s in stats) Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: _MobileStatBar(item: s))),
            ],
          ),
        );
      },
    );
  }
}

class _StatItem {
  const _StatItem(this.title, this.value, this.icon, this.color);
  final String title;
  final String value;
  final IconData icon;
  final Color color;
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.item});
  final _StatItem item;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BentoCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(item.icon, color: item.color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            item.value,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.title,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileStatBar extends StatelessWidget {
  const _MobileStatBar({required this.item});
  final _StatItem item;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BentoCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(item.icon, color: item.color, size: 20),
          const SizedBox(height: 8),
          Text(
            item.value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            item.title,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
