import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/bento_card.dart';
import '../../data/repositories/report_repository.dart';
import '../../domain/models/report_models.dart';
import '../providers/report_filter_providers.dart';
import '../widgets/report_form_scaffold.dart';

class EventReportTypePage extends ConsumerWidget {
  const EventReportTypePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = <ReportFilterDescriptor>[
      ReportFilterDescriptor(
        key: 'campaignId',
        label: 'Chiến dịch',
        initial: null,
        build: (values, enabled, onChanged) => _CampaignField(
          value: values['campaignId'] as CampaignSummary?,
          enabled: enabled,
          onChanged: (value) => onChanged(value),
        ),
      ),
      ReportFilterDescriptor(
        key: 'eventType',
        label: 'Loại sự kiện',
        initial: null,
        build: (values, enabled, onChanged) => _ChoiceField(
          label: 'Loại sự kiện',
          value: values['eventType'] as String?,
          enabled: enabled,
          items: const ['WORKSHOP', 'SEMINAR', 'MEETING', 'FIELD_TRIP', 'TRAINING', 'OTHER'],
          onChanged: (value) => onChanged(value),
        ),
      ),
      ReportFilterDescriptor(
        key: 'employeeId',
        label: 'Nhân viên',
        initial: null,
        build: (values, enabled, onChanged) => _EmployeeField(
          value: values['employeeId'] as EmployeeSummary?,
          enabled: enabled,
          onChanged: (value) => onChanged(value),
        ),
      ),
    ];

    return ReportFormScaffold(
      reportType: 'EVENT',
      title: 'Báo cáo sự kiện',
      sections: CampaignReportRequest.eventSections,
      filters: filters,
      chartSpecs: [
        ChartSpec(section: 'summary', builder: (ctx) => const _EventChartPreview()),
        ChartSpec(section: 'interactions', builder: (ctx) => const _EventInteractionsPreview()),
      ],
    );
  }
}

class _CampaignField extends ConsumerWidget {
  const _CampaignField({required this.value, required this.enabled, required this.onChanged});

  final CampaignSummary? value;
  final bool enabled;
  final ValueChanged<CampaignSummary?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(reportCampaignsProvider);
    return async.when(
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

class _EmployeeField extends ConsumerWidget {
  const _EmployeeField({required this.value, required this.enabled, required this.onChanged});

  final EmployeeSummary? value;
  final bool enabled;
  final ValueChanged<EmployeeSummary?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(reportEmployeesProvider);
    return async.when(
      data: (items) => DropdownButtonFormField<EmployeeSummary?>(
        value: items.any((e) => e.id == value?.id) ? value : null,
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: 'Nhân viên',
          prefixIcon: Icon(Icons.person_outlined),
          border: OutlineInputBorder(),
        ),
        items: [
          const DropdownMenuItem<EmployeeSummary?>(value: null, child: Text('Tất cả nhân viên')),
          ...items.map((e) => DropdownMenuItem<EmployeeSummary?>(value: e, child: Text('${e.name} (${e.role})', overflow: TextOverflow.ellipsis))),
        ],
        onChanged: enabled ? onChanged : null,
      ),
      loading: () => const _LoadingField(label: 'Nhân viên'),
      error: (_, __) => _LoadErrorField(label: 'Nhân viên', onRetry: () => ref.invalidate(reportEmployeesProvider)),
    );
  }
}

class _ChoiceField extends StatelessWidget {
  const _ChoiceField({required this.label, required this.value, required this.enabled, required this.items, required this.onChanged});

  final String label;
  final String? value;
  final bool enabled;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String?>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.tune),
        border: const OutlineInputBorder(),
      ),
      items: [
        DropdownMenuItem<String?>(value: null, child: Text('Tất cả ${label.toLowerCase()}')),
        ...items.map((e) => DropdownMenuItem<String?>(value: e, child: Text(e))),
      ],
      onChanged: enabled ? onChanged : null,
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

class _EventChartPreview extends StatelessWidget {
  const _EventChartPreview();

  @override
  Widget build(BuildContext context) {
    return BentoCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tổng quan sự kiện', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          const Spacer(),
          Center(child: Icon(Icons.event_outlined, size: 36, color: Theme.of(context).colorScheme.tertiary)),
        ],
      ),
    );
  }
}

class _EventInteractionsPreview extends StatelessWidget {
  const _EventInteractionsPreview();

  @override
  Widget build(BuildContext context) {
    return BentoCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tương tác theo sự kiện', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          const Spacer(),
          Center(child: Icon(Icons.bar_chart_outlined, size: 36, color: Theme.of(context).colorScheme.primary)),
        ],
      ),
    );
  }
}
