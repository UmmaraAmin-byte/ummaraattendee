class TimeSeriesPoint {
  final DateTime date;
  final double value;
  const TimeSeriesPoint(this.date, this.value);
}

class RoomStats {
  final String roomId;
  final String roomName;
  final String buildingName;
  final int bookingCount;
  final double revenue;
  const RoomStats({
    required this.roomId,
    required this.roomName,
    required this.buildingName,
    required this.bookingCount,
    required this.revenue,
  });
}

class BuildingRevenue {
  final String buildingId;
  final String buildingName;
  final double revenue;
  final int bookingCount;
  const BuildingRevenue({
    required this.buildingId,
    required this.buildingName,
    required this.revenue,
    required this.bookingCount,
  });
}

class OrganizerStats {
  final String organizerId;
  final String name;
  final int bookingCount;
  final double totalSpend;
  const OrganizerStats({
    required this.organizerId,
    required this.name,
    required this.bookingCount,
    required this.totalSpend,
  });
}

class HourSlotCount {
  final int hour;
  final int count;
  const HourSlotCount(this.hour, this.count);
}

class DaySlotCount {
  final int weekday;
  final int count;
  const DaySlotCount(this.weekday, this.count);
}

class AnalyticsSnapshot {
  final double totalRevenue;
  final double avgBookingValue;
  final double occupancyRate;
  final double cancellationRate;
  final int totalBookings;
  final int confirmedBookings;
  final int cancelledBookings;
  final int pendingBookings;

  final List<RoomStats> topRooms;
  final List<BuildingRevenue> revenueByBuilding;
  final List<OrganizerStats> topOrganizers;
  final List<OrganizerStats> repeatOrganizers;

  final List<TimeSeriesPoint> dailyBookings;
  final List<TimeSeriesPoint> weeklyRevenue;
  final List<TimeSeriesPoint> monthlyRevenue;
  final List<HourSlotCount> bookingsByHour;
  final List<DaySlotCount> bookingsByDay;

  const AnalyticsSnapshot({
    required this.totalRevenue,
    required this.avgBookingValue,
    required this.occupancyRate,
    required this.cancellationRate,
    required this.totalBookings,
    required this.confirmedBookings,
    required this.cancelledBookings,
    required this.pendingBookings,
    required this.topRooms,
    required this.revenueByBuilding,
    required this.topOrganizers,
    required this.repeatOrganizers,
    required this.dailyBookings,
    required this.weeklyRevenue,
    required this.monthlyRevenue,
    required this.bookingsByHour,
    required this.bookingsByDay,
  });

  static AnalyticsSnapshot empty() => const AnalyticsSnapshot(
        totalRevenue: 0,
        avgBookingValue: 0,
        occupancyRate: 0,
        cancellationRate: 0,
        totalBookings: 0,
        confirmedBookings: 0,
        cancelledBookings: 0,
        pendingBookings: 0,
        topRooms: [],
        revenueByBuilding: [],
        topOrganizers: [],
        repeatOrganizers: [],
        dailyBookings: [],
        weeklyRevenue: [],
        monthlyRevenue: [],
        bookingsByHour: [],
        bookingsByDay: [],
      );
}
