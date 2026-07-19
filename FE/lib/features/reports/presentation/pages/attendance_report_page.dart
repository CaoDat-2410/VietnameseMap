import 'package:data_table_2/data_table_2.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/bento_card.dart';
import '../../../analytics/presentation/widgets/base_chart_card.dart';
import '../../../attendance/data/models/attendance_models.dart';
import '../../data/repositories/report_repository.dart';
import '../providers/attendance_report_provider.dart';
import '../providers/report_filter_providers.dart';

class AttendanceReportPage extends ConsumerWidget {
  const AttendanceReportPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final asyncData = ref.watch(attendanceReportDataProvider);

    return Scaffold(
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, viewport) {
            final isCompact = viewport.maxWidth < 700;
            final padding = EdgeInsets.fromLTRB(isCompact ? 16 : 24, 18, isCompact ? 16 : 24, 32);

            return SingleChildScrollView(
              padding: padding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Header(l10n: l10n),
                  const SizedBox(height: 16),
                  _FilterSection(l10n: l10n, isCompact: isCompact),
                  const SizedBox(height: 16),
                  asyncData.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, st) => Center(child: Text('Lỗi: $e')),
                    data: (items) => _ReportContent(items: items, l10n: l10n, isCompact: isCompact),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.l10n});
  final AppLocalizations l10n;

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
            color: AppColors.success.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.access_time_outlined, color: AppColors.success),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Báo cáo chấm công', // fallback to literal if l10n is missing key
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'Tổng hợp giờ làm, check-in/check-out theo nhân viên, chiến dịch, khoảng thời gian',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FilterSection extends ConsumerWidget {
  const _FilterSection({required this.l10n, required this.isCompact});
  final AppLocalizations l10n;
  final bool isCompact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(attendanceReportFilterProvider);

    return BentoCard(
      padding: EdgeInsets.all(isCompact ? 16 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.tune, size: 20, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text('Bộ lọc báo cáo', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildEmployeeFilter(context, ref, filters.employeeId),
              _buildCampaignFilter(context, ref, filters.campaignId),
              _buildDateFilter(context, ref, 'Từ ngày', filters.from, (d) => ref.read(attendanceReportFilterProvider.notifier).state = filters.copyWith(from: d, to: filters.to)), // small hack for 'to' null issue
              _buildDateFilter(context, ref, 'Đến ngày', filters.to, (d) => ref.read(attendanceReportFilterProvider.notifier).state = filters.copyWith(to: d, from: filters.from)),
              _buildStatusFilter(context, ref, filters.status),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeFilter(BuildContext context, WidgetRef ref, int? currentId) {
    final asyncEmployees = ref.watch(reportEmployeesProvider);
    return SizedBox(
      width: isCompact ? double.infinity : 200,
      child: asyncEmployees.when(
        data: (items) => DropdownButtonFormField<int?>(
          initialValue: currentId,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Nhân viên', prefixIcon: Icon(Icons.person_outline), border: OutlineInputBorder()),
          items: [
            const DropdownMenuItem(value: null, child: Text('Tất cả nhân viên')),
            ...items.map((e) => DropdownMenuItem(value: e.id, child: Text(e.name, overflow: TextOverflow.ellipsis))),
          ],
          onChanged: (v) {
            final f = ref.read(attendanceReportFilterProvider);
            ref.read(attendanceReportFilterProvider.notifier).state = f.copyWith(employeeId: v, status: f.status, campaignId: f.campaignId, from: f.from, to: f.to);
          },
        ),
        loading: () => const TextField(enabled: false, decoration: InputDecoration(labelText: 'Nhân viên', border: OutlineInputBorder())),
        error: (_, __) => const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildCampaignFilter(BuildContext context, WidgetRef ref, int? currentId) {
    final asyncCampaigns = ref.watch(reportCampaignsProvider);
    return SizedBox(
      width: isCompact ? double.infinity : 220,
      child: asyncCampaigns.when(
        data: (items) => DropdownButtonFormField<int?>(
          initialValue: currentId,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Chiến dịch', prefixIcon: Icon(Icons.campaign_outlined), border: OutlineInputBorder()),
          items: [
            const DropdownMenuItem(value: null, child: Text('Tất cả chiến dịch')),
            ...items.map((e) => DropdownMenuItem(value: e.id, child: Text(e.name, overflow: TextOverflow.ellipsis))),
          ],
          onChanged: (v) {
            final f = ref.read(attendanceReportFilterProvider);
            ref.read(attendanceReportFilterProvider.notifier).state = AttendanceReportFilter(employeeId: f.employeeId, campaignId: v, status: f.status, from: f.from, to: f.to);
          },
        ),
        loading: () => const TextField(enabled: false, decoration: InputDecoration(labelText: 'Chiến dịch', border: OutlineInputBorder())),
        error: (_, __) => const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildDateFilter(BuildContext context, WidgetRef ref, String label, DateTime? value, ValueChanged<DateTime?> onChanged) {
    return SizedBox(
      width: isCompact ? double.infinity : 180,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: value ?? DateTime.now(),
            firstDate: DateTime(2020),
            lastDate: DateTime(2030),
          );
          if (picked != null) onChanged(picked);
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: const Icon(Icons.calendar_today_outlined),
            border: const OutlineInputBorder(),
            suffixIcon: value != null ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () => onChanged(null)) : null,
          ),
          child: Text(
            value != null ? '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}' : 'Chọn ngày',
            style: value == null ? TextStyle(color: Theme.of(context).hintColor) : null,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusFilter(BuildContext context, WidgetRef ref, String? currentStatus) {
    return SizedBox(
      width: isCompact ? double.infinity : 180,
      child: DropdownButtonFormField<String?>(
        initialValue: currentStatus,
        decoration: const InputDecoration(labelText: 'Trạng thái', prefixIcon: Icon(Icons.info_outline), border: OutlineInputBorder()),
        items: const [
          DropdownMenuItem(value: null, child: Text('Tất cả')),
          DropdownMenuItem(value: 'OPEN', child: Text('Đang mở')),
          DropdownMenuItem(value: 'CLOSED', child: Text('Đã đóng')),
        ],
        onChanged: (v) {
            final f = ref.read(attendanceReportFilterProvider);
            ref.read(attendanceReportFilterProvider.notifier).state = AttendanceReportFilter(employeeId: f.employeeId, campaignId: f.campaignId, status: v, from: f.from, to: f.to);
        },
      ),
    );
  }
}

class _ReportContent extends StatelessWidget {
  const _ReportContent({required this.items, required this.l10n, required this.isCompact});
  final List<AttendanceRecord> items;
  final AppLocalizations l10n;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    int totalMinutes = 0;
    int openCount = 0;
    final Set<String> uniqueDays = {};

    for (final r in items) {
      if (r.workedMinutes != null) totalMinutes += r.workedMinutes!;
      if (r.isOpen) openCount++;
      uniqueDays.add(r.checkInAt.toIso8601String().split('T').first);
    }
    final totalHours = totalMinutes / 60;
    final avgHours = uniqueDays.isNotEmpty ? totalHours / uniqueDays.length : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildKpis(totalHours, avgHours, openCount),
        const SizedBox(height: 16),
        _buildCharts(),
        const SizedBox(height: 16),
        _buildTable(context),
      ],
    );
  }

  Widget _buildKpis(double totalHours, double avgHours, int openCount) {
    final kpis = [
      _KpiData('Tổng bản ghi', items.length.toString(), Icons.list_alt, AppColors.primary),
      _KpiData('Tổng giờ làm', '${totalHours.toStringAsFixed(1)}h', Icons.timer_outlined, AppColors.success),
      _KpiData('TB giờ/ngày', '${avgHours.toStringAsFixed(1)}h', Icons.functions, AppColors.info),
      _KpiData('Phiên đang mở', openCount.toString(), Icons.lock_open, AppColors.warning),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: kpis.map((kpi) {
        return SizedBox(
          width: isCompact ? double.infinity : 200,
          child: BentoCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(kpi.icon, size: 20, color: kpi.color),
                    const SizedBox(width: 8),
                    Text(kpi.label, style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(kpi.value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCharts() {
    return LayoutBuilder(builder: (context, constraints) {
      final columns = constraints.maxWidth >= 800 ? 2 : 1;
      final width = columns == 1 ? constraints.maxWidth : (constraints.maxWidth - 16) / 2;
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          SizedBox(width: width, child: _EmployeeHoursChart(items: items)),
          SizedBox(width: width, child: _CheckInsByDayChart(items: items)),
        ],
      );
    });
  }

  Widget _buildTable(BuildContext context) {
    return BentoCard(
      padding: const EdgeInsets.all(0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Chi tiết bản ghi', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          ),
          SizedBox(
            height: 400,
            child: DataTable2(
              columnSpacing: 12,
              horizontalMargin: 16,
              minWidth: 800,
              headingRowColor: WidgetStatePropertyAll(Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)),
              columns: const [
                DataColumn2(label: Text('Nhân viên'), size: ColumnSize.L),
                DataColumn2(label: Text('Chiến dịch'), size: ColumnSize.L),
                DataColumn2(label: Text('Sự kiện'), size: ColumnSize.M),
                DataColumn2(label: Text('Check-in'), size: ColumnSize.M),
                DataColumn2(label: Text('Check-out'), size: ColumnSize.M),
                DataColumn2(label: Text('Giờ làm'), size: ColumnSize.S, numeric: true),
                DataColumn2(label: Text('Trạng thái'), size: ColumnSize.S),
              ],
              rows: items.map((e) {
                final cIn = '${e.checkInAt.day}/${e.checkInAt.month} ${e.checkInAt.hour.toString().padLeft(2, '0')}:${e.checkInAt.minute.toString().padLeft(2, '0')}';
                final cOut = e.checkOutAt != null ? '${e.checkOutAt!.day}/${e.checkOutAt!.month} ${e.checkOutAt!.hour.toString().padLeft(2, '0')}:${e.checkOutAt!.minute.toString().padLeft(2, '0')}' : '--';
                final hours = e.workedMinutes != null ? (e.workedMinutes! / 60).toStringAsFixed(1) : '--';
                return DataRow(cells: [
                  DataCell(Text(e.employeeName)),
                  DataCell(Text(e.campaignName ?? '--')),
                  DataCell(Text(e.eventName ?? '--')),
                  DataCell(Text(cIn)),
                  DataCell(Text(cOut)),
                  DataCell(Text(hours)),
                  DataCell(Text(e.isOpen ? 'Đang mở' : 'Đã đóng', style: TextStyle(color: e.isOpen ? AppColors.warning : AppColors.success, fontWeight: FontWeight.bold))),
                ]);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiData {
  _KpiData(this.label, this.value, this.icon, this.color);
  final String label;
  final String value;
  final IconData icon;
  final Color color;
}

class _EmployeeHoursChart extends StatelessWidget {
  const _EmployeeHoursChart({required this.items});
  final List<AttendanceRecord> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const BaseChartCard(title: 'Giờ làm theo nhân viên', height: 300, child: ChartEmptyState(message: 'Không có dữ liệu'));

    final map = <String, double>{};
    for (final r in items) {
      if (r.workedMinutes != null) {
        map[r.employeeName] = (map[r.employeeName] ?? 0) + (r.workedMinutes! / 60);
      }
    }
    
    if (map.isEmpty) return const BaseChartCard(title: 'Giờ làm theo nhân viên', height: 300, child: ChartEmptyState(message: 'Chưa có giờ làm'));

    final sorted = map.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(10).toList();

    return BaseChartCard(
      title: 'Giờ làm theo nhân viên (Top 10)',
      height: 300,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: top.first.value * 1.2,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => Theme.of(context).colorScheme.surface,
              getTooltipItem: (group, _, rod, __) {
                return BarTooltipItem(
                  '${top[group.x].key}\n${rod.toY.toStringAsFixed(1)}h',
                  TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (val, _) {
                  final idx = val.toInt();
                  if (idx < 0 || idx >= top.length) return const SizedBox.shrink();
                  final name = top[idx].key.split(' ').last;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(name, style: const TextStyle(fontSize: 10)),
                  );
                },
                reservedSize: 28,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (val, _) => Text(val.toInt().toString(), style: const TextStyle(fontSize: 10)),
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: top.asMap().entries.map((e) {
            return BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: e.value.value,
                  color: AppColors.chartColors[e.key % AppColors.chartColors.length],
                  width: 16,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                )
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _CheckInsByDayChart extends StatelessWidget {
  const _CheckInsByDayChart({required this.items});
  final List<AttendanceRecord> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const BaseChartCard(title: 'Check-in theo ngày', height: 300, child: ChartEmptyState(message: 'Không có dữ liệu'));

    final map = <String, int>{};
    for (final r in items) {
      final date = r.checkInAt.toIso8601String().split('T').first;
      map[date] = (map[date] ?? 0) + 1;
    }

    final sorted = map.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    if (sorted.isEmpty) return const BaseChartCard(title: 'Check-in theo ngày', height: 300, child: ChartEmptyState(message: 'Không có dữ liệu'));

    return BaseChartCard(
      title: 'Check-in theo ngày',
      height: 300,
      child: LineChart(
        LineChartData(
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => Theme.of(context).colorScheme.surface,
              getTooltipItems: (spots) {
                return spots.map((spot) {
                  final date = sorted[spot.x.toInt()].key;
                  return LineTooltipItem(
                    '$date\n${spot.y.toInt()} lượt',
                    TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold),
                  );
                }).toList();
              },
            ),
          ),
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (val, _) {
                  final idx = val.toInt();
                  if (idx < 0 || idx >= sorted.length) return const SizedBox.shrink();
                  // only show max 5 labels
                  if (sorted.length > 5 && idx % (sorted.length ~/ 5) != 0 && idx != sorted.length - 1) return const SizedBox.shrink();
                  final dateStr = sorted[idx].key.substring(5); // MM-dd
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(dateStr, style: const TextStyle(fontSize: 10)),
                  );
                },
                reservedSize: 28,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (val, _) => Text(val.toInt().toString(), style: const TextStyle(fontSize: 10)),
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: sorted.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.value.toDouble())).toList(),
              isCurved: true,
              color: AppColors.primary,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.primary.withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
