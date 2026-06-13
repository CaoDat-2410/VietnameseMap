import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart' as latlng;

import '../../../../core/errors/failures.dart';
import '../../../../core/widgets/app_error_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../domain/entities/administrative_unit_summary.dart';
import '../providers/map_provider.dart';
import '../../../weather/presentation/providers/weather_provider.dart';
import '../../../weather/presentation/widgets/weather_summary_row.dart';

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

/// Tracks the current drill-down level in the list body.
enum DrillLevel { province, commune }

class ProvinceListBody extends ConsumerStatefulWidget {
  const ProvinceListBody({super.key, this.scrollController});

  final ScrollController? scrollController;

  @override
  ConsumerState<ProvinceListBody> createState() => _ProvinceListBodyState();
}

class _ProvinceListBodyState extends ConsumerState<ProvinceListBody> {
  final _debouncer = Debouncer(milliseconds: 300);
  final _focusNode = FocusNode();
  DrillLevel _previousLevel = DrillLevel.province;

  @override
  void dispose() {
    _debouncer._isRunning = false;
    _focusNode.dispose();
    super.dispose();
  }

  void _onLevelChanged(DrillLevel newLevel) {
    if (_previousLevel != newLevel) {
      _previousLevel = newLevel;
      // Clear search when leaving province level
      if (_previousLevel != DrillLevel.province) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(provinceSearchQueryProvider.notifier).state = '';
        });
      }
      // Auto-scroll to top on level change
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final controller = widget.scrollController;
        if (!mounted || controller == null || !controller.hasClients) return;

        controller.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedProvince = ref.watch(selectedProvinceProvider);
    final selectedCommune = ref.watch(selectedCommuneProvider);

    final DrillLevel level;
    final String? provinceCode;

    if (selectedProvince != null) {
      level = DrillLevel.commune;
      provinceCode = selectedProvince.code;
    } else {
      level = DrillLevel.province;
      provinceCode = null;
    }

    _onLevelChanged(level);

    return Column(
      children: [
        _DrillDownHeader(
          level: level,
          selectedProvince: selectedProvince,
          selectedCommune: selectedCommune,
          onBackToProvinces: () {
            ref.read(selectedProvinceProvider.notifier).state = null;
            ref.read(selectedCommuneProvider.notifier).state = null;
          },
        ),
        if (level == DrillLevel.province) _buildSearchBar(),
        Expanded(
          child: _DrillDownList(
            level: level,
            provinceCode: provinceCode,
            scrollController: widget.scrollController,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    final searchQuery = ref.watch(provinceSearchQueryProvider);
    final query = searchQuery.toLowerCase();

    return Padding(
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
    );
  }
}

// ---------------------------------------------------------------------------
// Breadcrumb header
// ---------------------------------------------------------------------------

class _DrillDownHeader extends StatelessWidget {
  const _DrillDownHeader({
    required this.level,
    required this.selectedProvince,
    required this.selectedCommune,
    required this.onBackToProvinces,
  });

  final DrillLevel level;
  final AdministrativeUnitSummary? selectedProvince;
  final ({String code, int id, String name})? selectedCommune;
  final VoidCallback onBackToProvinces;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (level != DrillLevel.province) ...[
            _BreadcrumbChip(
              icon: Icons.map,
              label: selectedProvince?.name ?? 'Tỉnh',
              color: const Color(0xFF1565C0),
              onTap: onBackToProvinces,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20),
            ),
          ],
          Expanded(
            child: Text(
              _levelTitle,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String get _levelTitle {
    switch (level) {
      case DrillLevel.province:
        return 'Tỉnh / Thành phố';
      case DrillLevel.commune:
        return 'Xã / Phường';
    }
  }
}

class _BreadcrumbChip extends StatelessWidget {
  const _BreadcrumbChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 80),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Drill-down list content
// ---------------------------------------------------------------------------

class _DrillDownList extends ConsumerWidget {
  const _DrillDownList({
    required this.level,
    required this.provinceCode,
    this.scrollController,
  });

  final DrillLevel level;
  final String? provinceCode;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    switch (level) {
      case DrillLevel.province:
        return _ProvinceListView(scrollController: scrollController);
      case DrillLevel.commune:
        return _CommuneListView(
          provinceCode: provinceCode!,
          scrollController: scrollController,
        );
    }
  }
}

class _ProvinceListView extends ConsumerWidget {
  const _ProvinceListView({this.scrollController});

  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncProvinces = ref.watch(provincesProvider);
    final selectedProvince = ref.watch(selectedProvinceProvider);
    final searchQuery = ref.watch(provinceSearchQueryProvider);
    final query = _normalizeVietnamese(searchQuery);

    return asyncProvinces.when(
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
                      _normalizeVietnamese(p.name).contains(query) ||
                      p.code.toLowerCase().contains(query))
                  .toList();

          if (filtered.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.search_off, size: 48, color: Colors.grey),
                  SizedBox(height: 8),
                  Text('Không tìm thấy tỉnh nào',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

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
                child: ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final province = filtered[index];
                    final isSelected =
                        selectedProvince?.code == province.code;

                    return _UnitCard(
                      unit: province,
                      index: filtered.indexOf(province),
                      isSelected: isSelected,
                      onTap: () {
                        ref.read(selectedProvinceProvider.notifier).state =
                            province;
                        ref.read(selectedCommuneProvider.notifier).state = null;
                        ref.read(provinceSearchQueryProvider.notifier).state = '';
                        _selectWeatherForUnit(
                          ref,
                          unit: province,
                          sourceType: WeatherLocationSourceType.province,
                          provinceName: province.name,
                        );
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
    );
  }
}

class _CommuneListView extends ConsumerWidget {
  const _CommuneListView({required this.provinceCode, this.scrollController});

  final String provinceCode;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncCommunes = ref.watch(communesProvider(provinceCode));
    final selectedCommune = ref.watch(selectedCommuneProvider);
    final selectedProvince = ref.watch(selectedProvinceProvider);

    return asyncCommunes.when(
      loading: () => const LoadingWidget(message: 'Đang tải xã/phường...'),
      error: (e, _) => AppErrorWidget(
        failure: UnknownFailure(e.toString()),
        onRetry: () => ref.invalidate(communesProvider(provinceCode)),
      ),
      data: (result) => result.when(
        ok: (communes) {
          if (communes.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.location_off, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 8),
                  Text('Không có dữ liệu xã/phường',
                      style: TextStyle(color: Colors.grey.shade500)),
                ],
              ),
            );
          }

          return ListView.separated(
            controller: scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: communes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final commune = communes[index];
              final isSelected = selectedCommune?.code == commune.code;

              return _UnitCard(
                unit: commune,
                index: index,
                isSelected: isSelected,
                color: const Color(0xFF00695C),
                showChevron: false,
                onTap: () async {
                  ref.read(selectedCommuneProvider.notifier).state =
                      (code: commune.code, name: commune.name, id: commune.id ?? 0);
                  await _selectWeatherForUnit(
                    ref,
                    unit: commune,
                    sourceType: WeatherLocationSourceType.commune,
                    provinceName: selectedProvince?.name,
                    communeName: commune.name,
                  );
                },
              );
            },
          );
        },
        err: (failure) => AppErrorWidget(
          failure: failure,
          onRetry: () => ref.invalidate(communesProvider(provinceCode)),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared card widget for all levels
// ---------------------------------------------------------------------------

Future<void> _selectWeatherForUnit(
  WidgetRef ref, {
  required AdministrativeUnitSummary unit,
  required WeatherLocationSourceType sourceType,
  String? provinceName,
  String? communeName,
  latlng.LatLng? centroid,
}) async {
  if (centroid != null) {
    ref.read(selectedWeatherLocationProvider.notifier).state =
        SelectedWeatherLocation(
      displayName: buildWeatherDisplayName(
        provinceName: provinceName,
        communeName: communeName,
        fallback: unit.name,
      ),
      provinceName: provinceName,
      communeName: communeName,
      lat: centroid.latitude,
      lng: centroid.longitude,
      sourceType: sourceType,
      code: unit.id?.toString() ?? unit.code,
      selectedAt: DateTime.now(),
    );
    ref.invalidate(selectedWeatherProvider);
    return;
  }

  final unitResult = await ref.read(geoRepositoryProvider).getUnitByCode(unit.code);
  unitResult.when(
    ok: (detail) {
      final lat = detail.centroidLat;
      final lng = detail.centroidLng;
      if (lat == null || lng == null) return;

      ref.read(selectedWeatherLocationProvider.notifier).state =
          SelectedWeatherLocation(
        displayName: buildWeatherDisplayName(
          provinceName: provinceName,
          communeName: communeName,
          fallback: unit.name,
        ),
        provinceName: provinceName,
        communeName: communeName,
        lat: lat,
        lng: lng,
        sourceType: sourceType,
        code: unit.code,
        selectedAt: DateTime.now(),
      );
      ref.invalidate(selectedWeatherProvider);
    },
    err: (_) {},
  );
}

String _normalizeVietnamese(String value) {
  var normalized = value.toLowerCase();
  const groups = {
    'a': 'áàảãạăắằẳẵặâấầẩẫậ',
    'e': 'éèẻẽẹêếềểễệ',
    'i': 'íìỉĩị',
    'o': 'óòỏõọôốồổỗộơớờởỡợ',
    'u': 'úùủũụưứừửữự',
    'y': 'ýỳỷỹỵ',
    'd': 'đ',
  };
  for (final entry in groups.entries) {
    for (final rune in entry.value.runes) {
      final char = String.fromCharCode(rune);
      normalized = normalized.replaceAll(char, entry.key);
    }
  }
  return normalized.trim();
}

class _UnitCard extends ConsumerWidget {
  const _UnitCard({
    required this.unit,
    required this.index,
    required this.isSelected,
    this.color,
    this.showChevron = true,
    required this.onTap,
  });

  final AdministrativeUnitSummary unit;
  final int index;
  final bool isSelected;
  final Color? color;
  final bool showChevron;
  final VoidCallback onTap;

  static const _avatarColors = [
    Color(0xFFDA291C),
    Color(0xFF1565C0),
    Color(0xFF2E7D32),
    Color(0xFF6A1B9A),
    Color(0xFFE65100),
    Color(0xFF00695C),
  ];

  Color get _color => color ?? _avatarColors[index % _avatarColors.length];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initial = unit.name.isNotEmpty ? unit.name[0] : '?';
    final weatherAsync = isSelected ? ref.watch(selectedWeatherProvider) : null;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      margin: EdgeInsets.zero,
      decoration: BoxDecoration(
        color: isSelected ? _color.withValues(alpha: 0.08) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? _color.withValues(alpha: 0.5) : Colors.transparent,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected ? _color.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.03),
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
                  backgroundColor: _color.withValues(alpha: 0.12),
                  child: Text(
                    initial,
                    style: TextStyle(
                      color: _color,
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
                      Text(
                        unit.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          unit.code,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (weatherAsync != null) ...[
                        const SizedBox(height: 8),
                        weatherAsync.when(
                          loading: () => Text(
                            'Đang tải thời tiết...',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 12,
                            ),
                          ),
                          error: (_, __) => Text(
                            'Không tải được thời tiết',
                            style: TextStyle(
                              color: Colors.red.shade600,
                              fontSize: 12,
                            ),
                          ),
                          data: (result) => result.when(
                            ok: (snapshot) {
                              final locationCode = snapshot.location.code;
                              final matchesUnit = locationCode == unit.code ||
                                  (unit.id != null &&
                                      locationCode == unit.id.toString());
                              if (!matchesUnit) {
                                return Text(
                                  'Chọn để xem thời tiết',
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 12,
                                  ),
                                );
                              }
                              return WeatherSummaryRow(
                                weather: snapshot.weather,
                                compact: true,
                              );
                            },
                            err: (_) => Text(
                              'Không tải được thời tiết',
                              style: TextStyle(
                                color: Colors.red.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              if (showChevron)
                Icon(
                  Icons.chevron_right,
                  color: isSelected ? _color : Colors.grey.shade400,
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
