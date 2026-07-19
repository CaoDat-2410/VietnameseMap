import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:latlong2/latlong.dart';

class EventMapPreview extends StatelessWidget {
  const EventMapPreview({
    super.key,
    required this.lat,
    required this.lng,
    this.label,
    this.height = 220,
  });

  final double lat;
  final double lng;
  final String? label;
  final double height;

  @override
  Widget build(BuildContext context) {
    final tooltip = label ?? '';
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: height,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: LatLng(lat, lng),
            initialZoom: 13,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.none,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate:
                  'https://{s}.basemaps.cartocdn.com/light_nolabels/{z}/{x}/{y}.png',
              tileProvider: CancellableNetworkTileProvider(),
              userAgentPackageName: 'com.example.vietnamese_map',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: LatLng(lat, lng),
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  child: Tooltip(
                    message: tooltip,
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.red,
                      size: 36,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
