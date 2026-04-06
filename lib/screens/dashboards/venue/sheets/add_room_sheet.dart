import 'package:flutter/material.dart';
import '../../../../models/room_model.dart';
import '../../../../services/venue_service.dart';

class AddRoomSheet extends StatefulWidget {
  final String buildingId;
  final String ownerId;
  final RoomModel? existing;
  final VoidCallback onSaved;

  const AddRoomSheet({
    super.key,
    required this.buildingId,
    required this.ownerId,
    this.existing,
    required this.onSaved,
  });

  @override
  State<AddRoomSheet> createState() => _AddRoomSheetState();
}

class _AddRoomSheetState extends State<AddRoomSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _capacityCtrl;
  late final TextEditingController _floorCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _amenitiesCtrl;
  RoomType _selectedType = RoomType.other;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final r = widget.existing;
    _nameCtrl = TextEditingController(text: r?.name ?? '');
    _capacityCtrl =
        TextEditingController(text: r != null ? '${r.capacity}' : '');
    _floorCtrl = TextEditingController(text: r?.floor ?? '');
    _descCtrl = TextEditingController(text: r?.description ?? '');
    _amenitiesCtrl =
        TextEditingController(text: r?.amenities.join(', ') ?? '');
    _selectedType = r?.type ?? RoomType.other;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _capacityCtrl.dispose();
    _floorCtrl.dispose();
    _descCtrl.dispose();
    _amenitiesCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final capacity = int.tryParse(_capacityCtrl.text.trim()) ?? 0;
    final amenities = _amenitiesCtrl.text
        .split(',')
        .map((a) => a.trim())
        .where((a) => a.isNotEmpty)
        .toList();
    final svc = VenueService();
    String? err;
    if (widget.existing == null) {
      err = svc.addRoom(
        buildingId: widget.buildingId,
        ownerId: widget.ownerId,
        name: _nameCtrl.text,
        capacity: capacity,
        type: _selectedType,
        floor: _floorCtrl.text,
        description: _descCtrl.text,
        amenities: amenities,
      );
    } else {
      err = svc.updateRoom(
        roomId: widget.existing!.id,
        ownerId: widget.ownerId,
        name: _nameCtrl.text,
        capacity: capacity,
        type: _selectedType,
        floor: _floorCtrl.text,
        description: _descCtrl.text,
        amenities: amenities,
      );
    }
    setState(() => _saving = false);
    if (err != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(err)));
      return;
    }
    Navigator.pop(context);
    widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    isEdit ? 'Edit Room' : 'Add Room',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Color(0xFF6B6B6B)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameCtrl,
                decoration:
                    _deco('Room Name', Icons.meeting_room_outlined),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Room name is required'
                    : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _capacityCtrl,
                      keyboardType: TextInputType.number,
                      decoration: _deco('Capacity', Icons.people_outline),
                      validator: (v) {
                        final n = int.tryParse(v ?? '');
                        if (n == null || n <= 0) {
                          return 'Enter valid capacity';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _floorCtrl,
                      decoration: _deco('Floor', Icons.layers_outlined),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<RoomType>(
                value: _selectedType,
                decoration:
                    _deco('Room Type', Icons.category_outlined),
                items: RoomType.values
                    .map((t) => DropdownMenuItem(
                          value: t,
                          child: Text(t.displayName),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _selectedType = v);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amenitiesCtrl,
                decoration: _deco(
                    'Amenities (comma-separated)',
                    Icons.checklist_rtl_outlined),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                maxLines: 3,
                decoration:
                    _deco('Description (optional)', Icons.notes_outlined),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A1A1A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                    textStyle: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  child: Text(_saving
                      ? 'Saving...'
                      : (isEdit ? 'Update Room' : 'Add Room')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _deco(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF6B6B6B), fontSize: 13),
      prefixIcon: Icon(icon, color: const Color(0xFF3D3D3D), size: 20),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF1A1A1A), width: 1.5),
      ),
      contentPadding:
          const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
    );
  }
}
