import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../models/building_model.dart';
import '../../../../services/venue_service.dart';
import '../../../../services/map_service.dart';

class BuildingsMapView extends StatefulWidget {
  final List<BuildingModel> buildings;
  final VenueService venueService;
  final void Function(BuildingModel) onBuildingTap;

  const BuildingsMapView({
    super.key,
    required this.buildings,
    required this.venueService,
    required this.onBuildingTap,
  });

  @override
  State<BuildingsMapView> createState() => _BuildingsMapViewState();
}

class _BuildingsMapViewState extends State<BuildingsMapView> {
  late final MapController _mapController;
  BuildingModel? _activeBuilding;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  List<BuildingModel> get _mappedBuildings =>
      widget.buildings.where((b) => b.hasLocation).toList();

  LatLng get _center {
    final mapped = _mappedBuildings;
    if (mapped.isEmpty) return const LatLng(40.7128, -74.0060);
    final avgLat = mapped.map((b) => b.latitude!).reduce((a, b) => a + b) /
        mapped.length;
    final avgLng = mapped.map((b) => b.longitude!).reduce((a, b) => a + b) /
        mapped.length;
    return LatLng(avgLat, avgLng);
  }

  Future<void> _openDirections(BuildingModel b) async {
    final url =
        MapService().directionsUrl(b.latitude!, b.longitude!, b.name);
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mapped = _mappedBuildings;

    if (widget.buildings.isEmpty) {
      return _emptyState('No buildings added yet.');
    }
    if (mapped.isEmpty) {
      return _emptyState(
          'No locations set yet.\nEdit a building and tap "Pick Location".');
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 13,
              onTap: (_, __) {
                if (_activeBuilding != null) {
                  setState(() => _activeBuilding = null);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.eventflow.app',
              ),
              MarkerLayer(
                markers: mapped.map((b) {
                  final isActive = _activeBuilding?.id == b.id;
                  return Marker(
                    point: LatLng(b.latitude!, b.longitude!),
                    width: isActive ? 54 : 44,
                    height: isActive ? 54 : 44,
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _activeBuilding = b);
                        _mapController.move(
                            LatLng(b.latitude!, b.longitude!), 15);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: isActive ? 34 : 28,
                              height: isActive ? 34 : 28,
                              decoration: BoxDecoration(
                                color: isActive
                                    ? const Color(0xFF1A1A1A)
                                    : Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF1A1A1A),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(50),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.apartment_outlined,
                                size: isActive ? 18 : 14,
                                color: isActive
                                    ? Colors.white
                                    : const Color(0xFF1A1A1A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          if (_activeBuilding != null)
            Positioned(
              bottom: 12,
              left: 12,
              right: 12,
              child: _buildingPopup(_activeBuilding!),
            ),
        ],
      ),
    );
  }

  Widget _buildingPopup(BuildingModel b) {
    final rooms = widget.venueService.roomsForBuilding(b.id);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(30),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.apartment_outlined,
                  size: 18, color: Color(0xFF1A1A1A)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  b.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _activeBuilding = null),
                child: const Icon(Icons.close,
                    size: 18, color: Color(0xFF6B6B6B)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  size: 13, color: Color(0xFF6B6B6B)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  b.address,
                  style: const TextStyle(
                      color: Color(0xFF6B6B6B), fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _chip(Icons.meeting_room_outlined,
                  '${rooms.length} room${rooms.length != 1 ? 's' : ''}'),
              _chip(
                Icons.my_location,
                '${b.latitude!.toStringAsFixed(4)}, ${b.longitude!.toStringAsFixed(4)}',
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => widget.onBuildingTap(b),
                  icon: const Icon(Icons.chevron_right, size: 16),
                  label: const Text('View Rooms'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1A1A1A),
                    side: const BorderSide(color: Color(0xFFE8E8E8)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _openDirections(b),
                  icon: const Icon(Icons.directions_outlined, size: 16),
                  label: const Text('Directions'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A1A1A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFF6B6B6B)),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: Color(0xFF6B6B6B))),
        ],
      ),
    );
  }

  Widget _emptyState(String msg) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6F6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.map_outlined,
                size: 42, color: Color(0xFFD0D0D0)),
            const SizedBox(height: 10),
            Text(
              msg,
              style: const TextStyle(
                  color: Color(0xFF9B9B9B), fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
