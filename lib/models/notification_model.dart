enum NotificationType {
  newBooking,
  cancellation,
  reminder,
  bookingModified,
  eventRegistered,
  newEventInCategory,
}

class NotificationModel {
  final String id;
  final String ownerId;
  final String title;
  final String message;
  final DateTime timestamp;
  final NotificationType type;
  final String? bookingId;
  bool isRead;

  NotificationModel({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.type,
    this.bookingId,
    this.isRead = false,
  });
}
