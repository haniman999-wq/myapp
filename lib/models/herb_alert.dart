import '../utils/date_format.dart';

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

/// 한약 종류. 종류마다 기본 확인 전화 날짜와 이름 뒤 표시가 다릅니다.
enum HerbType {
  /// 건강보험 첩약: 10일 뒤 확인 전화.
  insured('insured', '건보첩약', '건', [10]),

  /// 비급여한약: 15일 · 25일 뒤 확인 전화.
  nonInsured('nonInsured', '비급여한약', '비급', [15, 25]);

  const HerbType(this.dbValue, this.label, this.tag, this.defaultDays);

  final String dbValue;
  final String label;

  /// 이름 뒤에 붙는 짧은 표시. 화면에는 '🌿 건' 처럼 보입니다.
  final String tag;

  /// 복약 시작일로부터 기본으로 잡는 확인 전화 날짜(일).
  final List<int> defaultDays;

  String get nameTag => tag;

  /// 예전 데이터(종류 칸이 없던 때)는 비급여로 봅니다.
  static HerbType fromDb(String? value) =>
      values.firstWhere((t) => t.dbValue == value, orElse: () => nonInsured);
}
