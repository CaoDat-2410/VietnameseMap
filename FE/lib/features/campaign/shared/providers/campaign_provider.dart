import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/map/presentation/providers/map_provider.dart';
import '../../../school/shared/models/school_model.dart';
import '../models/campaign_models.dart';
import '../repositories/campaign_repository.dart';

final campaignRepositoryProvider = Provider<CampaignRepository>(
  (ref) => CampaignRepository(ref.watch(dioClientProvider)),
);

final campaignsProvider = FutureProvider<List<CampaignModel>>((ref) {
  return ref.watch(campaignRepositoryProvider).getCampaigns();
});

final campaignDetailProvider =
    FutureProvider.family<CampaignModel, int>((ref, campaignId) {
  return ref.watch(campaignRepositoryProvider).getCampaign(campaignId);
});

final campaignDashboardProvider =
    FutureProvider.family<CampaignDashboardModel, int>((ref, campaignId) {
  return ref.watch(campaignRepositoryProvider).getDashboard(campaignId);
});



final campaignEventsProvider =
    FutureProvider.family<List<CampaignEventModel>, int>((ref, campaignId) {
  return ref.watch(campaignRepositoryProvider).getEvents(campaignId);
});

final eventDetailProvider =
    FutureProvider.family<CampaignEventModel, int>((ref, eventId) {
  return ref.watch(campaignRepositoryProvider).getEvent(eventId);
});

final employeesProvider = FutureProvider<List<EmployeeModel>>((ref) {
  return ref.watch(campaignRepositoryProvider).getEmployees();
});

final eventSchoolsProvider =
    FutureProvider.family<List<SchoolModel>, int>((ref, eventId) {
  return ref.watch(campaignRepositoryProvider).getEventSchools(eventId);
});

final eventAssignmentsProvider =
    FutureProvider.family<List<EmployeeModel>, int>((ref, eventId) {
  return ref.watch(campaignRepositoryProvider).getEventAssignments(eventId);
});

final eventInteractionsProvider =
    FutureProvider.family<List<InteractionModel>, int>((ref, eventId) {
  return ref.watch(campaignRepositoryProvider).getInteractions(eventId);
});

final campaignRegistrationsProvider =
    FutureProvider.family<List<StudentRegistrationModel>, int>(
        (ref, campaignId) {
  return ref.watch(campaignRepositoryProvider).getCampaignRegistrations(
        campaignId,
      );
});

final myRegistrationsProvider =
    FutureProvider<List<StudentRegistrationModel>>((ref) {
  return ref.watch(campaignRepositoryProvider).getMyRegistrations();
});

final usersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(campaignRepositoryProvider).getUsers();
});
