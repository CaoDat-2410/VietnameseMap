import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../campaign/shared/models/campaign_models.dart';
import '../../../campaign/shared/providers/campaign_provider.dart';

/// Home data for the Staff role.
/// NOTE: Uses mock data until backend provides GET /api/v1/employees/{id}/stats
class StaffHomeModel {
  const StaffHomeModel({
    required this.eventsJoined,
    required this.interactionsLogged,
    required this.schoolsVisited,
    required this.assignedEvents,
    required this.recentInteractions,
  });

  final int eventsJoined;
  final int interactionsLogged;
  final int schoolsVisited;
  final List<CampaignEventModel> assignedEvents;
  final List<InteractionModel> recentInteractions;
}

/// Staff home — uses mock data since no employee-stats API exists yet.
final staffHomeProvider = FutureProvider<StaffHomeModel>((ref) async {
  // TODO: Replace with real API call once backend implements
  //   GET /api/v1/employees/{id}/stats
  // For now, derive from events/interactions the staff is assigned to.

  // Fetch first campaign to get events
  final campaigns = await ref.watch(campaignsProvider.future);
  if (campaigns.isEmpty) {
    return const StaffHomeModel(
      eventsJoined: 0,
      interactionsLogged: 0,
      schoolsVisited: 0,
      assignedEvents: [],
      recentInteractions: [],
    );
  }

  final events = await ref.watch(campaignEventsProvider(campaigns.first.id).future);

  // Count interactions across all events
  int totalInteractions = 0;
  int totalSchools = 0;
  final schoolsSeen = <String>{};
  for (final event in events) {
    final interactions = await ref
        .watch(eventInteractionsProvider(event.id).future);
    totalInteractions += interactions.length;
    if (event.schoolUid != null && schoolsSeen.add(event.schoolUid!)) {
      totalSchools++;
    }
  }

  return StaffHomeModel(
    eventsJoined: events.length,
    interactionsLogged: totalInteractions,
    schoolsVisited: totalSchools,
    assignedEvents: events.take(8).toList(),
    recentInteractions: [], // interactions would be enriched with employee filter
  );
});
