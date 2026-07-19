import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../shared/models/school_model.dart';
import '../../shared/providers/schools_provider.dart';

class SchoolDetailPage extends ConsumerStatefulWidget {
  const SchoolDetailPage({super.key, required this.schoolUid});

  final String schoolUid;

  @override
  ConsumerState<SchoolDetailPage> createState() => _SchoolDetailPageState();
}

class _SchoolDetailPageState extends ConsumerState<SchoolDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final detail = ref.watch(schoolDetailProvider(widget.schoolUid));

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.schoolDetail),
          actions: [
            IconButton(
              icon: const Icon(Icons.map),
              tooltip: 'Show on Map',
              onPressed: () => context.go('/map?schools=${widget.schoolUid}'),
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: [
              Tab(text: l10n.tongQuan),
              Tab(text: l10n.hocSinh),
              Tab(text: l10n.gvBgh),
              Tab(text: l10n.nguoiThan),
            ],
          ),
        ),
        body: detail.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _ErrorBlock(
            error: error,
            onRetry: () => ref.invalidate(schoolDetailProvider(widget.schoolUid)),
          ),
          data: (data) => TabBarView(
            controller: _tabController,
            children: [
              _OverviewTab(school: data.school),
              _StudentsTab(students: data.students, l10n: l10n),
              _PersonsTab(persons: data.persons, l10n: l10n),
              _RelativesTab(relatives: data.relatives, l10n: l10n),
            ],
          ),
        ),
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.school});

  final SchoolModel school;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListView(
      padding: const EdgeInsets.all(16),
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
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 8),
        _InfoRow(label: l10n.province, value: school.provinceName),
        _InfoRow(label: l10n.provinceCode, value: school.provinceCode),
        _InfoRow(label: l10n.commune, value: school.communeName),
        _InfoRow(label: l10n.communeCode, value: school.communeCode),
        _InfoRow(label: l10n.schoolCode, value: school.schoolCode),
        _InfoRow(label: l10n.address, value: school.address),
        if (school.hasCoordinates)
          _InfoRow(
            label: 'Tọa độ',
            value: '${school.latitude!.toStringAsFixed(5)}, ${school.longitude!.toStringAsFixed(5)}',
          ),
        if (school.geocodeStatus != null)
          _InfoRow(
            label: 'Trạng thái vị trí',
            value: school.geocodeStatusDisplay,
          ),
        if (school.isApproximate && school.geocodeNote != null)
          Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.orange.shade700, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    school.geocodeNote!,
                    style: TextStyle(color: Colors.orange.shade800),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _StudentsTab extends StatelessWidget {
  const _StudentsTab({required this.students, required this.l10n});

  final List<StudentModel> students;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    if (students.isEmpty) return _EmptyBlock(message: l10n.noStudents);
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: students.length,
      itemBuilder: (context, index) {
        final item = students[index];
        return Card(
          child: ListTile(
            title: Text(item.fullName),
            subtitle: Text('${l10n.grade} ${item.grade} | ${l10n.classLabel} ${item.className}'),
            trailing: Text('#${item.id}'),
          ),
        );
      },
    );
  }
}

class _PersonsTab extends StatelessWidget {
  const _PersonsTab({required this.persons, required this.l10n});

  final List<PersonModel> persons;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    if (persons.isEmpty) {
      return _EmptyBlock(message: l10n.noTeachersPersons);
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
  const _RelativesTab({required this.relatives, required this.l10n});

  final List<StudentRelativeModel> relatives;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    if (relatives.isEmpty) return _EmptyBlock(message: l10n.noRelatives);
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
            child: Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
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
    final l10n = AppLocalizations.of(context)!;
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
                label: Text(l10n.retry),
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
