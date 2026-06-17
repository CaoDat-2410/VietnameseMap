import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../providers/map_provider.dart';
import '../../../../core/utils/geojson_utils.dart';
import '../../data/datasources/geo_local_datasource.dart';
import '../../domain/entities/unit_level.dart';
import '../../../weather/presentation/providers/weather_provider.dart'
    show
        SelectedWeatherLocation,
        WeatherLocationSourceType,
        activeWeatherLocationProvider,
        buildWeatherDisplayName,
        selectedWeatherLocationProvider,
        selectedWeatherProvider;
import '../../../weather/presentation/widgets/weather_summary_row.dart';
import 'boundary_label_widget.dart';

class VietnamMapView extends ConsumerStatefulWidget {
  const VietnamMapView({
    super.key,
    this.focusLat,
    this.focusLng,
    this.focusLabel,
  });

  final double? focusLat;
  final double? focusLng;
  final String? focusLabel;

  @override
  ConsumerState<VietnamMapView> createState() => _VietnamMapViewState();
}

class _EventFocus {
  const _EventFocus({required this.lat, required this.lng, required this.label});
  final double lat;
  final double lng;
  final String label;
}

class _VietnamMapViewState extends ConsumerState<VietnamMapView> {
  final MapController _mapController = MapController();

  static const LatLng _vietnamCenter = LatLng(16.0, 106.5);
  static const double _initialZoom = 6.0;
  static const double _focusZoom = 13.0;

  LatLng? _currentLocation;
  LatLng? _tappedLocation;
  List<Polygon> _selectedPolygons = [];
  bool _isLoadingBoundary = false;
  double _currentZoom = _initialZoom;

  List<_ProvinceBoundaryEntry> _provinceBoundaryEntries = [];
  bool _pendingCameraMove = false;
  _EventFocus? _eventFocus;
  bool _focusCameraApplied = false;

  @override
  void initState() {
    super.initState();
    final lat = widget.focusLat;
    final lng = widget.focusLng;
    final label = widget.focusLabel;
    if (lat != null && lng != null) {
      _eventFocus = _EventFocus(lat: lat, lng: lng, label: label ?? '');
    }
  }

  void _maybeApplyFocusCamera() {
    final focus = _eventFocus;
    if (focus == null || _focusCameraApplied) return;
    _focusCameraApplied = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _mapController.move(LatLng(focus.lat, focus.lng), _focusZoom);
    });
  }

  Future<void> _getCurrentLocation() async {
    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Location services are disabled on this device')),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permissions are denied')),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Location permissions are permanently denied')),
          );
        }
        return;
      }

      if (!mounted) return;
      final position = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.medium),
      );
      if (!mounted) return;
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _mapController.move(_currentLocation!, 12);
      });
      ref.read(selectedWeatherLocationProvider.notifier).state =
          SelectedWeatherLocation(
        displayName: 'Vị trí hiện tại',
        lat: position.latitude,
        lng: position.longitude,
        sourceType: WeatherLocationSourceType.currentLocation,
        selectedAt: DateTime.now(),
      );
      ref.invalidate(selectedWeatherProvider);
    } catch (e) {
      debugPrint('Error getting current location: $e');
    }
  }

  void _buildBoundaryEntries(List<ProvincePolygonEntry> entries) {
    _provinceBoundaryEntries = entries.map((e) {
      final polygons = <Polygon>[];
      for (final ring in e.rings) {
        if (ring.isEmpty) continue;
        final outer = ring.map((p) => LatLng(p['lat']!, p['lng']!)).toList();
        final holes = e.rings
            .skip(1)
            .map(
              (h) => h.map((p) => LatLng(p['lat']!, p['lng']!)).toList(),
            )
            .toList();
        polygons.add(Polygon(
          points: outer,
          holePointsList: holes.isEmpty ? null : holes,
          color: const Color(0x0A1565C0),
          borderColor: const Color(0x99607D8B),
          borderStrokeWidth: 1.2,
        ));
      }
      final centroid = e.centroid != null
          ? LatLng(e.centroid!['lat']!, e.centroid!['lng']!)
          : null;
      return _ProvinceBoundaryEntry(
        code: e.code,
        name: e.name,
        polygons: polygons,
        centroid: centroid,
      );
    }).toList();

    _computeVietnamBoundsFromEntries(_provinceBoundaryEntries);
  }

  void _computeVietnamBoundsFromEntries(List<_ProvinceBoundaryEntry> entries) {
    double minLat = 90, maxLat = -90, minLng = 180, maxLng = -180;
    for (final entry in entries) {
      for (final polygon in entry.polygons) {
        for (final point in polygon.points) {
          if (point.latitude < minLat) minLat = point.latitude;
          if (point.latitude > maxLat) maxLat = point.latitude;
          if (point.longitude < minLng) minLng = point.longitude;
          if (point.longitude > maxLng) maxLng = point.longitude;
        }
      }
    }
    if (minLat != 90) {
      // Vietnam bounds computed
    }
  }

  Future<void> _handleMapTap(TapPosition tapPosition, LatLng point) async {
    setState(() {
      _tappedLocation = point;
    });

    final repo = ref.read(geoRepositoryProvider);
    final result = await repo.reverseGeocode(point.latitude, point.longitude);

    await result.when(
      ok: (unit) async {
        String? provinceName;
        String? communeName;
        final String selectedCode = unit.code;

        if (unit.level == UnitLevel.commune) {
          communeName = unit.name;
        } else if (unit.level == UnitLevel.province) {
          provinceName = unit.name;
        }

        // Get parent province for commune
        if (unit.parentCode != null) {
          final parentResult = await repo.getUnitByCode(unit.parentCode!);
          if (parentResult.isOk) {
            provinceName = parentResult.valueOrThrow.name;
          }
        }

        // Update selected province
        if (provinceName != null) {
          final provincesResult = ref.read(provincesProvider).valueOrNull;
          if (provincesResult != null && provincesResult.isOk) {
            final match = provincesResult.valueOrThrow
                .where(
                    (p) => p.name == provinceName || p.code == unit.parentCode)
                .firstOrNull;
            if (match != null) {
              ref.read(selectedProvinceProvider.notifier).state = match;
            }
          }
        }

        // Update selected commune
        if (communeName != null) {
          ref.read(selectedCommuneProvider.notifier).state =
              (code: unit.code, name: communeName, id: unit.id);
        }

        ref.read(selectedWeatherLocationProvider.notifier).state =
            SelectedWeatherLocation(
          displayName: buildWeatherDisplayName(
            provinceName: provinceName,
            communeName: communeName,
            fallback: 'Vị trí đã chọn',
          ),
          provinceName: provinceName,
          communeName: communeName,
          lat: point.latitude,
          lng: point.longitude,
          sourceType: WeatherLocationSourceType.mapTap,
          code: selectedCode,
          selectedAt: DateTime.now(),
        );
        ref.invalidate(selectedWeatherProvider);

        if (mounted) {
          _showLocationDetails(provinceName, communeName);
        }
      },
      err: (failure) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Vị trí chọn nằm ngoài lãnh thổ Việt Nam hoặc không có dữ liệu.')),
          );
        }
      },
    );
  }

  void _showLocationDetails(String? province, String? commune) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Color.fromRGBO(33, 150, 243, 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.location_on, color: Colors.blue),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Thông tin khu vực',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (province != null) _buildInfoRow('Tỉnh/Thành phố', province),
              if (commune != null) _buildInfoRow('Xã/Phường', commune),
              const Divider(height: 24),
              Consumer(
                builder: (context, ref, _) {
                  final weatherAsync = ref.watch(selectedWeatherProvider);
                  return weatherAsync.when(
                    loading: () => Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text('Đang tải thời tiết...'),
                      ],
                    ),
                    error: (_, __) => const Text('Không tải được thời tiết'),
                    data: (result) => result.when(
                      ok: (snapshot) =>
                          WeatherSummaryRow(weather: snapshot.weather),
                      err: (_) => const Text('Không tải được thời tiết'),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  context.go('/weather');
                },
                icon: const Icon(Icons.cloud_outlined),
                label: const Text('Xem chi tiết thời tiết'),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Đóng',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadBoundary(String code) async {
    if (!mounted) return;
    setState(() {
      _isLoadingBoundary = true;
    });

    final repo = ref.read(geoRepositoryProvider);
    final result = await repo.getProvinceBoundary(code);

    if (!mounted) return;
    setState(() {
      _isLoadingBoundary = false;
    });

    result.when(
      ok: (feature) {
        try {
          final coords = feature.geometry.coordinates;
          if (coords.isEmpty) {
            throw Exception('Empty GeoJSON coordinates');
          }
          final polygons = GeoJsonUtils.parseGeoJsonToPolygons(
            coords,
            fillColor: const Color.fromRGBO(255, 152, 0, 0.15),
            borderColor: Colors.transparent,
            borderStrokeWidth: 0.0,
          );

          if (polygons.isEmpty) {
            throw Exception('Parsed polygons are empty');
          }

          setState(() {
            _selectedPolygons = polygons;
          });

          final bounds = GeoJsonUtils.getBoundsFromPolygons(polygons);
          if (bounds != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted || _pendingCameraMove) return;
              _pendingCameraMove = true;
              _mapController.fitCamera(
                CameraFit.bounds(
                  bounds: bounds,
                  padding: const EdgeInsets.all(48.0),
                ),
              );
              Future.delayed(const Duration(milliseconds: 500), () {
                _pendingCameraMove = false;
              });
            });
          }
        } catch (e) {
          debugPrint('Error parsing GeoJSON: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content:
                    Text('Dữ liệu bản đồ không hợp lệ hoặc bị lỗi định dạng.')),
          );
        }
      },
      err: (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải dữ liệu bản đồ: ${failure.message}'),
            action: SnackBarAction(
              label: 'Thử lại',
              onPressed: () => _loadBoundary(code),
            ),
          ),
        );
      },
    );
  }

  List<Polygon> _getVisibleBoundaryPolygons() {
    double fillOpacity = 0.22;
    double borderOpacity = 0.95;
    double borderStrokeWidth = 2.2;

    if (_currentZoom > 7) {
      fillOpacity = 0.10;
      borderOpacity = 0.75;
      borderStrokeWidth = 2.4;
    }

    const baseColor = Color(0xFF1565C0);

    final allPolygons = <Polygon>[];
    for (final entry in _provinceBoundaryEntries) {
      for (final polygon in entry.polygons) {
        allPolygons.add(
          Polygon(
            points: polygon.points,
            holePointsList: polygon.holePointsList,
            color: baseColor.withValues(alpha: fillOpacity),
            borderColor: baseColor.withValues(alpha: borderOpacity),
            borderStrokeWidth: borderStrokeWidth,
          ),
        );
      }
    }

    return allPolygons;
  }

  @override
  Widget build(BuildContext context) {
    _maybeApplyFocusCamera();
    ref.listen(selectedProvinceProvider, (previous, next) {
      if (next != null && (previous == null || previous.code != next.code)) {
        _loadBoundary(next.code);
        ref.read(selectedCommuneProvider.notifier).state = null;
      }
    });

    final asyncPolygonEntries = ref.watch(provincePolygonEntriesProvider);
    asyncPolygonEntries.whenData((entries) {
      if (_provinceBoundaryEntries.isEmpty) {
        _buildBoundaryEntries(entries);
        setState(() {});
      }
    });

    final visibleBoundaries = _getVisibleBoundaryPolygons();

    final selectedProvince = ref.watch(selectedProvinceProvider);
    final selectedCommune = ref.watch(selectedCommuneProvider);

    // Load commune boundaries when province is selected
    final asyncCommuneBoundaries = selectedProvince != null
        ? ref.watch(communeBoundariesProvider(selectedProvince.code))
        : null;

    final communeEntries =
        <({String code, String name, List<Polygon> polygons})>[];
    asyncCommuneBoundaries?.whenData((entries) {
      for (final entry in entries) {
        communeEntries.add(entry);
      }
    });

    // Commune centroids for labels
    final communeCentroidsAsync = selectedProvince != null
        ? ref.watch(communeCentroidsProvider(selectedProvince.code))
        : null;
    final communeCentroids = <String, LatLng>{};
    communeCentroidsAsync?.whenData((m) {
      for (final e in m.entries) {
        communeCentroids[e.key] = e.value;
      }
    });

    final provinceLabels = <BoundaryLabel>[];
    if (_currentZoom >= 7.5) {
      for (final entry in _provinceBoundaryEntries) {
        final centroid = entry.centroid;
        if (centroid != null) {
          provinceLabels.add(BoundaryLabel(
            text: entry.name,
            position: centroid,
            maxWidth: 130,
            fontSize: _currentZoom >= 8 ? 12 : 10,
          ));
        }
      }
    }

    final communeLabels = <BoundaryLabel>[];
    if (_currentZoom >= 9) {
      for (final entry in communeEntries) {
        final centroid = communeCentroids[entry.code] ??
            (entry.polygons.isNotEmpty
                ? GeoJsonUtils.computePolygonCentroid(
                    entry.polygons.first.points)
                : null);
        if (centroid != null) {
          communeLabels.add(BoundaryLabel(
            text: entry.name,
            position: centroid,
            maxWidth: 110,
            fontSize: _currentZoom >= 11 ? 10 : 9,
            fontWeight: FontWeight.w400,
            backgroundColor: const Color(0xCC004D40),
          ));
        }
      }
    }

    final communePolygons = <Polygon>[];
    for (final entry in communeEntries) {
      for (final polygon in entry.polygons) {
        final tapped = selectedCommune?.code == entry.code;
        communePolygons.add(Polygon(
          points: polygon.points,
          holePointsList: polygon.holePointsList,
          color: tapped ? const Color(0x4D4CAF50) : const Color(0x1A4CAF50),
          borderColor:
              tapped ? const Color(0xFF4CAF50) : const Color(0xCC4CAF50),
          borderStrokeWidth: tapped ? 2.5 : 1.8,
        ));
      }
    }

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _eventFocus != null
                ? LatLng(_eventFocus!.lat, _eventFocus!.lng)
                : _vietnamCenter,
            initialZoom: _eventFocus != null ? _focusZoom : _initialZoom,
            minZoom: 5.5,
            maxZoom: 18.0,
            onPositionChanged: (position, hasGesture) {
              if (position.zoom != _currentZoom) {
                setState(() {
                  _currentZoom = position.zoom;
                });
              }
            },
            onTap: (tapPos, point) {
              _handleMapTap(tapPos, point);
            },
          ),
          children: [
            TileLayer(
              urlTemplate:
                  'https://{s}.basemaps.cartocdn.com/light_nolabels/{z}/{x}/{y}.png',
              tileProvider: CancellableNetworkTileProvider(),
              userAgentPackageName: 'com.example.vietnamese_map',
            ),

            // Province base boundaries
            if (visibleBoundaries.isNotEmpty)
              PolygonLayer(polygons: visibleBoundaries),

            // Commune boundaries
            if (communePolygons.isNotEmpty)
              PolygonLayer(polygons: communePolygons),

            // Selected province highlight
            if (_selectedPolygons.isNotEmpty)
              PolygonLayer(polygons: _selectedPolygons),

            // Province labels
            if (provinceLabels.isNotEmpty)
              BoundaryLabelLayer(labels: provinceLabels),

            // Commune labels
            if (communeLabels.isNotEmpty)
              BoundaryLabelLayer(labels: communeLabels),

            // Markers
            MarkerLayer(
              markers: [
                Marker(
                  point: const LatLng(16.5, 112.0),
                  width: 120,
                  height: 52,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on,
                          color: Colors.red, size: 16),
                      const Text(
                        'QĐ. Hoàng Sa',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                          height: 1.1,
                          shadows: [Shadow(color: Colors.white, blurRadius: 4)],
                        ),
                      ),
                      const Text(
                        '(Đà Nẵng)',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 8,
                          height: 1.1,
                          shadows: [Shadow(color: Colors.white, blurRadius: 4)],
                        ),
                      ),
                    ],
                  ),
                ),
                const Marker(
                  point: LatLng(9.5, 113.5),
                  width: 120,
                  height: 52,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.location_on, color: Colors.red, size: 16),
                      Text(
                        'QĐ. Trường Sa',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                          height: 1.1,
                          shadows: [
                            Shadow(color: Color(0xFFFFFFFF), blurRadius: 4)
                          ],
                        ),
                      ),
                      Text(
                        '(Khánh Hòa)',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 8,
                          height: 1.1,
                          shadows: [
                            Shadow(color: Color(0xFFFFFFFF), blurRadius: 4)
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (_tappedLocation != null)
                  Marker(
                    point: _tappedLocation!,
                    width: 40,
                    height: 40,
                    alignment: Alignment.topCenter,
                    child: const Icon(Icons.location_on,
                        color: Colors.red, size: 36),
                  ),
                if (_currentLocation != null)
                  Marker(
                    point: _currentLocation!,
                    width: 40,
                    height: 40,
                    child: const Icon(Icons.my_location,
                        color: Colors.blue, size: 24),
                  ),
                if (_eventFocus != null)
                  Marker(
                    point: LatLng(_eventFocus!.lat, _eventFocus!.lng),
                    width: 160,
                    height: 60,
                    alignment: Alignment.bottomCenter,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Tooltip(
                          message: _eventFocus!.label,
                          child: const Icon(Icons.location_on,
                              color: Colors.red, size: 40),
                        ),
                        if (_eventFocus!.label.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                            child: Text(
                              _eventFocus!.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),

        // Boundary loading overlay
        if (_isLoadingBoundary)
          Container(
            color: const Color(0x80FFFFFF),
            child: const Center(child: CircularProgressIndicator()),
          ),

        // Boundaries loading indicator
        if (asyncPolygonEntries.isLoading)
          Positioned(
            top: 16,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Đang tải ranh giới...',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Error indicator
        if (asyncPolygonEntries.hasError)
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Material(
              borderRadius: BorderRadius.circular(12),
              elevation: 4,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline,
                        color: Colors.red.shade700, size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Không tải được ranh giới tỉnh',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                    TextButton(
                      onPressed: () =>
                          ref.invalidate(provincePolygonEntriesProvider),
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Map control buttons
        Positioned(
          right: 16,
          bottom: 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton.small(
                heroTag: 'zoom_in',
                onPressed: () {
                  _mapController.move(
                    _mapController.camera.center,
                    _mapController.camera.zoom + 1,
                  );
                },
                child: const Icon(Icons.add),
              ),
              const SizedBox(height: 8),
              FloatingActionButton.small(
                heroTag: 'zoom_out',
                onPressed: () {
                  _mapController.move(
                    _mapController.camera.center,
                    _mapController.camera.zoom - 1,
                  );
                },
                child: const Icon(Icons.remove),
              ),
              const SizedBox(height: 8),
              FloatingActionButton.small(
                heroTag: 'reset',
                onPressed: () {
                  _mapController.move(_vietnamCenter, _initialZoom);
                  setState(() {
                    _selectedPolygons = [];
                    _tappedLocation = null;
                  });
                  ref.read(selectedProvinceProvider.notifier).state = null;
                  ref.read(selectedCommuneProvider.notifier).state = null;
                  ref.read(selectedWeatherLocationProvider.notifier).state =
                      null;
                  ref.invalidate(selectedWeatherProvider);
                  ref.invalidate(activeWeatherLocationProvider);
                },
                child: const Icon(Icons.refresh),
              ),
              const SizedBox(height: 8),
              FloatingActionButton.small(
                heroTag: 'my_location',
                onPressed: _getCurrentLocation,
                child: const Icon(Icons.my_location),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProvinceBoundaryEntry {
  const _ProvinceBoundaryEntry({
    required this.code,
    required this.name,
    required this.polygons,
    this.centroid,
  });

  final String code;
  final String name;
  final List<Polygon> polygons;
  final LatLng? centroid;
}
