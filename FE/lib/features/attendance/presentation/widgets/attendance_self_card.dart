import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../campaign/shared/providers/campaign_provider.dart';
import '../providers/attendance_providers.dart';

class AttendanceSelfCard extends ConsumerStatefulWidget {
  const AttendanceSelfCard({super.key});

  @override
  ConsumerState<AttendanceSelfCard> createState() => _AttendanceSelfCardState();
}

class _AttendanceSelfCardState extends ConsumerState<AttendanceSelfCard> {
  int? _selectedCampaignId;
  int? _selectedEventId;
  final _noteController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _handleCheckIn() async {
    if (_selectedCampaignId == null) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(attendanceActionsProvider).checkIn(
            campaignId: _selectedCampaignId!,
            eventId: _selectedEventId,
            note: _noteController.text.trim().isEmpty
                ? null
                : _noteController.text.trim(),
          );
      _noteController.clear();
      _selectedCampaignId = null;
      _selectedEventId = null;
    } on DioException catch (e) {
      if (!mounted) return;
      final code = e.response?.statusCode;
      final serverMessage = e.response?.data?['message']?.toString();
      final l10n = AppLocalizations.of(context)!;
      final msg = switch (code) {
        409 when serverMessage?.contains('open for check-in') == true =>
          l10n.campaignNotOpenForCheckIn,
        409 => l10n.alreadyCheckedIn,
        404 => l10n.noActiveCampaign,
        400 => l10n.employeeNotLinked,
        _ => serverMessage ?? e.message ?? 'Error',
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleCheckOut() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(attendanceActionsProvider).checkOut(
            note: _noteController.text.trim().isEmpty
                ? null
                : _noteController.text.trim(),
          );
      _noteController.clear();
    } on DioException catch (e) {
      if (!mounted) return;
      final code = e.response?.statusCode;
      final serverMessage = e.response?.data?['message']?.toString();
      final l10n = AppLocalizations.of(context)!;
      final msg = switch (code) {
        409 => l10n.noOpenSessionToCheckOut,
        400 => l10n.employeeNotLinked,
        _ => serverMessage ?? e.message ?? 'Error',
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final myAttendance = ref.watch(myAttendanceProvider);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: myAttendance.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Error: $error')),
          data: (page) {
            final latest = page.items.isNotEmpty ? page.items.first : null;
            final hasOpenSession = latest?.isOpen == true;

            if (hasOpenSession) {
              return _buildCheckOutView(context, l10n, latest!);
            } else {
              return _buildCheckInView(context, l10n);
            }
          },
        ),
      ),
    );
  }

  Widget _buildCheckOutView(
      BuildContext context, AppLocalizations l10n, dynamic latest) {
    final theme = Theme.of(context);
    final duration = DateTime.now().difference(latest.checkInAt);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final durationText =
        '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.work_history,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.openSession,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${latest.campaignName ?? 'N/A'}' +
                        (latest.eventName != null
                            ? ' - ${latest.eventName}'
                            : ''),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.timer_outlined,
                      size: 16, color: theme.colorScheme.onTertiaryContainer),
                  const SizedBox(width: 4),
                  Text(
                    durationText,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onTertiaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _noteController,
          decoration: InputDecoration(
            labelText: l10n.note,
            hintText: l10n.attendanceCorrectionNote,
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.notes),
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: _isLoading ? null : _handleCheckOut,
          icon: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.logout),
          label: Text(l10n.checkOut),
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
            foregroundColor: theme.colorScheme.onError,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCheckInView(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    final campaignsAsync = ref.watch(campaignsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.access_time_filled,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                l10n.noOpenSession,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        campaignsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (campaigns) {
            final activeCampaigns =
                campaigns.where((c) => c.status == 'ACTIVE').toList();

            if (activeCampaigns.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: theme.colorScheme.onErrorContainer),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.noActiveCampaign,
                        style: TextStyle(
                            color: theme.colorScheme.onErrorContainer),
                      ),
                    ),
                  ],
                ),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<int>(
                  value: _selectedCampaignId,
                  decoration: InputDecoration(
                    labelText: l10n.selectCampaign,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.campaign),
                  ),
                  items: activeCampaigns.map((c) {
                    return DropdownMenuItem(
                      value: c.id,
                      child: Text(c.name),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedCampaignId = val;
                      _selectedEventId = null;
                    });
                  },
                ),
                const SizedBox(height: 16),
                if (_selectedCampaignId != null)
                  ref.watch(campaignEventsProvider(_selectedCampaignId!)).when(
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Text('Error: $e'),
                        data: (events) {
                          if (events.isEmpty) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: DropdownButtonFormField<int>(
                              value: _selectedEventId,
                              decoration: InputDecoration(
                                labelText: l10n.selectEventOptional,
                                border: const OutlineInputBorder(),
                                prefixIcon: const Icon(Icons.event),
                              ),
                              items: [
                                DropdownMenuItem<int>(
                                  value: null,
                                  child: Text('--- ${l10n.clear} ---'),
                                ),
                                ...events.map((e) {
                                  return DropdownMenuItem(
                                    value: e.id,
                                    child: Text(e.name),
                                  );
                                }).toList(),
                              ],
                              onChanged: (val) {
                                setState(() => _selectedEventId = val);
                              },
                            ),
                          );
                        },
                      ),
                TextField(
                  controller: _noteController,
                  decoration: InputDecoration(
                    labelText: l10n.note,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.notes),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: (_isLoading || _selectedCampaignId == null)
                      ? null
                      : _handleCheckIn,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.login),
                  label: Text(l10n.checkIn),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
