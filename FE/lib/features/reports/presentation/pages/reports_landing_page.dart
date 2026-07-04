import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/bento_card.dart';

class ReportsLandingPage extends ConsumerWidget {
  const ReportsLandingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;

    final types = <_ReportTypeInfo>[
      _ReportTypeInfo(
        type: 'CAMPAIGN',
        title: 'Báo cáo chiến dịch',
        subtitle: 'Tổng hợp chiến dịch, sự kiện, trường, nhân viên, đăng ký, tương tác',
        icon: Icons.campaign_outlined,
        color: AppColors.primary,
        route: '/reports/campaign',
      ),
      _ReportTypeInfo(
        type: 'EVENT',
        title: 'Báo cáo sự kiện',
        subtitle: 'Chi tiết theo sự kiện: trường tham gia, nhân sự, tương tác',
        icon: Icons.event_outlined,
        color: AppColors.tertiary,
        route: '/reports/event',
      ),
      _ReportTypeInfo(
        type: 'SCHOOL',
        title: 'Báo cáo trường học',
        subtitle: 'Hoạt động của một trường: sự kiện đã tổ chức, tương tác đã ghi',
        icon: Icons.school_outlined,
        color: AppColors.warning,
        route: '/reports/school',
      ),
      _ReportTypeInfo(
        type: 'REGION',
        title: 'Báo cáo vùng miền',
        subtitle: 'Theo tỉnh/thành: số trường, số sự kiện, số tương tác',
        icon: Icons.location_on_outlined,
        color: AppColors.info,
        route: '/reports/region',
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Báo cáo PDF')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Chọn loại báo cáo',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Mỗi loại báo cáo có một bộ lọc riêng và các biểu đồ tương ứng được nhúng vào PDF.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            LayoutBuilder(builder: (context, c) {
              final cols = c.maxWidth >= 1100 ? 4 : c.maxWidth >= 700 ? 2 : 1;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: types
                    .map((t) => SizedBox(
                          width: cols == 1 ? double.infinity : (c.maxWidth - (cols - 1) * 16) / cols,
                          child: _ReportTypeCard(info: t),
                        ))
                    .toList(),
              );
            }),
            const SizedBox(height: 24),
            Text(
              'Lưu ý',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Báo cáo PDF được tạo ở chế độ nền. Khi sẵn sàng, bạn có thể tải xuống từ trang chi tiết của từng báo cáo.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportTypeInfo {
  const _ReportTypeInfo({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.route,
  });

  final String type;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String route;
}

class _ReportTypeCard extends StatelessWidget {
  const _ReportTypeCard({required this.info});

  final _ReportTypeInfo info;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return BentoCard(
      padding: const EdgeInsets.all(20),
      onTap: () => context.push(info.route),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: info.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(info.icon, color: info.color, size: 28),
          ),
          const SizedBox(height: 16),
          Text(info.title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(info.subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 6,
              children: [
                _Pill(text: info.type, color: info.color),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.color});
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}