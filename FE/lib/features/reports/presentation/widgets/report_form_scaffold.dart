import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/bento_card.dart';
import '../../data/chart_to_image.dart';
import '../../data/repositories/report_repository.dart';
import '../../domain/models/report_models.dart';
import '../providers/report_viewmodel.dart';

/// Shared form scaffold for the 4 report types. Each report type page
/// supplies its [reportType], [sections], and the list of [ChartSpec]s
/// to render and embed in the PDF.
class ReportFormScaffold extends ConsumerStatefulWidget {
  const ReportFormScaffold({
    super.key,
    required this.reportType,
    required this.title,
    required this.sections,
    required this.filters,
    required this.chartSpecs,
  });

  final String reportType;
  final String title;
  final List<String> sections;
  final List<ReportFilterDescriptor> filters;
  final List<ChartSpec> chartSpecs;

  @override
  ConsumerState<ReportFormScaffold> createState() => _ReportFormScaffoldState();
}

class _ReportFormScaffoldState extends ConsumerState<ReportFormScaffold> {
  final Map<String, dynamic> _values = {};
  bool _includeArchived = false;

  @override
  void initState() {
    super.initState();
    for (final f in widget.filters) {
      _values[f.key] = f.initial;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(campaignReportViewModelProvider);
    final report = state.valueOrNull;
    final isPending = report?.isPending == true || state.isLoading;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, viewport) {
            final isCompact = viewport.maxWidth < 700;
            final horizontalPadding = isCompact ? 16.0 : 24.0;
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(horizontalPadding, 18, horizontalPadding, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _PageHeader(title: widget.title, reportType: widget.reportType),
                  const SizedBox(height: 16),
                  BentoCard(
                    padding: EdgeInsets.all(isCompact ? 16 : 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _SectionTitle(
                          icon: Icons.tune,
                          title: 'Bộ lọc báo cáo',
                          subtitle: 'Chọn phạm vi dữ liệu trước khi tạo PDF.',
                        ),
                        const SizedBox(height: 14),
                        _buildFilters(isPending),
                        const SizedBox(height: 10),
                        SwitchListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Bao gồm dữ liệu đã lưu trữ'),
                          subtitle: Text(
                            'Bật khi cần xuất cả các bản ghi đã archive.',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                          value: _includeArchived,
                          onChanged: isPending ? null : (v) => setState(() => _includeArchived = v),
                        ),
                        const SizedBox(height: 18),
                        _buildChartsPreview(),
                        const SizedBox(height: 18),
                        Wrap(
                          spacing: 12,
                          runSpacing: 10,
                          children: [
                            FilledButton.icon(
                              onPressed: isPending ? null : _onExport,
                              icon: const Icon(Icons.picture_as_pdf),
                              label: Text(isPending ? 'Đang tạo...' : 'Xuất PDF'),
                            ),
                            if (report?.isReady == true)
                              OutlinedButton.icon(
                                onPressed: _onDownload,
                                icon: const Icon(Icons.download),
                                label: const Text('Tải xuống'),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _StatusPanel(state: state, report: report),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilters(bool isPending) {
    if (widget.filters.isEmpty) {
      return Text(
        'Không có bộ lọc cho loại báo cáo này.',
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }

    return LayoutBuilder(builder: (context, c) {
      final columns = c.maxWidth >= 960
          ? (widget.filters.length >= 3 ? 3 : widget.filters.length)
          : c.maxWidth >= 640
              ? (widget.filters.length >= 2 ? 2 : widget.filters.length)
              : 1;
      final itemWidth = columns == 1 ? c.maxWidth : (c.maxWidth - (columns - 1) * 12) / columns;

      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (final f in widget.filters)
            SizedBox(
              width: itemWidth,
              child: f.build(
                _values,
                !isPending,
                (v) => setState(() => _values[f.key] = v),
              ),
            ),
        ],
      );
    });
  }

  Widget _buildChartsPreview() {
    if (widget.chartSpecs.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionTitle(
          icon: Icons.insert_chart_outlined,
          title: 'Biểu đồ trong PDF',
          subtitle: 'Các preview này sẽ được render thành ảnh và nhúng vào file xuất.',
        ),
        const SizedBox(height: 12),
        LayoutBuilder(builder: (context, c) {
          final columns = c.maxWidth >= 960
              ? (widget.chartSpecs.length >= 3 ? 3 : widget.chartSpecs.length)
              : c.maxWidth >= 620
                  ? (widget.chartSpecs.length >= 2 ? 2 : widget.chartSpecs.length)
                  : 1;
          final itemWidth = columns == 1 ? c.maxWidth : (c.maxWidth - (columns - 1) * 12) / columns;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: widget.chartSpecs
                .map((spec) => SizedBox(
                      width: itemWidth,
                      height: c.maxWidth < 620 ? 168 : 190,
                      child: spec.builder(context),
                    ))
                .toList(),
          );
        }),
      ],
    );
  }

  Future<void> _onExport() async {
    final charts = <String, String>{};
    for (final spec in widget.chartSpecs) {
      final b64 = await ChartToImage.renderToBase64(context: context, chart: spec.builder(context));
      if (b64 != null) charts[spec.section] = b64;
    }
    final request = CampaignReportRequest(
      reportType: widget.reportType,
      campaignId: _intValue('campaignId'),
      eventId: _intValue('eventId'),
      fromDate: _values['fromDate'] as DateTime?,
      toDate: _values['toDate'] as DateTime?,
      eventStatus: _values['eventStatus'] as String?,
      eventType: _values['eventType'] as String?,
      provinceCode: _values['provinceCode'] as String?,
      schoolUid: _values['schoolUid'] is SchoolSummary ? (_values['schoolUid'] as SchoolSummary).uid : _values['schoolUid'] as String?,
      employeeId: _values['employeeId'] is EmployeeSummary ? (_values['employeeId'] as EmployeeSummary).id : _values['employeeId'] as int?,
      registrationStatus: _values['registrationStatus'] as String?,
      interactionOutcome: _values['interactionOutcome'] as String?,
      includeArchived: _includeArchived,
      sections: widget.sections,
      chartImages: charts,
    );
    await ref.read(campaignReportViewModelProvider.notifier).export(request);
  }

  int? _intValue(String key) {
    final value = _values[key];
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is CampaignSummary) return value.id;
    if (value is EmployeeSummary) return value.id;
    return int.tryParse(value.toString());
  }

  Future<void> _onDownload() async {
    final url = await ref.read(campaignReportViewModelProvider.notifier).downloadUrl();
    if (url == null || !mounted) return;
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, webOnlyWindowName: '_blank')) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không thể mở URL tải xuống')));
      }
    }
  }
}

class ReportFilterDescriptor {
  const ReportFilterDescriptor({
    required this.key,
    required this.label,
    required this.initial,
    required this.build,
  });

  final String key;
  final String label;
  final Object? initial;
  final Widget Function(Map<String, dynamic> values, bool enabled, ValueChanged<Object?> onChanged) build;
}

class ChartSpec {
  ChartSpec({required this.section, required this.builder});
  final String section;
  final Widget Function(BuildContext) builder;
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.title, required this.reportType});

  final String title;
  final String reportType;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.picture_as_pdf_outlined, color: scheme.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(
                'Mẫu $reportType - thiết lập bộ lọc, xem nhanh biểu đồ và xuất PDF.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title, required this.subtitle});

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: scheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusPanel extends StatelessWidget {
  const _StatusPanel({required this.state, required this.report});

  final AsyncValue<ReportExport?> state;
  final ReportExport? report;

  @override
  Widget build(BuildContext context) {
    return state.when(
      loading: () => const LinearProgressIndicator(),
      error: (error, _) => _Panel(
        icon: Icons.error_outline,
        iconColor: AppColors.error,
        title: 'Yêu cầu báo cáo thất bại',
        message: error.toString(),
      ),
      data: (value) {
        if (value == null) return const SizedBox.shrink();
        if (value.isPending) {
          return _Panel(
            icon: Icons.hourglass_top,
            iconColor: AppColors.warning,
            title: 'Báo cáo #${value.reportId} đang tạo',
            message: 'Trang này sẽ tự động làm mới.',
          );
        }
        if (value.isFailed) {
          return _Panel(
            icon: Icons.error_outline,
            iconColor: AppColors.error,
            title: 'Báo cáo #${value.reportId} thất bại',
            message: value.errorMessage ?? 'Backend không thể tạo PDF này.',
          );
        }
        return _Panel(
          icon: Icons.check_circle_outline,
          iconColor: AppColors.success,
          title: 'Báo cáo #${value.reportId} đã sẵn sàng',
          message: value.fileName ?? 'PDF đã sẵn sàng để tải xuống.',
        );
      },
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.icon, required this.iconColor, required this.title, required this.message});

  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(message),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
