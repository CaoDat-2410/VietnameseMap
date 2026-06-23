import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../auth/shared/providers/auth_provider.dart';
import '../../../map/presentation/widgets/event_map_preview.dart';
import '../../../school/shared/models/school_model.dart';
import '../../../school/shared/providers/schools_provider.dart';
import '../../../school/shared/repositories/schools_repository.dart';
import '../../presentation/widgets/event_interactions_tab.dart';
import '../../shared/models/campaign_models.dart';
import '../../shared/providers/campaign_provider.dart';
import '../widgets/event_form_dialog.dart';

class EventDetailPage extends ConsumerStatefulWidget {
  const EventDetailPage({super.key, required this.eventId});

  final int eventId;

  @override
  ConsumerState<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends ConsumerState<EventDetailPage>
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

  Future<void> _editEvent(CampaignEventModel event) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await showDialog<void>(
        context: context,
        builder: (context) => EventFormDialog(
          event: event,
          onSubmit: (data) async {
            await ref
                .read(campaignRepositoryProvider)
                .updateEvent(event.id, data);
            ref.invalidate(eventDetailProvider(event.id));
            ref.invalidate(campaignEventsProvider(event.campaignId));
            ref.invalidate(campaignDashboardProvider(event.campaignId));
          },
        ),
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.eventSaved)),
        );
      }
    } catch (error) {
      if (context.mounted) _showError(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final event = ref.watch(eventDetailProvider(widget.eventId));
    final role = ref.watch(activeUserProvider).valueOrNull?.role;
    final canManage = role == 'MANAGER' || role == 'ADMIN';

    return Scaffold(
      appBar: AppBar(
        title: event.maybeWhen(
          data: (item) => Text(item.name),
          orElse: () => Text(l10n.eventDetail),
        ),
        actions: [
          IconButton(
            tooltip: l10n.refresh,
            onPressed: () {
              ref.invalidate(eventDetailProvider(widget.eventId));
              ref.invalidate(eventSchoolsProvider(widget.eventId));
              ref.invalidate(eventAssignmentsProvider(widget.eventId));
              ref.invalidate(eventInteractionsProvider(widget.eventId));
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: event.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorBlock(
          error: error,
          onRetry: () => ref.invalidate(eventDetailProvider(widget.eventId)),
        ),
        data: (item) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: _EventHeader(event: item),
            ),
            Container(
              color: Theme.of(context).colorScheme.surface,
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs: [
                  Tab(text: l10n.thongTin),
                  Tab(text: l10n.truongThamGia),
                  Tab(text: l10n.nhanSu),
                  const Tab(text: 'Tương tác'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _EventInfoTab(
                    event: item,
                    canManage: canManage,
                    onEdit: () => _editEvent(item),
                  ),
                  _EventSchoolsTab(
                    eventId: item.id,
                    canManage: canManage,
                  ),
                  _EventEmployeesTab(
                    eventId: item.id,
                    canManage: canManage,
                  ),
                  EventInteractionsTab(eventId: item.id),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventHeader extends StatelessWidget {
  const _EventHeader({required this.event});

  final CampaignEventModel event;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(event.name, style: Theme.of(context).textTheme.headlineSmall),
        Chip(label: Text(event.status)),
        Chip(label: Text(event.eventType)),
      ],
    );
  }
}

class _EventInfoTab extends StatelessWidget {
  const _EventInfoTab({
    required this.event,
    required this.canManage,
    required this.onEdit,
  });

  final CampaignEventModel event;
  final bool canManage;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasLocation = event.hasLocation;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (canManage) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
              label: Text(l10n.edit),
            ),
          ),
          const SizedBox(height: 16),
        ],
        _InfoRow(label: l10n.name, value: event.name),
        _InfoRow(label: l10n.campaign, value: '#${event.campaignId}'),
        _InfoRow(label: l10n.type, value: event.eventType),
        _InfoRow(label: l10n.status, value: event.status),
        const SizedBox(height: 12),
        _TimeCard(event: event),
        if (event.locationLabel.isNotEmpty) ...[
          _InfoRow(label: l10n.locationLabel, value: event.locationLabel),
        ],
        _InfoRow(label: l10n.note, value: event.note),
        if (hasLocation) ...[
          const SizedBox(height: 16),
          EventMapPreview(
            lat: event.latitude!,
            lng: event.longitude!,
            label: event.name,
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.tonalIcon(
              onPressed: () {
                context.push(
                  '/map?lat=${event.latitude}&lng=${event.longitude}'
                  '&eventName=${Uri.encodeComponent(event.name)}',
                );
              },
              icon: const Icon(Icons.open_in_full),
              label: Text(l10n.viewOnFullMap),
            ),
          ),
        ],
      ],
    );
  }
}

class _TimeCard extends StatelessWidget {
  const _TimeCard({required this.event});

  final CampaignEventModel event;

  String _format(String raw) {
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    final local = parsed.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm';
  }

  String? _durationLabel() {
    final s = DateTime.tryParse(event.startsAt);
    final e = DateTime.tryParse(event.endsAt);
    if (s == null || e == null) return null;
    final diff = e.difference(s);
    if (diff.isNegative) return null;
    if (diff.inMinutes < 1) return '0m';
    final hours = diff.inHours;
    final minutes = diff.inMinutes - hours * 60;
    if (hours == 0) return '${minutes}m';
    if (minutes == 0) return '${hours}h';
    return '${hours}h ${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final duration = _durationLabel();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.schedule, size: 18, color: Colors.black54),
                const SizedBox(width: 8),
                Text(
                  l10n.time,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
                const Spacer(),
                if (duration != null)
                  Chip(
                    label: Text(duration),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            _InfoRow(label: l10n.startsAt, value: _format(event.startsAt)),
            _InfoRow(label: l10n.endsAt, value: _format(event.endsAt)),
          ],
        ),
      ),
    );
  }
}

class _EventSchoolsTab extends ConsumerStatefulWidget {
  const _EventSchoolsTab({
    required this.eventId,
    required this.canManage,
  });

  final int eventId;
  final bool canManage;

  @override
  ConsumerState<_EventSchoolsTab> createState() => _EventSchoolsTabState();
}

class _EventSchoolsTabState extends ConsumerState<_EventSchoolsTab> {
  final _searchController = TextEditingController();
  final _provinceController = TextEditingController();
  SchoolSearchParams _params = const SchoolSearchParams(limit: 20);
  bool _saving = false;

  @override
  void dispose() {
    _searchController.dispose();
    _provinceController.dispose();
    super.dispose();
  }

  void _search() {
    setState(() {
      _params = SchoolSearchParams(
        limit: 20,
        query: _searchController.text.trim(),
        provinceCode: _provinceController.text.trim(),
      );
    });
  }

  Future<void> _assign(SchoolModel school) async {
    final l10n = AppLocalizations.of(context)!;
    await _save(() async {
      await ref.read(campaignRepositoryProvider).assignSchool(
            widget.eventId,
            school.schoolUid,
          );
    }, l10n.schoolAssigned);
  }

  Future<void> _remove(SchoolModel school) async {
    final l10n = AppLocalizations.of(context)!;
    await _save(() async {
      await ref.read(campaignRepositoryProvider).removeSchool(
            widget.eventId,
            school.schoolUid,
          );
    }, l10n.schoolRemoved);
  }

  Future<void> _save(Future<void> Function() action, String message) async {
    setState(() => _saving = true);
    try {
      await action();
      ref.invalidate(eventSchoolsProvider(widget.eventId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (error) {
      if (mounted) _showError(context, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final assigned = ref.watch(eventSchoolsProvider(widget.eventId));
    final search = ref.watch(schoolsSearchProvider(_params));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(l10n.assignedSchools,
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        assigned.when(
          loading: () => const LinearProgressIndicator(),
          error: (error, _) => _InlineError(
            error: error,
            onRetry: () => ref.invalidate(eventSchoolsProvider(widget.eventId)),
          ),
          data: (items) => items.isEmpty
              ? Text(l10n.noAssignedSchools)
              : Column(
                  children: [
                    for (final school in items)
                      Card(
                        child: ListTile(
                          title: Text(school.schoolName),
                          subtitle: Text(
                              '${school.schoolUid} | ${school.provinceName}'),
                          trailing: widget.canManage
                              ? IconButton(
                                  tooltip: l10n.remove,
                                  onPressed:
                                      _saving ? null : () => _remove(school),
                                  icon: const Icon(Icons.delete_outline),
                                )
                              : null,
                        ),
                      ),
                  ],
                ),
        ),
        if (widget.canManage) ...[
          const SizedBox(height: 20),
          Text(l10n.findSchools, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              SizedBox(
                width: 260,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: l10n.search,
                    prefixIcon: const Icon(Icons.search),
                  ),
                  onSubmitted: (_) => _search(),
                ),
              ),
              SizedBox(
                width: 150,
                child: TextField(
                  controller: _provinceController,
                  decoration: InputDecoration(labelText: l10n.provinceCode),
                  onSubmitted: (_) => _search(),
                ),
              ),
              FilledButton.icon(
                onPressed: _search,
                icon: const Icon(Icons.search),
                label: Text(l10n.search),
              ),
            ],
          ),
          const SizedBox(height: 8),
          search.when(
            loading: () => const LinearProgressIndicator(),
            error: (error, _) => _InlineError(
              error: error,
              onRetry: () => ref.invalidate(schoolsSearchProvider(_params)),
            ),
            data: (page) => page.items.isEmpty
                ? Text(l10n.noSchoolsFound)
                : Column(
                    children: [
                      for (final school in page.items)
                        Card(
                          child: ListTile(
                            title: Text(school.schoolName),
                            subtitle: Text(
                              '${school.schoolUid} | ${school.provinceName} | ${school.communeName}',
                            ),
                            trailing: FilledButton(
                              onPressed:
                                  _saving ? null : () => _assign(school),
                              child: Text(l10n.assign),
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ],
    );
  }
}

class _EventEmployeesTab extends ConsumerStatefulWidget {
  const _EventEmployeesTab({
    required this.eventId,
    required this.canManage,
  });

  final int eventId;
  final bool canManage;

  @override
  ConsumerState<_EventEmployeesTab> createState() => _EventEmployeesTabState();
}

class _EventEmployeesTabState extends ConsumerState<_EventEmployeesTab> {
  bool _saving = false;

  Future<void> _assign(EmployeeModel employee) async {
    final l10n = AppLocalizations.of(context)!;
    await _save(() async {
      await ref.read(campaignRepositoryProvider).assignEmployee(
            widget.eventId,
            employee.id,
          );
    }, l10n.employeeAssigned);
  }

  Future<void> _remove(EmployeeModel employee) async {
    final l10n = AppLocalizations.of(context)!;
    await _save(() async {
      await ref.read(campaignRepositoryProvider).removeEmployee(
            widget.eventId,
            employee.id,
          );
    }, l10n.employeeRemoved);
  }

  Future<void> _save(Future<void> Function() action, String message) async {
    setState(() => _saving = true);
    try {
      await action();
      ref.invalidate(eventAssignmentsProvider(widget.eventId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (error) {
      if (mounted) _showError(context, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final assigned = ref.watch(eventAssignmentsProvider(widget.eventId));
    final employees = ref.watch(employeesProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(l10n.assignedEmployees,
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        assigned.when(
          loading: () => const LinearProgressIndicator(),
          error: (error, _) => _InlineError(
            error: error,
            onRetry: () =>
                ref.invalidate(eventAssignmentsProvider(widget.eventId)),
          ),
          data: (items) => items.isEmpty
              ? Text(l10n.noAssignedEmployees)
              : Column(
                  children: [
                    for (final employee in items)
                      Card(
                        child: ListTile(
                          title: Text(employee.fullName),
                          subtitle: Text(employee.role),
                          trailing: widget.canManage
                              ? IconButton(
                                  tooltip: l10n.remove,
                                  onPressed: _saving
                                      ? null
                                      : () => _remove(employee),
                                  icon: const Icon(Icons.delete_outline),
                                )
                              : null,
                        ),
                      ),
                  ],
                ),
        ),
        if (widget.canManage) ...[
          const SizedBox(height: 20),
          Text(l10n.employees, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          employees.when(
            loading: () => const LinearProgressIndicator(),
            error: (error, _) => _InlineError(
              error: error,
              onRetry: () => ref.invalidate(employeesProvider),
            ),
            data: (items) => items.isEmpty
                ? Text(l10n.noEmployees)
                : Column(
                    children: [
                      for (final employee in items)
                        Card(
                          child: ListTile(
                            title: Text(employee.fullName),
                            subtitle: Text(employee.role),
                            trailing: FilledButton(
                              onPressed:
                                  _saving ? null : () => _assign(employee),
                              child: Text(l10n.assign),
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ],
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
            width: 120,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(child: Text(value.isEmpty ? '-' : value)),
        ],
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: ListTile(
        title: Text(error.toString()),
        trailing: IconButton(
          tooltip: l10n.retry,
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
        ),
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

void _showError(BuildContext context, Object error) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(error.toString())),
  );
}
