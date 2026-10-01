/// 고객 한 명의 기본 정보.
///
/// 내원·예약 일정은 [Appointment] 로 따로 저장하고,
/// 마지막 내원일·다음 예약일은 [CustomerOverview] 에서 계산합니다.
class Customer {
  final int? id;
  final String name; // 고객명
  final String phone; // 전화번호
  final String gender; // 성별 ('남' | '여')
  final DateTime createdAt;

  const Customer({
    this.id,
    required this.name,
    required this.phone,
    required this.gender,
    required this.createdAt,
  });

  Customer copyWith({
    int? id,
    String? name,
    String? phone,
    String? gender,
    DateTime? createdAt,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      gender: gender ?? this.gender,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'gender': gender,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Customer.fromMap(Map<String, Object?> map) {
    return Customer(
      id: map['id'] as int?,
      name: map['name'] as String,
      phone: map['phone'] as String,
      gender: map['gender'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}
