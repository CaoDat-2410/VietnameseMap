import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../shared/providers/schools_provider.dart';
import '../shared/repositories/schools_repository.dart';
import '../widgets/school_filter_bar.dart';
import '../widgets/school_list_item.dart';
import '../widgets/school_pagination_bar.dart';

class SchoolListPage extends ConsumerStatefulWidget {
  const SchoolListPage({super.key});

  @override
  ConsumerState<SchoolListPage> createState() => _SchoolListPageState();
}

class _SchoolListPageState extends ConsumerState<SchoolListPage> {
  int _page = 0;
  String _query = '';
  String? _provinceCode;
  String? _communeCode;
  String? _area;
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _setTextFilter(void Function() update) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(() {
        _page = 0;
        update();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final params = SchoolSearchParams(
      page: _page,
      limit: 50,
      provinceCode: _provinceCode,
      communeCode: _communeCode,
      area: _area,
      query: _query,
    );
    final schoolsAsync = ref.watch(schoolsSearchProvider(params));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Schools'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(schoolsSearchProvider(params)),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          SchoolFilterBar(
            provinceCode: _provinceCode,
            communeCode: _communeCode,
            area: _area,
            onSearchChanged: (value) =>
                _setTextFilter(() => _query = value.trim()),
            onProvinceChanged: (value) =>
                _setTextFilter(() => _provinceCode = _blankToNull(value)),
            onCommuneChanged: (value) =>
                _setTextFilter(() => _communeCode = _blankToNull(value)),
            onAreaChanged: (value) => setState(() {
              _page = 0;
              _area = value;
            }),
          ),
          Expanded(
            child: schoolsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _ErrorState(
                message: error.toString(),
                onRetry: () => ref.invalidate(schoolsSearchProvider(params)),
              ),
              data: (result) {
                if (result.items.isEmpty) {
                  return const Center(child: Text('No schools found.'));
                }
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text('${result.totalItems} schools'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () async {
                          ref.invalidate(schoolsSearchProvider(params));
                          await ref.read(schoolsSearchProvider(params).future);
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: result.items.length,
                          itemBuilder: (context, index) {
                            final school = result.items[index];
                            return SchoolListItem(
                              school: school,
                              onTap: () =>
                                  context.push('/schools/${school.schoolUid}'),
                            );
                          },
                        ),
                      ),
                    ),
                    SchoolPaginationBar(
                      page: result.page,
                      totalPages: result.totalPages,
                      onPrevious: result.page > 0
                          ? () => setState(() => _page--)
                          : null,
                      onNext: result.page + 1 < result.totalPages
                          ? () => setState(() => _page++)
                          : null,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String? _blankToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
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
