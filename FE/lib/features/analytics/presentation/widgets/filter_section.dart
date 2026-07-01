import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/bento_card.dart';
import '../../data/repositories/analytics_repository.dart';
import '../providers/analytics_provider.dart';

class FilterSection extends ConsumerWidget {
  const FilterSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filterType = ref.watch(selectedFilterTypeProvider);
    final campaigns = ref.watch(campaignsListProvider);
    final selectedCampaignId = ref.watch(selectedCampaignIdProvider);
    final isMobile = MediaQuery.of(context).size.width < 600;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final mutedColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return BentoCard(
      padding: EdgeInsets.all(isMobile ? 14 : 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            spacing: 14,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.tune, size: 20, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'B\u{1ED9} l\u{1ECD}c',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                  ),
                ],
              ),
              SegmentedButton<AnalyticsFilterType>(
                segments: const [
                  ButtonSegment(
                    value: AnalyticsFilterType.none,
                    label: Text('T\u{1EA5}t c\u{1EA3}'),
                    icon: Icon(Icons.all_inclusive, size: 18),
                  ),
                  ButtonSegment(
                    value: AnalyticsFilterType.campaign,
                    label: Text('Chi\u{1EBF}n d\u{1ECB}ch'),
                    icon: Icon(Icons.campaign_outlined, size: 18),
                  ),
                  ButtonSegment(
                    value: AnalyticsFilterType.school,
                    label: Text('Tr\u{01B0}\u{1EDD}ng'),
                    icon: Icon(Icons.school_outlined, size: 18),
                  ),
                ],
                selected: {filterType},
                onSelectionChanged: (selected) {
                  ref.read(selectedFilterTypeProvider.notifier).state =
                      selected.first;
                  ref.read(selectedCampaignIdProvider.notifier).state = null;
                  ref.read(selectedCampaignNameProvider.notifier).state = null;
                  ref.read(selectedSchoolUidProvider.notifier).state = null;
                  ref.read(selectedSchoolNameProvider.notifier).state = null;
                },
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  padding: WidgetStateProperty.all(
                    EdgeInsets.symmetric(
                      horizontal: isMobile ? 8 : 12,
                      vertical: isMobile ? 6 : 8,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (filterType != AnalyticsFilterType.none) ...[
            const SizedBox(height: 14),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: switch (filterType) {
                AnalyticsFilterType.campaign => campaigns.when(
                    loading: () => const LinearProgressIndicator(minHeight: 3),
                    error: (_, __) => _FilterError(
                      message:
                          'Kh\u{00F4}ng th\u{1EC3} t\u{1EA3}i danh s\u{00E1}ch chi\u{1EBF}n d\u{1ECB}ch',
                      color: mutedColor,
                    ),
                    data: (list) {
                      final validValue =
                          list.any((c) => c.id == selectedCampaignId)
                              ? selectedCampaignId
                              : null;
                      return DropdownButtonFormField<int>(
                        initialValue: validValue,
                        isExpanded: true,
                        decoration: _inputDecoration(
                          context,
                          label: 'Ch\u{1ECD}n chi\u{1EBF}n d\u{1ECB}ch',
                          icon: Icons.campaign_outlined,
                          isMobile: isMobile,
                        ),
                        items: list
                            .map(
                              (campaign) => DropdownMenuItem<int>(
                                value: campaign.id,
                                child: Text(
                                  '${campaign.name} (${campaign.status})',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (id) {
                          ref.read(selectedCampaignIdProvider.notifier).state =
                              id;
                          ref.read(selectedSchoolUidProvider.notifier).state =
                              null;
                          ref.read(selectedSchoolNameProvider.notifier).state =
                              null;
                          String? selectedName;
                          for (final campaign in list) {
                            if (campaign.id == id) {
                              selectedName = campaign.name;
                              break;
                            }
                          }
                          ref
                              .read(selectedCampaignNameProvider.notifier)
                              .state = selectedName;
                        },
                      );
                    },
                  ),
                AnalyticsFilterType.school => _SchoolPickerField(
                    isMobile: isMobile,
                  ),
                AnalyticsFilterType.none => const SizedBox.shrink(),
              },
            ),
          ],
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(
    BuildContext context, {
    required String label,
    required IconData icon,
    required bool isMobile,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20),
      border: const OutlineInputBorder(),
      contentPadding: EdgeInsets.symmetric(
        horizontal: 12,
        vertical: isMobile ? 10 : 12,
      ),
      isDense: isMobile,
    );
  }
}

class _SchoolPickerField extends ConsumerWidget {
  const _SchoolPickerField({required this.isMobile});

  final bool isMobile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedName = ref.watch(selectedSchoolNameProvider);
    final selectedUid = ref.watch(selectedSchoolUidProvider);
    final label = selectedName ?? selectedUid;

    return InkWell(
      borderRadius: BorderRadius.circular(4),
      onTap: () async {
        final selected = await showModalBottomSheet<SchoolSummary>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          builder: (_) => const _SchoolPickerSheet(),
        );
        if (selected == null || !context.mounted) return;
        ref.read(selectedSchoolUidProvider.notifier).state = selected.uid;
        ref.read(selectedSchoolNameProvider.notifier).state =
            selected.displayName;
        ref.read(selectedCampaignIdProvider.notifier).state = null;
        ref.read(selectedCampaignNameProvider.notifier).state = null;
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Ch\u{1ECD}n tr\u{01B0}\u{1EDD}ng h\u{1ECD}c',
          prefixIcon: const Icon(Icons.school_outlined, size: 20),
          suffixIcon: const Icon(Icons.arrow_drop_down),
          border: const OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(
            horizontal: 12,
            vertical: isMobile ? 10 : 12,
          ),
          isDense: isMobile,
        ),
        child: Text(
          label ?? 'Ch\u{1ECD}n tr\u{01B0}\u{1EDD}ng h\u{1ECD}c',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _SchoolPickerSheet extends ConsumerStatefulWidget {
  const _SchoolPickerSheet();

  @override
  ConsumerState<_SchoolPickerSheet> createState() => _SchoolPickerSheetState();
}

class _SchoolPickerSheetState extends ConsumerState<_SchoolPickerSheet> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  final List<SchoolSummary> _items = [];

  Timer? _debounce;
  int _page = 0;
  int _totalItems = 0;
  int _totalPages = 0;
  bool _isInitialLoading = true;
  bool _isLoadingMore = false;
  String? _error;

  bool get _hasMore => _page + 1 < _totalPages;

  @override
  void initState() {
    super.initState();
    _loadSchools(reset: true);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadSchools({required bool reset}) async {
    if (_isLoadingMore || (_isInitialLoading && !reset)) return;
    setState(() {
      _error = null;
      if (reset) {
        _isInitialLoading = true;
        _page = 0;
        _items.clear();
      } else {
        _isLoadingMore = true;
      }
    });

    try {
      final nextPage = reset ? 0 : _page + 1;
      final result = await ref.read(analyticsRepositoryProvider).getSchools(
            page: nextPage,
            query: _searchController.text,
          );
      if (!mounted) return;
      setState(() {
        _page = result.page;
        _totalItems = result.totalItems;
        _totalPages = result.totalPages;
        if (reset) {
          _items
            ..clear()
            ..addAll(result.items);
        } else {
          _items.addAll(result.items);
        }
        _isInitialLoading = false;
        _isLoadingMore = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _isInitialLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) _loadSchools(reset: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * 0.82;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SizedBox(
        height: height,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ch\u{1ECD}n tr\u{01B0}\u{1EDD}ng h\u{1ECD}c',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _totalItems > 0
                              ? 'Hi\u{1EC3}n th\u{1ECB} ${_items.length}/$_totalItems tr\u{01B0}\u{1EDD}ng'
                              : 'T\u{00EC}m theo t\u{00EA}n tr\u{01B0}\u{1EDD}ng',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Ä\u{00F3}ng',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'T\u{00EC}m tr\u{01B0}\u{1EDD}ng theo t\u{00EA}n',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'X\u{00F3}a t\u{00EC}m ki\u{1EBF}m',
                          onPressed: () {
                            _searchController.clear();
                            _loadSchools(reset: true);
                          },
                          icon: const Icon(Icons.clear),
                        ),
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                textInputAction: TextInputAction.search,
                onChanged: _onSearchChanged,
                onSubmitted: (_) => _loadSchools(reset: true),
              ),
            ),
            Expanded(child: _buildBody(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isInitialLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error),
              const SizedBox(height: 8),
              Text(
                'Kh\u{00F4}ng th\u{1EC3} t\u{1EA3}i danh s\u{00E1}ch tr\u{01B0}\u{1EDD}ng',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _loadSchools(reset: true),
                icon: const Icon(Icons.refresh),
                label: const Text('Th\u{1EED} l\u{1EA1}i'),
              ),
            ],
          ),
        ),
      );
    }

    if (_items.isEmpty) {
      return Center(
        child: Text(
          'Kh\u{00F4}ng c\u{00F3} tr\u{01B0}\u{1EDD}ng ph\u{00F9} h\u{1EE3}p',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
      itemCount: _items.length + (_hasMore ? 1 : 0),
      separatorBuilder: (_, index) => index >= _items.length - 1
          ? const SizedBox.shrink()
          : const Divider(height: 1),
      itemBuilder: (context, index) {
        if (index >= _items.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            child: OutlinedButton.icon(
              onPressed:
                  _isLoadingMore ? null : () => _loadSchools(reset: false),
              icon: _isLoadingMore
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.expand_more),
              label: Text(
                _isLoadingMore
                    ? 'Äang t\u{1EA3}i...'
                    : 'T\u{1EA3}i th\u{00EA}m',
              ),
            ),
          );
        }

        final school = _items[index];
        return ListTile(
          leading: const Icon(Icons.school_outlined),
          title: Text(
            school.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: school.provinceName == null || school.provinceName!.isEmpty
              ? Text(school.uid)
              : Text('${school.provinceName} - ${school.uid}'),
          onTap: () => Navigator.of(context).pop(school),
        );
      },
    );
  }
}

class _FilterError extends StatelessWidget {
  const _FilterError({required this.message, required this.color});

  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.error_outline, size: 18, color: AppColors.error),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style:
                Theme.of(context).textTheme.bodyMedium?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}
