import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/bento_card.dart';
import '../../data/repositories/report_repository.dart';
import '../../domain/models/report_models.dart';
import '../providers/report_filter_providers.dart';
import '../widgets/report_form_scaffold.dart';

class SchoolReportTypePage extends ConsumerWidget {
  const SchoolReportTypePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = <ReportFilterDescriptor>[
      ReportFilterDescriptor(
        key: 'schoolUid',
        label: 'Trường học',
        initial: null,
        build: (values, enabled, onChanged) => _SchoolField(
          value: values['schoolUid'] as SchoolSummary?,
          enabled: enabled,
          onChanged: (value) => onChanged(value),
        ),
      ),
      ReportFilterDescriptor(
        key: 'provinceCode',
        label: 'Tỉnh/Thành phố',
        initial: null,
        build: (values, enabled, onChanged) => _ProvinceField(
          value: values['provinceCode'] as String?,
          enabled: enabled,
          onChanged: (value) => onChanged(value),
        ),
      ),
    ];

    return ReportFormScaffold(
      reportType: 'SCHOOL',
      title: 'Báo cáo trường học',
      sections: CampaignReportRequest.schoolSections,
      filters: filters,
      chartSpecs: [
        ChartSpec(section: 'summary', builder: (ctx) => const _SchoolSummaryPreview()),
        ChartSpec(section: 'events', builder: (ctx) => const _SchoolEventsPreview()),
      ],
    );
  }
}

class _SchoolField extends ConsumerWidget {
  const _SchoolField({required this.value, required this.enabled, required this.onChanged});

  final SchoolSummary? value;
  final bool enabled;
  final ValueChanged<SchoolSummary?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(reportSchoolsProvider(null));
    return async.when(
      data: (items) => DropdownButtonFormField<SchoolSummary?>(
        value: items.any((s) => s.uid == value?.uid) ? value : null,
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: 'Trường học',
          prefixIcon: Icon(Icons.school_outlined),
          border: OutlineInputBorder(),
        ),
        items: [
          const DropdownMenuItem<SchoolSummary?>(value: null, child: Text('Tất cả trường')),
          ...items.take(50).map((s) => DropdownMenuItem<SchoolSummary?>(value: s, child: Text(s.name, overflow: TextOverflow.ellipsis))),
        ],
        onChanged: enabled ? onChanged : null,
      ),
      loading: () => const _LoadingField(label: 'Trường học'),
      error: (_, __) => _LoadErrorField(label: 'Trường học', onRetry: () => ref.invalidate(reportSchoolsProvider(null))),
    );
  }
}

class _ProvinceField extends StatelessWidget {
  const _ProvinceField({required this.value, required this.enabled, required this.onChanged});

  final String? value;
  final bool enabled;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String?>(
      value: value,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Tỉnh/Thành phố',
        prefixIcon: Icon(Icons.location_on_outlined),
        border: OutlineInputBorder(),
      ),
      items: const [
        DropdownMenuItem<String?>(value: null, child: Text('Tất cả tỉnh/thành')),
        DropdownMenuItem<String?>(value: '01', child: Text('Hà Nội')),
        DropdownMenuItem<String?>(value: '77', child: Text('Hồ Chí Minh')),
        DropdownMenuItem<String?>(value: '48', child: Text('Đà Nẵng')),
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

class _SchoolSummaryPreview extends StatelessWidget {
  const _SchoolSummaryPreview();

  @override
  Widget build(BuildContext context) {
    return BentoCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Hoạt động của trường', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          const Spacer(),
          Center(child: Icon(Icons.school_outlined, size: 36, color: AppColors.warning)),
        ],
      ),
    );
  }
}

class _SchoolEventsPreview extends StatelessWidget {
  const _SchoolEventsPreview();

  @override
  Widget build(BuildContext context) {
    return BentoCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sự kiện đã tổ chức', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          const Spacer(),
          Center(child: Icon(Icons.event_note_outlined, size: 36, color: Theme.of(context).colorScheme.primary)),
        ],
      ),
    );
  }
}
