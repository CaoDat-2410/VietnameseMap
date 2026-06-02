import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/widgets/app_error_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../domain/entities/administrative_unit_summary.dart';
import '../providers/map_provider.dart';

class Debouncer {
  Debouncer({required this.milliseconds});
  final int milliseconds;
  VoidCallback? _action;
  bool _isRunning = false;

  void run(VoidCallback action) {
    _action = action;
    if (!_isRunning) {
      _isRunning = true;
      Future.delayed(Duration(milliseconds: milliseconds), () {
        _isRunning = false;
        _action?.call();
      });
    }
  }
}

final provinceSearchQueryProvider = StateProvider<String>((ref) => '');

class ProvinceListBody extends ConsumerStatefulWidget {
  const ProvinceListBody({super.key, this.scrollController});

  final ScrollController? scrollController;

  @override
  ConsumerState<ProvinceListBody> createState() => _ProvinceListBodyState();
}

class _ProvinceListBodyState extends ConsumerState<ProvinceListBody> {
  final _debouncer = Debouncer(milliseconds: 300);
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _debouncer._isRunning = false;
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncProvinces = ref.watch(provincesProvider);
    final selectedProvince = ref.watch(selectedProvinceProvider);
    final searchQuery = ref.watch(provinceSearchQueryProvider);
    final query = searchQuery.toLowerCase();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: KeyboardListener(
              focusNode: _focusNode,
              onKeyEvent: (event) {
                if (event is KeyDownEvent &&
                    event.logicalKey == LogicalKeyboardKey.escape) {
                  ref.read(provinceSearchQueryProvider.notifier).state = '';
                }
              },
              child: TextField(
                autofocus: false,
                onChanged: (v) {
                  ref.read(provinceSearchQueryProvider.notifier).state = v;
                },
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm tỉnh thành...',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  prefixIcon: Icon(Icons.search, color: Colors.blue.shade300),
                  suffixIcon: query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, color: Colors.grey),
                          onPressed: () {
                            ref.read(provinceSearchQueryProvider.notifier).state = '';
                          },
                        )
                      : null,
                  fillColor: Colors.transparent,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: asyncProvinces.when(
            loading: () => const LoadingWidget(message: 'Đang tải danh sách tỉnh...'),
            error: (e, _) => AppErrorWidget(
              failure: UnknownFailure(e.toString()),
              onRetry: () => ref.invalidate(provincesProvider),
            ),
            data: (result) => result.when(
              ok: (provinces) {
                final filtered = query.isEmpty
                    ? provinces
                    : provinces
                        .where((p) =>
                            p.name.toLowerCase().contains(query) ||
                            p.code.toLowerCase().contains(query))
                        .toList();

                return Column(
                  children: [
                    if (query.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8, left: 16, right: 16),
                        child: Row(
                          children: [
                            Text(
                              'Tìm thấy ${filtered.length} tỉnh',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    Expanded(
                      child: filtered.isEmpty
                          ? const Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.search_off, size: 48, color: Colors.grey),
                                  SizedBox(height: 8),
                                  Text('Không tìm thấy tỉnh nào',
                                      style: TextStyle(color: Colors.grey)),
                                ],
                              ),
                            )
                          : ListView.separated(
                              controller: widget.scrollController,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final province = filtered[index];
                                final isSelected =
                                    selectedProvince?.code == province.code;

                                return _ProvinceCard(
                                  province: province,
                                  index: filtered.indexOf(province),
                                  isSelected: isSelected,
                                  searchQuery: query,
                                  onTap: () {
                                    ref.read(selectedProvinceProvider.notifier).state =
                                        province;
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
              err: (failure) => AppErrorWidget(
                failure: failure,
                onRetry: () => ref.invalidate(provincesProvider),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProvinceCard extends StatelessWidget {
  const _ProvinceCard({
    required this.province,
    required this.index,
    required this.isSelected,
    required this.onTap,
    this.searchQuery = '',
  });

  final AdministrativeUnitSummary province;
  final int index;
  final bool isSelected;
  final VoidCallback onTap;
  final String searchQuery;

  static const _avatarColors = [
    Color(0xFFDA291C),
    Color(0xFF1565C0),
    Color(0xFF2E7D32),
    Color(0xFF6A1B9A),
    Color(0xFFE65100),
    Color(0xFF00695C),
  ];

  Widget _buildHighlightedText(String text, String query, Color highlightColor, TextStyle baseStyle) {
    if (query.isEmpty) {
      return Text(text, style: baseStyle, maxLines: 1, overflow: TextOverflow.ellipsis);
    }
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final startIndex = lowerText.indexOf(lowerQuery);
    if (startIndex == -1) {
      return Text(text, style: baseStyle, maxLines: 1, overflow: TextOverflow.ellipsis);
    }
    final endIndex = startIndex + query.length;
    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: baseStyle,
        children: [
          TextSpan(text: text.substring(0, startIndex)),
          TextSpan(
            text: text.substring(startIndex, endIndex),
            style: baseStyle.copyWith(
              color: highlightColor,
              fontWeight: FontWeight.bold,
              backgroundColor: highlightColor.withValues(alpha: 0.1),
            ),
          ),
          TextSpan(text: text.substring(endIndex)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = _avatarColors[index % _avatarColors.length];
    final initial = province.name.isNotEmpty ? province.name[0] : '?';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      margin: EdgeInsets.zero,
      decoration: BoxDecoration(
        color: isSelected ? color.withValues(alpha: 0.08) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? color.withValues(alpha: 0.5) : Colors.transparent,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected ? color.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.03),
            blurRadius: isSelected ? 12 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: color.withValues(alpha: 0.12),
                  child: Text(
                    initial,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHighlightedText(
                        province.name,
                        searchQuery,
                        color,
                        const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          province.code,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: isSelected ? color : Colors.grey.shade400,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
