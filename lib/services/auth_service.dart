// ─────────────────────────────────────────────
//  AuthService – In-Memory Authentication
//  Uses a List<UserModel> as the "database"
//  No external DB or Firebase needed
// ─────────────────────────────────────────────

import '../models/user_model.dart';

class AuthService {
  // Singleton
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // ── In-memory "database" ──────────────────
  final List<UserModel> _users = [];
  UserModel? _currentUser;

  // ── Shared Domain Stores (in-memory) ─────
  final List<Map<String, dynamic>> _events = [];
  final List<Map<String, dynamic>> _buildings = [];
  final List<Map<String, dynamic>> _rooms = [];
  final List<Map<String, dynamic>> _availabilitySlots = [];
  final List<Map<String, dynamic>> _bookings = [];

  List<Map<String, dynamic>> get allEvents => List.unmodifiable(_events);
  List<Map<String, dynamic>> get allBuildings => List.unmodifiable(_buildings);
  List<Map<String, dynamic>> get allRooms => List.unmodifiable(_rooms);
  List<Map<String, dynamic>> get allAvailabilitySlots =>
      List.unmodifiable(_availabilitySlots);
  List<Map<String, dynamic>> get allBookings => List.unmodifiable(_bookings);

  void addEvent(Map<String, dynamic> event) => _events.add(event);

  void removeEvent(String eventId) =>
      _events.removeWhere((e) => e['id'] == eventId);

  // ── Buildings ─────────────────────────────
  String? addBuilding({
    required String name,
    required String address,
    String? description,
    String? imageUrl,
  }) {
    if (currentUser == null || currentUser!.role != UserRole.staff) {
      return 'Only Venue Owners can add buildings.';
    }
    if (name.trim().isEmpty) return 'Building name is required.';
    if (address.trim().isEmpty) return 'Building address is required.';

    _buildings.add({
      'id': 'bld_${DateTime.now().microsecondsSinceEpoch}',
      'ownerId': currentUser!.id,
      'name': name.trim(),
      'address': address.trim(),
      'description': (description ?? '').trim(),
      'imageUrl': (imageUrl ?? '').trim(),
      'createdAt': DateTime.now(),
    });
    return null;
  }

  String? updateBuilding({
    required String buildingId,
    required String name,
    required String address,
    String? description,
    String? imageUrl,
  }) {
    final idx = _buildings.indexWhere((b) => b['id'] == buildingId);
    if (idx == -1) return 'Building not found.';
    if (_buildings[idx]['ownerId'] != currentUser?.id) {
      return 'You can only update your own building.';
    }
    _buildings[idx] = {
      ..._buildings[idx],
      'name': name.trim(),
      'address': address.trim(),
      'description': (description ?? '').trim(),
      'imageUrl': (imageUrl ?? '').trim(),
    };
    return null;
  }

  String? deleteBuilding(String buildingId) {
    final building = _buildings.where((b) => b['id'] == buildingId).toList();
    if (building.isEmpty) return 'Building not found.';
    if (building.first['ownerId'] != currentUser?.id) {
      return 'You can only delete your own building.';
    }
    final buildingRoomIds = _rooms
        .where((r) => r['buildingId'] == buildingId)
        .map((r) => r['id'] as String)
        .toSet();
    final hasActiveBookings = _bookings.any((b) =>
        buildingRoomIds.contains(b['roomId']) &&
        b['status'] != 'cancelled' &&
        (b['end'] as DateTime).isAfter(DateTime.now()));
    if (hasActiveBookings) {
      return 'Cannot delete building with active bookings.';
    }

    _buildings.removeWhere((b) => b['id'] == buildingId);
    _rooms.removeWhere((r) => r['buildingId'] == buildingId);
    _availabilitySlots.removeWhere((s) => buildingRoomIds.contains(s['roomId']));
    _bookings.removeWhere((b) => buildingRoomIds.contains(b['roomId']));
    return null;
  }

  // ── Rooms ─────────────────────────────────
  String? addRoom({
    required String buildingId,
    required String name,
    required int capacity,
    required List<String> amenities,
    double? pricing,
  }) {
    final building = _buildings.where((b) => b['id'] == buildingId).toList();
    if (building.isEmpty) return 'Building not found.';
    if (building.first['ownerId'] != currentUser?.id) {
      return 'You can only add rooms to your own building.';
    }
    if (name.trim().isEmpty) return 'Room name is required.';
    if (capacity <= 0) return 'Capacity must be greater than zero.';

    _rooms.add({
      'id': 'rm_${DateTime.now().microsecondsSinceEpoch}',
      'buildingId': buildingId,
      'name': name.trim(),
      'capacity': capacity,
      'amenities': amenities,
      'pricing': pricing,
      'createdAt': DateTime.now(),
    });
    return null;
  }

  String? deleteRoom(String roomId) {
    final room = _rooms.where((r) => r['id'] == roomId).toList();
    if (room.isEmpty) return 'Room not found.';
    final building = _buildings.firstWhere((b) => b['id'] == room.first['buildingId']);
    if (building['ownerId'] != currentUser?.id) {
      return 'You can only delete your own room.';
    }
    final hasActiveBookings = _bookings.any((b) =>
        b['roomId'] == roomId &&
        b['status'] != 'cancelled' &&
        (b['end'] as DateTime).isAfter(DateTime.now()));
    if (hasActiveBookings) return 'Cannot delete room with active bookings.';

    _rooms.removeWhere((r) => r['id'] == roomId);
    _availabilitySlots.removeWhere((s) => s['roomId'] == roomId);
    _bookings.removeWhere((b) => b['roomId'] == roomId);
    return null;
  }

  // ── Availability ──────────────────────────
  String? addAvailability({
    required String roomId,
    required DateTime start,
    required DateTime end,
    bool blocked = false,
  }) {
    if (!end.isAfter(start)) return 'End time must be after start time.';
    if (start.isBefore(DateTime.now())) return 'Cannot add past availability.';

    final room = _rooms.where((r) => r['id'] == roomId).toList();
    if (room.isEmpty) return 'Room not found.';
    final building = _buildings.firstWhere((b) => b['id'] == room.first['buildingId']);
    if (building['ownerId'] != currentUser?.id) {
      return 'You can only manage availability for your own rooms.';
    }

    final overlap = _availabilitySlots.any((slot) =>
        slot['roomId'] == roomId &&
        _isOverlap(start, end, slot['start'] as DateTime, slot['end'] as DateTime));
    if (overlap) return 'Availability slot overlaps with an existing slot.';

    _availabilitySlots.add({
      'id': 'av_${DateTime.now().microsecondsSinceEpoch}',
      'roomId': roomId,
      'start': start,
      'end': end,
      'blocked': blocked,
    });
    return null;
  }

  String? blockSlot(String availabilityId) {
    final idx = _availabilitySlots.indexWhere((s) => s['id'] == availabilityId);
    if (idx == -1) return 'Availability not found.';
    _availabilitySlots[idx] = {..._availabilitySlots[idx], 'blocked': true};
    return null;
  }

  String? removeAvailability(String availabilityId) {
    final slot = _availabilitySlots.where((s) => s['id'] == availabilityId).toList();
    if (slot.isEmpty) return 'Availability not found.';
    final hasBooking = _bookings.any((b) =>
        b['roomId'] == slot.first['roomId'] &&
        b['status'] != 'cancelled' &&
        _isOverlap(
          slot.first['start'] as DateTime,
          slot.first['end'] as DateTime,
          b['start'] as DateTime,
          b['end'] as DateTime,
        ));
    if (hasBooking) return 'Cannot remove slot that contains active booking.';
    _availabilitySlots.removeWhere((s) => s['id'] == availabilityId);
    return null;
  }

  // ── Event + Booking ───────────────────────
  String? upsertOrganizerEvent({
    String? eventId,
    required String title,
    required String description,
    String? category,
    required DateTime start,
    required DateTime end,
    required int expectedAttendees,
    required String status, // draft | published
    Map<String, dynamic>? templateSource,
  }) {
    if (currentUser == null || currentUser!.role != UserRole.organizer) {
      return 'Only Organizers can manage events.';
    }
    if (title.trim().isEmpty) return 'Event title is required.';
    if (!end.isAfter(start)) return 'Event end must be after start.';
    if (start.isBefore(DateTime.now())) return 'Cannot create events in the past.';
    if (expectedAttendees <= 0) return 'Expected attendees must be greater than zero.';

    if (eventId == null) {
      _events.add({
        'id': 'evt_${DateTime.now().microsecondsSinceEpoch}',
        'organizerId': currentUser!.id,
        'title': title.trim(),
        'description': description.trim(),
        'category': (category ?? '').trim(),
        'start': start,
        'end': end,
        'expectedAttendees': expectedAttendees,
        'status': status,
        'bookingId': null,
        'templateSourceId': templateSource?['id'],
        'createdAt': DateTime.now(),
      });
      return null;
    }

    final idx = _events.indexWhere((e) => e['id'] == eventId);
    if (idx == -1) return 'Event not found.';
    if (_events[idx]['organizerId'] != currentUser!.id) {
      return 'You can only update your own events.';
    }
    _events[idx] = {
      ..._events[idx],
      'title': title.trim(),
      'description': description.trim(),
      'category': (category ?? '').trim(),
      'start': start,
      'end': end,
      'expectedAttendees': expectedAttendees,
      'status': status,
    };
    return null;
  }

  String? deleteOrganizerEvent(String eventId) {
    final event = _events.where((e) => e['id'] == eventId).toList();
    if (event.isEmpty) return 'Event not found.';
    if (event.first['organizerId'] != currentUser?.id) {
      return 'You can only delete your own event.';
    }
    final bookingId = event.first['bookingId'] as String?;
    if (bookingId != null) {
      cancelBooking(bookingId);
    }
    _events.removeWhere((e) => e['id'] == eventId);
    return null;
  }

  String? createBooking({
    required String eventId,
    required String roomId,
    required DateTime start,
    required DateTime end,
  }) {
    final event = _events.where((e) => e['id'] == eventId).toList();
    if (event.isEmpty) return 'Event not found.';
    final ev = event.first;
    if (ev['organizerId'] != currentUser?.id) return 'Unauthorized booking.';
    if (ev['bookingId'] != null) return 'Event already has a booking.';
    if (!end.isAfter(start)) return 'Invalid booking time range.';
    if (start.isBefore(DateTime.now())) return 'Cannot book in the past.';

    final room = _rooms.where((r) => r['id'] == roomId).toList();
    if (room.isEmpty) return 'Room not found.';
    if ((room.first['capacity'] as int) < (ev['expectedAttendees'] as int)) {
      return 'Room capacity is smaller than expected attendees.';
    }

    final isAvailable = _availabilitySlots.any((slot) =>
        slot['roomId'] == roomId &&
        (slot['blocked'] as bool) == false &&
        !start.isBefore(slot['start'] as DateTime) &&
        !end.isAfter(slot['end'] as DateTime));
    if (!isAvailable) return 'Selected time is outside available slots.';

    final conflictingBooking = _bookings.any((b) =>
        b['roomId'] == roomId &&
        b['status'] != 'cancelled' &&
        _isOverlap(start, end, b['start'] as DateTime, b['end'] as DateTime));
    if (conflictingBooking) return 'This room is already booked for this time.';

    final bookingId = 'bk_${DateTime.now().microsecondsSinceEpoch}';
    _bookings.add({
      'id': bookingId,
      'eventId': eventId,
      'roomId': roomId,
      'start': start,
      'end': end,
      'status': 'confirmed',
      'createdAt': DateTime.now(),
    });

    final eventIndex = _events.indexWhere((e) => e['id'] == eventId);
    _events[eventIndex] = {..._events[eventIndex], 'bookingId': bookingId};
    return null;
  }

  String? cancelBooking(String bookingId) {
    final idx = _bookings.indexWhere((b) => b['id'] == bookingId);
    if (idx == -1) return 'Booking not found.';
    _bookings[idx] = {..._bookings[idx], 'status': 'cancelled'};
    final eventId = _bookings[idx]['eventId'] as String;
    final eIdx = _events.indexWhere((e) => e['id'] == eventId);
    if (eIdx != -1) {
      _events[eIdx] = {..._events[eIdx], 'bookingId': null};
    }
    return null;
  }

  // ── Queries ───────────────────────────────
  List<Map<String, dynamic>> get ownerBuildings => _buildings
      .where((b) => b['ownerId'] == currentUser?.id)
      .toList(growable: false);

  List<Map<String, dynamic>> roomsForBuilding(String buildingId) => _rooms
      .where((r) => r['buildingId'] == buildingId)
      .toList(growable: false);

  List<Map<String, dynamic>> availabilityForRoom(String roomId) =>
      _availabilitySlots
          .where((s) => s['roomId'] == roomId)
          .toList(growable: false);

  List<Map<String, dynamic>> get organizerEvents => _events
      .where((e) => e['organizerId'] == currentUser?.id)
      .toList(growable: false);

  Map<String, dynamic>? bookingForEvent(String eventId) {
    final event = _events.where((e) => e['id'] == eventId).toList();
    if (event.isEmpty || event.first['bookingId'] == null) return null;
    return _bookings.firstWhere(
      (b) => b['id'] == event.first['bookingId'],
      orElse: () => {},
    );
  }

  List<Map<String, dynamic>> searchAvailableRooms({
    required DateTime start,
    required DateTime end,
    required int minCapacity,
    String locationQuery = '',
    List<String> amenities = const [],
  }) {
    final normalizedLocation = locationQuery.trim().toLowerCase();
    final result = <Map<String, dynamic>>[];

    for (final room in _rooms) {
      final capacity = room['capacity'] as int;
      if (capacity < minCapacity) continue;

      final roomAmenities = (room['amenities'] as List).cast<String>();
      final amenityMatch =
          amenities.every((a) => roomAmenities.map((x) => x.toLowerCase()).contains(a.toLowerCase()));
      if (!amenityMatch) continue;

      final building = _buildings.firstWhere((b) => b['id'] == room['buildingId']);
      if (normalizedLocation.isNotEmpty &&
          !(building['address'] as String).toLowerCase().contains(normalizedLocation)) {
        continue;
      }

      final available = _availabilitySlots.any((slot) =>
          slot['roomId'] == room['id'] &&
          slot['blocked'] == false &&
          !start.isBefore(slot['start'] as DateTime) &&
          !end.isAfter(slot['end'] as DateTime));
      if (!available) continue;

      final booked = _bookings.any((b) =>
          b['roomId'] == room['id'] &&
          b['status'] != 'cancelled' &&
          _isOverlap(start, end, b['start'] as DateTime, b['end'] as DateTime));
      if (booked) continue;

      result.add({
        'building': building,
        'room': room,
      });
    }
    return result;
  }

  bool _isOverlap(
    DateTime aStart,
    DateTime aEnd,
    DateTime bStart,
    DateTime bEnd,
  ) {
    return aStart.isBefore(bEnd) && bStart.isBefore(aEnd);
  }

  // Seeded super admin so app is always accessible
  bool _seeded = false;

  void _seedSuperAdmin() {
    if (_seeded) return;
    _seeded = true;
    _users.add(UserModel(
      id: 'sa_001',
      fullName: 'Super Admin',
      email: 'admin@eventflow.com',
      password: 'admin123',
      role: UserRole.superAdmin,
      bio: 'System administrator',
    ));
  }

  // ── Seed Injection APIs ───────────────────
  void seedUsers(List<UserModel> users) {
    _seedSuperAdmin();
    for (final u in users) {
      final exists = _users.any((e) => e.id == u.id || e.email.toLowerCase() == u.email.toLowerCase());
      if (!exists) _users.add(u);
    }
  }

  void seedBuildings(List<Map<String, dynamic>> buildings) {
    for (final b in buildings) {
      final exists = _buildings.any((e) => e['id'] == b['id']);
      if (!exists) _buildings.add(b);
    }
  }

  void seedRooms(List<Map<String, dynamic>> rooms) {
    for (final r in rooms) {
      final exists = _rooms.any((e) => e['id'] == r['id']);
      if (!exists) _rooms.add(r);
    }
  }

  void seedAvailabilitySlots(List<Map<String, dynamic>> slots) {
    for (final s in slots) {
      final exists = _availabilitySlots.any((e) => e['id'] == s['id']);
      if (!exists) _availabilitySlots.add(s);
    }
  }

  void seedEvents(List<Map<String, dynamic>> events) {
    for (final e in events) {
      final exists = _events.any((ex) => ex['id'] == e['id']);
      if (!exists) _events.add(e);
    }
  }

  void seedBookings(List<Map<String, dynamic>> bookings) {
    for (final b in bookings) {
      final exists = _bookings.any((ex) => ex['id'] == b['id']);
      if (!exists) _bookings.add(b);
    }
  }

  // ── Getters ───────────────────────────────
  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  List<UserModel> get allUsers {
    _seedSuperAdmin();
    return List.unmodifiable(_users);
  }

  // ── Register ──────────────────────────────
  /// Returns null on success, or an error message string on failure.
  String? register({
    required String fullName,
    required String email,
    required String password,
    required UserRole role,
    String? company,
    String? industry,
    String? phone,
    String? bio,
    List<String>? interests,
  }) {
    _seedSuperAdmin();

    if (fullName.trim().isEmpty) return 'Full name is required.';
    if (email.trim().isEmpty) return 'Email is required.';
    if (!email.contains('@') || !email.contains('.')) {
      return 'Please enter a valid email address.';
    }
    if (password.length < 6) return 'Password must be at least 6 characters.';

    // Check duplicate email
    final exists = _users.any(
          (u) => u.email.toLowerCase() == email.trim().toLowerCase(),
    );
    if (exists) return 'An account with this email already exists.';

    final newUser = UserModel(
      id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
      fullName: fullName.trim(),
      email: email.trim().toLowerCase(),
      password: password,
      role: role,
      company: company?.trim(),
      industry: industry?.trim(),
      phone: phone?.trim(),
      bio: bio?.trim(),
      interests: interests ?? [],
    );

    _users.add(newUser);
    _currentUser = newUser;
    return null; // success
  }

  // ── Login ─────────────────────────────────
  /// Returns null on success, or an error message string on failure.
  String? login(String email, String password) {
    _seedSuperAdmin();

    if (email.trim().isEmpty) return 'Email is required.';
    if (password.isEmpty) return 'Password is required.';

    final user = _users.firstWhere(
          (u) =>
      u.email.toLowerCase() == email.trim().toLowerCase() &&
          u.password == password,
      orElse: () => UserModel(
        id: '',
        fullName: '',
        email: '',
        password: '',
        role: UserRole.attendee,
      ),
    );

    if (user.id.isEmpty) return 'Invalid email or password.';

    _currentUser = user;
    return null; // success
  }

  // ── Logout ────────────────────────────────
  void logout() {
    _currentUser = null;
  }

  // ── Update Profile ────────────────────────
  /// Updates the current user's profile.
  String? updateProfile({
    required String fullName,
    required String email,
    String? company,
    String? industry,
    String? phone,
    String? bio,
    List<String>? interests,
  }) {
    if (_currentUser == null) return 'Not logged in.';
    if (fullName.trim().isEmpty) return 'Full name is required.';
    if (email.trim().isEmpty) return 'Email is required.';
    if (!email.contains('@')) return 'Please enter a valid email.';

    // Check email uniqueness (excluding self)
    final emailTaken = _users.any(
          (u) =>
      u.id != _currentUser!.id &&
          u.email.toLowerCase() == email.trim().toLowerCase(),
    );
    if (emailTaken) return 'This email is already in use by another account.';

    final index = _users.indexWhere((u) => u.id == _currentUser!.id);
    if (index == -1) return 'User not found.';

    final updated = _currentUser!.copyWith(
      fullName: fullName.trim(),
      email: email.trim().toLowerCase(),
      company: company?.trim(),
      industry: industry?.trim(),
      phone: phone?.trim(),
      bio: bio?.trim(),
      interests: interests,
    );

    _users[index] = updated;
    _currentUser = updated;
    return null;
  }

  // ── Change Password ───────────────────────
  String? changePassword(String currentPass, String newPass) {
    if (_currentUser == null) return 'Not logged in.';
    if (_currentUser!.password != currentPass) {
      return 'Current password is incorrect.';
    }
    if (newPass.length < 6) return 'New password must be at least 6 characters.';

    final index = _users.indexWhere((u) => u.id == _currentUser!.id);
    _users[index] = _currentUser!.copyWith(password: newPass);
    _currentUser = _users[index];
    return null;
  }

  // ── Admin: Manage Users ───────────────────
  List<UserModel> getUsersByRole(UserRole role) {
    return _users.where((u) => u.role == role).toList();
  }

  String? deleteUser(String userId) {
    if (_currentUser?.role != UserRole.superAdmin) {
      return 'Only Super Admins can delete users.';
    }
    if (userId == _currentUser?.id) return 'Cannot delete your own account.';
    _users.removeWhere((u) => u.id == userId);
    return null;
  }

  String? changeUserRole(String userId, UserRole newRole) {
    if (_currentUser?.role != UserRole.superAdmin) {
      return 'Only Super Admins can change roles.';
    }
    final index = _users.indexWhere((u) => u.id == userId);
    if (index == -1) return 'User not found.';
    _users[index] = _users[index].copyWith(role: newRole);
    return null;
  }
}