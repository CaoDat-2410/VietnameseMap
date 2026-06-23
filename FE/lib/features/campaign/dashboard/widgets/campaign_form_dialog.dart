import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../shared/models/campaign_models.dart';

class CampaignFormDialog extends ConsumerStatefulWidget {
  const CampaignFormDialog({
    super.key,
    this.campaign,
    required this.onSubmit,
  });

  final CampaignModel? campaign;
  final Future<void> Function(Map<String, dynamic> data) onSubmit;

  @override
  ConsumerState<CampaignFormDialog> createState() => _CampaignFormDialogState();
}

class _CampaignFormDialogState extends ConsumerState<CampaignFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _objectiveController;
  late final TextEditingController _startDateController;
  late final TextEditingController _endDateController;
  late String _status;
  bool _saving = false;

  static const _statuses = ['DRAFT', 'ACTIVE', 'DONE', 'CANCELLED'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.campaign?.name ?? '');
    _objectiveController =
        TextEditingController(text: widget.campaign?.objective ?? '');
    _startDateController =
        TextEditingController(text: widget.campaign?.startDate ?? '');
    _endDateController =
        TextEditingController(text: widget.campaign?.endDate ?? '');
    _status = widget.campaign?.status ?? 'DRAFT';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _objectiveController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(TextEditingController controller) async {
    final initial = DateTime.tryParse(controller.text);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      controller.text =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await widget.onSubmit({
        'name': _nameController.text.trim(),
        'status': _status,
        'objective': _objectiveController.text.trim(),
        'startDate': _startDateController.text.trim(),
        'endDate': _endDateController.text.trim(),
      });
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isEditing = widget.campaign != null;

    return AlertDialog(
      title: Text(isEditing ? l10n.editCampaignTitle : l10n.createCampaignTitle),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: l10n.campaignName),
                  validator: (v) =>
                      v?.trim().isEmpty == true ? l10n.required : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _objectiveController,
                  decoration: InputDecoration(labelText: l10n.campaignObjective),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _startDateController,
                        decoration: InputDecoration(
                          labelText: l10n.campaignStartDate,
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.calendar_today),
                            onPressed: () => _selectDate(_startDateController),
                          ),
                        ),
                        validator: (v) =>
                            v?.trim().isEmpty == true ? l10n.required : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _endDateController,
                        decoration: InputDecoration(
                          labelText: l10n.campaignEndDate,
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.calendar_today),
                            onPressed: () => _selectDate(_endDateController),
                          ),
                        ),
                        validator: (v) =>
                            v?.trim().isEmpty == true ? l10n.required : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _status,
                  decoration: InputDecoration(labelText: l10n.status),
                  items: _statuses
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) => setState(() => _status = v ?? _status),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.save),
        ),
      ],
    );
  }
}
