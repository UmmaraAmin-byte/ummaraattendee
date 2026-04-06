class PricingModel {
  final String roomId;
  final double hourlyRate;
  final double dailyRate;
  final double weekendMultiplier;
  final double peakHourMultiplier;
  final Map<String, double> addOns;

  PricingModel({
    required this.roomId,
    this.hourlyRate = 0.0,
    this.dailyRate = 0.0,
    this.weekendMultiplier = 1.0,
    this.peakHourMultiplier = 1.0,
    Map<String, double>? addOns,
  }) : addOns = addOns ?? {};

  PricingModel copyWith({
    double? hourlyRate,
    double? dailyRate,
    double? weekendMultiplier,
    double? peakHourMultiplier,
    Map<String, double>? addOns,
  }) {
    return PricingModel(
      roomId: roomId,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      dailyRate: dailyRate ?? this.dailyRate,
      weekendMultiplier: weekendMultiplier ?? this.weekendMultiplier,
      peakHourMultiplier: peakHourMultiplier ?? this.peakHourMultiplier,
      addOns: addOns ?? Map.from(this.addOns),
    );
  }
}
