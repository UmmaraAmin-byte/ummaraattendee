import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../models/building_model.dart';

class BuildingCard extends StatelessWidget {
  final BuildingModel building;
  final int roomCount;
  final VoidCallback onViewRooms;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const BuildingCard({
    super.key,
    required this.building,
    required this.roomCount,
    required this.onViewRooms,
    required this.onEdit,
    required this.onDelete,
  });

  Future<void> _openDirections(BuildContext context) async {
    final lat = building.latitude!;
    final lng = building.longitude!;
    final uri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open maps.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.apartment_outlined,
                      color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        building.name,
                        style: const TextStyle(
                          color: Color(0xFF1A1A1A),
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 13, color: Color(0xFF9B9B9B)),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              building.address,
                              style: const TextStyle(
                                  color: Color(0xFF6B6B6B), fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (building.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          building.description,
                          style: const TextStyle(
                              color: Color(0xFF9B9B9B), fontSize: 12),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (building.hasLocation) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.my_location,
                                size: 12,
                                color: Color(0xFF6B6B6B)),
                            const SizedBox(width: 3),
                            Text(
                              '${building.latitude!.toStringAsFixed(4)}, ${building.longitude!.toStringAsFixed(4)}',
                              style: const TextStyle(
                                  color: Color(0xFF6B6B6B),
                                  fontSize: 11),
                            ),
                          ],
                        ),
                      ],
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
                        child: Row(children: [
                          Icon(Icons.edit_outlined,
                              size: 18, color: Color(0xFF3D3D3D)),
                          SizedBox(width: 8),
                          Text('Edit',
                              style: TextStyle(color: Color(0xFF1A1A1A))),
                        ])),
                    const PopupMenuItem(
                        value: 'delete',
                        child: Row(children: [
                          Icon(Icons.delete_outline,
                              size: 18, color: Color(0xFF1A1A1A)),
                          SizedBox(width: 8),
                          Text('Delete',
                              style: TextStyle(color: Color(0xFF1A1A1A))),
                        ])),
                  ],
                  icon: const Icon(Icons.more_vert,
                      color: Color(0xFF9B9B9B), size: 20),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                _badge(Icons.meeting_room_outlined,
                    '$roomCount room${roomCount != 1 ? 's' : ''}'),
                if (building.hasLocation) ...[
                  const SizedBox(width: 6),
                  _badge(Icons.location_on_outlined, 'Located'),
                ],
                const Spacer(),
                if (building.hasLocation)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: OutlinedButton.icon(
                      onPressed: () => _openDirections(context),
                      icon: const Icon(Icons.directions_outlined,
                          size: 14),
                      label: const Text('Directions'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF3D3D3D),
                        side: const BorderSide(
                            color: Color(0xFFD0D0D0), width: 1),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        textStyle: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                ElevatedButton.icon(
                  onPressed: onViewRooms,
                  icon: const Icon(Icons.chevron_right, size: 16),
                  label: const Text('View Rooms'),
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFEEEEEE),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 13, color: const Color(0xFF6B6B6B)),
          const SizedBox(width: 5),
          Text(text,
              style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B6B6B),
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
