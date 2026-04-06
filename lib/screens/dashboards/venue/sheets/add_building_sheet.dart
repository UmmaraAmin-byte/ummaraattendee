import 'package:flutter/material.dart';
import '../../../../models/building_model.dart';
import '../../../../services/venue_service.dart';
import '../widgets/location_picker.dart';

class AddBuildingSheet extends StatefulWidget {
  final String ownerId;
  final BuildingModel? existing;
  final VoidCallback onSaved;

  const AddBuildingSheet({
    super.key,
    required this.ownerId,
    this.existing,
    required this.onSaved,
  });

  @override
  State<AddBuildingSheet> createState() => _AddBuildingSheetState();
}

class _AddBuildingSheetState extends State<AddBuildingSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _termsCtrl;
  bool _saving = false;
  double? _latitude;
  double? _longitude;
  bool _locationCleared = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.existing?.name ?? '');
    _addressCtrl =
        TextEditingController(text: widget.existing?.address ?? '');
    _descCtrl =
        TextEditingController(text: widget.existing?.description ?? '');
    _termsCtrl = TextEditingController(
        text: widget.existing?.termsAndConditions ?? '');
    _latitude = widget.existing?.latitude;
    _longitude = widget.existing?.longitude;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _descCtrl.dispose();
    _termsCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickLocation() async {
    final result = await Navigator.push<LocationPickerResult>(
      context,
      MaterialPageRoute(
        builder: (_) => LocationPicker(
          initialLat: _latitude,
          initialLng: _longitude,
        ),
      ),
    );
    if (result != null && mounted) {
      setState(() {
        _latitude = result.latitude;
        _longitude = result.longitude;
        _locationCleared = false;
        if (result.address != null &&
            _addressCtrl.text.trim().isEmpty) {
          _addressCtrl.text = result.address!;
        }
      });
    }
  }

  void _clearLocation() {
    setState(() {
      _latitude = null;
      _longitude = null;
      _locationCleared = true;
    });
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final svc = VenueService();
    String? err;
    if (widget.existing == null) {
      err = svc.addBuilding(
        ownerId: widget.ownerId,
        name: _nameCtrl.text,
        address: _addressCtrl.text,
        description: _descCtrl.text,
        latitude: _latitude,
        longitude: _longitude,
        termsAndConditions: _termsCtrl.text,
      );
    } else {
      err = svc.updateBuilding(
        buildingId: widget.existing!.id,
        ownerId: widget.ownerId,
        name: _nameCtrl.text,
        address: _addressCtrl.text,
        description: _descCtrl.text,
        latitude: _latitude,
        longitude: _longitude,
        clearLocation: _locationCleared,
        termsAndConditions: _termsCtrl.text,
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
    final hasLocation = _latitude != null && _longitude != null;

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
                    isEdit ? 'Edit Building' : 'Add Building',
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
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameCtrl,
                decoration: _deco('Building Name', Icons.apartment_outlined),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressCtrl,
                decoration: _deco('Address', Icons.location_on_outlined),
                validator: (v) =>
                    (v == null || v.trim().isEmpty)
                        ? 'Address is required'
                        : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                maxLines: 3,
                decoration:
                    _deco('Description (optional)', Icons.notes_outlined),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _termsCtrl,
                maxLines: 5,
                decoration: _deco(
                    'Terms & Conditions (optional)', Icons.gavel_outlined),
              ),
              const SizedBox(height: 20),
              const Text(
                'Location',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 8),
              if (hasLocation) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFD0D0D0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle,
                          color: Color(0xFF3D3D3D), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Location set',
                              style: TextStyle(
                                color: Color(0xFF1A1A1A),
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              '${_latitude!.toStringAsFixed(5)}, ${_longitude!.toStringAsFixed(5)}',
                              style: const TextStyle(
                                  color: Color(0xFF6B6B6B), fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: _pickLocation,
                        style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF3D3D3D)),
                        child: const Text('Change',
                            style: TextStyle(fontSize: 12)),
                      ),
                      GestureDetector(
                        onTap: _clearLocation,
                        child: const Icon(Icons.close,
                            size: 16, color: Color(0xFF9B9B9B)),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                OutlinedButton.icon(
                  onPressed: _pickLocation,
                  icon: const Icon(Icons.map_outlined, size: 18),
                  label: const Text('Pick Location on Map'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1A1A1A),
                    side: const BorderSide(color: Color(0xFFD0D0D0)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    minimumSize: const Size(double.infinity, 0),
                    textStyle: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
              const SizedBox(height: 24),
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
                  ),
                  child: Text(
                    _saving
                        ? 'Saving...'
                        : (isEdit ? 'Update Building' : 'Add Building'),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
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
      labelStyle:
          const TextStyle(color: Color(0xFF6B6B6B), fontSize: 13),
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
