import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/bento_card.dart';
import '../../data/repositories/report_repository.dart' show EmployeeSummary, CampaignSummary, SchoolSummary;
import '../../domain/models/report_models.dart';
import '../providers/report_viewmodel.dart';

// ============================================================
// Data providers
// ============================================================

final reportCampaignsProvider = FutureProvider<List<CampaignSummary>>((ref) async {
  final repo = ref.watch(reportRepositoryProvider);
  return repo.getCampaigns();
});

final reportEmployeesProvider = FutureProvider<List<EmployeeSummary>>((ref) async {
  final repo = ref.watch(reportRepositoryProvider);
  return repo.getEmployees();
});

final reportProvincesProvider = FutureProvider<List<ProvinceOption>>((ref) async {
  return _provinces;
});

final reportSchoolsProvider = FutureProvider.family<List<SchoolSummary>, String?>((ref, provinceCode) async {
  final repo = ref.watch(reportRepositoryProvider);
  if (provinceCode == null) return [];
  final result = await repo.getSchools(page: 0, query: '');
  return result.items.where((s) => s.provinceCode == provinceCode).toList();
});

// ============================================================
// Province data
// ============================================================

class ProvinceOption {
  final String code;
  final String name;
  const ProvinceOption({required this.code, required this.name});
}

const _provinces = <ProvinceOption>[
  ProvinceOption(code: '01', name: 'Ha Noi'),
  ProvinceOption(code: '02', name: 'Ha Giang'),
  ProvinceOption(code: '04', name: 'Cao Bang'),
  ProvinceOption(code: '06', name: 'Bac Kan'),
  ProvinceOption(code: '08', name: 'Tuyen Quang'),
  ProvinceOption(code: '10', name: 'Lao Cai'),
  ProvinceOption(code: '11', name: 'Dien Bien'),
  ProvinceOption(code: '12', name: 'Lai Chau'),
  ProvinceOption(code: '14', name: 'Son La'),
  ProvinceOption(code: '15', name: 'Yen Bai'),
  ProvinceOption(code: '17', name: 'Hoa Binh'),
  ProvinceOption(code: '19', name: 'Thai Nguyen'),
  ProvinceOption(code: '20', name: 'Lang Son'),
  ProvinceOption(code: '22', name: 'Quang Ninh'),
  ProvinceOption(code: '24', name: 'Bac Giang'),
  ProvinceOption(code: '25', name: 'Phu Tho'),
  ProvinceOption(code: '26', name: 'Vinh Phuc'),
  ProvinceOption(code: '27', name: 'Bac Ninh'),
  ProvinceOption(code: '30', name: 'Hai Duong'),
  ProvinceOption(code: '31', name: 'Hung Yen'),
  ProvinceOption(code: '33', name: 'Ha Nam'),
  ProvinceOption(code: '34', name: 'Nam Dinh'),
  ProvinceOption(code: '35', name: 'Thai Binh'),
  ProvinceOption(code: '36', name: 'Ninh Binh'),
  ProvinceOption(code: '37', name: 'Thanh Hoa'),
  ProvinceOption(code: '38', name: 'Nghe An'),
  ProvinceOption(code: '40', name: 'Ha Tinh'),
  ProvinceOption(code: '42', name: 'Quang Binh'),
  ProvinceOption(code: '44', name: 'Quang Tri'),
  ProvinceOption(code: '45', name: 'Thua Thien Hue'),
  ProvinceOption(code: '46', name: 'Da Nang'),
  ProvinceOption(code: '48', name: 'Quang Nam'),
  ProvinceOption(code: '49', name: 'Quang Ngai'),
  ProvinceOption(code: '51', name: 'Binh Dinh'),
  ProvinceOption(code: '52', name: 'Phu Yen'),
  ProvinceOption(code: '54', name: 'Khanh Hoa'),
  ProvinceOption(code: '56', name: 'Ninh Thuan'),
  ProvinceOption(code: '58', name: 'Binh Thuan'),
  ProvinceOption(code: '60', name: 'Kon Tum'),
  ProvinceOption(code: '62', name: 'Gia Lai'),
  ProvinceOption(code: '64', name: 'Dak Lak'),
  ProvinceOption(code: '66', name: 'Dak Nong'),
  ProvinceOption(code: '67', name: 'Lam Dong'),
  ProvinceOption(code: '68', name: 'Binh Phuoc'),
  ProvinceOption(code: '70', name: 'Tay Ninh'),
  ProvinceOption(code: '72', name: 'Binh Duong'),
  ProvinceOption(code: '74', name: 'Dong Nai'),
  ProvinceOption(code: '75', name: 'Ba Ria - Vung Tau'),
  ProvinceOption(code: '77', name: 'Ho Chi Minh'),
  ProvinceOption(code: '79', name: 'Can Tho'),
  ProvinceOption(code: '80', name: 'Hau Giang'),
  ProvinceOption(code: '82', name: 'Kien Giang'),
  ProvinceOption(code: '84', name: 'Tien Giang'),
  ProvinceOption(code: '86', name: 'Ben Tre'),
  ProvinceOption(code: '87', name: 'Tra Vinh'),
  ProvinceOption(code: '89', name: 'Vinh Long'),
  ProvinceOption(code: '91', name: 'Dong Thap'),
  ProvinceOption(code: '92', name: 'An Giang'),
  ProvinceOption(code: '96', name: 'Ca Mau'),
];

// ============================================================
// Report page
// ============================================================

class CampaignReportPage extends ConsumerStatefulWidget {
  const CampaignReportPage({super.key});

  @override
  ConsumerState<CampaignReportPage> createState() => _CampaignReportPageState();
}

class _CampaignReportPageState extends ConsumerState<CampaignReportPage> {
  CampaignSummary? _selectedCampaign;
  DateTime? _fromDate;
  DateTime? _toDate;
  String? _selectedProvince;
  SchoolSummary? _selectedSchool;
  String? _eventType;
  String? _eventStatus;
  String? _registrationStatus;
  String? _interactionOutcome;
  EmployeeSummary? _selectedEmployee;
  final Set<String> _sections = {..._allSections};
  bool _includeArchived = false;

  static const _allSections = [
    'summary',
    'events',
    'schools',
    'assignments',
    'registrations',
    'interactions',
    'analytics',
  ];

  static const _eventTypes = ['WORKSHOP', 'SEMINAR', 'MEETING', 'FIELD_TRIP', 'TRAINING', 'OTHER'];
  static const _registrationStatuses = ['PENDING', 'APPROVED', 'REJECTED', 'CANCELLED'];
  static const _interactionOutcomes = ['SUCCESSFUL', 'FOLLOW_UP', 'NO_RESPONSE', 'INTERESTED', 'NOT_INTERESTED'];

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(campaignReportViewModelProvider);
    final report = state.valueOrNull;
    final isPending = report?.isPending == true || state.isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Bao cao chien dich PDF')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BentoCard(
              padding: const EdgeInsets.all(20),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 700;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Bo loc bao cao',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (isWide) ...[
                        _buildRow1(isPending),
                        const SizedBox(height: 16),
                        _buildRow2(isPending),
                        const SizedBox(height: 16),
                        _buildRow3(isPending),
                        const SizedBox(height: 16),
                        _buildRow4(isPending, report?.isReady == true),
                      ] else ...[
                        _buildNarrowLayout(isPending, report?.isReady == true),
                      ],
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            _buildStatusPanel(state),
          ],
        ),
      ),
    );
  }

  Widget _buildRow1(bool isPending) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _CampaignDropdown(value: _selectedCampaign, onChanged: (c) => setState(() => _selectedCampaign = c), enabled: !isPending)),
        const SizedBox(width: 16),
        Expanded(child: _SimpleDropdown(label: 'Loai su kien', value: _eventType, hint: 'Tat ca loai', items: _eventTypes, onChanged: (v) => setState(() => _eventType = v), enabled: !isPending)),
        const SizedBox(width: 16),
        Expanded(child: _EmployeeDropdown(value: _selectedEmployee, onChanged: (e) => setState(() => _selectedEmployee = e), enabled: !isPending)),
      ],
    );
  }

  Widget _buildRow2(bool isPending) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _DatePickerField(label: 'Tu ngay', value: _fromDate, onChanged: (d) => setState(() => _fromDate = d), enabled: !isPending)),
        const SizedBox(width: 16),
        Expanded(child: _DatePickerField(label: 'Den ngay', value: _toDate, onChanged: (d) => setState(() => _toDate = d), enabled: !isPending)),
      ],
    );
  }

  Widget _buildRow3(bool isPending) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _ProvinceDropdown(value: _selectedProvince, onChanged: (p) => setState(() { _selectedProvince = p; _selectedSchool = null; }), enabled: !isPending)),
        const SizedBox(width: 16),
        Expanded(child: _SchoolDropdown(provinceCode: _selectedProvince, value: _selectedSchool, onChanged: (s) => setState(() => _selectedSchool = s), enabled: !isPending)),
      ],
    );
  }

  Widget _buildRow4(bool isPending, bool isReady) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Bao gom chien dich da luu tru'),
          value: _includeArchived,
          onChanged: isPending ? null : (value) => setState(() => _includeArchived = value),
        )),
        const SizedBox(width: 16),
        FilledButton.icon(
          onPressed: isPending ? null : _export,
          icon: const Icon(Icons.picture_as_pdf),
          label: Text(isPending ? 'Dang tao...' : 'Xuat PDF'),
        ),
        if (isReady) ...[
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: _download,
            icon: const Icon(Icons.download),
            label: const Text('Tai xuong'),
          ),
        ],
      ],
    );
  }

  Widget _buildNarrowLayout(bool isPending, bool isReady) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CampaignDropdown(value: _selectedCampaign, onChanged: (c) => setState(() => _selectedCampaign = c), enabled: !isPending),
        const SizedBox(height: 16),
        _SimpleDropdown(label: 'Loai su kien', value: _eventType, hint: 'Tat ca loai', items: _eventTypes, onChanged: (v) => setState(() => _eventType = v), enabled: !isPending),
        const SizedBox(height: 16),
        _EmployeeDropdown(value: _selectedEmployee, onChanged: (e) => setState(() => _selectedEmployee = e), enabled: !isPending),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _DatePickerField(label: 'Tu ngay', value: _fromDate, onChanged: (d) => setState(() => _fromDate = d), enabled: !isPending)),
            const SizedBox(width: 12),
            Expanded(child: _DatePickerField(label: 'Den ngay', value: _toDate, onChanged: (d) => setState(() => _toDate = d), enabled: !isPending)),
          ],
        ),
        const SizedBox(height: 16),
        _ProvinceDropdown(value: _selectedProvince, onChanged: (p) => setState(() { _selectedProvince = p; _selectedSchool = null; }), enabled: !isPending),
        const SizedBox(height: 16),
        _SchoolDropdown(provinceCode: _selectedProvince, value: _selectedSchool, onChanged: (s) => setState(() => _selectedSchool = s), enabled: !isPending),
        const SizedBox(height: 16),
        _SimpleDropdown(label: 'Trang thai DK', value: _registrationStatus, hint: 'Tat ca', items: _registrationStatuses, onChanged: (v) => setState(() => _registrationStatus = v), enabled: !isPending),
        const SizedBox(height: 16),
        _SimpleDropdown(label: 'Ket qua TU', value: _interactionOutcome, hint: 'Tat ca', items: _interactionOutcomes, onChanged: (v) => setState(() => _interactionOutcome = v), enabled: !isPending),
        const SizedBox(height: 16),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Bao gom chien dich da luu tru'),
          value: _includeArchived,
          onChanged: isPending ? null : (value) => setState(() => _includeArchived = value),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: isPending ? null : _export,
                icon: const Icon(Icons.picture_as_pdf),
                label: Text(isPending ? 'Dang tao...' : 'Xuat PDF'),
              ),
            ),
            if (isReady) ...[
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: _download,
                icon: const Icon(Icons.download),
                label: const Text('Tai'),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildStatusPanel(AsyncValue<ReportExport?> state) {
    return state.when(
      loading: () => const LinearProgressIndicator(),
      error: (error, _) => _StatusPanel(
        icon: Icons.error_outline,
        iconColor: AppColors.error,
        title: 'Yeu cau bao cao that bai',
        message: error.toString(),
      ),
      data: (value) {
        if (value == null) return const SizedBox.shrink();
        if (value.isPending) {
          return _StatusPanel(
            icon: Icons.hourglass_top,
            iconColor: AppColors.warning,
            title: 'Bao cao #${value.reportId} dang tao',
            message: 'Trang nay se tu dong lam moi.',
          );
        }
        if (value.isFailed) {
          return _StatusPanel(
            icon: Icons.error_outline,
            iconColor: AppColors.error,
            title: 'Bao cao #${value.reportId} that bai',
            message: value.errorMessage ?? 'Backend khong the tao PDF nay.',
          );
        }
        return _StatusPanel(
          icon: Icons.check_circle_outline,
          iconColor: AppColors.success,
          title: 'Bao cao #${value.reportId} da san sang',
          message: value.fileName ?? 'PDF da san sang de tai xuong.',
        );
      },
    );
  }

  Future<void> _export() async {
    final request = CampaignReportRequest(
      campaignId: _selectedCampaign?.id,
      fromDate: _fromDate,
      toDate: _toDate,
      eventType: _eventType,
      eventStatus: _eventStatus,
      provinceCode: _selectedProvince,
      schoolUid: _selectedSchool?.uid,
      employeeId: _selectedEmployee?.id,
      registrationStatus: _registrationStatus,
      interactionOutcome: _interactionOutcome,
      includeArchived: _includeArchived,
      sections: _sections.toList(),
    );
    await ref.read(campaignReportViewModelProvider.notifier).export(request);
  }

  Future<void> _download() async {
    final url = await ref.read(campaignReportViewModelProvider.notifier).downloadUrl();
    if (url == null) return;
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, webOnlyWindowName: '_blank')) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Khong the mo URL tai xuong')),
        );
      }
    }
  }
}

// ============================================================
// Generic dropdown for string values
// ============================================================

class _SimpleDropdown extends StatelessWidget {
  const _SimpleDropdown({
    required this.label,
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
    required this.enabled,
  });

  final String label;
  final String? value;
  final String hint;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: [
        DropdownMenuItem<String>(value: null, child: Text(hint)),
        ...items.map((e) => DropdownMenuItem(value: e, child: Text(e))),
      ],
      onChanged: enabled ? onChanged : null,
    );
  }
}

// ============================================================
// Campaign dropdown
// ============================================================

class _CampaignDropdown extends ConsumerWidget {
  const _CampaignDropdown({required this.value, required this.onChanged, required this.enabled});

  final CampaignSummary? value;
  final ValueChanged<CampaignSummary?> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final campaignsAsync = ref.watch(reportCampaignsProvider);

    return campaignsAsync.when(
      loading: () => const TextField(
        enabled: false,
        decoration: InputDecoration(
          labelText: 'Chien dich',
          prefixIcon: Icon(Icons.campaign_outlined),
          border: OutlineInputBorder(),
        ),
      ),
      error: (_, __) => const TextField(
        enabled: false,
        decoration: InputDecoration(
          labelText: 'Chien dich',
          prefixIcon: Icon(Icons.campaign_outlined),
          border: OutlineInputBorder(),
          errorText: 'Loi tai danh sach',
        ),
      ),
      data: (campaigns) => DropdownButtonFormField<CampaignSummary>(
        value: campaigns.any((c) => c.id == value?.id) ? value : null,
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: 'Chien dich',
          prefixIcon: Icon(Icons.campaign_outlined),
          border: OutlineInputBorder(),
        ),
        items: [
          const DropdownMenuItem<CampaignSummary>(value: null, child: Text('Tat ca chien dich')),
          ...campaigns.map((c) => DropdownMenuItem(value: c, child: Text(c.name, overflow: TextOverflow.ellipsis))),
        ],
        onChanged: enabled ? onChanged : null,
      ),
    );
  }
}

// ============================================================
// Employee dropdown
// ============================================================

class _EmployeeDropdown extends ConsumerWidget {
  const _EmployeeDropdown({required this.value, required this.onChanged, required this.enabled});

  final EmployeeSummary? value;
  final ValueChanged<EmployeeSummary?> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employeesAsync = ref.watch(reportEmployeesProvider);

    return employeesAsync.when(
      loading: () => const TextField(
        enabled: false,
        decoration: InputDecoration(
          labelText: 'Nhan vien',
          prefixIcon: Icon(Icons.person_outlined),
          border: OutlineInputBorder(),
        ),
      ),
      error: (_, __) => const TextField(
        enabled: false,
        decoration: InputDecoration(
          labelText: 'Nhan vien',
          prefixIcon: Icon(Icons.person_outlined),
          border: OutlineInputBorder(),
          errorText: 'Loi tai danh sach',
        ),
      ),
      data: (employees) => DropdownButtonFormField<EmployeeSummary>(
        value: employees.any((e) => e.id == value?.id) ? value : null,
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: 'Nhan vien',
          prefixIcon: Icon(Icons.person_outlined),
          border: OutlineInputBorder(),
        ),
        items: [
          const DropdownMenuItem<EmployeeSummary>(value: null, child: Text('Tat ca nhan vien')),
          ...employees.map((e) => DropdownMenuItem(
            value: e,
            child: Text('${e.name} (${e.role})', overflow: TextOverflow.ellipsis),
          )),
        ],
        onChanged: enabled ? onChanged : null,
      ),
    );
  }
}

// ============================================================
// Date picker field
// ============================================================

class _DatePickerField extends StatelessWidget {
  const _DatePickerField({required this.label, required this.value, required this.onChanged, required this.enabled});

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled
          ? () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: value ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              );
              if (picked != null) onChanged(picked);
            }
          : null,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today_outlined),
          border: const OutlineInputBorder(),
          suffixIcon: value != null
              ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: enabled ? () => onChanged(null) : null)
              : null,
        ),
        child: Text(
          value != null ? _formatDate(value!) : 'Chon ngay',
          style: value == null ? TextStyle(color: Theme.of(context).hintColor) : null,
        ),
      ),
    );
  }

  String _formatDate(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

// ============================================================
// Province dropdown
// ============================================================

class _ProvinceDropdown extends StatelessWidget {
  const _ProvinceDropdown({required this.value, required this.onChanged, required this.enabled});

  final String? value;
  final ValueChanged<String?> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Tinh/Thanh pho',
        prefixIcon: Icon(Icons.location_on_outlined),
        border: OutlineInputBorder(),
      ),
      items: [
        const DropdownMenuItem<String>(value: null, child: Text('Tat ca tinh/thanh')),
        ..._provinces.map((p) => DropdownMenuItem(value: p.code, child: Text(p.name, overflow: TextOverflow.ellipsis))),
      ],
      onChanged: enabled ? onChanged : null,
    );
  }
}

// ============================================================
// School dropdown
// ============================================================

class _SchoolDropdown extends ConsumerWidget {
  const _SchoolDropdown({required this.provinceCode, required this.value, required this.onChanged, required this.enabled});

  final String? provinceCode;
  final SchoolSummary? value;
  final ValueChanged<SchoolSummary?> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schoolsAsync = ref.watch(reportSchoolsProvider(provinceCode));

    return schoolsAsync.when(
      loading: () => const TextField(
        enabled: false,
        decoration: InputDecoration(
          labelText: 'Truong hoc',
          prefixIcon: Icon(Icons.school_outlined),
          border: OutlineInputBorder(),
        ),
      ),
      error: (_, __) => const TextField(
        enabled: false,
        decoration: InputDecoration(
          labelText: 'Truong hoc',
          prefixIcon: Icon(Icons.school_outlined),
          border: OutlineInputBorder(),
          errorText: 'Loi tai truong',
        ),
      ),
      data: (schools) {
        final valid = schools.any((s) => s.uid == value?.uid) ? value : null;
        return DropdownButtonFormField<SchoolSummary>(
          value: valid,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Truong hoc',
            prefixIcon: Icon(Icons.school_outlined),
            border: OutlineInputBorder(),
          ),
          items: [
            const DropdownMenuItem<SchoolSummary>(value: null, child: Text('Tat ca truong')),
            ...schools.map((s) => DropdownMenuItem(
              value: s,
              child: Text('${s.name} (${s.provinceName ?? s.uid})', overflow: TextOverflow.ellipsis),
            )),
          ],
          onChanged: enabled ? onChanged : null,
        );
      },
    );
  }
}

// ============================================================
// Status panel
// ============================================================

class _StatusPanel extends StatelessWidget {
  const _StatusPanel({required this.icon, required this.iconColor, required this.title, required this.message});

  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(message),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
