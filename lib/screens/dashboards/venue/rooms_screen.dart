import 'package:flutter/material.dart';
import '../../../models/building_model.dart';
import '../../../models/room_model.dart';
import '../../../services/venue_service.dart';
import 'widgets/room_card.dart';
import 'sheets/add_room_sheet.dart';
import 'sheets/pricing_sheet.dart';
import 'sheets/availability_sheet.dart';

class RoomsScreen extends StatefulWidget {
  final BuildingModel building;
  final String ownerId;

  const RoomsScreen({
    super.key,
    required this.building,
    required this.ownerId,
  });

  @override
  State<RoomsScreen> createState() => _RoomsScreenState();
}

class _RoomsScreenState extends State<RoomsScreen> {
  final _svc = VenueService();

  void _refresh() => setState(() {});

  void _showAddRoom({RoomModel? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AddRoomSheet(
        buildingId: widget.building.id,
        ownerId: widget.ownerId,
        existing: existing,
        onSaved: _refresh,
      ),
    );
  }

  void _showPricing(RoomModel room) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => PricingSheet(
        roomId: room.id,
        roomName: room.name,
        onSaved: _refresh,
      ),
    );
  }

  void _showAvailability(RoomModel room) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AvailabilitySheet(
        roomId: room.id,
        roomName: room.name,
        onSaved: _refresh,
      ),
    );
  }

  void _deleteRoom(RoomModel room) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Room',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Delete "${room.name}"? This action cannot be undone.',
          style: const TextStyle(color: Color(0xFF6B6B6B), fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF6B6B6B)),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A1A1A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            onPressed: () {
              final err = _svc.deleteRoom(room.id, widget.ownerId);
              Navigator.pop(context);
              if (err != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(err)));
                return;
              }
              _refresh();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rooms =
        _svc.roomsForBuilding(widget.building.id);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: const BackButton(color: Color(0xFF1A1A1A)),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.building.name,
              style: const TextStyle(
                color: Color(0xFF1A1A1A),
                fontWeight: FontWeight.w700,
                fontSize: 16,
                letterSpacing: -0.2,
              ),
            ),
            Text(
              widget.building.address,
              style: const TextStyle(
                  color: Color(0xFF6B6B6B), fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE8E8E8)),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              onPressed: () => _showAddRoom(),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Room'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A1A1A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                textStyle: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
      body: rooms.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEEEEE),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.meeting_room_outlined,
                          size: 36, color: Color(0xFF9B9B9B)),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No rooms yet',
                      style: TextStyle(
                          color: Color(0xFF1A1A1A),
                          fontSize: 16,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Add your first room to get started.',
                      style: TextStyle(
                          color: Color(0xFF9B9B9B), fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => _showAddRoom(),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add Room'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A1A1A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: rooms.length,
              itemBuilder: (_, i) {
                final r = rooms[i];
                return RoomCard(
                  room: r,
                  pricing: _svc.pricingForRoom(r.id),
                  availability: _svc.availabilityForRoom(r.id),
                  onEdit: () => _showAddRoom(existing: r),
                  onDelete: () => _deleteRoom(r),
                  onPricing: () => _showPricing(r),
                  onAvailability: () => _showAvailability(r),
                );
              },
            ),
    );
  }
}
