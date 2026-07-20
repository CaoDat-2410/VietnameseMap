import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_spacing.dart';
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
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 560;
              final filterField = SizedBox(
                width: compact ? double.infinity : 240,
                child: DropdownButtonFormField<String?>(
                  key: ValueKey('attendance-filter-${filter.status}'),
                  initialValue: filter.status,
                  decoration: InputDecoration(
                    labelText: l10n.status,
                    prefixIcon: const Icon(Icons.filter_list_rounded),
                    isDense: true,
                  ),
                  items: [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text(l10n.attendanceStatusAll),
                    ),
                    DropdownMenuItem<String?>(
                      value: 'OPEN',
                      child: Text(l10n.attendanceStatusOpenLabel),
                    ),
                    DropdownMenuItem<String?>(
                      value: 'CLOSED',
                      child: Text(l10n.attendanceStatusClosedLabel),
                    ),
                  ],
                  onChanged: (value) {
                    ref.read(attendanceFilterProvider.notifier).state =
                        filter.copyWith(status: value);
                  },
                ),
              );
              final actions = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton.outlined(
                    onPressed: () => ref.invalidate(teamAttendanceProvider),
                    tooltip: l10n.refresh,
                    icon: const Icon(Icons.refresh),
                  ),
                  if (canManage) ...[
                    const SizedBox(width: AppSpacing.sm),
                    FilledButton.icon(
                      onPressed: () => showDialog<void>(
                        context: context,
                        builder: (_) => const AttendanceCreateDialog(),
                      ),
                      icon: const Icon(Icons.add),
                      label: Text(l10n.create),
                    ),
                  ],
                ],
              );

              return Padding(
                padding: const EdgeInsets.all(AppSpacing.cardPadding),
                child: compact
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          filterField,
                          const SizedBox(height: AppSpacing.md),
                          Align(
                            alignment: Alignment.centerRight,
                            child: actions,
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          filterField,
                          const Spacer(),
                          actions,
                        ],
                      ),
              );
            },
          ),
          Expanded(
            child: teamAttendance.when(
              loading: () => Column(
                children: [
                  LinearProgressIndicator(
                    semanticsLabel: l10n.attendanceLoadingStatus,
                  ),
                  const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ],
              ),
              error: (_, __) => _TableMessage(
                icon: Icons.cloud_off_outlined,
                title: l10n.attendanceLoadFailed,
                actionLabel: l10n.retry,
                onAction: () => ref.invalidate(teamAttendanceProvider),
              ),
              data: (page) {
                if (page.items.isEmpty) {
                  return _TableMessage(
                    icon: Icons.groups_2_outlined,
                    title: l10n.attendanceNoTeamRecords,
                    subtitle: l10n.attendanceNoTeamRecordsHint,
                    actionLabel: l10n.refresh,
                    onAction: () => ref.invalidate(teamAttendanceProvider),
                  );
                }

                final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
                return DataTable2(
                  minWidth: 900,
                  columnSpacing: 14,
                  horizontalMargin: 18,
                  headingRowColor: WidgetStatePropertyAll(
                    theme.colorScheme.surfaceContainerHigh,
                  ),
                  columns: [
                    DataColumn2(
                      label: Text(l10n.employees),
                      size: ColumnSize.L,
                    ),
                    DataColumn2(
                      label: Text(l10n.campaign),
                      size: ColumnSize.L,
                    ),
                    DataColumn2(label: Text(l10n.checkIn)),
                    DataColumn2(label: Text(l10n.checkOut)),
                    DataColumn2(
                      label: Text(l10n.workedHours),
                      numeric: true,
                    ),
                    DataColumn2(label: Text(l10n.status)),
                    if (canManage)
                      const DataColumn2(label: Text(''), size: ColumnSize.S),
                  ],
                  rows: page.items.map((record) {
                    final campaign = [
                      record.campaignName,
                      record.eventName,
                    ]
                        .whereType<String>()
                        .where((value) => value.isNotEmpty)
                        .join(' \u00B7 ');
                    return DataRow2(
                      cells: [
                        DataCell(
                          Text(
                            record.employeeName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        DataCell(
                          Text(
                            campaign.isEmpty ? '--' : campaign,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        DataCell(Text(dateFormat.format(record.checkInAt))),
                        DataCell(
                          Text(
                            record.checkOutAt == null
                                ? '--'
                                : dateFormat.format(record.checkOutAt!),
                          ),
                        ),
                        DataCell(
                          Text(
                            record.workedMinutes == null
                                ? '--'
                                : (record.workedMinutes! / 60)
                                    .toStringAsFixed(1),
                          ),
                        ),
                        DataCell(_StatusChip(isOpen: record.isOpen)),
                        if (canManage)
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: l10n.edit,
                                  icon:
                                      const Icon(Icons.edit_outlined, size: 20),
                                  onPressed: () => showDialog<void>(
                                    context: context,
                                    builder: (_) =>
                                        AttendanceEditDialog(record: record),
                                  ),
                                ),
                                IconButton(
                                  tooltip: l10n.delete,
                                  icon: Icon(
                                    Icons.delete_outline,
                                    size: 20,
                                    color: theme.colorScheme.error,
                                  ),
                                  onPressed: () =>
                                      _confirmDelete(context, ref, record.id),
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

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    int recordId,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.confirmDelete),
        content: TextField(
          controller: reasonController,
          autofocus: true,
          maxLength: 500,
          decoration: InputDecoration(
            labelText: '${l10n.deleteReason} *',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              final value = reasonController.text.trim();
              if (value.isNotEmpty) Navigator.pop(dialogContext, value);
            },
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    reasonController.dispose();
    if (reason != null && reason.isNotEmpty) {
      await ref
          .read(attendanceActionsProvider)
          .delete(recordId, reason: reason);
    }
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.isOpen});

  final bool isOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final background = isOpen
        ? theme.colorScheme.tertiaryContainer
        : theme.colorScheme.surfaceContainerHighest;
    final foreground = isOpen
        ? theme.colorScheme.onTertiaryContainer
        : theme.colorScheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: foreground,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isOpen
                ? l10n.attendanceStatusOpenLabel
                : l10n.attendanceStatusClosedLabel,
            style: theme.textTheme.labelMedium?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _TableMessage extends StatelessWidget {
  const _TableMessage({
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 46,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.md),
              OutlinedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.refresh),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
