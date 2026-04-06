class RegistrationService {
  static final RegistrationService _instance = RegistrationService._internal();
  factory RegistrationService() => _instance;
  RegistrationService._internal();

  final List<Map<String, dynamic>> _registrations = [];

  String? register({
    required String eventId,
    required String attendeeId,
    required String attendeeName,
    required String attendeeEmail,
  }) {
    final exists = _registrations.any(
      (r) => r['eventId'] == eventId && r['attendeeId'] == attendeeId,
    );
    if (exists) return 'Already registered.';
    _registrations.add({
      'id': 'reg_${DateTime.now().microsecondsSinceEpoch}',
      'eventId': eventId,
      'attendeeId': attendeeId,
      'attendeeName': attendeeName,
      'attendeeEmail': attendeeEmail,
      'registeredAt': DateTime.now(),
      'attended': false,
      'notes': '',
    });
    return null;
  }

  void unregister({required String eventId, required String attendeeId}) {
    _registrations.removeWhere(
      (r) => r['eventId'] == eventId && r['attendeeId'] == attendeeId,
    );
  }

  bool isRegistered({required String eventId, required String attendeeId}) {
    return _registrations.any(
      (r) => r['eventId'] == eventId && r['attendeeId'] == attendeeId,
    );
  }

  List<Map<String, dynamic>> registrationsForEvent(String eventId) {
    return _registrations
        .where((r) => r['eventId'] == eventId)
        .toList(growable: false);
  }

  List<Map<String, dynamic>> registrationsForAttendee(String attendeeId) {
    return _registrations
        .where((r) => r['attendeeId'] == attendeeId)
        .toList(growable: false);
  }

  int countForEvent(String eventId) =>
      _registrations.where((r) => r['eventId'] == eventId).length;

  void markAttended(String registrationId, {bool attended = true}) {
    final idx = _registrations.indexWhere((r) => r['id'] == registrationId);
    if (idx != -1) {
      _registrations[idx] = {..._registrations[idx], 'attended': attended};
    }
  }

  void setNote(String registrationId, String note) {
    final idx = _registrations.indexWhere((r) => r['id'] == registrationId);
    if (idx != -1) {
      _registrations[idx] = {..._registrations[idx], 'notes': note};
    }
  }

  void seedRegistrations(List<Map<String, dynamic>> regs) {
    for (final r in regs) {
      final exists = _registrations.any((e) => e['id'] == r['id']);
      if (!exists) _registrations.add(r);
    }
  }

  List<Map<String, dynamic>> get all => List.unmodifiable(_registrations);
}
