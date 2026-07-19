import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../campaign/shared/providers/campaign_provider.dart';

class StudentRegisterPage extends ConsumerStatefulWidget {
  const StudentRegisterPage({super.key, required this.campaignId});

  final int campaignId;

  @override
  ConsumerState<StudentRegisterPage> createState() =>
      _StudentRegisterPageState();
}

class _StudentRegisterPageState extends ConsumerState<StudentRegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _controllers = <String, TextEditingController>{
    'schoolUid': TextEditingController(text: '01-001'),
    'fullName': TextEditingController(),
    'email': TextEditingController(),
    'phone': TextEditingController(),
    'password': TextEditingController(),
    'grade': TextEditingController(text: '12'),
    'className': TextEditingController(),
    'note': TextEditingController(),
  };
  bool _saving = false;

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(campaignRepositoryProvider).registerStudent(
        widget.campaignId,
        {
          for (final entry in _controllers.entries)
            entry.key: entry.value.text.trim(),
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration submitted')),
        );
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
    final campaign = ref.watch(campaignDetailProvider(widget.campaignId));
    return Scaffold(
      appBar: AppBar(title: const Text('Campaign Registration')),
      body: campaign.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
        data: (item) => Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(item.name, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _field('schoolUid', 'School UID'),
                          _field('fullName', 'Full name'),
                          _field('email', 'Email'),
                          _field('phone', 'Phone'),
                          _field('password', 'Password', obscure: true),
                          _field('grade', 'Grade'),
                          _field('className', 'Class'),
                          _field('note', 'Note', required: false),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: _saving ? null : _submit,
                              child: Text(_saving
                                  ? 'Submitting...'
                                  : 'Submit registration'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    String key,
    String label, {
    bool obscure = false,
    bool required = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: _controllers[key],
        obscureText: obscure,
        decoration: InputDecoration(labelText: label),
        validator: (value) {
          if (!required) return null;
          if (value == null || value.trim().isEmpty) return 'Required';
          if (key == 'password' && value.length < 8) {
            return 'Minimum 8 characters';
          }
          return null;
        },
      ),
    );
  }
}
