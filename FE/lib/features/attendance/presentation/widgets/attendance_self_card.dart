import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/attendance_models.dart';
import '../providers/attendance_providers.dart';
import 'attendance_record_details.dart';

class AttendanceSelfCard extends ConsumerStatefulWidget {
  const AttendanceSelfCard({super.key});

  @override
  ConsumerState<AttendanceSelfCard> createState() => _AttendanceSelfCardState();
}

class _AttendanceSelfCardState extends ConsumerState<AttendanceSelfCard> {
  final _noteController = TextEditingController();
  int? _selectedCampaignId;
  int? _selectedEventId;
  bool _isLoading = false;
  bool _noteExpanded = false;
  AttendanceRecord? _lastCompleted;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _noteController.dispose();
    super.dispose();
  }

  String _errorMessage(DioException error, AppLocalizations l10n) {
    final code = error.response?.statusCode;
    final serverMessage = error.response?.data?['message']?.toString();
    return switch (code) {
      409 when serverMessage?.contains('open for check-in') == true =>
        l10n.campaignNotOpenForCheckIn,
      409 => l10n.alreadyCheckedIn,
      403 => l10n.notAssignedAttendanceTarget,
      404 => l10n.noActiveCampaign,
      400 => l10n.employeeNotLinked,
      _ => serverMessage ?? l10n.attendanceActionFailed,
    };
  }

  void _showFeedback(String message, {bool isError = false}) {
    final messenger = ScaffoldMessenger.of(context);
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                isError ? Icons.error_outline : Icons.check_circle_outline,
                color: isError
                    ? Theme.of(context).colorScheme.onErrorContainer
                    : Theme.of(context).colorScheme.onInverseSurface,
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(message)),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          width: isMobile ? null : 420,
          margin: isMobile ? const EdgeInsets.all(16) : null,
        ),
      );
  }

  Future<void> _handleCheckIn() async {
    if (_selectedCampaignId == null) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isLoading = true);
    try {
      await ref.read(attendanceActionsProvider).checkIn(
            campaignId: _selectedCampaignId!,
            eventId: _selectedEventId,
            note: _noteValue,
          );
      if (!mounted) return;
      _noteController.clear();
      setState(() {
        _selectedCampaignId = null;
        _selectedEventId = null;
        _noteExpanded = false;
      });
      _showFeedback(l10n.checkInSuccess);
    } on DioException catch (error) {
      if (!mounted) return;
      _showFeedback(_errorMessage(error, l10n), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleCheckOut(AttendanceRecord record) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await _confirmCheckOut(record);
    if (confirmed != true || !mounted) return;

    setState(() => _isLoading = true);
    try {
      final completed =
          await ref.read(attendanceActionsProvider).checkOut(note: _noteValue);
      if (!mounted) return;
      _noteController.clear();
      setState(() {
        _lastCompleted = completed;
        _noteExpanded = false;
      });
    } on DioException catch (error) {
      if (!mounted) return;
      final code = error.response?.statusCode;
      final serverMessage = error.response?.data?['message']?.toString();
      final message = switch (code) {
        409 => l10n.noOpenSessionToCheckOut,
        400 => l10n.employeeNotLinked,
        _ => serverMessage ?? l10n.attendanceActionFailed,
      };
      _showFeedback(message, isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String? get _noteValue {
    final value = _noteController.text.trim();
    return value.isEmpty ? null : value;
  }

  Future<bool?> _confirmCheckOut(AttendanceRecord record) {
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    if (isMobile) {
      return showModalBottomSheet<bool>(
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
            child: _CheckoutConfirmationContent(record: record),
          ),
        ),
      );
    }

    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
        content: SizedBox(
          width: 430,
          child: _CheckoutConfirmationContent(record: record),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final myAttendance = ref.watch(myAttendanceProvider);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          if (_isLoading)
            LinearProgressIndicator(
              minHeight: 3,
              semanticsLabel: l10n.attendanceLoadingStatus,
            ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.cardPaddingSpacious),
            child: myAttendance.when(
              loading: () => _LoadingState(
                label: l10n.attendanceLoadingStatus,
              ),
              error: (_, __) => _ErrorState(
                message: l10n.attendanceLoadFailed,
                retry: () => ref.invalidate(myAttendanceProvider),
              ),
              data: (page) {
                final latest = page.items.isEmpty ? null : page.items.first;
                final openRecord = latest?.isOpen == true ? latest : null;
                return AnimatedSwitcher(
                  duration: reduceMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 180),
                  child: openRecord == null
                      ? _buildReadyView(context, l10n)
                      : _buildActiveView(context, l10n, openRecord),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadyView(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    final targets = ref.watch(eligibleAttendanceTargetsProvider);

    return Column(
      key: const ValueKey('attendance-ready'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_lastCompleted != null) ...[
          _SuccessPanel(
            record: _lastCompleted!,
            onDismiss: () => setState(() => _lastCompleted = null),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        _StatusHeader(
          icon: Icons.play_arrow_rounded,
          title: l10n.attendanceReadyTitle,
          subtitle: l10n.noOpenSession,
          background: theme.colorScheme.primaryContainer,
          foreground: theme.colorScheme.onPrimaryContainer,
        ),
        const SizedBox(height: AppSpacing.xl),
        targets.when(
          loading: () => _LoadingState(
            label: l10n.attendanceLoadingTargets,
            compact: true,
          ),
          error: (_, __) => _ErrorState(
            message: l10n.attendanceTargetsLoadFailed,
            retry: () => ref.invalidate(eligibleAttendanceTargetsProvider),
            compact: true,
          ),
          data: (items) {
            final campaigns = {
              for (final target in items)
                target.campaignId: target.campaignName,
            };
            final events = items
                .where((target) => target.campaignId == _selectedCampaignId)
                .toList();

            if (campaigns.isEmpty) {
              return _InlineMessage(
                icon: Icons.assignment_late_outlined,
                message: l10n.noAssignedAttendanceTarget,
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<int>(
                  key: ValueKey('campaign-$_selectedCampaignId'),
                  initialValue: _selectedCampaignId,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: l10n.selectCampaign,
                    prefixIcon: const Icon(Icons.campaign_outlined),
                  ),
                  items: campaigns.entries
                      .map(
                        (entry) => DropdownMenuItem<int>(
                          value: entry.key,
                          child: Text(
                            entry.value,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: _isLoading
                      ? null
                      : (value) => setState(() {
                            _selectedCampaignId = value;
                            _selectedEventId = null;
                          }),
                ),
                if (_selectedCampaignId != null && events.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.base),
                  DropdownButtonFormField<int>(
                    key: ValueKey(
                        'event-$_selectedCampaignId-$_selectedEventId'),
                    initialValue: _selectedEventId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: l10n.selectEventOptional,
                      prefixIcon: const Icon(Icons.event_outlined),
                    ),
                    items: [
                      DropdownMenuItem<int>(
                        value: null,
                        child: Text(l10n.attendanceNoEvent),
                      ),
                      ...events.map(
                        (event) => DropdownMenuItem<int>(
                          value: event.eventId,
                          child: Text(
                            event.eventName,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                    onChanged: _isLoading
                        ? null
                        : (value) => setState(() => _selectedEventId = value),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                _NoteSection(
                  expanded: _noteExpanded,
                  controller: _noteController,
                  onToggle: () =>
                      setState(() => _noteExpanded = !_noteExpanded),
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  height: AppSpacing.touchTargetPreferred,
                  child: FilledButton.icon(
                    onPressed: _isLoading || _selectedCampaignId == null
                        ? null
                        : _handleCheckIn,
                    icon: const Icon(Icons.login_rounded),
                    label: Text(l10n.checkIn),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildActiveView(
    BuildContext context,
    AppLocalizations l10n,
    AttendanceRecord record,
  ) {
    final theme = Theme.of(context);
    final elapsed = DateTime.now().difference(record.checkInAt);
    final startedAt =
        DateFormat('dd/MM/yyyy \u00B7 HH:mm').format(record.checkInAt);

    return Column(
      key: const ValueKey('attendance-active'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StatusHeader(
          icon: Icons.bolt_rounded,
          title: l10n.attendanceStatusOpen,
          subtitle: record.campaignName ?? '--',
          background: theme.colorScheme.tertiaryContainer,
          foreground: theme.colorScheme.onTertiaryContainer,
        ),
        const SizedBox(height: AppSpacing.xl),
        _SummaryRow(
          icon: Icons.campaign_outlined,
          label: l10n.campaign,
          value: record.campaignName ?? '--',
        ),
        if (record.eventName != null)
          _SummaryRow(
            icon: Icons.event_outlined,
            label: l10n.events,
            value: record.eventName!,
          ),
        _SummaryRow(
          icon: Icons.schedule_outlined,
          label: l10n.attendanceStartedAt,
          value: startedAt,
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Column(
            children: [
              Text(
                l10n.attendanceDuration,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                formatAttendanceDuration(elapsed.inMinutes),
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _NoteSection(
          expanded: _noteExpanded,
          controller: _noteController,
          onToggle: () => setState(() => _noteExpanded = !_noteExpanded),
        ),
        const SizedBox(height: AppSpacing.lg),
        SizedBox(
          height: AppSpacing.touchTargetPreferred,
          child: FilledButton.icon(
            onPressed: _isLoading ? null : () => _handleCheckOut(record),
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.onSurface,
              foregroundColor: theme.colorScheme.surface,
            ),
            icon: const Icon(Icons.logout_rounded),
            label: Text(l10n.attendanceEndShift),
          ),
        ),
      ],
    );
  }
}

class _StatusHeader extends StatelessWidget {
  const _StatusHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.background,
    required this.foreground,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: foreground.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            ),
            child: Icon(icon, color: foreground),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: foreground.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NoteSection extends StatelessWidget {
  const _NoteSection({
    required this.expanded,
    required this.controller,
    required this.onToggle,
  });

  final bool expanded;
  final TextEditingController controller;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: onToggle,
            icon:
                Icon(expanded ? Icons.expand_less : Icons.add_comment_outlined),
            label: Text(
              expanded ? l10n.attendanceHideNote : l10n.attendanceAddNote,
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox(width: double.infinity),
          secondChild: Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: TextField(
              controller: controller,
              maxLines: 2,
              maxLength: 500,
              decoration: InputDecoration(
                labelText: l10n.note,
                hintText: l10n.attendanceCorrectionNote,
                prefixIcon: const Icon(Icons.notes_outlined),
              ),
            ),
          ),
          crossFadeState:
              expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 180),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: AppSpacing.iconBase,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: AppSpacing.md),
          SizedBox(
            width: 104,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineMessage extends StatelessWidget {
  const _InlineMessage({
    required this.icon,
    required this.message,
  });

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.onSecondaryContainer),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState({
    required this.label,
    this.compact = false,
  });

  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: compact ? 20 : 44),
      child: Column(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: AppSpacing.md),
          Text(label, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.retry,
    this.compact = false,
  });

  final String message;
  final VoidCallback retry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.all(compact ? AppSpacing.base : AppSpacing.xl),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        children: [
          Icon(Icons.cloud_off_outlined,
              color: theme.colorScheme.onErrorContainer),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: theme.colorScheme.onErrorContainer),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton.icon(
            onPressed: retry,
            icon: const Icon(Icons.refresh),
            label: Text(AppLocalizations.of(context)!.retry),
          ),
        ],
      ),
    );
  }
}

class _SuccessPanel extends StatelessWidget {
  const _SuccessPanel({
    required this.record,
    required this.onDismiss,
  });

  final AttendanceRecord record;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final recordedAt = record.checkOutAt ?? DateTime.now();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(
          color: theme.colorScheme.tertiary.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.check_circle_rounded,
                color: theme.colorScheme.onTertiaryContainer,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.checkOutSuccess,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.onTertiaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${l10n.attendanceRecordedAt} '
                      '${DateFormat('HH:mm \u00B7 dd/MM/yyyy').format(recordedAt)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onTertiaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: onDismiss,
                tooltip: l10n.close,
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: () => showAttendanceRecordDetails(context, record),
            icon: const Icon(Icons.receipt_long_outlined),
            label: Text(l10n.attendanceViewShiftDetails),
          ),
        ],
      ),
    );
  }
}

class _CheckoutConfirmationContent extends StatelessWidget {
  const _CheckoutConfirmationContent({required this.record});

  final AttendanceRecord record;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final elapsed = DateTime.now().difference(record.checkInAt);

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
                color: theme.colorScheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              ),
              child: Icon(
                Icons.logout_rounded,
                color: theme.colorScheme.onTertiaryContainer,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                l10n.confirmCheckOut,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            IconButton(
              onPressed: () => Navigator.pop(context, false),
              tooltip: l10n.close,
              icon: const Icon(Icons.close),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.base),
        Text(
          l10n.attendanceCheckoutPrompt,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _SummaryRow(
          icon: Icons.campaign_outlined,
          label: l10n.campaign,
          value: record.campaignName ?? '--',
        ),
        if (record.eventName != null)
          _SummaryRow(
            icon: Icons.event_outlined,
            label: l10n.events,
            value: record.eventName!,
          ),
        _SummaryRow(
          icon: Icons.schedule_outlined,
          label: l10n.attendanceStartedAt,
          value: DateFormat('HH:mm \u00B7 dd/MM/yyyy').format(record.checkInAt),
        ),
        _SummaryRow(
          icon: Icons.timer_outlined,
          label: l10n.attendanceDuration,
          value: formatAttendanceDuration(elapsed.inMinutes),
        ),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.attendanceKeepWorking),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: AppSpacing.touchTargetPreferred,
          child: FilledButton.icon(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.onSurface,
              foregroundColor: theme.colorScheme.surface,
            ),
            icon: const Icon(Icons.logout_rounded),
            label: Text(l10n.attendanceEndShift),
          ),
        ),
      ],
    );
  }
}
