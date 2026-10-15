import 'package:flutter_test/flutter_test.dart';
import 'package:idea_vault/models/appointment.dart';
import 'package:idea_vault/models/customer.dart';
import 'package:idea_vault/models/customer_overview.dart';
import 'package:idea_vault/models/herb_alert.dart';
import 'package:idea_vault/services/revisit_notifier.dart';
import 'package:idea_vault/utils/date_format.dart';
import 'package:idea_vault/widgets/herb_energy_bar.dart';

CustomerOverview overviewWith(
  List<(int daysFromToday, AppointmentStatus status)> appts, {
  DateTime? lastContact,
}) {
  final now = today();
  return CustomerOverview(
    customer: Customer(
      id: 1,
      name: '홍길동',
      phone: '010-0000-0000',
      gender: '남',
      createdAt: now,
    ),
    appointments: [
      for (final (days, status) in appts)
        Appointment(
          customerId: 1,
          date: now.add(Duration(days: days)),
          status: status,
        ),
    ],
    lastContact: lastContact,
  );
}

void main() {
  const visited = AppointmentStatus.visited;
  const booked = AppointmentStatus.booked;

  test('기록이 없으면 연락 대상이 아니다', () {
    expect(overviewWith([]).needsContact, isFalse);
  });

  test('마지막 내원 13일째는 아직 아니고, 14일째부터 연락 필요', () {
    expect(overviewWith([(-13, visited)]).needsContact, isFalse);
    expect(overviewWith([(-14, visited)]).needsContact, isTrue);
    expect(overviewWith([(-30, visited)]).needsContact, isTrue);
  });

  test('다음 예약이 잡혀 있으면 연락 대상이 아니다', () {
    final o = overviewWith([(-20, visited), (3, booked)]);
    expect(o.needsContact, isFalse);
    expect(o.contactDueDate, isNull);
  });

  test('오늘 예약도 재예약으로 본다', () {
    expect(overviewWith([(-20, visited), (0, booked)]).needsContact, isFalse);
  });

  test('노쇼는 바로 연락 대상', () {
    final o = overviewWith([(-30, visited), (-1, AppointmentStatus.noShow)]);
    expect(o.needsContact, isTrue);
  });

  test('처리 안 된 지난 예약도 기준일이 된다', () {
    final o = overviewWith([(-40, visited), (-5, booked)]);
    expect(o.uncheckedBookings, hasLength(1));
    expect(o.needsContact, isFalse); // 5일밖에 안 지남
    expect(o.contactDueDate, today().add(const Duration(days: 9)));
  });

  test('취소된 예약은 무시한다', () {
    final o = overviewWith([
      (-20, visited),
      (-2, AppointmentStatus.cancelled),
      (5, AppointmentStatus.cancelled),
    ]);
    expect(o.needsContact, isTrue);
    expect(o.daysSinceLastSchedule, 20);
  });

  test('기한 이후에 연락하면 연락함 상태', () {
    final before = overviewWith([
      (-20, visited),
    ], lastContact: today().subtract(const Duration(days: 10)));
    final after = overviewWith([(-20, visited)], lastContact: DateTime.now());
    expect(before.contactedSinceDue, isFalse);
    expect(after.contactedSinceDue, isTrue);
  });

  group('한약 복약 알림', () {
    test('알림일 전에는 확인 대상이 아니다', () {
      final o = herbOverview(startDaysAgo: 10, alerts: [(5, false)]);
      expect(o.needsHerbCheck, isFalse);
      expect(o.pendingHerbAlerts, hasLength(1));
    });

    test('알림일 당일부터 재예약과 상관없이 확인 대상', () {
      final o = herbOverview(
        startDaysAgo: 15,
        alerts: [(0, false), (10, false)],
      );
      expect(o.needsHerbCheck, isTrue);
      expect(o.dueHerbAlerts, hasLength(1));
      expect(o.herbLabel(o.dueHerbAlerts.first), '복약 15일');
    });

    test('확인 완료한 알림은 대상에서 빠진다', () {
      final o = herbOverview(
        startDaysAgo: 15,
        alerts: [(0, true), (10, false)],
      );
      expect(o.needsHerbCheck, isFalse);
      expect(o.pendingHerbAlerts, hasLength(1));
    });

    test('복약 종료(한약 환자 아님)면 알림이 있어도 대상 아님', () {
      final o = herbOverview(
        startDaysAgo: 15,
        alerts: [(0, false)],
        herbal: false,
      );
      expect(o.needsHerbCheck, isFalse);
    });
  });

  group('아침 요약 알림', () {
    test('재방문은 기한 날부터, 복약은 알림일부터 요약에 들어간다', () {
      final revisit = overviewWith([(-10, visited)]); // 4일 뒤 기한
      final herb = herbOverview(startDaysAgo: 10, alerts: [(5, false)]);
      final day3 = today().add(const Duration(days: 3));
      final day5 = today().add(const Duration(days: 5));
      expect(DailySummary.of([revisit, herb], day3).isEmpty, isTrue);
      final s = DailySummary.of([revisit, herb], day5);
      expect(s.total, 2);
      expect(s.title, '오늘 연락할 환자 2명 (복약 확인 1명 · 재방문 1명)');
    });

    test('처리 안 한 환자는 다음 날에도 계속 들어간다', () {
      final herb = herbOverview(startDaysAgo: 15, alerts: [(0, false)]);
      final tomorrow = today().add(const Duration(days: 1));
      expect(DailySummary.of([herb], tomorrow).total, 1);
    });

    test('복약 확인 완료·재예약하면 빠진다', () {
      final herb = herbOverview(startDaysAgo: 15, alerts: [(0, true)]);
      final rebooked = overviewWith([(-20, visited), (3, booked)]);
      expect(DailySummary.of([herb, rebooked], today()).isEmpty, isTrue);
    });
  });

  group('7일 반복 알림 · 놓친 연락', () {
    test('복약 알림: 7일째까지는 연락 대상, 8일째부터 놓친 연락', () {
      final day7 = herbOverview(startDaysAgo: 21, alerts: [(-6, false)]);
      expect(day7.needsHerbCheck, isTrue);
      expect(day7.hasMissed, isFalse);

      final day8 = herbOverview(startDaysAgo: 22, alerts: [(-7, false)]);
      expect(day8.needsHerbCheck, isFalse);
      expect(day8.missedHerbAlerts, hasLength(1));
      expect(day8.hasMissed, isTrue);
    });

    test('재방문: 기한 후 7일째까지 연락 대상, 그 뒤 놓친 연락', () {
      // 마지막 내원 20일 전 → 기한 6일 전 → 7일째
      final active = overviewWith([(-20, visited)]);
      expect(active.revisitPending, isTrue);
      expect(active.revisitMissed, isFalse);

      // 마지막 내원 21일 전 → 기한 7일 전 → 놓친 연락
      final missed = overviewWith([(-21, visited)]);
      expect(missed.revisitPending, isFalse);
      expect(missed.revisitMissed, isTrue);
    });

    test('연락함을 누른 환자는 놓친 연락이 되지 않는다', () {
      final o = overviewWith([(-30, visited)], lastContact: DateTime.now());
      expect(o.revisitMissed, isFalse);
      expect(o.hasMissed, isFalse);
    });

    test('요약 알림: 이름 뒤에 며칠째인지, 7일 지나면 빠짐', () {
      final herb = herbOverview(startDaysAgo: 17, alerts: [(-2, false)]);
      final s = DailySummary.of([herb], today());
      expect(s.body, contains('김한약(비급)(3일째)'));

      final old = herbOverview(startDaysAgo: 22, alerts: [(-7, false)]);
      expect(DailySummary.of([old], today()).isEmpty, isTrue);
    });
  });

  group('한약 종류', () {
    test('건보첩약은 10일, 비급여는 15·25일이 기본', () {
      expect(HerbType.insured.defaultDays, [10]);
      expect(HerbType.nonInsured.defaultDays, [15, 25]);
    });

    test('이름 뒤 표시', () {
      expect(HerbType.insured.nameTag, '건');
      expect(HerbType.nonInsured.nameTag, '비급');
    });

    test('예전 데이터(종류 없음)는 비급여로 본다', () {
      expect(HerbType.fromDb(null), HerbType.nonInsured);
      expect(HerbType.fromDb('insured'), HerbType.insured);
    });

    test('Customer 저장·불러오기에 종류가 유지된다', () {
      final c = Customer(
        name: '건보',
        phone: '010',
        gender: '남',
        herbStart: today(),
        herbType: HerbType.insured,
        createdAt: today(),
      );
      expect(Customer.fromMap(c.toMap()).herbType, HerbType.insured);
    });
  });

  group('회차', () {
    test('취소·노쇼를 빼고 날짜 순으로 센다, 5회차 표시', () {
      final o = overviewWith([
        (-40, visited), // 1
        (-30, AppointmentStatus.noShow), // 제외
        (-25, visited), // 2
        (-20, AppointmentStatus.cancelled), // 제외
        (-15, visited), // 3
        (-8, visited), // 4
        (3, booked), // 5
        (10, booked), // 6
      ]);
      final byDays = {
        for (final a in o.appointments) today().difference(a.date).inDays: a,
      };
      expect(o.visitNumberOf(byDays[40]!), 1);
      expect(o.visitNumberOf(byDays[30]!), isNull);
      expect(o.visitNumberOf(byDays[-3]!), 5);
      expect(o.milestoneOf(byDays[-3]!), 5);
      expect(o.milestoneOf(byDays[-10]!), isNull);
      expect(o.upcomingMilestone, 5); // 다음 예약이 5회차
    });
  });

  group('복약 에너지바', () {
    Customer herb({required int startDaysAgo, required int days}) => Customer(
      name: '바',
      phone: '010',
      gender: '여',
      herbStart: today().subtract(Duration(days: startDaysAgo)),
      herbDays: days,
      createdAt: today(),
    );

    test('3개월: 시작일 6칸, 15일 뒤 5칸, 90일 뒤 0칸', () {
      expect(
        HerbEnergyBar.filledCells(
          herb(startDaysAgo: 0, days: 90).herbRemainingDays!,
        ),
        6,
      );
      expect(herb(startDaysAgo: 15, days: 90).herbRemainingDays, 75);
      expect(HerbEnergyBar.filledCells(75), 5);
      expect(
        HerbEnergyBar.filledCells(
          herb(startDaysAgo: 90, days: 90).herbRemainingDays!,
        ),
        0,
      );
    });

    test('1개월은 2칸, 2개월은 4칸에서 시작', () {
      expect(
        HerbEnergyBar.filledCells(
          herb(startDaysAgo: 0, days: 30).herbRemainingDays!,
        ),
        2,
      );
      expect(
        HerbEnergyBar.filledCells(
          herb(startDaysAgo: 0, days: 60).herbRemainingDays!,
        ),
        4,
      );
    });

    test('일정 미루기(시작일이 뒤로)만큼 다시 채워진다', () {
      // 20일 지난 3개월 환자 → 70일 남음. 7일 미루면 시작일이 7일 뒤로 → 77일 남음
      expect(herb(startDaysAgo: 20, days: 90).herbRemainingDays, 70);
      expect(herb(startDaysAgo: 13, days: 90).herbRemainingDays, 77);
    });

    test('기간을 정하지 않았으면 표시 안 함', () {
      final c = Customer(
        name: '없음',
        phone: '010',
        gender: '남',
        herbStart: today(),
        createdAt: today(),
      );
      expect(c.herbRemainingDays, isNull);
      expect(
        Customer.fromMap(herb(startDaysAgo: 0, days: 60).toMap()).herbDays,
        60,
      );
    });
  });
}

CustomerOverview herbOverview({
  required int startDaysAgo,
  required List<(int daysFromToday, bool done)> alerts,
  bool herbal = true,
}) {
  final now = today();
  return CustomerOverview(
    customer: Customer(
      id: 2,
      name: '김한약',
      phone: '010-1111-2222',
      gender: '여',
      herbStart: herbal ? now.subtract(Duration(days: startDaysAgo)) : null,
      createdAt: now,
    ),
    appointments: const [],
    herbAlerts: [
      for (final (i, (days, done)) in alerts.indexed)
        HerbAlert(
          id: i + 1,
          customerId: 2,
          date: now.add(Duration(days: days)),
          done: done,
        ),
    ],
  );
}
