import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:latlong2/latlong.dart';

class EventMapPickerResult {
  const EventMapPickerResult({required this.lat, required this.lng});
  final double lat;
  final double lng;
}

class EventMapPickerPage extends StatefulWidget {
  const EventMapPickerPage({super.key, this.initialLat, this.initialLng});

  final double? initialLat;
  final double? initialLng;

  @override
  State<EventMapPickerPage> createState() => _EventMapPickerPageState();
}

class _EventMapPickerPageState extends State<EventMapPickerPage> {
  final MapController _mapController = MapController();
  static const LatLng _vietnamCenter = LatLng(16.0, 106.5);
  static const double _initialZoom = 6.0;
  static const double _focusZoom = 13.0;

  late LatLng _center;
  late double _zoom;

  @override
  void initState() {
    super.initState();
    final lat = widget.initialLat;
    final lng = widget.initialLng;
    if (lat != null && lng != null) {
      _center = LatLng(lat, lng);
      _zoom = _focusZoom;
    } else {
      _center = _vietnamCenter;
      _zoom = _initialZoom;
    }
  }

  void _onPositionChanged(MapCamera position, bool hasGesture) {
    _center = position.center;
    _zoom = position.zoom;
  }

  void _confirm() {
    Navigator.of(context).pop(
      EventMapPickerResult(lat: _center.latitude, lng: _center.longitude),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick location'),
        actions: [
          TextButton(
            onPressed: _confirm,
            child: const Text('Confirm'),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: _zoom,
              minZoom: 5.5,
              maxZoom: 18.0,
              onPositionChanged: _onPositionChanged,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.basemaps.cartocdn.com/light_nolabels/{z}/{x}/{y}.png',
                tileProvider: CancellableNetworkTileProvider(),
                userAgentPackageName: 'com.example.vietnamese_map',
              ),
            ],
          ),
          const IgnorePointer(
            child: Center(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x80000000),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.add,
                  size: 36,
                  color: Colors.red,
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 16,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Drag the map to position the crosshair',
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
