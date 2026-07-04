import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../campaign/shared/models/campaign_models.dart';
import '../../../campaign/shared/providers/campaign_provider.dart';
import '../providers/staff_registrations_provider.dart';

class StaffRegistrationsPage extends ConsumerStatefulWidget {
  const StaffRegistrationsPage({super.key});

  @override
  ConsumerState<StaffRegistrationsPage> createState() =>
      _StaffRegistrationsPageState();
}

class _StaffRegistrationsPageState
    extends ConsumerState<StaffRegistrationsPage> {
  final Set<int> _selectedIds = {};
  bool _bulkInProgress = false;

  @override
  void dispose() {
    _selectedIds.clear();
    super.dispose();
  }

  Future<void> _bulkUpdate(String status) async {
    if (_selectedIds.isEmpty || _bulkInProgress) return;
    setState(() => _bulkInProgress = true);
    final repo = ref.read(campaignRepositoryProvider);
    try {
      final updated = await repo.bulkUpdateRegistrationStatus(
        _selectedIds.toList(),
        status,
      );
      _selectedIds.clear();
      ref.invalidate(staffRegistrationsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã cập nhật $updated đơn')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    } finally {
      if (mounted) setState(() => _bulkInProgress = false);
    }
  }

  Future<void> _updateOne(int id, String status) async {
    try {
      await ref.read(campaignRepositoryProvider).updateRegistrationStatus(id, status);
      ref.invalidate(staffRegistrationsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã cập nhật #$id → $status')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(staffRegistrationsFilterProvider);
    final registrationsAsync = ref.watch(staffRegistrationsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Duyệt đơn đăng ký'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(staffRegistrationsProvider),
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Toolbar(
            filter: filter,
            selectedCount: _selectedIds.length,
            bulkInProgress: _bulkInProgress,
            onApprove: () => _bulkUpdate('APPROVED'),
            onReject: () => _bulkUpdate('REJECTED'),
          ),
          Expanded(
            child: registrationsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Lỗi tải đơn đăng ký: $e',
                      style: theme.textTheme.bodyLarge),
                ),
              ),
              data: (page) => _RegistrationsTable(
                items: page.items,
                selectedIds: _selectedIds,
                onToggleSelect: (id, selected) {
                  setState(() {
                    if (selected) {
                      _selectedIds.add(id);
                    } else {
                      _selectedIds.remove(id);
                    }
                  });
                },
                onApprove: (id) => _updateOne(id, 'APPROVED'),
                onReject: (id) => _updateOne(id, 'REJECTED'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Toolbar extends ConsumerWidget {
  const _Toolbar({
    required this.filter,
    required this.selectedCount,
    required this.bulkInProgress,
    required this.onApprove,
    required this.onReject,
  });

  final StaffRegistrationsFilter filter;
  final int selectedCount;
  final bool bulkInProgress;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0x22000000))),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 240,
            child: TextField(
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Tìm tên, email, SĐT...',
                prefixIcon: const Icon(Icons.search, size: 18),
                border: const OutlineInputBorder(),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                suffixIcon: filter.q != null && filter.q!.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 16),
                        onPressed: () => ref
                            .read(staffRegistrationsFilterProvider.notifier)
                            .update((f) =>
                                f.copyWith(clearQ: true)),
                      )
                    : null,
              ),
              onSubmitted: (v) => ref
                  .read(staffRegistrationsFilterProvider.notifier)
                  .update((f) => f.copyWith(q: v)),
            ),
          ),
          DropdownButton<String?>(
            value: filter.status,
            underline: const SizedBox.shrink(),
            items: const [
              DropdownMenuItem(value: null, child: Text('Tất cả trạng thái')),
              DropdownMenuItem(value: 'PENDING', child: Text('PENDING')),
              DropdownMenuItem(value: 'APPROVED', child: Text('APPROVED')),
              DropdownMenuItem(value: 'REJECTED', child: Text('REJECTED')),
              DropdownMenuItem(value: 'CANCELLED', child: Text('CANCELLED')),
            ],
            onChanged: (v) => ref
                .read(staffRegistrationsFilterProvider.notifier)
                .update((f) => f.copyWith(status: v, clearStatus: v == null)),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
            ),
            onPressed:
                selectedCount == 0 || bulkInProgress ? null : onApprove,
            icon: const Icon(Icons.check, size: 18),
            label: Text('Duyệt ($selectedCount)'),
          ),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red.shade700,
              side: BorderSide(color: Colors.red.shade400),
            ),
            onPressed:
                selectedCount == 0 || bulkInProgress ? null : onReject,
            icon: const Icon(Icons.close, size: 18),
            label: Text('Từ chối ($selectedCount)'),
          ),
          if (bulkInProgress)
            const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
    );
  }
}

class _RegistrationsTable extends StatelessWidget {
  const _RegistrationsTable({
    required this.items,
    required this.selectedIds,
    required this.onToggleSelect,
    required this.onApprove,
    required this.onReject,
  });

  final List<StudentRegistrationModel> items;
  final Set<int> selectedIds;
  final void Function(int id, bool selected) onToggleSelect;
  final Future<void> Function(int id) onApprove;
  final Future<void> Function(int id) onReject;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allSelected = items.isNotEmpty && items.every((r) => selectedIds.contains(r.id));
    return PaginatedDataTable2(
      headingRowHeight: 48,
      dataRowHeight: 56,
      columns: const [
        DataColumn2(label: Text('ID'), size: ColumnSize.S),
        DataColumn2(label: Text('Họ tên'), size: ColumnSize.L),
        DataColumn2(label: Text('Email')),
        DataColumn2(label: Text('SĐT'), size: ColumnSize.S),
        DataColumn2(label: Text('Trường'), size: ColumnSize.L),
        DataColumn2(label: Text('Lớp'), size: ColumnSize.S),
        DataColumn2(label: Text('Trạng thái'), size: ColumnSize.S),
        DataColumn2(label: Text('Ngày tạo'), size: ColumnSize.M),
        DataColumn2(label: Text('Thao tác'), size: ColumnSize.L, fixedWidth: 220),
      ],
      rowsPerPage: 25,
      availableRowsPerPage: const [10, 25, 50, 100],
      showCheckboxColumn: false,
      wrapInCard: false,
      empty: const Center(child: Text('Không có đơn đăng ký nào')),
      source: _RegistrationDataSource(
        items: items,
        selectedIds: selectedIds,
        allSelected: allSelected,
        onToggleAll: (sel) {
          for (final r in items) {
            onToggleSelect(r.id, sel);
          }
        },
        onToggleSelect: onToggleSelect,
        onApprove: onApprove,
        onReject: onReject,
        theme: theme,
      ),
    );
  }
}

class _RegistrationDataSource extends DataTableSource {
  _RegistrationDataSource({
    required this.items,
    required this.selectedIds,
    required this.allSelected,
    required this.onToggleAll,
    required this.onToggleSelect,
    required this.onApprove,
    required this.onReject,
    required this.theme,
  });

  final List<StudentRegistrationModel> items;
  final Set<int> selectedIds;
  final bool allSelected;
  final void Function(bool selected) onToggleAll;
  final void Function(int id, bool selected) onToggleSelect;
  final Future<void> Function(int id) onApprove;
  final Future<void> Function(int id) onReject;
  final ThemeData theme;

  @override
  DataRow? getRow(int index) {
    if (index >= items.length) return null;
    final r = items[index];
    final selected = selectedIds.contains(r.id);
    return DataRow(
      selected: selected,
      onSelectChanged: (v) => onToggleSelect(r.id, v ?? false),
      cells: [
        DataCell(Text('${r.id}')),
        DataCell(Text(
          r.student.fullName,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        )),
        DataCell(Text(r.student.email, overflow: TextOverflow.ellipsis)),
        DataCell(Text(r.student.phone)),
        DataCell(Text(
          r.school.schoolName,
          overflow: TextOverflow.ellipsis,
        )),
        DataCell(Text('${r.student.grade}-${r.student.className}')),
        DataCell(_StatusChip(status: r.status)),
        DataCell(Text(_formatDate(r.createdAt))),
        DataCell(Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (r.student.phone.isNotEmpty)
              IconButton(
                tooltip: 'Gọi',
                icon: const Icon(Icons.phone, size: 18, color: Colors.green),
                onPressed: () => _launch('tel:${r.student.phone}'),
              ),
            if (r.student.email.isNotEmpty)
              IconButton(
                tooltip: 'Email',
                icon: const Icon(Icons.email, size: 18, color: Colors.blue),
                onPressed: () => _launch('mailto:${r.student.email}'),
              ),
            IconButton(
              tooltip: 'Duyệt',
              icon: Icon(Icons.check_circle, size: 20, color: Colors.green.shade700),
              onPressed: r.status == 'APPROVED' ? null : () => onApprove(r.id),
            ),
            IconButton(
              tooltip: 'Từ chối',
              icon: Icon(Icons.cancel, size: 20, color: Colors.red.shade700),
              onPressed: r.status == 'REJECTED' ? null : () => onReject(r.id),
            ),
          ],
        )),
      ],
    );
  }

  void _launch(String url) {
    // For flutter web, simply copy to clipboard via services
    Clipboard.setData(ClipboardData(text: url));
  }

  String _formatDate(String iso) {
    if (iso.isEmpty) return '-';
    try {
      return iso.substring(0, 16).replaceFirst('T', ' ');
    } catch (_) {
      return iso;
    }
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => items.length;

  @override
  int get selectedRowCount => items.where((r) => selectedIds.contains(r.id)).length;
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'PENDING' => Colors.amber.shade700,
      'APPROVED' => Colors.green.shade700,
      'REJECTED' => Colors.red.shade700,
      'CANCELLED' => Colors.grey.shade600,
      _ => Colors.grey.shade600,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(status,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}
