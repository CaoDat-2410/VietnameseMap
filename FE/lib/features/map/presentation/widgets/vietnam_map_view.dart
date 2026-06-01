import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

import '../providers/map_provider.dart';
import '../../../../core/utils/geojson_utils.dart';
import '../../domain/entities/unit_level.dart';
import '../../domain/entities/administrative_unit.dart';

class VietnamMapView extends ConsumerStatefulWidget {
  const VietnamMapView({super.key});

  @override
  ConsumerState<VietnamMapView> createState() => _VietnamMapViewState();
}

class _VietnamMapViewState extends ConsumerState<VietnamMapView> {
  final MapController _mapController = MapController();

  // Vietnam geographic bounds and center
  static const LatLng _vietnamCenter = LatLng(16.0, 106.5);
  static const double _initialZoom = 6.0;
  static final LatLngBounds _vietnamBounds = LatLngBounds(
    const LatLng(2.0, 95.0),    // SW corner (widened to prevent camera constraint assertion)
    const LatLng(28.0, 118.0),  // NE corner
  );

  LatLng? _currentLocation;
  LatLng? _tappedLocation;
  List<Polygon> _selectedPolygons = [];
  bool _isLoadingBoundary = false;
  double _currentZoom = _initialZoom;

  // Cached province boundary polygons from the local GeoJSON asset
  List<_ProvinceBoundaryEntry> _provinceBoundaryEntries = [];
  bool _boundariesLoaded = false;

  @override
  void initState() {
    super.initState();
  }

  // -----------------------------------------------------------------------
  // Geolocation
  // -----------------------------------------------------------------------

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

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 5),
        ),
      );

      final latLng = LatLng(position.latitude, position.longitude);
      setState(() {
        _currentLocation = latLng;
      });
      _mapController.move(latLng, 14.0);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to determine location on this device')),
        );
      }
    }
  }

  // -----------------------------------------------------------------------
  // Map tap → reverse geocode
  // -----------------------------------------------------------------------

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
            
            // Highlight this province on the map
            final provincesResult = ref.read(provincesProvider).valueOrNull;
            if (provincesResult != null && provincesResult.isOk) {
              final match = provincesResult.valueOrThrow.where((p) => p.code == cu.code).firstOrNull;
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
            const SnackBar(content: Text('Vị trí chọn nằm ngoài lãnh thổ Việt Nam hoặc không có dữ liệu.')),
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

  // -----------------------------------------------------------------------
  // Load selected province boundary (highlight) via backend API
  // -----------------------------------------------------------------------

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
            fillColor: Color.fromRGBO(255, 152, 0, 0.15), // Distinct color with low opacity for selection
            borderColor: Colors.transparent,            // Clear border
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
            _mapController.fitCamera(
              CameraFit.bounds(
                bounds: bounds,
                padding: const EdgeInsets.all(48.0),
              ),
            );
          }
        } catch (e) {
          debugPrint('Error parsing GeoJSON: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Dữ liệu bản đồ không hợp lệ hoặc bị lỗi định dạng.')),
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

  // -----------------------------------------------------------------------
  // Parse all province boundaries from the local GeoJSON features
  // -----------------------------------------------------------------------

  void _buildBoundaryEntries(List<Map<String, dynamic>> features) {
    if (_boundariesLoaded) return;

    final entries = <_ProvinceBoundaryEntry>[];
    for (final feature in features) {
      final geometry = feature['geometry'] as Map<String, dynamic>?;
      final properties = feature['properties'] as Map<String, dynamic>?;
      if (geometry == null || properties == null) continue;

      final coords = geometry['coordinates'];
      if (coords == null) continue;

      final code = properties['ma'] as String? ?? '';
      final name = properties['ten'] as String? ?? '';

      final polygons = GeoJsonUtils.parseGeoJsonToPolygons(
        coords,
        fillColor: const Color(0x0A1565C0), // very subtle blue fill
        borderColor: const Color(0x99607D8B), // blue-grey border
        borderStrokeWidth: 1.2,
      );

      if (polygons.isNotEmpty) {
        entries.add(_ProvinceBoundaryEntry(
          code: code,
          name: name,
          polygons: polygons,
        ));
      }
    }

    _provinceBoundaryEntries = entries;
    _boundariesLoaded = true;
  }

  // -----------------------------------------------------------------------
  // Determine which boundary polygons to show based on current zoom level
  // -----------------------------------------------------------------------

  List<Polygon> _getVisibleBoundaryPolygons() {
    // Calculate styling based on zoom to prevent clutter
    // Fill fades out when zoomed in, but border remains visible to keep Vietnam highlighted.
    double fillOpacity = 0.12;
    double borderOpacity = 0.8;
    double borderStrokeWidth = 1.5;

    if (_currentZoom > 7) {
      fillOpacity = 0.04;
      borderOpacity = 0.5;
      borderStrokeWidth = 2.0;
    }

    final baseColor = const Color.fromRGBO(30, 136, 229, 1); // Prominent blue

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

  // Masking complex polygons with hundreds of holes in flutter_map
  // causes the 'earcut' triangulator to crash with "not a polygon".
  // Removed world mask to prevent crashing.

  // -----------------------------------------------------------------------
  // Build
  // -----------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    // Listen for province selection changes to load the highlight boundary
    ref.listen(selectedProvinceProvider, (previous, next) {
      if (next != null && (previous == null || previous.code != next.code)) {
        _loadBoundary(next.code);
      }
    });

    // Watch for the local GeoJSON data and build polygon entries once
    final asyncBoundaries = ref.watch(allProvinceBoundariesProvider);
    asyncBoundaries.whenData((features) {
      if (!_boundariesLoaded) {
        _buildBoundaryEntries(features);
      }
    });

    final visibleBoundaries = _getVisibleBoundaryPolygons();

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _vietnamCenter,
            initialZoom: _initialZoom,
            minZoom: 5.5,
            maxZoom: 18.0,
            // Restrict camera to Vietnam's bounding box
            cameraConstraint: CameraConstraint.contain(
              bounds: _vietnamBounds,
            ),
            onPositionChanged: (position, hasGesture) {
              if (position.zoom != _currentZoom) {
                setState(() {
                  _currentZoom = position.zoom;
                });
              }
            },
            onTap: _handleMapTap,
          ),
          children: [
            // Layer 1: Base map tiles (OpenStreetMap)
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.vietnamese_map',
            ),

            // Layer 2: All province boundaries (subtle, zoom-dependent)
            if (visibleBoundaries.isNotEmpty)
              PolygonLayer(
                polygons: visibleBoundaries,
              ),

            // Layer 3: Selected province highlight
            if (_selectedPolygons.isNotEmpty)
              PolygonLayer(
                polygons: _selectedPolygons,
              ),

            // Layer 4: Markers (Islands, Tapped location, Current location)
            MarkerLayer(
              markers: [
                // Hoang Sa Marker
                const Marker(
                  point: LatLng(16.5, 112.0),
                  width: 120,
                  height: 40,
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      Icon(Icons.location_on, color: Colors.red, size: 16),
                      Text(
                        'QĐ. Hoàng Sa\n(Đà Nẵng)',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                          shadows: [
                            Shadow(color: Colors.white, blurRadius: 4),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Truong Sa Marker
                const Marker(
                  point: LatLng(9.5, 113.5),
                  width: 120,
                  height: 40,
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      Icon(Icons.location_on, color: Colors.red, size: 16),
                      Text(
                        'QĐ. Trường Sa\n(Khánh Hòa)',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                          shadows: [
                            Shadow(color: Colors.white, blurRadius: 4),
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
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),

        // Boundaries loading indicator (first load from asset)
        if (asyncBoundaries.isLoading)
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

        // Error indicator for boundaries
        if (asyncBoundaries.hasError)
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
                      onPressed: () => ref.invalidate(allProvinceBoundariesProvider),
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Zoom level indicator (debug, subtle)
        // Positioned(
        //   top: 16,
        //   right: 60,
        //   child: Container(
        //     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        //     decoration: BoxDecoration(
        //       color: Colors.black54,
        //       borderRadius: BorderRadius.circular(8),
        //     ),
        //     child: Text(
        //       'z${_currentZoom.toStringAsFixed(1)}',
        //       style: const TextStyle(color: Colors.white, fontSize: 11),
        //     ),
        //   ),
        // ),

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

// ---------------------------------------------------------------------------
// Internal model for caching parsed province boundary polygons
// ---------------------------------------------------------------------------

class _ProvinceBoundaryEntry {
  const _ProvinceBoundaryEntry({
    required this.code,
    required this.name,
    required this.polygons,
  });

  final String code;
  final String name;
  final List<Polygon> polygons;
}
