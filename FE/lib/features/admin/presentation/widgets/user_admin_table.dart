import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import 'user_chips.dart';

/// Action types for the admin user table.
enum UserAction { edit, toggleStatus, delete }

/// Admin user table with sort, filter, search, and inline actions.
class UserAdminTable extends StatefulWidget {
  const UserAdminTable({
    super.key,
    required this.users,
    required this.onAction,
  });

  final List<Map<String, dynamic>> users;
  final void Function(Map<String, dynamic> user, UserAction action) onAction;

  @override
  State<UserAdminTable> createState() => _UserAdminTableState();
}

class _UserAdminTableState extends State<UserAdminTable> {
  int _pageSize = 10;
  String _searchQuery = '';
  String? _roleFilter;
  String? _statusFilter;
  int _sortColumnIndex = 0;
  bool _sortAscending = true;

  List<Map<String, dynamic>> get _filtered {
    return widget.users.where((u) {
      final email = (u['email'] as String? ?? '').toLowerCase();
      final role = u['role'] as String? ?? '';
      final status = u['status'] as String? ?? '';
      if (_searchQuery.isNotEmpty &&
          !email.contains(_searchQuery.toLowerCase())) {
        return false;
      }
      if (_roleFilter != null && role != _roleFilter) return false;
      if (_statusFilter != null && status != _statusFilter) return false;
      return true;
    }).toList();
  }

  List<Map<String, dynamic>> get _sorted {
    final rows = List<Map<String, dynamic>>.from(_filtered);
    rows.sort((a, b) {
      final aVal = a.values.toList()[_sortColumnIndex];
      final bVal = b.values.toList()[_sortColumnIndex];
      final cmp = Comparable.compare(
        aVal.toString().toLowerCase(),
        bVal.toString().toLowerCase(),
      );
      return _sortAscending ? cmp : -cmp;
    });
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final rows = _sorted;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Filter bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 280,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm email…',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    isDense: true,
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
              ),
              DropdownButton<String?>(
                value: _roleFilter,
                hint: const Text('Vai trò'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Tất cả vai trò')),
                  for (final r in ['ADMIN', 'MANAGER', 'STAFF', 'STUDENT'])
                    DropdownMenuItem(value: r, child: Text(r)),
                ],
                onChanged: (v) => setState(() => _roleFilter = v),
              ),
              DropdownButton<String?>(
                value: _statusFilter,
                hint: const Text('Trạng thái'),
                items: const [
                  DropdownMenuItem(value: null, child: Text('Tất cả trạng thái')),
                  DropdownMenuItem(value: 'ACTIVE', child: Text('ACTIVE')),
                  DropdownMenuItem(value: 'INACTIVE', child: Text('INACTIVE')),
                ],
                onChanged: (v) => setState(() => _statusFilter = v),
              ),
            ],
          ),
        ),
        // Table
        Expanded(
          child: PaginatedDataTable2(
            header: Text(
              'Danh sách người dùng (${rows.length})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            columns: [
              DataColumn2(
                label: const Text('ID'),
                size: ColumnSize.S,
                onSort: (i, asc) =>
                    setState(() { _sortColumnIndex = i; _sortAscending = asc; }),
              ),
              DataColumn2(
                label: const Text('Email'),
                size: ColumnSize.L,
                onSort: (i, asc) =>
                    setState(() { _sortColumnIndex = i; _sortAscending = asc; }),
              ),
              DataColumn2(
                label: const Text('Vai trò'),
                size: ColumnSize.S,
                onSort: (i, asc) =>
                    setState(() { _sortColumnIndex = i; _sortAscending = asc; }),
              ),
              DataColumn2(
                label: const Text('Trạng thái'),
                size: ColumnSize.S,
                onSort: (i, asc) =>
                    setState(() { _sortColumnIndex = i; _sortAscending = asc; }),
              ),
              DataColumn2(
                label: const Text('Employee ID'),
                size: ColumnSize.S,
                onSort: (i, asc) =>
                    setState(() { _sortColumnIndex = i; _sortAscending = asc; }),
              ),
              DataColumn2(
                label: const Text('Student ID'),
                size: ColumnSize.S,
                onSort: (i, asc) =>
                    setState(() { _sortColumnIndex = i; _sortAscending = asc; }),
              ),
              const DataColumn2(
                label: Text('Thao tác'),
                size: ColumnSize.S,
                fixedWidth: 120,
              ),
            ],
            source: _UserDataSource(
              rows: rows,
              onAction: widget.onAction,
              colorScheme: colorScheme,
            ),
            rowsPerPage: _pageSize,
            availableRowsPerPage: const [10, 25, 50],
            onRowsPerPageChanged: (v) {
              if (v != null) setState(() => _pageSize = v);
            },
            sortColumnIndex: _sortColumnIndex,
            sortAscending: _sortAscending,
            showCheckboxColumn: false,
            wrapInCard: false,
          ),
        ),
      ],
    );
  }
}

class _UserDataSource extends DataTableSource {
  _UserDataSource({
    required this.rows,
    required this.onAction,
    required this.colorScheme,
  });
  final List<Map<String, dynamic>> rows;
  final void Function(Map<String, dynamic> user, UserAction action) onAction;
  final ColorScheme colorScheme;

  @override
  DataRow? getRow(int index) {
    if (index >= rows.length) return null;
    final user = rows[index];
    return DataRow(
      cells: [
        DataCell(Text('${user['id']}')),
        DataCell(
          Text(
            user['email'] as String? ?? '',
            overflow: TextOverflow.ellipsis,
          ),
        ),
        DataCell(UserRoleChip(role: user['role'] as String? ?? '')),
        DataCell(UserStatusChip(status: user['status'] as String? ?? '')),
        DataCell(Text(
          '${user['employeeId'] ?? '-'}',
          textAlign: TextAlign.center,
        )),
        DataCell(Text(
          '${user['studentId'] ?? '-'}',
          textAlign: TextAlign.center,
        )),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, size: 20),
                tooltip: 'Sửa',
                onPressed: () => onAction(user, UserAction.edit),
              ),
              IconButton(
                icon: Icon(
                  user['status'] == 'ACTIVE' ? Icons.block : Icons.check_circle,
                  size: 20,
                ),
                tooltip: user['status'] == 'ACTIVE'
                    ? 'Vô hiệu hóa'
                    : 'Kích hoạt',
                onPressed: () => onAction(user, UserAction.toggleStatus),
              ),
              IconButton(
                icon: Icon(Icons.delete, size: 20, color: AppColors.error),
                tooltip: 'Xóa',
                onPressed: () => onAction(user, UserAction.delete),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;
  @override
  int get rowCount => rows.length;
  @override
  int get selectedRowCount => 0;
}
