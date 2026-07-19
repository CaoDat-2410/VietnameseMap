import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/report_repository.dart';
import '../providers/report_viewmodel.dart';

final reportCampaignsProvider = FutureProvider<List<CampaignSummary>>((ref) async {
  final repo = ref.watch(reportRepositoryProvider);
  return repo.getCampaigns();
});

final reportEmployeesProvider = FutureProvider<List<EmployeeSummary>>((ref) async {
  final repo = ref.watch(reportRepositoryProvider);
  return repo.getEmployees();
});

final reportSchoolsProvider = FutureProvider.family<List<SchoolSummary>, String?>((ref, provinceCode) async {
  final repo = ref.watch(reportRepositoryProvider);
  if (provinceCode == null) {
    final first = await repo.getSchools(page: 0, query: '');
    return first.items;
  }
  final result = await repo.getSchools(page: 0, query: '');
  return result.items.where((s) => s.provinceCode == provinceCode).toList();
});