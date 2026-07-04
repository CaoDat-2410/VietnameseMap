import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/analytics/analytics_service.dart';
import '../../data/repositories/report_repository.dart';
import '../../domain/models/report_models.dart';

final reportRepositoryProvider = Provider<ReportRepository>((ref) => ReportRepository());

final campaignReportViewModelProvider =
    StateNotifierProvider<CampaignReportViewModel, AsyncValue<ReportExport?>>((ref) {
  return CampaignReportViewModel(ref.watch(reportRepositoryProvider));
});

class CampaignReportViewModel extends StateNotifier<AsyncValue<ReportExport?>> {
  CampaignReportViewModel(this._repository) : super(const AsyncData(null));

  final ReportRepository _repository;
  Timer? _pollTimer;

  Future<void> export(CampaignReportRequest request) async {
    state = const AsyncLoading();
    try {
      final report = await _repository.createCampaignPdf(request);
      state = AsyncData(report);
      await AnalyticsService.logEvent('report_export_started', {'report_type': 'campaign'});
      if (report.isPending) _startPolling(report.reportId);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<String?> downloadUrl() async {
    final report = state.valueOrNull;
    if (report == null || !report.isReady) return null;
    final withUrl = await _repository.getDownloadUrl(report.reportId);
    await AnalyticsService.logEvent('report_export_downloaded', {'report_id': report.reportId});
    state = AsyncData(withUrl);
    return withUrl.downloadUrl;
  }

  void _startPolling(int reportId) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      try {
        final report = await _repository.getReport(reportId);
        state = AsyncData(report);
        if (!report.isPending) timer.cancel();
      } catch (e, st) {
        timer.cancel();
        state = AsyncError(e, st);
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}
