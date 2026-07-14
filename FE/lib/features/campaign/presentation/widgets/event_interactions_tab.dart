import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/shared/providers/auth_provider.dart';
import '../../shared/providers/campaign_provider.dart';

class EventInteractionsTab extends ConsumerWidget {
  const EventInteractionsTab({super.key, required this.eventId});

  final int eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final interactions = ref.watch(eventInteractionsProvider(eventId));
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: () => _openCreateDialog(context, ref),
              icon: const Icon(Icons.add_comment_outlined),
              label: const Text('Create Interaction'),
            ),
          ),
        ),
        Expanded(
          child: interactions.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => _ErrorBlock(
              error: error,
              onRetry: () => ref.invalidate(eventInteractionsProvider(eventId)),
            ),
            data: (items) {
              if (items.isEmpty) {
                return const Center(child: Text('No interactions yet'));
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                itemCount: items.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final interaction = items[index];
                  return Card(
                    child: ListTile(
                      title: Text(
                        '${interaction.participantType} #${interaction.participantId}',
                      ),
                      subtitle: Text(
                        '${interaction.schoolUid} | ${interaction.channel} | '
                        '${interaction.outcome}\n'
                        '${interaction.note.isEmpty ? '-' : interaction.note}\n'
                        'Next: ${interaction.nextFollowUpAt.isEmpty ? '-' : interaction.nextFollowUpAt}',
                      ),
                      trailing: Text('#${interaction.id}'),
                      isThreeLine: true,
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _openCreateDialog(BuildContext context, WidgetRef ref) async {
    try {
      await showDialog<void>(
        context: context,
        builder: (context) => _CreateInteractionDialog(eventId: eventId),
      );
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    }
  }
}

class _CreateInteractionDialog extends ConsumerStatefulWidget {
  const _CreateInteractionDialog({required this.eventId});

  final int eventId;

  @override
  ConsumerState<_CreateInteractionDialog> createState() =>
      _CreateInteractionDialogState();
}

class _CreateInteractionDialogState
    extends ConsumerState<_CreateInteractionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _schoolUidController = TextEditingController(text: '01-001');
  final _participantIdController = TextEditingController(text: '1');
  final _noteController = TextEditingController();
  final _nextFollowUpController = TextEditingController();
  String _participantType = 'STUDENT';
  String _channel = 'MEETING';
  String _outcome = 'INTERESTED';
  bool _saving = false;

  @override
  void dispose() {
    _schoolUidController.dispose();
    _participantIdController.dispose();
    _noteController.dispose();
    _nextFollowUpController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final user = await ref.read(currentUserProvider.future);
      final employeeId = user?.employeeId;
      if (employeeId == null) {
        throw StateError('Current user is not linked to an employee');
      }
      await ref.read(campaignRepositoryProvider).createInteraction(
        widget.eventId,
        {
          'employeeId': employeeId,
          'schoolUid': _schoolUidController.text.trim(),
          'participantType': _participantType,
          'participantId': int.parse(_participantIdController.text.trim()),
          'channel': _channel,
          'outcome': _outcome,
          'note': _noteController.text.trim(),
          'nextFollowUpAt': _emptyToNull(_nextFollowUpController.text),
        },
      );
      ref.invalidate(eventInteractionsProvider(widget.eventId));
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Interaction created')),
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
                TextFormField(
                  controller: _schoolUidController,
                  decoration: const InputDecoration(labelText: 'School UID'),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _participantType,
                  decoration:
                      const InputDecoration(labelText: 'Participant type'),
                  items: const [
                    DropdownMenuItem(value: 'STUDENT', child: Text('STUDENT')),
                    DropdownMenuItem(value: 'PERSON', child: Text('PERSON')),
                    DropdownMenuItem(
                        value: 'RELATIVE', child: Text('RELATIVE')),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _participantType = value);
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _participantIdController,
                  decoration:
                      const InputDecoration(labelText: 'Participant ID'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    final id = int.tryParse(value?.trim() ?? '');
                    if (id == null || id <= 0) {
                      return 'Participant ID must be positive';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _channel,
                  decoration: const InputDecoration(labelText: 'Channel'),
                  items: const [
                    DropdownMenuItem(value: 'MEETING', child: Text('MEETING')),
                    DropdownMenuItem(value: 'CALL', child: Text('CALL')),
                    DropdownMenuItem(value: 'EMAIL', child: Text('EMAIL')),
                    DropdownMenuItem(value: 'ZALO', child: Text('ZALO')),
                    DropdownMenuItem(value: 'OTHER', child: Text('OTHER')),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _channel = value);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _outcome,
                  decoration: const InputDecoration(labelText: 'Outcome'),
                  items: const [
                    DropdownMenuItem(
                      value: 'INTERESTED',
                      child: Text('INTERESTED'),
                    ),
                    DropdownMenuItem(
                      value: 'NOT_INTERESTED',
                      child: Text('NOT_INTERESTED'),
                    ),
                    DropdownMenuItem(
                        value: 'FOLLOW_UP', child: Text('FOLLOW_UP')),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _outcome = value);
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nextFollowUpController,
                  decoration: const InputDecoration(
                    labelText: 'Next follow up',
                    hintText: '2026-06-25T09:00:00',
                  ),
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isEmpty) return null;
                    return DateTime.tryParse(text) == null
                        ? 'Use yyyy-MM-ddTHH:mm:ss'
                        : null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _noteController,
                  decoration: const InputDecoration(labelText: 'Note'),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }

  String? _required(String? value) {
    return value == null || value.trim().isEmpty ? 'Required' : null;
  }

  String? _emptyToNull(String value) {
    final text = value.trim();
    return text.isEmpty ? null : text;
  }
}

class _ErrorBlock extends StatelessWidget {
  const _ErrorBlock({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        color: Theme.of(context).colorScheme.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(error.toString()),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
