import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../auth/shared/providers/auth_provider.dart';
import '../../../campaign/shared/providers/campaign_provider.dart';
import '../../../school/shared/providers/schools_provider.dart';
import '../../../school/shared/repositories/schools_repository.dart';

class EventRegistrationPage extends ConsumerStatefulWidget {
  const EventRegistrationPage({super.key, required this.campaignId});

  final int campaignId;

  @override
  ConsumerState<EventRegistrationPage> createState() =>
      _EventRegistrationPageState();
}

class _EventRegistrationPageState extends ConsumerState<EventRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _gradeController = TextEditingController();
  final _classNameController = TextEditingController();
  final _noteController = TextEditingController();
  String? _selectedSchoolUid;
  bool _saving = false;
  SchoolSearchParams _schoolParams = const SchoolSearchParams(limit: 50);

  @override
  void initState() {
    super.initState();
    final user = ref.read(activeUserProvider).valueOrNull;
    if (user != null) {
      _fullNameController.text = user.email.split('@').first;
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _gradeController.dispose();
    _classNameController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSchoolUid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pleaseSelectSchool)),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final user = ref.read(activeUserProvider).valueOrNull;
      await ref.read(campaignRepositoryProvider).registerStudent(
            widget.campaignId,
            {
              'schoolUid': _selectedSchoolUid,
              'fullName': _fullNameController.text.trim(),
              'email': user?.email ?? '',
              'phone': _phoneController.text.trim(),
              'password': 'authenticated',
              'grade': _gradeController.text.trim(),
              'className': _classNameController.text.trim(),
              'note': _noteController.text.trim(),
            },
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.registrationSuccess)),
        );
        ref.invalidate(myRegistrationsProvider);
        context.go('/student/my-registrations');
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final campaign = ref.watch(campaignDetailProvider(widget.campaignId));
    final user = ref.watch(activeUserProvider).valueOrNull;
    final schoolsAsync = ref.watch(schoolsSearchProvider(_schoolParams));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.registerForEvent),
        actions: [
          IconButton(
            tooltip: l10n.cancel,
            onPressed: () => context.go('/campaigns/' + ''),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      body: campaign.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
        data: (item) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.campaign,
                              style: Theme.of(context).textTheme.labelMedium),
                          Text(item.name,
                              style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 8),
                          if (item.objective.isNotEmpty)
                            Text(item.objective,
                                style: Theme.of(context).textTheme.bodyMedium),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 12,
                            children: [
                              Text('[' + l10n.start + ']: ' + item.startDate),
                              Text('[' + l10n.end + ']: ' + item.endDate),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(l10n.yourInformation,
                                style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _fullNameController,
                              decoration: InputDecoration(
                                labelText: '[' + l10n.fullName + '] *',
                                prefixIcon: const Icon(Icons.person_outline),
                              ),
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? l10n.required
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              decoration: InputDecoration(
                                labelText: l10n.email,
                                prefixIcon: const Icon(Icons.email_outlined),
                              ),
                              initialValue: user?.email ?? '',
                              enabled: false,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _phoneController,
                              decoration: InputDecoration(
                                labelText: '[' + l10n.phone + '] *',
                                prefixIcon: const Icon(Icons.phone_outlined),
                              ),
                              keyboardType: TextInputType.phone,
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? l10n.required
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            const Divider(),
                            const SizedBox(height: 8),
                            Text(l10n.schoolInformation,
                                style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 12),
                            schoolsAsync.when(
                              loading: () => const LinearProgressIndicator(),
                              error: (e, _) => Text(
                                  'Loi tai danh sach truong: ' + e.toString(),
                                  style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.error)),
                              data: (page) {
                                return Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    TextField(
                                      decoration: InputDecoration(
                                        labelText: l10n.searchSchool,
                                        prefixIcon: const Icon(Icons.search),
                                        hintText: l10n.searchSchool,
                                      ),
                                      onSubmitted: (q) {
                                        setState(() {
                                          _schoolParams = SchoolSearchParams(
                                            limit: 50,
                                            query: q.trim().isEmpty
                                                ? null
                                                : q.trim(),
                                          );
                                        });
                                      },
                                    ),
                                    const SizedBox(height: 8),
                                    DropdownButtonFormField<String>(
                                      initialValue: _selectedSchoolUid,
                                      decoration: InputDecoration(
                                        labelText: '[' + l10n.school + '] *',
                                        prefixIcon: const Icon(Icons.school),
                                      ),
                                      items: page.items
                                          .map((s) =>
                                              DropdownMenuItem<String>(
                                                value: s.schoolUid,
                                                child: Text(
                                                  s.schoolName + ' (' + s.provinceName + ')',
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ))
                                          .toList(),
                                      onChanged: (v) => setState(
                                          () => _selectedSchoolUid = v),
                                      validator: (v) => v == null || v.isEmpty
                                          ? l10n.pleaseSelectSchool
                                          : null,
                                    ),
                                    if (page.items.isEmpty)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(top: 8),
                                        child: Text(
                                          l10n.noSchoolsFoundHint,
                                          style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .error,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _gradeController,
                                    decoration: InputDecoration(
                                      labelText: '[' + l10n.grade + '] *',
                                      hintText: '10, 11, 12...',
                                      prefixIcon:
                                          const Icon(Icons.school_outlined),
                                    ),
                                    validator: (v) =>
                                        v == null || v.trim().isEmpty
                                            ? l10n.required
                                            : null,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: _classNameController,
                                    decoration: InputDecoration(
                                      labelText: '[' + l10n.className + '] *',
                                      hintText: '10A1, 11B2...',
                                      prefixIcon:
                                          const Icon(Icons.class_outlined),
                                    ),
                                    validator: (v) =>
                                        v == null || v.trim().isEmpty
                                            ? l10n.required
                                            : null,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _noteController,
                              decoration: InputDecoration(
                                labelText: l10n.note,
                                prefixIcon: const Icon(Icons.note_outlined),
                              ),
                              maxLines: 3,
                            ),
                            const SizedBox(height: 24),
                            FilledButton.icon(
                              onPressed: _saving ? null : _submit,
                              icon: _saving
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : const Icon(Icons.send_outlined),
                              label: Text(_saving
                                  ? l10n.submitting
                                  : l10n.submitRegistration),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
