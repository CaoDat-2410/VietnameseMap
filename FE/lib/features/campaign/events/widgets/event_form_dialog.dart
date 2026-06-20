import 'package:flutter/material.dart';

import '../../../../core/utils/date_time_utils.dart';
import '../../shared/models/campaign_models.dart';

class EventFormDialog extends StatefulWidget {
  const EventFormDialog({super.key, this.event});

  final CampaignEventModel? event;

  @override
  State<EventFormDialog> createState() => _EventFormDialogState();
}

class _EventFormDialogState extends State<EventFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _startsAt;
  late final TextEditingController _endsAt;
  late final TextEditingController _note;
  DateTime? _startsAtValue;
  DateTime? _endsAtValue;
  late String _eventType;
  late String _status;

  @override
  void initState() {
    super.initState();
    final event = widget.event;
    _name = TextEditingController(text: event?.name);
    _startsAtValue = DateTime.tryParse(event?.startsAt ?? '');
    _endsAtValue = DateTime.tryParse(event?.endsAt ?? '');
    _startsAt = TextEditingController(
      text: _startsAtValue == null ? '' : formatDateTime(_startsAtValue),
    );
    _endsAt = TextEditingController(
      text: _endsAtValue == null ? '' : formatDateTime(_endsAtValue),
    );
    _note = TextEditingController(text: event?.note);
    _eventType =
        event?.eventType.isNotEmpty == true ? event!.eventType : 'SCHOOL_VISIT';
    _status = event?.status.isNotEmpty == true ? event!.status : 'PLANNED';
  }

  @override
  void dispose() {
    _name.dispose();
    _startsAt.dispose();
    _endsAt.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.event == null ? 'Create Event' : 'Edit Event'),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _eventType,
                  decoration: const InputDecoration(labelText: 'Event type'),
                  items: const [
                    'SCHOOL_VISIT',
                    'ONLINE_WORKSHOP',
                    'SURVEY',
                    'MEETING',
                  ]
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(value),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => _eventType = value!,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: const ['PLANNED', 'IN_PROGRESS', 'DONE', 'CANCELLED']
                      .map(
                        (value) =>
                            DropdownMenuItem(value: value, child: Text(value)),
                      )
                      .toList(),
                  onChanged: (value) => _status = value!,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _startsAt,
                  decoration: const InputDecoration(
                    labelText: 'Starts at',
                    hintText: 'Select date and time',
                    suffixIcon: Icon(Icons.calendar_month),
                  ),
                  readOnly: true,
                  onTap: () => _pickDateTime(isStart: true),
                  validator: (_) => _startsAtValue == null ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _endsAt,
                  decoration: const InputDecoration(
                    labelText: 'Ends at',
                    hintText: 'Select date and time',
                    suffixIcon: Icon(Icons.calendar_month),
                  ),
                  readOnly: true,
                  onTap: () => _pickDateTime(isStart: false),
                  validator: (_) {
                    if (_endsAtValue == null) return 'Required';
                    if (_startsAtValue != null &&
                        _endsAtValue!.isBefore(_startsAtValue!)) {
                      return 'End time must be after start time';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _note,
                  decoration: const InputDecoration(labelText: 'Note'),
                  minLines: 2,
                  maxLines: 4,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Required' : null;

  Future<void> _pickDateTime({required bool isStart}) async {
    final currentValue = isStart ? _startsAtValue : _endsAtValue;
    final fallback = isStart
        ? DateTime.now()
        : (_startsAtValue ?? DateTime.now()).add(const Duration(hours: 1));
    final initialValue = currentValue ?? fallback;

    final date = await showDatePicker(
      context: context,
      initialDate: initialValue,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialValue),
    );
    if (time == null || !mounted) return;

    final selected = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    setState(() {
      if (isStart) {
        _startsAtValue = selected;
        _startsAt.text = formatDateTime(selected);
      } else {
        _endsAtValue = selected;
        _endsAt.text = formatDateTime(selected);
      }
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, <String, dynamic>{
      'name': _name.text.trim(),
      'eventType': _eventType,
      'status': _status,
      'startsAt': _startsAtValue?.toIso8601String(),
      'endsAt': _endsAtValue?.toIso8601String(),
      'note': _note.text.trim(),
    });
  }
}
