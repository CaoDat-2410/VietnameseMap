import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/map/presentation/providers/map_provider.dart';
import '../models/school_model.dart';
import '../repositories/schools_repository.dart';

final schoolsRepositoryProvider = Provider<SchoolsRepository>(
  (ref) => SchoolsRepository(ref.watch(dioClientProvider)),
);

final schoolsSearchProvider =
    FutureProvider.family<PagedResponse<SchoolModel>, SchoolSearchParams>(
        (ref, params) {
  return ref.watch(schoolsRepositoryProvider).searchSchools(params);
});

final schoolDetailProvider =
    FutureProvider.family<SchoolDetailModel, String>((ref, schoolUid) {
  return ref.watch(schoolsRepositoryProvider).getSchool(schoolUid);
});
