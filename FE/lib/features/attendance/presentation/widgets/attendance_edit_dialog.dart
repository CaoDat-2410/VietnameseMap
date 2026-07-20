import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../campaign/shared/providers/campaign_provider.dart';
import '../../data/models/attendance_models.dart';
import '../providers/attendance_providers.dart';

class AttendanceEditDialog extends ConsumerStatefulWidget {
  const AttendanceEditDialog({super.key, required this.record});

  final AttendanceRecord record;

  @override
  ConsumerState<AttendanceEditDialog> createState() =>
      _AttendanceEditDialogState();
}

class _AttendanceEditDialogState extends ConsumerState<AttendanceEditDialog> {
  int? _campaignId;
  int? _eventId;
  DateTime? _checkInAt;
  DateTime? _checkOutAt;
  final _checkInNoteCtrl = TextEditingController();
  final _checkOutNoteCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _campaignId = widget.record.campaignId;
    _eventId = widget.record.eventId;
    _checkInAt = widget.record.checkInAt;
    _checkOutAt = widget.record.checkOutAt;
    _checkInNoteCtrl.text = widget.record.checkInNote ?? '';
    _checkOutNoteCtrl.text = widget.record.checkOutNote ?? '';
  }

  @override
  void dispose() {
    _checkInNoteCtrl.dispose();
    _checkOutNoteCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime(bool isCheckIn) async {
    final initial = isCheckIn
        ? (_checkInAt ?? DateTime.now())
        : (_checkOutAt ?? DateTime.now());
    final d = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (d == null) return;
    if (!mounted) return;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (t == null) return;
    setState(() {
      final dt = DateTime(d.year, d.month, d.day, t.hour, t.minute);
      if (isCheckIn) {
        _checkInAt = dt;
      } else {
        _checkOutAt = dt;
      }
    });
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final reason = _reasonCtrl.text.trim();
    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.reasonRequired)),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref.read(attendanceActionsProvider).update(
            widget.record.id,
            campaignId: _campaignId,
            eventId: _eventId,
            clearEvent: _eventId == null,
            checkInAt: _checkInAt,
            checkOutAt: _checkOutAt,
            clearCheckOutAt:
                _checkOutAt == null && widget.record.checkOutAt != null,
            checkInNote: _checkInNoteCtrl.text.trim().isEmpty
                ? null
                : _checkInNoteCtrl.text.trim(),
            clearCheckInNote: _checkInNoteCtrl.text.trim().isEmpty,
            checkOutNote: _checkOutNoteCtrl.text.trim().isEmpty
                ? null
                : _checkOutNoteCtrl.text.trim(),
            clearCheckOutNote: _checkOutNoteCtrl.text.trim().isEmpty,
            correctionReason: reason,
          );
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.attendanceActionFailed)),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final campaignsAsync = ref.watch(campaignsProvider);

    return AlertDialog(
      title: Text(l10n.edit),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            campaignsAsync.when(
              loading: () => const CircularProgressIndicator(),
              error: (e, _) => Text(l10n.attendanceLoadFailed),
              data: (campaigns) {
                return DropdownButtonFormField<int>(
                  value: _campaignId,
                  decoration: InputDecoration(labelText: l10n.campaign),
                  items: campaigns.map((c) {
                    return DropdownMenuItem(value: c.id, child: Text(c.name));
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _campaignId = val;
                      _eventId = null;
                    });
                  },
                );
              },
            ),
            const SizedBox(height: 16),
            if (_campaignId != null)
              ref.watch(campaignEventsProvider(_campaignId!)).when(
                    loading: () => const CircularProgressIndicator(),
                    error: (e, _) => Text(l10n.attendanceLoadFailed),
                    data: (events) {
                      return DropdownButtonFormField<int>(
                        value: _eventId,
                        decoration: InputDecoration(
                            labelText: l10n.selectEventOptional),
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
                        onChanged: (val) => setState(() => _eventId = val),
                      );
                    },
                  ),
            const SizedBox(height: 16),
            ListTile(
              title: Text(l10n.checkIn),
              subtitle: Text(_checkInAt?.toString() ?? ''),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _pickDateTime(true),
              shape: RoundedRectangleBorder(
                  side: BorderSide(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(4)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _checkInNoteCtrl,
              decoration:
                  InputDecoration(labelText: '${l10n.checkIn} ${l10n.note}'),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: Text(l10n.checkOut),
              subtitle: Text(_checkOutAt?.toString() ?? '---'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_checkOutAt != null)
                    IconButton(
                      tooltip: l10n.clearCheckOutTime,
                      onPressed: () => setState(() => _checkOutAt = null),
                      icon: const Icon(Icons.clear),
                    ),
                  const Icon(Icons.calendar_today),
                ],
              ),
              onTap: () => _pickDateTime(false),
              shape: RoundedRectangleBorder(
                  side: BorderSide(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(4)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _checkOutNoteCtrl,
              decoration:
                  InputDecoration(labelText: '${l10n.checkOut} ${l10n.note}'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _reasonCtrl,
              decoration: InputDecoration(
                labelText: '${l10n.correctionReason} *',
              ),
              maxLength: 500,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _submit,
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
