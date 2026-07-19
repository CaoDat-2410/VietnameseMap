import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../campaign/shared/providers/campaign_provider.dart';
import '../providers/attendance_providers.dart';

class AttendanceCreateDialog extends ConsumerStatefulWidget {
  const AttendanceCreateDialog({super.key});

  @override
  ConsumerState<AttendanceCreateDialog> createState() =>
      _AttendanceCreateDialogState();
}

class _AttendanceCreateDialogState
    extends ConsumerState<AttendanceCreateDialog> {
  int? _employeeId;
  int? _campaignId;
  int? _eventId;
  DateTime? _checkInAt;
  DateTime? _checkOutAt;
  final _checkInNoteCtrl = TextEditingController();
  final _checkOutNoteCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _checkInNoteCtrl.dispose();
    _checkOutNoteCtrl.dispose();
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
    if (_employeeId == null || _campaignId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.required)),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      await ref.read(attendanceActionsProvider).createManual(
            employeeId: _employeeId!,
            campaignId: _campaignId!,
            eventId: _eventId,
            checkInAt: _checkInAt,
            checkOutAt: _checkOutAt,
            checkInNote: _checkInNoteCtrl.text.trim().isEmpty
                ? null
                : _checkInNoteCtrl.text.trim(),
            checkOutNote: _checkOutNoteCtrl.text.trim().isEmpty
                ? null
                : _checkOutNoteCtrl.text.trim(),
          );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
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
    final employeesAsync = ref.watch(employeesProvider);

    return AlertDialog(
      title: Text(l10n.create),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            employeesAsync.when(
              loading: () => const CircularProgressIndicator(),
              error: (e, _) => Text('Error: $e'),
              data: (employees) {
                return DropdownButtonFormField<int>(
                  value: _employeeId,
                  decoration: InputDecoration(
                    labelText: '${l10n.employees} *',
                  ),
                  items: employees.map((e) {
                    return DropdownMenuItem(
                      value: e.id,
                      child: Text(e.fullName),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _employeeId = val),
                );
              },
            ),
            const SizedBox(height: 16),
            campaignsAsync.when(
              loading: () => const CircularProgressIndicator(),
              error: (e, _) => Text('Error: $e'),
              data: (campaigns) {
                return DropdownButtonFormField<int>(
                  value: _campaignId,
                  decoration: InputDecoration(labelText: '${l10n.campaign} *'),
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
                    error: (e, _) => Text('Error: $e'),
                    data: (events) {
                      return DropdownButtonFormField<int>(
                        value: _eventId,
                        decoration:
                            InputDecoration(labelText: l10n.selectEventOptional),
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
              subtitle: Text(_checkInAt?.toString() ?? '---'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _pickDateTime(true),
              shape: RoundedRectangleBorder(
                  side: BorderSide(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(4)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _checkInNoteCtrl,
              decoration: InputDecoration(labelText: '${l10n.checkIn} ${l10n.note}'),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: Text(l10n.checkOut),
              subtitle: Text(_checkOutAt?.toString() ?? '---'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _pickDateTime(false),
              shape: RoundedRectangleBorder(
                  side: BorderSide(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(4)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _checkOutNoteCtrl,
              decoration: InputDecoration(labelText: '${l10n.checkOut} ${l10n.note}'),
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
          child: Text(l10n.create),
        ),
      ],
    );
  }
}
