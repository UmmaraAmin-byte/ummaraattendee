// ─────────────────────────────────────────────
//  User Model & Role Definitions
//  No database – data lives in memory (lists)
// ─────────────────────────────────────────────

enum UserRole { superAdmin, organizer, staff, attendee }

extension UserRoleExtension on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.superAdmin:
        return 'Super Admin';
      case UserRole.organizer:
        return 'Organizer';
      case UserRole.staff:
        return 'Venue Owner';
      case UserRole.attendee:
        return 'Attendee';
    }
  }

  String get emoji {
    switch (this) {
      case UserRole.superAdmin:
        return '👑';
      case UserRole.organizer:
        return '🎯';
      case UserRole.staff:
        return '🛠️';
      case UserRole.attendee:
        return '🎟️';
    }
  }
}

class UserModel {
  final String id;
  String fullName;
  String email;
  String password; // stored as plain text (no DB / no hashing needed for demo)
  UserRole role;
  String? company;
  String? industry;
  String? bio;
  String? phone;
  List<String> interests;
  DateTime createdAt;

  // For organizers: list of event IDs they manage
  List<String> managedEventIds;

  // For attendees: list of event IDs they are registered in
  List<String> registeredEventIds;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.password,
    required this.role,
    this.company,
    this.industry,
    this.bio,
    this.phone,
    List<String>? interests,
    List<String>? managedEventIds,
    List<String>? registeredEventIds,
    DateTime? createdAt,
  })  : interests = interests ?? [],
        managedEventIds = managedEventIds ?? [],
        registeredEventIds = registeredEventIds ?? [],
        createdAt = createdAt ?? DateTime.now();

  // Copy with updated fields
  UserModel copyWith({
    String? fullName,
    String? email,
    String? password,
    UserRole? role,
    String? company,
    String? industry,
    String? bio,
    String? phone,
    List<String>? interests,
  }) {
    return UserModel(
      id: id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      password: password ?? this.password,
      role: role ?? this.role,
      company: company ?? this.company,
      industry: industry ?? this.industry,
      bio: bio ?? this.bio,
      phone: phone ?? this.phone,
      interests: interests ?? this.interests,
      managedEventIds: managedEventIds,
      registeredEventIds: registeredEventIds,
      createdAt: createdAt,
    );
  }

  @override
  String toString() =>
      'UserModel(id: $id, name: $fullName, role: ${role.displayName})';
}