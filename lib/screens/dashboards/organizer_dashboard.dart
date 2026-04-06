import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import '../profile_screen.dart';
import '../landing_screen.dart';

class OrganizerDashboard extends StatefulWidget {
  const OrganizerDashboard({super.key});

  @override
  State<OrganizerDashboard> createState() => _OrganizerDashboardState();
}

class _OrganizerDashboardState extends State<OrganizerDashboard> {
  final _auth = AuthService();
  bool _redirecting = false;
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _attendeesCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _amenitiesCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
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
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _categoryCtrl.dispose();
    _attendeesCtrl.dispose();
    _locationCtrl.dispose();
    _amenitiesCtrl.dispose();
    super.dispose();
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.redAccent : const Color(0xFF2D2D2D),
    ));
  }

  Future<void> _showCreateEventSheet({Map<String, dynamic>? template}) async {
    _titleCtrl.text = (template?['title'] as String?) ?? '';
    _descCtrl.text = (template?['description'] as String?) ?? '';
    _categoryCtrl.text = (template?['category'] as String?) ?? '';
    _attendeesCtrl.text = ((template?['expectedAttendees'] as int?) ?? 50).toString();

    DateTime start = DateTime.now().add(const Duration(days: 2));
    DateTime end = start.add(const Duration(hours: 3));

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFFFFFFF),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setS) => Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    template == null ? 'Create Event' : 'Create from Template',
                    style: const TextStyle(
                      color: Color(0xFF1A1A1A),
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _titleCtrl,
                    decoration: const InputDecoration(labelText: 'Title'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _descCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Description'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _categoryCtrl,
                    decoration: const InputDecoration(labelText: 'Category (optional)'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _attendeesCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Expected Attendees'),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: () async {
                      final d = await showDatePicker(
                        context: ctx,
                        initialDate: start,
                        firstDate: DateTime.now(),
                        lastDate: DateTime(DateTime.now().year + 2),
                      );
                      if (!ctx.mounted) return;
                      if (d == null) return;
                      final st = await showTimePicker(
                        context: ctx,
                        initialTime: const TimeOfDay(hour: 10, minute: 0),
                      );
                      if (!ctx.mounted) return;
                      if (st == null) return;
                      final et = await showTimePicker(
                        context: ctx,
                        initialTime: const TimeOfDay(hour: 13, minute: 0),
                      );
                      if (!ctx.mounted) return;
                      if (et == null) return;
                      setS(() {
                        start = DateTime(d.year, d.month, d.day, st.hour, st.minute);
                        end = DateTime(d.year, d.month, d.day, et.hour, et.minute);
                      });
                    },
                    child: Text('Schedule: ${start.day}/${start.month} ${start.hour}:${start.minute.toString().padLeft(2, '0')}'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            final err = _auth.upsertOrganizerEvent(
                              title: _titleCtrl.text,
                              description: _descCtrl.text,
                              category: _categoryCtrl.text,
                              start: start,
                              end: end,
                              expectedAttendees: int.tryParse(_attendeesCtrl.text) ?? 0,
                              status: 'draft',
                              templateSource: template,
                            );
                            if (err != null) {
                              _showSnack(err, isError: true);
                              return;
                            }
                            Navigator.pop(ctx);
                            setState(() {});
                          },
                          child: const Text('Save Draft'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            final err = _auth.upsertOrganizerEvent(
                              title: _titleCtrl.text,
                              description: _descCtrl.text,
                              category: _categoryCtrl.text,
                              start: start,
                              end: end,
                              expectedAttendees: int.tryParse(_attendeesCtrl.text) ?? 0,
                              status: 'published',
                              templateSource: template,
                            );
                            if (err != null) {
                              _showSnack(err, isError: true);
                              return;
                            }
                            Navigator.pop(ctx);
                            setState(() {});
                          },
                          child: const Text('Publish'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _bookVenue(Map<String, dynamic> event) async {
    _locationCtrl.clear();
    _amenitiesCtrl.clear();
    final attendees = event['expectedAttendees'] as int;
    final start = event['start'] as DateTime;
    final end = event['end'] as DateTime;
    List<Map<String, dynamic>> results = _auth.searchAvailableRooms(
      start: start,
      end: end,
      minCapacity: attendees,
    );

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFFFFFFF),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setS) => Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Book Venue',
                  style: TextStyle(
                    color: Color(0xFF1A1A1A),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _locationCtrl,
                  decoration: const InputDecoration(labelText: 'Location filter'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _amenitiesCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Amenities filter (comma separated)',
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () {
                    final amenities = _amenitiesCtrl.text
                        .split(',')
                        .map((a) => a.trim())
                        .where((a) => a.isNotEmpty)
                        .toList();
                    setS(() {
                      results = _auth.searchAvailableRooms(
                        start: start,
                        end: end,
                        minCapacity: attendees,
                        locationQuery: _locationCtrl.text,
                        amenities: amenities,
                      );
                    });
                  },
                  child: const Text('Search'),
                ),
                const SizedBox(height: 10),
                if (results.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 8, bottom: 8),
                    child: Text('No available rooms found for this event window.'),
                  )
                else
                  ...results.take(5).map((r) {
                    final room = r['room'] as Map<String, dynamic>;
                    final building = r['building'] as Map<String, dynamic>;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F2F2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${building['name']} · ${room['name']} · cap ${room['capacity']}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              final err = _auth.createBooking(
                                eventId: event['id'] as String,
                                roomId: room['id'] as String,
                                start: start,
                                end: end,
                              );
                              if (err != null) {
                                _showSnack(err, isError: true);
                                return;
                              }
                              Navigator.pop(ctx);
                              setState(() {});
                              _showSnack('Booking confirmed.');
                            },
                            child: const Text('Select'),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser!;
    final events = _auth.organizerEvents;
    final totalEvents = events.length;
    final totalAttendees = events.fold<int>(
      0,
      (sum, e) => sum + ((e['expectedAttendees'] as int?) ?? 0),
    );
    final now = DateTime.now();
    final upcoming = events.where((e) => (e['start'] as DateTime).isAfter(now)).length;
    final past = events.where((e) => (e['end'] as DateTime).isBefore(now)).length;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFFFF),
        elevation: 0,
        title: const Text(
          'Organizer',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline, color: Color(0xFF1A1A1A)),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ).then((_) => setState(() {})),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Color(0xFF1A1A1A)),
            tooltip: 'Logout',
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
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateEventSheet,
        backgroundColor: const Color(0xFF2D2D2D),
        icon: const Icon(Icons.add),
        label: const Text('New Event'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello, ${user.fullName}',
              style: const TextStyle(
                color: Color(0xFF1A1A1A),
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Create events, reuse templates, and book venues.',
              style: TextStyle(color: Color(0xFF6B6B6B)),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _stat('Events', '$totalEvents'),
                _stat('Attendees', '$totalAttendees'),
                _stat('Upcoming', '$upcoming'),
                _stat('Past', '$past'),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'My Events',
              style: TextStyle(
                color: Color(0xFF1A1A1A),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            if (events.isEmpty)
              const Text('No events yet. Create your first event.')
            else
              ...events.map((e) {
                final booking = _auth.bookingForEvent(e['id'] as String);
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFFFF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE8E8E8)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              e['title'] as String,
                              style: const TextStyle(
                                color: Color(0xFF1A1A1A),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              final err = _auth.deleteOrganizerEvent(e['id'] as String);
                              if (err != null) {
                                _showSnack(err, isError: true);
                                return;
                              }
                              setState(() {});
                            },
                            icon: const Icon(Icons.delete_outline, color: Color(0xFF6B6B6B)),
                          ),
                        ],
                      ),
                      Text(
                        '${e['status']} · ${e['expectedAttendees']} attendees',
                        style: const TextStyle(color: Color(0xFF6B6B6B), fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      if (booking == null)
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _bookVenue(e),
                                child: const Text('Book Venue'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _showCreateEventSheet(template: e),
                                child: const Text('Duplicate'),
                              ),
                            ),
                          ],
                        )
                      else
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Booking: ${booking['status']}',
                                style: const TextStyle(
                                  color: Color(0xFF1A1A1A),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                _auth.cancelBooking(booking['id'] as String);
                                setState(() {});
                              },
                              child: const Text('Cancel Booking'),
                            ),
                          ],
                        ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF1A1A1A),
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(label, style: const TextStyle(color: Color(0xFF6B6B6B))),
        ],
      ),
    );
  }
}
