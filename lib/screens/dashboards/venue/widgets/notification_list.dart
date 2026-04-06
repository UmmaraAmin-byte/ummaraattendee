import 'package:flutter/material.dart';
import '../../../../../models/notification_model.dart';
import '../../../../../services/notification_service.dart';

class NotificationListView extends StatefulWidget {
  final String ownerId;
  const NotificationListView({super.key, required this.ownerId});

  @override
  State<NotificationListView> createState() => _NotificationListViewState();
}

class _NotificationListViewState extends State<NotificationListView> {
  final _svc = NotificationService();

  void _markAllRead() {
    _svc.markAllRead(widget.ownerId);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final notifications = _svc.notificationsForOwner(widget.ownerId);
    final unread = _svc.unreadCount(widget.ownerId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Notifications',
              style: TextStyle(
                color: Color(0xFF1A1A1A),
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
            if (unread > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$unread',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ],
            const Spacer(),
            if (unread > 0)
              TextButton(
                onPressed: _markAllRead,
                style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF6B6B6B)),
                child: const Text('Mark all read',
                    style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w400)),
              ),
          ],
        ),
        const SizedBox(height: 14),
        if (notifications.isEmpty)
          _buildEmpty()
        else
          ...notifications.map((n) => _NotifCard(
                notification: n,
                onTap: () {
                  _svc.markRead(n.id);
                  setState(() {});
                },
              )),
      ],
    );
  }

  Widget _buildEmpty() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48),
      alignment: Alignment.center,
      child: const Column(
        children: [
          Icon(Icons.notifications_none_outlined,
              size: 48, color: Color(0xFFD0D0D0)),
          SizedBox(height: 12),
          Text('No notifications yet',
              style: TextStyle(
                  color: Color(0xFF6B6B6B),
                  fontSize: 15,
                  fontWeight: FontWeight.w400)),
        ],
      ),
    );
  }
}

class _NotifCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  const _NotifCard({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isUnread ? const Color(0xFFF5F5F5) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isUnread
                ? const Color(0xFFD0D0D0)
                : const Color(0xFFE8E8E8),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isUnread ? const Color(0xFF1A1A1A) : const Color(0xFFEEEEEE),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(_icon(),
                  color: isUnread ? Colors.white : const Color(0xFF3D3D3D),
                  size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: TextStyle(
                      color: const Color(0xFF1A1A1A),
                      fontWeight: isUnread
                          ? FontWeight.w700
                          : FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    notification.message,
                    style: const TextStyle(
                        color: Color(0xFF6B6B6B), fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(notification.timestamp),
                    style: const TextStyle(
                        color: Color(0xFF9B9B9B), fontSize: 11),
                  ),
                ],
              ),
            ),
            if (isUnread)
              Container(
                width: 7,
                height: 7,
                margin: const EdgeInsets.only(top: 4, left: 8),
                decoration: const BoxDecoration(
                  color: Color(0xFF1A1A1A),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _icon() {
    switch (notification.type) {
      case NotificationType.newBooking:
        return Icons.book_online_outlined;
      case NotificationType.cancellation:
        return Icons.cancel_outlined;
      case NotificationType.reminder:
        return Icons.alarm_outlined;
      case NotificationType.bookingModified:
        return Icons.edit_outlined;
    }
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
