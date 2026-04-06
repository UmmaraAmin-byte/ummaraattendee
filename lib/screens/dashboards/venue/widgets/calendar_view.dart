import 'package:flutter/material.dart';
import '../../../../../models/booking_model.dart';
import '../../../../../services/booking_management_service.dart';

enum _ViewMode { month, week, day }

class VenueCalendarView extends StatefulWidget {
  final String ownerId;
  const VenueCalendarView({super.key, required this.ownerId});

  @override
  State<VenueCalendarView> createState() => _VenueCalendarViewState();
}

class _VenueCalendarViewState extends State<VenueCalendarView> {
  late DateTime _weekStart;
  _ViewMode _viewMode = _ViewMode.week;
  DateTime _selectedDay = DateTime.now();
  late DateTime _monthStart;

  static const double _hourHeight = 64.0;
  static const double _startHour = 6.0;
  static const double _endHour = 22.0;
  static const double _totalHours = _endHour - _startHour;
  static const double _timeAxisWidth = 52.0;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _weekStart = _mondayOf(now);
    _monthStart = DateTime(now.year, now.month, 1);
  }

  DateTime _mondayOf(DateTime d) {
    final diff = d.weekday - 1;
    return DateTime(d.year, d.month, d.day - diff);
  }

  List<DateTime> get _weekDays =>
      List.generate(7, (i) => _weekStart.add(Duration(days: i)));

  List<BookingModel> get _bookings =>
      BookingManagementService().getBookingsForOwner(widget.ownerId);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildViewToggle(),
        const SizedBox(height: 12),
        _buildToolbar(),
        const SizedBox(height: 12),
        if (_viewMode == _ViewMode.month)
          _buildMonthView()
        else if (_viewMode == _ViewMode.week)
          _buildWeekView()
        else
          _buildDayView(),
      ],
    );
  }

  Widget _buildViewToggle() {
    return Row(
      children: [
        Expanded(
          child: _ViewToggleButton(
            label: 'Month',
            icon: Icons.calendar_month_outlined,
            selected: _viewMode == _ViewMode.month,
            onTap: () => setState(() => _viewMode = _ViewMode.month),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ViewToggleButton(
            label: 'Week',
            icon: Icons.view_week_outlined,
            selected: _viewMode == _ViewMode.week,
            onTap: () => setState(() => _viewMode = _ViewMode.week),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ViewToggleButton(
            label: 'Day',
            icon: Icons.view_day_outlined,
            selected: _viewMode == _ViewMode.day,
            onTap: () => setState(() => _viewMode = _ViewMode.day),
          ),
        ),
      ],
    );
  }

  Widget _buildToolbar() {
    String title;
    switch (_viewMode) {
      case _ViewMode.month:
        title = _formatMonth(_monthStart);
        break;
      case _ViewMode.week:
        title = _formatWeekRange();
        break;
      case _ViewMode.day:
        title = _formatDay(_selectedDay);
        break;
    }

    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left, color: Color(0xFF1A1A1A)),
          onPressed: () => setState(() {
            switch (_viewMode) {
              case _ViewMode.month:
                _monthStart = DateTime(
                    _monthStart.year, _monthStart.month - 1, 1);
                break;
              case _ViewMode.week:
                _weekStart =
                    _weekStart.subtract(const Duration(days: 7));
                break;
              case _ViewMode.day:
                _selectedDay =
                    _selectedDay.subtract(const Duration(days: 1));
                break;
            }
          }),
        ),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xFF1A1A1A),
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right, color: Color(0xFF1A1A1A)),
          onPressed: () => setState(() {
            switch (_viewMode) {
              case _ViewMode.month:
                _monthStart = DateTime(
                    _monthStart.year, _monthStart.month + 1, 1);
                break;
              case _ViewMode.week:
                _weekStart = _weekStart.add(const Duration(days: 7));
                break;
              case _ViewMode.day:
                _selectedDay =
                    _selectedDay.add(const Duration(days: 1));
                break;
            }
          }),
        ),
        Material(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => setState(() {
              final now = DateTime.now();
              _weekStart = _mondayOf(now);
              _selectedDay = now;
              _monthStart = DateTime(now.year, now.month, 1);
            }),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: Text(
                'Today',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMonthView() {
    final bookings = _bookings;
    final today = DateTime.now();
    final firstDayOfMonth = _monthStart;
    final daysInMonth =
        DateTime(firstDayOfMonth.year, firstDayOfMonth.month + 1, 0).day;
    final firstWeekday = firstDayOfMonth.weekday;
    final leadingEmpty = firstWeekday - 1;
    final totalCells = leadingEmpty + daysInMonth;
    final rows = (totalCells / 7).ceil();

    Map<int, List<BookingModel>> bookingsByDay = {};
    for (final b in bookings) {
      if (b.isCancelled) continue;
      if (b.start.year == firstDayOfMonth.year &&
          b.start.month == firstDayOfMonth.month) {
        final day = b.start.day;
        bookingsByDay.putIfAbsent(day, () => []).add(b);
      }
    }

    return Column(
      children: [
        Row(
          children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
              .map(
                (d) => Expanded(
                  child: Center(
                    child: Text(
                      d,
                      style: const TextStyle(
                          color: Color(0xFF9B9B9B),
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 8),
        ...List.generate(rows, (row) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: List.generate(7, (col) {
                final cellIndex = row * 7 + col;
                final dayNum = cellIndex - leadingEmpty + 1;
                if (dayNum < 1 || dayNum > daysInMonth) {
                  return Expanded(child: Container(height: 52));
                }
                final isToday = today.year == firstDayOfMonth.year &&
                    today.month == firstDayOfMonth.month &&
                    today.day == dayNum;
                final isSelected = _selectedDay.year == firstDayOfMonth.year &&
                    _selectedDay.month == firstDayOfMonth.month &&
                    _selectedDay.day == dayNum;
                final dayBookings = bookingsByDay[dayNum] ?? [];
                final hasPending =
                    dayBookings.any((b) => b.isPending);
                final hasConfirmed =
                    dayBookings.any((b) => b.isActive);

                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _selectedDay = DateTime(
                          firstDayOfMonth.year,
                          firstDayOfMonth.month,
                          dayNum);
                      _viewMode = _ViewMode.day;
                    }),
                    child: Container(
                      height: 52,
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF1A1A1A)
                            : isToday
                                ? const Color(0xFFF5F5F5)
                                : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: isToday && !isSelected
                            ? Border.all(
                                color: const Color(0xFF1A1A1A), width: 1)
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
                                  : const Color(0xFF1A1A1A),
                              fontSize: 13,
                              fontWeight: isToday || isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                            ),
                          ),
                          if (dayBookings.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (hasConfirmed)
                                  Container(
                                    width: 5,
                                    height: 5,
                                    margin: const EdgeInsets.only(right: 2),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Colors.white
                                          : const Color(0xFF1A1A1A),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                if (hasPending)
                                  Container(
                                    width: 5,
                                    height: 5,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Colors.white54
                                          : const Color(0xFF9B9B9B),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          );
        }),
        const SizedBox(height: 12),
        Row(
          children: [
            _LegendDot(
                color: const Color(0xFF1A1A1A), label: 'Confirmed'),
            const SizedBox(width: 16),
            _LegendDot(
                color: const Color(0xFF9B9B9B), label: 'Pending'),
          ],
        ),
      ],
    );
  }

  Widget _buildWeekView() {
    final days = _weekDays;
    final today = DateTime.now();

    return Column(
      children: [
        Row(
          children: [
            SizedBox(width: _timeAxisWidth),
            ...days.map((d) {
              final isToday = d.year == today.year &&
                  d.month == today.month &&
                  d.day == today.day;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() {
                    _selectedDay = d;
                    _viewMode = _ViewMode.day;
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isToday
                          ? const Color(0xFFF5F5F5)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text(
                          _dayAbbr(d.weekday),
                          style: TextStyle(
                            color: isToday
                                ? const Color(0xFF1A1A1A)
                                : const Color(0xFF9B9B9B),
                            fontSize: 11,
                            fontWeight: isToday
                                ? FontWeight.w700
                                : FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${d.day}',
                          style: const TextStyle(
                            color: Color(0xFF1A1A1A),
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
        const Divider(height: 1, color: Color(0xFFE8E8E8)),
        const SizedBox(height: 8),
        SizedBox(
          height: _totalHours * _hourHeight,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final dayWidth = (constraints.maxWidth - _timeAxisWidth) / 7;
              return Stack(
                children: [
                  _buildTimeGrid(constraints.maxWidth),
                  ..._buildWeekBookingBlocks(days, dayWidth),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDayView() {
    final today = DateTime.now();
    final isToday = _selectedDay.year == today.year &&
        _selectedDay.month == today.month &&
        _selectedDay.day == today.day;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isToday
                ? const Color(0xFFF5F5F5)
                : const Color(0xFFF9F9F9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            _formatDay(_selectedDay),
            style: const TextStyle(
              color: Color(0xFF1A1A1A),
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Divider(height: 1, color: Color(0xFFE8E8E8)),
        SizedBox(
          height: _totalHours * _hourHeight,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final colWidth = constraints.maxWidth - _timeAxisWidth;
              return Stack(
                children: [
                  _buildTimeGrid(constraints.maxWidth),
                  ..._buildDayBookingBlocks(_selectedDay, colWidth),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTimeGrid(double totalWidth) {
    return SizedBox(
      width: totalWidth,
      height: _totalHours * _hourHeight,
      child: Stack(
        children: List.generate((_totalHours).toInt() + 1, (i) {
          final y = i * _hourHeight;
          final hour = (_startHour + i).toInt();
          return Positioned(
            top: y,
            left: 0,
            right: 0,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: _timeAxisWidth,
                  child: Text(
                    _hourLabel(hour),
                    style: const TextStyle(
                        color: Color(0xFF9B9B9B), fontSize: 10),
                    textAlign: TextAlign.right,
                  ),
                ),
                Expanded(
                  child: Container(
                    height: 1,
                    color: const Color(0xFFEEEEEE),
                    margin: const EdgeInsets.only(left: 6),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  List<Widget> _buildWeekBookingBlocks(
      List<DateTime> days, double dayWidth) {
    final bookings = _bookings;
    final widgets = <Widget>[];
    for (final b in bookings) {
      if (b.isCancelled) continue;
      for (var i = 0; i < days.length; i++) {
        final day = days[i];
        if (b.start.year == day.year &&
            b.start.month == day.month &&
            b.start.day == day.day) {
          final top = _topOffset(b.start);
          final height = _blockHeight(b).clamp(24.0, _totalHours * _hourHeight - top);
          if (top < 0) continue;
          widgets.add(Positioned(
            left: _timeAxisWidth + i * dayWidth + 2,
            width: dayWidth - 4,
            top: top,
            height: height,
            child: _BookingBlock(
              booking: b,
              compact: true,
              onTap: () => _showBookingDetails(b),
            ),
          ));
        }
      }
    }
    return widgets;
  }

  List<Widget> _buildDayBookingBlocks(DateTime day, double colWidth) {
    final bookings = _bookings;
    final widgets = <Widget>[];
    for (final b in bookings) {
      if (b.isCancelled) continue;
      if (b.start.year != day.year ||
          b.start.month != day.month ||
          b.start.day != day.day) continue;

      final top = _topOffset(b.start);
      final height = _blockHeight(b).clamp(28.0, _totalHours * _hourHeight - top);
      if (top < 0) continue;
      widgets.add(Positioned(
        left: _timeAxisWidth + 4,
        width: colWidth - 8,
        top: top,
        height: height,
        child: _BookingBlock(
          booking: b,
          compact: false,
          onTap: () => _showBookingDetails(b),
        ),
      ));
    }
    return widgets;
  }

  double _topOffset(DateTime dt) {
    final h = dt.hour + dt.minute / 60.0;
    return (h - _startHour) * _hourHeight;
  }

  double _blockHeight(BookingModel b) {
    return b.duration.inMinutes / 60.0 * _hourHeight;
  }

  void _showBookingDetails(BookingModel b) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(b.eventTitle,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow(Icons.person_outline, b.organizerName),
            const SizedBox(height: 6),
            _detailRow(Icons.meeting_room_outlined,
                '${b.roomName} · ${b.buildingName}'),
            const SizedBox(height: 6),
            _detailRow(
                Icons.schedule_outlined,
                '${_hhmm(b.start)} – ${_hhmm(b.end)}'),
            if (b.revenue > 0) ...[
              const SizedBox(height: 6),
              _detailRow(Icons.attach_money_rounded,
                  '\$${b.revenue.toStringAsFixed(2)}'),
            ],
            const SizedBox(height: 10),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: b.isPending
                    ? const Color(0xFFF5F5F5)
                    : b.isActive
                        ? const Color(0xFFEEEEEE)
                        : const Color(0xFFF2F2F2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                b.managedStatus.toUpperCase(),
                style: TextStyle(
                  color: b.isPending
                      ? const Color(0xFF6B6B6B)
                      : b.isActive
                          ? const Color(0xFF3D3D3D)
                          : const Color(0xFF9B9B9B),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String text, {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF9B9B9B)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
                color: color ?? const Color(0xFF1A1A1A), fontSize: 13),
          ),
        ),
      ],
    );
  }

  String _formatMonth(DateTime d) {
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[d.month]} ${d.year}';
  }

  String _formatWeekRange() {
    final end = _weekStart.add(const Duration(days: 6));
    return '${_monthAbbr(_weekStart.month)} ${_weekStart.day} – ${_monthAbbr(end.month)} ${end.day}, ${end.year}';
  }

  String _formatDay(DateTime d) {
    const days = [
      '', 'Monday', 'Tuesday', 'Wednesday',
      'Thursday', 'Friday', 'Saturday', 'Sunday',
    ];
    return '${days[d.weekday]}, ${_monthAbbr(d.month)} ${d.day} ${d.year}';
  }

  String _dayAbbr(int weekday) {
    const abbrs = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return abbrs[weekday];
  }

  String _monthAbbr(int m) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return months[m];
  }

  String _hourLabel(int h) {
    if (h == 0) return '12AM';
    if (h < 12) return '${h}AM';
    if (h == 12) return '12PM';
    return '${h - 12}PM';
  }

  String _hhmm(DateTime dt) {
    final h = dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    final suffix = h >= 12 ? 'PM' : 'AM';
    final hour = h % 12 == 0 ? 12 : h % 12;
    return '$hour:$m $suffix';
  }
}

class _BookingBlock extends StatelessWidget {
  final BookingModel booking;
  final bool compact;
  final VoidCallback onTap;
  const _BookingBlock(
      {required this.booking,
      required this.compact,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isPending = booking.isPending;
    final blockBg = isPending
        ? const Color(0xFFF5F5F5)
        : const Color(0xFFEEEEEE);
    final blockBorder = isPending
        ? const Color(0xFFD0D0D0)
        : const Color(0xFF1A1A1A);
    final textColor = isPending
        ? const Color(0xFF6B6B6B)
        : const Color(0xFF1A1A1A);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            EdgeInsets.symmetric(horizontal: compact ? 4 : 8, vertical: 3),
        decoration: BoxDecoration(
          color: blockBg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: blockBorder, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              booking.eventTitle,
              style: TextStyle(
                color: textColor,
                fontSize: compact ? 9 : 11,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (!compact) ...[
              Text(
                booking.roomName,
                style: const TextStyle(
                    color: Color(0xFF6B6B6B), fontSize: 10),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ViewToggleButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ViewToggleButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1A1A1A) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? const Color(0xFF1A1A1A)
                : const Color(0xFFE0E0E0),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 14,
              color: selected ? Colors.white : const Color(0xFF6B6B6B),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : const Color(0xFF6B6B6B),
                fontSize: 12,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
              color: Color(0xFF6B6B6B), fontSize: 11),
        ),
      ],
    );
  }
}
