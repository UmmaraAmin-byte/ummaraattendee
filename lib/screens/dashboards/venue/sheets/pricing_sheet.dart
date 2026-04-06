import 'package:flutter/material.dart';
import '../../../../models/pricing_model.dart';
import '../../../../services/venue_service.dart';

class PricingSheet extends StatefulWidget {
  final String roomId;
  final String roomName;
  final VoidCallback onSaved;

  const PricingSheet({
    super.key,
    required this.roomId,
    required this.roomName,
    required this.onSaved,
  });

  @override
  State<PricingSheet> createState() => _PricingSheetState();
}

class _PricingSheetState extends State<PricingSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _hourlyCtrl;
  late final TextEditingController _dailyCtrl;
  late final TextEditingController _weekendCtrl;
  late final TextEditingController _peakCtrl;

  final Map<String, double> _addOns = {};
  final _addOnNameCtrl = TextEditingController();
  final _addOnPriceCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final existing = VenueService().pricingForRoom(widget.roomId);
    _hourlyCtrl = TextEditingController(
        text: existing != null && existing.hourlyRate > 0
            ? existing.hourlyRate.toStringAsFixed(2)
            : '');
    _dailyCtrl = TextEditingController(
        text: existing != null && existing.dailyRate > 0
            ? existing.dailyRate.toStringAsFixed(2)
            : '');
    _weekendCtrl = TextEditingController(
        text:
            (existing?.weekendMultiplier ?? 1.0).toStringAsFixed(2));
    _peakCtrl = TextEditingController(
        text:
            (existing?.peakHourMultiplier ?? 1.0).toStringAsFixed(2));
    if (existing != null) {
      _addOns.addAll(existing.addOns);
    }
  }

  @override
  void dispose() {
    _hourlyCtrl.dispose();
    _dailyCtrl.dispose();
    _weekendCtrl.dispose();
    _peakCtrl.dispose();
    _addOnNameCtrl.dispose();
    _addOnPriceCtrl.dispose();
    super.dispose();
  }

  void _addAddOn() {
    final name = _addOnNameCtrl.text.trim();
    final price = double.tryParse(_addOnPriceCtrl.text.trim());
    if (name.isEmpty || price == null || price < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Enter a valid add-on name and price.')),
      );
      return;
    }
    setState(() {
      _addOns[name] = price;
      _addOnNameCtrl.clear();
      _addOnPriceCtrl.clear();
    });
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final pricing = PricingModel(
      roomId: widget.roomId,
      hourlyRate: double.tryParse(_hourlyCtrl.text.trim()) ?? 0.0,
      dailyRate: double.tryParse(_dailyCtrl.text.trim()) ?? 0.0,
      weekendMultiplier:
          double.tryParse(_weekendCtrl.text.trim()) ?? 1.0,
      peakHourMultiplier:
          double.tryParse(_peakCtrl.text.trim()) ?? 1.0,
      addOns: Map.from(_addOns),
    );
    VenueService().savePricing(pricing);
    Navigator.pop(context);
    widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pricing',
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
                'Rates',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFF1A1A1A)),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _hourlyCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      decoration: _deco('Hourly Rate (\$)',
                          Icons.access_time_outlined),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _dailyCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      decoration: _deco(
                          'Daily Rate (\$)', Icons.today_outlined),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _weekendCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      decoration: _deco(
                          'Weekend ×', Icons.weekend_outlined),
                      validator: (v) {
                        final n = double.tryParse(v ?? '');
                        if (n == null || n <= 0) {
                          return 'Must be > 0';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _peakCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      decoration: _deco(
                          'Peak Hour ×', Icons.trending_up_outlined),
                      validator: (v) {
                        final n = double.tryParse(v ?? '');
                        if (n == null || n <= 0) {
                          return 'Must be > 0';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Add-Ons',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFF1A1A1A)),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _addOnNameCtrl,
                      decoration:
                          _deco('Add-On Name', Icons.add_circle_outline),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _addOnPriceCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      decoration:
                          _deco('Price', Icons.attach_money_outlined),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _addAddOn,
                    icon: const Icon(Icons.add,
                        color: Color(0xFF1A1A1A)),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFF2F2F2),
                    ),
                  ),
                ],
              ),
              if (_addOns.isNotEmpty) ...[
                const SizedBox(height: 10),
                ..._addOns.entries.map((e) => Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9F9F9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: const Color(0xFFEEEEEE)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF1A1A1A),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(e.key,
                                style: const TextStyle(
                                    color: Color(0xFF1A1A1A),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500)),
                          ),
                          Text('\$${e.value.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  color: Color(0xFF1A1A1A),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () =>
                                setState(() => _addOns.remove(e.key)),
                            child: const Icon(Icons.close,
                                size: 16,
                                color: Color(0xFF9B9B9B)),
                          ),
                        ],
                      ),
                    )),
              ],
              const SizedBox(height: 20),
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
                  child: const Text('Save Pricing'),
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
      prefixIcon: Icon(icon, color: const Color(0xFF3D3D3D), size: 18),
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
          const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
    );
  }
}
