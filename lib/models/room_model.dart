enum RoomType { hall, conference, outdoor, classroom, boardroom, studio, other }

extension RoomTypeExtension on RoomType {
  String get displayName {
    switch (this) {
      case RoomType.hall:
        return 'Hall';
      case RoomType.conference:
        return 'Conference';
      case RoomType.outdoor:
        return 'Outdoor';
      case RoomType.classroom:
        return 'Classroom';
      case RoomType.boardroom:
        return 'Boardroom';
      case RoomType.studio:
        return 'Studio';
      case RoomType.other:
        return 'Other';
    }
  }
}

class RoomModel {
  final String id;
  final String buildingId;
  final String name;
  final int capacity;
  final RoomType type;
  final String floor;
  final String description;
  final List<String> amenities;
  final List<String> imageUrls;
  final DateTime createdAt;

  RoomModel({
    required this.id,
    required this.buildingId,
    required this.name,
    required this.capacity,
    this.type = RoomType.other,
    this.floor = '',
    this.description = '',
    List<String>? amenities,
    List<String>? imageUrls,
    DateTime? createdAt,
  })  : amenities = amenities ?? [],
        imageUrls = imageUrls ?? [],
        createdAt = createdAt ?? DateTime.now();

  RoomModel copyWith({
    String? name,
    int? capacity,
    RoomType? type,
    String? floor,
    String? description,
    List<String>? amenities,
    List<String>? imageUrls,
  }) {
    return RoomModel(
      id: id,
      buildingId: buildingId,
      name: name ?? this.name,
      capacity: capacity ?? this.capacity,
      type: type ?? this.type,
      floor: floor ?? this.floor,
      description: description ?? this.description,
      amenities: amenities ?? this.amenities,
      imageUrls: imageUrls ?? this.imageUrls,
      createdAt: createdAt,
    );
  }
}
