import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../school/shared/models/school_model.dart';
import '../../../school/shared/providers/schools_provider.dart';
import '../../../school/shared/repositories/schools_repository.dart';

class EventSchoolsTab extends ConsumerStatefulWidget {
  const EventSchoolsTab({
    super.key,
    required this.assignedSchoolUids,
    required this.onAssign,
    required this.onRemove,
  });

  final Set<String> assignedSchoolUids;
  final Future<void> Function(SchoolModel school) onAssign;
  final Future<void> Function(SchoolModel school) onRemove;

  @override
  ConsumerState<EventSchoolsTab> createState() => _EventSchoolsTabState();
}

class _EventSchoolsTabState extends ConsumerState<EventSchoolsTab> {
  String _query = '';
  String? _provinceCode;
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _setFilter(void Function() update) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(update);
    });
  }

  @override
  Widget build(BuildContext context) {
    final params = SchoolSearchParams(
      page: 0,
      limit: 50,
      query: _query,
      provinceCode: _provinceCode,
    );
    final schoolsAsync = ref.watch(schoolsSearchProvider(params));
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 330,
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search schools',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) => _setFilter(() => _query = value.trim()),
                ),
              ),
              SizedBox(
                width: 190,
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Province code (optional)',
                  ),
                  onChanged: (value) => _setFilter(() {
                    final trimmed = value.trim();
                    _provinceCode = trimmed.isEmpty ? null : trimmed;
                  }),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: schoolsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(error.toString(), textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () =>
                        ref.invalidate(schoolsSearchProvider(params)),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
            data: (result) {
              if (result.items.isEmpty) {
                return const Center(child: Text('No schools found.'));
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: result.items.length,
                itemBuilder: (context, index) {
                  final school = result.items[index];
                  final assigned = widget.assignedSchoolUids.contains(
                    school.schoolUid,
                  );
                  return Card(
                    child: ListTile(
                      title: Text(school.schoolName),
                      subtitle: Text(
                        '${school.schoolUid} • ${school.provinceName} • '
                        '${school.communeName} • ${school.areaType}\n'
                        '${school.address}',
                      ),
                      isThreeLine: true,
                      trailing: assigned
                          ? OutlinedButton(
                              onPressed: () => widget.onRemove(school),
                              child: const Text('Remove'),
                            )
                          : FilledButton(
                              onPressed: () => widget.onAssign(school),
                              child: const Text('Assign'),
                            ),
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
}
