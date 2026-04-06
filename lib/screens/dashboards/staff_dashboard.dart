import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/venue_service.dart';
import '../../services/analytics_service.dart';
import '../../services/notification_service.dart';
import '../../models/user_model.dart';
import '../../models/building_model.dart';
import '../../models/analytics_model.dart';
import '../profile_screen.dart';
import '../landing_screen.dart';
import 'venue/widgets/building_card.dart';
import 'venue/widgets/map_view.dart';
import 'venue/widgets/analytics_cards.dart';
import 'venue/widgets/revenue_chart.dart';
import 'venue/widgets/booking_list.dart';
import 'venue/widgets/calendar_view.dart';
import 'venue/widgets/notification_list.dart';
import 'venue/widgets/document_list.dart';
import 'venue/sheets/add_building_sheet.dart';
import 'venue/rooms_screen.dart';

class StaffDashboard extends StatefulWidget {
  const StaffDashboard({super.key});

  @override
  State<StaffDashboard> createState() => _StaffDashboardState();
}

class _StaffDashboardState extends State<StaffDashboard>
    with SingleTickerProviderStateMixin {
  final _auth = AuthService();
  final _svc = VenueService();
  bool _redirecting = false;
  late TabController _tabController;

  static const _tabs = [
    _TabItem(Icons.dashboard_outlined, 'Overview'),
    _TabItem(Icons.bar_chart_rounded, 'Analytics'),
    _TabItem(Icons.inbox_outlined, 'Bookings'),
    _TabItem(Icons.calendar_month_outlined, 'Calendar'),
    _TabItem(Icons.forum_outlined, 'Comms'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _guardAuth();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _guardAuth() {
    final user = _auth.currentUser;
    if (_redirecting) return;
    if (user == null || user.role != UserRole.staff) {
      _redirecting = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LandingScreen()),
          (r) => false,
        );
      });
    }
  }

  void _refresh() => setState(() {});

  void _showAddBuilding({BuildingModel? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AddBuildingSheet(
        ownerId: _auth.currentUser!.id,
        existing: existing,
        onSaved: _refresh,
      ),
    );
  }

  void _deleteBuilding(BuildingModel building) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Building',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Delete "${building.name}"? All rooms and their data will be removed.',
          style: const TextStyle(color: Color(0xFF6B6B6B), fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF6B6B6B)),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A1A1A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              final err =
                  _svc.deleteBuilding(building.id, _auth.currentUser!.id);
              Navigator.pop(context);
              if (err != null) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(err)));
                return;
              }
              _refresh();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _viewRooms(BuildingModel building) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RoomsScreen(
          building: building,
          ownerId: _auth.currentUser!.id,
        ),
      ),
    ).then((_) => _refresh());
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser!;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: _buildAppBar(user),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _OverviewTab(
            user: user,
            svc: _svc,
            auth: _auth,
            onRefresh: _refresh,
            onShowAddBuilding: _showAddBuilding,
            onDeleteBuilding: _deleteBuilding,
            onViewRooms: _viewRooms,
          ),
          _AnalyticsTab(ownerId: user.id),
          _BookingsTab(ownerId: user.id, ownerName: user.fullName),
          _CalendarTab(ownerId: user.id),
          _CommsTab(ownerId: user.id),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(UserModel user) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(145),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(color: Color(0xFFE8E8E8), width: 1),
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Venue Owner',
                            style: TextStyle(
                              color: Color(0xFF1A1A1A),
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            user.fullName,
                            style: const TextStyle(
                                color: Color(0xFF6B6B6B),
                                fontSize: 13,
                                fontWeight: FontWeight.w400),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    _AppBarIconBtn(
                      icon: Icons.person_outline,
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ProfileScreen()),
                      ).then((_) => _refresh()),
                    ),
                    const SizedBox(width: 2),
                    _AppBarIconBtn(
                      icon: Icons.logout_rounded,
                      onPressed: () {
                        _auth.logout();
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const LandingScreen()),
                          (r) => false,
                        );
                      },
                    ),
                  ],
                ),
              ),
              TabBar(
                controller: _tabController,
                isScrollable: false,
                indicatorColor: const Color(0xFF1A1A1A),
                indicatorWeight: 2,
                indicatorSize: TabBarIndicatorSize.label,
                labelColor: const Color(0xFF1A1A1A),
                unselectedLabelColor: const Color(0xFF9B9B9B),
                labelStyle: const TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w600),
                unselectedLabelStyle: const TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w400),
                tabs: _tabs
                    .asMap()
                    .entries
                    .map((entry) {
                  final i = entry.key;
                  final t = entry.value;
                  final isComms = i == 4;
                  final unread = isComms
                      ? NotificationService().unreadCount(user.id)
                      : 0;
                  return Tab(
                    iconMargin: const EdgeInsets.only(bottom: 2),
                    text: t.label,
                    icon: isComms && unread > 0
                        ? Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Icon(t.icon, size: 18),
                              Positioned(
                                top: -4,
                                right: -6,
                                child: Container(
                                  width: 14,
                                  height: 14,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF1A1A1A),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      unread > 9 ? '9+' : '$unread',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 8,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Icon(t.icon, size: 18),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppBarIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  const _AppBarIconBtn({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: const Color(0xFF1A1A1A), size: 20),
        ),
      ),
    );
  }
}

class _TabItem {
  final IconData icon;
  final String label;
  const _TabItem(this.icon, this.label);
}

// ─── OVERVIEW TAB ──────────────────────────────────────────────────────────

class _OverviewTab extends StatefulWidget {
  final UserModel user;
  final VenueService svc;
  final AuthService auth;
  final VoidCallback onRefresh;
  final void Function({BuildingModel? existing}) onShowAddBuilding;
  final void Function(BuildingModel) onDeleteBuilding;
  final void Function(BuildingModel) onViewRooms;

  const _OverviewTab({
    required this.user,
    required this.svc,
    required this.auth,
    required this.onRefresh,
    required this.onShowAddBuilding,
    required this.onDeleteBuilding,
    required this.onViewRooms,
  });

  @override
  State<_OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<_OverviewTab> {
  bool _mapExpanded = true;

  @override
  Widget build(BuildContext context) {
    final buildings = widget.svc.buildingsForOwner(widget.user.id);
    final totalRooms = buildings.fold<int>(
        0, (sum, b) => sum + widget.svc.roomsForBuilding(b.id).length);
    final totalBookings = widget.auth.allBookings.length;

    return RefreshIndicator(
      color: const Color(0xFF1A1A1A),
      onRefresh: () async => widget.onRefresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcome(),
            const SizedBox(height: 20),
            _buildStatCards(buildings.length, totalRooms, totalBookings),
            const SizedBox(height: 24),
            _buildMapSection(buildings),
            const SizedBox(height: 24),
            _buildSectionHeader(
              'Buildings',
              trailing: ElevatedButton.icon(
                onPressed: () => widget.onShowAddBuilding(),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Building'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A1A1A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 9),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  textStyle: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 14),
            if (buildings.isEmpty)
              _buildEmptyBuildings()
            else
              ...buildings.map((b) => BuildingCard(
                    building: b,
                    roomCount: widget.svc.roomsForBuilding(b.id).length,
                    onViewRooms: () => widget.onViewRooms(b),
                    onEdit: () => widget.onShowAddBuilding(existing: b),
                    onDelete: () => widget.onDeleteBuilding(b),
                  )),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcome() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hi, ${widget.user.fullName.split(' ').first}',
          style: const TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Manage your venues, analytics, and bookings',
          style: TextStyle(
              color: Color(0xFF9B9B9B),
              fontSize: 14,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.1),
        ),
      ],
    );
  }

  Widget _buildStatCards(int buildings, int rooms, int bookings) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.apartment_outlined,
            value: '$buildings',
            label: 'Buildings',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.meeting_room_outlined,
            value: '$rooms',
            label: 'Rooms',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.book_online_outlined,
            value: '$bookings',
            label: 'Bookings',
          ),
        ),
      ],
    );
  }

  Widget _buildMapSection(List<BuildingModel> buildings) {
    final locatedCount = buildings.where((b) => b.hasLocation).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Map View',
              style: TextStyle(
                color: Color(0xFF1A1A1A),
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFEEEEEE),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$locatedCount located',
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF6B6B6B),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Spacer(),
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () =>
                  setState(() => _mapExpanded = !_mapExpanded),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    Text(
                      _mapExpanded ? 'Collapse' : 'Expand',
                      style: const TextStyle(
                          color: Color(0xFF6B6B6B),
                          fontSize: 12,
                          fontWeight: FontWeight.w500),
                    ),
                    Icon(
                      _mapExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: const Color(0xFF9B9B9B),
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (_mapExpanded) ...[
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 300,
              child: BuildingsMapView(
                buildings: buildings,
                venueService: widget.svc,
                onBuildingTap: widget.onViewRooms,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title, {Widget? trailing}) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 17,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
        const Spacer(),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _buildEmptyBuildings() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 56),
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFEEEEEE),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.apartment_outlined,
                  size: 36, color: Color(0xFF9B9B9B)),
            ),
            const SizedBox(height: 16),
            const Text(
              'No buildings yet',
              style: TextStyle(
                color: Color(0xFF1A1A1A),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Add your first building to get started.',
              style: TextStyle(color: Color(0xFF9B9B9B), fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => widget.onShowAddBuilding(),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Building'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A1A1A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── ANALYTICS TAB ─────────────────────────────────────────────────────────

class _AnalyticsTab extends StatefulWidget {
  final String ownerId;
  const _AnalyticsTab({required this.ownerId});

  @override
  State<_AnalyticsTab> createState() => _AnalyticsTabState();
}

class _AnalyticsTabState extends State<_AnalyticsTab> {
  late AnalyticsSnapshot _snapshot;

  @override
  void initState() {
    super.initState();
    _snapshot = AnalyticsService.compute(widget.ownerId);
  }

  void _reload() {
    setState(() {
      _snapshot = AnalyticsService.compute(widget.ownerId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: const Color(0xFF1A1A1A),
      onRefresh: () async => _reload(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader('Revenue Trends'),
            const SizedBox(height: 14),
            BookingsTrendChart(dailyBookings: _snapshot.dailyBookings),
            WeeklyRevenueChart(weeklyRevenue: _snapshot.weeklyRevenue),
            MonthlyRevenueChart(monthlyRevenue: _snapshot.monthlyRevenue),
            const SizedBox(height: 24),
            const Divider(color: Color(0xFFE8E8E8), height: 1),
            const SizedBox(height: 24),
            _sectionHeader('Metrics & Insights'),
            const SizedBox(height: 14),
            AnalyticsOverviewCards(data: _snapshot),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFF1A1A1A),
        fontSize: 17,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
    );
  }
}

// ─── BOOKINGS TAB ──────────────────────────────────────────────────────────

class _BookingsTab extends StatelessWidget {
  final String ownerId;
  final String ownerName;
  const _BookingsTab(
      {required this.ownerId, this.ownerName = 'Staff'});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: const Color(0xFF1A1A1A),
      onRefresh: () async {},
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Booking Inbox',
              style: TextStyle(
                color: Color(0xFF1A1A1A),
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Review, approve, and manage all bookings',
              style: TextStyle(
                  color: Color(0xFF6B6B6B),
                  fontSize: 13,
                  fontWeight: FontWeight.w400),
            ),
            const SizedBox(height: 20),
            BookingListView(ownerId: ownerId, ownerName: ownerName),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ─── CALENDAR TAB ──────────────────────────────────────────────────────────

class _CalendarTab extends StatelessWidget {
  final String ownerId;
  const _CalendarTab({required this.ownerId});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Schedule Calendar',
            style: TextStyle(
              color: Color(0xFF1A1A1A),
              fontSize: 17,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Visual overview of all room bookings',
            style: TextStyle(
                color: Color(0xFF6B6B6B),
                fontSize: 13,
                fontWeight: FontWeight.w400),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE8E8E8)),
            ),
            child: VenueCalendarView(ownerId: ownerId),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ─── COMMUNICATIONS TAB ────────────────────────────────────────────────────

class _CommsTab extends StatefulWidget {
  final String ownerId;
  const _CommsTab({required this.ownerId});

  @override
  State<_CommsTab> createState() => _CommsTabState();
}

class _CommsTabState extends State<_CommsTab>
    with SingleTickerProviderStateMixin {
  late TabController _innerTab;

  @override
  void initState() {
    super.initState();
    _innerTab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _innerTab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: Color(0xFFE8E8E8), width: 1),
            ),
          ),
          child: TabBar(
            controller: _innerTab,
            indicatorColor: const Color(0xFF1A1A1A),
            indicatorWeight: 2,
            indicatorSize: TabBarIndicatorSize.label,
            labelColor: const Color(0xFF1A1A1A),
            unselectedLabelColor: const Color(0xFF9B9B9B),
            labelStyle:
                const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            unselectedLabelStyle:
                const TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
            tabs: const [
              Tab(text: 'Notifications'),
              Tab(text: 'Documents'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _innerTab,
            children: [
              RefreshIndicator(
                color: const Color(0xFF1A1A1A),
                onRefresh: () async => setState(() {}),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: NotificationListView(ownerId: widget.ownerId),
                ),
              ),
              RefreshIndicator(
                color: const Color(0xFF1A1A1A),
                onRefresh: () async => setState(() {}),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: DocumentListView(ownerId: widget.ownerId),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── SHARED WIDGETS ────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF1A1A1A),
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.0,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(
                color: Color(0xFF9B9B9B),
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.1),
          ),
        ],
      ),
    );
  }
}
