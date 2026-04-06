import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/auth_service.dart';
import '../../services/registration_service.dart';
import '../../models/user_model.dart';
import '../profile_screen.dart';
import '../landing_screen.dart';

// ── Theme constants ───────────────────────────────────────────────────────────

const _bg = Color(0xFFFAFAFA);
const _white = Color(0xFFFFFFFF);
const _border = Color(0xFFE8E8E8);
const _ink = Color(0xFF1A1A1A);
const _muted = Color(0xFF6B6B6B);
const _accent = Color(0xFF2D2D2D);

// ── Status helpers ────────────────────────────────────────────────────────────

String _eventStatus(Map<String, dynamic> e) {
  final status = e['status'] as String? ?? 'draft';
  if (status == 'draft') return 'draft';
  final start = e['start'] as DateTime?;
  final end = e['end'] as DateTime?;
  final now = DateTime.now();
  if (start == null || end == null) return status;
  if (now.isAfter(end)) return 'completed';
  if (now.isAfter(start) && now.isBefore(end)) return 'ongoing';
  return 'upcoming';
}

Color _statusColor(String s) {
  switch (s) {
    case 'upcoming':
      return const Color(0xFF1565C0);
    case 'ongoing':
      return const Color(0xFF2E7D32);
    case 'completed':
      return const Color(0xFF546E7A);
    case 'draft':
      return const Color(0xFFE65100);
    default:
      return _muted;
  }
}

String _fmt(DateTime dt) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
}

String _fmtTime(DateTime dt) =>
    '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

String _fmtDate(DateTime dt) => '${_fmt(dt)}, ${_fmtTime(dt)}';

// ── Dashboard ─────────────────────────────────────────────────────────────────

class OrganizerDashboard extends StatefulWidget {
  const OrganizerDashboard({super.key});

  @override
  State<OrganizerDashboard> createState() => _OrganizerDashboardState();
}

class _OrganizerDashboardState extends State<OrganizerDashboard>
    with SingleTickerProviderStateMixin {
  final _auth = AuthService();
  final _reg = RegistrationService();
  bool _redirecting = false;

  late final TabController _tabCtrl;
  static const _tabs = ['Events', 'Attendees', 'Venues', 'Analytics'];
  static const _tabIcons = [
    Icons.event_outlined,
    Icons.people_outline,
    Icons.meeting_room_outlined,
    Icons.bar_chart_outlined,
  ];

  // Event form
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _attendeesCtrl = TextEditingController();

  // Venue search
  final _locationCtrl = TextEditingController();
  int _venueMinCap = 1;
  DateTime _venueSearchStart = DateTime.now().add(const Duration(hours: 1));
  DateTime _venueSearchEnd = DateTime.now().add(const Duration(hours: 4));
  List<Map<String, dynamic>> _venueResults = [];

  // Attendees tab
  String? _selectedAttendeesEventId;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _tabs.length, vsync: this);
    _tabCtrl.addListener(() => setState(() {}));
    _guardAuth();
  }

  void _guardAuth() {
    final user = _auth.currentUser;
    if (_redirecting) return;
    if (user == null || user.role != UserRole.organizer) {
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

  @override
  void dispose() {
    _tabCtrl.dispose();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _categoryCtrl.dispose();
    _attendeesCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? Colors.redAccent : _accent,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  String _locationLabel(Map<String, dynamic> event) {
    final bookingId = event['bookingId'] as String?;
    if (bookingId == null) return '';
    final bookings =
        _auth.allBookings.where((b) => b['id'] == bookingId).toList();
    if (bookings.isEmpty) return '';
    final roomId = bookings.first['roomId'] as String? ?? '';
    final rooms = _auth.allRooms.where((r) => r['id'] == roomId).toList();
    if (rooms.isEmpty) return '';
    final room = rooms.first;
    final buildings = _auth.allBuildings
        .where((b) => b['id'] == room['buildingId'])
        .toList();
    if (buildings.isEmpty) return room['name'] as String? ?? '';
    return '${buildings.first['name']} · ${room['name']}';
  }

  Set<String> _conflictingIds(List<Map<String, dynamic>> events) {
    final conflicts = <String>{};
    for (int i = 0; i < events.length; i++) {
      for (int j = i + 1; j < events.length; j++) {
        final aStart = events[i]['start'] as DateTime?;
        final aEnd = events[i]['end'] as DateTime?;
        final bStart = events[j]['start'] as DateTime?;
        final bEnd = events[j]['end'] as DateTime?;
        if (aStart == null || aEnd == null || bStart == null || bEnd == null) {
          continue;
        }
        if (aStart.isBefore(bEnd) && bStart.isBefore(aEnd)) {
          conflicts.add(events[i]['id'] as String);
          conflicts.add(events[j]['id'] as String);
        }
      }
    }
    return conflicts;
  }

  // ── Create / Edit event sheet ─────────────────────────────

  Future<void> _showEventSheet({Map<String, dynamic>? existing}) async {
    final isEdit = existing != null;
    _titleCtrl.text = (existing?['title'] as String?) ?? '';
    _descCtrl.text = (existing?['description'] as String?) ?? '';
    _categoryCtrl.text = (existing?['category'] as String?) ?? '';
    _attendeesCtrl.text =
        ((existing?['expectedAttendees'] as int?) ?? 50).toString();

    DateTime start = isEdit
        ? (existing!['start'] as DateTime)
        : DateTime.now().add(const Duration(days: 7));
    DateTime end = isEdit
        ? (existing!['end'] as DateTime)
        : start.add(const Duration(hours: 3));

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        isEdit ? 'Edit Event' : 'Add Event',
                        style: const TextStyle(
                          color: _ink,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close, color: _muted),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                _formField(_titleCtrl, 'Event title', maxLines: 1),
                const SizedBox(height: 10),
                _formField(
                  _descCtrl,
                  'Description — tell attendees what to expect',
                  maxLines: 4,
                ),
                const SizedBox(height: 10),
                _formField(
                  _categoryCtrl,
                  'Category  (e.g. Technology, Arts & Culture)',
                  maxLines: 1,
                ),
                const SizedBox(height: 10),
                _formField(
                  _attendeesCtrl,
                  'Expected number of attendees',
                  maxLines: 1,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                _dtTile(
                  label: 'Start',
                  dt: start,
                  ctx: ctx,
                  onPicked: (d) => setS(() => start = d),
                ),
                const SizedBox(height: 8),
                _dtTile(
                  label: 'End',
                  dt: end,
                  ctx: ctx,
                  onPicked: (d) => setS(() => end = d),
                  firstDate: start,
                ),
                if (isEdit && (existing!['bookingId'] as String?) != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFFE082)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline,
                            size: 14, color: Color(0xFFE65100)),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'This event has an active venue booking. Changing the date does not automatically update the booking.',
                            style: TextStyle(
                                fontSize: 12, color: Color(0xFFE65100)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _submitEvent(
                          ctx: ctx,
                          start: start,
                          end: end,
                          status: 'draft',
                          eventId: existing?['id'] as String?,
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _ink,
                          side: const BorderSide(color: _border),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Save as Draft'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _submitEvent(
                          ctx: ctx,
                          start: start,
                          end: end,
                          status: 'published',
                          eventId: existing?['id'] as String?,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(isEdit ? 'Save Changes' : 'Publish'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _submitEvent({
    required BuildContext ctx,
    required DateTime start,
    required DateTime end,
    required String status,
    String? eventId,
  }) {
    final err = _auth.upsertOrganizerEvent(
      eventId: eventId,
      title: _titleCtrl.text,
      description: _descCtrl.text,
      category: _categoryCtrl.text,
      start: start,
      end: end,
      expectedAttendees: int.tryParse(_attendeesCtrl.text) ?? 0,
      status: status,
    );
    if (err != null) {
      _snack(err, error: true);
      return;
    }
    Navigator.pop(ctx);
    setState(() {});
    _snack(eventId == null ? 'Event created.' : 'Event updated.');
  }

  Widget _formField(
    TextEditingController ctrl,
    String label, {
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(color: _ink, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: _muted, fontSize: 13),
        filled: true,
        fillColor: const Color(0xFFF7F7F7),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _ink, width: 1.5),
        ),
      ),
    );
  }

  Widget _dtTile({
    required String label,
    required DateTime dt,
    required BuildContext ctx,
    required void Function(DateTime) onPicked,
    DateTime? firstDate,
  }) {
    return GestureDetector(
      onTap: () async {
        final d = await showDatePicker(
          context: ctx,
          initialDate: dt,
          firstDate: firstDate ?? DateTime.now(),
          lastDate: DateTime(DateTime.now().year + 3),
        );
        if (!ctx.mounted || d == null) return;
        final t = await showTimePicker(
          context: ctx,
          initialTime: TimeOfDay(hour: dt.hour, minute: dt.minute),
        );
        if (!ctx.mounted || t == null) return;
        onPicked(DateTime(d.year, d.month, d.day, t.hour, t.minute));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F7F7),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            Text(
              '$label: ',
              style: const TextStyle(
                  color: _muted, fontSize: 13, fontWeight: FontWeight.w500),
            ),
            Expanded(
              child: Text(
                _fmtDate(dt),
                style: const TextStyle(
                    color: _ink, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
            const Icon(Icons.edit_calendar_outlined, size: 16, color: _muted),
          ],
        ),
      ),
    );
  }

  // ── Book venue sheet ──────────────────────────────────────

  Future<void> _showBookVenueSheet(Map<String, dynamic> event) async {
    final start = event['start'] as DateTime;
    final end = event['end'] as DateTime;
    final attendees = event['expectedAttendees'] as int;
    List<Map<String, dynamic>> results = _auth.searchAvailableRooms(
      start: start,
      end: end,
      minCapacity: attendees,
    );
    final locCtrl = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, ctrl) => ListView(
            controller: ctrl,
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Book Venue',
                            style: TextStyle(
                                color: _ink,
                                fontSize: 18,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(
                          event['title'] as String? ?? '',
                          style:
                              const TextStyle(color: _muted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close, color: _muted),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _infoRow(Icons.schedule_outlined,
                  '${_fmtDate(start)} – ${_fmtTime(end)}'),
              _infoRow(Icons.people_outline,
                  '$attendees expected attendees minimum capacity'),
              const SizedBox(height: 12),
              TextField(
                controller: locCtrl,
                style: const TextStyle(color: _ink, fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Filter by location',
                  labelStyle: const TextStyle(color: _muted, fontSize: 13),
                  prefixIcon:
                      const Icon(Icons.location_on_outlined, size: 18),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => setS(() {
                    results = _auth.searchAvailableRooms(
                      start: start,
                      end: end,
                      minCapacity: attendees,
                      locationQuery: locCtrl.text,
                    );
                  }),
                  icon: const Icon(Icons.search, size: 16),
                  label: const Text('Search'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _ink,
                    side: const BorderSide(color: _border),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (results.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    'No available venues found for this event window.',
                    style: TextStyle(color: _muted, fontSize: 13),
                  ),
                )
              else
                ...results.take(6).map((r) {
                  final room = r['room'] as Map<String, dynamic>;
                  final building = r['building'] as Map<String, dynamic>;
                  final pricing = room['pricing'] as double?;
                  final cap = room['capacity'] as int? ?? 0;
                  final amenities =
                      (room['amenities'] as List).cast<String>();
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F7F7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(room['name'] as String? ?? '',
                            style: const TextStyle(
                                color: _ink,
                                fontWeight: FontWeight.w700,
                                fontSize: 13)),
                        const SizedBox(height: 2),
                        Text(building['name'] as String? ?? '',
                            style: const TextStyle(
                                color: _muted, fontSize: 12)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            _chip('$cap capacity', Icons.people_outline),
                            if (pricing != null)
                              _chip('£${pricing.toStringAsFixed(0)}/hr',
                                  Icons.sell_outlined),
                            ...amenities
                                .take(3)
                                .map((a) => _chip(
                                    a, Icons.check_circle_outline)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              final err = _auth.createBooking(
                                eventId: event['id'] as String,
                                roomId: room['id'] as String,
                                start: start,
                                end: end,
                              );
                              if (err != null) {
                                _snack(err, error: true);
                                return;
                              }
                              Navigator.pop(ctx);
                              setState(() {});
                              _snack('Venue booked successfully.');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _accent,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text('Book Venue'),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
    locCtrl.dispose();
  }

  // ── Events Tab ────────────────────────────────────────────

  Widget _buildEventsTab(List<Map<String, dynamic>> events) {
    final now = DateTime.now();
    final total = events.length;
    final upcoming = events
        .where((e) =>
            e['status'] == 'published' &&
            (e['start'] as DateTime?)?.isAfter(now) == true)
        .length;
    final drafts = events.where((e) => e['status'] == 'draft').length;
    final past = events
        .where((e) => (e['end'] as DateTime?)?.isBefore(now) == true)
        .length;
    final conflicts = _conflictingIds(events);

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stats row
              SizedBox(
                height: 82,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _statTile('Total', '$total', Icons.event_outlined),
                    const SizedBox(width: 10),
                    _statTile('Upcoming', '$upcoming',
                        Icons.upcoming_outlined,
                        color: const Color(0xFF1565C0)),
                    const SizedBox(width: 10),
                    _statTile('Drafts', '$drafts', Icons.edit_outlined,
                        color: const Color(0xFFE65100)),
                    const SizedBox(width: 10),
                    _statTile(
                        'Completed', '$past', Icons.check_circle_outline,
                        color: const Color(0xFF546E7A)),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Conflict alert
              if (conflicts.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFFCC02)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          color: Color(0xFFE65100), size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${conflicts.length} of your events have overlapping times. '
                          'Review the highlighted events below and adjust their schedules.',
                          style: const TextStyle(
                            color: Color(0xFFE65100),
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Event list
              if (events.isEmpty)
                _emptyState(
                  icon: Icons.event_outlined,
                  title: 'No events yet',
                  subtitle:
                      "Tap 'Add Event' to create your first event and start managing bookings and attendees.",
                )
              else ...[
                const Text('My Events',
                    style: TextStyle(
                        color: _ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                ...events.map((e) => _eventCard(e, conflicts)),
              ],
            ],
          ),
        ),

        // FAB
        Positioned(
          bottom: 20,
          right: 16,
          child: FloatingActionButton.extended(
            onPressed: _showEventSheet,
            backgroundColor: _accent,
            foregroundColor: Colors.white,
            elevation: 2,
            icon: const Icon(Icons.add),
            label: const Text('Add Event',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  Widget _eventCard(
      Map<String, dynamic> e, Set<String> conflicts) {
    final id = e['id'] as String;
    final title = e['title'] as String? ?? '';
    final status = _eventStatus(e);
    final statusColor = _statusColor(status);
    final start = e['start'] as DateTime?;
    final end = e['end'] as DateTime?;
    final category = e['category'] as String? ?? '';
    final expected = e['expectedAttendees'] as int? ?? 0;
    final registered = _reg.countForEvent(id);
    final location = _locationLabel(e);
    final booking = _auth.bookingForEvent(id);
    final isConflict = conflicts.contains(id);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isConflict ? const Color(0xFFFFCC02) : _border,
          width: isConflict ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 6, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          if (category.isNotEmpty)
                            _badgePill(category, const Color(0xFF757575),
                                bg: const Color(0xFFF0F0F0)),
                          _badgePill(
                              status.toUpperCase(), statusColor,
                              bg: statusColor.withOpacity(0.1)),
                          if (isConflict)
                            _conflictBadge(),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        title,
                        style: const TextStyle(
                          color: _ink,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (v) => _handleAction(v, e),
                  icon: const Icon(Icons.more_vert, color: _muted, size: 20),
                  color: _white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  itemBuilder: (_) => [
                    _menuItem('edit', Icons.edit_outlined, 'Edit Event'),
                    _menuItem(
                        'duplicate', Icons.copy_outlined, 'Duplicate'),
                    _menuItem('delete', Icons.delete_outline, 'Delete',
                        isDestructive: true),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (start != null)
                  _infoRow(
                    Icons.schedule_outlined,
                    '${_fmt(start)}, ${_fmtTime(start)}'
                    '${end != null ? ' – ${_fmtTime(end)}' : ''}',
                  ),
                if (location.isNotEmpty)
                  _infoRow(Icons.location_on_outlined, location),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _pill('$registered registered',
                        Icons.how_to_reg_outlined,
                        color: const Color(0xFF1565C0)),
                    _pill('$expected expected', Icons.people_outline),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
            child: booking == null
                ? OutlinedButton.icon(
                    onPressed: () => _showBookVenueSheet(e),
                    icon: const Icon(Icons.meeting_room_outlined, size: 14),
                    label: const Text('Book Venue'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _ink,
                      side: const BorderSide(color: _border),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      textStyle: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  )
                : Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle_outline,
                                size: 13, color: Color(0xFF2E7D32)),
                            const SizedBox(width: 5),
                            Text(
                              'Venue booked · ${(booking['status'] as String? ?? '').toUpperCase()}',
                              style: const TextStyle(
                                color: Color(0xFF2E7D32),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          _auth.cancelBooking(booking['id'] as String);
                          setState(() {});
                          _snack('Booking cancelled.');
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                          textStyle: const TextStyle(fontSize: 12),
                        ),
                        child: const Text('Cancel Booking'),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _menuItem(
      String value, IconData icon, String label,
      {bool isDestructive = false}) {
    final color = isDestructive ? Colors.redAccent : _ink;
    return PopupMenuItem<String>(
      value: value,
      child: Row(children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(color: color, fontSize: 13)),
      ]),
    );
  }

  void _handleAction(String action, Map<String, dynamic> e) {
    switch (action) {
      case 'edit':
        _showEventSheet(existing: e);
        break;
      case 'duplicate':
        _showEventSheet(existing: {
          ...e,
          'id': null,
          'title': 'Copy of ${e['title']}',
          'bookingId': null,
        });
        break;
      case 'delete':
        _confirmDelete(e);
        break;
    }
  }

  void _confirmDelete(Map<String, dynamic> e) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Event',
            style: TextStyle(
                color: _ink, fontWeight: FontWeight.w700, fontSize: 16)),
        content: Text(
          'Are you sure you want to delete "${e['title']}"? This cannot be undone.',
          style: const TextStyle(color: _muted, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('Keep', style: TextStyle(color: _muted)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              final err =
                  _auth.deleteOrganizerEvent(e['id'] as String);
              if (err != null) {
                _snack(err, error: true);
                return;
              }
              setState(() {});
              _snack('Event deleted.');
            },
            child: const Text('Delete',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  // ── Attendees Tab ─────────────────────────────────────────

  Widget _buildAttendeesTab(List<Map<String, dynamic>> events) {
    final published =
        events.where((e) => e['status'] == 'published').toList();
    final registrations = _selectedAttendeesEventId != null
        ? _reg.registrationsForEvent(_selectedAttendeesEventId!)
        : <Map<String, dynamic>>[];
    final selectedEvent = _selectedAttendeesEventId != null
        ? events
            .where((e) => e['id'] == _selectedAttendeesEventId)
            .toList()
        : <Map<String, dynamic>>[];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('View Attendees',
              style: TextStyle(
                  color: _ink, fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text(
            'Select an event to see who has registered and manage attendance.',
            style: TextStyle(color: _muted, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 14),
          if (published.isEmpty)
            _emptyState(
              icon: Icons.event_busy_outlined,
              title: 'No published events',
              subtitle:
                  'Publish an event from the Events tab to start tracking attendees.',
            )
          else ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: _white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _border),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedAttendeesEventId,
                  isExpanded: true,
                  hint: const Text('Choose an event',
                      style: TextStyle(color: _muted, fontSize: 13)),
                  icon: const Icon(Icons.keyboard_arrow_down_rounded,
                      color: _muted),
                  items: published
                      .map((e) => DropdownMenuItem<String>(
                            value: e['id'] as String,
                            child: Text(
                              e['title'] as String? ?? '',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: _ink, fontSize: 13),
                            ),
                          ))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _selectedAttendeesEventId = v),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_selectedAttendeesEventId != null) ...[
              if (selectedEvent.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F7F7),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedEvent.first['title'] as String? ?? '',
                        style: const TextStyle(
                            color: _ink,
                            fontWeight: FontWeight.w700,
                            fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _pill(
                              '${registrations.length} registered',
                              Icons.how_to_reg_outlined,
                              color: const Color(0xFF1565C0)),
                          _pill(
                              '${registrations.where((r) => r['attended'] == true).length} attended',
                              Icons.check_circle_outline,
                              color: const Color(0xFF2E7D32)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (registrations.isEmpty)
                _emptyState(
                  icon: Icons.people_outline,
                  title: 'No registrations yet',
                  subtitle:
                      "Nobody has signed up yet. Share the event with your audience to get registrations.",
                )
              else ...[
                const Text('Registered Attendees',
                    style: TextStyle(
                        color: _ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                ...registrations.map((r) => _attendeeRow(r)),
              ],
            ],
          ],
        ],
      ),
    );
  }

  Widget _attendeeRow(Map<String, dynamic> r) {
    final name = r['attendeeName'] as String? ?? '';
    final email = r['attendeeEmail'] as String? ?? '';
    final regAt = r['registeredAt'] as DateTime?;
    final attended = r['attended'] as bool? ?? false;
    final notes = r['notes'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFFF0F0F0),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(
                  color: _ink, fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        color: _ink,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
                const SizedBox(height: 2),
                Text(email,
                    style: const TextStyle(color: _muted, fontSize: 12)),
                if (regAt != null)
                  Text('Registered ${_fmt(regAt)}',
                      style:
                          const TextStyle(color: _muted, fontSize: 11)),
                if (notes.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text('"$notes"',
                      style: const TextStyle(
                          color: _muted,
                          fontSize: 11,
                          fontStyle: FontStyle.italic)),
                ],
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              _reg.markAttended(r['id'] as String,
                  attended: !attended);
              setState(() {});
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: attended
                    ? const Color(0xFFE8F5E9)
                    : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: attended
                        ? const Color(0xFFA5D6A7)
                        : _border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    attended
                        ? Icons.check_circle_outline
                        : Icons.radio_button_unchecked,
                    size: 13,
                    color: attended
                        ? const Color(0xFF2E7D32)
                        : _muted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    attended ? 'Attended' : 'Mark',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: attended
                          ? const Color(0xFF2E7D32)
                          : _muted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Venues Tab ────────────────────────────────────────────

  Widget _buildVenuesTab(List<Map<String, dynamic>> events) {
    final unbookedPublished = events
        .where((e) =>
            e['status'] == 'published' && e['bookingId'] == null)
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Find a Venue',
              style: TextStyle(
                  color: _ink, fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text(
            'Search rooms across all buildings. Only venues free for your chosen time and capacity are shown.',
            style: TextStyle(color: _muted, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Availability Filters',
                    style: TextStyle(
                        color: _ink,
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                _dtTile(
                  label: 'From',
                  dt: _venueSearchStart,
                  ctx: context,
                  onPicked: (d) => setState(() => _venueSearchStart = d),
                ),
                const SizedBox(height: 8),
                _dtTile(
                  label: 'To',
                  dt: _venueSearchEnd,
                  ctx: context,
                  onPicked: (d) => setState(() => _venueSearchEnd = d),
                  firstDate: _venueSearchStart,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Text('Min capacity: ',
                        style: TextStyle(color: _muted, fontSize: 13)),
                    Expanded(
                      child: Slider(
                        value: _venueMinCap.toDouble(),
                        min: 1,
                        max: 500,
                        divisions: 49,
                        activeColor: _accent,
                        label: '$_venueMinCap',
                        onChanged: (v) =>
                            setState(() => _venueMinCap = v.round()),
                      ),
                    ),
                    Text('$_venueMinCap',
                        style: const TextStyle(
                            color: _ink,
                            fontWeight: FontWeight.w700,
                            fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _locationCtrl,
                  style: const TextStyle(color: _ink, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Location  (e.g. London, Manchester)',
                    labelStyle:
                        const TextStyle(color: _muted, fontSize: 12),
                    prefixIcon: const Icon(
                        Icons.location_on_outlined,
                        size: 18),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _runVenueSearch,
                    icon: const Icon(Icons.search, size: 16),
                    label: const Text('Search Available Venues'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding:
                          const EdgeInsets.symmetric(vertical: 13),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_venueResults.isEmpty)
            _emptyState(
              icon: Icons.meeting_room_outlined,
              title: 'Ready to search',
              subtitle:
                  'Set a time range, minimum capacity, and location, then tap Search.',
            )
          else ...[
            Text(
              '${_venueResults.length} ${_venueResults.length == 1 ? 'venue' : 'venues'} available',
              style: const TextStyle(
                  color: _ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            ..._venueResults
                .map((r) => _venueCard(r, unbookedPublished)),
          ],
        ],
      ),
    );
  }

  void _runVenueSearch() {
    setState(() {
      _venueResults = _auth.searchAvailableRooms(
        start: _venueSearchStart,
        end: _venueSearchEnd,
        minCapacity: _venueMinCap,
        locationQuery: _locationCtrl.text,
      );
    });
  }

  Widget _venueCard(
      Map<String, dynamic> r, List<Map<String, dynamic>> unbookedEvents) {
    final room = r['room'] as Map<String, dynamic>;
    final building = r['building'] as Map<String, dynamic>;
    final amenities = (room['amenities'] as List).cast<String>();
    final pricing = room['pricing'] as double?;
    final cap = room['capacity'] as int? ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(room['name'] as String? ?? '',
              style: const TextStyle(
                  color: _ink,
                  fontWeight: FontWeight.w700,
                  fontSize: 15)),
          const SizedBox(height: 2),
          _infoRow(Icons.location_city_outlined,
              building['name'] as String? ?? ''),
          _infoRow(Icons.place_outlined,
              building['address'] as String? ?? ''),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              _chip('$cap capacity', Icons.people_outline),
              if (pricing != null)
                _chip('£${pricing.toStringAsFixed(0)}/hr',
                    Icons.sell_outlined),
              ...amenities.take(4).map((a) => _chip(a, Icons.check_outlined)),
            ],
          ),
          if (unbookedEvents.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('Book for an event:',
                style: TextStyle(color: _muted, fontSize: 12)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: unbookedEvents.map((e) {
                return GestureDetector(
                  onTap: () {
                    final err = _auth.createBooking(
                      eventId: e['id'] as String,
                      roomId: room['id'] as String,
                      start: e['start'] as DateTime,
                      end: e['end'] as DateTime,
                    );
                    if (err != null) {
                      _snack(err, error: true);
                      return;
                    }
                    setState(() => _venueResults = []);
                    _snack('Venue booked for "${e['title']}".');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _accent.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: _accent.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add, size: 12, color: _accent),
                        const SizedBox(width: 4),
                        Text(
                          e['title'] as String? ?? '',
                          style: const TextStyle(
                            color: _accent,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  // ── Analytics Tab ─────────────────────────────────────────

  Widget _buildAnalyticsTab(List<Map<String, dynamic>> events) {
    if (events.isEmpty) {
      return _emptyState(
        icon: Icons.bar_chart_outlined,
        title: 'No events to analyse',
        subtitle:
            'Create and publish events to see registration and attendance analytics here.',
      );
    }

    final published =
        events.where((e) => e['status'] == 'published').toList();
    final totalRegistered = events.fold<int>(
        0, (s, e) => s + _reg.countForEvent(e['id'] as String));
    final totalExpected =
        events.fold<int>(0, (s, e) => s + ((e['expectedAttendees'] as int?) ?? 0));
    final rate = totalExpected > 0
        ? (totalRegistered / totalExpected * 100).toStringAsFixed(0)
        : '0';

    Map<String, dynamic>? topEvent;
    int topCount = 0;
    for (final e in events) {
      final c = _reg.countForEvent(e['id'] as String);
      if (c > topCount) {
        topCount = c;
        topEvent = e;
      }
    }

    final chartEvents = published.take(6).toList();
    final maxY = chartEvents.fold<double>(
          0,
          (m, e) => (e['expectedAttendees'] as int? ?? 0) > m
              ? (e['expectedAttendees'] as int).toDouble()
              : m,
        ) *
        1.25;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Analytics',
              style: TextStyle(
                  color: _ink, fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text(
            'A clear picture of how attendees are engaging with your events.',
            style: TextStyle(color: _muted, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 14),

          // Summary cards
          Row(
            children: [
              Expanded(
                child: _analyticsCard('$totalRegistered', 'Total Registered',
                    Icons.how_to_reg_outlined, const Color(0xFF1565C0)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _analyticsCard('$rate%', 'Fill Rate',
                    Icons.pie_chart_outline, const Color(0xFF2E7D32)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _analyticsCard('$topCount', 'Best Event',
                    Icons.star_outline, const Color(0xFFE65100)),
              ),
            ],
          ),
          if (topEvent != null) ...[
            const SizedBox(height: 6),
            Text(
              'Most popular: ${topEvent['title']}',
              style: const TextStyle(color: _muted, fontSize: 11),
            ),
          ],

          const SizedBox(height: 20),

          // Bar chart
          if (chartEvents.isNotEmpty) ...[
            const Text('Registrations vs Expected',
                style: TextStyle(
                    color: _ink, fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            const Text(
              'Dark bar = registered attendees. Light bar = expected attendees.',
              style: TextStyle(color: _muted, fontSize: 12, height: 1.4),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
              decoration: BoxDecoration(
                color: _white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _border),
              ),
              height: 220,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxY < 10 ? 10 : maxY,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, gIdx, rod, rIdx) {
                        if (gIdx >= chartEvents.length) return null;
                        final label = rIdx == 0 ? 'Registered' : 'Expected';
                        return BarTooltipItem(
                          '$label\n${rod.toY.round()}',
                          const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, _) {
                          final i = v.round();
                          if (i < 0 || i >= chartEvents.length) {
                            return const SizedBox();
                          }
                          final t =
                              chartEvents[i]['title'] as String? ?? '';
                          final short =
                              t.length > 10 ? '${t.substring(0, 10)}…' : t;
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(short,
                                style: const TextStyle(
                                    fontSize: 9, color: _muted),
                                textAlign: TextAlign.center),
                          );
                        },
                        reservedSize: 30,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        getTitlesWidget: (v, _) => Text(
                          v.round().toString(),
                          style:
                              const TextStyle(fontSize: 10, color: _muted),
                        ),
                      ),
                    ),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxY < 10 ? 2 : maxY / 5,
                    getDrawingHorizontalLine: (_) => const FlLine(
                      color: Color(0xFFF0F0F0),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(chartEvents.length, (i) {
                    final e = chartEvents[i];
                    final registered =
                        _reg.countForEvent(e['id'] as String).toDouble();
                    final expected =
                        (e['expectedAttendees'] as int? ?? 0).toDouble();
                    return BarChartGroupData(
                      x: i,
                      barsSpace: 3,
                      barRods: [
                        BarChartRodData(
                          toY: registered,
                          color: const Color(0xFF1A1A1A),
                          width: 10,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4)),
                        ),
                        BarChartRodData(
                          toY: expected,
                          color: const Color(0xFFE0E0E0),
                          width: 10,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4)),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                _legendDot(const Color(0xFF1A1A1A)),
                const SizedBox(width: 5),
                const Text('Registered',
                    style: TextStyle(color: _muted, fontSize: 11)),
                const SizedBox(width: 14),
                _legendDot(const Color(0xFFE0E0E0)),
                const SizedBox(width: 5),
                const Text('Expected',
                    style: TextStyle(color: _muted, fontSize: 11)),
              ],
            ),
          ],

          const SizedBox(height: 20),

          // Per-event breakdown
          const Text('Event Breakdown',
              style: TextStyle(
                  color: _ink, fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          ...events.map((e) => _breakdownRow(e)),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _breakdownRow(Map<String, dynamic> e) {
    final title = e['title'] as String? ?? '';
    final expected = (e['expectedAttendees'] as int? ?? 0);
    final regs = _reg.registrationsForEvent(e['id'] as String);
    final registered = regs.length;
    final attended =
        regs.where((r) => r['attended'] == true).length;
    final fill = expected > 0 ? (registered / expected).clamp(0.0, 1.0) : 0.0;
    final status = _eventStatus(e);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title,
                    style: const TextStyle(
                        color: _ink,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
              ),
              _badgePill(status.toUpperCase(), _statusColor(status),
                  bg: _statusColor(status).withOpacity(0.1)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fill,
              backgroundColor: const Color(0xFFF0F0F0),
              valueColor: AlwaysStoppedAnimation<Color>(
                fill >= 0.8
                    ? const Color(0xFF2E7D32)
                    : fill >= 0.4
                        ? const Color(0xFF1565C0)
                        : const Color(0xFF9E9E9E),
              ),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _inlineStat('$registered', 'registered'),
              const SizedBox(width: 14),
              _inlineStat('$expected', 'expected'),
              const SizedBox(width: 14),
              _inlineStat('$attended', 'attended'),
              const Spacer(),
              Text('${(fill * 100).toStringAsFixed(0)}% full',
                  style: const TextStyle(
                      color: _muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  // ── Micro-widgets ─────────────────────────────────────────

  Widget _statTile(String label, String value, IconData icon,
      {Color? color}) {
    return Container(
      width: 110,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: color ?? _muted),
              const SizedBox(width: 4),
              Expanded(
                child: Text(label,
                    style: TextStyle(
                        color: color ?? _muted,
                        fontSize: 10,
                        fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(value,
              style: const TextStyle(
                  color: _ink, fontSize: 22, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _analyticsCard(
      String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: _muted, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          Icon(icon, size: 13, color: _muted),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text,
                style: const TextStyle(color: _muted, fontSize: 12),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  Widget _pill(String label, IconData icon, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (color ?? _muted).withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color ?? _muted),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  color: color ?? _muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _chip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
          color: const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(6)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: _muted),
          const SizedBox(width: 3),
          Text(label,
              style: const TextStyle(
                  color: _muted, fontSize: 10, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _badgePill(String label, Color fg, {required Color bg}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(label,
          style: TextStyle(
              color: fg, fontSize: 10, fontWeight: FontWeight.w700)),
    );
  }

  Widget _conflictBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFFFCC02)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.warning_amber_rounded,
              size: 10, color: Color(0xFFE65100)),
          SizedBox(width: 3),
          Text('TIME CONFLICT',
              style: TextStyle(
                  color: Color(0xFFE65100),
                  fontSize: 9,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _inlineStat(String value, String label) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: value,
            style: const TextStyle(
                color: _ink, fontSize: 13, fontWeight: FontWeight.w700),
          ),
          TextSpan(
            text: ' $label',
            style: const TextStyle(color: _muted, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color) {
    return Container(
      width: 10,
      height: 10,
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
    );
  }

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0F0),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, size: 28, color: _muted),
          ),
          const SizedBox(height: 16),
          Text(title,
              style: const TextStyle(
                  color: _ink,
                  fontWeight: FontWeight.w700,
                  fontSize: 15)),
          const SizedBox(height: 6),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: _muted, fontSize: 13, height: 1.5)),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) return const SizedBox();
    final events = _auth.organizerEvents;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Organiser',
                style: TextStyle(
                    color: _ink,
                    fontWeight: FontWeight.w800,
                    fontSize: 17)),
            Text(user.fullName,
                style: const TextStyle(
                    color: _muted, fontSize: 12, fontWeight: FontWeight.w400)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline, color: _ink),
            tooltip: 'Profile',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ).then((_) => setState(() {})),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: _ink),
            tooltip: 'Log out',
            onPressed: () {
              _auth.logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LandingScreen()),
                (r) => false,
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: Container(
            decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: _border))),
            child: TabBar(
              controller: _tabCtrl,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: _ink,
              unselectedLabelColor: _muted,
              labelStyle: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 12),
              unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w500, fontSize: 12),
              indicator: const UnderlineTabIndicator(
                  borderSide: BorderSide(color: _ink, width: 2.5)),
              indicatorSize: TabBarIndicatorSize.label,
              tabs: List.generate(
                _tabs.length,
                (i) => Tab(
                  height: 44,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_tabIcons[i], size: 14),
                      const SizedBox(width: 5),
                      Text(_tabs[i]),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildEventsTab(events),
          _buildAttendeesTab(events),
          _buildVenuesTab(events),
          _buildAnalyticsTab(events),
        ],
      ),
    );
  }
}
