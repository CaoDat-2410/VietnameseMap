import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../campaign/shared/providers/campaign_provider.dart';

class MyRegistrationsPage extends ConsumerWidget {
  const MyRegistrationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final registrations = ref.watch(myRegistrationsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('My registrations')),
      body: registrations.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('No registrations yet'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                child: ListTile(
                  title: Text(item.school.schoolName),
                  subtitle: Text('${item.student.fullName}\n${item.note}'),
                  trailing: Chip(label: Text(item.status)),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
