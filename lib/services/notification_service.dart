import '../models/notification_model.dart';

class NotificationService {
  static final NotificationService _instance =
      NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final List<NotificationModel> _notifications = [];

  List<NotificationModel> notificationsForOwner(String ownerId) {
    return _notifications
        .where((n) => n.ownerId == ownerId)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  int unreadCount(String ownerId) {
    return _notifications
        .where((n) => n.ownerId == ownerId && !n.isRead)
        .length;
  }

  void markAllRead(String ownerId) {
    for (final n in _notifications) {
      if (n.ownerId == ownerId) n.isRead = true;
    }
  }

  void markRead(String notificationId) {
    final idx = _notifications.indexWhere((n) => n.id == notificationId);
    if (idx != -1) _notifications[idx].isRead = true;
  }

  void notifyNewBooking({
    required String ownerId,
    required String eventTitle,
    required String organizerName,
    required String bookingId,
  }) {
    _add(NotificationModel(
      id: _id(),
      ownerId: ownerId,
      title: 'New Booking Request',
      message: '"$eventTitle" by $organizerName is awaiting approval.',
      timestamp: DateTime.now(),
      type: NotificationType.newBooking,
      bookingId: bookingId,
    ));
  }

  void notifyCancellation({
    required String ownerId,
    required String eventTitle,
    required String bookingId,
  }) {
    _add(NotificationModel(
      id: _id(),
      ownerId: ownerId,
      title: 'Booking Cancelled',
      message: '"$eventTitle" has been cancelled.',
      timestamp: DateTime.now(),
      type: NotificationType.cancellation,
      bookingId: bookingId,
    ));
  }

  void notifyUpcomingEvent({
    required String ownerId,
    required String eventTitle,
    required String roomName,
    required DateTime start,
    required String bookingId,
  }) {
    final hour = start.hour;
    final suffix = hour >= 12 ? 'PM' : 'AM';
    final h = hour % 12 == 0 ? 12 : hour % 12;
    _add(NotificationModel(
      id: _id(),
      ownerId: ownerId,
      title: 'Upcoming Event Tomorrow',
      message: '"$eventTitle" in $roomName at $h:00 $suffix.',
      timestamp: DateTime.now(),
      type: NotificationType.reminder,
      bookingId: bookingId,
    ));
  }

  void notifyModification({
    required String ownerId,
    required String eventTitle,
    required String bookingId,
  }) {
    _add(NotificationModel(
      id: _id(),
      ownerId: ownerId,
      title: 'Booking Modified',
      message: '"$eventTitle" has been updated with new details.',
      timestamp: DateTime.now(),
      type: NotificationType.bookingModified,
      bookingId: bookingId,
    ));
  }

  void addNotification({
    required String ownerId,
    required String title,
    required String message,
    required NotificationType type,
    String? bookingId,
  }) {
    _add(NotificationModel(
      id: _id(),
      ownerId: ownerId,
      title: title,
      message: message,
      timestamp: DateTime.now(),
      type: type,
      bookingId: bookingId,
    ));
  }

  void _add(NotificationModel n) => _notifications.add(n);

  String _id() => 'notif_${DateTime.now().microsecondsSinceEpoch}';

  void seedNotifications(List<NotificationModel> notifications) {
    for (final n in notifications) {
      final exists = _notifications.any((e) => e.id == n.id);
      if (!exists) _notifications.add(n);
    }
  }
}
