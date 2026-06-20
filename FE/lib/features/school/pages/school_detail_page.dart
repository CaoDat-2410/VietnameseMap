import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../shared/models/school_model.dart';
import '../shared/providers/schools_provider.dart';

class SchoolDetailPage extends ConsumerWidget {
  const SchoolDetailPage({super.key, required this.schoolUid});

  final String schoolUid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(schoolDetailProvider(schoolUid));
    return Scaffold(
      appBar: AppBar(
        title: const Text('School Detail'),
        actions: [
          IconButton(
            onPressed: () => ref.invalidate(schoolDetailProvider(schoolUid)),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(error.toString(), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () =>
                    ref.invalidate(schoolDetailProvider(schoolUid)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (detail) => DefaultTabController(
          length: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(school: detail.school),
              const TabBar(
                isScrollable: true,
                tabs: [
                  Tab(text: 'Tổng quan'),
                  Tab(text: 'Học sinh'),
                  Tab(text: 'GV/BGH'),
                  Tab(text: 'Người thân'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _Overview(school: detail.school),
                    _ParticipantList<StudentModel>(
                      items: detail.students,
                      emptyText: 'No students yet.',
                      builder: (student) => ListTile(
                        leading: const Icon(Icons.person_outline),
                        title: Text(student.fullName),
                        subtitle: Text(
                          'Grade ${student.grade} • ${student.className}',
                        ),
                      ),
                    ),
                    _ParticipantList<PersonModel>(
                      items: detail.persons,
                      emptyText: 'No teachers or staff yet.',
                      builder: (person) => ListTile(
                        leading: const Icon(Icons.badge_outlined),
                        title: Text(person.fullName),
                        subtitle: Text(person.role),
                      ),
                    ),
                    _ParticipantList<StudentRelativeModel>(
                      items: detail.relatives,
                      emptyText: 'No relatives yet.',
                      builder: (relative) => ListTile(
                        leading: const Icon(Icons.family_restroom),
                        title: Text(relative.fullName),
                        subtitle: Text(
                          '${relative.relationship} • ${relative.phone}\n'
                          'Student ID: ${relative.studentId}',
                        ),
                        isThreeLine: true,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.school});

  final SchoolModel school;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  school.schoolName,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 4),
                Text(school.schoolUid),
              ],
            ),
          ),
          Chip(label: Text(school.areaType.isEmpty ? 'N/A' : school.areaType)),
        ],
      ),
    );
  }
}

class _Overview extends StatelessWidget {
  const _Overview({required this.school});

  final SchoolModel school;

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String)>[
      ('Province', '${school.provinceName} (${school.provinceCode})'),
      ('Commune', '${school.communeName} (${school.communeCode})'),
      ('School code', school.schoolCode),
      ('Address', school.address),
    ];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: rows
          .map(
            (row) => Card(
              child: ListTile(
                title: Text(row.$1),
                subtitle: Text(row.$2.isEmpty ? 'N/A' : row.$2),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _ParticipantList<T> extends StatelessWidget {
  const _ParticipantList({
    required this.items,
    required this.emptyText,
    required this.builder,
  });

  final List<T> items;
  final String emptyText;
  final Widget Function(T item) builder;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return Center(child: Text(emptyText));
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, index) => builder(items[index]),
    );
  }
}
