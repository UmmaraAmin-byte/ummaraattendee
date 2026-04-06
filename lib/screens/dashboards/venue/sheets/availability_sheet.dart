import 'package:flutter/material.dart';
import '../../../../models/availability_model.dart';
import '../../../../services/venue_service.dart';

class AvailabilitySheet extends StatefulWidget {
  final String roomId;
  final String roomName;
  final VoidCallback onSaved;

  const AvailabilitySheet({
    super.key,
    required this.roomId,
    required this.roomName,
    required this.onSaved,
  });

  @override
  State<AvailabilitySheet> createState() => _AvailabilitySheetState();
}

class _AvailabilitySheetState extends State<AvailabilitySheet> {
  late int _startHour;
  late int _endHour;
  late List<int> _recurringDays;
  late List<DateTime> _blackoutDates;

  static const _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    final existing =
        VenueService().availabilityForRoom(widget.roomId);
    _startHour = existing?.workingHourStart ?? 8;
    _endHour = existing?.workingHourEnd ?? 18;
    _recurringDays = List.from(existing?.recurringDays ?? [1, 2, 3, 4, 5]);
    _blackoutDates = List.from(existing?.blackoutDates ?? []);
  }

  void _save() {
    if (_endHour <= _startHour) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('End hour must be after start hour.')),
      );
      return;
    }
    final availability = AvailabilityModel(
      roomId: widget.roomId,
      workingHourStart: _startHour,
      workingHourEnd: _endHour,
      recurringDays: List.from(_recurringDays),
      blackoutDates: List.from(_blackoutDates),
    );
    VenueService().saveAvailability(availability);
    Navigator.pop(context);
    widget.onSaved();
  }

  Future<void> _addBlackoutDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
    );
    if (picked == null || !mounted) return;
    final already = _blackoutDates.any((d) =>
        d.year == picked.year &&
        d.month == picked.month &&
        d.day == picked.day);
    if (!already) setState(() => _blackoutDates.add(picked));
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Availability',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      Text(
                        widget.roomName,
                        style: const TextStyle(
                            color: Color(0xFF6B6B6B), fontSize: 13),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Color(0xFF6B6B6B)),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Working Hours',
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Color(0xFF1A1A1A)),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _hourPicker(
                      'From', _startHour, (v) {
                    setState(() => _startHour = v);
                  }),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _hourPicker(
                      'Until', _endHour, (v) {
                    setState(() => _endHour = v);
                  }),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Available Days',
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Color(0xFF1A1A1A)),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(7, (i) {
                final day = i + 1;
                final selected = _recurringDays.contains(day);
                return FilterChip(
                  label: Text(_dayNames[i]),
                  selected: selected,
                  onSelected: (v) {
                    setState(() {
                      if (v) {
                        _recurringDays.add(day);
                      } else {
                        _recurringDays.remove(day);
                      }
                    });
                  },
                  backgroundColor: Colors.white,
                  selectedColor: const Color(0xFF1A1A1A),
                  side: BorderSide(
                    color: selected
                        ? const Color(0xFF1A1A1A)
                        : const Color(0xFFDDDDDD),
                  ),
                  labelStyle: TextStyle(
                    color: selected
                        ? Colors.white
                        : const Color(0xFF3D3D3D),
                    fontSize: 13,
                    fontWeight: selected
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                  checkmarkColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 4, vertical: 2),
                  showCheckmark: false,
                );
              }),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Blackout Dates',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Color(0xFF1A1A1A)),
                ),
                TextButton.icon(
                  onPressed: _addBlackoutDate,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Date'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
            if (_blackoutDates.isEmpty)
              const Text(
                'No blackout dates set.',
                style: TextStyle(
                    color: Color(0xFF6B6B6B), fontSize: 13),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _blackoutDates.map((d) {
                  return Chip(
                    label: Text(_fmt(d),
                        style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF3D3D3D),
                            fontWeight: FontWeight.w500)),
                    deleteIcon: const Icon(Icons.close,
                        size: 14, color: Color(0xFF9B9B9B)),
                    onDeleted: () =>
                        setState(() => _blackoutDates.remove(d)),
                    backgroundColor: const Color(0xFFEEEEEE),
                    side: const BorderSide(color: Color(0xFFDDDDDD)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 4, vertical: 0),
                  );
                }).toList(),
              ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
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
                child: const Text('Save Availability'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hourPicker(
      String label, int value, void Function(int) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13, color: Color(0xFF6B6B6B), fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            border:
                Border.all(color: const Color(0xFFE8E8E8)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: value,
              isExpanded: true,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              items: List.generate(24, (i) => i)
                  .map((h) => DropdownMenuItem(
                        value: h,
                        child: Text(
                            '${h.toString().padLeft(2, '0')}:00'),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
            ),
          ),
        ),
      ],
    );
  }
}
