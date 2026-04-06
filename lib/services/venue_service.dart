import 'dart:math' as math;
import '../models/building_model.dart';
import '../models/room_model.dart';
import '../models/pricing_model.dart';
import '../models/availability_model.dart';

class VenueService {
  static final VenueService _instance = VenueService._internal();
  factory VenueService() => _instance;
  VenueService._internal();

  final List<BuildingModel> _buildings = [];
  final List<RoomModel> _rooms = [];
  final Map<String, PricingModel> _pricing = {};
  final Map<String, AvailabilityModel> _availability = {};

  List<BuildingModel> buildingsForOwner(String ownerId) =>
      _buildings.where((b) => b.ownerId == ownerId).toList();

  List<RoomModel> roomsForBuilding(String buildingId) =>
      _rooms.where((r) => r.buildingId == buildingId).toList();

  PricingModel? pricingForRoom(String roomId) => _pricing[roomId];

  AvailabilityModel? availabilityForRoom(String roomId) =>
      _availability[roomId];

  String? addBuilding({
    required String ownerId,
    required String name,
    required String address,
    String description = '',
    double? latitude,
    double? longitude,
    String termsAndConditions = '',
  }) {
    if (name.trim().isEmpty) return 'Building name is required.';
    if (address.trim().isEmpty) return 'Building address is required.';
    _buildings.add(BuildingModel(
      id: 'bld_${DateTime.now().microsecondsSinceEpoch}',
      ownerId: ownerId,
      name: name.trim(),
      address: address.trim(),
      description: description.trim(),
      latitude: latitude,
      longitude: longitude,
      termsAndConditions: termsAndConditions.trim(),
    ));
    return null;
  }

  String? updateBuilding({
    required String buildingId,
    required String ownerId,
    required String name,
    required String address,
    String description = '',
    double? latitude,
    double? longitude,
    bool clearLocation = false,
    String termsAndConditions = '',
  }) {
    final idx = _buildings.indexWhere((b) => b.id == buildingId);
    if (idx == -1) return 'Building not found.';
    if (_buildings[idx].ownerId != ownerId) {
      return 'You can only update your own building.';
    }
    if (name.trim().isEmpty) return 'Building name is required.';
    if (address.trim().isEmpty) return 'Building address is required.';
    _buildings[idx] = _buildings[idx].copyWith(
      name: name.trim(),
      address: address.trim(),
      description: description.trim(),
      latitude: latitude,
      longitude: longitude,
      clearLocation: clearLocation,
      termsAndConditions: termsAndConditions.trim(),
    );
    return null;
  }

  String? updateBuildingTerms({
    required String buildingId,
    required String ownerId,
    required String terms,
  }) {
    final idx = _buildings.indexWhere((b) => b.id == buildingId);
    if (idx == -1) return 'Building not found.';
    if (_buildings[idx].ownerId != ownerId) return 'Access denied.';
    _buildings[idx] = _buildings[idx].copyWith(termsAndConditions: terms);
    return null;
  }

  BuildingModel? buildingForRoom(String roomId) {
    final room = _rooms.where((r) => r.id == roomId).toList();
    if (room.isEmpty) return null;
    final bldList = _buildings.where((b) => b.id == room.first.buildingId).toList();
    return bldList.isEmpty ? null : bldList.first;
  }

  String? deleteBuilding(String buildingId, String ownerId) {
    final idx = _buildings.indexWhere((b) => b.id == buildingId);
    if (idx == -1) return 'Building not found.';
    if (_buildings[idx].ownerId != ownerId) {
      return 'You can only delete your own building.';
    }
    final roomIds = _rooms
        .where((r) => r.buildingId == buildingId)
        .map((r) => r.id)
        .toList();
    for (final rid in roomIds) {
      _pricing.remove(rid);
      _availability.remove(rid);
    }
    _rooms.removeWhere((r) => r.buildingId == buildingId);
    _buildings.removeAt(idx);
    return null;
  }

  String? addRoom({
    required String buildingId,
    required String ownerId,
    required String name,
    required int capacity,
    RoomType type = RoomType.other,
    String floor = '',
    String description = '',
    List<String>? amenities,
  }) {
    final buildingExists =
        _buildings.any((b) => b.id == buildingId && b.ownerId == ownerId);
    if (!buildingExists) return 'Building not found or access denied.';
    if (name.trim().isEmpty) return 'Room name is required.';
    if (capacity <= 0) return 'Capacity must be greater than zero.';
    _rooms.add(RoomModel(
      id: 'rm_${DateTime.now().microsecondsSinceEpoch}',
      buildingId: buildingId,
      name: name.trim(),
      capacity: capacity,
      type: type,
      floor: floor.trim(),
      description: description.trim(),
      amenities: amenities ?? [],
    ));
    return null;
  }

  String? updateRoom({
    required String roomId,
    required String ownerId,
    required String name,
    required int capacity,
    RoomType type = RoomType.other,
    String floor = '',
    String description = '',
    List<String>? amenities,
  }) {
    final idx = _rooms.indexWhere((r) => r.id == roomId);
    if (idx == -1) return 'Room not found.';
    final building =
        _buildings.firstWhere((b) => b.id == _rooms[idx].buildingId,
            orElse: () => BuildingModel(
                  id: '',
                  ownerId: '',
                  name: '',
                  address: '',
                ));
    if (building.id.isEmpty || building.ownerId != ownerId) {
      return 'You can only update your own room.';
    }
    if (name.trim().isEmpty) return 'Room name is required.';
    if (capacity <= 0) return 'Capacity must be greater than zero.';
    _rooms[idx] = _rooms[idx].copyWith(
      name: name.trim(),
      capacity: capacity,
      type: type,
      floor: floor.trim(),
      description: description.trim(),
      amenities: amenities,
    );
    return null;
  }

  String? deleteRoom(String roomId, String ownerId) {
    final idx = _rooms.indexWhere((r) => r.id == roomId);
    if (idx == -1) return 'Room not found.';
    final building =
        _buildings.firstWhere((b) => b.id == _rooms[idx].buildingId,
            orElse: () => BuildingModel(
                  id: '',
                  ownerId: '',
                  name: '',
                  address: '',
                ));
    if (building.id.isEmpty || building.ownerId != ownerId) {
      return 'You can only delete your own room.';
    }
    _pricing.remove(roomId);
    _availability.remove(roomId);
    _rooms.removeAt(idx);
    return null;
  }

  void savePricing(PricingModel pricing) {
    _pricing[pricing.roomId] = pricing;
  }

  void saveAvailability(AvailabilityModel availability) {
    _availability[availability.roomId] = availability;
  }

  void seedBuildings(List<BuildingModel> buildings) {
    for (final b in buildings) {
      final exists = _buildings.any((e) => e.id == b.id);
      if (!exists) _buildings.add(b);
    }
  }

  void seedRooms(List<RoomModel> rooms) {
    for (final r in rooms) {
      final exists = _rooms.any((e) => e.id == r.id);
      if (!exists) _rooms.add(r);
    }
  }

  void seedPricing(Map<String, PricingModel> pricing) {
    for (final entry in pricing.entries) {
      _pricing.putIfAbsent(entry.key, () => entry.value);
    }
  }

  void seedAvailability(Map<String, AvailabilityModel> availability) {
    for (final entry in availability.entries) {
      _availability.putIfAbsent(entry.key, () => entry.value);
    }
  }

  List<RoomModel> get allRooms => List.unmodifiable(_rooms);

  List<BuildingModel> nearbyBuildings({
    required double lat,
    required double lng,
    double radiusKm = 10.0,
  }) {
    return _buildings.where((b) {
      if (!b.hasLocation) return false;
      final dist = _haversineKm(
        lat, lng, b.latitude!, b.longitude!,
      );
      return dist <= radiusKm;
    }).toList();
  }

  static double _haversineKm(
      double lat1, double lng1, double lat2, double lng2) {
    const r = 6371.0;
    final dLat = _toRad(lat2 - lat1);
    final dLng = _toRad(lng2 - lng1);
    final a = math.pow(math.sin(dLat / 2), 2) +
        math.cos(_toRad(lat1)) *
            math.cos(_toRad(lat2)) *
            math.pow(math.sin(dLng / 2), 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return r * c;
  }

  static double _toRad(double deg) => deg * math.pi / 180;
}
