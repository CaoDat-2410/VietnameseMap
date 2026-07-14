import 'package:flutter/material.dart';

class UserFormDialog extends StatefulWidget {
  const UserFormDialog({
    super.key,
    this.initial,
    required this.onSubmit,
  });

  final Map<String, dynamic>? initial;
  final Future<void> Function(Map<String, dynamic> data) onSubmit;

  static const _roles = ['ADMIN', 'MANAGER', 'STAFF', 'STUDENT'];
  static const _statuses = ['ACTIVE', 'DISABLED'];

  @override
  State<UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<UserFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _employeeIdController;
  late final TextEditingController _studentIdController;
  late String _role;
  late String _status;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(
      text: widget.initial?['email'] as String? ?? '',
    );
    _passwordController = TextEditingController();
    _employeeIdController = TextEditingController(
      text: widget.initial?['employeeId']?.toString() ?? '',
    );
    _studentIdController = TextEditingController(
      text: widget.initial?['studentId']?.toString() ?? '',
    );
    _role = widget.initial?['role'] as String? ?? 'STAFF';
    final initialStatus = widget.initial?['status'] as String? ?? 'ACTIVE';
    _status = initialStatus == 'INACTIVE' ? 'DISABLED' : initialStatus;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _employeeIdController.dispose();
    _studentIdController.dispose();
    super.dispose();
  }

  bool get _isEdit => widget.initial != null;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isLoading) return;

    setState(() => _isLoading = true);

    final data = <String, dynamic>{
      'email': _emailController.text.trim(),
      'role': _role,
      'status': _status,
    };

    if (!_isEdit) {
      data['password'] = _passwordController.text;
    }

    final employeeId = int.tryParse(_employeeIdController.text);
    if (employeeId != null) {
      data['employeeId'] = employeeId;
    }

    final studentId = int.tryParse(_studentIdController.text);
    if (studentId != null) {
      data['studentId'] = studentId;
    }

    try {
      await widget.onSubmit(data);
      if (mounted) Navigator.of(context).pop();
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
    return AlertDialog(
      title: Text(_isEdit ? 'Edit User' : 'Create User'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Email is required' : null,
                ),
                if (!_isEdit) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Password is required' : null,
                  ),
                ],
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _role,
                  decoration: const InputDecoration(
                    labelText: 'Role',
                    border: OutlineInputBorder(),
                  ),
                  items: UserFormDialog._roles
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: (v) => setState(() => _role = v!),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _status,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                  ),
                  items: UserFormDialog._statuses
                      .map((s) =>
                          DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) => setState(() => _status = v!),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _employeeIdController,
                  decoration: const InputDecoration(
                    labelText: 'Employee ID (optional)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _studentIdController,
                  decoration: const InputDecoration(
                    labelText: 'Student ID (optional)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_isEdit ? 'Save' : 'Create'),
        ),
      ],
    );
  }
}
