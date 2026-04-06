import '../models/analytics_model.dart';
import 'auth_service.dart';
import 'venue_service.dart';
import 'booking_management_service.dart';

class AnalyticsService {
  static AnalyticsSnapshot compute(String ownerId) {
    final venue = VenueService();
    final bms = BookingManagementService();

    final ownerRoomIds = <String>{};
    for (final b in venue.buildingsForOwner(ownerId)) {
      for (final r in venue.roomsForBuilding(b.id)) {
        ownerRoomIds.add(r.id);
      }
    }

    if (ownerRoomIds.isEmpty) return AnalyticsSnapshot.empty();

    final bookings = bms.getBookingsForOwner(ownerId);
    if (bookings.isEmpty) return AnalyticsSnapshot.empty();

    final confirmed = bookings.where((b) => b.isActive).toList();
    final cancelled =
        bookings.where((b) => b.isCancelled && !b.isRejected).toList();
    final rejected = bookings.where((b) => b.isRejected).toList();
    final pending = bookings.where((b) => b.isPending).toList();
    final allInactive = cancelled.length + rejected.length;

    final totalRevenue =
        confirmed.fold<double>(0, (s, b) => s + b.revenue);
    final avgBookingValue =
        confirmed.isEmpty ? 0.0 : totalRevenue / confirmed.length;

    final totalHours = ownerRoomIds.length * 16.0 * 30;
    final bookedHours =
        confirmed.fold<double>(0, (s, b) => s + b.durationHours);
    final occupancyRate = totalHours > 0
        ? (bookedHours / totalHours * 100).clamp(0.0, 100.0)
        : 0.0;

    final cancellationRate = bookings.isNotEmpty
        ? (allInactive / bookings.length * 100).clamp(0.0, 100.0)
        : 0.0;

    // Room stats
    final roomStats = <String, _RoomAccumulator>{};
    for (final b in confirmed) {
      roomStats.putIfAbsent(
        b.roomId,
        () => _RoomAccumulator(
          roomId: b.roomId,
          roomName: b.roomName,
          buildingName: b.buildingName,
        ),
      );
      roomStats[b.roomId]!.bookingCount++;
      roomStats[b.roomId]!.revenue += b.revenue;
    }
    final topRooms = roomStats.values
        .map((a) => RoomStats(
              roomId: a.roomId,
              roomName: a.roomName,
              buildingName: a.buildingName,
              bookingCount: a.bookingCount,
              revenue: a.revenue,
            ))
        .toList()
      ..sort((a, b) => b.bookingCount.compareTo(a.bookingCount));

    // Revenue by building
    final buildingAcc = <String, _BuildingAccumulator>{};
    for (final b in confirmed) {
      buildingAcc.putIfAbsent(
        b.buildingId,
        () => _BuildingAccumulator(
          buildingId: b.buildingId,
          buildingName: b.buildingName,
        ),
      );
      buildingAcc[b.buildingId]!.revenue += b.revenue;
      buildingAcc[b.buildingId]!.bookingCount++;
    }
    final revenueByBuilding = buildingAcc.values
        .map((a) => BuildingRevenue(
              buildingId: a.buildingId,
              buildingName: a.buildingName,
              revenue: a.revenue,
              bookingCount: a.bookingCount,
            ))
        .toList()
      ..sort((a, b) => b.revenue.compareTo(a.revenue));

    // Organizer stats
    final orgStats = <String, _OrgAccumulator>{};
    for (final b in bookings) {
      orgStats.putIfAbsent(
        b.organizerId,
        () =>
            _OrgAccumulator(organizerId: b.organizerId, name: b.organizerName),
      );
      orgStats[b.organizerId]!.bookingCount++;
      if (b.isActive) orgStats[b.organizerId]!.totalSpend += b.revenue;
    }
    final topOrganizers = orgStats.values
        .map((a) => OrganizerStats(
              organizerId: a.organizerId,
              name: a.name,
              bookingCount: a.bookingCount,
              totalSpend: a.totalSpend,
            ))
        .toList()
      ..sort((a, b) => b.bookingCount.compareTo(a.bookingCount));

    final repeatOrganizers =
        topOrganizers.where((o) => o.bookingCount > 1).toList();

    // Daily bookings (last 30 days)
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    final dailyCounts = <DateTime, double>{};
    for (var i = 0; i < 30; i++) {
      final d = thirtyDaysAgo.add(Duration(days: i));
      final key = DateTime(d.year, d.month, d.day);
      dailyCounts[key] = 0;
    }
    for (final b in bookings) {
      final key =
          DateTime(b.createdAt.year, b.createdAt.month, b.createdAt.day);
      if (dailyCounts.containsKey(key)) {
        dailyCounts[key] = dailyCounts[key]! + 1;
      }
    }
    final dailyBookings = dailyCounts.entries
        .map((e) => TimeSeriesPoint(e.key, e.value))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    // Weekly revenue (last 8 weeks)
    final weeklyRevenue = <DateTime, double>{};
    for (var i = 0; i < 8; i++) {
      final weekStart = _startOfWeek(now.subtract(Duration(days: 7 * (7 - i))));
      weeklyRevenue[weekStart] = 0;
    }
    for (final b in confirmed) {
      final ws = _startOfWeek(b.start);
      if (weeklyRevenue.containsKey(ws)) {
        weeklyRevenue[ws] = weeklyRevenue[ws]! + b.revenue;
      }
    }
    final weeklyRevList = weeklyRevenue.entries
        .map((e) => TimeSeriesPoint(e.key, e.value))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    // Monthly revenue (last 6 months)
    final monthlyRevenue = <DateTime, double>{};
    for (var i = 5; i >= 0; i--) {
      final month = _monthStart(now.month - i, now.year);
      monthlyRevenue[month] = 0;
    }
    for (final b in confirmed) {
      final ms = DateTime(b.start.year, b.start.month);
      if (monthlyRevenue.containsKey(ms)) {
        monthlyRevenue[ms] = monthlyRevenue[ms]! + b.revenue;
      }
    }
    final monthlyRevList = monthlyRevenue.entries
        .map((e) => TimeSeriesPoint(e.key, e.value))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    // Peak hours and days
    final hourCounts = <int, int>{};
    for (final b in confirmed) {
      final h = b.start.hour;
      hourCounts[h] = (hourCounts[h] ?? 0) + 1;
    }
    final bookingsByHour =
        List.generate(24, (i) => HourSlotCount(i, hourCounts[i] ?? 0));

    final dayCounts = <int, int>{};
    for (final b in confirmed) {
      final d = b.start.weekday;
      dayCounts[d] = (dayCounts[d] ?? 0) + 1;
    }
    final bookingsByDay =
        List.generate(7, (i) => DaySlotCount(i + 1, dayCounts[i + 1] ?? 0));

    return AnalyticsSnapshot(
      totalRevenue: totalRevenue,
      avgBookingValue: avgBookingValue,
      occupancyRate: occupancyRate,
      cancellationRate: cancellationRate,
      totalBookings: bookings.length,
      confirmedBookings: confirmed.length,
      cancelledBookings: allInactive,
      pendingBookings: pending.length,
      topRooms: topRooms.take(5).toList(),
      revenueByBuilding: revenueByBuilding,
      topOrganizers: topOrganizers.take(5).toList(),
      repeatOrganizers: repeatOrganizers.take(5).toList(),
      dailyBookings: dailyBookings,
      weeklyRevenue: weeklyRevList,
      monthlyRevenue: monthlyRevList,
      bookingsByHour: bookingsByHour,
      bookingsByDay: bookingsByDay,
    );
  }

  static DateTime _startOfWeek(DateTime d) {
    final diff = d.weekday - 1;
    return DateTime(d.year, d.month, d.day - diff);
  }

  static DateTime _monthStart(int month, int year) {
    var m = month;
    var y = year;
    while (m <= 0) {
      m += 12;
      y--;
    }
    while (m > 12) {
      m -= 12;
      y++;
    }
    return DateTime(y, m);
  }
}

class _RoomAccumulator {
  final String roomId;
  final String roomName;
  final String buildingName;
  int bookingCount = 0;
  double revenue = 0;
  _RoomAccumulator({
    required this.roomId,
    required this.roomName,
    required this.buildingName,
  });
}

class _BuildingAccumulator {
  final String buildingId;
  final String buildingName;
  double revenue = 0;
  int bookingCount = 0;
  _BuildingAccumulator({
    required this.buildingId,
    required this.buildingName,
  });
}

class _OrgAccumulator {
  final String organizerId;
  final String name;
  int bookingCount = 0;
  double totalSpend = 0;
  _OrgAccumulator({required this.organizerId, required this.name});
}
