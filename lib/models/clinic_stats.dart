import '../utils/date_format.dart';
import 'appointment.dart';
import 'customer_overview.dart';
import 'herb_alert.dart';

/// 경영 통계 계산.
///
/// 기준
/// - '내원'으로 처리된 기록만 셉니다. (예약만 잡힌 것, 노쇼, 취소는 내원이 아님)
/// - 회차는 환자 전체 기준(취소·노쇼 제외, 날짜·시간 순)이고, 1회차 내원 = 초진입니다.
/// - 진료과는 그 예약·내원 기록에 정한 과를 따릅니다. 과를 안 정한 기록은 '미지정'.
/// - 재진율 · 5회차 도달률은 "기간 안에 초진한 환자" 중 이후(오늘까지) 다시 온 비율입니다.
///   기간이 최근일수록 아직 다시 올 시간이 부족해 낮게 나올 수 있어요.
class DeptStats {
  DeptStats(this.deptId);

  /// null = 미지정, [allDepts] = 전체.
  final int? deptId;

  static const allDepts = -1;

  int firstVisits = 0; // 초진 수
  int revisits = 0; // 재진 수 (건)
  int noShows = 0;
  int cancels = 0;

  /// 기간 안에 이 과에 내원한 서로 다른 환자.
  final Set<int> patients = {};

  /// 기간 안에 이 과에서 초진한 환자.
  final Set<int> firstVisitPatients = {};

  /// 그중 이후 재진한 환자 / 5회차까지 온 환자.
  final Set<int> returnedPatients = {};
  final Set<int> fifthVisitPatients = {};

  /// 기간 안에 이 과에 내원했고, 그 기간에 한약을 복용한 환자 (종류별).
  final Set<int> herbInsured = {};
  final Set<int> herbNonInsured = {};

  int get visits => firstVisits + revisits;
  int get herbPatients => herbInsured.length + herbNonInsured.length;

  double? _rate(int part, int whole) => whole == 0 ? null : part / whole;

  /// 재진율: 초진 환자 중 다시 온 비율.
  double? get revisitRate =>
      _rate(returnedPatients.length, firstVisitPatients.length);

  /// 5회차 도달률: 초진 환자 중 5회차까지 온 비율.
  double? get fifthVisitRate =>
      _rate(fifthVisitPatients.length, firstVisitPatients.length);

  /// 한약 환자 비율: 내원 환자 중 한약 복용 환자.
  double? get herbRate => _rate(herbPatients, patients.length);

  /// 노쇼율: (내원 + 노쇼) 중 노쇼.
  double? get noShowRate => _rate(noShows, visits + noShows);

  /// 환자 1명당 평균 내원 횟수.
  double? get visitsPerPatient =>
      patients.isEmpty ? null : visits / patients.length;
}

class ClinicStats {
  ClinicStats._(this.start, this.end);

  final DateTime start;
  final DateTime end;

  /// 진료과별 (미지정은 null 키).
  final Map<int?, DeptStats> byDept = {};

  /// 전체 합계.
  final DeptStats total = DeptStats(DeptStats.allDepts);

  /// 기간 안에 새로 등록한 환자 수.
  int newRegistrations = 0;

  /// 요일별 내원 수 (월=0 … 일=6).
  final List<int> visitsByWeekday = List.filled(7, 0);

  /// 시간대별 내원 수 (시 → 건). 시간을 넣은 기록만.
  final Map<int, int> visitsByHour = {};

  // 지금 상태 (기간과 상관없음)
  int registeredPatients = 0;
  int herbalNow = 0;
  int needsContactNow = 0;
  int missedNow = 0;

  bool _inPeriod(DateTime d) {
    final day = dateOnly(d);
    return !day.isBefore(start) && !day.isAfter(end);
  }

  DeptStats _dept(int? id) => byDept.putIfAbsent(id, () => DeptStats(id));

  static ClinicStats compute(
    List<CustomerOverview> overviews, {
    required DateTime start,
    required DateTime end,
  }) {
    final s = ClinicStats._(dateOnly(start), dateOnly(end));
    s.registeredPatients = overviews.length;

    for (final o in overviews) {
      final c = o.customer;
      final id = c.id;
      if (id == null) continue;

      if (s._inPeriod(c.createdAt)) s.newRegistrations++;
      if (c.isHerbal) s.herbalNow++;
      if (o.revisitPending || o.needsHerbCheck) s.needsContactNow++;
      if (o.hasMissed) s.missedNow++;

      // 이 환자가 기간 안에 한약을 먹었는지
      final herbInPeriod =
          (c.herbStart != null && !dateOnly(c.herbStart!).isAfter(s.end)) ||
          o.herbAlerts.any((a) => s._inPeriod(a.date));

      // 이후 재진·5회차 여부 (오늘까지 실제 내원 기준)
      var maxVisit = 0;
      for (final a in o.appointments) {
        if (a.status != AppointmentStatus.visited) continue;
        final n = o.visitNumberOf(a) ?? 0;
        if (n > maxVisit) maxVisit = n;
      }

      for (final a in o.appointments) {
        if (!s._inPeriod(a.date)) continue;
        final dept = s._dept(a.deptId);
        switch (a.status) {
          case AppointmentStatus.noShow:
            dept.noShows++;
            s.total.noShows++;
            continue;
          case AppointmentStatus.cancelled:
            dept.cancels++;
            s.total.cancels++;
            continue;
          case AppointmentStatus.booked:
            continue;
          case AppointmentStatus.visited:
            break;
        }

        final n = o.visitNumberOf(a) ?? 0;
        for (final d in [dept, s.total]) {
          d.patients.add(id);
          if (n == 1) {
            d.firstVisits++;
            d.firstVisitPatients.add(id);
            if (maxVisit >= 2) d.returnedPatients.add(id);
            if (maxVisit >= kMilestoneVisit) d.fifthVisitPatients.add(id);
          } else {
            d.revisits++;
          }
          if (herbInPeriod) {
            (c.herbType == HerbType.insured ? d.herbInsured : d.herbNonInsured)
                .add(id);
          }
        }

        s.visitsByWeekday[a.date.weekday - 1]++;
        final h = a.hour;
        if (h != null) s.visitsByHour[h] = (s.visitsByHour[h] ?? 0) + 1;
      }
    }
    return s;
  }

  /// 최근 [months]개월(이번 달 포함) 월별 초진·재진 수. (그래프용)
  static List<(DateTime month, int first, int re)> monthlyTrend(
    List<CustomerOverview> overviews, {
    int months = 6,
    int? deptId,
    bool allDepts = true,
  }) {
    final now = today();
    final result = <(DateTime, int, int)>[];
    for (var i = months - 1; i >= 0; i--) {
      final m = DateTime(now.year, now.month - i, 1);
      final last = DateTime(m.year, m.month + 1, 0);
      final st = compute(overviews, start: m, end: last);
      final d = allDepts ? st.total : (st.byDept[deptId] ?? DeptStats(deptId));
      result.add((m, d.firstVisits, d.revisits));
    }
    return result;
  }
}
