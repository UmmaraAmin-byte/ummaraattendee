import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../services/map_service.dart' as ms;

class LocationPickerResult {
  final double latitude;
  final double longitude;
  final String? address;

  LocationPickerResult({
    required this.latitude,
    required this.longitude,
    this.address,
  });
}

class LocationPicker extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;

  const LocationPicker({
    super.key,
    this.initialLat,
    this.initialLng,
  });

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  late final MapController _mapController;
  LatLng? _selected;
  String? _address;
  bool _loadingAddress = false;

  static const LatLng _defaultCenter = LatLng(40.7128, -74.0060);

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    if (widget.initialLat != null && widget.initialLng != null) {
      _selected = LatLng(widget.initialLat!, widget.initialLng!);
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _onTap(TapPosition _, LatLng point) async {
    setState(() {
      _selected = point;
      _address = null;
      _loadingAddress = true;
    });
    final addr = await ms.MapService()
        .reverseGeocode(point.latitude, point.longitude);
    if (mounted) {
      setState(() {
        _address = addr;
        _loadingAddress = false;
      });
    }
  }

  void _confirm() {
    if (_selected == null) return;
    Navigator.pop(
      context,
      LocationPickerResult(
        latitude: _selected!.latitude,
        longitude: _selected!.longitude,
        address: _address,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final center = _selected ??
        (_defaultCenter);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Color(0xFF1A1A1A)),
        title: const Text(
          'Pick Location',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        actions: [
          if (_selected != null)
            TextButton(
              onPressed: _confirm,
              child: const Text(
                'Confirm',
                style: TextStyle(
                  color: Color(0xFF1A1A1A),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: center,
              initialZoom: _selected != null ? 14 : 12,
              onTap: _onTap,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.eventflow.app',
              ),
              if (_selected != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selected!,
                      width: 48,
                      height: 48,
                      child: const Icon(
                        Icons.location_pin,
                        color: Color(0xFF1A1A1A),
                        size: 42,
                        shadows: [
                          Shadow(
                            blurRadius: 6,
                            color: Color(0x44000000),
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      size: 16, color: Color(0xFF6B6B6B)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _selected == null
                          ? 'Tap on the map to place a marker'
                          : _loadingAddress
                              ? 'Fetching address...'
                              : (_address ?? 'Location selected — tap Confirm'),
                      style: const TextStyle(
                          color: Color(0xFF6B6B6B), fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_selected != null)
            Positioned(
              bottom: 24,
              left: 24,
              right: 24,
              child: ElevatedButton.icon(
                onPressed: _confirm,
                icon: const Icon(Icons.check_circle_outline),
                label: Text(_address != null
                    ? 'Use this location'
                    : 'Confirm location'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A1A1A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
