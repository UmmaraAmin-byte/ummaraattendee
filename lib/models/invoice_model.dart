class InvoiceModel {
  final String id;
  final String bookingId;
  final String eventTitle;
  final String organizerName;
  final String roomName;
  final String buildingName;
  final DateTime start;
  final DateTime end;
  final double hourlyRate;
  final double durationHours;
  final double weekendMultiplier;
  final double totalAmount;
  final DateTime generatedAt;
  final String? termsAndConditions;

  const InvoiceModel({
    required this.id,
    required this.bookingId,
    required this.eventTitle,
    required this.organizerName,
    required this.roomName,
    required this.buildingName,
    required this.start,
    required this.end,
    required this.hourlyRate,
    required this.durationHours,
    required this.weekendMultiplier,
    required this.totalAmount,
    required this.generatedAt,
    this.termsAndConditions,
  });
}
