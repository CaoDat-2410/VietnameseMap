import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../campaign/shared/models/campaign_models.dart';
import '../../../campaign/shared/providers/campaign_provider.dart';
import '../../../auth/shared/providers/auth_provider.dart';

/// Home data for the Student role.
class StudentHomeModel {
  const StudentHomeModel({
    required this.registrations,
    required this.approvedCount,
    required this.pendingCount,
  });

  final List<StudentRegistrationModel> registrations;
  final int approvedCount;
  final int pendingCount;
}

/// Combines student registrations + available campaigns.
final studentHomeProvider = FutureProvider<StudentHomeModel>((ref) async {
  final registrations = await ref.watch(myRegistrationsProvider.future);
  final campaigns = await ref.watch(campaignsProvider.future);

  int approvedCount = 0;
  int pendingCount = 0;
  for (final r in registrations) {
    switch (r.status.toUpperCase()) {
      case 'APPROVED':
        approvedCount++;
        break;
      case 'PENDING':
        pendingCount++;
        break;
    }
  }

  // Filter campaigns that are currently accepting registrations
  final now = DateTime.now();
  final activeCampaigns = campaigns.where((c) {
    // Campaigns that haven't ended yet
    try {
      final endDate = DateTime.parse(c.endDate);
      return endDate.isAfter(now);
    } catch (_) {
      return true;
    }
  }).toList();

  return StudentHomeModel(
    registrations: registrations,
    approvedCount: approvedCount,
    pendingCount: pendingCount,
  );
});

/// Available campaigns for student registration.
final availableCampaignsProvider = FutureProvider<List<CampaignModel>>((ref) async {
  final campaigns = await ref.watch(campaignsProvider.future);
  final now = DateTime.now();
  return campaigns.where((c) {
    try {
      final endDate = DateTime.parse(c.endDate);
      return endDate.isAfter(now);
    } catch (_) {
      return true;
    }
  }).toList();
});
