import '../utils/date_format.dart';
import 'herb_alert.dart';

/// 환자 한 명의 기본 정보.
///
/// 내원·예약 일정은 [Appointment] 로 따로 저장하고,
/// 마지막 내원일·다음 예약일은 [CustomerOverview] 에서 계산합니다.
class Customer {
  final int? id;
  final String name; // 환자명
  final String phone; // 전화번호
  final String gender; // 성별 ('남' | '여')
  final String memo; // 특이사항 메모
  final DateTime? herbStart; // 한약 복약 시작일 (null = 한약 환자 아님)
  final HerbType herbType; // 한약 종류 (건보첩약 | 비급여)
  final int? herbDays; // 복약 기간(일): 30 · 60 · 90. 정하지 않았으면 null
  final DateTime createdAt;

  const Customer({
    this.id,
    required this.name,
    required this.phone,
    required this.gender,
    this.memo = '',
    this.herbStart,
    this.herbType = HerbType.nonInsured,
    this.herbDays,
    required this.createdAt,
  });

  /// 지금 한약을 복용 중인 환자인지.
  bool get isHerbal => herbStart != null;

  /// 남은 복약 일수 (0 ~ [herbDays]). 기간을 정하지 않았으면 null.
  /// 일정 미루기로 시작일이 뒤로 가면 남은 일수도 그만큼 늘어납니다.
  int? get herbRemainingDays {
    final start = herbStart;
    final days = herbDays;
    if (start == null || days == null) return null;
    final end = dateOnly(start).add(Duration(days: days));
    return end.difference(today()).inDays.clamp(0, days);
  }

  Customer copyWith({
    int? id,
    String? name,
    String? phone,
    String? gender,
    String? memo,
    DateTime? herbStart,
    HerbType? herbType,
    int? herbDays,
    DateTime? createdAt,
    bool clearHerbStart = false,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      gender: gender ?? this.gender,
      memo: memo ?? this.memo,
      herbStart: clearHerbStart ? null : (herbStart ?? this.herbStart),
      herbType: herbType ?? this.herbType,
      herbDays: herbDays ?? this.herbDays,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, Object?> toMap() {
    final start = herbStart;
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'gender': gender,
      'memo': memo,
      'herbStart': start == null ? null : toDbDate(start),
      'herbType': start == null ? null : herbType.dbValue,
      'herbDays': start == null ? null : herbDays,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Customer.fromMap(Map<String, Object?> map) {
    final start = map['herbStart'] as String?;
    return Customer(
      id: map['id'] as int?,
      name: map['name'] as String,
      phone: map['phone'] as String,
      gender: map['gender'] as String,
      memo: (map['memo'] as String?) ?? '',
      herbStart: start == null ? null : DateTime.parse(start),
      herbType: HerbType.fromDb(map['herbType'] as String?),
      herbDays: map['herbDays'] as int?,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}
