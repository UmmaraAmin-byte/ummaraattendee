import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../services/auth_service.dart';
import '../../../services/venue_service.dart';
import '../../../models/building_model.dart';

const _categoryColors = <String, Color>{
  'Technology':     Color(0xFF1565C0),
  'Business':       Color(0xFF2E7D32),
  'Arts & Culture': Color(0xFF6A1B9A),
  'Education':      Color(0xFFE65100),
  'Workshop':       Color(0xFF00695C),
  'Seminar':        Color(0xFF4527A0),
  'Conference':     Color(0xFF283593),
  'Networking':     Color(0xFF37474F),
  'Health':         Color(0xFFC62828),
  'Finance':        Color(0xFF558B2F),
};

Color _catColor(String c) => _categoryColors[c] ?? const Color(0xFF2D2D2D);

class AttendeeMapTab extends StatefulWidget {
  final Set<String> registeredIds;
  final void Function(Map<String, dynamic>) onToggleRegistration;
  final void Function(Map<String, dynamic>) onEventTap;
  final String Function(Map<String, dynamic>) locationLabel;
  final String Function(Map<String, dynamic>) organizerName;

  const AttendeeMapTab({
    super.key,
    required this.registeredIds,
    required this.onToggleRegistration,
    required this.onEventTap,
    required this.locationLabel,
    required this.organizerName,
  });

  @override
  State<AttendeeMapTab> createState() => _AttendeeMapTabState();
}

class _AttendeeMapTabState extends State<AttendeeMapTab> {
  final _auth = AuthService();
  final _venue = VenueService();
  late final MapController _mapCtrl;
  BuildingModel? _activeBuilding;

  @override
  void initState() {
    super.initState();
    _mapCtrl = MapController();
  }

  @override
  void dispose() {
    _mapCtrl.dispose();
    super.dispose();
  }

  List<BuildingModel> get _mapped =>
      _venue.allBuildings.where((b) => b.hasLocation).toList();

  LatLng get _center {
    final m = _mapped;
    if (m.isEmpty) return const LatLng(51.5074, -0.1278);
    final lat = m.map((b) => b.latitude!).reduce((a, b) => a + b) / m.length;
    final lng = m.map((b) => b.longitude!).reduce((a, b) => a + b) / m.length;
    return LatLng(lat, lng);
  }

  List<Map<String, dynamic>> _eventsAtBuilding(BuildingModel building) {
    final roomIds = _venue.roomsForBuilding(building.id)
        .map((r) => r.id)
        .toSet();
    final bookingIds = _auth.allBookings
        .where((bk) => roomIds.contains(bk['roomId']))
        .map((bk) => bk['id'] as String)
        .toSet();
    return _auth.allEvents
        .where((e) =>
            e['status'] == 'published' &&
            bookingIds.contains(e['bookingId']))
        .toList()
      ..sort((a, b) {
        final sa = a['start'] as DateTime?;
        final sb = b['start'] as DateTime?;
        if (sa == null && sb == null) return 0;
        if (sa == null) return 1;
        if (sb == null) return -1;
        return sa.compareTo(sb);
      });
  }

  bool _hasRegisteredEvent(BuildingModel b) {
    final events = _eventsAtBuilding(b);
    return events.any((e) => widget.registeredIds.contains(e['id']));
  }

  Future<void> _openDirections(BuildingModel b) async {
    final url =
        'https://www.google.com/maps/dir/?api=1&destination=${b.latitude},${b.longitude}';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _fmtTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _fmtDate(DateTime dt) {
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${dt.day} ${months[dt.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final buildings = _venue.allBuildings;
    final mapped = _mapped;

    if (buildings.isEmpty) {
      return _emptyState('No venues available yet.');
    }
    if (mapped.isEmpty) {
      return _emptyState('No venue locations set yet.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Legend
        _legend(),
        const SizedBox(height: 12),

        // Map
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 340,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapCtrl,
                  options: MapOptions(
                    initialCenter: _center,
                    initialZoom: 12,
                    onTap: (_, __) =>
                        setState(() => _activeBuilding = null),
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
                        final hasReg = _hasRegisteredEvent(b);
                        final events = _eventsAtBuilding(b);

                        return Marker(
                          point: LatLng(b.latitude!, b.longitude!),
                          width: isActive ? 60 : 48,
                          height: isActive ? 60 : 48,
                          child: GestureDetector(
                            onTap: () {
                              setState(() => _activeBuilding = b);
                              _mapCtrl.move(
                                  LatLng(b.latitude!, b.longitude!), 15);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    width: isActive ? 40 : 32,
                                    height: isActive ? 40 : 32,
                                    decoration: BoxDecoration(
                                      color: hasReg
                                          ? const Color(0xFF1A1A1A)
                                          : Colors.white,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xFF1A1A1A),
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withAlpha(40),
                                          blurRadius: 6,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.location_city_outlined,
                                      size: isActive ? 20 : 15,
                                      color: hasReg
                                          ? Colors.white
                                          : const Color(0xFF1A1A1A),
                                    ),
                                  ),
                                  if (events.isNotEmpty)
                                    Positioned(
                                      top: 0,
                                      right: 0,
                                      child: Container(
                                        width: 16,
                                        height: 16,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF2D2D2D),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text(
                                            '${events.length}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 9,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
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

                // Active building popup
                if (_activeBuilding != null)
                  Positioned(
                    bottom: 12,
                    left: 12,
                    right: 12,
                    child: _buildingPopup(_activeBuilding!),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Venue list
        const Text(
          'All Venues',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 10),
        ...mapped.map((b) => _venueListTile(b)),
      ],
    );
  }

  Widget _legend() {
    return Row(
      children: [
        _legendDot(const Color(0xFF1A1A1A), 'Has registered event'),
        const SizedBox(width: 16),
        _legendDot(Colors.white, 'No registered events',
            border: const Color(0xFF1A1A1A)),
      ],
    );
  }

  Widget _legendDot(Color fill, String label, {Color? border}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: fill,
            shape: BoxShape.circle,
            border: border != null ? Border.all(color: border, width: 1.5) : null,
          ),
        ),
        const SizedBox(width: 5),
        Text(label,
            style: const TextStyle(color: Color(0xFF6B6B6B), fontSize: 11)),
      ],
    );
  }

  Widget _buildingPopup(BuildingModel b) {
    final events = _eventsAtBuilding(b);
    return Container(
      constraints: const BoxConstraints(maxHeight: 260),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withAlpha(30),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: [
                const Icon(Icons.location_city_outlined,
                    size: 18, color: Color(0xFF1A1A1A)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        b.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      Text(
                        b.address,
                        style: const TextStyle(
                            color: Color(0xFF6B6B6B), fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => _openDirections(b),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.directions_outlined,
                                size: 13, color: Colors.white),
                            SizedBox(width: 3),
                            Text('Directions',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () =>
                          setState(() => _activeBuilding = null),
                      child: const Icon(Icons.close,
                          size: 18, color: Color(0xFF9E9E9E)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          if (events.isEmpty)
            const Padding(
              padding: EdgeInsets.all(14),
              child: Text(
                'No events at this venue.',
                style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 12),
              ),
            )
          else
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${events.length} event${events.length != 1 ? 's' : ''} here',
                      style: const TextStyle(
                          color: Color(0xFF6B6B6B),
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    ...events.map((e) => _popupEventRow(e)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _popupEventRow(Map<String, dynamic> e) {
    final registered = widget.registeredIds.contains(e['id']);
    final cat = (e['category'] as String? ?? '');
    final start = e['start'] as DateTime?;
    final end = e['end'] as DateTime?;

    return GestureDetector(
      onTap: () {
        setState(() => _activeBuilding = null);
        widget.onEventTap(e);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: registered ? const Color(0xFFF5F5F5) : const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: registered
                ? const Color(0xFF1A1A1A)
                : const Color(0xFFE8E8E8),
            width: registered ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 3,
              height: 36,
              decoration: BoxDecoration(
                color: _catColor(cat),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    e['title'] as String? ?? '',
                    style: const TextStyle(
                      color: Color(0xFF1A1A1A),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (start != null)
                    Text(
                      '${_fmtDate(start)}  ${_fmtTime(start)}'
                      '${end != null ? ' – ${_fmtTime(end)}' : ''}',
                      style: const TextStyle(
                          color: Color(0xFF6B6B6B), fontSize: 11),
                    ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => widget.onToggleRegistration(e),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: registered
                      ? const Color(0xFF1A1A1A)
                      : const Color(0xFFEEEEEE),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  registered ? '✓' : '+',
                  style: TextStyle(
                    color: registered ? Colors.white : const Color(0xFF1A1A1A),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _venueListTile(BuildingModel b) {
    final events = _eventsAtBuilding(b);
    final hasReg = _hasRegisteredEvent(b);

    return GestureDetector(
      onTap: () {
        setState(() => _activeBuilding = b);
        _mapCtrl.move(LatLng(b.latitude!, b.longitude!), 15);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasReg ? const Color(0xFF1A1A1A) : const Color(0xFFE8E8E8),
            width: hasReg ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: hasReg
                    ? const Color(0xFF1A1A1A)
                    : const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.location_city_outlined,
                size: 18,
                color: hasReg ? Colors.white : const Color(0xFF2D2D2D),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    b.name,
                    style: const TextStyle(
                      color: Color(0xFF1A1A1A),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    b.address,
                    style: const TextStyle(
                        color: Color(0xFF6B6B6B), fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${events.length} event${events.length != 1 ? 's' : ''}',
                  style: const TextStyle(
                      color: Color(0xFF9E9E9E), fontSize: 11),
                ),
                if (hasReg)
                  const Text(
                    'Registered',
                    style: TextStyle(
                      color: Color(0xFF1A1A1A),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, color: Color(0xFFCCCCCC), size: 18),
          ],
        ),
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
            const Icon(Icons.map_outlined, size: 42, color: Color(0xFFD0D0D0)),
            const SizedBox(height: 10),
            Text(
              msg,
              style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
