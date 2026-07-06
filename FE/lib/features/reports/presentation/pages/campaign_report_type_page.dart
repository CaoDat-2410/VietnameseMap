import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/bento_card.dart';
import '../../data/repositories/report_repository.dart';
import '../../domain/models/report_models.dart';
import '../providers/report_filter_providers.dart';
import '../widgets/report_form_scaffold.dart';

class CampaignReportTypePage extends ConsumerWidget {
  const CampaignReportTypePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = <ReportFilterDescriptor>[
      ReportFilterDescriptor(
        key: 'campaignId',
        label: 'Chiến dịch',
        initial: null,
        build: (values, enabled, onChanged) => _CampaignFilterField(
          value: values['campaignId'] as CampaignSummary?,
          enabled: enabled,
          onChanged: (value) => onChanged(value),
        ),
      ),
      ReportFilterDescriptor(
        key: 'fromDate',
        label: 'Từ ngày',
        initial: null,
        build: (values, enabled, onChanged) => _DateField(
          value: values['fromDate'] as DateTime?,
          enabled: enabled,
          onChanged: (value) => onChanged(value),
        ),
      ),
      ReportFilterDescriptor(
        key: 'toDate',
        label: 'Đến ngày',
        initial: null,
        build: (values, enabled, onChanged) => _DateField(
          value: values['toDate'] as DateTime?,
          enabled: enabled,
          onChanged: (value) => onChanged(value),
        ),
      ),
    ];

    final chartSpecs = <ChartSpec>[
      ChartSpec(section: 'summary', builder: (ctx) => const _SummaryPreview()),
      ChartSpec(section: 'interactions', builder: (ctx) => const _OutcomeDonutPreview()),
    ];

    return ReportFormScaffold(
      reportType: 'CAMPAIGN',
      title: 'Báo cáo chiến dịch',
      sections: CampaignReportRequest.campaignSections,
      filters: filters,
      chartSpecs: chartSpecs,
    );
  }
}

class _CampaignFilterField extends ConsumerWidget {
  const _CampaignFilterField({required this.value, required this.enabled, required this.onChanged});

  final CampaignSummary? value;
  final bool enabled;
  final ValueChanged<CampaignSummary?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final campaignsAsync = ref.watch(reportCampaignsProvider);
    return campaignsAsync.when(
      data: (items) => DropdownButtonFormField<CampaignSummary?>(
        value: items.any((c) => c.id == value?.id) ? value : null,
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: 'Chiến dịch',
          prefixIcon: Icon(Icons.campaign_outlined),
          border: OutlineInputBorder(),
        ),
        items: [
          const DropdownMenuItem<CampaignSummary?>(value: null, child: Text('Tất cả chiến dịch')),
          ...items.map((c) => DropdownMenuItem<CampaignSummary?>(value: c, child: Text(c.name, overflow: TextOverflow.ellipsis))),
        ],
        onChanged: enabled ? onChanged : null,
      ),
      loading: () => const _LoadingField(label: 'Chiến dịch'),
      error: (_, __) => _LoadErrorField(label: 'Chiến dịch', onRetry: () => ref.invalidate(reportCampaignsProvider)),
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
      borderRadius: BorderRadius.circular(8),
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

class _LoadingField extends StatelessWidget {
  const _LoadingField({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return TextField(
      enabled: false,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.hourglass_empty),
        border: const OutlineInputBorder(),
      ),
    );
  }
}

class _LoadErrorField extends StatelessWidget {
  const _LoadErrorField({required this.label, required this.onRetry});

  final String label;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onRetry,
      icon: const Icon(Icons.refresh),
      label: Text('Tải lại $label'),
      style: OutlinedButton.styleFrom(alignment: Alignment.centerLeft, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18)),
    );
  }
}

class _SummaryPreview extends StatelessWidget {
  const _SummaryPreview();

  @override
  Widget build(BuildContext context) {
    return BentoCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('KPI tổng hợp', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          const Text('Sự kiện / Tương tác / Trường / Đăng ký', style: TextStyle(fontSize: 11)),
          const Spacer(),
          Center(child: Icon(Icons.dashboard_outlined, size: 36, color: Theme.of(context).colorScheme.primary)),
        ],
      ),
    );
  }
}

class _OutcomeDonutPreview extends StatelessWidget {
  const _OutcomeDonutPreview();

  @override
  Widget build(BuildContext context) {
    return BentoCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Phân bố kết quả tương tác', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          const Spacer(),
          Center(child: Icon(Icons.donut_large_outlined, size: 36, color: Theme.of(context).colorScheme.tertiary)),
        ],
      ),
    );
  }
}
