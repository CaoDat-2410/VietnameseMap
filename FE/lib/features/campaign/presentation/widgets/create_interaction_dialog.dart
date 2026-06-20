import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/dev_identity.dart';
import '../../../../core/utils/date_time_utils.dart';
import '../../../school/shared/models/school_model.dart';
import '../../../school/shared/providers/schools_provider.dart';
import '../../../school/shared/repositories/schools_repository.dart';

class CreateInteractionDialog extends StatefulWidget {
  const CreateInteractionDialog({
    super.key,
    this.availableSchools = const [],
  });

  final List<SchoolModel> availableSchools;

  @override
  State<CreateInteractionDialog> createState() =>
      _CreateInteractionDialogState();
}

class _CreateInteractionDialogState extends State<CreateInteractionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _participantId = TextEditingController(text: '1');
  final _note = TextEditingController();
  final _nextFollowUpAt = TextEditingController();
  SchoolModel? _selectedSchool;
  DateTime? _nextFollowUpAtValue;
  String _participantType = 'STUDENT';
  String _channel = 'MEETING';
  String _outcome = 'INTERESTED';

  @override
  void initState() {
    super.initState();
    if (widget.availableSchools.length == 1) {
      _selectedSchool = widget.availableSchools.single;
    }
  }

  @override
  void dispose() {
    _participantId.dispose();
    _note.dispose();
    _nextFollowUpAt.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Interaction'),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FormField<SchoolModel>(
                  initialValue: _selectedSchool,
                  validator: (value) =>
                      value == null ? 'Please select a school' : null,
                  builder: (field) => InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _selectSchool(field),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'School',
                        errorText: field.errorText,
                        prefixIcon: const Icon(Icons.school_outlined),
                        suffixIcon: const Icon(Icons.search),
                      ),
                      child: _selectedSchool == null
                          ? const Text('Search and select a school')
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedSchool!.schoolName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${_selectedSchool!.provinceName} • '
                                  '${_selectedSchool!.communeName}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _participantType,
                  decoration: const InputDecoration(
                    labelText: 'Participant type',
                  ),
                  items: const ['STUDENT', 'PERSON', 'RELATIVE']
                      .map(
                        (value) =>
                            DropdownMenuItem(value: value, child: Text(value)),
                      )
                      .toList(),
                  onChanged: (value) => _participantType = value!,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _participantId,
                  decoration: const InputDecoration(
                    labelText: 'Participant ID',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) =>
                      int.tryParse(value?.trim() ?? '') == null
                          ? 'Enter a valid number'
                          : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _channel,
                  decoration: const InputDecoration(labelText: 'Channel'),
                  items: const ['MEETING', 'CALL', 'EMAIL', 'ZALO', 'OTHER']
                      .map(
                        (value) =>
                            DropdownMenuItem(value: value, child: Text(value)),
                      )
                      .toList(),
                  onChanged: (value) => _channel = value!,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _outcome,
                  decoration: const InputDecoration(labelText: 'Outcome'),
                  items: const ['INTERESTED', 'NOT_INTERESTED', 'FOLLOW_UP']
                      .map(
                        (value) =>
                            DropdownMenuItem(value: value, child: Text(value)),
                      )
                      .toList(),
                  onChanged: (value) => _outcome = value!,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _note,
                  decoration: const InputDecoration(labelText: 'Note'),
                  minLines: 2,
                  maxLines: 4,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nextFollowUpAt,
                  decoration: const InputDecoration(
                    labelText: 'Next follow-up at',
                    hintText: 'Optional',
                    suffixIcon: Icon(Icons.calendar_month),
                  ),
                  readOnly: true,
                  onTap: _pickNextFollowUpAt,
                ),
                if (_nextFollowUpAtValue != null)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _nextFollowUpAtValue = null;
                          _nextFollowUpAt.clear();
                        });
                      },
                      icon: const Icon(Icons.clear),
                      label: const Text('Clear follow-up'),
                    ),
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
        FilledButton(onPressed: _submit, child: const Text('Create')),
      ],
    );
  }

  Future<void> _selectSchool(FormFieldState<SchoolModel> field) async {
    final school = await showDialog<SchoolModel>(
      context: context,
      builder: (_) => _SchoolPickerDialog(
        preferredSchools: widget.availableSchools,
      ),
    );
    if (school == null || !mounted) return;
    setState(() => _selectedSchool = school);
    field.didChange(school);
  }

  Future<void> _pickNextFollowUpAt() async {
    final initialValue = _nextFollowUpAtValue ?? DateTime.now();
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
      _nextFollowUpAtValue = selected;
      _nextFollowUpAt.text = formatDateTime(selected);
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, <String, dynamic>{
      'employeeId': devEmployeeId,
      'schoolUid': _selectedSchool!.schoolUid,
      'participantType': _participantType,
      'participantId': int.parse(_participantId.text.trim()),
      'channel': _channel,
      'outcome': _outcome,
      'note': _note.text.trim(),
      'nextFollowUpAt': _nextFollowUpAtValue?.toIso8601String(),
    });
  }
}

class _SchoolPickerDialog extends ConsumerStatefulWidget {
  const _SchoolPickerDialog({required this.preferredSchools});

  final List<SchoolModel> preferredSchools;

  @override
  ConsumerState<_SchoolPickerDialog> createState() =>
      _SchoolPickerDialogState();
}

class _SchoolPickerDialogState extends ConsumerState<_SchoolPickerDialog> {
  String _query = '';
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final params = SchoolSearchParams(
      page: 0,
      limit: 50,
      query: _query,
    );
    final schoolsAsync = ref.watch(schoolsSearchProvider(params));

    return AlertDialog(
      title: const Text('Select school'),
      content: SizedBox(
        width: 620,
        height: 520,
        child: Column(
          children: [
            TextField(
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Search school name or address',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 350), () {
                  if (mounted) setState(() => _query = value.trim());
                });
              },
            ),
            const SizedBox(height: 12),
            Expanded(
              child: schoolsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(error.toString(), textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () =>
                            ref.invalidate(schoolsSearchProvider(params)),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
                data: (result) {
                  final schools = _mergeSchools(
                    widget.preferredSchools,
                    result.items,
                  );
                  if (schools.isEmpty) {
                    return const Center(child: Text('No schools found.'));
                  }
                  return ListView.separated(
                    itemCount: schools.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final school = schools[index];
                      final preferred = widget.preferredSchools.any(
                        (item) => item.schoolUid == school.schoolUid,
                      );
                      return ListTile(
                        onTap: () => Navigator.pop(context, school),
                        leading: const CircleAvatar(
                          child: Icon(Icons.school_outlined),
                        ),
                        title: Text(school.schoolName),
                        subtitle: Text(
                          '${school.provinceName} • ${school.communeName}\n'
                          '${school.address}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        isThreeLine: true,
                        trailing: preferred
                            ? const Tooltip(
                                message: 'Assigned in this session',
                                child: Icon(Icons.check_circle),
                              )
                            : null,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  List<SchoolModel> _mergeSchools(
    List<SchoolModel> preferred,
    List<SchoolModel> results,
  ) {
    final byUid = <String, SchoolModel>{};
    for (final school in [...preferred, ...results]) {
      byUid[school.schoolUid] = school;
    }
    return byUid.values.toList();
  }
}
