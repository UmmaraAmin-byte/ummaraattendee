import 'package:flutter/material.dart';
import '../../../../../models/booking_model.dart';
import '../../../../../models/notification_model.dart';
import '../../../../../models/payment_model.dart';
import '../../../../../models/room_model.dart';
import '../../../../../services/booking_management_service.dart';
import '../../../../../services/chat_service.dart';
import '../../../../../services/notification_service.dart';
import '../../../../../services/payment_service.dart';
import '../../../../../services/venue_service.dart';
import 'chat_screen.dart';
import 'invoice_view.dart';

class BookingCard extends StatefulWidget {
  final BookingModel booking;
  final String ownerId;
  final String ownerName;
  final VoidCallback onRefresh;

  const BookingCard({
    super.key,
    required this.booking,
    required this.ownerId,
    required this.onRefresh,
    this.ownerName = 'Staff',
  });

  @override
  State<BookingCard> createState() => _BookingCardState();
}

class _BookingCardState extends State<BookingCard> {
  bool _notesExpanded = false;
  late final TextEditingController _internalCtrl;
  late final TextEditingController _organizerCtrl;
  final _chatSvc = ChatService();
  final _paymentSvc = PaymentService();
  final _notifSvc = NotificationService();

  BookingModel get booking => widget.booking;
  String get ownerId => widget.ownerId;

  @override
  void initState() {
    super.initState();
    final notes = _chatSvc.notesForBooking(booking.id);
    _internalCtrl =
        TextEditingController(text: notes.internalNote);
    _organizerCtrl =
        TextEditingController(text: notes.organizerInstruction);
  }

  @override
  void dispose() {
    _internalCtrl.dispose();
    _organizerCtrl.dispose();
    super.dispose();
  }

  PaymentModel get _payment =>
      _paymentSvc.getOrCreate(booking.id, booking.revenue);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          _buildBody(),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          _buildQuickActions(context),
          if (!booking.isCancelled) ...[
            const Divider(height: 1, color: Color(0xFFF5F5F5)),
            _buildActions(context),
          ],
          if (_notesExpanded) ...[
            const Divider(height: 1, color: Color(0xFFF5F5F5)),
            _buildNotesPanel(),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.eventTitle,
                  style: const TextStyle(
                    color: Color(0xFF1A1A1A),
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  booking.organizerName,
                  style: const TextStyle(
                      color: Color(0xFF6B6B6B),
                      fontSize: 12,
                      fontWeight: FontWeight.w400),
                ),
              ],
            ),
          ),
          _StatusBadge(status: booking.managedStatus),
        ],
      ),
    );
  }

  Widget _buildBody() {
    final start = booking.start;
    final end = booking.end;
    final dateStr =
        '${_month(start.month)} ${start.day}, ${start.year}';
    final timeStr = '${_time(start)} – ${_time(end)}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        children: [
          _InfoRow(
              icon: Icons.meeting_room_outlined,
              label:
                  '${booking.roomName} · ${booking.buildingName}'),
          const SizedBox(height: 6),
          _InfoRow(icon: Icons.calendar_today_outlined, label: dateStr),
          const SizedBox(height: 6),
          _InfoRow(icon: Icons.schedule_outlined, label: timeStr),
          if (booking.revenue > 0) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: _InfoRow(
                    icon: Icons.attach_money_rounded,
                    label: '\$${booking.revenue.toStringAsFixed(2)}',
                    bold: true,
                  ),
                ),
                _PaymentChip(status: _payment.status),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        children: [
          _QuickBtn(
            icon: Icons.chat_bubble_outline,
            label: 'Chat',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BookingChatScreen(
                  booking: booking,
                  ownerId: ownerId,
                  ownerName: widget.ownerName,
                ),
              ),
            ),
          ),
          _QuickBtn(
            icon: Icons.receipt_long_outlined,
            label: 'Invoice',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => InvoiceView(
                  booking: booking,
                  ownerId: ownerId,
                ),
              ),
            ),
          ),
          _QuickBtn(
            icon: Icons.gavel_outlined,
            label: 'Agreement',
            onTap: () => _showAgreementDialog(context),
          ),
          _QuickBtn(
            icon: Icons.notes_outlined,
            label: 'Notes',
            active: _notesExpanded,
            onTap: () =>
                setState(() => _notesExpanded = !_notesExpanded),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        children: [
          if (booking.isPending) ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _reject(context),
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF6B6B6B),
                      side: const BorderSide(color: Color(0xFFD0D0D0)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      textStyle: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _approve(context),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A1A1A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
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
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showModifySheet(context),
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Modify Booking'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1A1A1A),
                  side: const BorderSide(color: Color(0xFFD0D0D0)),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  textStyle: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ] else if (booking.isActive) ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        _showSuggestAlternatives(context),
                    icon: const Icon(Icons.swap_horiz, size: 16),
                    label: const Text('Alternatives'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1A1A1A),
                      side: const BorderSide(color: Color(0xFFD0D0D0)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      textStyle: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showModifySheet(context),
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Modify'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1A1A1A),
                      side: const BorderSide(color: Color(0xFFD0D0D0)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      textStyle: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => _cancel(context),
                  icon: const Icon(Icons.cancel_outlined, size: 16),
                  label: const Text('Cancel'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF9B9B9B),
                    side: const BorderSide(color: Color(0xFFD0D0D0)),
                    padding: const EdgeInsets.symmetric(
                        vertical: 8, horizontal: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    textStyle: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w400),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNotesPanel() {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Notes',
            style: TextStyle(
                color: Color(0xFF1A1A1A),
                fontWeight: FontWeight.w700,
                fontSize: 14),
          ),
          const SizedBox(height: 12),
          const Text(
            'Internal (staff only)',
            style: TextStyle(
                color: Color(0xFF6B6B6B),
                fontSize: 12,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: _internalCtrl,
            maxLines: 2,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Notes visible to staff only…',
              hintStyle: const TextStyle(
                  color: Color(0xFFB0B0B0), fontSize: 13),
              filled: true,
              fillColor: const Color(0xFFF5F5F5),
              contentPadding: const EdgeInsets.all(10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Organizer instructions',
            style: TextStyle(
                color: Color(0xFF6B6B6B),
                fontSize: 12,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: _organizerCtrl,
            maxLines: 2,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Instructions visible to organizer…',
              hintStyle: const TextStyle(
                  color: Color(0xFFB0B0B0), fontSize: 13),
              filled: true,
              fillColor: const Color(0xFFF5F5F5),
              contentPadding: const EdgeInsets.all(10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () {
                _chatSvc.saveNotes(
                  booking.id,
                  _internalCtrl.text,
                  _organizerCtrl.text,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Notes saved'),
                    backgroundColor: Color(0xFF1A1A1A),
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 1),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A1A1A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                textStyle: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600),
                elevation: 0,
              ),
              child: const Text('Save Notes'),
            ),
          ),
        ],
      ),
    );
  }

  void _showAgreementDialog(BuildContext context) {
    final building = VenueService().buildingForRoom(booking.roomId);
    final terms = building?.termsAndConditions ?? '';
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.gavel_outlined,
                color: Color(0xFF3D3D3D), size: 20),
            const SizedBox(width: 8),
            const Text('Booking Agreement',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _agreementRow('Event', booking.eventTitle),
              _agreementRow('Organizer', booking.organizerName),
              _agreementRow('Room',
                  '${booking.roomName} · ${booking.buildingName}'),
              _agreementRow(
                  'Date',
                  '${_month(booking.start.month)} ${booking.start.day},'
                      ' ${booking.start.year}'),
              _agreementRow('Time',
                  '${_time(booking.start)} – ${_time(booking.end)}'),
              if (booking.revenue > 0)
                _agreementRow('Total',
                    '\$${booking.revenue.toStringAsFixed(2)}'),
              if (terms.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(color: Color(0xFFEEEEEE)),
                const SizedBox(height: 8),
                const Text(
                  'Terms & Conditions',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 6),
                Text(terms,
                    style: const TextStyle(
                        color: Color(0xFF6B6B6B),
                        fontSize: 12,
                        height: 1.5)),
              ] else ...[
                const SizedBox(height: 12),
                const Text(
                  'No terms & conditions set for this venue.',
                  style: TextStyle(
                      color: Color(0xFF9B9B9B), fontSize: 12),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF6B6B6B)),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _agreementRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(label,
                style: const TextStyle(
                    color: Color(0xFF9B9B9B), fontSize: 12)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    color: Color(0xFF1A1A1A),
                    fontSize: 12,
                    fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  void _approve(BuildContext context) {
    BookingManagementService().approveBooking(booking.id);
    _notifSvc.addNotification(
      ownerId: ownerId,
      title: 'Booking Approved',
      message: '"${booking.eventTitle}" has been confirmed.',
      type: NotificationType.newBooking,
    );
    _snack(context, 'Booking approved');
    widget.onRefresh();
  }

  void _reject(BuildContext context) {
    final err = BookingManagementService().rejectBooking(booking.id);
    if (err != null) {
      _snack(context, err);
      return;
    }
    _notifSvc.addNotification(
      ownerId: ownerId,
      title: 'Booking Rejected',
      message: '"${booking.eventTitle}" was rejected.',
      type: NotificationType.cancellation,
    );
    _snack(context, 'Booking rejected');
    widget.onRefresh();
  }

  void _cancel(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel Booking',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700)),
        content: Text(
            'Cancel booking for "${booking.eventTitle}"? This cannot be undone.',
            style: const TextStyle(
                color: Color(0xFF6B6B6B), fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF6B6B6B)),
            child: const Text('Keep'),
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
              Navigator.pop(context);
              final err =
                  BookingManagementService().cancelBooking(booking.id);
              if (err != null) {
                _snack(context, err);
                return;
              }
              _notifSvc.addNotification(
                ownerId: ownerId,
                title: 'Booking Cancelled',
                message: '"${booking.eventTitle}" was cancelled.',
                type: NotificationType.cancellation,
              );
              _snack(context, 'Booking cancelled');
              widget.onRefresh();
            },
            child: const Text('Cancel Booking'),
          ),
        ],
      ),
    );
  }

  void _showModifySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ModifyBookingSheet(
        booking: booking,
        ownerId: ownerId,
        onSaved: () {
          _notifSvc.addNotification(
            ownerId: ownerId,
            title: 'Booking Modified',
            message: '"${booking.eventTitle}" was updated.',
            type: NotificationType.bookingModified,
          );
          widget.onRefresh();
        },
      ),
    );
  }

  void _showSuggestAlternatives(BuildContext context) {
    final alternatives = BookingManagementService()
        .suggestAlternativeRooms(ownerId, booking);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Alternative Rooms',
              style: TextStyle(
                  color: Color(0xFF1A1A1A),
                  fontSize: 16,
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'Available for ${_time(booking.start)} – ${_time(booking.end)}',
              style: const TextStyle(
                  color: Color(0xFF6B6B6B), fontSize: 13),
            ),
            const SizedBox(height: 16),
            if (alternatives.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    'No alternative rooms available for this time slot.',
                    style: TextStyle(
                        color: Color(0xFF9B9B9B), fontSize: 13),
                  ),
                ),
              )
            else
              ...alternatives.take(5).map(
                    (r) => ListTile(
                      leading: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: const Icon(Icons.meeting_room_outlined,
                            color: Colors.white, size: 18),
                      ),
                      title: Text(r.name,
                          style: const TextStyle(
                              color: Color(0xFF1A1A1A),
                              fontWeight: FontWeight.w600,
                              fontSize: 13)),
                      subtitle: Text('Capacity: ${r.capacity}',
                          style: const TextStyle(
                              color: Color(0xFF6B6B6B), fontSize: 12)),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  void _snack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: const Color(0xFF1A1A1A),
      behavior: SnackBarBehavior.floating,
    ));
  }

  static String _time(DateTime dt) {
    final h = dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    final suffix = h >= 12 ? 'PM' : 'AM';
    final hour = h % 12 == 0 ? 12 : h % 12;
    return '$hour:$m $suffix';
  }

  static String _month(int m) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return months[m];
  }
}

// ─── Payment chip ──────────────────────────────────────────────────────────

class _PaymentChip extends StatelessWidget {
  final PaymentStatus status;
  const _PaymentChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;
    switch (status) {
      case PaymentStatus.paid:
        bg = const Color(0xFF1A1A1A);
        fg = Colors.white;
        label = 'Paid';
        break;
      case PaymentStatus.refunded:
        bg = const Color(0xFFEEEEEE);
        fg = const Color(0xFF3D3D3D);
        label = 'Refunded';
        break;
      case PaymentStatus.pending:
        bg = const Color(0xFFF5F5F5);
        fg = const Color(0xFF9B9B9B);
        label = 'Unpaid';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: status == PaymentStatus.paid
                ? const Color(0xFF1A1A1A)
                : const Color(0xFFE0E0E0)),
      ),
      child: Text(label,
          style: TextStyle(
              color: fg, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }
}

// ─── Quick Action Button ────────────────────────────────────────────────────

class _QuickBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  const _QuickBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    final fg = active ? Colors.white : const Color(0xFF3D3D3D);
    final bg = active ? const Color(0xFF1A1A1A) : const Color(0xFFF2F2F2);
    final border =
        active ? const Color(0xFF1A1A1A) : const Color(0xFFDDDDDD);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: fg),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                    color: fg,
                    fontSize: 12,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

// ─── Modify Booking Sheet ──────────────────────────────────────────────────

class _ModifyBookingSheet extends StatefulWidget {
  final BookingModel booking;
  final String ownerId;
  final VoidCallback onSaved;

  const _ModifyBookingSheet({
    required this.booking,
    required this.ownerId,
    required this.onSaved,
  });

  @override
  State<_ModifyBookingSheet> createState() => _ModifyBookingSheetState();
}

class _ModifyBookingSheetState extends State<_ModifyBookingSheet> {
  late DateTime _date;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late String _selectedRoomId;
  late List<RoomModel> _allRooms;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _date = DateTime(
        widget.booking.start.year,
        widget.booking.start.month,
        widget.booking.start.day);
    _startTime = TimeOfDay(
        hour: widget.booking.start.hour,
        minute: widget.booking.start.minute);
    _endTime = TimeOfDay(
        hour: widget.booking.end.hour,
        minute: widget.booking.end.minute);
    _selectedRoomId = widget.booking.roomId;
    _loadRooms();
  }

  void _loadRooms() {
    final venue = VenueService();
    final rooms = <RoomModel>[];
    for (final b in venue.buildingsForOwner(widget.ownerId)) {
      rooms.addAll(venue.roomsForBuilding(b.id));
    }
    _allRooms = rooms;
  }

  DateTime _buildDateTime(DateTime date, TimeOfDay time) {
    return DateTime(
        date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF1A1A1A),
            onPrimary: Colors.white,
            onSurface: Color(0xFF1A1A1A),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime(bool isStart) async {
    final initial = isStart ? _startTime : _endTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF1A1A1A),
            onPrimary: Colors.white,
            onSurface: Color(0xFF1A1A1A),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  void _save() {
    setState(() {
      _error = null;
      _saving = true;
    });

    final newStart = _buildDateTime(_date, _startTime);
    final newEnd = _buildDateTime(_date, _endTime);

    final err = BookingManagementService().modifyBooking(
      bookingId: widget.booking.id,
      ownerId: widget.ownerId,
      newStart: newStart,
      newEnd: newEnd,
      newRoomId: _selectedRoomId,
    );

    setState(() => _saving = false);

    if (err != null) {
      setState(() => _error = err);
      return;
    }

    Navigator.pop(context);
    widget.onSaved();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Booking modified successfully'),
      backgroundColor: Color(0xFF1A1A1A),
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, mediaQuery.viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Modify Booking',
                  style: TextStyle(
                      color: Color(0xFF1A1A1A),
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2),
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
          const SizedBox(height: 4),
          Text(
            widget.booking.eventTitle,
            style: const TextStyle(
                color: Color(0xFF6B6B6B),
                fontSize: 13,
                fontWeight: FontWeight.w400),
          ),
          const SizedBox(height: 20),
          _fieldLabel('Date'),
          const SizedBox(height: 6),
          _PickerTile(
            icon: Icons.calendar_today_outlined,
            label:
                '${_date.day} ${_monthName(_date.month)} ${_date.year}',
            onTap: _pickDate,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fieldLabel('Start Time'),
                    const SizedBox(height: 6),
                    _PickerTile(
                      icon: Icons.schedule_outlined,
                      label: _startTime.format(context),
                      onTap: () => _pickTime(true),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fieldLabel('End Time'),
                    const SizedBox(height: 6),
                    _PickerTile(
                      icon: Icons.schedule_outlined,
                      label: _endTime.format(context),
                      onTap: () => _pickTime(false),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _fieldLabel('Room'),
          const SizedBox(height: 6),
          if (_allRooms.isEmpty)
            const Text('No rooms available',
                style: TextStyle(
                    color: Color(0xFF9B9B9B), fontSize: 13))
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F9F9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE0E0E0)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _selectedRoomId,
                  items: _allRooms
                      .map((r) => DropdownMenuItem(
                            value: r.id,
                            child: Text(r.name,
                                style: const TextStyle(
                                    color: Color(0xFF1A1A1A),
                                    fontSize: 13)),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedRoomId = val);
                    }
                  },
                ),
              ),
            ),
          if (_error != null) ...[
            const SizedBox(height: 12),
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
                    child: Text(_error!,
                        style: const TextStyle(
                            color: Color(0xFF6B6B6B), fontSize: 12)),
                  ),
                ],
              ),
            ),
          ],
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
                    borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Save Changes',
                      style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldLabel(String text) => Text(
        text,
        style: const TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 13,
            fontWeight: FontWeight.w600),
      );

  static String _monthName(int m) {
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return months[m];
  }
}

class _PickerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PickerTile(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF9F9F9),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE0E0E0)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 16, color: const Color(0xFF3D3D3D)),
              const SizedBox(width: 8),
              Text(label,
                  style: const TextStyle(
                      color: Color(0xFF1A1A1A), fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Status Badge ──────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    Color border;
    String label;
    switch (status) {
      case 'confirmed':
        bg = const Color(0xFF1A1A1A);
        fg = Colors.white;
        border = const Color(0xFF1A1A1A);
        label = 'Confirmed';
        break;
      case 'pending':
        bg = const Color(0xFFF5F5F5);
        fg = const Color(0xFF3D3D3D);
        border = const Color(0xFFD0D0D0);
        label = 'Pending';
        break;
      case 'rejected':
        bg = const Color(0xFFEEEEEE);
        fg = const Color(0xFF9B9B9B);
        border = const Color(0xFFDDDDDD);
        label = 'Rejected';
        break;
      default:
        bg = const Color(0xFFEEEEEE);
        fg = const Color(0xFF9B9B9B);
        border = const Color(0xFFDDDDDD);
        label = 'Cancelled';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Text(label,
          style: TextStyle(
              color: fg, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

// ─── Info Row ──────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool bold;
  const _InfoRow(
      {required this.icon, required this.label, this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF9B9B9B)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color:
                  bold ? const Color(0xFF1A1A1A) : const Color(0xFF6B6B6B),
              fontSize: 13,
              fontWeight:
                  bold ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}
