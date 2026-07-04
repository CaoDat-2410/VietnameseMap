import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../campaign/shared/providers/campaign_provider.dart';
import '../../../campaign/shared/models/campaign_models.dart';

@immutable
class StaffRegistrationsFilter {
  const StaffRegistrationsFilter({
    this.status,
    this.q,
  });

  final String? status;
  final String? q;

  StaffRegistrationsFilter copyWith({String? status, String? q, bool clearStatus = false, bool clearQ = false}) {
    return StaffRegistrationsFilter(
      status: clearStatus ? null : (status ?? this.status),
      q: clearQ ? null : (q ?? this.q),
    );
  }
}

final staffRegistrationsFilterProvider =
    StateProvider<StaffRegistrationsFilter>((ref) => const StaffRegistrationsFilter());

final staffRegistrationsProvider = FutureProvider.autoDispose<StaffRegistrationsPage>((ref) async {
  final filter = ref.watch(staffRegistrationsFilterProvider);
  final repo = ref.read(campaignRepositoryProvider);
  final result = await repo.listStaffRegistrations(
    status: filter.status,
    q: filter.q,
    limit: 200,
  );
  return StaffRegistrationsPage(
    items: result['items'] as List<StudentRegistrationModel>,
    totalItems: result['totalItems'] as int,
  );
});

class StaffRegistrationsPage {
  StaffRegistrationsPage({required this.items, required this.totalItems});
  final List<StudentRegistrationModel> items;
  final int totalItems;
}
