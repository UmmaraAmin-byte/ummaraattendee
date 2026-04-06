import 'package:flutter/material.dart';
import '../../../services/auth_service.dart';
import '../../../models/user_model.dart';

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

Color _catColor(String c) => _categoryColors[c] ?? const Color(0xFF2D2D2D);

enum _CalView { month, week }

class AttendeeCalendarTab extends StatefulWidget {
  final Set<String> registeredIds;
  final void Function(Map<String, dynamic>) onToggleRegistration;
  final void Function(Map<String, dynamic>) onEventTap;
  final String Function(Map<String, dynamic>) locationLabel;
  final String Function(Map<String, dynamic>) organizerName;

  const AttendeeCalendarTab({
    super.key,
    required this.registeredIds,
    required this.onToggleRegistration,
    required this.onEventTap,
    required this.locationLabel,
    required this.organizerName,
  });

  @override
  State<AttendeeCalendarTab> createState() => _AttendeeCalendarTabState();
}

class _AttendeeCalendarTabState extends State<AttendeeCalendarTab> {
  final _auth = AuthService();
  _CalView _view = _CalView.month;
  DateTime _focusMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _focusWeek = _mondayOf(DateTime.now());
  DateTime? _selectedDay;

  static DateTime _mondayOf(DateTime d) {
    final diff = d.weekday - 1;
    return DateTime(d.year, d.month, d.day - diff);
  }

  List<Map<String, dynamic>> get _publishedEvents => _auth.allEvents
      .where((e) => e['status'] == 'published' && e['start'] != null)
      .toList();

  List<Map<String, dynamic>> _eventsOnDay(DateTime day) {
    return _publishedEvents.where((e) {
      final start = e['start'] as DateTime;
      return start.year == day.year &&
          start.month == day.month &&
          start.day == day.day;
    }).toList()
      ..sort((a, b) => (a['start'] as DateTime).compareTo(b['start'] as DateTime));
  }

  String _fmt(DateTime dt) {
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${dt.day} ${months[dt.month - 1]}';
  }

  String _fmtTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── View toggle
        _viewToggle(),
        const SizedBox(height: 16),

        if (_view == _CalView.month) ...[
          _monthToolbar(),
          const SizedBox(height: 12),
          _monthGrid(),
        ] else ...[
          _weekToolbar(),
          const SizedBox(height: 12),
          _weekStrip(),
        ],

        // ── Selected day events
        if (_selectedDay != null) ...[
          const SizedBox(height: 16),
          _dayEventsList(_selectedDay!),
        ],
      ],
    );
  }

  Widget _viewToggle() {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: const Color(0xFFEEEEEE),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [_CalView.month, _CalView.week].map((v) {
          final sel = v == _view;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _view = v),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: sel ? const Color(0xFF1A1A1A) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  v == _CalView.month ? 'Month' : 'Week',
                  style: TextStyle(
                    color: sel ? Colors.white : const Color(0xFF6B6B6B),
                    fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── MONTH view ─────────────────────────────────────────────

  Widget _monthToolbar() {
    final months = ['January','February','March','April','May','June','July','August','September','October','November','December'];
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left, color: Color(0xFF1A1A1A)),
          onPressed: () => setState(() {
            _focusMonth = DateTime(_focusMonth.year, _focusMonth.month - 1, 1);
            _selectedDay = null;
          }),
        ),
        Expanded(
          child: Text(
            '${months[_focusMonth.month - 1]} ${_focusMonth.year}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF1A1A1A),
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right, color: Color(0xFF1A1A1A)),
          onPressed: () => setState(() {
            _focusMonth = DateTime(_focusMonth.year, _focusMonth.month + 1, 1);
            _selectedDay = null;
          }),
        ),
      ],
    );
  }

  Widget _monthGrid() {
    const dayHeaders = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final firstDay = _focusMonth;
    final lastDay = DateTime(_focusMonth.year, _focusMonth.month + 1, 0);
    // Offset: Monday = 1, so first cell offset = firstDay.weekday - 1
    final startOffset = firstDay.weekday - 1;
    final totalCells = startOffset + lastDay.day;
    final rows = (totalCells / 7).ceil();

    return Column(
      children: [
        // Header row
        Row(
          children: dayHeaders
              .map((d) => Expanded(
                    child: Center(
                      child: Text(d,
                          style: const TextStyle(
                            color: Color(0xFF9E9E9E),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          )),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 6),
        ...List.generate(rows, (row) {
          return Row(
            children: List.generate(7, (col) {
              final cellIndex = row * 7 + col;
              final dayNum = cellIndex - startOffset + 1;
              if (dayNum < 1 || dayNum > lastDay.day) {
                return const Expanded(child: SizedBox(height: 52));
              }
              final day = DateTime(_focusMonth.year, _focusMonth.month, dayNum);
              final events = _eventsOnDay(day);
              final isToday = _isToday(day);
              final isSelected = _selectedDay != null &&
                  _selectedDay!.day == day.day &&
                  _selectedDay!.month == day.month &&
                  _selectedDay!.year == day.year;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() =>
                      _selectedDay = isSelected ? null : day),
                  child: Container(
                    height: 52,
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF1A1A1A)
                          : isToday
                              ? const Color(0xFFF0F0F0)
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: isToday && !isSelected
                          ? Border.all(color: const Color(0xFFCCCCCC))
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$dayNum',
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : isToday
                                    ? const Color(0xFF1A1A1A)
                                    : const Color(0xFF2D2D2D),
                            fontSize: 13,
                            fontWeight: isToday || isSelected
                                ? FontWeight.w700
                                : FontWeight.w400,
                          ),
                        ),
                        if (events.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 2,
                            children: events.take(3).map((e) {
                              final cat = e['category'] as String? ?? '';
                              final reg = widget.registeredIds.contains(e['id']);
                              return Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.white
                                      : reg
                                          ? const Color(0xFF1A1A1A)
                                          : _catColor(cat),
                                  shape: BoxShape.circle,
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }),
          );
        }),
      ],
    );
  }

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.day == now.day && d.month == now.month && d.year == now.year;
  }

  // ── WEEK view ──────────────────────────────────────────────

  Widget _weekToolbar() {
    final end = _focusWeek.add(const Duration(days: 6));
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left, color: Color(0xFF1A1A1A)),
          onPressed: () => setState(() {
            _focusWeek = _focusWeek.subtract(const Duration(days: 7));
            _selectedDay = null;
          }),
        ),
        Expanded(
          child: Text(
            '${_fmt(_focusWeek)} – ${_fmt(end)}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF1A1A1A),
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right, color: Color(0xFF1A1A1A)),
          onPressed: () => setState(() {
            _focusWeek = _focusWeek.add(const Duration(days: 7));
            _selectedDay = null;
          }),
        ),
      ],
    );
  }

  Widget _weekStrip() {
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Row(
      children: List.generate(7, (i) {
        final day = _focusWeek.add(Duration(days: i));
        final events = _eventsOnDay(day);
        final isToday = _isToday(day);
        final isSelected = _selectedDay != null &&
            _selectedDay!.day == day.day &&
            _selectedDay!.month == day.month &&
            _selectedDay!.year == day.year;

        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() =>
                _selectedDay = isSelected ? null : day),
            child: Container(
              height: 72,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF1A1A1A)
                    : isToday
                        ? const Color(0xFFF0F0F0)
                        : const Color(0xFFFFFFFF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF1A1A1A)
                      : const Color(0xFFE8E8E8),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    labels[i],
                    style: TextStyle(
                      color: isSelected
                          ? const Color(0xFFB0B0B0)
                          : const Color(0xFF9E9E9E),
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${day.day}',
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF1A1A1A),
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (events.isNotEmpty)
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 2,
                      children: events.take(3).map((e) {
                        final cat = e['category'] as String? ?? '';
                        final reg = widget.registeredIds.contains(e['id']);
                        return Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white
                                : reg
                                    ? const Color(0xFF1A1A1A)
                                    : _catColor(cat),
                            shape: BoxShape.circle,
                          ),
                        );
                      }).toList(),
                    )
                  else
                    Container(width: 5, height: 5),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  // ── Day event list ─────────────────────────────────────────

  Widget _dayEventsList(DateTime day) {
    final events = _eventsOnDay(day);
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final label = '${day.day} ${months[day.month - 1]} ${day.year}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.event_outlined, size: 15, color: Color(0xFF1A1A1A)),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF1A1A1A),
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            const Spacer(),
            Text(
              '${events.length} event${events.length != 1 ? 's' : ''}',
              style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (events.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F8F8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE8E8E8)),
            ),
            child: const Center(
              child: Text(
                'No events on this day.',
                style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 13),
              ),
            ),
          )
        else
          ...events.map((e) => _dayEventTile(e)),
      ],
    );
  }

  Widget _dayEventTile(Map<String, dynamic> e) {
    final registered = widget.registeredIds.contains(e['id']);
    final category = (e['category'] as String? ?? '');
    final catColor = _catColor(category);
    final start = e['start'] as DateTime?;
    final end = e['end'] as DateTime?;
    final location = widget.locationLabel(e);
    final organizer = widget.organizerName(e);

    return GestureDetector(
      onTap: () => widget.onEventTap(e),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: registered ? const Color(0xFF1A1A1A) : const Color(0xFFE8E8E8),
            width: registered ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 52,
              decoration: BoxDecoration(
                color: catColor,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    e['title'] as String? ?? '',
                    style: const TextStyle(
                      color: Color(0xFF1A1A1A),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 3),
                  if (start != null)
                    Text(
                      '${_fmtTime(start)}${end != null ? ' – ${_fmtTime(end)}' : ''}',
                      style: const TextStyle(
                        color: Color(0xFF6B6B6B), fontSize: 12),
                    ),
                  if (location.isNotEmpty)
                    Text(
                      location,
                      style: const TextStyle(
                        color: Color(0xFF9E9E9E), fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (organizer.isNotEmpty)
                  Text(
                    organizer,
                    style: const TextStyle(
                      color: Color(0xFF9E9E9E), fontSize: 10),
                  ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => widget.onToggleRegistration(e),
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
}
