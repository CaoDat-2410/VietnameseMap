import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/map/presentation/providers/map_provider.dart';
import '../models/campaign_models.dart';
import '../repositories/campaign_repository.dart';

final campaignRepositoryProvider = Provider<CampaignRepository>(
  (ref) => CampaignRepository(ref.watch(dioClientProvider)),
);

final campaignsProvider = FutureProvider<List<CampaignModel>>((ref) {
  return ref.watch(campaignRepositoryProvider).getCampaigns();
});

final campaignDashboardProvider =
    FutureProvider.family<CampaignDashboardModel, int>((ref, campaignId) {
  return ref.watch(campaignRepositoryProvider).getDashboard(campaignId);
});

final campaignEventsProvider =
    FutureProvider.family<List<CampaignEventModel>, int>((ref, campaignId) {
  return ref.watch(campaignRepositoryProvider).getEvents(campaignId);
});

final eventInteractionsProvider =
    FutureProvider.family<List<InteractionModel>, int>((ref, eventId) {
  return ref.watch(campaignRepositoryProvider).getInteractions(eventId);
});
