import 'package:flutter/material.dart';

import '../models/clinic_stats.dart';
import '../models/customer_overview.dart';
import '../models/department.dart';
import '../services/customer_database.dart';
import '../theme.dart';
import '../utils/date_format.dart';
import '../widgets/customer_name.dart';

/// 기간 고르기.
enum _Range { thisMonth, lastMonth, last3Months, thisYear, custom }

/// 경영 통계 (CRM). 통계 보기 권한이 있는 직원만 열 수 있습니다.
class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key, this.preview});

  /// 화면 점검(테스트)용 예시 데이터. 있으면 서버 대신 이걸 씁니다.
  final (List<CustomerOverview>, List<Department>)? preview;

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final _db = CustomerDatabase.instance;
  _Range _range = _Range.thisMonth;
  late DateTimeRange _period = _periodFor(_Range.thisMonth);

  late Future<_Data> _future;

  @override
  void initState() {
    super.initState();
    if (widget.preview == null) _db.changes.addListener(_reload);
    _reload();
  }

  @override
  void dispose() {
    _db.changes.removeListener(_reload);
    super.dispose();
  }

  void _reload() {
    final preview = widget.preview;
    if (preview != null) {
      _future = Future.value(
        _Data(allowed: true, overviews: preview.$1, depts: preview.$2),
      );
      return;
    }
    setState(() {
      _future = () async {
        final me = await _db.me();
        return _Data(
          allowed: (me?.canViewStats ?? false) || (me?.isAdmin ?? false),
          overviews: await _db.getOverviews(),
          depts: await _db.getDepartments(),
        );
      }();
    });
  }

  static DateTimeRange _periodFor(_Range r) {
    final t = today();
    return switch (r) {
      _Range.thisMonth => DateTimeRange(
        start: DateTime(t.year, t.month),
        end: t,
      ),
      _Range.lastMonth => DateTimeRange(
        start: DateTime(t.year, t.month - 1),
        end: DateTime(t.year, t.month, 0),
      ),
      _Range.last3Months => DateTimeRange(
        start: DateTime(t.year, t.month - 2),
        end: t,
      ),
      _Range.thisYear => DateTimeRange(start: DateTime(t.year), end: t),
      _Range.custom => DateTimeRange(start: DateTime(t.year, t.month), end: t),
    };
  }

  Future<void> _pick(_Range r) async {
    if (r != _Range.custom) {
      setState(() {
        _range = r;
        _period = _periodFor(r);
      });
      return;
    }
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: today(),
      initialDateRange: _period,
    );
    if (picked == null) return;
    setState(() {
      _range = r;
      _period = DateTimeRange(
        start: dateOnly(picked.start),
        end: dateOnly(picked.end),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF37474F),
        foregroundColor: Colors.white,
        title: const Text('경영 통계'),
      ),
      body: FutureBuilder<_Data>(
        future: _future,
        builder: (context, snapshot) {
          final data = snapshot.data;
          if (data == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!data.allowed) return const _NoPermission();

          final stats = ClinicStats.compute(
            data.overviews,
            start: _period.start,
            end: _period.end,
          );
          return ListView(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 40),
            children: [
              _PeriodBar(range: _range, period: _period, onPick: _pick),
              const SizedBox(height: 12),
              _SectionTitle('전체 요약', Icons.dashboard_outlined),
              _SummaryGrid(stats: stats),
              const SizedBox(height: 18),
              _SectionTitle('진료과별 비교', Icons.leaderboard_outlined),
              if (data.depts.isEmpty)
                const _Hint('진료과가 아직 없어요. 서버에 2단계 설정(진료과)을 하면 나타나요.'),
              _DeptCompare(stats: stats, depts: data.depts),
              const SizedBox(height: 18),
              _SectionTitle('진료과별 상세', Icons.table_chart_outlined),
              for (final d in data.depts)
                _DeptCard(
                  title: DeptBadge(dept: d, fontSize: 14),
                  stats: stats.byDept[d.id] ?? DeptStats(d.id),
                ),
              if (stats.byDept[null] case final none? when none.visits > 0)
                _DeptCard(
                  title: const Text(
                    '진료과 미지정',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  stats: none,
                ),
              const SizedBox(height: 18),
              _SectionTitle('최근 6개월 추이 (초진 · 재진)', Icons.show_chart),
              _MonthlyTrend(overviews: data.overviews),
              const SizedBox(height: 18),
              _SectionTitle('요일별 내원', Icons.calendar_view_week),
              _WeekdayBars(counts: stats.visitsByWeekday),
              if (stats.visitsByHour.isNotEmpty) ...[
                const SizedBox(height: 18),
                _SectionTitle('시간대별 내원 (시간을 넣은 기록)', Icons.schedule),
                _HourBars(byHour: stats.visitsByHour),
              ],
              const SizedBox(height: 18),
              _SectionTitle('지금 상태', Icons.monitor_heart_outlined),
              _NowGrid(stats: stats),
              const SizedBox(height: 18),
              const _Hint(
                '· 초진 = 환자의 첫 내원(1회차), 재진 = 2회차 이후 내원. 회차는 취소·노쇼를 빼고 셉니다.\n'
                '· 재진율 · 5회차 도달률 = 기간 안에 초진한 환자 중 오늘까지 다시 온(5회차까지 온) 비율. '
                '최근 기간일수록 아직 올 시간이 부족해 낮게 나올 수 있어요.\n'
                '· 한약 비율 = 기간 안 내원 환자 중 그 기간에 한약을 복용한 환자.\n'
                '· 노쇼율 = (내원 + 노쇼) 중 노쇼. 진료과는 각 예약·내원 기록에 정한 과 기준.',
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Data {
  _Data({required this.allowed, required this.overviews, required this.depts});

  final bool allowed;
  final List<CustomerOverview> overviews;
  final List<Department> depts;
}

// ───────────────────────── 조각들 ─────────────────────────

String _pct(double? v) => v == null ? '-' : '${(v * 100).round()}%';
String _num(double? v) => v == null ? '-' : v.toStringAsFixed(1);

class _NoPermission extends StatelessWidget {
  const _NoPermission();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline, size: 56, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              '경영 통계를 볼 권한이 없어요',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 6),
            Text(
              '원장님(관리자)이 설정 → 관리자 설정에서 권한을 켜 주면 볼 수 있어요.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text, this.icon);

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF37474F)),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF37474F),
            ),
          ),
        ],
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12.5,
          color: Colors.black54,
          height: 1.5,
        ),
      ),
    );
  }
}

class _PeriodBar extends StatelessWidget {
  const _PeriodBar({
    required this.range,
    required this.period,
    required this.onPick,
  });

  final _Range range;
  final DateTimeRange period;
  final ValueChanged<_Range> onPick;

  @override
  Widget build(BuildContext context) {
    const labels = {
      _Range.thisMonth: '이번 달',
      _Range.lastMonth: '지난달',
      _Range.last3Months: '최근 3개월',
      _Range.thisYear: '올해',
      _Range.custom: '직접 선택',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            for (final r in _Range.values)
              ChoiceChip(
                label: Text(labels[r]!),
                selected: range == r,
                onSelected: (_) => onPick(r),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '기간: ${formatDateWithWeekday(period.start)} ~ ${formatDateWithWeekday(period.end)}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric(this.label, this.value, {this.color, this.sub});

  final String label;
  final String value;
  final Color? color;
  final String? sub;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12.5, color: Colors.grey),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color ?? Colors.black87,
            ),
          ),
          if (sub != null)
            Text(
              sub!,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
        ],
      ),
    );
  }
}

class _Grid extends StatelessWidget {
  const _Grid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final cols = c.maxWidth > 900 ? 5 : (c.maxWidth > 560 ? 4 : 2);
        const gap = 8.0;
        final w = (c.maxWidth - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [for (final ch in children) SizedBox(width: w, child: ch)],
        );
      },
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.stats});

  final ClinicStats stats;

  @override
  Widget build(BuildContext context) {
    final t = stats.total;
    return _Grid(
      children: [
        _Metric('초진 수', '${t.firstVisits}', color: kFirstVisitBlue),
        _Metric('재진 수', '${t.revisits}', color: kPrimaryGreenDark),
        _Metric('총 내원', '${t.visits}'),
        _Metric('실환자 수', '${t.patients.length}', sub: '기간 안 내원한 사람'),
        _Metric('신규 등록', '${stats.newRegistrations}'),
        _Metric('재진율', _pct(t.revisitRate), color: kPrimaryGreenDark),
        _Metric('5회차 도달률', _pct(t.fifthVisitRate), color: kMilestonePink),
        _Metric(
          '한약 환자 비율',
          _pct(t.herbRate),
          color: kHerbPurple,
          sub: '건보 ${t.herbInsured.length} · 비급여 ${t.herbNonInsured.length}명',
        ),
        _Metric(
          '노쇼율',
          _pct(t.noShowRate),
          color: kNoShowRed,
          sub: '노쇼 ${t.noShows}건',
        ),
        _Metric('1인당 내원', _num(t.visitsPerPatient), sub: '취소 ${t.cancels}건'),
      ],
    );
  }
}

/// 진료과별 주요 지표를 막대로 나란히 비교 (과별 능력치).
class _DeptCompare extends StatelessWidget {
  const _DeptCompare({required this.stats, required this.depts});

  final ClinicStats stats;
  final List<Department> depts;

  @override
  Widget build(BuildContext context) {
    if (depts.isEmpty) return const SizedBox.shrink();
    DeptStats of(Department d) => stats.byDept[d.id] ?? DeptStats(d.id);

    Widget block(
      String title,
      double Function(DeptStats) value,
      String Function(DeptStats) label, {
      bool isRate = false,
    }) {
      final values = [for (final d in depts) value(of(d))];
      final max = isRate
          ? 1.0
          : values.fold<double>(0, (a, b) => b > a ? b : a);
      return Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              for (final (i, d) in depts.indexed)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 70,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: DeptBadge(dept: d),
                        ),
                      ),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: max <= 0 ? 0 : (values[i] / max).clamp(0, 1),
                            minHeight: 14,
                            color: d.color,
                            backgroundColor: Colors.grey.shade200,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 56,
                        child: Text(
                          label(of(d)),
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        block(
          '초진 수',
          (s) => s.firstVisits.toDouble(),
          (s) => '${s.firstVisits}',
        ),
        block('재진 수', (s) => s.revisits.toDouble(), (s) => '${s.revisits}'),
        block(
          '재진율',
          (s) => s.revisitRate ?? 0,
          (s) => _pct(s.revisitRate),
          isRate: true,
        ),
        block(
          '5회차 도달률',
          (s) => s.fifthVisitRate ?? 0,
          (s) => _pct(s.fifthVisitRate),
          isRate: true,
        ),
        block(
          '한약 환자 비율',
          (s) => s.herbRate ?? 0,
          (s) => _pct(s.herbRate),
          isRate: true,
        ),
      ],
    );
  }
}

class _DeptCard extends StatelessWidget {
  const _DeptCard({required this.title, required this.stats});

  final Widget title;
  final DeptStats stats;

  @override
  Widget build(BuildContext context) {
    final s = stats;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            title,
            const SizedBox(height: 8),
            _Grid(
              children: [
                _Metric('초진', '${s.firstVisits}', color: kFirstVisitBlue),
                _Metric('재진', '${s.revisits}', color: kPrimaryGreenDark),
                _Metric('재진율', _pct(s.revisitRate)),
                _Metric('5회차 도달률', _pct(s.fifthVisitRate)),
                _Metric('한약 비율', _pct(s.herbRate), sub: '${s.herbPatients}명'),
                _Metric('실환자', '${s.patients.length}'),
                _Metric('노쇼율', _pct(s.noShowRate)),
                _Metric('1인당 내원', _num(s.visitsPerPatient)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthlyTrend extends StatelessWidget {
  const _MonthlyTrend({required this.overviews});

  final List<CustomerOverview> overviews;

  @override
  Widget build(BuildContext context) {
    final trend = ClinicStats.monthlyTrend(overviews);
    final max = trend.fold<int>(1, (m, e) => e.$2 + e.$3 > m ? e.$2 + e.$3 : m);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 10),
        child: Column(
          children: [
            SizedBox(
              height: 150,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final (_, first, re) in trend)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              '${first + re}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Container(
                              height: 110 * re / max,
                              color: kPrimaryGreen,
                            ),
                            Container(
                              height: 110 * first / max,
                              color: kFirstVisitBlue,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                for (final (m, _, _) in trend)
                  Expanded(
                    child: Text(
                      '${m.month}월',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _Legend(color: kFirstVisitBlue, label: '초진'),
                SizedBox(width: 16),
                _Legend(color: kPrimaryGreen, label: '재진'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, color: color),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class _Bars extends StatelessWidget {
  const _Bars({required this.labels, required this.values});

  final List<String> labels;
  final List<int> values;

  @override
  Widget build(BuildContext context) {
    final max = values.fold<int>(1, (m, v) => v > m ? v : m);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
        child: SizedBox(
          height: 120,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final (i, v) in values.indexed)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('$v', style: const TextStyle(fontSize: 10)),
                        Container(
                          height: 70 * v / max,
                          decoration: BoxDecoration(
                            color: const Color(0xFF78909C),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(labels[i], style: const TextStyle(fontSize: 11)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeekdayBars extends StatelessWidget {
  const _WeekdayBars({required this.counts});

  final List<int> counts;

  @override
  Widget build(BuildContext context) =>
      _Bars(labels: const ['월', '화', '수', '목', '금', '토', '일'], values: counts);
}

class _HourBars extends StatelessWidget {
  const _HourBars({required this.byHour});

  final Map<int, int> byHour;

  @override
  Widget build(BuildContext context) {
    final hours = byHour.keys.toList()..sort();
    final from = hours.first;
    final to = hours.last;
    return _Bars(
      labels: [for (var h = from; h <= to; h++) '$h시'],
      values: [for (var h = from; h <= to; h++) byHour[h] ?? 0],
    );
  }
}

class _NowGrid extends StatelessWidget {
  const _NowGrid({required this.stats});

  final ClinicStats stats;

  @override
  Widget build(BuildContext context) {
    return _Grid(
      children: [
        _Metric('등록 환자', '${stats.registeredPatients}'),
        _Metric('지금 복약 중', '${stats.herbalNow}', color: kHerbPurple),
        _Metric('오늘 연락할 환자', '${stats.needsContactNow}', color: kNoShowRed),
        _Metric('놓친 연락', '${stats.missedNow}', color: kMissedBrown),
      ],
    );
  }
}
