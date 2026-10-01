import '../utils/date_format.dart';
import 'appointment.dart';
import 'customer.dart';
import 'herb_alert.dart';

/// 마지막 일정 후 며칠이 지나면 연락 대상으로 볼지.
const int kRevisitDays = 14;

/// 연락 안 한 환자를 며칠 동안 계속 알릴지. 이 기간이 지나면 '놓친 연락'으로 옮깁니다.
const int kMaxReminderDays = 7;

/// 환자 + 그 환자의 예약 기록을 묶어 '연락 필요' 같은 상태를 계산합니다.
///
/// 상태는 DB 에 저장하지 않고 매번 계산합니다. 날짜가 바뀌면 자동으로 맞아집니다.
class CustomerOverview {
  CustomerOverview({
    required this.customer,
    required List<Appointment> appointments,
    List<HerbAlert> herbAlerts = const [],
    this.lastContact,
  }) : appointments = [...appointments]
         ..sort((a, b) => a.date.compareTo(b.date)),
       herbAlerts = [...herbAlerts]..sort((a, b) => a.date.compareTo(b.date));

  final Customer customer;

  /// 날짜 오름차순.
  final List<Appointment> appointments;

  /// 한약 복약 확인 알림. 날짜 오름차순.
  final List<HerbAlert> herbAlerts;

  /// '연락함' 버튼을 마지막으로 누른 시각.
  final DateTime? lastContact;

  // ───────── 한약 복약 ─────────

  /// 아직 확인 안 한 복약 알림 (지난 것 + 앞으로 올 것).
  List<HerbAlert> get pendingHerbAlerts =>
      herbAlerts.where((a) => !a.done).toList();

  /// 오늘이거나 지났는데 아직 확인 안 한 복약 알림 (놓친 것 포함).
  List<HerbAlert> get dueHerbAlerts =>
      herbAlerts.where((a) => a.isDue).toList();

  /// 지금 연락해야 하는 복약 알림: 알림일부터 [kMaxReminderDays]일 이내.
  List<HerbAlert> get activeHerbAlerts => dueHerbAlerts
      .where((a) => _daysSince(a.date) < kMaxReminderDays)
      .toList();

  /// [kMaxReminderDays]일 동안 알렸는데도 확인 안 한 복약 알림 → '놓친 연락'.
  List<HerbAlert> get missedHerbAlerts => customer.isHerbal
      ? dueHerbAlerts
            .where((a) => _daysSince(a.date) >= kMaxReminderDays)
            .toList()
      : const [];

  bool get needsHerbCheck => customer.isHerbal && activeHerbAlerts.isNotEmpty;

  // ───────── 반복 알림 · 놓친 연락 ─────────

  static int _daysSince(DateTime d) => today().difference(dateOnly(d)).inDays;

  /// 재방문 연락 기한이 지난 날 수 (기한 당일 = 0). 연락 대상이 아니면 null.
  int? get revisitOverdueDays {
    final due = contactDueDate;
    if (due == null || !needsContact) return null;
    return _daysSince(due);
  }

  /// [kMaxReminderDays]일 동안 알렸는데도 '연락함'을 안 눌렀으면 '놓친 연락'.
  bool get revisitMissed =>
      !contactedSinceDue && (revisitOverdueDays ?? -1) >= kMaxReminderDays;

  /// 연락 탭에 보여줄 재방문 대상 (놓친 연락은 따로 모읍니다).
  bool get revisitActive => needsContact && !revisitMissed;

  /// 아직 연락 안 한 재방문 대상 (배지·요약에 셈).
  bool get revisitPending => revisitActive && !contactedSinceDue;

  /// '놓친 연락' 보관함에 들어갈 환자인지.
  bool get hasMissed => revisitMissed || missedHerbAlerts.isNotEmpty;

  // ───────── 특정 날짜 기준 (아침 요약 알림 예약용) ─────────

  /// [day] 아침 기준으로 복약 확인 알림이 며칠째인지 (첫날 = 1).
  /// 알릴 게 없거나 [kMaxReminderDays]일이 지났으면 null.
  int? herbReminderDayOn(DateTime day) {
    if (!customer.isHerbal) return null;
    int? best;
    for (final a in herbAlerts) {
      if (a.done) continue;
      final n = dateOnly(day).difference(dateOnly(a.date)).inDays;
      if (n < 0 || n >= kMaxReminderDays) continue;
      // 여러 개면 가장 오래된(가장 많이 알린) 것 기준
      if (best == null || n + 1 > best) best = n + 1;
    }
    return best;
  }

  /// [day] 아침 기준으로 재방문 연락 알림이 며칠째인지 (첫날 = 1). 아니면 null.
  int? revisitReminderDayOn(DateTime day) {
    final due = contactDueDate;
    if (due == null || contactedSinceDue) return null;
    final n = dateOnly(day).difference(due).inDays;
    if (n < 0 || n >= kMaxReminderDays) return null;
    return n + 1;
  }

  bool herbCheckDueOn(DateTime day) => herbReminderDayOn(day) != null;

  bool revisitDueOn(DateTime day) => revisitReminderDayOn(day) != null;

  /// '복약 15일' 같은 표시용 문구.
  String herbLabel(HerbAlert alert) {
    final start = customer.herbStart;
    if (start == null) return '복약 확인';
    return '복약 ${alert.dayFrom(start)}일';
  }

  /// 가장 최근 '내원' 날짜.
  DateTime? get lastVisit {
    for (final a in appointments.reversed) {
      if (a.status == AppointmentStatus.visited) return a.date;
    }
    return null;
  }

  /// 오늘 이후(오늘 포함) 가장 가까운 예약.
  Appointment? get nextBooking {
    final now = today();
    for (final a in appointments) {
      if (a.status == AppointmentStatus.booked && !a.date.isBefore(now)) {
        return a;
      }
    }
    return null;
  }

  /// 예약일이 지났는데 내원/노쇼 처리를 안 한 기록.
  List<Appointment> get uncheckedBookings =>
      appointments.where((a) => a.needsCheck).toList();

  /// 연락 기준이 되는 마지막 일정: 오늘 이전의 취소 아닌 일정 중 가장 최근.
  /// (내원 / 노쇼 / 처리 안 된 지난 예약 모두 포함)
  Appointment? get lastSchedule {
    final now = today();
    for (final a in appointments.reversed) {
      if (a.status == AppointmentStatus.cancelled) continue;
      if (a.date.isBefore(now) || a.status != AppointmentStatus.booked) {
        return a;
      }
    }
    return null;
  }

  /// 연락해야 하는 날. 다음 예약이 잡혀 있으면 null.
  /// 노쇼는 바로 연락 대상, 그 외에는 마지막 일정 + [kRevisitDays]일.
  DateTime? get contactDueDate {
    if (nextBooking != null) return null;
    final last = lastSchedule;
    if (last == null) return null;
    if (last.status == AppointmentStatus.noShow) return last.date;
    return last.date.add(const Duration(days: kRevisitDays));
  }

  bool get needsContact {
    final due = contactDueDate;
    return due != null && !today().isBefore(due);
  }

  /// 마지막 일정 후 지난 일수.
  int? get daysSinceLastSchedule {
    final last = lastSchedule;
    if (last == null) return null;
    return today().difference(last.date).inDays;
  }

  /// 연락 기한이 된 이후에 이미 '연락함' 처리를 했는지.
  bool get contactedSinceDue {
    final due = contactDueDate;
    final contact = lastContact;
    if (due == null || contact == null) return false;
    return !dateOnly(contact).isBefore(due);
  }

  /// 목록에 보여줄 한 줄 상태 설명.
  String get contactReason {
    final last = lastSchedule;
    if (last == null) return '';
    if (last.status == AppointmentStatus.noShow) {
      return '${formatShortDate(last.date)} 예약 노쇼';
    }
    final label = last.needsCheck ? '예약(미확인)' : last.status.label;
    return '마지막 $label ${formatShortDate(last.date)} · '
        '$daysSinceLastSchedule일 경과';
  }
}
