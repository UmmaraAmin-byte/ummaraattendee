class MessageModel {
  final String id;
  final String bookingId;
  final String senderId;
  final String senderName;
  final bool isOwner;
  final String text;
  final DateTime timestamp;

  const MessageModel({
    required this.id,
    required this.bookingId,
    required this.senderId,
    required this.senderName,
    required this.isOwner,
    required this.text,
    required this.timestamp,
  });
}
