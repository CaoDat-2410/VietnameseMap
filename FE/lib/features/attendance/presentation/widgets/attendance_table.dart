import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';
import '../providers/attendance_providers.dart';
import 'attendance_create_dialog.dart';
import 'attendance_edit_dialog.dart';

class AttendanceTable extends ConsumerWidget {
  const AttendanceTable({super.key, required this.canManage});

  final bool canManage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final teamAttendance = ref.watch(teamAttendanceProvider);
    final filter = ref.watch(attendanceFilterProvider);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.attendance,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (canManage)
                  FilledButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => const AttendanceCreateDialog(),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: Text(l10n.create),
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    value: filter.status,
                    decoration: InputDecoration(
                      labelText: l10n.status,
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    items: [
                      DropdownMenuItem(value: null, child: Text(l10n.all)),
                      const DropdownMenuItem(value: 'OPEN', child: Text('OPEN')),
                      const DropdownMenuItem(value: 'CLOSED', child: Text('CLOSED')),
                    ],
                    onChanged: (val) {
                      ref.read(attendanceFilterProvider.notifier).state =
                          filter.copyWith(status: val);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => ref.invalidate(teamAttendanceProvider),
                  tooltip: l10n.refresh,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: teamAttendance.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
              data: (page) {
                if (page.items.isEmpty) {
                  return Center(child: Text(l10n.noData));
                }
                return DataTable2(
                  columnSpacing: 12,
                  horizontalMargin: 16,
                  minWidth: 800,
                  columns: [
                    DataColumn2(label: Text(l10n.employees), size: ColumnSize.L),
                    DataColumn2(label: Text(l10n.campaign), size: ColumnSize.L),
                    DataColumn2(label: Text(l10n.checkIn)),
                    DataColumn2(label: Text(l10n.checkOut)),
                    DataColumn2(label: Text(l10n.workedHours), numeric: true),
                    DataColumn2(label: Text(l10n.status)),
                    if (canManage) const DataColumn2(label: Text(''), size: ColumnSize.S),
                  ],
                  rows: page.items.map((r) {
                    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
                    return DataRow(
                      cells: [
                        DataCell(Text(r.employeeName)),
                        DataCell(Text('${r.campaignName ?? ''}${r.eventName != null ? ' - ${r.eventName}' : ''}')),
                        DataCell(Text(dateFormat.format(r.checkInAt))),
                        DataCell(Text(r.checkOutAt != null ? dateFormat.format(r.checkOutAt!) : '')),
                        DataCell(Text(r.workedMinutes != null ? (r.workedMinutes! / 60).toStringAsFixed(1) : '')),
                        DataCell(
                          Chip(
                            label: Text(r.status, style: const TextStyle(fontSize: 12)),
                            backgroundColor: r.isOpen ? Colors.green.shade100 : Colors.grey.shade200,
                          ),
                        ),
                        if (canManage)
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 20),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (_) => AttendanceEditDialog(record: r),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: Text(l10n.confirmDelete),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx, false),
                                            child: Text(l10n.cancel),
                                          ),
                                          FilledButton(
                                            onPressed: () => Navigator.pop(ctx, true),
                                            child: Text(l10n.delete),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      await ref.read(attendanceActionsProvider).delete(r.id);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                      ],
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
