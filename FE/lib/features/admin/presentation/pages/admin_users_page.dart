import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../campaign/shared/providers/campaign_provider.dart';
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
        data: (items) => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final user = items[index];
            final id = user['id'] as int;
            return Card(
              child: ListTile(
                title: Text(user['email'] as String? ?? ''),
                subtitle: Row(
                  children: [
                    _RoleChip(role: user['role'] as String? ?? ''),
                    const SizedBox(width: 8),
                    _StatusChip(status: user['status'] as String? ?? ''),
                  ],
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (action) => _handleAction(context, ref, user, action),
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 20),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: user['status'] == 'ACTIVE' ? 'deactivate' : 'activate',
                      child: Row(
                        children: [
                          Icon(
                            user['status'] == 'ACTIVE'
                                ? Icons.block
                                : Icons.check_circle,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(user['status'] == 'ACTIVE' ? 'Deactivate' : 'Activate'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    ...['ADMIN', 'MANAGER', 'STAFF', 'STUDENT']
                        .map((role) => PopupMenuItem(
                              value: 'role_$role',
                              child: Row(
                                children: [
                                  Icon(
                                    user['role'] == role
                                        ? Icons.check
                                        : Icons.person_outline,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(role),
                                ],
                              ),
                            )),
                  ],
                ),
              ),
            );
          },
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
    String action,
  ) async {
    final repo = ref.read(campaignRepositoryProvider);
    final id = user['id'] as int;

    switch (action) {
      case 'edit':
        await _openForm(context, ref, user);
        break;
      case 'activate':
      case 'deactivate':
        final newStatus = action == 'activate' ? 'ACTIVE' : 'INACTIVE';
        final confirmed = await _confirm(
          context,
          title: '$newStatus User?',
          message: 'Set status to $newStatus for ${user['email']}?',
        );
        if (confirmed) {
          await repo.updateUserStatus(id, newStatus);
          ref.invalidate(usersProvider);
        }
        break;
      case 'delete':
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
        break;
      default:
        if (action.startsWith('role_')) {
          final role = action.substring(5);
          await repo.updateUserRole(id, role);
          ref.invalidate(usersProvider);
        }
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
                ? FilledButton.styleFrom(backgroundColor: Colors.red)
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

class _RoleChip extends StatelessWidget {
  const _RoleChip({required this.role});

  final String role;

  Color get _color {
    switch (role) {
      case 'ADMIN':
        return AppColors.error;
      case 'MANAGER':
        return AppColors.warning;
      case 'STAFF':
        return AppColors.info;
      case 'STUDENT':
        return AppColors.success;
      default:
        return AppColors.textTertiaryLight;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(role, style: const TextStyle(fontSize: 12)),
      backgroundColor: _color.withOpacity(0.1),
      side: BorderSide(color: _color),
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final isActive = status == 'ACTIVE';
    return Chip(
      label: Text(
        status,
        style: TextStyle(
          fontSize: 12,
          color: isActive ? AppColors.success : AppColors.warning,
        ),
      ),
      backgroundColor:
          isActive ? AppColors.successLight : AppColors.warningLight,
      side: BorderSide(color: isActive ? AppColors.success : AppColors.warning),
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
