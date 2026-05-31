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
  static const LatLng _vietnamCenter = LatLng(16.0, 108.0);
  LatLng? _currentLocation;
  LatLng? _tappedLocation;
  List<Polygon> _selectedPolygons = [];
  bool _isLoadingBoundary = false;

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
          if (currentUnit!.level == UnitLevel.ward) {
            wardName = currentUnit!.name;
          } else if (currentUnit!.level == UnitLevel.district) {
            districtName = currentUnit!.name;
          } else if (currentUnit!.level == UnitLevel.province) {
            provinceName = currentUnit!.name;
            
            // Highlight this province on the map
            final provincesResult = ref.read(provincesProvider).valueOrNull;
            if (provincesResult != null && provincesResult.isOk) {
              final match = provincesResult.valueOrThrow.where((p) => p.code == currentUnit!.code).firstOrNull;
              if (match != null) {
                ref.read(selectedProvinceProvider.notifier).state = match;
              }
            }
          }

          if (currentUnit!.parentCode != null) {
            final parentResult = await repo.getUnitByCode(currentUnit!.parentCode!);
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
                    color: Colors.blue.withOpacity(0.1),
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
            fillColor: Colors.orange.withOpacity(0.15), // Distinct color with low opacity for selection
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

  @override
  Widget build(BuildContext context) {
    ref.listen(selectedProvinceProvider, (previous, next) {
      if (next != null && (previous == null || previous.code != next.code)) {
        _loadBoundary(next.code);
      }
    });

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _vietnamCenter,
            initialZoom: 5.5,
            minZoom: 4.0,
            maxZoom: 18.0,
            onTap: _handleMapTap,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.vietnamese_map',
            ),
            PolygonLayer(
              polygons: _selectedPolygons,
            ),
            if (_tappedLocation != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: _tappedLocation!,
                    width: 40,
                    height: 40,
                    alignment: Alignment.topCenter,
                    child: const Icon(Icons.location_on, color: Colors.red, size: 36),
                  ),
                ],
              ),
            if (_currentLocation != null)
              MarkerLayer(
                markers: [
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
        if (_isLoadingBoundary)
          Container(
            color: Colors.white.withOpacity(0.5),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
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
                  _mapController.move(_vietnamCenter, 5.5);
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
