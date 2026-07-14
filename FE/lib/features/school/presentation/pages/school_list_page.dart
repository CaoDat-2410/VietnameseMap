import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/bento_card.dart';
import '../../shared/models/school_model.dart';
import '../../shared/providers/schools_provider.dart';
import '../../shared/repositories/schools_repository.dart';

// Provider to track selected schools for map display
final selectedSchoolsForMapProvider = StateProvider<List<SchoolModel>>((ref) => []);

class SchoolListPage extends ConsumerStatefulWidget {
  const SchoolListPage({super.key});

  @override
  ConsumerState<SchoolListPage> createState() => _SchoolListPageState();
}

class _SchoolListPageState extends ConsumerState<SchoolListPage> {
  final _searchController = TextEditingController();
  final _provinceController = TextEditingController();
  final _communeController = TextEditingController();
  String? _area;
  int _page = 0;
  final Set<String> _selectedSchoolUids = {};

  SchoolSearchParams get _params => SchoolSearchParams(
        page: _page,
        provinceCode: _provinceController.text.trim(),
        communeCode: _communeController.text.trim(),
        area: _area,
        query: _searchController.text.trim(),
      );

  @override
  void dispose() {
    _searchController.dispose();
    _provinceController.dispose();
    _communeController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    setState(() => _page = 0);
  }

  void _clearFilters() {
    _searchController.clear();
    _provinceController.clear();
    _communeController.clear();
    setState(() {
      _area = null;
      _page = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pageResult = ref.watch(schoolsSearchProvider(_params));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách trường học'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(schoolsSearchProvider(_params)),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SchoolFilterBar(
            searchController: _searchController,
            provinceController: _provinceController,
            communeController: _communeController,
            area: _area,
            onAreaChanged: (value) => setState(() => _area = value),
            onApply: _applyFilters,
            onClear: _clearFilters,
          ),
          const SizedBox(height: 16),
          pageResult.when(
            loading: () => const _LoadingBlock(),
            error: (error, _) => _ErrorBlock(
              error: error,
              onRetry: () => ref.invalidate(schoolsSearchProvider(_params)),
            ),
            data: (page) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Hiển thị ${page.items.length} trong ${page.totalItems} trường',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_selectedSchoolUids.isNotEmpty) ...[
                          OutlinedButton.icon(
                            onPressed: () {
                              setState(() {
                                _selectedSchoolUids.clear();
                              });
                            },
                            icon: const Icon(Icons.clear),
                            label: Text('Xóa (${_selectedSchoolUids.length})'),
                          ),
                          const SizedBox(width: 8),
                        ],
                        FilledButton.icon(
                          onPressed: () {
                            final selectedUids = _selectedSchoolUids.toList();
                            if (selectedUids.isNotEmpty) {
                              final query = Uri.encodeComponent(selectedUids.join(','));
                              context.go('/map?schools=$query');
                            } else {
                              context.go('/map');
                            }
                          },
                          icon: const Icon(Icons.map),
                          label: Text(_selectedSchoolUids.isNotEmpty
                              ? 'Xem ${_selectedSchoolUids.length} trường'
                              : 'Xem bản đồ'),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (page.items.isEmpty)
                  const _EmptyBlock(message: 'Không tìm thấy trường học nào')
                else
                  for (final school in page.items)
                    _SchoolListItem(
                      school: school,
                      isSelected: _selectedSchoolUids.contains(school.schoolUid),
                      onTap: () {
                        setState(() {
                          if (_selectedSchoolUids.contains(school.schoolUid)) {
                            _selectedSchoolUids.remove(school.schoolUid);
                          } else {
                            _selectedSchoolUids.add(school.schoolUid);
                          }
                        });
                      },
                    ),
                const SizedBox(height: 12),
                _PaginationBar(
                  page: page.page,
                  totalPages: page.totalPages,
                  onPrevious: page.page == 0
                      ? null
                      : () => setState(() => _page = page.page - 1),
                  onNext: page.page >= page.totalPages - 1
                      ? null
                      : () => setState(() => _page = page.page + 1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SchoolFilterBar extends StatelessWidget {
  const _SchoolFilterBar({
    required this.searchController,
    required this.provinceController,
    required this.communeController,
    required this.area,
    required this.onAreaChanged,
    required this.onApply,
    required this.onClear,
  });

  final TextEditingController searchController;
  final TextEditingController provinceController;
  final TextEditingController communeController;
  final String? area;
  final ValueChanged<String?> onAreaChanged;
  final VoidCallback onApply;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return BentoCard(
      size: BentoSize.wide,
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 280,
            child: TextField(
              controller: searchController,
              decoration: const InputDecoration(
                labelText: 'Tìm kiếm',
                hintText: 'Tên trường hoặc địa chỉ',
                prefixIcon: Icon(Icons.search),
              ),
              onSubmitted: (_) => onApply(),
            ),
          ),
          SizedBox(
            width: 140,
            child: TextField(
              controller: provinceController,
              decoration: const InputDecoration(labelText: 'Mã tỉnh'),
              onSubmitted: (_) => onApply(),
            ),
          ),
          SizedBox(
            width: 140,
            child: TextField(
              controller: communeController,
              decoration: const InputDecoration(labelText: 'Mã xã'),
              onSubmitted: (_) => onApply(),
            ),
          ),
          SizedBox(
            width: 140,
            child: DropdownButtonFormField<String>(
              value: area,
              decoration: const InputDecoration(labelText: 'Khu vực'),
              items: const [
                DropdownMenuItem(value: 'KV1', child: Text('KV1')),
                DropdownMenuItem(value: 'KV2', child: Text('KV2')),
                DropdownMenuItem(value: 'KV2_NT', child: Text('KV2_NT')),
                DropdownMenuItem(value: 'KV3', child: Text('KV3')),
              ],
              onChanged: onAreaChanged,
            ),
          ),
          FilledButton.icon(
            onPressed: onApply,
            icon: const Icon(Icons.search),
            label: const Text('Tìm kiếm'),
          ),
          OutlinedButton.icon(
            onPressed: onClear,
            icon: const Icon(Icons.clear),
            label: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
}

class _SchoolListItem extends StatelessWidget {
  const _SchoolListItem({
    required this.school,
    required this.isSelected,
    required this.onTap,
  });

  final SchoolModel school;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: BentoCard(
        size: BentoSize.wide,
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Selection checkbox
            Checkbox(
              value: isSelected,
              onChanged: (_) => onTap(),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.school_outlined,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    school.schoolName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${school.provinceName} | ${school.communeName}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                  if (school.address.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      school.address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      StatusChip(
                        label: school.schoolUid,
                        status: StatusType.draft,
                      ),
                      if (school.areaType.isNotEmpty)
                        StatusChip(
                          label: school.areaType,
                          status: StatusType.pending,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({
    required this.page,
    required this.totalPages,
    required this.onPrevious,
    required this.onNext,
  });

  final int page;
  final int totalPages;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        OutlinedButton.icon(
          onPressed: onPrevious,
          icon: const Icon(Icons.chevron_left),
          label: const Text('Previous'),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('Page ${page + 1} / ${totalPages == 0 ? 1 : totalPages}'),
        ),
        OutlinedButton.icon(
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right),
          label: const Text('Next'),
        ),
      ],
    );
  }
}

class _LoadingBlock extends StatelessWidget {
  const _LoadingBlock();

  @override
  Widget build(BuildContext context) {
    return BentoCard(
      size: BentoSize.wide,
      child: SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Đang tải dữ liệu...',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorBlock extends StatelessWidget {
  const _ErrorBlock({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return BentoCard(
      size: BentoSize.wide,
      child: SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 12),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyBlock extends StatelessWidget {
  const _EmptyBlock({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return BentoCard(
      size: BentoSize.wide,
      child: SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.search_off,
                size: 48,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
