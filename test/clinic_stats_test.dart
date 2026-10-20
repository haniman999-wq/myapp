import 'package:flutter_test/flutter_test.dart';
import 'package:idea_vault/models/appointment.dart';
import 'package:idea_vault/models/clinic_stats.dart';
import 'package:idea_vault/models/customer.dart';
import 'package:idea_vault/models/customer_overview.dart';
import 'package:idea_vault/models/herb_alert.dart';
import 'package:idea_vault/utils/date_format.dart';

var _nextId = 1;

CustomerOverview patient(
  int id,
  List<(int daysAgo, AppointmentStatus status, int? dept)> appts, {
  HerbType? herb,
}) {
  final now = today();
  return CustomerOverview(
    customer: Customer(
      id: id,
      name: '환자$id',
      phone: '010',
      gender: '여',
      herbStart: herb == null ? null : now.subtract(const Duration(days: 20)),
      herbType: herb ?? HerbType.nonInsured,
      createdAt: now.subtract(const Duration(days: 60)),
    ),
    appointments: [
      for (final (days, status, dept) in appts)
        Appointment(
          id: _nextId++,
          customerId: id,
          date: now.subtract(Duration(days: days)),
          status: status,
          deptId: dept,
        ),
    ],
  );
}

void main() {
  const v = AppointmentStatus.visited;
  const n = AppointmentStatus.noShow;

  // 기간: 최근 30일
  final start = today().subtract(const Duration(days: 30));
  final end = today();

  final data = [
    // 1과 초진(25일 전) → 재진 4번 = 5회차 도달
    patient(1, [(25, v, 1), (20, v, 1), (15, v, 1), (10, v, 1), (5, v, 1)]),
    // 1과 초진(20일 전) → 다시 안 옴, 한약(비급)
    patient(2, [(20, v, 1)], herb: HerbType.nonInsured),
    // 2과 초진(10일 전) → 재진 1번, 노쇼 1번, 한약(건보)
    patient(3, [(10, v, 2), (6, n, 2), (3, v, 2)], herb: HerbType.insured),
    // 기간 전 초진(50일 전, 2과) → 기간 안 재진만
    patient(4, [(50, v, 2), (12, v, 2)]),
  ];

  final s = ClinicStats.compute(data, start: start, end: end);

  test('과별 초진·재진 수', () {
    expect(s.byDept[1]!.firstVisits, 2);
    expect(s.byDept[1]!.revisits, 4);
    expect(s.byDept[2]!.firstVisits, 1);
    expect(s.byDept[2]!.revisits, 2); // 3번 환자 재진 + 4번 환자 재진
    expect(s.total.firstVisits, 3);
    expect(s.total.visits, 9);
  });

  test('재진율·5회차 도달률은 기간 안 초진 환자 기준', () {
    expect(s.byDept[1]!.revisitRate, 0.5); // 2명 중 1명
    expect(s.byDept[1]!.fifthVisitRate, 0.5);
    expect(s.byDept[2]!.revisitRate, 1.0); // 3번 환자
    expect(s.total.revisitRate, closeTo(2 / 3, 1e-9));
  });

  test('한약 비율과 종류', () {
    expect(s.byDept[1]!.herbRate, 0.5); // 1과 내원 환자 2명 중 1명
    expect(s.byDept[2]!.herbInsured.length, 1);
    expect(s.total.herbPatients, 2);
  });

  test('노쇼율·실환자수', () {
    expect(s.byDept[2]!.noShows, 1);
    expect(s.byDept[2]!.noShowRate, closeTo(1 / 4, 1e-9)); // 내원 3 + 노쇼 1
    expect(s.total.patients.length, 4);
  });

  test('기간 밖 기록은 세지 않는다', () {
    final old = ClinicStats.compute(
      data,
      start: today().subtract(const Duration(days: 60)),
      end: today().subtract(const Duration(days: 40)),
    );
    expect(old.total.firstVisits, 1); // 4번 환자 50일 전 초진만
    expect(old.total.revisits, 0);
  });
}
