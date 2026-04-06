import '../models/message_model.dart';

class BookingNotes {
  String internalNote;
  String organizerInstruction;
  BookingNotes({this.internalNote = '', this.organizerInstruction = ''});
}

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  final Map<String, List<MessageModel>> _threads = {};
  final Map<String, BookingNotes> _notes = {};

  List<MessageModel> messagesForBooking(String bookingId) {
    return List.unmodifiable(_threads[bookingId] ?? []);
  }

  void sendMessage({
    required String bookingId,
    required String senderId,
    required String senderName,
    required bool isOwner,
    required String text,
  }) {
    final msg = MessageModel(
      id: 'msg_${DateTime.now().microsecondsSinceEpoch}',
      bookingId: bookingId,
      senderId: senderId,
      senderName: senderName,
      isOwner: isOwner,
      text: text.trim(),
      timestamp: DateTime.now(),
    );
    _threads.putIfAbsent(bookingId, () => []).add(msg);
  }

  int unreadCount(String bookingId, {required bool forOwner}) {
    return 0;
  }

  bool hasMessages(String bookingId) {
    return (_threads[bookingId]?.isNotEmpty) ?? false;
  }

  BookingNotes notesForBooking(String bookingId) {
    return _notes.putIfAbsent(bookingId, () => BookingNotes());
  }

  void saveNotes(String bookingId, String internal, String organizer) {
    final notes = _notes.putIfAbsent(bookingId, () => BookingNotes());
    notes.internalNote = internal;
    notes.organizerInstruction = organizer;
  }

  void seedMessages(String bookingId, List<MessageModel> messages) {
    _threads.putIfAbsent(bookingId, () => []);
    for (final m in messages) {
      final exists = _threads[bookingId]!.any((e) => e.id == m.id);
      if (!exists) _threads[bookingId]!.add(m);
    }
  }
}
