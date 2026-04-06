import '../models/user_model.dart';
import '../models/building_model.dart';
import '../models/room_model.dart';
import '../models/pricing_model.dart';
import '../models/availability_model.dart';
import '../models/payment_model.dart';
import '../models/message_model.dart';
import '../models/notification_model.dart';
import '../models/document_model.dart';
import 'auth_service.dart';
import 'venue_service.dart';
import 'booking_management_service.dart';
import 'chat_service.dart';
import 'payment_service.dart';
import 'notification_service.dart';
import 'document_service.dart';
import 'registration_service.dart';

class SeedService {
  static final SeedService _instance = SeedService._internal();
  factory SeedService() => _instance;
  SeedService._internal();

  bool _seeded = false;

  void seed() {
    if (_seeded) return;
    _seeded = true;

    final now = DateTime.now();

    // ─────────────────────────────────────────
    // 1. USERS
    // ─────────────────────────────────────────

    // Venue Owners (role: staff)
    final owner1 = UserModel(
      id: 'own_001',
      fullName: 'Margaret Thornton',
      email: 'margaret@thorntonvenues.co.uk',
      password: 'password123',
      role: UserRole.staff,
      company: 'Thornton Venues Ltd',
      industry: 'Hospitality',
      phone: '+44 20 7946 0958',
      bio: 'Award-winning venue owner with 15 years of experience across Central London.',
      interests: ['Hospitality', 'Event Design', 'Architecture'],
    );

    final owner2 = UserModel(
      id: 'own_002',
      fullName: 'James Holloway',
      email: 'james@hollowayhalls.com',
      password: 'password123',
      role: UserRole.staff,
      company: 'Holloway Halls',
      industry: 'Events & Conferences',
      phone: '+44 161 496 0321',
      bio: 'Manchester-based venue operator specialising in corporate conferences and exhibitions.',
      interests: ['Corporate Events', 'Technology', 'Music'],
    );

    final owner3 = UserModel(
      id: 'own_003',
      fullName: 'Priya Nair',
      email: 'priya@nairspaces.com',
      password: 'password123',
      role: UserRole.staff,
      company: 'Nair Creative Spaces',
      industry: 'Creative Industries',
      phone: '+44 117 928 4475',
      bio: 'Bristol-based creative space owner passionate about bringing communities together.',
      interests: ['Art', 'Community', 'Sustainability'],
    );

    // Organizers
    final org1 = UserModel(
      id: 'org_001',
      fullName: 'Daniel Webb',
      email: 'daniel@webbevents.com',
      password: 'password123',
      role: UserRole.organizer,
      company: 'Webb Events',
      industry: 'Event Management',
      phone: '+44 20 7123 4567',
      bio: 'Corporate event planner specialising in large-scale conferences and product launches.',
      interests: ['Tech Conferences', 'Networking', 'Innovation'],
    );

    final org2 = UserModel(
      id: 'org_002',
      fullName: 'Sophie Lawson',
      email: 'sophie@lawsoncreative.co.uk',
      password: 'password123',
      role: UserRole.organizer,
      company: 'Lawson Creative',
      industry: 'Arts & Culture',
      phone: '+44 161 555 0198',
      bio: 'Independent event curator bringing arts and cultural experiences to wider audiences.',
      interests: ['Visual Arts', 'Live Music', 'Film'],
    );

    final org3 = UserModel(
      id: 'org_003',
      fullName: 'Ahmed Karimi',
      email: 'ahmed@karimiconsulting.com',
      password: 'password123',
      role: UserRole.organizer,
      company: 'Karimi Consulting',
      industry: 'Business & Finance',
      phone: '+44 117 944 2210',
      bio: 'Business consultant turned event organiser with a focus on leadership summits.',
      interests: ['Leadership', 'Finance', 'International Business'],
    );

    // Attendees
    final att1 = UserModel(
      id: 'att_001',
      fullName: 'Laura Simmons',
      email: 'laura.simmons@email.com',
      password: 'password123',
      role: UserRole.attendee,
      company: 'Simmons Digital',
      phone: '+44 20 7123 9900',
      bio: 'Tech enthusiast and serial conference-goer.',
      interests: ['Technology', 'AI', 'Startups'],
    );

    final att2 = UserModel(
      id: 'att_002',
      fullName: 'Nathan Brooks',
      email: 'nathan.brooks@email.com',
      password: 'password123',
      role: UserRole.attendee,
      company: 'Brooks Creative Studio',
      phone: '+44 161 555 7712',
      bio: 'Freelance designer interested in creative workshops.',
      interests: ['Design', 'Illustration', 'Photography'],
    );

    final att3 = UserModel(
      id: 'att_003',
      fullName: 'Chloe Martinez',
      email: 'chloe.martinez@email.com',
      password: 'password123',
      role: UserRole.attendee,
      company: 'Vivid Brand Agency',
      phone: '+44 117 496 3344',
      bio: 'Marketing professional with a passion for brand storytelling.',
      interests: ['Marketing', 'Branding', 'Social Media'],
    );

    final att4 = UserModel(
      id: 'att_004',
      fullName: 'Ravi Sharma',
      email: 'ravi.sharma@email.com',
      password: 'password123',
      role: UserRole.attendee,
      company: 'Sharma Ventures',
      phone: '+44 20 7956 0043',
      bio: 'Startup founder looking for networking events and pitching opportunities.',
      interests: ['Entrepreneurship', 'Investment', 'Product'],
    );

    final auth = AuthService();
    auth.seedUsers([
      owner1, owner2, owner3,
      org1, org2, org3,
      att1, att2, att3, att4,
    ]);

    // ─────────────────────────────────────────
    // 2. BUILDINGS & ROOMS (VenueService + AuthService)
    // ─────────────────────────────────────────

    final venue = VenueService();

    // Building 1 – owner1 (London)
    final bld1 = BuildingModel(
      id: 'bld_001',
      ownerId: owner1.id,
      name: 'Thornton Grand Hall',
      address: '14 Bishopsgate, London, EC2N 4HE',
      description: 'A prestigious event space in the heart of the City of London, ideal for large conferences and gala dinners.',
      latitude: 51.5154,
      longitude: -0.0815,
      termsAndConditions: 'All bookings require a 25% deposit. Cancellations within 48 hours forfeit the deposit.',
    );

    // Building 2 – owner1 (London)
    final bld2 = BuildingModel(
      id: 'bld_002',
      ownerId: owner1.id,
      name: 'Thornton Studio East',
      address: '88 Brick Lane, London, E1 6RL',
      description: 'A versatile creative studio in Shoreditch, perfect for workshops, launches, and intimate gatherings.',
      latitude: 51.5221,
      longitude: -0.0717,
      termsAndConditions: 'No alcohol without a temporary events notice. Noise curfew at 22:00.',
    );

    // Building 3 – owner2 (Manchester)
    final bld3 = BuildingModel(
      id: 'bld_003',
      ownerId: owner2.id,
      name: 'Holloway Conference Centre',
      address: '1 Deansgate, Manchester, M3 1AZ',
      description: 'State-of-the-art conference facilities in central Manchester with full AV support and catering.',
      latitude: 53.4803,
      longitude: -2.2502,
      termsAndConditions: 'Clients must confirm final attendee count 72 hours before the event.',
    );

    // Building 4 – owner2 (Manchester)
    final bld4 = BuildingModel(
      id: 'bld_004',
      ownerId: owner2.id,
      name: 'Holloway Garden Pavilion',
      address: '12 Piccadilly Gardens, Manchester, M1 1RG',
      description: 'Stunning outdoor pavilion with landscaped gardens, suitable for summer events and team building days.',
      latitude: 53.4808,
      longitude: -2.2372,
      termsAndConditions: 'Outdoor events subject to weather cancellation clause. See full policy.',
    );

    // Building 5 – owner3 (Bristol)
    final bld5 = BuildingModel(
      id: 'bld_005',
      ownerId: owner3.id,
      name: 'Nair Creative Hub',
      address: '32 Stokes Croft, Bristol, BS1 3QD',
      description: 'A vibrant creative hub in the heart of Bristol\'s arts district, with studio spaces and a rooftop terrace.',
      latitude: 51.4597,
      longitude: -2.5975,
      termsAndConditions: 'Community events receive a 15% discount. All events must comply with Bristol City Council guidelines.',
    );

    venue.seedBuildings([bld1, bld2, bld3, bld4, bld5]);

    // Rooms for bld1 (Thornton Grand Hall)
    final rm101 = RoomModel(id: 'rm_101', buildingId: 'bld_001', name: 'The Grand Ballroom', capacity: 500, type: RoomType.hall, floor: 'Ground Floor', description: 'Spectacular ballroom with chandeliers, a sprung dance floor, and a stage. Perfect for gala dinners and awards ceremonies.', amenities: ['Wi-Fi', 'Stage', 'AV System', 'Catering', 'Parking', 'Air Conditioning']);
    final rm102 = RoomModel(id: 'rm_102', buildingId: 'bld_001', name: 'The Churchill Suite', capacity: 120, type: RoomType.conference, floor: 'First Floor', description: 'Elegant conference suite with ceiling-to-floor windows overlooking the City skyline.', amenities: ['Wi-Fi', 'Projector', 'AV System', 'Catering', 'Air Conditioning', 'Whiteboard']);
    final rm103 = RoomModel(id: 'rm_103', buildingId: 'bld_001', name: 'Boardroom One', capacity: 20, type: RoomType.boardroom, floor: 'Second Floor', description: 'Intimate boardroom with premium furnishings, ideal for executive meetings and interviews.', amenities: ['Wi-Fi', 'Projector', 'AV System', 'Air Conditioning']);
    final rm104 = RoomModel(id: 'rm_104', buildingId: 'bld_001', name: 'The Classroom Suite', capacity: 60, type: RoomType.classroom, floor: 'First Floor', description: 'Training room fitted with tiered seating, whiteboards, and comprehensive AV equipment.', amenities: ['Wi-Fi', 'Projector', 'Whiteboard', 'Air Conditioning']);

    // Rooms for bld2 (Thornton Studio East)
    final rm201 = RoomModel(id: 'rm_201', buildingId: 'bld_002', name: 'Main Studio', capacity: 80, type: RoomType.studio, floor: 'Ground Floor', description: 'Industrial-chic studio with exposed brick, track lighting, and a DJ booth. Great for product launches and pop-ups.', amenities: ['Wi-Fi', 'AV System', 'Stage', 'Air Conditioning']);
    final rm202 = RoomModel(id: 'rm_202', buildingId: 'bld_002', name: 'Garden Terrace', capacity: 60, type: RoomType.outdoor, floor: 'Rooftop', description: 'Beautiful rooftop terrace with city views, ideal for evening receptions and summer parties.', amenities: ['Wi-Fi', 'Catering', 'Parking']);
    final rm203 = RoomModel(id: 'rm_203', buildingId: 'bld_002', name: 'Workshop Room A', capacity: 30, type: RoomType.classroom, floor: 'First Floor', description: 'Flexible workshop space with moveable furniture and whiteboard walls.', amenities: ['Wi-Fi', 'Whiteboard', 'Projector']);

    // Rooms for bld3 (Holloway Conference Centre)
    final rm301 = RoomModel(id: 'rm_301', buildingId: 'bld_003', name: 'Main Auditorium', capacity: 400, type: RoomType.hall, floor: 'Ground Floor', description: 'Full auditorium with tiered seating, cinema-grade screen, and professional sound system.', amenities: ['Wi-Fi', 'Stage', 'AV System', 'Projector', 'Air Conditioning', 'Catering']);
    final rm302 = RoomModel(id: 'rm_302', buildingId: 'bld_003', name: 'Conference Room Alpha', capacity: 80, type: RoomType.conference, floor: 'First Floor', description: 'Flexible conference room divisible into two smaller spaces, with full AV and catering facilities.', amenities: ['Wi-Fi', 'Projector', 'AV System', 'Catering', 'Whiteboard', 'Air Conditioning']);
    final rm303 = RoomModel(id: 'rm_303', buildingId: 'bld_003', name: 'Executive Boardroom', capacity: 20, type: RoomType.boardroom, floor: 'Second Floor', description: 'Premium boardroom with video-conferencing capabilities and leather seating.', amenities: ['Wi-Fi', 'AV System', 'Air Conditioning']);
    final rm304 = RoomModel(id: 'rm_304', buildingId: 'bld_003', name: 'Training Suite B', capacity: 45, type: RoomType.classroom, floor: 'First Floor', description: 'Dedicated training suite with breakout areas and digital whiteboard technology.', amenities: ['Wi-Fi', 'Projector', 'Whiteboard', 'Air Conditioning']);

    // Rooms for bld4 (Holloway Garden Pavilion)
    final rm401 = RoomModel(id: 'rm_401', buildingId: 'bld_004', name: 'Garden Pavilion Main', capacity: 200, type: RoomType.outdoor, floor: 'Ground Level', description: 'Stunning glass-and-steel pavilion opening to manicured gardens, ideal for summer celebrations.', amenities: ['Wi-Fi', 'Catering', 'Parking', 'Stage', 'AV System']);
    final rm402 = RoomModel(id: 'rm_402', buildingId: 'bld_004', name: 'Garden Studio', capacity: 40, type: RoomType.studio, floor: 'Ground Level', description: 'Intimate garden studio with natural light and private courtyard access.', amenities: ['Wi-Fi', 'Projector', 'Air Conditioning']);
    final rm403 = RoomModel(id: 'rm_403', buildingId: 'bld_004', name: 'Pavilion Boardroom', capacity: 20, type: RoomType.boardroom, floor: 'First Floor', description: 'Quiet executive boardroom with garden views and full AV connectivity.', amenities: ['Wi-Fi', 'Projector', 'AV System', 'Air Conditioning']);
    final rm404 = RoomModel(id: 'rm_404', buildingId: 'bld_004', name: 'Classroom Suite', capacity: 50, type: RoomType.classroom, floor: 'First Floor', description: 'Bright training classroom with moveable desks and interactive whiteboard, overlooking the gardens.', amenities: ['Wi-Fi', 'Projector', 'Whiteboard', 'Air Conditioning']);

    // Rooms for bld5 (Nair Creative Hub)
    final rm501 = RoomModel(id: 'rm_501', buildingId: 'bld_005', name: 'The Loft', capacity: 100, type: RoomType.hall, floor: 'Third Floor', description: 'Airy open-plan loft with skylight windows and a stage area, perfect for community events and performances.', amenities: ['Wi-Fi', 'Stage', 'AV System', 'Air Conditioning']);
    final rm502 = RoomModel(id: 'rm_502', buildingId: 'bld_005', name: 'Creative Studio 1', capacity: 25, type: RoomType.studio, floor: 'First Floor', description: 'Intimate creative studio with mood lighting and photography-friendly white walls.', amenities: ['Wi-Fi', 'Air Conditioning']);
    final rm503 = RoomModel(id: 'rm_503', buildingId: 'bld_005', name: 'Collaboration Space', capacity: 35, type: RoomType.conference, floor: 'Second Floor', description: 'Modern collaboration space with breakout pods and digital collaboration tools.', amenities: ['Wi-Fi', 'Projector', 'Whiteboard', 'Air Conditioning']);
    final rm504 = RoomModel(id: 'rm_504', buildingId: 'bld_005', name: 'Rooftop Terrace', capacity: 80, type: RoomType.outdoor, floor: 'Rooftop', description: 'Open rooftop terrace overlooking Stokes Croft, perfect for evening events with a Bristol backdrop.', amenities: ['Wi-Fi', 'Catering', 'Parking']);

    final allRooms = [rm101, rm102, rm103, rm104, rm201, rm202, rm203, rm301, rm302, rm303, rm304, rm401, rm402, rm403, rm404, rm501, rm502, rm503, rm504];
    venue.seedRooms(allRooms);

    // Seed buildings and rooms into AuthService maps too
    auth.seedBuildings([
      {'id': 'bld_001', 'ownerId': owner1.id, 'name': 'Thornton Grand Hall', 'address': '14 Bishopsgate, London, EC2N 4HE', 'description': 'A prestigious event space in the heart of the City of London.', 'imageUrl': '', 'createdAt': now.subtract(const Duration(days: 730))},
      {'id': 'bld_002', 'ownerId': owner1.id, 'name': 'Thornton Studio East', 'address': '88 Brick Lane, London, E1 6RL', 'description': 'A versatile creative studio in Shoreditch.', 'imageUrl': '', 'createdAt': now.subtract(const Duration(days: 500))},
      {'id': 'bld_003', 'ownerId': owner2.id, 'name': 'Holloway Conference Centre', 'address': '1 Deansgate, Manchester, M3 1AZ', 'description': 'State-of-the-art conference facilities in central Manchester.', 'imageUrl': '', 'createdAt': now.subtract(const Duration(days: 600))},
      {'id': 'bld_004', 'ownerId': owner2.id, 'name': 'Holloway Garden Pavilion', 'address': '12 Piccadilly Gardens, Manchester, M1 1RG', 'description': 'Stunning outdoor pavilion with landscaped gardens.', 'imageUrl': '', 'createdAt': now.subtract(const Duration(days: 400))},
      {'id': 'bld_005', 'ownerId': owner3.id, 'name': 'Nair Creative Hub', 'address': '32 Stokes Croft, Bristol, BS1 3QD', 'description': 'A vibrant creative hub in the heart of Bristol\'s arts district.', 'imageUrl': '', 'createdAt': now.subtract(const Duration(days: 365))},
    ]);

    auth.seedRooms([
      {'id': 'rm_101', 'buildingId': 'bld_001', 'name': 'The Grand Ballroom', 'capacity': 500, 'amenities': ['Wi-Fi', 'Stage', 'AV System', 'Catering', 'Parking', 'Air Conditioning'], 'pricing': 450.0, 'createdAt': now.subtract(const Duration(days: 720))},
      {'id': 'rm_102', 'buildingId': 'bld_001', 'name': 'The Churchill Suite', 'capacity': 120, 'amenities': ['Wi-Fi', 'Projector', 'AV System', 'Catering', 'Air Conditioning', 'Whiteboard'], 'pricing': 180.0, 'createdAt': now.subtract(const Duration(days: 720))},
      {'id': 'rm_103', 'buildingId': 'bld_001', 'name': 'Boardroom One', 'capacity': 20, 'amenities': ['Wi-Fi', 'Projector', 'AV System', 'Air Conditioning'], 'pricing': 75.0, 'createdAt': now.subtract(const Duration(days: 720))},
      {'id': 'rm_104', 'buildingId': 'bld_001', 'name': 'The Classroom Suite', 'capacity': 60, 'amenities': ['Wi-Fi', 'Projector', 'Whiteboard', 'Air Conditioning'], 'pricing': 120.0, 'createdAt': now.subtract(const Duration(days: 720))},
      {'id': 'rm_201', 'buildingId': 'bld_002', 'name': 'Main Studio', 'capacity': 80, 'amenities': ['Wi-Fi', 'AV System', 'Stage', 'Air Conditioning'], 'pricing': 150.0, 'createdAt': now.subtract(const Duration(days: 490))},
      {'id': 'rm_202', 'buildingId': 'bld_002', 'name': 'Garden Terrace', 'capacity': 60, 'amenities': ['Wi-Fi', 'Catering', 'Parking'], 'pricing': 100.0, 'createdAt': now.subtract(const Duration(days: 490))},
      {'id': 'rm_203', 'buildingId': 'bld_002', 'name': 'Workshop Room A', 'capacity': 30, 'amenities': ['Wi-Fi', 'Whiteboard', 'Projector'], 'pricing': 60.0, 'createdAt': now.subtract(const Duration(days: 490))},
      {'id': 'rm_301', 'buildingId': 'bld_003', 'name': 'Main Auditorium', 'capacity': 400, 'amenities': ['Wi-Fi', 'Stage', 'AV System', 'Projector', 'Air Conditioning', 'Catering'], 'pricing': 380.0, 'createdAt': now.subtract(const Duration(days: 590))},
      {'id': 'rm_302', 'buildingId': 'bld_003', 'name': 'Conference Room Alpha', 'capacity': 80, 'amenities': ['Wi-Fi', 'Projector', 'AV System', 'Catering', 'Whiteboard', 'Air Conditioning'], 'pricing': 160.0, 'createdAt': now.subtract(const Duration(days: 590))},
      {'id': 'rm_303', 'buildingId': 'bld_003', 'name': 'Executive Boardroom', 'capacity': 20, 'amenities': ['Wi-Fi', 'AV System', 'Air Conditioning'], 'pricing': 80.0, 'createdAt': now.subtract(const Duration(days: 590))},
      {'id': 'rm_304', 'buildingId': 'bld_003', 'name': 'Training Suite B', 'capacity': 45, 'amenities': ['Wi-Fi', 'Projector', 'Whiteboard', 'Air Conditioning'], 'pricing': 110.0, 'createdAt': now.subtract(const Duration(days: 590))},
      {'id': 'rm_401', 'buildingId': 'bld_004', 'name': 'Garden Pavilion Main', 'capacity': 200, 'amenities': ['Wi-Fi', 'Catering', 'Parking', 'Stage', 'AV System'], 'pricing': 250.0, 'createdAt': now.subtract(const Duration(days: 390))},
      {'id': 'rm_402', 'buildingId': 'bld_004', 'name': 'Garden Studio', 'capacity': 40, 'amenities': ['Wi-Fi', 'Projector', 'Air Conditioning'], 'pricing': 90.0, 'createdAt': now.subtract(const Duration(days: 390))},
      {'id': 'rm_403', 'buildingId': 'bld_004', 'name': 'Pavilion Boardroom', 'capacity': 20, 'amenities': ['Wi-Fi', 'Projector', 'AV System', 'Air Conditioning'], 'pricing': 85.0, 'createdAt': now.subtract(const Duration(days: 390))},
      {'id': 'rm_404', 'buildingId': 'bld_004', 'name': 'Classroom Suite', 'capacity': 50, 'amenities': ['Wi-Fi', 'Projector', 'Whiteboard', 'Air Conditioning'], 'pricing': 115.0, 'createdAt': now.subtract(const Duration(days: 390))},
      {'id': 'rm_501', 'buildingId': 'bld_005', 'name': 'The Loft', 'capacity': 100, 'amenities': ['Wi-Fi', 'Stage', 'AV System', 'Air Conditioning'], 'pricing': 140.0, 'createdAt': now.subtract(const Duration(days: 355))},
      {'id': 'rm_502', 'buildingId': 'bld_005', 'name': 'Creative Studio 1', 'capacity': 25, 'amenities': ['Wi-Fi', 'Air Conditioning'], 'pricing': 50.0, 'createdAt': now.subtract(const Duration(days: 355))},
      {'id': 'rm_503', 'buildingId': 'bld_005', 'name': 'Collaboration Space', 'capacity': 35, 'amenities': ['Wi-Fi', 'Projector', 'Whiteboard', 'Air Conditioning'], 'pricing': 70.0, 'createdAt': now.subtract(const Duration(days: 355))},
      {'id': 'rm_504', 'buildingId': 'bld_005', 'name': 'Rooftop Terrace', 'capacity': 80, 'amenities': ['Wi-Fi', 'Catering', 'Parking'], 'pricing': 120.0, 'createdAt': now.subtract(const Duration(days: 355))},
    ]);

    // ─────────────────────────────────────────
    // 3. PRICING & AVAILABILITY (VenueService)
    // ─────────────────────────────────────────

    final pricingMap = <String, PricingModel>{};
    final availMap = <String, AvailabilityModel>{};

    final roomPricingData = {
      'rm_101': [450.0, 3200.0, 1.3, 1.2],
      'rm_102': [180.0, 1300.0, 1.2, 1.1],
      'rm_103': [75.0, 550.0, 1.1, 1.0],
      'rm_104': [120.0, 900.0, 1.1, 1.0],
      'rm_201': [150.0, 1100.0, 1.25, 1.15],
      'rm_202': [100.0, 700.0, 1.3, 1.0],
      'rm_203': [60.0, 420.0, 1.1, 1.0],
      'rm_301': [380.0, 2800.0, 1.3, 1.2],
      'rm_302': [160.0, 1200.0, 1.2, 1.1],
      'rm_303': [80.0, 600.0, 1.1, 1.0],
      'rm_304': [110.0, 820.0, 1.1, 1.0],
      'rm_401': [250.0, 1800.0, 1.35, 1.0],
      'rm_402': [90.0, 650.0, 1.2, 1.0],
      'rm_403': [85.0, 620.0, 1.1, 1.0],
      'rm_404': [115.0, 850.0, 1.1, 1.0],
      'rm_501': [140.0, 1000.0, 1.2, 1.1],
      'rm_502': [50.0, 350.0, 1.1, 1.0],
      'rm_503': [70.0, 500.0, 1.1, 1.0],
      'rm_504': [120.0, 850.0, 1.25, 1.0],
    };

    for (final entry in roomPricingData.entries) {
      final d = entry.value;
      pricingMap[entry.key] = PricingModel(
        roomId: entry.key,
        hourlyRate: d[0],
        dailyRate: d[1],
        weekendMultiplier: d[2],
        peakHourMultiplier: d[3],
      );
    }

    // Most rooms: Mon-Fri 08:00-20:00; selected rooms also open Saturday
    final weekendRoomIds = {
      'rm_101', 'rm_201', 'rm_301', 'rm_401', 'rm_501', // flagship rooms
    };
    for (final rm in allRooms) {
      final days = weekendRoomIds.contains(rm.id)
          ? [1, 2, 3, 4, 5, 6] // Mon-Sat
          : [1, 2, 3, 4, 5];   // Mon-Fri
      availMap[rm.id] = AvailabilityModel(
        roomId: rm.id,
        workingHourStart: 8,
        workingHourEnd: 20,
        recurringDays: days,
      );
    }

    venue.seedPricing(pricingMap);
    venue.seedAvailability(availMap);

    // ─────────────────────────────────────────
    // 4. AVAILABILITY SLOTS (AuthService) – 6-month rolling window
    // ─────────────────────────────────────────

    final windowStart = now;
    final windowEnd = now.add(const Duration(days: 180));

    final slots = <Map<String, dynamic>>[];
    int slotCounter = 0;

    for (final rm in allRooms) {
      slotCounter++;
      slots.add({
        'id': 'av_s${slotCounter.toString().padLeft(3, '0')}',
        'roomId': rm.id,
        'start': DateTime(windowStart.year, windowStart.month, windowStart.day, 8),
        'end': DateTime(windowEnd.year, windowEnd.month, windowEnd.day, 20),
        'blocked': false,
      });
    }

    auth.seedAvailabilitySlots(slots);

    // ─────────────────────────────────────────
    // 5. EVENTS
    // ─────────────────────────────────────────

    final futureDate = (int daysAhead, int hour) =>
        DateTime(now.year, now.month, now.day + daysAhead, hour);
    final pastDate = (int daysAgo, int hour) =>
        DateTime(now.year, now.month, now.day - daysAgo, hour);

    // org1 events (Daniel Webb)
    final evtIds = [
      'evt_001', 'evt_002', 'evt_003', 'evt_004',
      'evt_005', 'evt_006', 'evt_007', 'evt_008',
      'evt_009', 'evt_010', 'evt_011', 'evt_012',
    ];

    auth.seedEvents([
      // org1 – 4 events
      {
        'id': evtIds[0], 'organizerId': org1.id, 'title': 'London Tech Summit 2026',
        'description': 'The premier technology conference bringing together 500 industry leaders for a full day of keynotes, panels, and networking.',
        'category': 'Technology', 'start': futureDate(30, 9), 'end': futureDate(30, 18),
        'expectedAttendees': 450, 'status': 'published', 'bookingId': 'bk_001', 'createdAt': now.subtract(const Duration(days: 60)),
      },
      {
        'id': evtIds[1], 'organizerId': org1.id, 'title': 'Product Launch: Nexus AI',
        'description': 'Exclusive product launch event for Nexus AI\'s groundbreaking enterprise platform.',
        'category': 'Business', 'start': futureDate(45, 14), 'end': futureDate(45, 19),
        'expectedAttendees': 70, 'status': 'published', 'bookingId': 'bk_002', 'createdAt': now.subtract(const Duration(days: 30)),
      },
      {
        'id': evtIds[2], 'organizerId': org1.id, 'title': 'Leadership Masterclass Series',
        'description': 'An intimate masterclass series covering strategic leadership, team dynamics, and innovation.',
        'category': 'Business', 'start': pastDate(45, 10), 'end': pastDate(45, 16),
        'expectedAttendees': 25, 'status': 'published', 'bookingId': null, 'createdAt': now.subtract(const Duration(days: 60)),
      },
      {
        'id': evtIds[3], 'organizerId': org1.id, 'title': 'Annual Sales Kickoff 2026',
        'description': 'Company-wide sales kickoff featuring department updates, Q&A sessions, and evening celebration.',
        'category': 'Corporate', 'start': futureDate(90, 8), 'end': futureDate(90, 20),
        'expectedAttendees': 380, 'status': 'draft', 'bookingId': null, 'createdAt': now.subtract(const Duration(days: 5)),
      },
      // org2 – 4 events
      {
        'id': evtIds[4], 'organizerId': org2.id, 'title': 'Bristol Arts Open 2026',
        'description': 'A celebration of emerging artists from the South West, featuring live art, performances, and an evening auction.',
        'category': 'Arts & Culture', 'start': futureDate(20, 11), 'end': futureDate(20, 21),
        'expectedAttendees': 90, 'status': 'published', 'bookingId': 'bk_003', 'createdAt': now.subtract(const Duration(days: 45)),
      },
      {
        'id': evtIds[5], 'organizerId': org2.id, 'title': 'Film Industry Networking Night',
        'description': 'An evening of industry networking for filmmakers, producers, and distributors.',
        'category': 'Arts & Culture', 'start': futureDate(35, 18), 'end': futureDate(35, 22),
        'expectedAttendees': 55, 'status': 'published', 'bookingId': 'bk_004', 'createdAt': now.subtract(const Duration(days: 20)),
      },
      {
        'id': evtIds[6], 'organizerId': org2.id, 'title': 'Creative Writing Workshop',
        'description': 'A hands-on creative writing workshop led by award-winning author Helena Cross.',
        'category': 'Education', 'start': pastDate(20, 10), 'end': pastDate(20, 15),
        'expectedAttendees': 22, 'status': 'published', 'bookingId': null, 'createdAt': now.subtract(const Duration(days: 40)),
      },
      {
        'id': evtIds[7], 'organizerId': org2.id, 'title': 'Music & Technology Festival',
        'description': 'A two-day festival exploring the intersection of music production and emerging technology.',
        'category': 'Arts & Culture', 'start': futureDate(120, 10), 'end': futureDate(121, 22),
        'expectedAttendees': 75, 'status': 'draft', 'bookingId': null, 'createdAt': now.subtract(const Duration(days: 3)),
      },
      // org3 – 4 events
      {
        'id': evtIds[8], 'organizerId': org3.id, 'title': 'Global Finance Forum',
        'description': 'A one-day forum bringing together CFOs and finance executives for panel discussions on macroeconomic trends.',
        'category': 'Finance', 'start': futureDate(15, 9), 'end': futureDate(15, 17),
        'expectedAttendees': 70, 'status': 'published', 'bookingId': 'bk_005', 'createdAt': now.subtract(const Duration(days: 50)),
      },
      {
        'id': evtIds[9], 'organizerId': org3.id, 'title': 'Startup Pitch Competition',
        'description': 'Ten early-stage startups pitch to a panel of investors for a chance to secure seed funding.',
        'category': 'Business', 'start': futureDate(50, 13), 'end': futureDate(50, 18),
        'expectedAttendees': 30, 'status': 'published', 'bookingId': 'bk_006', 'createdAt': now.subtract(const Duration(days: 25)),
      },
      {
        'id': evtIds[10], 'organizerId': org3.id, 'title': 'Annual Strategy Review',
        'description': 'Confidential internal strategy session for senior management.',
        'category': 'Corporate', 'start': futureDate(85, 9), 'end': futureDate(85, 17),
        'expectedAttendees': 14, 'status': 'draft', 'bookingId': null, 'createdAt': now.subtract(const Duration(days: 4)),
      },
      {
        'id': evtIds[11], 'organizerId': org3.id, 'title': 'International Trade Summit',
        'description': 'A summit connecting UK exporters with international trade partners across three continents.',
        'category': 'Business', 'start': futureDate(110, 8), 'end': futureDate(110, 18),
        'expectedAttendees': 350, 'status': 'draft', 'bookingId': null, 'createdAt': now.subtract(const Duration(days: 2)),
      },
    ]);

    // ─────────────────────────────────────────
    // 6. BOOKINGS
    // ─────────────────────────────────────────

    // Past bookings (for history)
    final pastStart1 = pastDate(60, 9);
    final pastEnd1 = pastDate(60, 17);
    final pastStart2 = pastDate(30, 14);
    final pastEnd2 = pastDate(30, 19);

    auth.seedBookings([
      // bk_001: evt_001 -> rm_101 (Grand Ballroom), confirmed+approved, future
      {'id': 'bk_001', 'eventId': evtIds[0], 'roomId': 'rm_101', 'start': futureDate(30, 9), 'end': futureDate(30, 18), 'status': 'confirmed', 'createdAt': now.subtract(const Duration(days: 55))},
      // bk_002: evt_002 -> rm_201 (Main Studio), confirmed+approved, future
      {'id': 'bk_002', 'eventId': evtIds[1], 'roomId': 'rm_201', 'start': futureDate(45, 14), 'end': futureDate(45, 19), 'status': 'confirmed', 'createdAt': now.subtract(const Duration(days: 25))},
      // bk_003: evt_005 -> rm_501 (The Loft), confirmed, pending review, future
      {'id': 'bk_003', 'eventId': evtIds[4], 'roomId': 'rm_501', 'start': futureDate(20, 11), 'end': futureDate(20, 21), 'status': 'confirmed', 'createdAt': now.subtract(const Duration(days: 40))},
      // bk_004: evt_006 -> rm_503 (Collaboration Space), confirmed, pending review, future
      {'id': 'bk_004', 'eventId': evtIds[5], 'roomId': 'rm_503', 'start': futureDate(35, 18), 'end': futureDate(35, 22), 'status': 'confirmed', 'createdAt': now.subtract(const Duration(days: 18))},
      // bk_005: evt_009 -> rm_302 (Conference Room Alpha), confirmed+approved, future
      {'id': 'bk_005', 'eventId': evtIds[8], 'roomId': 'rm_302', 'start': futureDate(15, 9), 'end': futureDate(15, 17), 'status': 'confirmed', 'createdAt': now.subtract(const Duration(days: 45))},
      // bk_006: evt_010 -> rm_402 (Garden Studio), confirmed, pending review, future
      {'id': 'bk_006', 'eventId': evtIds[9], 'roomId': 'rm_402', 'start': futureDate(50, 13), 'end': futureDate(50, 18), 'status': 'confirmed', 'createdAt': now.subtract(const Duration(days: 20))},
      // bk_007: past booking for rm_102 – confirmed+approved (historical)
      {'id': 'bk_007', 'eventId': 'evt_hist_001', 'roomId': 'rm_102', 'start': pastStart1, 'end': pastEnd1, 'status': 'confirmed', 'createdAt': now.subtract(const Duration(days: 90))},
      // bk_008: past booking for rm_301 – confirmed+approved (historical)
      {'id': 'bk_008', 'eventId': 'evt_hist_002', 'roomId': 'rm_301', 'start': pastStart2, 'end': pastEnd2, 'status': 'confirmed', 'createdAt': now.subtract(const Duration(days: 45))},
      // bk_009: cancelled booking for rm_104
      {'id': 'bk_009', 'eventId': 'evt_hist_003', 'roomId': 'rm_104', 'start': futureDate(100, 10), 'end': futureDate(100, 14), 'status': 'cancelled', 'createdAt': now.subtract(const Duration(days: 35))},
      // bk_010: cancelled booking for rm_401
      {'id': 'bk_010', 'eventId': 'evt_hist_004', 'roomId': 'rm_401', 'start': futureDate(130, 12), 'end': futureDate(130, 20), 'status': 'cancelled', 'createdAt': now.subtract(const Duration(days: 15))},
    ]);

    // Seed historical events for past bookings
    auth.seedEvents([
      {'id': 'evt_hist_001', 'organizerId': org1.id, 'title': 'Q4 Strategy Workshop', 'description': 'Internal Q4 planning session.', 'category': 'Corporate', 'start': pastStart1, 'end': pastEnd1, 'expectedAttendees': 100, 'status': 'published', 'bookingId': 'bk_007', 'createdAt': now.subtract(const Duration(days: 100))},
      {'id': 'evt_hist_002', 'organizerId': org3.id, 'title': 'Manchester Finance Roundtable', 'description': 'Regional finance networking roundtable.', 'category': 'Finance', 'start': pastStart2, 'end': pastEnd2, 'expectedAttendees': 60, 'status': 'published', 'bookingId': 'bk_008', 'createdAt': now.subtract(const Duration(days: 55))},
      {'id': 'evt_hist_003', 'organizerId': org2.id, 'title': 'Autumn Art Showcase', 'description': 'Showcase of autumn art collection.', 'category': 'Arts & Culture', 'start': futureDate(100, 10), 'end': futureDate(100, 14), 'expectedAttendees': 50, 'status': 'published', 'bookingId': null, 'createdAt': now.subtract(const Duration(days: 40))},
      {'id': 'evt_hist_004', 'organizerId': org2.id, 'title': 'Garden Party Fundraiser', 'description': 'Annual charity garden party fundraiser.', 'category': 'Charity', 'start': futureDate(130, 12), 'end': futureDate(130, 20), 'expectedAttendees': 150, 'status': 'published', 'bookingId': null, 'createdAt': now.subtract(const Duration(days: 20))},
    ]);

    // Mark approved bookings
    final bookingManagement = BookingManagementService();
    bookingManagement.seedApprovedIds(['bk_001', 'bk_002', 'bk_005', 'bk_007', 'bk_008']);

    // ─────────────────────────────────────────
    // 7. PAYMENTS
    // ─────────────────────────────────────────

    final payment = PaymentService();
    payment.seedPayments([
      PaymentModel(bookingId: 'bk_001', amount: 4050.0, status: PaymentStatus.paid, paidAt: now.subtract(const Duration(days: 50))),
      PaymentModel(bookingId: 'bk_002', amount: 750.0, status: PaymentStatus.paid, paidAt: now.subtract(const Duration(days: 20))),
      PaymentModel(bookingId: 'bk_003', amount: 1400.0),
      PaymentModel(bookingId: 'bk_004', amount: 280.0),
      PaymentModel(bookingId: 'bk_005', amount: 1280.0, status: PaymentStatus.paid, paidAt: now.subtract(const Duration(days: 40))),
      PaymentModel(bookingId: 'bk_006', amount: 450.0),
      PaymentModel(bookingId: 'bk_007', amount: 1440.0, status: PaymentStatus.paid, paidAt: now.subtract(const Duration(days: 85))),
      PaymentModel(bookingId: 'bk_008', amount: 1900.0, status: PaymentStatus.paid, paidAt: now.subtract(const Duration(days: 28))),
      PaymentModel(bookingId: 'bk_009', amount: 480.0, status: PaymentStatus.refunded, paidAt: now.subtract(const Duration(days: 32)), refundedAt: now.subtract(const Duration(days: 30))),
      PaymentModel(bookingId: 'bk_010', amount: 2000.0, status: PaymentStatus.refunded, paidAt: now.subtract(const Duration(days: 14)), refundedAt: now.subtract(const Duration(days: 12))),
    ]);

    // ─────────────────────────────────────────
    // 8. CHAT MESSAGES
    // ─────────────────────────────────────────

    final chat = ChatService();
    int msgCounter = 0;
    String mid() { msgCounter++; return 'msg_s${msgCounter.toString().padLeft(3, '0')}'; }

    // bk_001: Grand Ballroom booking – owner1 & org1 chat
    chat.seedMessages('bk_001', [
      MessageModel(id: mid(), bookingId: 'bk_001', senderId: org1.id, senderName: org1.fullName, isOwner: false, text: 'Hi Margaret, just wanted to confirm we\'re good for the 30th. We\'ll have around 450 guests.', timestamp: now.subtract(const Duration(days: 52))),
      MessageModel(id: mid(), bookingId: 'bk_001', senderId: owner1.id, senderName: owner1.fullName, isOwner: true, text: 'Hi Daniel, confirmed! Our team will be setting up from 7am. Please send over the final floor plan by the 25th.', timestamp: now.subtract(const Duration(days: 51))),
      MessageModel(id: mid(), bookingId: 'bk_001', senderId: org1.id, senderName: org1.fullName, isOwner: false, text: 'Will do! Also, can we arrange for AV rehearsal the evening before?', timestamp: now.subtract(const Duration(days: 50))),
      MessageModel(id: mid(), bookingId: 'bk_001', senderId: owner1.id, senderName: owner1.fullName, isOwner: true, text: 'Absolutely, we can give you access from 6pm on the 29th. No extra charge.', timestamp: now.subtract(const Duration(days: 49))),
      MessageModel(id: mid(), bookingId: 'bk_001', senderId: org1.id, senderName: org1.fullName, isOwner: false, text: 'That\'s fantastic, thank you! We\'re really excited about this event.', timestamp: now.subtract(const Duration(days: 48))),
    ]);

    // bk_002: Main Studio booking – owner1 & org1
    chat.seedMessages('bk_002', [
      MessageModel(id: mid(), bookingId: 'bk_002', senderId: org1.id, senderName: org1.fullName, isOwner: false, text: 'Hi Margaret, quick question about the Main Studio – is there a PA system included?', timestamp: now.subtract(const Duration(days: 22))),
      MessageModel(id: mid(), bookingId: 'bk_002', senderId: owner1.id, senderName: owner1.fullName, isOwner: true, text: 'Yes, a full PA system and wireless mics are included. Our tech team will be on site too.', timestamp: now.subtract(const Duration(days: 21))),
      MessageModel(id: mid(), bookingId: 'bk_002', senderId: org1.id, senderName: org1.fullName, isOwner: false, text: 'Perfect. We\'ll bring our own backdrop and branded materials. Is early access possible?', timestamp: now.subtract(const Duration(days: 20))),
      MessageModel(id: mid(), bookingId: 'bk_002', senderId: owner1.id, senderName: owner1.fullName, isOwner: true, text: 'We can open up from 12pm. I\'ll add a note to your booking.', timestamp: now.subtract(const Duration(days: 19))),
    ]);

    // bk_003: The Loft booking – owner3 & org2
    chat.seedMessages('bk_003', [
      MessageModel(id: mid(), bookingId: 'bk_003', senderId: org2.id, senderName: org2.fullName, isOwner: false, text: 'Hello Priya, we\'re so excited to be hosting the Bristol Arts Open at The Loft!', timestamp: now.subtract(const Duration(days: 38))),
      MessageModel(id: mid(), bookingId: 'bk_003', senderId: owner3.id, senderName: owner3.fullName, isOwner: true, text: 'We\'re thrilled to have you! The Loft is perfect for an arts event. Let me know if you need any staging help.', timestamp: now.subtract(const Duration(days: 37))),
      MessageModel(id: mid(), bookingId: 'bk_003', senderId: org2.id, senderName: org2.fullName, isOwner: false, text: 'Yes please! We\'d love to discuss a custom layout – we need wall mounting points for the exhibition pieces.', timestamp: now.subtract(const Duration(days: 36))),
      MessageModel(id: mid(), bookingId: 'bk_003', senderId: owner3.id, senderName: owner3.fullName, isOwner: true, text: 'We have picture rails throughout – no drilling needed. I\'ll send you our exhibition guide today.', timestamp: now.subtract(const Duration(days: 35))),
    ]);

    // bk_004: Collaboration Space – owner3 & org2
    chat.seedMessages('bk_004', [
      MessageModel(id: mid(), bookingId: 'bk_004', senderId: org2.id, senderName: org2.fullName, isOwner: false, text: 'Hi Priya, can the Collaboration Space accommodate a screening setup with a large projector?', timestamp: now.subtract(const Duration(days: 16))),
      MessageModel(id: mid(), bookingId: 'bk_004', senderId: owner3.id, senderName: owner3.fullName, isOwner: true, text: 'Yes! We have a 4K projector and a 120-inch screen. We can also supply a small bar setup for your networking section.', timestamp: now.subtract(const Duration(days: 15))),
      MessageModel(id: mid(), bookingId: 'bk_004', senderId: org2.id, senderName: org2.fullName, isOwner: false, text: 'A bar setup would be brilliant! What\'s the arrangement for that?', timestamp: now.subtract(const Duration(days: 14))),
    ]);

    // bk_005: Conference Room Alpha – owner2 & org3
    chat.seedMessages('bk_005', [
      MessageModel(id: mid(), bookingId: 'bk_005', senderId: org3.id, senderName: org3.fullName, isOwner: false, text: 'Hello James, we\'re finalising the delegate list for the Global Finance Forum. Are we still on?', timestamp: now.subtract(const Duration(days: 42))),
      MessageModel(id: mid(), bookingId: 'bk_005', senderId: owner2.id, senderName: owner2.fullName, isOwner: true, text: 'Absolutely! Everything is confirmed. Our catering team is ready and the AV will be tested the morning of the event.', timestamp: now.subtract(const Duration(days: 41))),
      MessageModel(id: mid(), bookingId: 'bk_005', senderId: org3.id, senderName: org3.fullName, isOwner: false, text: 'Great. We\'ll have three speakers with different tech setups. Can your team handle multiple laptop inputs?', timestamp: now.subtract(const Duration(days: 40))),
      MessageModel(id: mid(), bookingId: 'bk_005', senderId: owner2.id, senderName: owner2.fullName, isOwner: true, text: 'Yes, we have an HDMI switcher and adapters for USB-C, DisplayPort, and VGA. No problem at all.', timestamp: now.subtract(const Duration(days: 39))),
      MessageModel(id: mid(), bookingId: 'bk_005', senderId: org3.id, senderName: org3.fullName, isOwner: false, text: 'Outstanding. Looking forward to a successful event!', timestamp: now.subtract(const Duration(days: 38))),
    ]);

    // bk_006: Garden Studio – owner2 & org3
    chat.seedMessages('bk_006', [
      MessageModel(id: mid(), bookingId: 'bk_006', senderId: org3.id, senderName: org3.fullName, isOwner: false, text: 'Hi James, the Garden Studio looks perfect for the pitch competition. Can we set up a judges\' table at the front?', timestamp: now.subtract(const Duration(days: 18))),
      MessageModel(id: mid(), bookingId: 'bk_006', senderId: owner2.id, senderName: owner2.fullName, isOwner: true, text: 'Definitely! We\'ll arrange the furniture to your spec. Send us a layout diagram and we\'ll have it ready before you arrive.', timestamp: now.subtract(const Duration(days: 17))),
      MessageModel(id: mid(), bookingId: 'bk_006', senderId: org3.id, senderName: org3.fullName, isOwner: false, text: 'Brilliant. We\'ll also need a timer display for the pitchers. Is that something you can provide?', timestamp: now.subtract(const Duration(days: 16))),
    ]);

    // ─────────────────────────────────────────
    // 9. NOTIFICATIONS
    // ─────────────────────────────────────────

    final notif = NotificationService();
    int notifCounter = 0;
    String nid() { notifCounter++; return 'notif_s${notifCounter.toString().padLeft(3, '0')}'; }

    // Owner1 (Margaret) notifications
    notif.seedNotifications([
      NotificationModel(id: nid(), ownerId: owner1.id, title: 'New Booking Request', message: '"London Tech Summit 2026" by Daniel Webb is awaiting approval.', timestamp: now.subtract(const Duration(days: 55)), type: NotificationType.newBooking, bookingId: 'bk_001'),
      NotificationModel(id: nid(), ownerId: owner1.id, title: 'Booking Confirmed', message: '"London Tech Summit 2026" has been approved and confirmed.', timestamp: now.subtract(const Duration(days: 54)), type: NotificationType.bookingModified, bookingId: 'bk_001', isRead: true),
      NotificationModel(id: nid(), ownerId: owner1.id, title: 'New Booking Request', message: '"Product Launch: Nexus AI" by Daniel Webb is awaiting approval.', timestamp: now.subtract(const Duration(days: 25)), type: NotificationType.newBooking, bookingId: 'bk_002'),
      NotificationModel(id: nid(), ownerId: owner1.id, title: 'Payment Received', message: 'Payment of £4,050 received for "London Tech Summit 2026".', timestamp: now.subtract(const Duration(days: 50)), type: NotificationType.bookingModified, bookingId: 'bk_001', isRead: true),
      NotificationModel(id: nid(), ownerId: owner1.id, title: 'Upcoming Event Tomorrow', message: '"London Tech Summit 2026" in The Grand Ballroom at 9:00 AM.', timestamp: now.subtract(const Duration(days: 1)), type: NotificationType.reminder, bookingId: 'bk_001'),
      NotificationModel(id: nid(), ownerId: owner1.id, title: 'Booking Cancelled', message: '"Q4 Strategy Workshop" booking has been cancelled and refunded.', timestamp: now.subtract(const Duration(days: 30)), type: NotificationType.cancellation, bookingId: 'bk_009', isRead: true),
    ]);

    // Owner2 (James) notifications
    notif.seedNotifications([
      NotificationModel(id: nid(), ownerId: owner2.id, title: 'New Booking Request', message: '"Global Finance Forum" by Ahmed Karimi is awaiting approval.', timestamp: now.subtract(const Duration(days: 45)), type: NotificationType.newBooking, bookingId: 'bk_005'),
      NotificationModel(id: nid(), ownerId: owner2.id, title: 'Booking Confirmed', message: '"Global Finance Forum" has been approved and confirmed.', timestamp: now.subtract(const Duration(days: 44)), type: NotificationType.bookingModified, bookingId: 'bk_005', isRead: true),
      NotificationModel(id: nid(), ownerId: owner2.id, title: 'New Booking Request', message: '"Startup Pitch Competition" by Ahmed Karimi is awaiting approval.', timestamp: now.subtract(const Duration(days: 20)), type: NotificationType.newBooking, bookingId: 'bk_006'),
      NotificationModel(id: nid(), ownerId: owner2.id, title: 'Payment Received', message: 'Payment of £1,280 received for "Global Finance Forum".', timestamp: now.subtract(const Duration(days: 40)), type: NotificationType.bookingModified, bookingId: 'bk_005', isRead: true),
      NotificationModel(id: nid(), ownerId: owner2.id, title: 'Booking Cancelled', message: '"Garden Party Fundraiser" booking has been cancelled.', timestamp: now.subtract(const Duration(days: 12)), type: NotificationType.cancellation, bookingId: 'bk_010'),
      NotificationModel(id: nid(), ownerId: owner2.id, title: 'Upcoming Event Tomorrow', message: '"Global Finance Forum" in Conference Room Alpha at 9:00 AM.', timestamp: now.subtract(const Duration(days: 1)), type: NotificationType.reminder, bookingId: 'bk_005'),
      NotificationModel(id: nid(), ownerId: owner2.id, title: 'Booking Modified', message: '"Manchester Finance Roundtable" has been updated with new details.', timestamp: now.subtract(const Duration(days: 38)), type: NotificationType.bookingModified, bookingId: 'bk_008', isRead: true),
    ]);

    // Owner3 (Priya) notifications
    notif.seedNotifications([
      NotificationModel(id: nid(), ownerId: owner3.id, title: 'New Booking Request', message: '"Bristol Arts Open 2026" by Sophie Lawson is awaiting approval.', timestamp: now.subtract(const Duration(days: 40)), type: NotificationType.newBooking, bookingId: 'bk_003'),
      NotificationModel(id: nid(), ownerId: owner3.id, title: 'New Booking Request', message: '"Film Industry Networking Night" by Sophie Lawson is awaiting approval.', timestamp: now.subtract(const Duration(days: 18)), type: NotificationType.newBooking, bookingId: 'bk_004'),
      NotificationModel(id: nid(), ownerId: owner3.id, title: 'Payment Received', message: 'Payment of £1,400 pending for "Bristol Arts Open 2026".', timestamp: now.subtract(const Duration(days: 38)), type: NotificationType.bookingModified, bookingId: 'bk_003', isRead: true),
      NotificationModel(id: nid(), ownerId: owner3.id, title: 'Upcoming Event Tomorrow', message: '"Bristol Arts Open 2026" in The Loft at 11:00 AM.', timestamp: now.subtract(const Duration(days: 1)), type: NotificationType.reminder, bookingId: 'bk_003'),
      NotificationModel(id: nid(), ownerId: owner3.id, title: 'Booking Modified', message: '"Film Industry Networking Night" has been updated with new venue details.', timestamp: now.subtract(const Duration(days: 15)), type: NotificationType.bookingModified, bookingId: 'bk_004'),
    ]);

    // ─────────────────────────────────────────
    // 10. DOCUMENTS
    // ─────────────────────────────────────────

    final docs = DocumentService();
    int docCounter = 0;
    String did() { docCounter++; return 'doc_s${docCounter.toString().padLeft(3, '0')}'; }

    // Owner1 documents
    docs.seedDocuments([
      DocumentModel(id: did(), ownerId: owner1.id, name: 'Thornton Venues Trading License 2026', type: DocumentType.license, uploadedAt: now.subtract(const Duration(days: 300)), notes: 'Annual trading license issued by City of London Corporation. Valid until 31 Dec 2026.'),
      DocumentModel(id: did(), ownerId: owner1.id, name: 'Public Entertainment Permit – Grand Ballroom', type: DocumentType.permit, uploadedAt: now.subtract(const Duration(days: 200)), notes: 'Permit for events up to 500 persons. Includes alcohol licence.'),
      DocumentModel(id: did(), ownerId: owner1.id, name: 'Fire Safety Certificate 2025', type: DocumentType.certificate, uploadedAt: now.subtract(const Duration(days: 120)), notes: 'Issued by London Fire Brigade following annual inspection.'),
      DocumentModel(id: did(), ownerId: owner1.id, name: 'BREEAM Environmental Certificate', type: DocumentType.certificate, uploadedAt: now.subtract(const Duration(days: 365)), notes: 'BREEAM Excellent rating for sustainable building operations.'),
    ]);

    // Owner2 documents
    docs.seedDocuments([
      DocumentModel(id: did(), ownerId: owner2.id, name: 'Holloway Halls Business License', type: DocumentType.license, uploadedAt: now.subtract(const Duration(days: 280)), notes: 'Business license issued by Manchester City Council.'),
      DocumentModel(id: did(), ownerId: owner2.id, name: 'Premises Licence – Conference Centre', type: DocumentType.permit, uploadedAt: now.subtract(const Duration(days: 180)), notes: 'Licensed for regulated entertainment and supply of alcohol.'),
      DocumentModel(id: did(), ownerId: owner2.id, name: 'Health & Safety Certificate', type: DocumentType.certificate, uploadedAt: now.subtract(const Duration(days: 90)), notes: 'Issued following annual HSE inspection. All venues compliant.'),
      DocumentModel(id: did(), ownerId: owner2.id, name: 'Outdoor Events Permit – Garden Pavilion', type: DocumentType.permit, uploadedAt: now.subtract(const Duration(days: 150)), notes: 'Permit for outdoor events up to 200 persons in Piccadilly Gardens.'),
      DocumentModel(id: did(), ownerId: owner2.id, name: 'Public Liability Insurance 2026', type: DocumentType.certificate, uploadedAt: now.subtract(const Duration(days: 60)), notes: 'Public liability coverage up to £10M. Policy number: PLI-2026-HH-449.'),
    ]);

    // Owner3 documents
    docs.seedDocuments([
      DocumentModel(id: did(), ownerId: owner3.id, name: 'Nair Creative Spaces Business License', type: DocumentType.license, uploadedAt: now.subtract(const Duration(days: 250)), notes: 'Business license issued by Bristol City Council. Valid 2026.'),
      DocumentModel(id: did(), ownerId: owner3.id, name: 'Temporary Events Notice – Rooftop', type: DocumentType.permit, uploadedAt: now.subtract(const Duration(days: 100)), notes: 'TEN for rooftop events, maximum capacity 80 persons.'),
      DocumentModel(id: did(), ownerId: owner3.id, name: 'Accessibility Compliance Certificate', type: DocumentType.certificate, uploadedAt: now.subtract(const Duration(days: 80)), notes: 'All public spaces meet BS 8300 accessibility standards.'),
      DocumentModel(id: did(), ownerId: owner3.id, name: 'Arts Council Accreditation', type: DocumentType.certificate, uploadedAt: now.subtract(const Duration(days: 180)), notes: 'Accredited Creative Space Partner by Arts Council England.'),
    ]);

    // ─────────────────────────────────────────
    // 11. ATTENDEE REGISTRATIONS
    // ─────────────────────────────────────────

    final reg = RegistrationService();
    int regCounter = 0;
    String rid() { regCounter++; return 'reg_s${regCounter.toString().padLeft(3, '0')}'; }

    reg.seedRegistrations([
      // Laura (att1) – tech & finance
      {'id': rid(), 'eventId': 'evt_001', 'attendeeId': att1.id, 'attendeeName': att1.fullName, 'attendeeEmail': att1.email, 'registeredAt': now.subtract(const Duration(days: 28)), 'attended': false, 'notes': ''},
      {'id': rid(), 'eventId': 'evt_009', 'attendeeId': att1.id, 'attendeeName': att1.fullName, 'attendeeEmail': att1.email, 'registeredAt': now.subtract(const Duration(days: 20)), 'attended': false, 'notes': ''},
      {'id': rid(), 'eventId': 'evt_002', 'attendeeId': att1.id, 'attendeeName': att1.fullName, 'attendeeEmail': att1.email, 'registeredAt': now.subtract(const Duration(days: 12)), 'attended': false, 'notes': 'Interested in enterprise AI tools'},
      // Past event attended
      {'id': rid(), 'eventId': 'evt_003', 'attendeeId': att1.id, 'attendeeName': att1.fullName, 'attendeeEmail': att1.email, 'registeredAt': now.subtract(const Duration(days: 60)), 'attended': true, 'notes': 'Excellent session'},

      // Nathan (att2) – arts & culture
      {'id': rid(), 'eventId': 'evt_005', 'attendeeId': att2.id, 'attendeeName': att2.fullName, 'attendeeEmail': att2.email, 'registeredAt': now.subtract(const Duration(days: 25)), 'attended': false, 'notes': ''},
      {'id': rid(), 'eventId': 'evt_006', 'attendeeId': att2.id, 'attendeeName': att2.fullName, 'attendeeEmail': att2.email, 'registeredAt': now.subtract(const Duration(days: 15)), 'attended': false, 'notes': ''},
      {'id': rid(), 'eventId': 'evt_001', 'attendeeId': att2.id, 'attendeeName': att2.fullName, 'attendeeEmail': att2.email, 'registeredAt': now.subtract(const Duration(days: 22)), 'attended': false, 'notes': ''},
      // Past event attended
      {'id': rid(), 'eventId': 'evt_007', 'attendeeId': att2.id, 'attendeeName': att2.fullName, 'attendeeEmail': att2.email, 'registeredAt': now.subtract(const Duration(days: 30)), 'attended': true, 'notes': 'Really enjoyed the workshop'},

      // Chloe (att3) – business & networking
      {'id': rid(), 'eventId': 'evt_001', 'attendeeId': att3.id, 'attendeeName': att3.fullName, 'attendeeEmail': att3.email, 'registeredAt': now.subtract(const Duration(days: 30)), 'attended': false, 'notes': ''},
      {'id': rid(), 'eventId': 'evt_006', 'attendeeId': att3.id, 'attendeeName': att3.fullName, 'attendeeEmail': att3.email, 'registeredAt': now.subtract(const Duration(days: 18)), 'attended': false, 'notes': 'Interested in distribution'},
      {'id': rid(), 'eventId': 'evt_005', 'attendeeId': att3.id, 'attendeeName': att3.fullName, 'attendeeEmail': att3.email, 'registeredAt': now.subtract(const Duration(days: 10)), 'attended': false, 'notes': ''},

      // Ravi (att4) – entrepreneurship & finance
      {'id': rid(), 'eventId': 'evt_001', 'attendeeId': att4.id, 'attendeeName': att4.fullName, 'attendeeEmail': att4.email, 'registeredAt': now.subtract(const Duration(days: 35)), 'attended': false, 'notes': ''},
      {'id': rid(), 'eventId': 'evt_009', 'attendeeId': att4.id, 'attendeeName': att4.fullName, 'attendeeEmail': att4.email, 'registeredAt': now.subtract(const Duration(days: 22)), 'attended': false, 'notes': ''},
      {'id': rid(), 'eventId': 'evt_010', 'attendeeId': att4.id, 'attendeeName': att4.fullName, 'attendeeEmail': att4.email, 'registeredAt': now.subtract(const Duration(days: 14)), 'attended': false, 'notes': 'Pitching our edtech startup'},
      {'id': rid(), 'eventId': 'evt_002', 'attendeeId': att4.id, 'attendeeName': att4.fullName, 'attendeeEmail': att4.email, 'registeredAt': now.subtract(const Duration(days: 8)), 'attended': false, 'notes': ''},
    ]);
  }
}
