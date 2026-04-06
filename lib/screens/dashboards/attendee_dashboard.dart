import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../../models/notification_model.dart';
import '../profile_screen.dart';
import '../unified_auth_sheet.dart';
import '../landing_screen.dart';
import '../../models/user_model.dart';
import 'organizer_dashboard.dart';
import 'staff_dashboard.dart';
import 'super_admin_dashboard.dart';
import 'tabs/attendee_calendar_tab.dart';
import 'tabs/attendee_map_tab.dart';
import 'tabs/attendee_notifications_tab.dart';
import 'tabs/attendee_analytics_tab.dart';

// ── Shared helpers ────────────────────────────────────────────────────────────

const _categoryColors = <String, Color>{
  'Technology':     Color(0xFF1565C0),
  'Business':       Color(0xFF2E7D32),
  'Arts & Culture': Color(0xFF6A1B9A),
  'Education':      Color(0xFFE65100),
  'Workshop':       Color(0xFF00695C),
  'Seminar':        Color(0xFF4527A0),
  'Conference':     Color(0xFF283593),
  'Networking':     Color(0xFF37474F),
  'Health':         Color(0xFFC62828),
  'Finance':        Color(0xFF558B2F),
};

Color _categoryColor(String cat) =>
    _categoryColors[cat] ?? const Color(0xFF2D2D2D);

enum _TimeFilter { all, today, thisWeek, thisMonth }

const _timeFilterLabels = {
  _TimeFilter.all:       'All',
  _TimeFilter.today:     'Today',
  _TimeFilter.thisWeek:  'This Week',
  _TimeFilter.thisMonth: 'This Month',
};

// ── Dashboard ─────────────────────────────────────────────────────────────────

class AttendeeDashboard extends StatefulWidget {
  const AttendeeDashboard({super.key});

  @override
  State<AttendeeDashboard> createState() => _AttendeeDashboardState();
}

class _AttendeeDashboardState extends State<AttendeeDashboard>
    with SingleTickerProviderStateMixin {
  final _auth = AuthService();
  final _notif = NotificationService();

  final Set<String> _registeredIds = {};
  Map<String, dynamic>? _pendingRegistrationEvent;

  // Events tab filters
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategory;
  String? _selectedOrganizerId;
  _TimeFilter _timeFilter = _TimeFilter.all;

  late final TabController _tabCtrl;
  static const _tabs = ['Events', 'Calendar', 'Map', 'Alerts', 'Analytics'];
  static const _tabIcons = [
    Icons.event_outlined,
    Icons.calendar_month_outlined,
    Icons.map_outlined,
    Icons.notifications_outlined,
    Icons.bar_chart_outlined,
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _tabs.length, vsync: this);
    _tabCtrl.addListener(() => setState(() {}));
    _searchCtrl.addListener(() =>
        setState(() => _searchQuery = _searchCtrl.text.trim().toLowerCase()));
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────

  String _organizerName(Map<String, dynamic> event) {
    final orgId = event['organizerId'] as String? ?? '';
    final match = _auth.allUsers.where((u) => u.id == orgId).toList();
    return match.isNotEmpty ? match.first.fullName : '';
  }

  String _locationLabel(Map<String, dynamic> event) {
    final bookingId = event['bookingId'] as String?;
    if (bookingId == null) return '';
    final booking =
        _auth.allBookings.where((b) => b['id'] == bookingId).toList();
    if (booking.isEmpty) return '';
    final roomId = booking.first['roomId'] as String? ?? '';
    final rooms = _auth.allRooms.where((r) => r['id'] == roomId).toList();
    if (rooms.isEmpty) return '';
    final room = rooms.first;
    final buildingId = room['buildingId'] as String? ?? '';
    final buildings =
        _auth.allBuildings.where((b) => b['id'] == buildingId).toList();
    final buildingName =
        buildings.isNotEmpty ? buildings.first['name'] as String : '';
    final roomName = room['name'] as String? ?? '';
    if (buildingName.isEmpty && roomName.isEmpty) return '';
    if (buildingName.isEmpty) return roomName;
    if (roomName.isEmpty) return buildingName;
    return '$buildingName · $roomName';
  }

  String _formatDate(DateTime dt) {
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  // ── Filtering ─────────────────────────────────────────────

  List<Map<String, dynamic>> _applyFilters(List<Map<String, dynamic>> events) {
    final now = DateTime.now();
    return events.where((e) {
      if ((e['status'] as String? ?? '') != 'published') return false;
      final title = (e['title'] as String? ?? '').toLowerCase();
      if (_searchQuery.isNotEmpty && !title.contains(_searchQuery)) return false;
      final cat = (e['category'] as String? ?? '');
      if (_selectedCategory != null && _selectedCategory != cat) return false;
      final orgId = (e['organizerId'] as String? ?? '');
      if (_selectedOrganizerId != null && _selectedOrganizerId != orgId) return false;
      final start = e['start'] as DateTime?;
      if (start != null) {
        switch (_timeFilter) {
          case _TimeFilter.today:
            if (start.day != now.day || start.month != now.month || start.year != now.year) return false;
            break;
          case _TimeFilter.thisWeek:
            final weekEnd = now.add(const Duration(days: 7));
            if (start.isBefore(now) || start.isAfter(weekEnd)) return false;
            break;
          case _TimeFilter.thisMonth:
            if (start.month != now.month || start.year != now.year) return false;
            break;
          case _TimeFilter.all:
            break;
        }
      }
      return true;
    }).toList()
      ..sort((a, b) {
        final sa = a['start'] as DateTime?;
        final sb = b['start'] as DateTime?;
        if (sa == null && sb == null) return 0;
        if (sa == null) return 1;
        if (sb == null) return -1;
        return sa.compareTo(sb);
      });
  }

  // ── Double-booking check ──────────────────────────────────

  Map<String, dynamic>? _conflictingEvent(Map<String, dynamic> newEvent) {
    final newStart = newEvent['start'] as DateTime?;
    final newEnd = newEvent['end'] as DateTime?;
    if (newStart == null || newEnd == null) return null;
    for (final regId in _registeredIds) {
      final regEvents = _auth.allEvents.where((e) => e['id'] == regId).toList();
      if (regEvents.isEmpty) continue;
      final reg = regEvents.first;
      final regStart = reg['start'] as DateTime?;
      final regEnd = reg['end'] as DateTime?;
      if (regStart == null || regEnd == null) continue;
      if (newStart.isBefore(regEnd) && newEnd.isAfter(regStart)) return reg;
    }
    return null;
  }

  // ── Registration ──────────────────────────────────────────

  Future<void> _toggleRegistration(Map<String, dynamic> event) async {
    if (!_auth.isLoggedIn) {
      _pendingRegistrationEvent = event;
      final ok = await UnifiedAuthSheet.show(
        context,
        intent: AuthIntent.attendeeRegister,
        defaultRole: UserRole.attendee,
      );
      if (!ok || !_auth.isLoggedIn) return;
      final pending = _pendingRegistrationEvent;
      _pendingRegistrationEvent = null;
      if (pending != null) _doRegister(pending);
      return;
    }
    _doRegister(event);
  }

  void _doRegister(Map<String, dynamic> event) {
    final id = event['id'] as String;
    if (_registeredIds.contains(id)) {
      setState(() => _registeredIds.remove(id));
      _showSnack('Unregistered from "${event['title']}".');
      return;
    }
    final conflict = _conflictingEvent(event);
    if (conflict != null) {
      _showConflictDialog(event, conflict);
      return;
    }
    setState(() => _registeredIds.add(id));
    _showSnack('Registered for "${event['title']}"!');

    // Attendee notification
    if (_auth.isLoggedIn) {
      final uid = _auth.currentUser!.id;
      final start = event['start'] as DateTime?;
      _notif.addNotification(
        ownerId: uid,
        title: 'Registration Confirmed',
        message: 'You\'re registered for "${event['title']}"'
            '${start != null ? ' on ${_formatDate(start)} at ${_formatTime(start)}' : ''}.',
        type: NotificationType.eventRegistered,
      );
    }
  }

  void _showConflictDialog(
      Map<String, dynamic> newEvent, Map<String, dynamic> existing) {
    final existingStart = existing['start'] as DateTime?;
    final existingEnd = existing['end'] as DateTime?;
    final timeStr = existingStart != null && existingEnd != null
        ? '${_formatTime(existingStart)} – ${_formatTime(existingEnd)} on ${_formatDate(existingStart)}'
        : '';

    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFFFFFFFF),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFF1A1A1A), size: 22),
            SizedBox(width: 8),
            Text(
              'Time Conflict',
              style: TextStyle(
                color: Color(0xFF1A1A1A),
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'You are already registered for another event at this time. Please select a different event.',
              style: TextStyle(color: Color(0xFF1A1A1A), height: 1.5),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE0E0E0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    existing['title'] as String? ?? '',
                    style: const TextStyle(
                      color: Color(0xFF1A1A1A),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  if (timeStr.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.schedule_outlined,
                            size: 13, color: Color(0xFF6B6B6B)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            timeStr,
                            style: const TextStyle(
                                color: Color(0xFF6B6B6B), fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Got it',
              style: TextStyle(
                  color: Color(0xFF2D2D2D), fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFF2D2D2D),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ── Event detail sheet ────────────────────────────────────

  void _showEventDetail(Map<String, dynamic> e) {
    final category = (e['category'] as String? ?? '');
    final catColor = _categoryColor(category);
    final start = e['start'] as DateTime?;
    final end = e['end'] as DateTime?;
    final location = _locationLabel(e);
    final organizer = _organizerName(e);
    final description = (e['description'] as String? ?? '');
    final capacity = e['expectedAttendees'] as int? ?? 0;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFFFFFFF),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) {
          final isReg = _registeredIds.contains(e['id'] as String);
          return DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (_, ctrl) => SingleChildScrollView(
              controller: ctrl,
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8E8E8),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: catColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      category.isEmpty ? 'Event' : category,
                      style: TextStyle(
                          color: catColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    e['title'] as String? ?? '',
                    style: const TextStyle(
                      color: Color(0xFF1A1A1A),
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (start != null)
                    _detailRow(Icons.schedule_outlined,
                        '${_formatDate(start)}${end != null ? ', ${_formatTime(start)} – ${_formatTime(end)}' : ''}'),
                  if (location.isNotEmpty)
                    _detailRow(Icons.location_on_outlined, location),
                  if (organizer.isNotEmpty)
                    _detailRow(Icons.person_outline, 'Organised by $organizer'),
                  if (capacity > 0)
                    _detailRow(Icons.people_outline, '$capacity expected attendees'),
                  const SizedBox(height: 16),
                  if (description.isNotEmpty) ...[
                    const Text(
                      'About this event',
                      style: TextStyle(
                        color: Color(0xFF1A1A1A),
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: const TextStyle(
                        color: Color(0xFF4A4A4A),
                        height: 1.6,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _toggleRegistration(e);
                        setS(() {});
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isReg
                            ? const Color(0xFFF5F5F5)
                            : const Color(0xFF1A1A1A),
                        foregroundColor:
                            isReg ? const Color(0xFF1A1A1A) : Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: isReg
                              ? const BorderSide(color: Color(0xFFE0E0E0))
                              : BorderSide.none,
                        ),
                      ),
                      child: Text(
                        isReg
                            ? 'Unregister from this event'
                            : 'Register for this event',
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _detailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF6B6B6B), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    color: Color(0xFF4A4A4A), fontSize: 13)),
          ),
        ],
      ),
    );
  }

  // ── Navigation ────────────────────────────────────────────

  void _goToMyDashboard() {
    final u = _auth.currentUser;
    if (u == null) return;
    Widget screen;
    switch (u.role) {
      case UserRole.attendee:
        screen = const AttendeeDashboard();
        break;
      case UserRole.organizer:
        screen = const OrganizerDashboard();
        break;
      case UserRole.staff:
        screen = const StaffDashboard();
        break;
      case UserRole.superAdmin:
        screen = const SuperAdminDashboard();
        break;
    }
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => screen),
      (r) => false,
    );
  }

  Future<void> _handleAuthFromLanding() async {
    if (!_auth.isLoggedIn) return;
    final u = _auth.currentUser;
    if (u == null) return;
    if (u.role == UserRole.attendee) {
      setState(() {});
      return;
    }
    _goToMyDashboard();
  }

  // ── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final unreadCount = _auth.isLoggedIn
        ? _notif.unreadCount(_auth.currentUser!.id)
        : 0;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // ── Tab bar ──────────────────────────────────────
          Container(
            color: const Color(0xFFFFFFFF),
            child: TabBar(
              controller: _tabCtrl,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: const Color(0xFF1A1A1A),
              unselectedLabelColor: const Color(0xFF9E9E9E),
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
              indicator: const UnderlineTabIndicator(
                borderSide:
                    BorderSide(color: Color(0xFF1A1A1A), width: 2.5),
              ),
              indicatorSize: TabBarIndicatorSize.label,
              tabs: List.generate(_tabs.length, (i) {
                final isNotif = i == 3;
                return Tab(
                  height: 44,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_tabIcons[i], size: 14),
                      const SizedBox(width: 5),
                      Text(_tabs[i]),
                      if (isNotif && unreadCount > 0) ...[
                        const SizedBox(width: 4),
                        Container(
                          width: 16,
                          height: 16,
                          decoration: const BoxDecoration(
                            color: Color(0xFF1A1A1A),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              unreadCount > 9 ? '9+' : '$unreadCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }),
            ),
          ),

          // ── Tab views ─────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                // 0 — Events
                _eventsTab(),

                // 1 — Calendar
                SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: AttendeeCalendarTab(
                    registeredIds: _registeredIds,
                    onToggleRegistration: _toggleRegistration,
                    onEventTap: _showEventDetail,
                    locationLabel: _locationLabel,
                    organizerName: _organizerName,
                  ),
                ),

                // 2 — Map
                SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: AttendeeMapTab(
                    registeredIds: _registeredIds,
                    onToggleRegistration: _toggleRegistration,
                    onEventTap: _showEventDetail,
                    locationLabel: _locationLabel,
                    organizerName: _organizerName,
                  ),
                ),

                // 3 — Notifications
                SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: AttendeeNotificationsTab(
                    registeredIds: _registeredIds,
                    onEventTap: _showEventDetail,
                  ),
                ),

                // 4 — Analytics
                SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: AttendeeAnalyticsTab(
                    registeredIds: _registeredIds,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFFFFFFFF),
      elevation: 0,
      title: const Text(
        'EventFlow',
        style: TextStyle(
          color: Color(0xFF1A1A1A),
          fontWeight: FontWeight.w800,
          fontSize: 18,
        ),
      ),
      actions: [
        if (!_auth.isLoggedIn) ...[
          TextButton(
            onPressed: () async {
              final ok = await UnifiedAuthSheet.show(
                context,
                intent: AuthIntent.generic,
                defaultRole: UserRole.attendee,
              );
              if (!ok) return;
              await _handleAuthFromLanding();
            },
            child: const Text(
              'Login',
              style: TextStyle(
                  color: Color(0xFF1A1A1A), fontWeight: FontWeight.w600),
            ),
          ),
          TextButton(
            onPressed: () async {
              final ok = await UnifiedAuthSheet.show(
                context,
                intent: AuthIntent.generic,
                defaultRole: UserRole.attendee,
              );
              if (!ok) return;
              await _handleAuthFromLanding();
            },
            child: const Text(
              'Sign up',
              style: TextStyle(
                  color: Color(0xFF1A1A1A), fontWeight: FontWeight.w600),
            ),
          ),
        ] else ...[
          TextButton(
            onPressed: _goToMyDashboard,
            child: const Text(
              'Dashboard',
              style: TextStyle(
                  color: Color(0xFF1A1A1A), fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline, color: Color(0xFF1A1A1A)),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ).then((_) => setState(() {})),
          ),
          TextButton(
            onPressed: () {
              _auth.logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LandingScreen()),
                (route) => false,
              );
            },
            child: const Text(
              'Logout',
              style: TextStyle(
                  color: Color(0xFF1A1A1A), fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ],
    );
  }

  // ── Events Tab ────────────────────────────────────────────

  Widget _eventsTab() {
    final allEvents = _auth.allEvents;
    final filteredEvents = _applyFilters(allEvents);
    final now = DateTime.now();
    final upcomingEvents = filteredEvents
        .where((e) => (e['start'] as DateTime?)?.isAfter(now) ?? false)
        .take(5)
        .toList();
    final myEvents = allEvents
        .where((e) => _registeredIds.contains(e['id'] as String))
        .toList()
      ..sort((a, b) {
        final sa = a['start'] as DateTime?;
        final sb = b['start'] as DateTime?;
        if (sa == null && sb == null) return 0;
        if (sa == null) return 1;
        if (sb == null) return -1;
        return sa.compareTo(sb);
      });

    final categories = allEvents
        .map((e) => e['category'] as String? ?? '')
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    final organizers = _auth.allUsers
        .where((u) => u.role == UserRole.organizer)
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome banner
          _welcomeBanner(),
          const SizedBox(height: 20),

          // Stats
          _statsRow(allEvents.length),
          const SizedBox(height: 20),

          // My Schedule
          if (myEvents.isNotEmpty) ...[
            _sectionHeader('My Schedule', Icons.calendar_today_outlined),
            const SizedBox(height: 10),
            ...myEvents.map((e) => _myScheduleTile(e)),
            const SizedBox(height: 20),
          ],

          // Upcoming Events carousel
          _sectionHeader('Upcoming Events', Icons.upcoming_outlined),
          const SizedBox(height: 10),
          if (upcomingEvents.isEmpty)
            _emptyState('No upcoming events right now.')
          else
            SizedBox(
              height: 220,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: upcomingEvents.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) =>
                    _upcomingEventCard(upcomingEvents[i]),
              ),
            ),
          const SizedBox(height: 20),

          // Search + filters
          _sectionHeader('Browse Events', Icons.search_outlined),
          const SizedBox(height: 10),
          _searchBar(),
          const SizedBox(height: 8),
          _filterRow(categories, organizers),
          const SizedBox(height: 12),

          // Events list
          if (filteredEvents.isEmpty)
            _emptyState(
              _searchQuery.isNotEmpty
                  ? 'No events match "$_searchQuery".'
                  : 'No events found for the selected filters.',
            )
          else
            ...filteredEvents.map((e) => _eventCard(e)),

          // Venue owner promo
          const SizedBox(height: 20),
          _venueOwnerBanner(),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ── Section header ────────────────────────────────────────

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF1A1A1A), size: 17),
        const SizedBox(width: 7),
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  // ── Welcome banner ────────────────────────────────────────

  Widget _welcomeBanner() {
    final user = _auth.currentUser;
    final greeting = user != null
        ? 'Welcome back, ${user.fullName.split(' ').first}!'
        : 'Discover events near you';
    final subtitle = user != null
        ? 'Browse, register, and manage your upcoming events.'
        : 'Sign in to register for events and build your schedule.';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(
                      color: Color(0xFFB0B0B0), fontSize: 13, height: 1.4),
                ),
                if (!_auth.isLoggedIn) ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 38,
                    child: ElevatedButton(
                      onPressed: () async {
                        final ok = await UnifiedAuthSheet.show(
                          context,
                          intent: AuthIntent.attendeeRegister,
                          defaultRole: UserRole.attendee,
                        );
                        if (!ok) return;
                        await _handleAuthFromLanding();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF1A1A1A),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        textStyle: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                      child: const Text('Get Started'),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.event_outlined,
                color: Colors.white, size: 28),
          ),
        ],
      ),
    );
  }

  // ── Stats row ─────────────────────────────────────────────

  Widget _statsRow(int totalEvents) {
    final upcomingCount = _auth.allEvents.where((e) {
      final start = e['start'] as DateTime?;
      return start != null &&
          start.isAfter(DateTime.now()) &&
          e['status'] == 'published';
    }).length;

    return Row(
      children: [
        Expanded(
          child: _statCard(
              label: 'Available',
              value: '$totalEvents',
              icon: Icons.event_available_outlined),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard(
              label: 'Registered',
              value: '${_registeredIds.length}',
              icon: Icons.confirmation_num_outlined),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard(
              label: 'Upcoming',
              value: '$upcomingCount',
              icon: Icons.schedule_outlined),
        ),
      ],
    );
  }

  Widget _statCard({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF2D2D2D), size: 18),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(
                  color: Color(0xFF1A1A1A),
                  fontSize: 22,
                  fontWeight: FontWeight.w800)),
          Text(label,
              style: const TextStyle(
                  color: Color(0xFF6B6B6B), fontSize: 11)),
        ],
      ),
    );
  }

  // ── My Schedule tile ──────────────────────────────────────

  Widget _myScheduleTile(Map<String, dynamic> e) {
    final start = e['start'] as DateTime?;
    final end = e['end'] as DateTime?;
    final location = _locationLabel(e);
    final category = (e['category'] as String? ?? '');
    final catColor = _categoryColor(category);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: Row(
        children: [
          if (start != null)
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('${start.day}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800)),
                  Text(_formatDate(start).split(' ')[1],
                      style: const TextStyle(
                          color: Color(0xFFB0B0B0), fontSize: 10)),
                ],
              ),
            )
          else
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(10),
              ),
              child:
                  const Icon(Icons.event, color: Colors.white, size: 20),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e['title'] as String? ?? '',
                    style: const TextStyle(
                        color: Color(0xFF1A1A1A),
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
                if (start != null)
                  Text(
                    '${_formatTime(start)}${end != null ? ' – ${_formatTime(end)}' : ''}',
                    style: const TextStyle(
                        color: Color(0xFF6B6B6B), fontSize: 12),
                  ),
                if (location.isNotEmpty)
                  Text(location,
                      style: const TextStyle(
                          color: Color(0xFF6B6B6B), fontSize: 12),
                      overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: catColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              category.isEmpty ? 'Event' : category,
              style: TextStyle(
                  color: catColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // ── Upcoming event card (horizontal) ──────────────────────

  Widget _upcomingEventCard(Map<String, dynamic> e) {
    final category = (e['category'] as String? ?? '');
    final catColor = _categoryColor(category);
    final start = e['start'] as DateTime?;
    final end = e['end'] as DateTime?;
    final location = _locationLabel(e);
    final organizer = _organizerName(e);
    final registered = _registeredIds.contains(e['id'] as String);

    return GestureDetector(
      onTap: () => _showEventDetail(e),
      child: Container(
        width: 236,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: registered
                ? const Color(0xFF1A1A1A)
                : const Color(0xFFE8E8E8),
            width: registered ? 1.5 : 1,
          ),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 14,
                offset: Offset(0, 4))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: catColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    category.isEmpty ? 'Event' : category,
                    style: TextStyle(
                        color: catColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w700),
                  ),
                ),
                const Spacer(),
                if (registered)
                  const Icon(Icons.check_circle,
                      color: Color(0xFF1A1A1A), size: 15),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              e['title'] as String? ?? '',
              style: const TextStyle(
                  color: Color(0xFF1A1A1A),
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  height: 1.3),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            if (start != null)
              Row(children: [
                const Icon(Icons.schedule_outlined,
                    color: Color(0xFF6B6B6B), size: 11),
                const SizedBox(width: 3),
                Expanded(
                  child: Text(
                    '${_formatDate(start)}${end != null ? ', ${_formatTime(start)}–${_formatTime(end)}' : ''}',
                    style: const TextStyle(
                        color: Color(0xFF6B6B6B), fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ]),
            if (location.isNotEmpty)
              Row(children: [
                const Icon(Icons.location_on_outlined,
                    color: Color(0xFF6B6B6B), size: 11),
                const SizedBox(width: 3),
                Expanded(
                  child: Text(location,
                      style: const TextStyle(
                          color: Color(0xFF6B6B6B), fontSize: 11),
                      overflow: TextOverflow.ellipsis),
                ),
              ]),
            const Spacer(),
            Row(
              children: [
                if (organizer.isNotEmpty)
                  Expanded(
                    child: Text(
                      'By $organizer',
                      style: const TextStyle(
                          color: Color(0xFF9E9E9E), fontSize: 10),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                GestureDetector(
                  onTap: () => _toggleRegistration(e),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: registered
                          ? const Color(0xFFF0F0F0)
                          : const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      registered ? 'Registered' : 'Register',
                      style: TextStyle(
                        color: registered
                            ? const Color(0xFF1A1A1A)
                            : Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Event list card ───────────────────────────────────────

  Widget _eventCard(Map<String, dynamic> e) {
    final registered = _registeredIds.contains(e['id'] as String);
    final category = (e['category'] as String? ?? '');
    final catColor = _categoryColor(category);
    final start = e['start'] as DateTime?;
    final end = e['end'] as DateTime?;
    final location = _locationLabel(e);
    final organizer = _organizerName(e);
    final description = (e['description'] as String? ?? '');
    final capacity = e['expectedAttendees'] as int? ?? 0;

    return GestureDetector(
      onTap: () => _showEventDetail(e),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: registered
                ? const Color(0xFF1A1A1A)
                : const Color(0xFFE8E8E8),
            width: registered ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: catColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    category.isEmpty ? 'Event' : category,
                    style: TextStyle(
                        color: catColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w700),
                  ),
                ),
                const Spacer(),
                if (registered)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('Registered',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600)),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              e['title'] as String? ?? '',
              style: const TextStyle(
                  color: Color(0xFF1A1A1A),
                  fontWeight: FontWeight.w700,
                  fontSize: 15),
            ),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                    color: Color(0xFF6B6B6B), fontSize: 12, height: 1.4),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                if (start != null)
                  _metaChip(Icons.schedule_outlined,
                      '${_formatDate(start)}  ${_formatTime(start)}${end != null ? '–${_formatTime(end)}' : ''}'),
                if (location.isNotEmpty)
                  _metaChip(Icons.location_on_outlined, location),
                if (organizer.isNotEmpty)
                  _metaChip(Icons.person_outline, organizer),
                if (capacity > 0)
                  _metaChip(Icons.people_outline, '$capacity expected'),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: ElevatedButton(
                onPressed: () => _toggleRegistration(e),
                style: ElevatedButton.styleFrom(
                  backgroundColor: registered
                      ? const Color(0xFFF5F5F5)
                      : const Color(0xFF1A1A1A),
                  foregroundColor: registered
                      ? const Color(0xFF1A1A1A)
                      : Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: registered
                        ? const BorderSide(color: Color(0xFFE0E0E0))
                        : BorderSide.none,
                  ),
                  textStyle: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
                child: Text(registered
                    ? 'Unregister'
                    : 'Register for this event'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metaChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: const Color(0xFF6B6B6B), size: 12),
        const SizedBox(width: 4),
        Text(text,
            style: const TextStyle(
                color: Color(0xFF6B6B6B), fontSize: 12)),
      ],
    );
  }

  // ── Search bar ────────────────────────────────────────────

  Widget _searchBar() {
    return TextField(
      controller: _searchCtrl,
      style: const TextStyle(color: Color(0xFF1A1A1A)),
      decoration: InputDecoration(
        hintText: 'Search events by name…',
        hintStyle: const TextStyle(color: Color(0xFF9E9E9E)),
        prefixIcon:
            const Icon(Icons.search, color: Color(0xFF2D2D2D), size: 20),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.close,
                    color: Color(0xFF6B6B6B), size: 18),
                onPressed: _searchCtrl.clear,
              )
            : null,
        filled: true,
        fillColor: const Color(0xFFFFFFFF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE8E8E8)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE8E8E8)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Color(0xFF2D2D2D), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }

  // ── Filter row ────────────────────────────────────────────

  Widget _filterRow(List<String> categories, List<UserModel> organizers) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterDropdown<_TimeFilter>(
            icon: Icons.schedule_outlined,
            label: _timeFilterLabels[_timeFilter]!,
            value: _timeFilter,
            items: _TimeFilter.values
                .map((f) => DropdownMenuItem(
                      value: f,
                      child: Text(_timeFilterLabels[f]!),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _timeFilter = v!),
          ),
          const SizedBox(width: 8),
          _FilterDropdown<String?>(
            icon: Icons.category_outlined,
            label: _selectedCategory ?? 'Category',
            value: _selectedCategory,
            items: [
              const DropdownMenuItem<String?>(
                  value: null, child: Text('All Categories')),
              ...categories.map(
                (c) => DropdownMenuItem<String?>(value: c, child: Text(c)),
              ),
            ],
            onChanged: (v) =>
                setState(() => _selectedCategory = v),
          ),
          const SizedBox(width: 8),
          _FilterDropdown<String?>(
            icon: Icons.person_outline,
            label: _selectedOrganizerId != null
                ? organizers
                    .where((o) => o.id == _selectedOrganizerId)
                    .map((o) => o.fullName.split(' ').first)
                    .firstOrNull ?? 'Organizer'
                : 'Organizer',
            value: _selectedOrganizerId,
            items: [
              const DropdownMenuItem<String?>(
                  value: null, child: Text('All Organizers')),
              ...organizers.map(
                (o) => DropdownMenuItem<String?>(
                    value: o.id, child: Text(o.fullName)),
              ),
            ],
            onChanged: (v) =>
                setState(() => _selectedOrganizerId = v),
          ),
          if (_selectedCategory != null ||
              _selectedOrganizerId != null ||
              _timeFilter != _TimeFilter.all ||
              _searchQuery.isNotEmpty) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                _searchCtrl.clear();
                setState(() {
                  _selectedCategory = null;
                  _selectedOrganizerId = null;
                  _timeFilter = _TimeFilter.all;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.close, color: Colors.white, size: 13),
                    SizedBox(width: 4),
                    Text('Clear',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Venue owner promo ─────────────────────────────────────

  Widget _venueOwnerBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Own a venue?',
                    style: TextStyle(
                        color: Color(0xFF1A1A1A),
                        fontWeight: FontWeight.w800,
                        fontSize: 15)),
                SizedBox(height: 4),
                Text('List your space and get booked by organizers.',
                    style: TextStyle(
                        color: Color(0xFF6B6B6B), fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton(
            onPressed: () async {
              if (!_auth.isLoggedIn) {
                final ok = await UnifiedAuthSheet.show(
                  context,
                  intent: AuthIntent.ownerListVenue,
                  defaultRole: UserRole.staff,
                );
                if (!ok) return;
              }
              _goToMyDashboard();
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF1A1A1A),
              side: const BorderSide(color: Color(0xFF1A1A1A)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('List Space'),
          ),
        ],
      ),
    );
  }

  // ── Empty state ───────────────────────────────────────────

  Widget _emptyState(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            const Icon(Icons.event_busy_outlined,
                color: Color(0xFFCCCCCC), size: 52),
            const SizedBox(height: 12),
            Text(
              msg,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Color(0xFF9E9E9E), fontSize: 14, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Reusable filter dropdown chip ─────────────────────────────────────────────

class _FilterDropdown<T> extends StatelessWidget {
  final IconData icon;
  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _FilterDropdown({
    required this.icon,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          icon: const Icon(Icons.expand_more,
              size: 16, color: Color(0xFF6B6B6B)),
          isDense: true,
          style: const TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          items: items,
          onChanged: onChanged,
          hint: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: const Color(0xFF6B6B6B)),
              const SizedBox(width: 4),
              Text(label,
                  style: const TextStyle(
                      color: Color(0xFF6B6B6B), fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}
