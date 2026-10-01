import '../utils/date_format.dart';

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
  final DateTime createdAt;

  const Customer({
    this.id,
    required this.name,
    required this.phone,
    required this.gender,
    this.memo = '',
    this.herbStart,
    required this.createdAt,
  });

  /// 지금 한약을 복용 중인 환자인지.
  bool get isHerbal => herbStart != null;

  Customer copyWith({
    int? id,
    String? name,
    String? phone,
    String? gender,
    String? memo,
    DateTime? herbStart,
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
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}
