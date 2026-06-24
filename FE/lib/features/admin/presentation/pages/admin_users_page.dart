import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../campaign/shared/providers/campaign_provider.dart';
import '../widgets/user_admin_table.dart';
import '../widgets/user_form_dialog.dart';

class AdminUsersPage extends ConsumerWidget {
  const AdminUsersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final users = ref.watch(usersProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.users)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(context, ref),
        child: const Icon(Icons.add),
      ),
      body: users.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
        data: (items) => UserAdminTable(
          users: items,
          onAction: (user, action) => _handleAction(context, ref, user, action),
        ),
      ),
    );
  }

  Future<void> _openForm(BuildContext context, WidgetRef ref, [Map<String, dynamic>? user]) async {
    await showDialog<void>(
      context: context,
      builder: (_) => UserFormDialog(
        initial: user,
        onSubmit: (data) async {
          final repo = ref.read(campaignRepositoryProvider);
          if (user != null) {
            await repo.updateUser(user['id'] as int, data);
          } else {
            await repo.createUser(data);
          }
          ref.invalidate(usersProvider);
        },
      ),
    );
  }

  Future<void> _handleAction(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> user,
    UserAction action,
  ) async {
    switch (action) {
      case UserAction.edit:
        await _openForm(context, ref, user);
        break;
      case UserAction.toggleStatus:
        await _toggleStatus(context, ref, user);
        break;
      case UserAction.delete:
        await _deleteUser(context, ref, user);
        break;
    }
  }

  Future<void> _toggleStatus(BuildContext context, WidgetRef ref, Map<String, dynamic> user) async {
    final repo = ref.read(campaignRepositoryProvider);
    final id = user['id'] as int;
    final currentStatus = user['status'] as String? ?? 'ACTIVE';
    final newStatus = currentStatus == 'ACTIVE' ? 'INACTIVE' : 'ACTIVE';
    final confirmed = await _confirm(
      context,
      title: '$newStatus User?',
      message: 'Set status to $newStatus for ${user['email']}?',
    );
    if (confirmed) {
      await repo.updateUserStatus(id, newStatus);
      ref.invalidate(usersProvider);
    }
  }

  Future<void> _deleteUser(BuildContext context, WidgetRef ref, Map<String, dynamic> user) async {
    final repo = ref.read(campaignRepositoryProvider);
    final id = user['id'] as int;
    final confirmed = await _confirm(
      context,
      title: 'Delete User?',
      message: 'This action cannot be undone. Delete ${user['email']}?',
      confirmText: 'Delete',
      isDestructive: true,
    );
    if (confirmed) {
      await repo.deleteUser(id);
      ref.invalidate(usersProvider);
    }
  }

  Future<bool> _confirm(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Confirm',
    bool isDestructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: isDestructive
                ? FilledButton.styleFrom(backgroundColor: AppColors.error)
                : null,
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmText),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

