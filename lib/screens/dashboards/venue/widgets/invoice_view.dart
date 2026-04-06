import 'package:flutter/material.dart';
import '../../../../../models/booking_model.dart';
import '../../../../../models/invoice_model.dart';
import '../../../../../models/payment_model.dart';
import '../../../../../services/payment_service.dart';
import '../../../../../services/venue_service.dart';

class InvoiceView extends StatefulWidget {
  final BookingModel booking;
  final String ownerId;

  const InvoiceView({
    super.key,
    required this.booking,
    required this.ownerId,
  });

  @override
  State<InvoiceView> createState() => _InvoiceViewState();
}

class _InvoiceViewState extends State<InvoiceView> {
  late final PaymentService _paymentSvc;
  late PaymentModel _payment;
  String? _actionError;

  @override
  void initState() {
    super.initState();
    _paymentSvc = PaymentService();
    _payment = _paymentSvc.getOrCreate(
        widget.booking.id, widget.booking.revenue);
  }

  InvoiceModel _buildInvoice() {
    final b = widget.booking;
    final pricing = VenueService().pricingForRoom(b.roomId);
    final isWeekend = b.start.weekday >= 6;
    final multiplier =
        pricing != null && isWeekend ? pricing.weekendMultiplier : 1.0;

    String? terms;
    final building =
        VenueService().buildingForRoom(b.roomId);
    if (building != null &&
        building.termsAndConditions.isNotEmpty) {
      terms = building.termsAndConditions;
    }

    return InvoiceModel(
      id: 'INV-${b.id.substring(0, 8).toUpperCase()}',
      bookingId: b.id,
      eventTitle: b.eventTitle,
      organizerName: b.organizerName,
      roomName: b.roomName,
      buildingName: b.buildingName,
      start: b.start,
      end: b.end,
      hourlyRate: pricing?.hourlyRate ?? 0,
      durationHours: b.durationHours,
      weekendMultiplier: multiplier,
      totalAmount: b.revenue,
      generatedAt: DateTime.now(),
      termsAndConditions: terms,
    );
  }

  void _markPaid() {
    final err = _paymentSvc.markPaid(widget.booking.id);
    if (err != null) {
      setState(() => _actionError = err);
      return;
    }
    setState(() {
      _payment = _paymentSvc.get(widget.booking.id)!;
      _actionError = null;
    });
  }

  void _markRefunded() {
    final err = _paymentSvc.markRefunded(widget.booking.id);
    if (err != null) {
      setState(() => _actionError = err);
      return;
    }
    setState(() {
      _payment = _paymentSvc.get(widget.booking.id)!;
      _actionError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final invoice = _buildInvoice();

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A1A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Invoice',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPaymentStatus(),
            const SizedBox(height: 16),
            _buildInvoiceCard(invoice),
            if (invoice.termsAndConditions != null &&
                invoice.termsAndConditions!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildTermsCard(invoice.termsAndConditions!),
            ],
            const SizedBox(height: 16),
            _buildActions(),
            if (_actionError != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFD0D0D0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: Color(0xFF6B6B6B), size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_actionError!,
                          style: const TextStyle(
                              color: Color(0xFF6B6B6B), fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentStatus() {
    Color statusColor;
    Color statusBg;
    IconData statusIcon;

    final isPaid = _payment.status == PaymentStatus.paid;
    switch (_payment.status) {
      case PaymentStatus.paid:
        statusColor = Colors.white;
        statusBg = const Color(0xFF1A1A1A);
        statusIcon = Icons.check_circle_outline;
        break;
      case PaymentStatus.refunded:
        statusColor = const Color(0xFF6B6B6B);
        statusBg = const Color(0xFFF5F5F5);
        statusIcon = Icons.undo_outlined;
        break;
      case PaymentStatus.pending:
        statusColor = const Color(0xFF6B6B6B);
        statusBg = const Color(0xFFF5F5F5);
        statusIcon = Icons.hourglass_empty_outlined;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: statusBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isPaid ? const Color(0xFF1A1A1A) : const Color(0xFFE0E0E0)),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 20),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Payment Status',
                style: TextStyle(
                    color: statusColor.withAlpha(180),
                    fontSize: 12,
                    fontWeight: FontWeight.w500),
              ),
              Text(
                _payment.statusLabel,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const Spacer(),
          if (_payment.paidAt != null)
            Text(
              _shortDate(_payment.paidAt!),
              style: TextStyle(
                  color: statusColor.withAlpha(180), fontSize: 12),
            ),
        ],
      ),
    );
  }

  Widget _buildInvoiceCard(InvoiceModel invoice) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'INVOICE',
                  style: TextStyle(
                    color: Color(0xFF9B9B9B),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              Text(
                invoice.id,
                style: const TextStyle(
                    color: Color(0xFF6B6B6B), fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFFEEEEEE)),
          const SizedBox(height: 12),
          _row('Event', invoice.eventTitle),
          _row('Organizer', invoice.organizerName),
          _row('Venue', invoice.buildingName),
          _row('Room', invoice.roomName),
          _row('Date', _formatDate(invoice.start)),
          _row('Time',
              '${_hhmm(invoice.start)} – ${_hhmm(invoice.end)}'),
          const SizedBox(height: 12),
          const Divider(color: Color(0xFFEEEEEE)),
          const SizedBox(height: 12),
          _pricingRow(
              'Hourly Rate', '\$${invoice.hourlyRate.toStringAsFixed(2)}/hr'),
          _pricingRow(
              'Duration', '${invoice.durationHours.toStringAsFixed(1)} hrs'),
          if (invoice.weekendMultiplier > 1)
            _pricingRow('Weekend Multiplier',
                '×${invoice.weekendMultiplier.toStringAsFixed(1)}'),
          const SizedBox(height: 8),
          const Divider(color: Color(0xFFEEEEEE)),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  color: Color(0xFF1A1A1A),
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              Text(
                '\$${invoice.totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Color(0xFF1A1A1A),
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Generated ${_formatDate(invoice.generatedAt)}',
            style: const TextStyle(
                color: Color(0xFF9B9B9B), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsCard(String terms) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.gavel_outlined,
                  size: 16, color: Color(0xFF6B6B6B)),
              SizedBox(width: 6),
              Text(
                'Terms & Conditions',
                style: TextStyle(
                    color: Color(0xFF1A1A1A),
                    fontWeight: FontWeight.w700,
                    fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            terms,
            style: const TextStyle(
                color: Color(0xFF6B6B6B), fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        if (_payment.status == PaymentStatus.pending) ...[
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _markPaid,
              icon: const Icon(Icons.check_circle_outline, size: 16),
              label: const Text('Mark as Paid'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A1A1A),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                textStyle: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ] else if (_payment.status == PaymentStatus.paid) ...[
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _markRefunded,
              icon: const Icon(Icons.undo_outlined, size: 16),
              label: const Text('Issue Refund'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF6B6B6B),
                side: const BorderSide(color: Color(0xFFD0D0D0)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                textStyle: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ] else if (_payment.status == PaymentStatus.refunded) ...[
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: const Text(
                'Refund Issued',
                style: TextStyle(
                    color: Color(0xFF9B9B9B),
                    fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(label,
                style: const TextStyle(
                    color: Color(0xFF9B9B9B), fontSize: 13)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    color: Color(0xFF1A1A1A),
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _pricingRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(label,
              style: const TextStyle(
                  color: Color(0xFF6B6B6B), fontSize: 13)),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                  color: Color(0xFF1A1A1A),
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month]} ${d.day}, ${d.year}';
  }

  String _shortDate(DateTime d) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month]} ${d.day}';
  }

  String _hhmm(DateTime dt) {
    final h = dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    final suffix = h >= 12 ? 'PM' : 'AM';
    final hour = h % 12 == 0 ? 12 : h % 12;
    return '$hour:$m $suffix';
  }
}
