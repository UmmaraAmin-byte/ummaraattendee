class BuildingModel {
  final String id;
  final String ownerId;
  final String name;
  final String address;
  final String description;
  final List<String> imageUrls;
  final DateTime createdAt;
  final double? latitude;
  final double? longitude;
  final String termsAndConditions;

  BuildingModel({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.address,
    this.description = '',
    List<String>? imageUrls,
    DateTime? createdAt,
    this.latitude,
    this.longitude,
    this.termsAndConditions = '',
  })  : imageUrls = imageUrls ?? [],
        createdAt = createdAt ?? DateTime.now();

  bool get hasLocation => latitude != null && longitude != null;

  BuildingModel copyWith({
    String? name,
    String? address,
    String? description,
    List<String>? imageUrls,
    double? latitude,
    double? longitude,
    bool clearLocation = false,
    String? termsAndConditions,
  }) {
    return BuildingModel(
      id: id,
      ownerId: ownerId,
      name: name ?? this.name,
      address: address ?? this.address,
      description: description ?? this.description,
      imageUrls: imageUrls ?? this.imageUrls,
      createdAt: createdAt,
      latitude: clearLocation ? null : (latitude ?? this.latitude),
      longitude: clearLocation ? null : (longitude ?? this.longitude),
      termsAndConditions: termsAndConditions ?? this.termsAndConditions,
    );
  }
}
