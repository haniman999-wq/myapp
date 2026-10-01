import '../utils/date_format.dart';

/// 한약 복약 시작일로부터 기본으로 잡아두는 확인 전화 날짜(일).
const List<int> kDefaultHerbAlertDays = [15, 25];

/// 한 환자에게 걸어둘 수 있는 남은(미완료) 복약 알림 최대 개수.
const int kMaxHerbAlerts = 10;

/// 한약 복약 확인 알림 한 건. 이 날짜에 무조건 연락 대상이 됩니다.
class HerbAlert {
  final int? id;
  final int customerId;
  final DateTime date;

  /// 연락 후 '확인 완료'를 눌렀는지.
  final bool done;

  const HerbAlert({
    this.id,
    required this.customerId,
    required this.date,
    this.done = false,
  });

  /// 오늘이거나 이미 지났는데 아직 확인 안 한 알림.
  bool get isDue => !done && !date.isAfter(today());

  /// 복약 시작일로부터 며칠째인지. (시작일 = 0일)
  int dayFrom(DateTime start) =>
      dateOnly(date).difference(dateOnly(start)).inDays;

  HerbAlert copyWith({DateTime? date, bool? done}) {
    return HerbAlert(
      id: id,
      customerId: customerId,
      date: date ?? this.date,
      done: done ?? this.done,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'customerId': customerId,
      'date': toDbDate(date),
      'done': done ? 1 : 0,
    };
  }

  factory HerbAlert.fromMap(Map<String, Object?> map) {
    return HerbAlert(
      id: map['id'] as int?,
      customerId: map['customerId'] as int,
      date: DateTime.parse(map['date'] as String),
      done: (map['done'] as int) == 1,
    );
  }
}
