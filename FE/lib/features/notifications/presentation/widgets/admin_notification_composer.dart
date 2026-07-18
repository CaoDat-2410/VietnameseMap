import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/models/notification_models.dart';
import '../providers/notification_provider.dart';

class AdminNotificationComposer extends ConsumerStatefulWidget {
  const AdminNotificationComposer({super.key});

  @override
  ConsumerState<AdminNotificationComposer> createState() =>
      _AdminNotificationComposerState();
}

class _AdminNotificationComposerState
    extends ConsumerState<AdminNotificationComposer> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();

  late Future<List<NotificationRecipient>> _recipientsFuture;
  int _recipientId = 0;
  String _type = 'admin_general';
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _loadRecipients();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _loadRecipients() {
    _recipientsFuture =
        ref.read(notificationRepositoryProvider).listRecipients();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate() || _sending) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() => _sending = true);
    try {
      final result = await ref.read(notificationRepositoryProvider).sendManual(
            targetUserId: _recipientId == 0 ? null : _recipientId,
            title: _titleController.text.trim(),
            body: _bodyController.text.trim(),
            type: _type,
          );
      invalidateNotifications(ref);
      _titleController.clear();
      _bodyController.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result == null
                ? l10n.notificationSavedNoDevice
                : l10n.notificationSent,
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.notificationSendFailed)),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<List<NotificationRecipient>>(
          future: _recipientsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 160,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError) {
              return _LoadError(
                message: l10n.notificationLoadUsersFailed,
                retryLabel: l10n.retry,
                onRetry: () => setState(_loadRecipients),
              );
            }
            final recipients = snapshot.data ?? const <NotificationRecipient>[];
            return Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: colors.primaryContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Icon(
                            Icons.send_outlined,
                            color: colors.onPrimaryContainer,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.notificationManagement,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l10n.notificationManagementDescription,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final wide = constraints.maxWidth >= 700;
                      final recipient = _recipientDropdown(
                        l10n,
                        recipients,
                        wide ? (constraints.maxWidth - 12) * 0.58 : null,
                      );
                      final category = _categoryDropdown(l10n);
                      if (!wide) {
                        return Column(
                          children: [
                            recipient,
                            const SizedBox(height: 12),
                            category,
                          ],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 3, child: recipient),
                          const SizedBox(width: 12),
                          Expanded(flex: 2, child: category),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _titleController,
                    maxLength: 120,
                    decoration: InputDecoration(
                      labelText: l10n.notificationTitle,
                      prefixIcon: const Icon(Icons.title),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? l10n.notificationTitleRequired
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _bodyController,
                    minLines: 3,
                    maxLines: 5,
                    maxLength: 500,
                    decoration: InputDecoration(
                      labelText: l10n.notificationBody,
                      alignLabelWithHint: true,
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(bottom: 48),
                        child: Icon(Icons.notes_outlined),
                      ),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? l10n.notificationBodyRequired
                        : null,
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: _sending ? null : _send,
                      icon: _sending
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send),
                      label: Text(
                        _sending
                            ? l10n.notificationSending
                            : l10n.notificationSend,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: const EdgeInsets.only(bottom: 8),
                    leading: const Icon(Icons.notifications_active_outlined),
                    title: Text(l10n.supportedNotifications),
                    subtitle: Text(l10n.supportedNotificationsDescription),
                    children: [
                      _SupportedType(text: l10n.notifyRegistrationResult),
                      _SupportedType(text: l10n.notifyCampaignCreated),
                      _SupportedType(text: l10n.notifyEventCreated),
                      _SupportedType(text: l10n.notifyEventAssignment),
                      _SupportedType(text: l10n.notifyAccountDeactivated),
                      _SupportedType(text: l10n.notifyDailyEventReminder),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _recipientDropdown(
    AppLocalizations l10n,
    List<NotificationRecipient> recipients,
    double? width,
  ) {
    return DropdownMenu<int>(
      width: width,
      initialSelection: _recipientId,
      enableFilter: true,
      requestFocusOnTap: true,
      leadingIcon: const Icon(Icons.group_outlined),
      label: Text(l10n.notificationRecipient),
      hintText: l10n.notificationSearchRecipient,
      dropdownMenuEntries: [
        DropdownMenuEntry<int>(
          value: 0,
          label: l10n.notificationAllUsers,
          leadingIcon: const Icon(Icons.groups_outlined),
        ),
        ...recipients.map(
          (recipient) => DropdownMenuEntry<int>(
            value: recipient.id,
            label: recipient.label,
            leadingIcon: const Icon(Icons.person_outline),
          ),
        ),
      ],
      onSelected: (value) {
        if (value != null) setState(() => _recipientId = value);
      },
    );
  }

  Widget _categoryDropdown(AppLocalizations l10n) {
    return DropdownButtonFormField<String>(
      initialValue: _type,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: l10n.notificationCategory,
        prefixIcon: const Icon(Icons.category_outlined),
      ),
      items: [
        DropdownMenuItem(
          value: 'admin_general',
          child: Text(l10n.notificationGeneral),
        ),
        DropdownMenuItem(
          value: 'campaign_update',
          child: Text(l10n.notificationCampaignUpdate),
        ),
        DropdownMenuItem(
          value: 'event_reminder',
          child: Text(l10n.notificationEventReminder),
        ),
        DropdownMenuItem(
          value: 'system_notice',
          child: Text(l10n.notificationSystemNotice),
        ),
      ],
      onChanged: _sending
          ? null
          : (value) {
              if (value != null) setState(() => _type = value);
            },
    );
  }
}

class _SupportedType extends StatelessWidget {
  const _SupportedType({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => ListTile(
        dense: true,
        minVerticalPadding: 0,
        contentPadding: const EdgeInsets.only(left: 12),
        leading: Icon(
          Icons.check_circle_outline,
          size: 20,
          color: Theme.of(context).colorScheme.tertiary,
        ),
        title: Text(text),
      );
}

class _LoadError extends StatelessWidget {
  const _LoadError({
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                color: Theme.of(context).colorScheme.error,
                size: 36,
              ),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(retryLabel),
              ),
            ],
          ),
        ),
      );
}
