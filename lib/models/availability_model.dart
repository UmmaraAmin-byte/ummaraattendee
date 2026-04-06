class DateRange {
  final DateTime start;
  final DateTime end;

  DateRange({required this.start, required this.end});
}

class AvailabilityModel {
  final String roomId;
  final int workingHourStart;
  final int workingHourEnd;
  final List<DateTime> blackoutDates;
  final List<DateRange> maintenanceBlocks;
  final List<int> recurringDays;

  AvailabilityModel({
    required this.roomId,
    this.workingHourStart = 8,
    this.workingHourEnd = 18,
    List<DateTime>? blackoutDates,
    List<DateRange>? maintenanceBlocks,
    List<int>? recurringDays,
  })  : blackoutDates = blackoutDates ?? [],
        maintenanceBlocks = maintenanceBlocks ?? [],
        recurringDays = recurringDays ?? [1, 2, 3, 4, 5];

  AvailabilityModel copyWith({
    int? workingHourStart,
    int? workingHourEnd,
    List<DateTime>? blackoutDates,
    List<DateRange>? maintenanceBlocks,
    List<int>? recurringDays,
  }) {
    return AvailabilityModel(
      roomId: roomId,
      workingHourStart: workingHourStart ?? this.workingHourStart,
      workingHourEnd: workingHourEnd ?? this.workingHourEnd,
      blackoutDates: blackoutDates ?? List.from(this.blackoutDates),
      maintenanceBlocks: maintenanceBlocks ?? List.from(this.maintenanceBlocks),
      recurringDays: recurringDays ?? List.from(this.recurringDays),
    );
  }
}
