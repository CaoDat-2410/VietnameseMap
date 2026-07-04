import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/bento_card.dart';
import '../../domain/models/report_models.dart';
import '../widgets/report_form_scaffold.dart';

class RegionReportTypePage extends StatelessWidget {
  const RegionReportTypePage({super.key});

  @override
  Widget build(BuildContext context) {
    final filters = <ReportFilterDescriptor>[
      ReportFilterDescriptor(
        key: 'provinceCode',
        label: 'Tỉnh/Thành phố',
        initial: null,
        build: (values, enabled, onChanged) => DropdownButtonFormField<String>(
          value: values['provinceCode'] as String?,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Tỉnh/Thành phố',
            prefixIcon: Icon(Icons.location_on_outlined),
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem<String>(value: null, child: Text('Tất cả tỉnh/thành')),
            DropdownMenuItem<String>(value: '01', child: Text('Ha Noi')),
            DropdownMenuItem<String>(value: '77', child: Text('Ho Chi Minh')),
            DropdownMenuItem<String>(value: '48', child: Text('Da Nang')),
            DropdownMenuItem<String>(value: '92', child: Text('An Giang')),
          ],
          onChanged: enabled ? onChanged : null,
        ),
      ),
      ReportFilterDescriptor(
        key: 'fromDate',
        label: 'Từ ngày',
        initial: null,
        build: (values, enabled, onChanged) => _DateField(value: values['fromDate'] as DateTime?, enabled: enabled, onChanged: onChanged),
      ),
      ReportFilterDescriptor(
        key: 'toDate',
        label: 'Đến ngày',
        initial: null,
        build: (values, enabled, onChanged) => _DateField(value: values['toDate'] as DateTime?, enabled: enabled, onChanged: onChanged),
      ),
    ];

    return ReportFormScaffold(
      reportType: 'REGION',
      title: 'Báo cáo vùng miền',
      sections: CampaignReportRequest.regionSections,
      filters: filters,
      chartSpecs: [
        ChartSpec(section: 'summary', builder: (ctx) => _RegionSummaryPreview()),
        ChartSpec(section: 'interactions', builder: (ctx) => _RegionAnalyticsPreview()),
      ],
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({required this.value, required this.enabled, required this.onChanged});
  final DateTime? value;
  final bool enabled;
  final ValueChanged<DateTime?> onChanged;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled
          ? () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: value ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              );
              if (picked != null) onChanged(picked);
            }
          : null,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Ngày',
          prefixIcon: const Icon(Icons.calendar_today_outlined),
          border: const OutlineInputBorder(),
          suffixIcon: value != null
              ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: enabled ? () => onChanged(null) : null)
              : null,
        ),
        child: Text(
          value != null ? '${value!.day.toString().padLeft(2, '0')}/${value!.month.toString().padLeft(2, '0')}/${value!.year}' : 'Chọn ngày',
          style: value == null ? TextStyle(color: Theme.of(context).hintColor) : null,
        ),
      ),
    );
  }
}

class _RegionSummaryPreview extends StatelessWidget {
  const _RegionSummaryPreview();
  @override
  Widget build(BuildContext context) {
    return BentoCard(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tổng quan vùng', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          const Spacer(),
          Center(child: Icon(Icons.public_outlined, size: 36, color: AppColors.info)),
        ],
      ),
    );
  }
}

class _RegionAnalyticsPreview extends StatelessWidget {
  const _RegionAnalyticsPreview();
  @override
  Widget build(BuildContext context) {
    return BentoCard(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Phân tích tương tác vùng', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          const Spacer(),
          Center(child: Icon(Icons.analytics_outlined, size: 36, color: Theme.of(context).colorScheme.primary)),
        ],
      ),
    );
  }
}