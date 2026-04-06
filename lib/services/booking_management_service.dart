import '../models/booking_model.dart';
import '../models/room_model.dart';
import 'auth_service.dart';
import 'venue_service.dart';

class _BookingModification {
  final DateTime start;
  final DateTime end;
  final String roomId;
  const _BookingModification({
    required this.start,
    required this.end,
    required this.roomId,
  });
}

class BookingManagementService {
  static final BookingManagementService _instance =
      BookingManagementService._internal();
  factory BookingManagementService() => _instance;
  BookingManagementService._internal();

  final Set<String> _approvedIds = {};
  final Set<String> _rejectedIds = {};
  final Map<String, _BookingModification> _modifications = {};

  String _effectiveStatus(Map<String, dynamic> raw) {
    final id = raw['id'] as String;
    if (_rejectedIds.contains(id)) return 'rejected';
    final authStatus = raw['status'] as String;
    if (authStatus == 'cancelled') return 'cancelled';
    if (_approvedIds.contains(id)) return 'confirmed';
    return 'pending';
  }

  List<BookingModel> getBookingsForOwner(String ownerId) {
    final auth = AuthService();
    final venue = VenueService();

    final roomToBuilding = <String, String>{};
    final roomNameMap = <String, String>{};
    final buildingNameMap = <String, String>{};

    for (final b in venue.buildingsForOwner(ownerId)) {
      buildingNameMap[b.id] = b.name;
      for (final r in venue.roomsForBuilding(b.id)) {
        roomToBuilding[r.id] = b.id;
        roomNameMap[r.id] = r.name;
      }
    }

    // Also index all rooms for name lookups after modifications
    for (final b in venue.buildingsForOwner(ownerId)) {
      for (final r in venue.roomsForBuilding(b.id)) {
        roomNameMap[r.id] = r.name;
      }
    }

    final userMap = <String, String>{};
    for (final u in auth.allUsers) {
      userMap[u.id] = u.fullName;
    }

    final eventMap = <String, Map<String, dynamic>>{};
    for (final e in auth.allEvents) {
      eventMap[e['id'] as String] = e;
    }

    final result = <BookingModel>[];
    for (final raw in auth.allBookings) {
      final originalRid = raw['roomId'] as String;
      final bid = roomToBuilding[originalRid];
      if (bid == null) continue;

      // Apply any modifications
      final mod = _modifications[raw['id'] as String];
      final effectiveRid = mod?.roomId ?? originalRid;
      final effectiveStart = mod?.start ?? (raw['start'] as DateTime);
      final effectiveEnd = mod?.end ?? (raw['end'] as DateTime);

      // Resolve building for modified room
      final effectiveBid = roomToBuilding[effectiveRid] ?? bid;

      final eventId = raw['eventId'] as String;
      final event = eventMap[eventId];
      final organizerId = (event?['organizerId'] as String?) ?? 'unknown';
      final orgName = userMap[organizerId] ?? 'Unknown Organizer';
      final evtTitle = (event?['title'] as String?) ?? 'Untitled Event';

      final pricing = venue.pricingForRoom(effectiveRid);
      final durationHours =
          effectiveEnd.difference(effectiveStart).inMinutes / 60.0;
      final isWeekend = effectiveStart.weekday >= 6;
      final multiplier =
          pricing != null && isWeekend ? pricing.weekendMultiplier : 1.0;
      final revenue =
          pricing != null ? pricing.hourlyRate * durationHours * multiplier : 0.0;

      result.add(BookingModel(
        id: raw['id'] as String,
        eventId: eventId,
        roomId: effectiveRid,
        buildingId: effectiveBid,
        start: effectiveStart,
        end: effectiveEnd,
        authStatus: raw['status'] as String,
        managedStatus: _effectiveStatus(raw),
        createdAt: raw['createdAt'] as DateTime,
        eventTitle: evtTitle,
        organizerName: orgName,
        organizerId: organizerId,
        roomName: roomNameMap[effectiveRid] ?? 'Unknown Room',
        buildingName: buildingNameMap[effectiveBid] ?? 'Unknown Building',
        revenue: revenue,
      ));
    }

    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return result;
  }

  void approveBooking(String bookingId) {
    _approvedIds.add(bookingId);
    _rejectedIds.remove(bookingId);
  }

  void seedApprovedIds(List<String> ids) {
    _approvedIds.addAll(ids);
  }

  String? rejectBooking(String bookingId) {
    final err = AuthService().cancelBooking(bookingId);
    if (err != null) return err;
    _rejectedIds.add(bookingId);
    _approvedIds.remove(bookingId);
    return null;
  }

  String? cancelBooking(String bookingId) {
    return AuthService().cancelBooking(bookingId);
  }

  String? modifyBooking({
    required String bookingId,
    required String ownerId,
    required DateTime newStart,
    required DateTime newEnd,
    required String newRoomId,
  }) {
    if (!newEnd.isAfter(newStart)) return 'End time must be after start time.';

    final auth = AuthService();
    final venue = VenueService();

    // Validate the new room belongs to this owner
    bool roomBelongsToOwner = false;
    for (final b in venue.buildingsForOwner(ownerId)) {
      for (final r in venue.roomsForBuilding(b.id)) {
        if (r.id == newRoomId) {
          roomBelongsToOwner = true;
          break;
        }
      }
      if (roomBelongsToOwner) break;
    }
    if (!roomBelongsToOwner) return 'Room does not belong to your venues.';

    // Check for conflicts with other bookings in the new room/time
    final hasConflict = auth.allBookings.any((bk) {
      if (bk['id'] == bookingId) return false;
      if (bk['roomId'] != newRoomId) return false;
      if (bk['status'] == 'cancelled') return false;
      if (_rejectedIds.contains(bk['id'])) return false;
      final bkStart = bk['start'] as DateTime;
      final bkEnd = bk['end'] as DateTime;
      return newStart.isBefore(bkEnd) && bkStart.isBefore(newEnd);
    });
    if (hasConflict) return 'New time slot conflicts with an existing booking.';

    _modifications[bookingId] = _BookingModification(
      start: newStart,
      end: newEnd,
      roomId: newRoomId,
    );
    return null;
  }

  List<RoomModel> suggestAlternativeRooms(
      String ownerId, BookingModel booking) {
    final venue = VenueService();
    final auth = AuthService();

    final alternatives = <RoomModel>[];
    for (final b in venue.buildingsForOwner(ownerId)) {
      for (final r in venue.roomsForBuilding(b.id)) {
        if (r.id == booking.roomId) continue;
        final hasConflict = auth.allBookings.any((bk) {
          if (bk['roomId'] != r.id) return false;
          if (bk['status'] == 'cancelled') return false;
          if (_rejectedIds.contains(bk['id'])) return false;
          final bStart = bk['start'] as DateTime;
          final bEnd = bk['end'] as DateTime;
          return bStart.isBefore(booking.end) && bEnd.isAfter(booking.start);
        });
        if (!hasConflict) alternatives.add(r);
      }
    }
    return alternatives;
  }
}
