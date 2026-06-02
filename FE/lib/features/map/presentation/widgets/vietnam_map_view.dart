import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

import '../providers/map_provider.dart';
import '../../../../core/utils/geojson_utils.dart';
import '../../data/datasources/geo_local_datasource.dart';
import '../../domain/entities/unit_level.dart';
import '../../domain/entities/administrative_unit.dart';
import 'boundary_label_widget.dart';

class VietnamMapView extends ConsumerStatefulWidget {
  const VietnamMapView({super.key});

  @override
  ConsumerState<VietnamMapView> createState() => _VietnamMapViewState();
}

class _VietnamMapViewState extends ConsumerState<VietnamMapView> {
  final MapController _mapController = MapController();

  static const LatLng _vietnamCenter = LatLng(16.0, 106.5);
  static const double _initialZoom = 6.0;

  LatLng? _currentLocation;
  LatLng? _tappedLocation;
  List<Polygon> _selectedPolygons = [];
  bool _isLoadingBoundary = false;
  double _currentZoom = _initialZoom;

  List<_ProvinceBoundaryEntry> _provinceBoundaryEntries = [];
  bool _pendingCameraMove = false;

  /// Builds _ProvinceBoundaryEntry list from ProvincePolygonEntry structs.
  /// Polygon objects are created here (lightweight) so they are never recreated
  /// on every build — only once when the Isolate resolves.
  @override
  void initState() {
    super.initState();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location services are disabled on this device')),
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
            const SnackBar(content: Text('Location permissions are permanently denied')),
          );
        }
        return;
      }

      if (!mounted) return;
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      );
      if (!mounted) return;
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _mapController.move(_currentLocation!, 12);
      });
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
        final holes = e.rings.skip(1).map(
          (h) => h.map((p) => LatLng(p['lat']!, p['lng']!)).toList(),
        ).toList();
        polygons.add(Polygon(
          points: outer,
          holePointsList: holes.isEmpty ? null : holes,
          color: const Color(0x0A1565C0),
          borderColor: const Color(0x99607D8B),
          borderStrokeWidth: 1.2,
        ));
      }
      final centroid = e.centroid != null ? LatLng(e.centroid!['lat']!, e.centroid!['lng']!) : null;
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
      // Vietnam bounds computed; reserved for future fitBounds on first load.
    }
  }

  Future<void> _handleMapTap(TapPosition tapPosition, LatLng point) async {
    setState(() {
      _tappedLocation = point;
    });

    final repo = ref.read(geoRepositoryProvider);
    final result = await repo.reverseGeocode(point.latitude, point.longitude);

    result.when(
      ok: (unit) async {
        String? provinceName;
        String? districtName;
        String? wardName;

        AdministrativeUnit? currentUnit = unit;

        while (currentUnit != null) {
          final cu = currentUnit;
          if (cu.level == UnitLevel.ward) {
            wardName = cu.name;
          } else if (cu.level == UnitLevel.district) {
            districtName = cu.name;
          } else if (cu.level == UnitLevel.province) {
            provinceName = cu.name;

            final provincesResult = ref.read(provincesProvider).valueOrNull;
            if (provincesResult != null && provincesResult.isOk) {
              final match = provincesResult.valueOrThrow
                  .where((p) => p.code == cu.code)
                  .firstOrNull;
              if (match != null) {
                ref.read(selectedProvinceProvider.notifier).state = match;
              }
            }
          }

          if (cu.parentCode != null) {
            final parentResult = await repo.getUnitByCode(cu.parentCode!);
            if (parentResult.isOk) {
              currentUnit = parentResult.valueOrThrow;
            } else {
              currentUnit = null;
            }
          } else {
            currentUnit = null;
          }
        }

        if (mounted) {
          _showLocationDetails(provinceName, districtName, wardName);
        }
      },
      err: (failure) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Vị trí chọn nằm ngoài lãnh thổ Việt Nam hoặc không có dữ liệu.')),
          );
        }
      },
    );
  }

  void _showLocationDetails(String? province, String? district, String? ward) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color.fromRGBO(33, 150, 243, 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.location_on, color: Colors.blue),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Thông tin khu vực',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (province != null) _buildInfoRow('Tỉnh/Thành phố', province),
            if (district != null) _buildInfoRow('Quận/Huyện', district),
            if (ward != null) _buildInfoRow('Phường/Xã', ward),
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
                child: const Text('Đóng', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
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
            fillColor: Color.fromRGBO(255, 152, 0, 0.15),
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
                content: Text('Dữ liệu bản đồ không hợp lệ hoặc bị lỗi định dạng.')),
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
    double fillOpacity = 0.12;
    double borderOpacity = 0.8;
    double borderStrokeWidth = 1.5;

    if (_currentZoom > 7) {
      fillOpacity = 0.04;
      borderOpacity = 0.5;
      borderStrokeWidth = 2.0;
    }

    final baseColor = const Color.fromRGBO(30, 136, 229, 1);

    final allPolygons = <Polygon>[];
    for (final entry in _provinceBoundaryEntries) {
      for (final polygon in entry.polygons) {
        allPolygons.add(
          Polygon(
            points: polygon.points,
            holePointsList: polygon.holePointsList,
            color: baseColor.withOpacity(fillOpacity),
            borderColor: baseColor.withOpacity(borderOpacity),
            borderStrokeWidth: borderStrokeWidth,
            isFilled: true,
          ),
        );
      }
    }

    return allPolygons;
  }

  Future<void> _handleDistrictTap(
      LatLng point, List<({String code, String name, List<Polygon> polygons})> entries) async {
    for (final entry in entries) {
      for (final polygon in entry.polygons) {
        if (GeoJsonUtils.pointInPolygon(point, polygon.points)) {
          final repo = ref.read(geoRepositoryProvider);
          final wardsResult = await repo.getWards(entry.code);
          wardsResult.when(ok: (wards) {
            if (wards.isNotEmpty) {
              ref.read(selectedDistrictProvider.notifier).state =
                  (code: entry.code, name: entry.name);
            }
          }, err: (_) {});

          final districtBounds = GeoJsonUtils.getBoundsFromPolygons(entry.polygons) ??
              LatLngBounds(point, point);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted || _pendingCameraMove) return;
            _pendingCameraMove = true;
            _mapController.fitCamera(
              CameraFit.bounds(
                bounds: districtBounds,
                padding: const EdgeInsets.all(48.0),
              ),
            );
            Future.delayed(const Duration(milliseconds: 500), () {
              _pendingCameraMove = false;
            });
          });
          return;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(selectedProvinceProvider, (previous, next) {
      if (next != null && (previous == null || previous.code != next.code)) {
        _loadBoundary(next.code);
        ref.read(selectedDistrictProvider.notifier).state = null;
        ref.read(selectedWardProvider.notifier).state = null;
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
    final asyncDistrictBoundaries = selectedProvince != null
        ? ref.watch(districtBoundariesProvider(selectedProvince.code))
        : null;

    final districtEntries =
        <({String code, String name, List<Polygon> polygons})>[];
    asyncDistrictBoundaries?.whenData((entries) {
      for (final entry in entries) {
        districtEntries.add(entry);
      }
    });

    final selectedDistrict = ref.watch(selectedDistrictProvider);
    final asyncWardBoundaries = selectedDistrict != null
        ? ref.watch(wardBoundariesProvider(selectedDistrict.code))
        : null;

    final wardEntries =
        <({String code, String name, List<Polygon> polygons})>[];
    asyncWardBoundaries?.whenData((entries) {
      for (final entry in entries) {
        wardEntries.add(entry);
      }
    });

    final districtCentroidsAsync = selectedProvince != null
        ? ref.watch(districtCentroidsProvider(selectedProvince.code))
        : null;
    final districtCentroids = <String, LatLng>{};
    districtCentroidsAsync?.whenData((m) {
      for (final e in m.entries) {
        districtCentroids[e.key] = e.value;
      }
    });

    final wardCentroidsAsync = selectedDistrict != null
        ? ref.watch(wardCentroidsProvider(selectedDistrict.code))
        : null;
    final wardCentroids = <String, LatLng>{};
    wardCentroidsAsync?.whenData((m) {
      for (final e in m.entries) {
        wardCentroids[e.key] = e.value;
      }
    });

    final provinceLabels = <BoundaryLabel>[];
    if (_currentZoom >= 6) {
      for (final entry in _provinceBoundaryEntries) {
        final centroid = entry.centroid;
        if (centroid != null) {
          provinceLabels.add(BoundaryLabel(
            text: entry.name,
            position: centroid,
            maxWidth: 130,
            fontSize: _currentZoom >= 8 ? 12 : 10,
            fontWeight: FontWeight.w500,
            backgroundColor: const Color(0xCC1A237E),
          ));
        }
      }
    }

    final districtLabels = <BoundaryLabel>[];
    if (_currentZoom >= 9) {
      for (final entry in districtEntries) {
        final centroid = districtCentroids[entry.code] ??
            (entry.polygons.isNotEmpty
                ? GeoJsonUtils.computePolygonCentroid(entry.polygons.first.points)
                : null);
        if (centroid != null) {
          districtLabels.add(BoundaryLabel(
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

    final wardLabels = <BoundaryLabel>[];
    if (_currentZoom >= 12) {
      for (final entry in wardEntries) {
        final centroid = wardCentroids[entry.code] ??
            (entry.polygons.isNotEmpty
                ? GeoJsonUtils.computePolygonCentroid(entry.polygons.first.points)
                : null);
        if (centroid != null) {
          wardLabels.add(BoundaryLabel(
            text: entry.name,
            position: centroid,
            maxWidth: 90,
            fontSize: 8,
            fontWeight: FontWeight.w400,
            backgroundColor: const Color(0xCC4A148C),
          ));
        }
      }
    }

    final districtPolygons = <Polygon>[];
    for (final entry in districtEntries) {
      for (final polygon in entry.polygons) {
        final tapped = selectedDistrict?.code == entry.code;
        districtPolygons.add(Polygon(
          points: polygon.points,
          holePointsList: polygon.holePointsList,
          color: tapped ? const Color(0x4D4CAF50) : const Color(0x1A4CAF50),
          borderColor: tapped ? const Color(0xFF4CAF50) : const Color(0xCC4CAF50),
          borderStrokeWidth: tapped ? 2.5 : 1.8,
          isFilled: true,
        ));
      }
    }

    final wardPolygons = <Polygon>[];
    for (final entry in wardEntries) {
      for (final polygon in entry.polygons) {
        wardPolygons.add(Polygon(
          points: polygon.points,
          holePointsList: polygon.holePointsList,
          color: const Color(0x1A9C27B0),
          borderColor: const Color(0xCC9C27B0),
          borderStrokeWidth: 1.5,
          isFilled: true,
        ));
      }
    }

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _vietnamCenter,
            initialZoom: _initialZoom,
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
              if (districtEntries.isNotEmpty) {
                _handleDistrictTap(point, districtEntries);
              }
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://{s}.basemaps.cartocdn.com/light_nolabels/{z}/{x}/{y}.png',
              tileProvider: CancellableNetworkTileProvider(),
              userAgentPackageName: 'com.example.vietnamese_map',
            ),

            // Province base boundaries
            if (visibleBoundaries.isNotEmpty)
              PolygonLayer(polygons: visibleBoundaries),

            // District boundaries
            if (districtPolygons.isNotEmpty)
              PolygonLayer(polygons: districtPolygons),

            // Ward boundaries
            if (wardPolygons.isNotEmpty)
              PolygonLayer(polygons: wardPolygons),

            // Selected province highlight
            if (_selectedPolygons.isNotEmpty)
              PolygonLayer(polygons: _selectedPolygons),

            // Province labels
            if (provinceLabels.isNotEmpty)
              BoundaryLabelLayer(labels: provinceLabels),

            // District labels
            if (districtLabels.isNotEmpty)
              BoundaryLabelLayer(labels: districtLabels),

            // Ward labels
            if (wardLabels.isNotEmpty)
              BoundaryLabelLayer(labels: wardLabels),

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
                      const Icon(Icons.location_on, color: Colors.red, size: 16),
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
                Marker(
                  point: const LatLng(9.5, 113.5),
                  width: 120,
                  height: 52,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on, color: Colors.red, size: 16),
                      const Text(
                        'QĐ. Trường Sa',
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
                        '(Khánh Hòa)',
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
                if (_tappedLocation != null)
                  Marker(
                    point: _tappedLocation!,
                    width: 40,
                    height: 40,
                    alignment: Alignment.topCenter,
                    child: const Icon(Icons.location_on, color: Colors.red, size: 36),
                  ),
                if (_currentLocation != null)
                  Marker(
                    point: _currentLocation!,
                    width: 40,
                    height: 40,
                    child: const Icon(Icons.my_location, color: Colors.blue, size: 24),
                  ),
              ],
            ),
          ],
        ),

        // Boundary loading overlay
        if (_isLoadingBoundary)
          Container(
            color: Color.fromRGBO(255, 255, 255, 0.5),
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Không tải được ranh giới tỉnh',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                    TextButton(
                      onPressed: () => ref.invalidate(provincePolygonEntriesProvider),
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
                  ref.read(selectedDistrictProvider.notifier).state = null;
                  ref.read(selectedWardProvider.notifier).state = null;
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
