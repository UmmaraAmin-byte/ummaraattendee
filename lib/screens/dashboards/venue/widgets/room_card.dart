import 'package:flutter/material.dart';
import '../../../../models/room_model.dart';
import '../../../../models/pricing_model.dart';
import '../../../../models/availability_model.dart';

class RoomCard extends StatelessWidget {
  final RoomModel room;
  final PricingModel? pricing;
  final AvailabilityModel? availability;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onPricing;
  final VoidCallback onAvailability;

  const RoomCard({
    super.key,
    required this.room,
    this.pricing,
    this.availability,
    required this.onEdit,
    required this.onDelete,
    required this.onPricing,
    required this.onAvailability,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(Icons.meeting_room_outlined,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        room.name,
                        style: const TextStyle(
                          color: Color(0xFF1A1A1A),
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _chip(room.type.displayName,
                              Icons.category_outlined),
                          _chip('Cap: ${room.capacity}',
                              Icons.people_outline),
                          if (room.floor.isNotEmpty)
                            _chip('Floor ${room.floor}',
                                Icons.layers_outlined),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'edit') onEdit();
                    if (v == 'delete') onDelete();
                  },
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined,
                                size: 18, color: Color(0xFF3D3D3D)),
                            SizedBox(width: 8),
                            Text('Edit',
                                style:
                                    TextStyle(color: Color(0xFF1A1A1A))),
                          ],
                        )),
                    const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline,
                                size: 18, color: Color(0xFF1A1A1A)),
                            SizedBox(width: 8),
                            Text('Delete',
                                style:
                                    TextStyle(color: Color(0xFF1A1A1A))),
                          ],
                        )),
                  ],
                  icon: const Icon(Icons.more_vert,
                      color: Color(0xFF9B9B9B), size: 20),
                ),
              ],
            ),
            if (room.amenities.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: room.amenities
                    .map((a) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEEEEE),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(a,
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF6B6B6B),
                                  fontWeight: FontWeight.w500)),
                        ))
                    .toList(),
              ),
            ],
            const SizedBox(height: 14),
            const Divider(color: Color(0xFFECECEC), height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _infoTile(
                    icon: Icons.payments_outlined,
                    label: pricing != null && pricing!.hourlyRate > 0
                        ? '\$${pricing!.hourlyRate.toStringAsFixed(0)}/hr'
                        : 'Set Pricing',
                    hasData: pricing != null && pricing!.hourlyRate > 0,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _infoTile(
                    icon: Icons.schedule_outlined,
                    label: availability != null
                        ? '${availability!.workingHourStart}:00–${availability!.workingHourEnd}:00'
                        : 'Set Hours',
                    hasData: availability != null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onPricing,
                    icon: const Icon(Icons.payments_outlined, size: 15),
                    label: const Text('Pricing'),
                    style: _actionStyle(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onAvailability,
                    icon: const Icon(Icons.calendar_today_outlined,
                        size: 15),
                    label: const Text('Availability'),
                    style: _actionStyle(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFEEEEEE),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFF6B6B6B)),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF6B6B6B),
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _infoTile({
    required IconData icon,
    required String label,
    required bool hasData,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: hasData ? const Color(0xFFF8F8F8) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: hasData ? const Color(0xFFE8E8E8) : const Color(0xFFD0D0D0),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 14,
              color: hasData
                  ? const Color(0xFF3D3D3D)
                  : const Color(0xFFB0B0B0)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                  fontSize: 12,
                  color: hasData
                      ? const Color(0xFF3D3D3D)
                      : const Color(0xFFB0B0B0),
                  fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  ButtonStyle _actionStyle() {
    return OutlinedButton.styleFrom(
      foregroundColor: const Color(0xFF1A1A1A),
      side: const BorderSide(color: Color(0xFFD0D0D0)),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      textStyle:
          const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
    );
  }
}
