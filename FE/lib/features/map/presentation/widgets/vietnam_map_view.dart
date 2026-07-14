import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../providers/map_provider.dart';
import '../providers/osm_geocoding_provider.dart';
import '../../../../core/utils/geojson_utils.dart';
import '../../data/datasources/geo_local_datasource.dart';
import '../../data/repositories/osm_geocoding_repository.dart';
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
    this.schoolUids,
  });

  final double? focusLat;
  final double? focusLng;
  final String? focusLabel;
  final List<String>? schoolUids;

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
  bool _isLoadingCommuneBoundaries = false;

  // Use a ValueNotifier for zoom so we can rebuild only the label layer
  // (and other zoom-dependent widgets) without forcing a full FlutterMap rebuild.
  final ValueNotifier<double> _zoomNotifier =
      ValueNotifier<double>(_initialZoom);

  List<_ProvinceBoundaryEntry> _provinceBoundaryEntries = [];

  // Cached visible polygons — built once per change of boundary entries, not per frame.
  // Avoids allocating 63+ new Polygon objects on every zoom/keyboard tap.
  List<Polygon> _cachedVisibleBoundaries = const [];
  List<({String code, String name, List<Polygon> polygons})>
      _cachedCommuneEntries = const [];
  Map<String, LatLng> _cachedCommuneCentroids = const {};
  List<({String code, String name, List<Polygon> polygons})>?
      _lastSeenCommuneEntries;
  Map<String, LatLng>? _lastSeenCommuneCentroids;

  // Cache for commune PolygonLayer; keyed by (entries identity, tapped code).
  // Avoids re-allocating hundreds of Polygon objects on every widget rebuild.
  String? _communePolygonsCacheKey;
  List<Polygon> _cachedCommunePolygons = const [];

  bool _pendingCameraMove = false;
  _EventFocus? _eventFocus;
  bool _focusCameraApplied = false;

  // School markers state (populated via on-demand OSM geocoding only)
  List<SchoolGeocode> _schoolGeocodes = [];
  SchoolGeocode? _selectedSchool;
  bool _isLoadingSchools = false;

  // Map readiness gating: the OSM geocode may resolve before the FlutterMap
  // widget has bound the MapController. We wait for the map's first onPositionChanged
  // event (which only fires after the map is mounted and laid out) before
  // dispatching the auto-zoom.
  bool _mapReady = false;
  Completer<void>? _mapReadyCompleter;
  int _zoomRetry = 0;

  // Performance: debounce zoom updates to reduce rebuild frequency
  Timer? _zoomDebounceTimer;
  static const _zoomDebounceMs = 150;

  @override
  void dispose() {
    _zoomNotifier.dispose();
    _zoomDebounceTimer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final lat = widget.focusLat;
    final lng = widget.focusLng;
    final label = widget.focusLabel;
    if (lat != null && lng != null) {
      _eventFocus = _EventFocus(lat: lat, lng: lng, label: label ?? '');
    }
    // Fire the geocode call immediately on mount. MapController is only needed
    // by _zoomToGeocoded (called inside addPostFrameCallback), not by the fetch.
    if (widget.schoolUids != null && widget.schoolUids!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.schoolUids != null) {
          _geocodeAndShowSchools(widget.schoolUids!);
        }
      });
    }
  }

  Future<void> _geocodeAndShowSchools(List<String> schoolUids) async {
    if (!mounted) return;
    setState(() {
      _isLoadingSchools = true;
    });

    try {
      final results = await ref.read(schoolGeocodeProvider(schoolUids).future);
      if (!mounted) return;
      setState(() {
        _schoolGeocodes = results;
        _isLoadingSchools = false;
      });

      // Auto-zoom to the first geocoded school with coordinates
      final withCoords = results.where((s) => s.hasCoordinates).toList();
      if (withCoords.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _zoomToGeocoded(withCoords);
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingSchools = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể tải vị trí trường học: $e'),
          action: SnackBarAction(
            label: 'Thử lại',
            onPressed: () =>
                _geocodeAndShowSchools(widget.schoolUids ?? const []),
          ),
        ),
      );
    }
  }

  void _zoomToGeocoded(List<SchoolGeocode> schools) {
    if (schools.isEmpty || !_mapReady) return;
    if (_zoomRetry > 2) return;
    try {
      if (schools.length == 1) {
        _mapController.move(
          LatLng(schools.first.latitude!, schools.first.longitude!),
          15,
        );
      } else {
        final bounds = LatLngBounds.fromPoints(
          schools
              .where((s) => s.hasCoordinates)
              .map((s) => LatLng(s.latitude!, s.longitude!))
              .toList(),
        );
        _mapController.fitCamera(
          CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(80.0)),
        );
      }
      _zoomRetry = 0;
    } catch (e) {
      _zoomRetry++;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _zoomToGeocoded(schools);
      });
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

  void _handleGeocodedSchoolTap(SchoolGeocode school) {
    if (!school.hasCoordinates) return;
    setState(() {
      _selectedSchool = school;
    });
    _mapController.move(
      LatLng(school.latitude!, school.longitude!),
      16,
    );
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
      // GeoJSON Polygon: rings[0] = outer, rings[1..] = holes.
      // Our extractRings() flattens both single Polygon and MultiPolygon into
      // a flat list, so we cannot easily group holes back to their outer ring
      // here. We treat rings[0] as outer and rings[1..] as its holes — which
      // is correct for the single-Polygon features emitted by the backend.
      if (e.rings.isEmpty) {
        return _ProvinceBoundaryEntry(
          code: e.code,
          name: e.name,
          polygons: const [],
          centroid: null,
        );
      }

      final outer = e.rings.first
          .map((p) => LatLng(p['lat']!, p['lng']!))
          .toList(growable: false);
      final holePointsList = e.rings
          .skip(1)
          .map(
            (h) => h.map((p) => LatLng(p['lat']!, p['lng']!)).toList(
              growable: false,
            ),
          )
          .toList(growable: false);
      final polygon = Polygon(
        points: outer,
        holePointsList: holePointsList.isEmpty ? null : holePointsList,
        color: const Color(0x0A1565C0),
        borderColor: const Color(0x99607D8B),
        borderStrokeWidth: 1.2,
      );
      final centroid = e.centroid != null
          ? LatLng(e.centroid!['lat']!, e.centroid!['lng']!)
          : null;
      return _ProvinceBoundaryEntry(
        code: e.code,
        name: e.name,
        polygons: [polygon],
        centroid: centroid,
      );
    }).toList();

    // Build the visible-polygons cache once. Subsequent rebuilds reuse it.
    _cachedVisibleBoundaries = _buildVisibleBoundaries();
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
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(ctx).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                    decoration: BoxDecoration(
                      color: Theme.of(ctx).colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.location_on, color: Theme.of(ctx).colorScheme.primary),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Thông tin khu vực',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(ctx).colorScheme.onSurface,
                      ),
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
                        Text(
                          'Đang tải thời tiết...',
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                    error: (_, __) => Text('Không tải được thời tiết',
                        style: TextStyle(color: Theme.of(context).colorScheme.error)),
                    data: (result) => result.when(
                      ok: (snapshot) =>
                          WeatherSummaryRow(weather: snapshot.weather),
                      err: (_) => Text('Không tải được thời tiết',
                          style: TextStyle(color: Theme.of(context).colorScheme.error)),
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
                icon: Icon(Icons.cloud_outlined, color: Theme.of(ctx).colorScheme.primary),
                label: Text('Xem chi tiết thời tiết',
                    style: TextStyle(color: Theme.of(ctx).colorScheme.primary)),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(ctx).colorScheme.primary,
                    foregroundColor: Theme.of(ctx).colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Đóng',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 14),
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

  /// Builds the polygon list used by the province PolygonLayer.
  /// Cached after `_buildBoundaryEntries`; do not call per-frame.
  List<Polygon> _buildVisibleBoundaries() {
    const baseColor = Color(0xFF1565C0);
    const fillOpacity = 0.22;
    const borderOpacity = 0.95;
    const borderStrokeWidth = 2.2;
    final fillColor = baseColor.withValues(alpha: fillOpacity);
    final borderColor = baseColor.withValues(alpha: borderOpacity);

    final allPolygons = <Polygon>[];
    for (final entry in _provinceBoundaryEntries) {
      for (final polygon in entry.polygons) {
        allPolygons.add(
          Polygon(
            points: polygon.points,
            holePointsList: polygon.holePointsList,
            color: fillColor,
            borderColor: borderColor,
            borderStrokeWidth: borderStrokeWidth,
          ),
        );
      }
    }
    return allPolygons;
  }

  /// Builds (or returns cached) commune polygons. Cached by (entries, tapped)
  /// so the PolygonLayer isn't re-allocated on every zoom-induced build.
  List<Polygon> _buildCommunePolygons(
    List<({String code, String name, List<Polygon> polygons})> entries,
    String? tappedCode,
  ) {
    final key = '${identityHashCode(entries)}|$tappedCode';
    if (key == _communePolygonsCacheKey) return _cachedCommunePolygons;
    final polygons = <Polygon>[];
    for (final entry in entries) {
      final tapped = tappedCode == entry.code;
      for (final polygon in entry.polygons) {
        polygons.add(Polygon(
          points: polygon.points,
          holePointsList: polygon.holePointsList,
          color: tapped ? const Color(0x4D4CAF50) : const Color(0x1A4CAF50),
          borderColor:
              tapped ? const Color(0xFF4CAF50) : const Color(0xCC4CAF50),
          borderStrokeWidth: tapped ? 2.5 : 1.8,
        ));
      }
    }
    _communePolygonsCacheKey = key;
    _cachedCommunePolygons = polygons;
    return polygons;
  }

  @override
  Widget build(BuildContext context) {
    _maybeApplyFocusCamera();
    ref.listen(selectedProvinceProvider, (previous, next) {
      if (next != null && (previous == null || previous.code != next.code)) {
        _loadBoundary(next.code);
        ref.read(selectedCommuneProvider.notifier).state = null;
        // Reset loading states
        setState(() {
          _isLoadingCommuneBoundaries = false;
        });
        // Drop cached commune data for the previous province so the next build
        // doesn't show stale polygons/labels while the new ones load.
        _cachedCommuneEntries = const [];
        _cachedCommuneCentroids = const {};
        _lastSeenCommuneEntries = null;
        _lastSeenCommuneCentroids = null;
        _communePolygonsCacheKey = null;
        _cachedCommunePolygons = const [];
      }
    });

    final asyncPolygonEntries = ref.watch(provincePolygonEntriesProvider);

    // Build boundary entries and trigger rebuild when provider resolves.
    asyncPolygonEntries.maybeWhen(
      data: (entries) {
        if (_provinceBoundaryEntries.isEmpty && entries.isNotEmpty) {
          _buildBoundaryEntries(entries);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() {});
          });
        }
        return null;
      },
      orElse: () {},
    );

    final selectedProvince = ref.watch(selectedProvinceProvider);
    final selectedCommune = ref.watch(selectedCommuneProvider);

    // Load commune boundaries when province is selected
    final asyncCommuneBoundaries = selectedProvince != null
        ? ref.watch(communeBoundariesProvider(selectedProvince.code))
        : null;

    // Track loading state for commune boundaries
    final bool isCommuneLoading = asyncCommuneBoundaries?.isLoading ?? false;

    // Update loading state
    if (isCommuneLoading != _isLoadingCommuneBoundaries) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _isLoadingCommuneBoundaries = isCommuneLoading;
          });
        }
      });
    }

    // Cache commune entries and trigger rebuild when async value resolves.
    final communeEntries = _cachedCommuneEntries;
    asyncCommuneBoundaries?.maybeWhen(
      data: (entries) {
        if (!identical(entries, _lastSeenCommuneEntries)) {
          _lastSeenCommuneEntries = entries;
          _cachedCommuneEntries = entries;
          _cachedCommunePolygons = _buildCommunePolygons(entries, selectedCommune?.code);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() {});
          });
        }
        return null;
      },
      orElse: () {},
    );

    // Commune centroids for labels
    final communeCentroidsAsync = selectedProvince != null
        ? ref.watch(communeCentroidsProvider(selectedProvince.code))
        : null;
    final communeCentroids = _cachedCommuneCentroids;
    communeCentroidsAsync?.maybeWhen(
      data: (m) {
        if (!identical(m, _lastSeenCommuneCentroids)) {
          _lastSeenCommuneCentroids = m;
          _cachedCommuneCentroids = m;
        }
        return null;
      },
      orElse: () {},
    );

    // Province + commune labels — rebuilt only when zoom changes (via ValueListenableBuilder).
    List<BoundaryLabel> buildProvinceLabels(double zoom) {
      if (zoom < 7.5) return const [];
      final labels = <BoundaryLabel>[];
      for (final entry in _provinceBoundaryEntries) {
        final centroid = entry.centroid;
        if (centroid != null) {
          labels.add(BoundaryLabel(
            text: entry.name,
            position: centroid,
            maxWidth: 130,
            fontSize: zoom >= 8 ? 12 : 10,
          ));
        }
      }
      return labels;
    }

    List<BoundaryLabel> buildCommuneLabels(
        double zoom,
        List<({String code, String name, List<Polygon> polygons})> entries,
        Map<String, LatLng> centroids) {
      if (zoom < 9) return const [];
      final labels = <BoundaryLabel>[];
      for (final entry in entries) {
        final centroid = centroids[entry.code] ??
            (entry.polygons.isNotEmpty
                ? GeoJsonUtils.computePolygonCentroid(
                    entry.polygons.first.points)
                : null);
        if (centroid != null) {
          labels.add(BoundaryLabel(
            text: entry.name,
            position: centroid,
            maxWidth: 110,
            fontSize: zoom >= 11 ? 10 : 9,
            fontWeight: FontWeight.w400,
            backgroundColor: const Color(0xCC004D40),
          ));
        }
      }
      return labels;
    }

    // Commune polygons — cache by (selectedCommune, entries) tuple.
    // Each province has hundreds of polygons; rebuilding the full list every
    // tap (e.g. zoom change) used to thrash the PolygonLayer.
    final tappedCode = selectedCommune?.code;
    final communePolygons = _buildCommunePolygons(communeEntries, tappedCode);

    return RepaintBoundary(
      child: Stack(
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
                // Performance: debounce zoom updates to reduce rebuild frequency
                _zoomDebounceTimer?.cancel();
                _zoomDebounceTimer = Timer(
                  Duration(milliseconds: _zoomDebounceMs),
                  () {
                    if (position.zoom != _zoomNotifier.value) {
                      _zoomNotifier.value = position.zoom;
                    }
                  },
                );
              // Mark the map as ready once it starts reporting position changes.
              if (!_mapReady) {
                _mapReady = true;
                final completer = _mapReadyCompleter;
                if (completer != null && !completer.isCompleted) {
                  completer.complete();
                }
              }
            },
            onTap: (tapPos, point) {
              _handleMapTap(tapPos, point);
            },
          ),
          children: [
            TileLayer(
              urlTemplate: Theme.of(context).brightness == Brightness.dark
                  ? 'https://{s}.basemaps.cartocdn.com/dark_nolabels/{z}/{x}/{y}.png'
                  : 'https://{s}.basemaps.cartocdn.com/light_nolabels/{z}/{x}/{y}.png',
              tileProvider: CancellableNetworkTileProvider(),
              userAgentPackageName: 'com.example.vietnamese_map',
              maxZoom: 18,
              minZoom: 5,
            ),

            // Province base boundaries — uses cached list, not rebuilt per frame.
            if (_cachedVisibleBoundaries.isNotEmpty)
              PolygonLayer(polygons: _cachedVisibleBoundaries),

            // Commune boundaries
            if (communePolygons.isNotEmpty)
              PolygonLayer(polygons: communePolygons),

            // Selected province highlight
            if (_selectedPolygons.isNotEmpty)
              PolygonLayer(polygons: _selectedPolygons),

            // Province + commune labels — rebuild ONLY when zoom changes.
            ValueListenableBuilder<double>(
              valueListenable: _zoomNotifier,
              builder: (context, zoom, _) {
                final provinceLabels = buildProvinceLabels(zoom);
                final communeLabels = buildCommuneLabels(
                    zoom, communeEntries, communeCentroids);
                return Stack(
                  children: [
                    if (provinceLabels.isNotEmpty)
                      BoundaryLabelLayer(
                          key: const ValueKey('province_labels'),
                          labels: provinceLabels),
                    if (communeLabels.isNotEmpty)
                      BoundaryLabelLayer(
                          key: const ValueKey('commune_labels'),
                          labels: communeLabels),
                  ],
                );
              },
            ),

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
                      Text(
                        'QĐ. Hoàng Sa',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black87,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                          height: 1.1,
                          shadows: [
                            Shadow(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.black54
                                    : Colors.white,
                                blurRadius: 4),
                          ],
                        ),
                      ),
                      Text(
                        '(Đà Nẵng)',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white70
                              : Colors.black54,
                          fontSize: 8,
                          height: 1.1,
                          shadows: [
                            Shadow(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.black54
                                    : Colors.white,
                                blurRadius: 4),
                          ],
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
                      Text(
                        'QĐ. Trường Sa',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black87,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                          height: 1.1,
                          shadows: [
                            Shadow(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.black54
                                    : Colors.white,
                                blurRadius: 4),
                          ],
                        ),
                      ),
                      Text(
                        '(Khánh Hòa)',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white70
                              : Colors.black54,
                          fontSize: 8,
                          height: 1.1,
                          shadows: [
                            Shadow(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.black54
                                    : Colors.white,
                                blurRadius: 4),
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
                              color: Theme.of(context).colorScheme.inverseSurface,
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
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

            // School markers (from on-demand OSM geocoding) with clustering
            if (_schoolGeocodes.isNotEmpty)
              MarkerClusterLayerWidget(
                options: MarkerClusterLayerOptions(
                  maxClusterRadius: 80,
                  size: const Size(50, 50),
                  markers: _schoolGeocodes
                      .where((s) => s.hasCoordinates)
                      .map((school) {
                    final isSelected = _selectedSchool?.schoolUid == school.schoolUid;
                    return Marker(
                      point: LatLng(school.latitude!, school.longitude!),
                      width: isSelected ? 50 : 40,
                      height: isSelected ? 60 : 50,
                      alignment: Alignment.topCenter,
                      child: _SchoolMarkerWidget(
                        marker: school,
                        isSelected: isSelected,
                        onTap: () => _handleGeocodedSchoolTap(school),
                      ),
                    );
                  }).toList(),
                  builder: (context, clusterMarkers) {
                    return Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          '${clusterMarkers.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),

        // School loading indicator
        if (_isLoadingSchools)
          Positioned(
            top: 80,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Đang tải vị trí trường học...',
                      style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // School count badge
        if (_schoolGeocodes.isNotEmpty && !_isLoadingSchools)
          Positioned(
            top: 80,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.inverseSurface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.school, size: 16, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    '${_schoolGeocodes.length} trường',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Boundary loading overlay
        if (_isLoadingBoundary)
          Container(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
            child: const Center(child: CircularProgressIndicator()),
          ),

        // Commune boundaries loading modal
        if (_isLoadingCommuneBoundaries)
          Container(
            color: const Color(0x60000000),
            child: Center(
                child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(strokeWidth: 3),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Đang tải ranh giới xã/phường...',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Vui lòng chờ trong giây lát',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
              const SizedBox(height: 8),
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
                    _schoolGeocodes = [];
                    _selectedSchool = null;
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
    ),
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

class _SchoolMarkerWidget extends StatelessWidget {
  const _SchoolMarkerWidget({
    required this.marker,
    required this.isSelected,
    required this.onTap,
  });

  final SchoolGeocode marker;
  final bool isSelected;
  final VoidCallback onTap;

  Color get _markerColor {
    if (isSelected) return Colors.blue;
    if (marker.isExact) return Colors.green;
    // Fallback coordinates (centroid) are always shown in orange
    return Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Tooltip(
        message: marker.schoolName,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!marker.isExact && !isSelected)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.warning_amber, size: 12, color: Colors.orange.shade700),
                    const SizedBox(width: 2),
                    Text(
                      '~',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            Icon(
              Icons.school,
              color: _markerColor,
              size: isSelected ? 40 : 32,
            ),
          ],
        ),
      ),
    );
  }
}
