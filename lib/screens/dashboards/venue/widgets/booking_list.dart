import 'package:flutter/material.dart';
import '../../../../../models/booking_model.dart';
import '../../../../../services/booking_management_service.dart';
import 'booking_card.dart';

class BookingListView extends StatefulWidget {
  final String ownerId;
  final String ownerName;
  const BookingListView({
    super.key,
    required this.ownerId,
    this.ownerName = 'Staff',
  });

  @override
  State<BookingListView> createState() => _BookingListViewState();
}

class _BookingListViewState extends State<BookingListView> {
  String _filter = 'all';

  List<BookingModel> get _filtered {
    final all =
        BookingManagementService().getBookingsForOwner(widget.ownerId);
    switch (_filter) {
      case 'pending':
        return all.where((b) => b.isPending).toList();
      case 'confirmed':
        return all.where((b) => b.isActive).toList();
      case 'cancelled':
        return all.where((b) => b.isCancelled).toList();
      default:
        return all;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookings = _filtered;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFilterRow(),
        const SizedBox(height: 14),
        if (bookings.isEmpty)
          _buildEmptyState()
        else
          ...bookings.map(
            (b) => BookingCard(
              booking: b,
              ownerId: widget.ownerId,
              ownerName: widget.ownerName,
              onRefresh: () => setState(() {}),
            ),
          ),
      ],
    );
  }

  Widget _buildFilterRow() {
    final all = BookingManagementService().getBookingsForOwner(widget.ownerId);
    final pendingCount = all.where((b) => b.isPending).length;
    final confirmedCount = all.where((b) => b.isActive).length;
    final cancelledCount = all.where((b) => b.isCancelled).length;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterChip(
            label: 'All',
            count: all.length,
            selected: _filter == 'all',
            onTap: () => setState(() => _filter = 'all'),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Pending',
            count: pendingCount,
            selected: _filter == 'pending',
            onTap: () => setState(() => _filter = 'pending'),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Confirmed',
            count: confirmedCount,
            selected: _filter == 'confirmed',
            onTap: () => setState(() => _filter = 'confirmed'),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Cancelled',
            count: cancelledCount,
            selected: _filter == 'cancelled',
            onTap: () => setState(() => _filter = 'cancelled'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    String msg;
    switch (_filter) {
      case 'pending':
        msg = 'No pending bookings';
        break;
      case 'confirmed':
        msg = 'No confirmed bookings';
        break;
      case 'cancelled':
        msg = 'No cancelled bookings';
        break;
      default:
        msg = 'No bookings yet';
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 56),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFEEEEEE),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.inbox_outlined,
                  size: 32, color: Color(0xFF9B9B9B)),
            ),
            const SizedBox(height: 14),
            Text(msg,
                style: const TextStyle(
                    color: Color(0xFF1A1A1A),
                    fontSize: 15,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1A1A1A) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? const Color(0xFF1A1A1A)
                : const Color(0xFFDDDDDD),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : const Color(0xFF6B6B6B),
                fontSize: 13,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white.withAlpha(50)
                    : const Color(0xFFEEEEEE),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: selected
                      ? Colors.white
                      : const Color(0xFF6B6B6B),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
