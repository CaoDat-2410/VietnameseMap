import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/school_model.dart';
import '../../shared/providers/schools_provider.dart';

class SchoolDetailPage extends ConsumerWidget {
  const SchoolDetailPage({super.key, required this.schoolUid});

  final String schoolUid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(schoolDetailProvider(schoolUid));

    return Scaffold(
      appBar: AppBar(title: const Text('School Detail')),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorBlock(
          error: error,
          onRetry: () => ref.invalidate(schoolDetailProvider(schoolUid)),
        ),
        data: (data) => DefaultTabController(
          length: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: _SchoolHeader(school: data.school),
              ),
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
                    _OverviewTab(school: data.school),
                    _StudentsTab(students: data.students),
                    _PersonsTab(persons: data.persons),
                    _RelativesTab(relatives: data.relatives),
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

class _SchoolHeader extends StatelessWidget {
  const _SchoolHeader({required this.school});

  final SchoolModel school;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(school.schoolName,
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Chip(label: Text(school.schoolUid)),
            Chip(
                label: Text(school.areaType.isEmpty ? 'N/A' : school.areaType)),
          ],
        ),
      ],
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.school});

  final SchoolModel school;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _InfoRow(label: 'Province', value: school.provinceName),
        _InfoRow(label: 'Province code', value: school.provinceCode),
        _InfoRow(label: 'Commune', value: school.communeName),
        _InfoRow(label: 'Commune code', value: school.communeCode),
        _InfoRow(label: 'School code', value: school.schoolCode),
        _InfoRow(label: 'Address', value: school.address),
      ],
    );
  }
}

class _StudentsTab extends StatelessWidget {
  const _StudentsTab({required this.students});

  final List<StudentModel> students;

  @override
  Widget build(BuildContext context) {
    if (students.isEmpty) return const _EmptyBlock(message: 'No students');
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: students.length,
      itemBuilder: (context, index) {
        final item = students[index];
        return Card(
          child: ListTile(
            title: Text(item.fullName),
            subtitle: Text('Grade ${item.grade} | Class ${item.className}'),
            trailing: Text('#${item.id}'),
          ),
        );
      },
    );
  }
}

class _PersonsTab extends StatelessWidget {
  const _PersonsTab({required this.persons});

  final List<PersonModel> persons;

  @override
  Widget build(BuildContext context) {
    if (persons.isEmpty) {
      return const _EmptyBlock(message: 'No teachers/persons');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: persons.length,
      itemBuilder: (context, index) {
        final item = persons[index];
        return Card(
          child: ListTile(
            title: Text(item.fullName),
            subtitle: Text(item.role),
            trailing: Text('#${item.id}'),
          ),
        );
      },
    );
  }
}

class _RelativesTab extends StatelessWidget {
  const _RelativesTab({required this.relatives});

  final List<StudentRelativeModel> relatives;

  @override
  Widget build(BuildContext context) {
    if (relatives.isEmpty) return const _EmptyBlock(message: 'No relatives');
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: relatives.length,
      itemBuilder: (context, index) {
        final item = relatives[index];
        return Card(
          child: ListTile(
            title: Text(item.fullName),
            subtitle: Text('${item.relationship} | ${item.phone}'),
            trailing: Text('Student #${item.studentId}'),
          ),
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(child: Text(value.isEmpty ? '-' : value)),
        ],
      ),
    );
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

class _EmptyBlock extends StatelessWidget {
  const _EmptyBlock({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(message));
  }
}
