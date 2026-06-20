import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../presentation/widgets/event_interactions_tab.dart';
import '../../shared/models/campaign_models.dart';
import '../../shared/providers/campaign_provider.dart';
import '../widgets/event_employees_tab.dart';
import '../widgets/event_form_dialog.dart';
import '../widgets/event_info_tab.dart';
import '../widgets/event_schools_tab.dart';
import '../widgets/event_status_chip.dart';
import '../widgets/event_type_chip.dart';
import '../../../school/shared/models/school_model.dart';

class EventDetailPage extends ConsumerStatefulWidget {
  const EventDetailPage({super.key, required this.eventId});

  final int eventId;

  @override
  ConsumerState<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends ConsumerState<EventDetailPage> {
  final Map<String, SchoolModel> _assignedSchools = {};
  final Set<int> _assignedEmployeeIds = {};

  Set<String> get _assignedSchoolUids => _assignedSchools.keys.toSet();

  @override
  Widget build(BuildContext context) {
    final eventAsync = ref.watch(eventDetailProvider(widget.eventId));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Detail'),
        actions: [
          IconButton(
            onPressed: () =>
                ref.invalidate(eventDetailProvider(widget.eventId)),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: eventAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(error.toString(), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () =>
                    ref.invalidate(eventDetailProvider(widget.eventId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (event) => DefaultTabController(
          length: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _EventHeader(event: event),
              const TabBar(
                isScrollable: true,
                tabs: [
                  Tab(text: 'Thông tin'),
                  Tab(text: 'Trường tham gia'),
                  Tab(text: 'Nhân sự'),
                  Tab(text: 'Interactions'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    EventInfoTab(event: event, onEdit: () => _editEvent(event)),
                    EventSchoolsTab(
                      assignedSchoolUids: _assignedSchoolUids,
                      onAssign: _assignSchool,
                      onRemove: _removeSchool,
                    ),
                    EventEmployeesTab(
                      assignedIds: _assignedEmployeeIds,
                      onAssign: _assignEmployee,
                      onRemove: _removeEmployee,
                    ),
                    EventInteractionsTab(
                      eventId: widget.eventId,
                      availableSchools: _assignedSchools.values.toList(),
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

  Future<void> _editEvent(CampaignEventModel event) async {
    final data = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => EventFormDialog(event: event),
    );
    if (data == null || !mounted) return;
    try {
      await ref
          .read(campaignRepositoryProvider)
          .updateEvent(widget.eventId, data);
      ref.invalidate(eventDetailProvider(widget.eventId));
      ref.invalidate(campaignEventsProvider(event.campaignId));
      _showMessage('Event updated.');
    } catch (error) {
      _showMessage('Update failed: $error');
    }
  }

  Future<void> _assignSchool(SchoolModel school) async {
    try {
      await ref
          .read(campaignRepositoryProvider)
          .assignSchool(widget.eventId, school.schoolUid);
      if (mounted) {
        setState(() => _assignedSchools[school.schoolUid] = school);
      }
      _showMessage('School assigned.');
    } catch (error) {
      _showMessage('Assign school failed: $error');
    }
  }

  Future<void> _removeSchool(SchoolModel school) async {
    try {
      await ref
          .read(campaignRepositoryProvider)
          .removeSchool(widget.eventId, school.schoolUid);
      if (mounted) {
        setState(() => _assignedSchools.remove(school.schoolUid));
      }
      _showMessage('School removed.');
    } catch (error) {
      _showMessage('Remove school failed: $error');
    }
  }

  Future<void> _assignEmployee(int employeeId) async {
    try {
      await ref
          .read(campaignRepositoryProvider)
          .assignEmployee(widget.eventId, employeeId);
      if (mounted) setState(() => _assignedEmployeeIds.add(employeeId));
      _showMessage('Employee assigned.');
    } catch (error) {
      _showMessage('Assign employee failed: $error');
    }
  }

  Future<void> _removeEmployee(int employeeId) async {
    try {
      await ref
          .read(campaignRepositoryProvider)
          .removeEmployee(widget.eventId, employeeId);
      if (mounted) setState(() => _assignedEmployeeIds.remove(employeeId));
      _showMessage('Employee removed.');
    } catch (error) {
      _showMessage('Remove employee failed: $error');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _EventHeader extends StatelessWidget {
  const _EventHeader({required this.event});

  final CampaignEventModel event;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(event.name, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              EventStatusChip(status: event.status),
              EventTypeChip(eventType: event.eventType),
            ],
          ),
        ],
      ),
    );
  }
}
