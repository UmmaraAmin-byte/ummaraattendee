import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../profile_screen.dart';
import '../unified_auth_sheet.dart';
import '../../models/user_model.dart';
import 'organizer_dashboard.dart';
import 'staff_dashboard.dart';
import 'super_admin_dashboard.dart';

class AttendeeDashboard extends StatefulWidget {
  const AttendeeDashboard({super.key});

  @override
  State<AttendeeDashboard> createState() => _AttendeeDashboardState();
}

class _AttendeeDashboardState extends State<AttendeeDashboard> {
  final _auth = AuthService();

  // IDs of events the attendee has registered for
  final Set<String> _registeredIds = {};

  // Search filter
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  Map<String, dynamic>? _pendingRegistrationEvent;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() => _searchQuery = _searchCtrl.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

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
      if (pending != null) {
        _completeRegistration(pending);
      }
      return;
    }

    final id = event['id'] as String;
    setState(() {
      if (_registeredIds.contains(id)) {
        _registeredIds.remove(id);
        _showSnack('Unregistered from "${event['title']}"');
      } else {
        _registeredIds.add(id);
        _showSnack('Registered for "${event['title']}"!');
      }
    });
  }

  void _completeRegistration(Map<String, dynamic> event) {
    final id = event['id'] as String;
    setState(() {
      if (_registeredIds.contains(id)) {
        _registeredIds.remove(id);
        _showSnack('Unregistered from "${event['title']}"');
      } else {
        _registeredIds.add(id);
        _showSnack('Event registered successfully.');
      }
    });
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: const Color(0xFF2D2D2D),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    // Read from shared store
    final allEvents = _auth.allEvents;

    // Filtered list for "Available Events"
    final filteredEvents = allEvents.where((e) {
      if (_searchQuery.isEmpty) return true;
      return (e['title'] as String).toLowerCase().contains(_searchQuery);
    }).toList();

    // Events the attendee is registered for (in full)
    final myEvents = allEvents
        .where((e) => _registeredIds.contains(e['id'] as String))
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
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
                  color: Color(0xFF1A1A1A),
                  fontWeight: FontWeight.w600,
                ),
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
                  color: Color(0xFF1A1A1A),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ] else ...[
            TextButton(
              onPressed: _goToMyDashboard,
              child: const Text(
                'Dashboard',
                style: TextStyle(
                  color: Color(0xFF1A1A1A),
                  fontWeight: FontWeight.w600,
                ),
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
                setState(() {});
              },
              child: const Text(
                'Logout',
                style: TextStyle(
                  color: Color(0xFF1A1A1A),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _heroSection(),
            const SizedBox(height: 24),
            _featuredEventsSection(filteredEvents),
            const SizedBox(height: 24),
            _howItWorks(),
            const SizedBox(height: 24),
            _forVenueOwners(),
            const SizedBox(height: 24),

            // ── Stats ──────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _statCard(
                      'Registered',
                      '${_registeredIds.length}',
                      Icons.confirmation_num_outlined,
                      const Color(0xFF2D2D2D)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _statCard(
                      'Available',
                      '${allEvents.length}',
                      Icons.event_available_outlined,
                      const Color(0xFF6B6B6B)),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── My Schedule ────────────────────────
            if (myEvents.isNotEmpty) ...[
              const Text('My Schedule',
                  style: TextStyle(
                      color: Color(0xFF1A1A1A),
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              ...myEvents.map((e) => _myEventTile(e)),
              const SizedBox(height: 24),
            ],

            // ── Search Box ─────────────────────────
            const Text('Available Events',
                style: TextStyle(
                    color: Color(0xFF1A1A1A),
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            TextField(
              controller: _searchCtrl,
              style: const TextStyle(color: Color(0xFF1A1A1A)),
              decoration: InputDecoration(
                hintText: 'Search events by name…',
                hintStyle: const TextStyle(color: Color(0xFF9E9E9E)),
                prefixIcon: const Icon(Icons.search,
                    color: Color(0xFF2D2D2D), size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close,
                            color: Color(0xFF6B6B6B), size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                        },
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
              ),
            ),
            const SizedBox(height: 14),

            // ── Events List ────────────────────────
            if (allEvents.isEmpty)
              _emptyState(
                  'No events yet.\nCheck back later when an organizer has created events.')
            else if (filteredEvents.isEmpty)
              _emptyState('No events match "$_searchQuery".')
            else
              ...filteredEvents.map((e) => _eventCard(e)),

            // ── Interests ─────────────────────────
            const SizedBox(height: 24),
            if ((user?.interests ?? []).isNotEmpty) ...[
              const Text('Your Interests',
                  style: TextStyle(
                      color: Color(0xFF1A1A1A),
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: user!.interests
                    .map((i) => Chip(
                          label: Text(i,
                              style: const TextStyle(
                                  color: Color(0xFF1A1A1A), fontSize: 12)),
                          backgroundColor: const Color(0xFFF0F0F0),
                          side: const BorderSide(color: Color(0xFFE8E8E8)),
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _goToMyDashboard() {
    final u = _auth.currentUser;
    if (u == null) return;
    Widget screen = const AttendeeDashboard();
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

    // If they signed in as attendee, we can just refresh the landing.
    if (u.role == UserRole.attendee) {
      setState(() {});
      return;
    }

    // Otherwise, take them to the correct role dashboard.
    _goToMyDashboard();
  }

  Widget _heroSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E8E8)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Plan, Book, and Manage Events Seamlessly',
            style: TextStyle(
              color: Color(0xFF1A1A1A),
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Discover events, reserve venues, and manage everything in one place—built for attendees, organizers, and venue owners.',
            style: TextStyle(color: Color(0xFF6B6B6B), height: 1.4),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ElevatedButton(
                onPressed: () async {
                  if (!_auth.isLoggedIn) {
                    final ok = await UnifiedAuthSheet.show(
                      context,
                      intent: AuthIntent.organizerCreateEvent,
                      defaultRole: UserRole.organizer,
                    );
                    if (!ok) return;
                  }
                  _goToMyDashboard();
                },
                child: const Text('Create Event'),
              ),
              OutlinedButton(
                onPressed: () {},
                child: const Text('Find Events'),
              ),
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
                child: const Text('List Your Venue'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _featuredEventsSection(List<Map<String, dynamic>> events) {
    final featured = events.take(3).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Featured Events',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        if (featured.isEmpty)
          const Text(
            'No featured events yet. Check back soon.',
            style: TextStyle(color: Color(0xFF6B6B6B)),
          )
        else
          ...featured.map((e) {
            final location = (e['location'] as String?) ?? '';
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFFFF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE8E8E8)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F2F2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.local_activity_outlined,
                          color: Color(0xFF2D2D2D)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e['title'] as String,
                            style: const TextStyle(
                              color: Color(0xFF1A1A1A),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (location.isNotEmpty)
                            Text(
                              location,
                              style: const TextStyle(
                                color: Color(0xFF6B6B6B),
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded,
                        color: Color(0xFF6B6B6B)),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _howItWorks() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'How it works',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        _stepCard(
          icon: Icons.search,
          title: 'Create or discover events',
          subtitle: 'Browse public events or create your own in minutes.',
        ),
        const SizedBox(height: 10),
        _stepCard(
          icon: Icons.meeting_room_outlined,
          title: 'Book venues بسهولة',
          subtitle: 'Find available rooms that match your schedule and capacity.',
        ),
        const SizedBox(height: 10),
        _stepCard(
          icon: Icons.people_outline,
          title: 'Manage attendees',
          subtitle: 'Track registrations and keep your event organized.',
        ),
      ],
    );
  }

  Widget _stepCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0F0),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF2D2D2D)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF1A1A1A),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(color: Color(0xFF6B6B6B), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _forVenueOwners() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'For Venue Owners',
                  style: TextStyle(
                    color: Color(0xFF1A1A1A),
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'List your space, manage rooms and availability, and get booked by organizers.',
                  style: TextStyle(color: Color(0xFF6B6B6B)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
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
            child: const Text('List Your Space'),
          ),
        ],
      ),
    );
  }

  // ── Widgets ──────────────────────────────────

  Widget _statCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: TextStyle(
                      color: color,
                      fontSize: 22,
                      fontWeight: FontWeight.w800)),
              Text(label,
                  style: const TextStyle(
                      color: Color(0xFF6B6B6B), fontSize: 11)),
            ],
          )
        ],
      ),
    );
  }

  Widget _myEventTile(Map<String, dynamic> e) {
    final date = e['date'] as DateTime?;
    final dateStr = date != null
        ? '${date.day}/${date.month}/${date.year}'
        : null;
    final location = (e['location'] as String?) ?? '';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle,
              color: Color(0xFF2D2D2D), size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e['title'] as String,
                    style: const TextStyle(
                        color: Color(0xFF1A1A1A),
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
                if (dateStr != null || location.isNotEmpty)
                  Text(
                    [if (dateStr != null) dateStr, if (location.isNotEmpty) location]
                        .join(' · '),
                    style: const TextStyle(
                        color: Color(0xFF6B6B6B), fontSize: 12),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _eventCard(Map<String, dynamic> e) {
    final registered = _registeredIds.contains(e['id'] as String);
    final date = e['date'] as DateTime?;
    final dateStr = date != null
        ? '${date.day}/${date.month}/${date.year}'
        : null;
    final location = (e['location'] as String?) ?? '';
    final organizer = (e['organizer'] as String?) ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: registered
              ? const Color(0xFF2D2D2D)
              : const Color(0xFFE8E8E8),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e['title'] as String,
                    style: const TextStyle(
                        color: Color(0xFF1A1A1A),
                        fontWeight: FontWeight.w600,
                        fontSize: 15)),
                const SizedBox(height: 4),
                if (dateStr != null)
                  Row(children: [
                    const Icon(Icons.calendar_today_outlined,
                        color: Color(0xFF6B6B6B), size: 13),
                    const SizedBox(width: 4),
                    Text(dateStr,
                        style: const TextStyle(
                            color: Color(0xFF6B6B6B), fontSize: 12)),
                  ]),
                if (location.isNotEmpty)
                  Row(children: [
                    const Icon(Icons.location_on_outlined,
                        color: Color(0xFF2D2D2D), size: 13),
                    const SizedBox(width: 4),
                    Text(location,
                        style: const TextStyle(
                            color: Color(0xFF6B6B6B), fontSize: 12)),
                  ]),
                if (organizer.isNotEmpty)
                  Row(children: [
                    const Icon(Icons.person_outline,
                        color: Color(0xFF6B6B6B), size: 13),
                    const SizedBox(width: 4),
                    Text('By $organizer',
                        style: const TextStyle(
                            color: Color(0xFF6B6B6B), fontSize: 12)),
                  ]),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () => _toggleRegistration(e),
            style: ElevatedButton.styleFrom(
              backgroundColor: registered
                  ? const Color(0xFFF0F0F0)
                  : const Color(0xFF2D2D2D),
              foregroundColor:
                  registered ? const Color(0xFF1A1A1A) : Colors.white,
              side: registered
                  ? const BorderSide(color: Color(0xFFE8E8E8))
                  : BorderSide.none,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              textStyle: const TextStyle(fontSize: 12),
            ),
            child: Text(registered ? 'Unregister' : 'Register'),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            const Icon(Icons.event_note_outlined,
                color: Color(0xFF9E9E9E), size: 60),
            const SizedBox(height: 16),
            Text(msg,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Color(0xFF6B6B6B), fontSize: 14, height: 1.6)),
          ],
        ),
      ),
    );
  }
}