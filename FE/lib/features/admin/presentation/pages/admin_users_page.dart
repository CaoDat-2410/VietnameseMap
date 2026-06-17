import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../campaign/shared/providers/campaign_provider.dart';

class AdminUsersPage extends ConsumerWidget {
  const AdminUsersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = ref.watch(usersProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Users')),
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
                subtitle: Text('Role: ${user['role']} | ${user['status']}'),
                trailing: PopupMenuButton<String>(
                  onSelected: (role) async {
                    await ref
                        .read(campaignRepositoryProvider)
                        .updateUserRole(id, role);
                    ref.invalidate(usersProvider);
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'ADMIN', child: Text('ADMIN')),
                    PopupMenuItem(value: 'MANAGER', child: Text('MANAGER')),
                    PopupMenuItem(value: 'STAFF', child: Text('STAFF')),
                    PopupMenuItem(value: 'STUDENT', child: Text('STUDENT')),
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
