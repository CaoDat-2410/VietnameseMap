import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../map/presentation/providers/map_provider.dart';
import '../../shared/models/campaign_models.dart';
import '../../shared/providers/campaign_provider.dart';
import '../pages/event_map_picker_page.dart';

class EventFormDialog extends ConsumerStatefulWidget {
  const EventFormDialog({
    super.key,
    this.event,
    required this.onSubmit,
  });

  final CampaignEventModel? event;
  final Future<void> Function(Map<String, dynamic> data) onSubmit;

  @override
  ConsumerState<EventFormDialog> createState() => _EventFormDialogState();
}

class _EventFormDialogState extends ConsumerState<EventFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _startsAtController;
  late final TextEditingController _endsAtController;
  late final TextEditingController _noteController;
  late final TextEditingController _locationLabelController;
  String _eventType = 'SCHOOL_VISIT';
  String _status = 'PLANNED';
  String? _selectedSchoolUid;
  double? _lat;
  double? _lng;
  bool _autoFilledFromSchool = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final event = widget.event;
    _nameController = TextEditingController(text: event?.name ?? '');
    _startsAtController = TextEditingController(text: event?.startsAt ?? '');
    _endsAtController = TextEditingController(text: event?.endsAt ?? '');
    _noteController = TextEditingController(text: event?.note ?? '');
    _locationLabelController =
        TextEditingController(text: event?.locationLabel ?? '');
    _eventType =
        event?.eventType.isNotEmpty == true ? event!.eventType : 'SCHOOL_VISIT';
    _status = event?.status.isNotEmpty == true ? event!.status : 'PLANNED';
    _selectedSchoolUid =
        event?.schoolUid.isNotEmpty == true ? event!.schoolUid : null;
    _lat = event?.latitude;
    _lng = event?.longitude;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _startsAtController.dispose();
    _endsAtController.dispose();
    _noteController.dispose();
    _locationLabelController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await widget.onSubmit({
        'name': _nameController.text.trim(),
        'eventType': _eventType,
        'status': _status,
        'startsAt': _emptyToNull(_startsAtController.text),
        'endsAt': _emptyToNull(_endsAtController.text),
        'note': _noteController.text.trim(),
        'locationLabel': _emptyToNull(_locationLabelController.text),
        'latitude': _lat,
        'longitude': _lng,
        'schoolUid': _emptyToNull(_selectedSchoolUid),
        'provinceCode': _selectedSchoolUid == null
            ? null
            : _provinceCodeForSchool(_selectedSchoolUid!),
      });
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _provinceCodeForSchool(String schoolUid) {
    final schools = ref.read(eventSchoolsProvider(widget.event?.id ?? 0));
    return schools.valueOrNull
        ?.where((s) => s.schoolUid == schoolUid)
        .map((s) => s.provinceCode)
        .firstOrNull;
  }

  Future<void> _openPicker() async {
    final result = await Navigator.of(context).push<EventMapPickerResult>(
      MaterialPageRoute(
        builder: (_) => EventMapPickerPage(
          initialLat: _lat,
          initialLng: _lng,
        ),
      ),
    );
    if (result != null) {
      setState(() {
        _lat = result.lat;
        _lng = result.lng;
        _autoFilledFromSchool = false;
      });
    }
  }

  void _onSchoolChanged(String? schoolUid) {
    setState(() {
      _selectedSchoolUid = schoolUid;
      _autoFilledFromSchool = schoolUid != null;
    });
    if (schoolUid == null) return;
    final schools = ref.read(eventSchoolsProvider(widget.event?.id ?? 0));
    final selected = schools.valueOrNull
        ?.where((s) => s.schoolUid == schoolUid)
        .firstOrNull;
    if (selected == null) return;
    final centroidsAsync = ref.read(provinceCentroidsProvider);
    final centroids = centroidsAsync.valueOrNull;
    final centroid = centroids?[selected.provinceCode];
    if (centroid != null) {
      setState(() {
        _lat = centroid.latitude;
        _lng = centroid.longitude;
      });
    }
    final currentLabel = _locationLabelController.text.trim();
    if (currentLabel.isEmpty) {
      _locationLabelController.text =
          '${selected.schoolName}, ${selected.provinceName}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventId = widget.event?.id ?? 0;
    final schoolsAsync = ref.watch(eventSchoolsProvider(eventId));
    final centroidsAsync = ref.watch(provinceCentroidsProvider);
    final hasLocation = _lat != null && _lng != null;

    return AlertDialog(
      title: Text(widget.event == null ? 'Create Event' : 'Edit Event'),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _eventType,
                  decoration: const InputDecoration(labelText: 'Event type'),
                  items: const [
                    DropdownMenuItem(
                      value: 'SCHOOL_VISIT',
                      child: Text('SCHOOL_VISIT'),
                    ),
                    DropdownMenuItem(
                      value: 'ONLINE_WORKSHOP',
                      child: Text('ONLINE_WORKSHOP'),
                    ),
                    DropdownMenuItem(value: 'SURVEY', child: Text('SURVEY')),
                    DropdownMenuItem(value: 'MEETING', child: Text('MEETING')),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _eventType = value);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: const [
                    DropdownMenuItem(value: 'PLANNED', child: Text('PLANNED')),
                    DropdownMenuItem(
                      value: 'IN_PROGRESS',
                      child: Text('IN_PROGRESS'),
                    ),
                    DropdownMenuItem(value: 'DONE', child: Text('DONE')),
                    DropdownMenuItem(
                      value: 'CANCELLED',
                      child: Text('CANCELLED'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _status = value);
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _startsAtController,
                  decoration: const InputDecoration(
                    labelText: 'Starts at',
                    hintText: '2026-06-20T08:00:00',
                  ),
                  validator: _datetime,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _endsAtController,
                  decoration: const InputDecoration(
                    labelText: 'Ends at',
                    hintText: '2026-06-20T11:00:00',
                  ),
                  validator: (value) {
                    final formatError = _datetime(value);
                    if (formatError != null) return formatError;
                    final startsAt =
                        DateTime.tryParse(_startsAtController.text);
                    final endsAt = DateTime.tryParse(value ?? '');
                    if (startsAt != null &&
                        endsAt != null &&
                        endsAt.isBefore(startsAt)) {
                      return 'Ends at must be after starts at';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _noteController,
                  decoration: const InputDecoration(labelText: 'Note'),
                  maxLines: 3,
                ),
                const SizedBox(height: 20),
                const _SectionHeader('Location'),
                const SizedBox(height: 8),
                schoolsAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text(
                    'Could not load schools: $e',
                    style: const TextStyle(color: Colors.red),
                  ),
                  data: (schools) {
                    if (schools.isEmpty) {
                      return const Text(
                        'No schools assigned yet. Assign schools in the Schools tab to enable auto-location, or drop a pin manually below.',
                        style: TextStyle(color: Colors.black54),
                      );
                    }
                    return DropdownButtonFormField<String>(
                      initialValue: _selectedSchoolUid,
                      decoration: const InputDecoration(labelText: 'School'),
                      items: [
                        for (final s in schools)
                          DropdownMenuItem(
                            value: s.schoolUid,
                            child: Text('${s.schoolName} (${s.provinceName})'),
                          ),
                      ],
                      onChanged: _onSchoolChanged,
                    );
                  },
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _locationLabelController,
                  decoration: const InputDecoration(labelText: 'Address label'),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 200,
                  child: _EventLocationPreview(
                    lat: _lat,
                    lng: _lng,
                    onChanged: (lat, lng) {
                      setState(() {
                        _lat = lat;
                        _lng = lng;
                        _autoFilledFromSchool = false;
                      });
                    },
                  ),
                ),
                if (_autoFilledFromSchool) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.warning_amber_rounded,
                            color: Colors.deepOrange, size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Using province center as approximate location - drag the pin to refine.',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        hasLocation
                            ? 'Lat ${_lat!.toStringAsFixed(4)}, Lng ${_lng!.toStringAsFixed(4)}'
                            : 'No location selected',
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: _openPicker,
                      icon: const Icon(Icons.map_outlined),
                      label: const Text('Pick on map'),
                    ),
                  ],
                ),
                if (centroidsAsync.isLoading)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: LinearProgressIndicator(),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }

  String? _required(String? value) {
    return value == null || value.trim().isEmpty ? 'Required' : null;
  }

  String? _datetime(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    if (DateTime.tryParse(text) == null) {
      return 'Use yyyy-MM-ddTHH:mm:ss';
    }
    return null;
  }

  String? _emptyToNull(String? value) {
    final text = (value ?? '').trim();
    return text.isEmpty ? null : text;
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.black54,
        ),
      ),
    );
  }
}

class _EventLocationPreview extends StatefulWidget {
  const _EventLocationPreview({required this.lat, required this.lng, this.onChanged});

  final double? lat;
  final double? lng;
  final void Function(double lat, double lng)? onChanged;

  @override
  State<_EventLocationPreview> createState() => _EventLocationPreviewState();
}

class _EventLocationPreviewState extends State<_EventLocationPreview> {
  final MapController _mapController = MapController();
  LatLng? _marker;

  @override
  void initState() {
    super.initState();
    _marker = _effectiveLatLng();
  }

  @override
  void didUpdateWidget(covariant _EventLocationPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = _effectiveLatLng();
    if (_marker != next) {
      setState(() => _marker = next);
    }
  }

  LatLng? _effectiveLatLng() {
    final lat = widget.lat;
    final lng = widget.lng;
    if (lat == null || lng == null) return null;
    return LatLng(lat, lng);
  }

  void _onDrag(double deltaLat, double deltaLng) {
    final marker = _marker;
    if (marker == null) return;
    final zoom = _mapController.camera.zoom;
    final metersPerPixel = 156543.03 *
        math.cos(marker.latitude * math.pi / 180.0) /
        math.pow(2, zoom.clamp(0.0, 20.0));
    final dLat = -deltaLat * metersPerPixel / 111320.0;
    final dLng = deltaLng *
        metersPerPixel /
        (111320.0 * math.cos(marker.latitude * math.pi / 180.0));
    final next = LatLng(
      (marker.latitude + dLat).clamp(-90.0, 90.0),
      (marker.longitude + dLng).clamp(-180.0, 180.0),
    );
    setState(() => _marker = next);
    widget.onChanged?.call(next.latitude, next.longitude);
  }

  @override
  Widget build(BuildContext context) {
    final marker = _marker;
    if (marker == null) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: const Text('No location yet'),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Listener(
        onPointerMove: (event) {
          _onDrag(event.delta.dy, event.delta.dx);
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanUpdate: (details) {
            _onDrag(details.delta.dy, details.delta.dx);
          },
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: marker,
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
                    point: _marker!,
                    width: 40,
                    height: 40,
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.red,
                      size: 36,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
