import 'package:flutter_test/flutter_test.dart';
import 'package:idea_vault/models/appointment.dart';
import 'package:idea_vault/models/customer.dart';
import 'package:idea_vault/models/customer_overview.dart';
import 'package:idea_vault/models/herb_alert.dart';
import 'package:idea_vault/utils/date_format.dart';

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
