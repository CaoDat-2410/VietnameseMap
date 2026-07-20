import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';
import '../../data/models/attendance_models.dart';

String formatAttendanceDuration(int? totalMinutes) {
  if (totalMinutes == null) return '--:--';
  final hours = totalMinutes ~/ 60;
  final minutes = totalMinutes % 60;
  return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
}

Future<void> showAttendanceRecordDetails(
  BuildContext context,
  AttendanceRecord record,
) {
  final isMobile = MediaQuery.sizeOf(context).width < 600;
  if (isMobile) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            0,
            20,
            20 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: AttendanceRecordDetailsContent(record: record),
        ),
      ),
    );
  }

  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      content: SizedBox(
        width: 420,
        child: AttendanceRecordDetailsContent(record: record),
      ),
    ),
  );
}

class AttendanceRecordDetailsContent extends StatelessWidget {
  const AttendanceRecordDetailsContent({
    super.key,
    required this.record,
  });

  final AttendanceRecord record;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd/MM/yyyy \u00B7 HH:mm');
    final duration = record.workedMinutes ??
        (record.checkOutAt?.difference(record.checkInAt).inMinutes);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.receipt_long_outlined,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.attendanceShiftDetails,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            IconButton(
              onPressed: () => Navigator.pop(context),
              tooltip: l10n.close,
              icon: const Icon(Icons.close),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _DetailRow(
          icon: Icons.campaign_outlined,
          label: l10n.campaign,
          value: record.campaignName ?? '--',
        ),
        if (record.eventName != null)
          _DetailRow(
            icon: Icons.event_outlined,
            label: l10n.events,
            value: record.eventName!,
          ),
        _DetailRow(
          icon: Icons.login_outlined,
          label: l10n.attendanceStartedAt,
          value: dateFormat.format(record.checkInAt),
        ),
        _DetailRow(
          icon: Icons.logout_outlined,
          label: l10n.attendanceEndedAt,
          value: record.checkOutAt == null
              ? l10n.attendanceStatusOpenLabel
              : dateFormat.format(record.checkOutAt!),
        ),
        _DetailRow(
          icon: Icons.timer_outlined,
          label: l10n.attendanceDuration,
          value: formatAttendanceDuration(duration),
          emphasize: true,
        ),
        if ((record.checkInNote?.isNotEmpty ?? false) ||
            (record.checkOutNote?.isNotEmpty ?? false))
          _DetailRow(
            icon: Icons.notes_outlined,
            label: l10n.note,
            value: [
              record.checkInNote,
              record.checkOutNote,
            ]
                .whereType<String>()
                .where((value) => value.isNotEmpty)
                .join(' \u00B7 '),
          ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.close),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: (emphasize
                          ? theme.textTheme.titleMedium
                          : theme.textTheme.bodyLarge)
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
