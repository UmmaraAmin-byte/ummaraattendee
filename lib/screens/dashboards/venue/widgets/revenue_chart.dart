import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../../models/analytics_model.dart';

class BookingsTrendChart extends StatelessWidget {
  final List<TimeSeriesPoint> dailyBookings;
  const BookingsTrendChart({super.key, required this.dailyBookings});

  @override
  Widget build(BuildContext context) {
    final hasData = dailyBookings.any((p) => p.value > 0);
    return _ChartCard(
      title: 'Bookings Over Time',
      subtitle: 'Last 30 days',
      child: hasData ? _buildChart() : _emptyState(),
    );
  }

  Widget _buildChart() {
    final spots = <FlSpot>[];
    double maxY = 1;
    for (var i = 0; i < dailyBookings.length; i++) {
      final v = dailyBookings[i].value;
      spots.add(FlSpot(i.toDouble(), v));
      if (v > maxY) maxY = v;
    }

    return SizedBox(
      height: 180,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: (dailyBookings.length - 1).toDouble(),
          minY: 0,
          maxY: (maxY + 1).ceilToDouble(),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => const FlLine(
              color: Color(0xFFEEEEEE),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: 1,
                getTitlesWidget: (v, _) => Text(
                  v.toInt().toString(),
                  style: const TextStyle(
                      color: Color(0xFF9B9B9B), fontSize: 10),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 20,
                interval: 7,
                getTitlesWidget: (v, _) {
                  final idx = v.toInt();
                  if (idx >= dailyBookings.length) {
                    return const SizedBox.shrink();
                  }
                  final d = dailyBookings[idx].date;
                  return Text(
                    '${d.month}/${d.day}',
                    style: const TextStyle(
                        color: Color(0xFF9B9B9B), fontSize: 10),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              color: const Color(0xFF1A1A1A),
              barWidth: 2,
              isCurved: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: const Color(0xFF1A1A1A).withAlpha(18),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => const Color(0xFF1A1A1A),
              getTooltipItems: (spots) => spots
                  .map((s) => LineTooltipItem(
                        '${s.y.toInt()} bookings',
                        const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600),
                      ))
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _emptyState() => const SizedBox(
        height: 120,
        child: Center(
          child: Text('No booking data yet',
              style: TextStyle(color: Color(0xFF9B9B9B), fontSize: 13)),
        ),
      );
}

class WeeklyRevenueChart extends StatelessWidget {
  final List<TimeSeriesPoint> weeklyRevenue;
  const WeeklyRevenueChart({super.key, required this.weeklyRevenue});

  @override
  Widget build(BuildContext context) {
    final hasData = weeklyRevenue.any((p) => p.value > 0);
    return _ChartCard(
      title: 'Weekly Revenue',
      subtitle: 'Last 8 weeks',
      child: hasData ? _buildChart() : _emptyState(),
    );
  }

  Widget _buildChart() {
    double maxY = 1;
    for (final p in weeklyRevenue) {
      if (p.value > maxY) maxY = p.value;
    }

    final barGroups = <BarChartGroupData>[];
    for (var i = 0; i < weeklyRevenue.length; i++) {
      barGroups.add(BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: weeklyRevenue[i].value,
            color: const Color(0xFF1A1A1A),
            width: 14,
            borderRadius: BorderRadius.circular(4),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: maxY * 1.1,
              color: const Color(0xFFEEEEEE),
            ),
          ),
        ],
      ));
    }

    return SizedBox(
      height: 180,
      child: BarChart(
        BarChartData(
          maxY: maxY * 1.2,
          barGroups: barGroups,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => const FlLine(
              color: Color(0xFFEEEEEE),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 42,
                getTitlesWidget: (v, _) => Text(
                  '\$${v.toInt()}',
                  style: const TextStyle(
                      color: Color(0xFF9B9B9B), fontSize: 10),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 20,
                getTitlesWidget: (v, _) {
                  final idx = v.toInt();
                  if (idx >= weeklyRevenue.length) {
                    return const SizedBox.shrink();
                  }
                  final d = weeklyRevenue[idx].date;
                  return Text(
                    'W${d.month}/${d.day}',
                    style: const TextStyle(
                        color: Color(0xFF9B9B9B), fontSize: 10),
                  );
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
                '\$${rod.toY.toStringAsFixed(0)}',
                const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _emptyState() => const SizedBox(
        height: 120,
        child: Center(
          child: Text('No revenue data yet',
              style: TextStyle(color: Color(0xFF9B9B9B), fontSize: 13)),
        ),
      );
}

class MonthlyRevenueChart extends StatelessWidget {
  final List<TimeSeriesPoint> monthlyRevenue;
  const MonthlyRevenueChart({super.key, required this.monthlyRevenue});

  static const _monthAbbrs = [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  @override
  Widget build(BuildContext context) {
    final hasData = monthlyRevenue.any((p) => p.value > 0);
    return _ChartCard(
      title: 'Monthly Revenue',
      subtitle: 'Last 6 months',
      child: hasData ? _buildChart() : _emptyState(),
    );
  }

  Widget _buildChart() {
    double maxY = 1;
    for (final p in monthlyRevenue) {
      if (p.value > maxY) maxY = p.value;
    }

    final spots = <FlSpot>[];
    for (var i = 0; i < monthlyRevenue.length; i++) {
      spots.add(FlSpot(i.toDouble(), monthlyRevenue[i].value));
    }

    return SizedBox(
      height: 180,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: (monthlyRevenue.length - 1).toDouble(),
          minY: 0,
          maxY: maxY * 1.2,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => const FlLine(
              color: Color(0xFFEEEEEE),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 42,
                getTitlesWidget: (v, _) => Text(
                  '\$${v.toInt()}',
                  style: const TextStyle(
                      color: Color(0xFF9B9B9B), fontSize: 10),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 20,
                getTitlesWidget: (v, _) {
                  final idx = v.toInt();
                  if (idx >= monthlyRevenue.length) {
                    return const SizedBox.shrink();
                  }
                  final d = monthlyRevenue[idx].date;
                  return Text(
                    _monthAbbrs[d.month],
                    style: const TextStyle(
                        color: Color(0xFF9B9B9B), fontSize: 10),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              color: const Color(0xFF1A1A1A),
              barWidth: 2,
              isCurved: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                  radius: 3,
                  color: const Color(0xFF1A1A1A),
                  strokeColor: Colors.white,
                  strokeWidth: 1.5,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: const Color(0xFF1A1A1A).withAlpha(18),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => const Color(0xFF1A1A1A),
              getTooltipItems: (spots) => spots
                  .map((s) => LineTooltipItem(
                        '\$${s.y.toStringAsFixed(0)}',
                        const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600),
                      ))
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _emptyState() => const SizedBox(
        height: 120,
        child: Center(
          child: Text('No revenue data yet',
              style: TextStyle(color: Color(0xFF9B9B9B), fontSize: 13)),
        ),
      );
}

class _ChartCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  const _ChartCard(
      {required this.title, required this.subtitle, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: Color(0xFF1A1A1A),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2)),
          const SizedBox(height: 4),
          Text(subtitle,
              style: const TextStyle(
                  color: Color(0xFF9B9B9B),
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.1)),
          const SizedBox(height: 20),
          child,
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}
