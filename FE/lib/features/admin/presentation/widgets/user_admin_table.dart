import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/bento_card.dart';
import 'user_chips.dart';

enum UserAction { edit, toggleStatus, delete }

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
    return LayoutBuilder(
      builder: (context, c) {
        final isMobile = c.maxWidth < 600;
        return isMobile
            ? _MobileUserList(
                searchQuery: _searchQuery,
                roleFilter: _roleFilter,
                statusFilter: _statusFilter,
                sortColumnIndex: _sortColumnIndex,
                sortAscending: _sortAscending,
                rows: _sorted,
                onSearch: (v) => setState(() => _searchQuery = v),
                onRoleFilter: (v) => setState(() => _roleFilter = v),
                onStatusFilter: (v) => setState(() => _statusFilter = v),
                onSort: (i, asc) =>
                    setState(() { _sortColumnIndex = i; _sortAscending = asc; }),
                onAction: widget.onAction,
              )
            : _DesktopUserTable(
                searchQuery: _searchQuery,
                roleFilter: _roleFilter,
                statusFilter: _statusFilter,
                sortColumnIndex: _sortColumnIndex,
                sortAscending: _sortAscending,
                rows: _sorted,
                pageSize: _pageSize,
                onSearch: (v) => setState(() => _searchQuery = v),
                onRoleFilter: (v) => setState(() => _roleFilter = v),
                onStatusFilter: (v) => setState(() => _statusFilter = v),
                onSort: (i, asc) =>
                    setState(() { _sortColumnIndex = i; _sortAscending = asc; }),
                onPageSize: (v) => setState(() { if (v != null) _pageSize = v; }),
                onAction: widget.onAction,
              );
      },
    );
  }
}

class _MobileUserList extends StatelessWidget {
  const _MobileUserList({
    required this.searchQuery,
    required this.roleFilter,
    required this.statusFilter,
    required this.sortColumnIndex,
    required this.sortAscending,
    required this.rows,
    required this.onSearch,
    required this.onRoleFilter,
    required this.onStatusFilter,
    required this.onSort,
    required this.onAction,
  });

  final String searchQuery;
  final String? roleFilter;
  final String? statusFilter;
  final int sortColumnIndex;
  final bool sortAscending;
  final List<Map<String, dynamic>> rows;
  final ValueChanged<String> onSearch;
  final ValueChanged<String?> onRoleFilter;
  final ValueChanged<String?> onStatusFilter;
  final void Function(int, bool) onSort;
  final void Function(Map<String, dynamic>, UserAction) onAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm email…',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  isDense: true,
                ),
                onChanged: onSearch,
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterChip(
                      label: roleFilter ?? 'Vai trò',
                      isActive: roleFilter != null,
                      onTap: () => _showRoleFilterSheet(context),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: statusFilter ?? 'Trạng thái',
                      isActive: statusFilter != null,
                      onTap: () => _showStatusFilterSheet(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                '${rows.length} người dùng',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const Spacer(),
              _SortButton(
                label: 'Sắp xếp',
                onTap: () => _showSortSheet(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: rows.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 48,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Không tìm thấy người dùng',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: rows.length,
                  itemBuilder: (context, index) {
                    final user = rows[index];
                    return _MobileUserCard(user: user, onAction: onAction);
                  },
                ),
        ),
      ],
    );
  }

  void _showRoleFilterSheet(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      builder: (_) => _FilterSheet(
        title: 'Lọc theo vai trò',
        options: const [null, 'ADMIN', 'MANAGER', 'STAFF', 'STUDENT'],
        labels: const ['Tất cả', 'ADMIN', 'MANAGER', 'STAFF', 'STUDENT'],
        selected: roleFilter,
        onSelect: (v) { onRoleFilter(v); Navigator.pop(ctx); },
      ),
    );
  }

  void _showStatusFilterSheet(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      builder: (_) => _FilterSheet(
        title: 'Lọc theo trạng thái',
        options: const [null, 'ACTIVE', 'INACTIVE'],
        labels: const ['Tất cả', 'ACTIVE', 'INACTIVE'],
        selected: statusFilter,
        onSelect: (v) { onStatusFilter(v); Navigator.pop(ctx); },
      ),
    );
  }

  void _showSortSheet(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('ID'),
              trailing: sortColumnIndex == 0
                  ? Icon(sortAscending ? Icons.arrow_upward : Icons.arrow_downward, size: 18)
                  : null,
              onTap: () { onSort(0, sortColumnIndex == 0 ? !sortAscending : true); Navigator.pop(ctx); },
            ),
            ListTile(
              title: const Text('Email'),
              trailing: sortColumnIndex == 1
                  ? Icon(sortAscending ? Icons.arrow_upward : Icons.arrow_downward, size: 18)
                  : null,
              onTap: () { onSort(1, sortColumnIndex == 1 ? !sortAscending : true); Navigator.pop(ctx); },
            ),
            ListTile(
              title: const Text('Vai trò'),
              trailing: sortColumnIndex == 2
                  ? Icon(sortAscending ? Icons.arrow_upward : Icons.arrow_downward, size: 18)
                  : null,
              onTap: () { onSort(2, sortColumnIndex == 2 ? !sortAscending : true); Navigator.pop(ctx); },
            ),
            ListTile(
              title: const Text('Trạng thái'),
              trailing: sortColumnIndex == 3
                  ? Icon(sortAscending ? Icons.arrow_upward : Icons.arrow_downward, size: 18)
                  : null,
              onTap: () { onSort(3, sortColumnIndex == 3 ? !sortAscending : true); Navigator.pop(ctx); },
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.isActive, required this.onTap});
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isActive
                    ? Theme.of(context).colorScheme.onPrimaryContainer
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              size: 18,
              color: isActive
                  ? Theme.of(context).colorScheme.onPrimaryContainer
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _SortButton extends StatelessWidget {
  const _SortButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sort, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterSheet<T> extends StatelessWidget {
  const _FilterSheet({
    required this.title,
    required this.options,
    required this.labels,
    required this.selected,
    required this.onSelect,
  });
  final String title;
  final List<T> options;
  final List<String> labels;
  final T selected;
  final ValueChanged<T> onSelect;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(title, style: Theme.of(context).textTheme.titleMedium),
          ),
          const Divider(height: 1),
          ...List.generate(options.length, (i) => ListTile(
            title: Text(labels[i]),
            trailing: options[i] == selected
                ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary, size: 18)
                : null,
            onTap: () => onSelect(options[i]),
          )),
        ],
      ),
    );
  }
}

class _MobileUserCard extends StatelessWidget {
  const _MobileUserCard({required this.user, required this.onAction});
  final Map<String, dynamic> user;
  final void Function(Map<String, dynamic>, UserAction) onAction;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: BentoCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: colorScheme.primaryContainer,
                  child: Text(
                    (user['email'] as String? ?? '@')[0].toUpperCase(),
                    style: TextStyle(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user['email'] as String? ?? '',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      UserRoleChip(role: user['role'] as String? ?? ''),
                    ],
                  ),
                ),
                UserStatusChip(status: user['status'] as String? ?? ''),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _InfoChip(label: 'ID: ${user['id']}'),
                const SizedBox(width: 8),
                if (user['employeeId'] != null) ...[
                  _InfoChip(label: 'EMP: ${user['employeeId']}'),
                  const SizedBox(width: 8),
                ],
                if (user['studentId'] != null) ...[
                  _InfoChip(label: 'STU: ${user['studentId']}'),
                  const SizedBox(width: 8),
                ],
                if (user['firebaseUid'] != null)
                  _InfoChip(label: 'Google', color: Color(0xFF4285F4)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => onAction(user, UserAction.edit),
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Sửa'),
                ),
                const SizedBox(width: 4),
                TextButton.icon(
                  onPressed: () => onAction(user, UserAction.toggleStatus),
                  icon: Icon(
                    user['status'] == 'ACTIVE' ? Icons.block : Icons.check_circle,
                    size: 18,
                  ),
                  label: Text(user['status'] == 'ACTIVE' ? 'Tắt' : 'Bật'),
                ),
                const SizedBox(width: 4),
                TextButton.icon(
                  onPressed: () => onAction(user, UserAction.delete),
                  icon: Icon(Icons.delete, size: 18, color: AppColors.error),
                  label: Text('Xóa', style: TextStyle(color: AppColors.error)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, this.color});
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? Theme.of(context).colorScheme.surfaceContainerHighest;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color != null ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _DesktopUserTable extends StatelessWidget {
  const _DesktopUserTable({
    required this.searchQuery,
    required this.roleFilter,
    required this.statusFilter,
    required this.sortColumnIndex,
    required this.sortAscending,
    required this.rows,
    required this.pageSize,
    required this.onSearch,
    required this.onRoleFilter,
    required this.onStatusFilter,
    required this.onSort,
    required this.onPageSize,
    required this.onAction,
  });

  final String searchQuery;
  final String? roleFilter;
  final String? statusFilter;
  final int sortColumnIndex;
  final bool sortAscending;
  final List<Map<String, dynamic>> rows;
  final int pageSize;
  final ValueChanged<String> onSearch;
  final ValueChanged<String?> onRoleFilter;
  final ValueChanged<String?> onStatusFilter;
  final void Function(int, bool) onSort;
  final ValueChanged<int?> onPageSize;
  final void Function(Map<String, dynamic>, UserAction) onAction;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    isDense: true,
                  ),
                  onChanged: onSearch,
                ),
              ),
              DropdownButton<String?>(
                value: roleFilter,
                hint: const Text('Vai trò'),
                items: [
                  DropdownMenuItem(value: null, child: const Text('Tất cả vai trò')),
                  for (final r in ['ADMIN', 'MANAGER', 'STAFF', 'STUDENT'])
                    DropdownMenuItem(value: r, child: Text(r)),
                ],
                onChanged: onRoleFilter,
              ),
              DropdownButton<String?>(
                value: statusFilter,
                hint: const Text('Trạng thái'),
                items: [
                  DropdownMenuItem(value: null, child: const Text('Tất cả trạng thái')),
                  DropdownMenuItem(value: 'ACTIVE', child: Text('ACTIVE')),
                  DropdownMenuItem(value: 'INACTIVE', child: Text('INACTIVE')),
                ],
                onChanged: onStatusFilter,
              ),
            ],
          ),
        ),
        Expanded(
          child: PaginatedDataTable2(
            minWidth: 1080,
            columnSpacing: 14,
            horizontalMargin: 14,
            headingRowHeight: 48,
            dataRowHeight: 58,
            header: Text(
              'Danh sách người dùng (${rows.length})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            columns: [
              DataColumn2(
                label: const Text('ID'),
                size: ColumnSize.S,
                fixedWidth: 64,
                onSort: (i, asc) => onSort(i, asc),
              ),
              DataColumn2(
                label: const Text('Email'),
                size: ColumnSize.L,
                onSort: (i, asc) => onSort(i, asc),
              ),
              DataColumn2(
                label: const Text('Vai trò'),
                size: ColumnSize.S,
                fixedWidth: 112,
                onSort: (i, asc) => onSort(i, asc),
              ),
              DataColumn2(
                label: const Text('Trạng thái'),
                size: ColumnSize.S,
                fixedWidth: 128,
                onSort: (i, asc) => onSort(i, asc),
              ),
              DataColumn2(
                label: const Text('Employee ID'),
                size: ColumnSize.S,
                fixedWidth: 116,
                onSort: (i, asc) => onSort(i, asc),
              ),
              DataColumn2(
                label: const Text('Student ID'),
                size: ColumnSize.S,
                fixedWidth: 108,
                onSort: (i, asc) => onSort(i, asc),
              ),
              const DataColumn2(
                label: Text('Google'),
                size: ColumnSize.S,
                fixedWidth: 76,
              ),
              const DataColumn2(
                label: Text('Thao tác'),
                size: ColumnSize.S,
                fixedWidth: 132,
              ),
            ],
            source: _UserDataSource(rows: rows, onAction: onAction, colorScheme: colorScheme),
            rowsPerPage: pageSize,
            availableRowsPerPage: const [10, 25, 50],
            onRowsPerPageChanged: onPageSize,
            sortColumnIndex: sortColumnIndex,
            sortAscending: sortAscending,
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
        DataCell(Text(
          user['email'] as String? ?? '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          softWrap: false,
        )),
        DataCell(UserRoleChip(role: user['role'] as String? ?? '')),
        DataCell(UserStatusChip(status: user['status'] as String? ?? '')),
        DataCell(Text('${user['employeeId'] ?? '-'}', textAlign: TextAlign.center)),
        DataCell(Text('${user['studentId'] ?? '-'}', textAlign: TextAlign.center)),
        DataCell(user['firebaseUid'] != null
            ? const Tooltip(
                message: 'Dang nhap Google Firebase',
                child: Icon(Icons.g_mobiledata, size: 20, color: Color(0xFF4285F4)),
              )
            : const SizedBox.shrink()),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(constraints: const BoxConstraints.tightFor(width: 36, height: 36), padding: EdgeInsets.zero, icon: const Icon(Icons.edit, size: 20), tooltip: 'Sửa', onPressed: () => onAction(user, UserAction.edit)),
              IconButton(
                constraints: const BoxConstraints.tightFor(width: 36, height: 36),
                padding: EdgeInsets.zero,
                icon: Icon(user['status'] == 'ACTIVE' ? Icons.block : Icons.check_circle, size: 20),
                tooltip: user['status'] == 'ACTIVE' ? 'Vô hiệu hóa' : 'Kích hoạt',
                onPressed: () => onAction(user, UserAction.toggleStatus),
              ),
              IconButton(constraints: const BoxConstraints.tightFor(width: 36, height: 36), padding: EdgeInsets.zero, icon: const Icon(Icons.delete, size: 20, color: AppColors.error), tooltip: 'Xóa', onPressed: () => onAction(user, UserAction.delete)),
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
