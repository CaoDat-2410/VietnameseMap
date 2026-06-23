import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/models/school_model.dart';
import '../../shared/providers/schools_provider.dart';
import '../../shared/repositories/schools_repository.dart';

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
      appBar: AppBar(title: const Text('Schools')),
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
                    Text(
                      'Showing ${page.items.length} of ${page.totalItems} schools',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    TextButton.icon(
                      onPressed: () {
                        final params = _params;
                        final query = Uri.encodeComponent(
                          'province=${params.provinceCode ?? ''}&commune=${params.communeCode ?? ''}'
                        );
                        context.go('/map?schools=true&$query');
                      },
                      icon: const Icon(Icons.map),
                      label: const Text('Show on Map'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (page.items.isEmpty)
                  const _EmptyBlock(message: 'No schools found')
                else
                  for (final school in page.items)
                    _SchoolListItem(
                      school: school,
                      onTap: () => context.go('/schools/${school.schoolUid}'),
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
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 280,
          child: TextField(
            controller: searchController,
            decoration: const InputDecoration(
              labelText: 'Search',
              hintText: 'Search school name or address',
              prefixIcon: Icon(Icons.search),
            ),
            onSubmitted: (_) => onApply(),
          ),
        ),
        SizedBox(
          width: 140,
          child: TextField(
            controller: provinceController,
            decoration: const InputDecoration(labelText: 'Province code'),
            onSubmitted: (_) => onApply(),
          ),
        ),
        SizedBox(
          width: 140,
          child: TextField(
            controller: communeController,
            decoration: const InputDecoration(labelText: 'Commune code'),
            onSubmitted: (_) => onApply(),
          ),
        ),
        SizedBox(
          width: 140,
          child: DropdownButtonFormField<String>(
            initialValue: area,
            decoration: const InputDecoration(labelText: 'Area'),
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
          label: const Text('Apply'),
        ),
        TextButton.icon(
          onPressed: onClear,
          icon: const Icon(Icons.clear),
          label: const Text('Clear'),
        ),
      ],
    );
  }
}

class _SchoolListItem extends StatelessWidget {
  const _SchoolListItem({required this.school, required this.onTap});

  final SchoolModel school;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(Icons.school_outlined),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      school.schoolName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${school.provinceName} | ${school.communeName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (school.address.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        school.address,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        Chip(
                          label: Text(school.schoolUid),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                        ),
                        Chip(
                          label: Text(
                            school.areaType.isEmpty ? 'N/A' : school.areaType,
                          ),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right),
            ],
          ),
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
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: CircularProgressIndicator(),
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
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(error.toString()),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
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
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(child: Text(message)),
    );
  }
}
