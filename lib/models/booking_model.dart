class BookingModel {
  final String id;
  final String eventId;
  final String roomId;
  final String buildingId;
  final DateTime start;
  final DateTime end;
  final String authStatus;
  final String managedStatus;
  final DateTime createdAt;

  final String eventTitle;
  final String organizerName;
  final String organizerId;
  final String roomName;
  final String buildingName;
  final double revenue;

  const BookingModel({
    required this.id,
    required this.eventId,
    required this.roomId,
    required this.buildingId,
    required this.start,
    required this.end,
    required this.authStatus,
    required this.managedStatus,
    required this.createdAt,
    required this.eventTitle,
    required this.organizerName,
    required this.organizerId,
    required this.roomName,
    required this.buildingName,
    required this.revenue,
  });

  bool get isActive => managedStatus == 'confirmed';
  bool get isPending => managedStatus == 'pending';
  bool get isCancelled =>
      managedStatus == 'cancelled' || managedStatus == 'rejected';
  bool get isRejected => managedStatus == 'rejected';

  Duration get duration => end.difference(start);
  double get durationHours => duration.inMinutes / 60.0;
}
