import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../../models/analytics_model.dart';

class AnalyticsOverviewCards extends StatelessWidget {
  final AnalyticsSnapshot data;
  const AnalyticsOverviewCards({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Business Metrics'),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: _MetricCard(
              icon: Icons.attach_money_rounded,
              label: 'Total Revenue',
              value: '\$${data.totalRevenue.toStringAsFixed(0)}',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _MetricCard(
              icon: Icons.trending_up_rounded,
              label: 'Avg Booking Value',
              value: '\$${data.avgBookingValue.toStringAsFixed(0)}',
            ),
          ),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: _MetricCard(
              icon: Icons.percent_rounded,
              label: 'Occupancy Rate',
              value: '${data.occupancyRate.toStringAsFixed(1)}%',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _MetricCard(
              icon: Icons.cancel_outlined,
              label: 'Cancellation Rate',
              value: '${data.cancellationRate.toStringAsFixed(1)}%',
              muted: true,
            ),
          ),
        ]),
        const SizedBox(height: 24),
        _sectionLabel('Status Breakdown'),
        const SizedBox(height: 12),
        _StatusRow(data: data),
        if (data.revenueByBuilding.isNotEmpty) ...[
          const SizedBox(height: 24),
          _sectionLabel('Revenue by Building'),
          const SizedBox(height: 12),
          ...data.revenueByBuilding
              .map((b) => _BuildingRevenueRow(stat: b)),
        ],
        if (data.topRooms.isNotEmpty) ...[
          const SizedBox(height: 24),
          _sectionLabel('Revenue per Room'),
          const SizedBox(height: 12),
          ..._revenueByRoom(data.topRooms).asMap().entries.map(
                (e) => _RoomRevenueRow(rank: e.key + 1, stat: e.value),
              ),
        ],
        const SizedBox(height: 24),
        _sectionLabel('Top Rooms by Bookings'),
        const SizedBox(height: 12),
        if (data.topRooms.isEmpty)
          _emptyState('No room bookings yet')
        else
          ...data.topRooms.asMap().entries.map(
                (e) => _RoomStatRow(rank: e.key + 1, stat: e.value),
              ),
        const SizedBox(height: 24),
        _sectionLabel('Peak Booking Times'),
        const SizedBox(height: 12),
        _PeakTimesCard(data: data),
        const SizedBox(height: 24),
        _sectionLabel('Customer Insights'),
        const SizedBox(height: 12),
        if (data.topOrganizers.isEmpty)
          _emptyState('No client data yet')
        else
          ...data.topOrganizers.take(5).map((o) => _ClientRow(stat: o)),
        if (data.repeatOrganizers.isNotEmpty) ...[
          const SizedBox(height: 12),
          _RepeatClientsChip(count: data.repeatOrganizers.length),
        ],
      ],
    );
  }

  List<RoomStats> _revenueByRoom(List<RoomStats> rooms) {
    final sorted = [...rooms]..sort((a, b) => b.revenue.compareTo(a.revenue));
    return sorted;
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: const TextStyle(
          color: Color(0xFF1A1A1A),
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
      );

  Widget _emptyState(String msg) => Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        alignment: Alignment.center,
        child: Text(msg,
            style: const TextStyle(color: Color(0xFF9B9B9B), fontSize: 13)),
      );
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool muted;
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    this.muted = false,
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
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: muted ? const Color(0xFFEEEEEE) : const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon,
                color: muted ? const Color(0xFF9B9B9B) : Colors.white,
                size: 17),
          ),
          const SizedBox(height: 14),
          Text(value,
              style: TextStyle(
                  color: muted
                      ? const Color(0xFF9B9B9B)
                      : const Color(0xFF1A1A1A),
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8)),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(
                  color: Color(0xFF9B9B9B),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.1)),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final AnalyticsSnapshot data;
  const _StatusRow({required this.data});

  @override
  Widget build(BuildContext context) {
    final total = data.totalBookings;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: Row(
        children: [
          _pill('${data.confirmedBookings}', 'Confirmed',
              Colors.white, const Color(0xFF1A1A1A)),
          const SizedBox(width: 8),
          _pill('${data.pendingBookings}', 'Pending',
              const Color(0xFF3D3D3D), const Color(0xFFF0F0F0)),
          const SizedBox(width: 8),
          _pill('${data.cancelledBookings}', 'Cancelled',
              const Color(0xFF9B9B9B), const Color(0xFFF5F5F5)),
          const SizedBox(width: 8),
          _pill('$total', 'Total',
              const Color(0xFF1A1A1A), const Color(0xFFEEEEEE)),
        ],
      ),
    );
  }

  Widget _pill(String count, String label, Color fg, Color bg) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(count,
                style: TextStyle(
                    color: fg,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    color: Color(0xFF9B9B9B),
                    fontSize: 10,
                    fontWeight: FontWeight.w400)),
          ],
        ),
      ),
    );
  }
}

class _BuildingRevenueRow extends StatelessWidget {
  final BuildingRevenue stat;
  const _BuildingRevenueRow({required this.stat});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFEEEEEE),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.apartment_outlined,
                color: Color(0xFF3D3D3D), size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(stat.buildingName,
                    style: const TextStyle(
                        color: Color(0xFF1A1A1A),
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
                Text(
                    '${stat.bookingCount} confirmed booking${stat.bookingCount == 1 ? '' : 's'}',
                    style: const TextStyle(
                        color: Color(0xFF9B9B9B), fontSize: 11)),
              ],
            ),
          ),
          Text(
            '\$${stat.revenue.toStringAsFixed(0)}',
            style: const TextStyle(
                color: Color(0xFF1A1A1A),
                fontWeight: FontWeight.w700,
                fontSize: 15),
          ),
        ],
      ),
    );
  }
}

class _RoomStatRow extends StatelessWidget {
  final int rank;
  final RoomStats stat;
  const _RoomStatRow({required this.rank, required this.stat});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '#$rank',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(stat.roomName,
                    style: const TextStyle(
                        color: Color(0xFF1A1A1A),
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
                Text(stat.buildingName,
                    style: const TextStyle(
                        color: Color(0xFF9B9B9B), fontSize: 11)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${stat.bookingCount} booking${stat.bookingCount == 1 ? '' : 's'}',
                  style: const TextStyle(
                      color: Color(0xFF1A1A1A),
                      fontWeight: FontWeight.w600,
                      fontSize: 12)),
              Text('\$${stat.revenue.toStringAsFixed(0)} rev',
                  style: const TextStyle(
                      color: Color(0xFF9B9B9B), fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoomRevenueRow extends StatelessWidget {
  final int rank;
  final RoomStats stat;
  const _RoomRevenueRow({required this.rank, required this.stat});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '#$rank',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(stat.roomName,
                    style: const TextStyle(
                        color: Color(0xFF1A1A1A),
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
                Text(stat.buildingName,
                    style: const TextStyle(
                        color: Color(0xFF9B9B9B), fontSize: 11)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${stat.revenue.toStringAsFixed(0)}',
                style: const TextStyle(
                    color: Color(0xFF1A1A1A),
                    fontWeight: FontWeight.w700,
                    fontSize: 15),
              ),
              Text(
                  '${stat.bookingCount} booking${stat.bookingCount == 1 ? '' : 's'}',
                  style: const TextStyle(
                      color: Color(0xFF9B9B9B), fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

class _PeakTimesCard extends StatelessWidget {
  final AnalyticsSnapshot data;
  const _PeakTimesCard({required this.data});

  static const _dayAbbrs = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    final noData = data.totalBookings == 0;

    if (noData) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE8E8E8)),
        ),
        child: const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text('No booking data yet',
                style: TextStyle(color: Color(0xFF9B9B9B), fontSize: 13)),
          ),
        ),
      );
    }

    return Column(
      children: [
        _buildHourChart(),
        const SizedBox(height: 12),
        _buildDayChart(),
      ],
    );
  }

  Widget _buildHourChart() {
    final hours = data.bookingsByHour;
    final workHours =
        hours.where((h) => h.hour >= 6 && h.hour <= 22).toList();
    double maxCount =
        workHours.fold(0.0, (m, h) => h.count > m ? h.count.toDouble() : m);
    if (maxCount == 0) maxCount = 1;

    final bars = workHours.asMap().entries.map((e) {
      final h = e.value;
      final isPeak = h.count > 0 &&
          h.count ==
              workHours.fold(0, (m, x) => x.count > m ? x.count : m);
      return BarChartGroupData(
        x: e.key,
        barRods: [
          BarChartRodData(
            toY: h.count.toDouble(),
            color: isPeak
                ? const Color(0xFF1A1A1A)
                : const Color(0xFFD0D0D0),
            width: 8,
            borderRadius: BorderRadius.circular(3),
          ),
        ],
      );
    }).toList();

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
          Row(
            children: [
              const Icon(Icons.schedule_outlined,
                  color: Color(0xFF1A1A1A), size: 16),
              const SizedBox(width: 6),
              const Text('Bookings by Hour',
                  style: TextStyle(
                      color: Color(0xFF1A1A1A),
                      fontWeight: FontWeight.w600,
                      fontSize: 13)),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: BarChart(
              BarChartData(
                maxY: maxCount * 1.3,
                barGroups: bars,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => const FlLine(
                    color: Color(0xFFEEEEEE),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 18,
                      interval: 2,
                      getTitlesWidget: (v, _) {
                        final idx = v.toInt();
                        if (idx >= workHours.length) {
                          return const SizedBox.shrink();
                        }
                        final h = workHours[idx].hour;
                        if (idx % 2 != 0) return const SizedBox.shrink();
                        final suffix = h >= 12 ? 'p' : 'a';
                        final display = h == 0
                            ? '12a'
                            : h == 12
                                ? '12p'
                                : h > 12
                                    ? '${h - 12}$suffix'
                                    : '$h$suffix';
                        return Text(display,
                            style: const TextStyle(
                                color: Color(0xFF9B9B9B), fontSize: 9));
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => const Color(0xFF1A1A1A),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final h = workHours[group.x].hour;
                      final suffix = h >= 12 ? 'PM' : 'AM';
                      final display = h == 0
                          ? '12AM'
                          : h == 12
                              ? '12PM'
                              : h > 12
                                  ? '${h - 12}$suffix'
                                  : '$h$suffix';
                      return BarTooltipItem(
                        '$display\n${rod.toY.toInt()} bookings',
                        const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayChart() {
    final days = data.bookingsByDay;
    double maxCount =
        days.fold(0.0, (m, d) => d.count > m ? d.count.toDouble() : m);
    if (maxCount == 0) maxCount = 1;

    final bars = days.asMap().entries.map((e) {
      final d = e.value;
      final isPeak = d.count > 0 &&
          d.count == days.fold(0, (m, x) => x.count > m ? x.count : m);
      return BarChartGroupData(
        x: e.key,
        barRods: [
          BarChartRodData(
            toY: d.count.toDouble(),
            color: isPeak
                ? const Color(0xFF1A1A1A)
                : const Color(0xFFD0D0D0),
            width: 22,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    }).toList();

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
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined,
                  color: Color(0xFF1A1A1A), size: 16),
              const SizedBox(width: 6),
              const Text('Bookings by Day of Week',
                  style: TextStyle(
                      color: Color(0xFF1A1A1A),
                      fontWeight: FontWeight.w600,
                      fontSize: 13)),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: BarChart(
              BarChartData(
                maxY: maxCount * 1.3,
                barGroups: bars,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => const FlLine(
                    color: Color(0xFFEEEEEE),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 18,
                      getTitlesWidget: (v, _) {
                        final idx = v.toInt();
                        if (idx >= _dayAbbrs.length) {
                          return const SizedBox.shrink();
                        }
                        return Text(_dayAbbrs[idx],
                            style: const TextStyle(
                                color: Color(0xFF9B9B9B), fontSize: 9));
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => const Color(0xFF1A1A1A),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                        BarTooltipItem(
                      '${_dayAbbrs[group.x]}\n${rod.toY.toInt()} bookings',
                      const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClientRow extends StatelessWidget {
  final OrganizerStats stat;
  const _ClientRow({required this.stat});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFEEEEEE),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              stat.name.isNotEmpty
                  ? stat.name[0].toUpperCase()
                  : 'O',
              style: const TextStyle(
                  color: Color(0xFF3D3D3D),
                  fontWeight: FontWeight.w700,
                  fontSize: 14),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(stat.name,
                style: const TextStyle(
                    color: Color(0xFF1A1A1A),
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${stat.bookingCount} bookings',
                  style: const TextStyle(
                      color: Color(0xFF3D3D3D),
                      fontWeight: FontWeight.w600,
                      fontSize: 12)),
              Text('\$${stat.totalSpend.toStringAsFixed(0)}',
                  style: const TextStyle(
                      color: Color(0xFF9B9B9B), fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

class _RepeatClientsChip extends StatelessWidget {
  final int count;
  const _RepeatClientsChip({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.repeat_rounded,
              size: 16, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            '$count repeat client${count == 1 ? '' : 's'}',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
