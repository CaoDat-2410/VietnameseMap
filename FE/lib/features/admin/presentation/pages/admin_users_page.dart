import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../campaign/shared/providers/campaign_provider.dart';

class AdminUsersPage extends ConsumerWidget {
  const AdminUsersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final users = ref.watch(usersProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.users)),
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
                subtitle: Text('${l10n.role}: ${user['role']} | ${l10n.status}: ${user['status']}'),
                trailing: PopupMenuButton<String>(
                  onSelected: (role) async {
                    await ref
                        .read(campaignRepositoryProvider)
                        .updateUserRole(id, role);
                    ref.invalidate(usersProvider);
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'ADMIN', child: Text('ADMIN')),
                    const PopupMenuItem(value: 'MANAGER', child: Text('MANAGER')),
                    const PopupMenuItem(value: 'STAFF', child: Text('STAFF')),
                    const PopupMenuItem(value: 'STUDENT', child: Text('STUDENT')),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
