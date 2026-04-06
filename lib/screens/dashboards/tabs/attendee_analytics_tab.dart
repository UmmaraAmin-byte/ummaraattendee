import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
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

const _chartPalette = [
  Color(0xFF1A1A1A),
  Color(0xFF4A4A4A),
  Color(0xFF7A7A7A),
  Color(0xFFAAAAAA),
  Color(0xFF2D2D2D),
  Color(0xFF5D5D5D),
  Color(0xFF8D8D8D),
];

Color _catColor(String c) => _categoryColors[c] ?? const Color(0xFF2D2D2D);

class AttendeeAnalyticsTab extends StatefulWidget {
  final Set<String> registeredIds;

  const AttendeeAnalyticsTab({
    super.key,
    required this.registeredIds,
  });

  @override
  State<AttendeeAnalyticsTab> createState() => _AttendeeAnalyticsTabState();
}

class _AttendeeAnalyticsTabState extends State<AttendeeAnalyticsTab> {
  final _auth = AuthService();
  int? _touchedPieIndex;
  int? _touchedRegPieIndex;

  List<Map<String, dynamic>> get _allPublished => _auth.allEvents
      .where((e) => e['status'] == 'published')
      .toList();

  List<Map<String, dynamic>> get _myEvents => _allPublished
      .where((e) => widget.registeredIds.contains(e['id'] as String))
      .toList();

  String _organizerName(String orgId) {
    final match = _auth.allUsers.where((u) => u.id == orgId).toList();
    return match.isNotEmpty ? match.first.fullName : 'Unknown';
  }

  @override
  Widget build(BuildContext context) {
    final all = _allPublished;
    final my = _myEvents;
    final upcoming = all
        .where((e) =>
            (e['start'] as DateTime?)?.isAfter(DateTime.now()) ?? false)
        .length;
    final past = all.length - upcoming;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Stats row ──────────────────────────────────
        _sectionLabel('Overview'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _statCard(
                icon: Icons.event_available_outlined,
                value: '${all.length}',
                label: 'Total Events',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _statCard(
                icon: Icons.confirmation_num_outlined,
                value: '${my.length}',
                label: 'Registered',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _statCard(
                icon: Icons.upcoming_outlined,
                value: '$upcoming',
                label: 'Upcoming',
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // ── Registration donut ──────────────────────────
        _sectionLabel('Registration Status'),
        const SizedBox(height: 12),
        _registrationPie(my.length, all.length - my.length),
        const SizedBox(height: 24),

        // ── Category breakdown (my events) ─────────────
        if (my.isNotEmpty) ...[
          _sectionLabel('My Events by Category'),
          const SizedBox(height: 12),
          _categoryPie(my),
          const SizedBox(height: 24),
        ],

        // ── Events per category (all events) ───────────
        if (all.isNotEmpty) ...[
          _sectionLabel('All Events by Category'),
          const SizedBox(height: 12),
          _categoryBarChart(all),
          const SizedBox(height: 24),
        ],

        // ── Top organizers ──────────────────────────────
        if (all.isNotEmpty) ...[
          _sectionLabel('Events by Organizer'),
          const SizedBox(height: 12),
          _organizerList(all),
          const SizedBox(height: 24),
        ],

        // ── Timeline (events per month) ─────────────────
        _sectionLabel('Events Timeline (Next 6 Months)'),
        const SizedBox(height: 12),
        _timelineChart(all),
      ],
    );
  }

  Widget _sectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        color: Color(0xFF1A1A1A),
        fontWeight: FontWeight.w700,
        fontSize: 15,
      ),
    );
  }

  Widget _statCard({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF2D2D2D), size: 18),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF1A1A1A),
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 10),
          ),
        ],
      ),
    );
  }

  // ── Registration donut ────────────────────────────────────

  Widget _registrationPie(int registered, int available) {
    if (registered == 0 && available == 0) {
      return _chartEmpty('No events available.');
    }
    final total = registered + available;
    final regPct =
        total > 0 ? (registered / total * 100).toStringAsFixed(1) : '0';

    final sections = <PieChartSectionData>[
      PieChartSectionData(
        value: registered.toDouble(),
        color: const Color(0xFF1A1A1A),
        title: registered > 0 ? '$registered' : '',
        titleStyle: const TextStyle(
            color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
        radius: _touchedRegPieIndex == 0 ? 62 : 54,
      ),
      PieChartSectionData(
        value: available > 0 ? available.toDouble() : 0.001,
        color: const Color(0xFFEEEEEE),
        title: available > 0 ? '$available' : '',
        titleStyle: const TextStyle(
            color: Color(0xFF6B6B6B),
            fontSize: 12,
            fontWeight: FontWeight.w700),
        radius: _touchedRegPieIndex == 1 ? 62 : 54,
      ),
    ];

    return Row(
      children: [
        SizedBox(
          width: 160,
          height: 160,
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 44,
              sectionsSpace: 2,
              pieTouchData: PieTouchData(
                touchCallback: (evt, res) {
                  setState(() {
                    if (res?.touchedSection == null ||
                        evt is FlPointerExitEvent) {
                      _touchedRegPieIndex = null;
                    } else {
                      _touchedRegPieIndex =
                          res!.touchedSection!.touchedSectionIndex;
                    }
                  });
                },
              ),
            ),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$regPct%',
                style: const TextStyle(
                  color: Color(0xFF1A1A1A),
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Text(
                'registration rate',
                style: TextStyle(color: Color(0xFF6B6B6B), fontSize: 12),
              ),
              const SizedBox(height: 14),
              _legendRow(const Color(0xFF1A1A1A), 'Registered ($registered)'),
              const SizedBox(height: 6),
              _legendRow(const Color(0xFFEEEEEE),
                  'Available ($available)', border: const Color(0xFFCCCCCC)),
            ],
          ),
        ),
      ],
    );
  }

  // ── Category pie (my events) ──────────────────────────────

  Widget _categoryPie(List<Map<String, dynamic>> events) {
    final counts = <String, int>{};
    for (final e in events) {
      final cat = (e['category'] as String? ?? 'Other');
      counts[cat] = (counts[cat] ?? 0) + 1;
    }
    if (counts.isEmpty) return _chartEmpty('No registered events yet.');

    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final sections = entries.asMap().entries.map((entry) {
      final i = entry.key;
      final cat = entry.value.key;
      final count = entry.value.value;
      return PieChartSectionData(
        value: count.toDouble(),
        color: _catColor(cat),
        title: count > 0 ? '$count' : '',
        titleStyle: const TextStyle(
            color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
        radius: _touchedPieIndex == i ? 68 : 58,
      );
    }).toList();

    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PieChart(
            PieChartData(
              sections: sections,
              sectionsSpace: 2,
              centerSpaceRadius: 0,
              pieTouchData: PieTouchData(
                touchCallback: (evt, res) {
                  setState(() {
                    if (res?.touchedSection == null ||
                        evt is FlPointerExitEvent) {
                      _touchedPieIndex = null;
                    } else {
                      _touchedPieIndex =
                          res!.touchedSection!.touchedSectionIndex;
                    }
                  });
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 14,
          runSpacing: 6,
          children: entries.map((e) {
            return _legendRow(_catColor(e.key), '${e.key} (${e.value})');
          }).toList(),
        ),
      ],
    );
  }

  // ── Category bar chart (all events) ──────────────────────

  Widget _categoryBarChart(List<Map<String, dynamic>> events) {
    final counts = <String, int>{};
    for (final e in events) {
      final cat = (e['category'] as String? ?? 'Other');
      counts[cat] = (counts[cat] ?? 0) + 1;
    }
    if (counts.isEmpty) return _chartEmpty('No event data.');

    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxVal =
        entries.fold<int>(0, (m, e) => e.value > m ? e.value : m).toDouble();

    final groups = entries.asMap().entries.map((entry) {
      return BarChartGroupData(
        x: entry.key,
        barRods: [
          BarChartRodData(
            toY: entry.value.value.toDouble(),
            color: _catColor(entry.value.key),
            width: 14,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 180,
          child: BarChart(
            BarChartData(
              barGroups: groups,
              maxY: maxVal + 1,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 1,
                getDrawingHorizontalLine: (_) => const FlLine(
                  color: Color(0xFFEEEEEE),
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 24,
                    interval: 1,
                    getTitlesWidget: (v, _) => Text(
                      v.toInt() == v ? '${v.toInt()}' : '',
                      style: const TextStyle(
                          color: Color(0xFF9E9E9E), fontSize: 10),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (v, _) {
                      final i = v.toInt();
                      if (i < 0 || i >= entries.length) {
                        return const SizedBox.shrink();
                      }
                      final cat = entries[i].key;
                      final short = cat.length > 5
                          ? cat.substring(0, 4) + '.'
                          : cat;
                      return Transform.rotate(
                        angle: -0.4,
                        child: Text(
                          short,
                          style: const TextStyle(
                              color: Color(0xFF6B6B6B), fontSize: 9),
                        ),
                      );
                    },
                  ),
                ),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Organizer list ────────────────────────────────────────

  Widget _organizerList(List<Map<String, dynamic>> events) {
    final counts = <String, int>{};
    for (final e in events) {
      final orgId = (e['organizerId'] as String? ?? '');
      if (orgId.isEmpty) continue;
      counts[orgId] = (counts[orgId] ?? 0) + 1;
    }
    if (counts.isEmpty) return _chartEmpty('No organizer data.');

    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxVal = entries.first.value;

    return Column(
      children: entries.take(5).toList().asMap().entries.map((entry) {
        final orgId = entry.value.key;
        final count = entry.value.value;
        final pct = maxVal > 0 ? count / maxVal : 0.0;
        final name = _organizerName(orgId);

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              SizedBox(
                width: 110,
                child: Text(
                  name,
                  style: const TextStyle(
                    color: Color(0xFF1A1A1A),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 10,
                    backgroundColor: const Color(0xFFEEEEEE),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF1A1A1A)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 24,
                child: Text(
                  '$count',
                  style: const TextStyle(
                    color: Color(0xFF6B6B6B),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ── Timeline (events per month) ───────────────────────────

  Widget _timelineChart(List<Map<String, dynamic>> events) {
    final now = DateTime.now();
    final months = List.generate(6, (i) {
      final m = DateTime(now.year, now.month + i, 1);
      return m;
    });

    final counts = <int, int>{};
    for (final e in events) {
      final start = e['start'] as DateTime?;
      if (start == null) continue;
      for (var i = 0; i < 6; i++) {
        final m = months[i];
        if (start.year == m.year && start.month == m.month) {
          counts[i] = (counts[i] ?? 0) + 1;
          break;
        }
      }
    }

    final maxVal =
        counts.values.fold<int>(0, (m, v) => v > m ? v : m).toDouble();

    final bars = List.generate(6, (i) {
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: (counts[i] ?? 0).toDouble(),
            color: (counts[i] ?? 0) > 0
                ? const Color(0xFF1A1A1A)
                : const Color(0xFFE0E0E0),
            width: 20,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(6)),
          ),
        ],
      );
    });

    const monthAbbr = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];

    return SizedBox(
      height: 160,
      child: BarChart(
        BarChartData(
          barGroups: bars,
          maxY: maxVal < 1 ? 4 : maxVal + 1,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 1,
            getDrawingHorizontalLine: (_) => const FlLine(
              color: Color(0xFFEEEEEE),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                interval: 1,
                getTitlesWidget: (v, _) => Text(
                  v.toInt() == v ? '${v.toInt()}' : '',
                  style: const TextStyle(
                      color: Color(0xFF9E9E9E), fontSize: 10),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                getTitlesWidget: (v, _) {
                  final i = v.toInt();
                  if (i < 0 || i >= 6) return const SizedBox.shrink();
                  final month = months[i];
                  return Text(
                    monthAbbr[month.month - 1],
                    style: const TextStyle(
                        color: Color(0xFF6B6B6B), fontSize: 10),
                  );
                },
              ),
            ),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
          ),
        ),
      ),
    );
  }

  Widget _legendRow(Color color, String label, {Color? border}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
            border: border != null
                ? Border.all(color: border, width: 1)
                : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(color: Color(0xFF6B6B6B), fontSize: 12),
        ),
      ],
    );
  }

  Widget _chartEmpty(String msg) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: Center(
        child: Text(
          msg,
          style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 13),
        ),
      ),
    );
  }
}
