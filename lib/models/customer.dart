/// 고객 한 명의 정보.
///
/// ver.1 필수 입력: 고객명 · 성별 · 전화번호
/// 스케쥴링용 확장 필드(내원/예약일)는 선택 입력이라 nullable 로 둡니다.
class Customer {
  final int? id;
  final String name; // 고객명
  final String phone; // 전화번호
  final String gender; // 성별 ('남' | '여')
  final DateTime? firstVisit; // 최초내원일
  final DateTime? lastVisit; // 최종내원일
  final DateTime? appointment; // 예약일
  final DateTime createdAt;

  const Customer({
    this.id,
    required this.name,
    required this.phone,
    required this.gender,
    this.firstVisit,
    this.lastVisit,
    this.appointment,
    required this.createdAt,
  });

  /// 예약일이 지났는데 그 뒤로 내원 기록이 없으면 '노쇼(재진 로스)'로 본다.
  bool get isNoShow {
    final appt = appointment;
    if (appt == null) return false;
    // 예약일이 아직 오늘 이후면 노쇼가 아니다.
    final today = DateTime.now();
    final apptDay = DateTime(appt.year, appt.month, appt.day);
    final todayDay = DateTime(today.year, today.month, today.day);
    if (!apptDay.isBefore(todayDay)) return false;
    final last = lastVisit;
    if (last == null) return true;
    return last.isBefore(apptDay);
  }

  Customer copyWith({
    int? id,
    String? name,
    String? phone,
    String? gender,
    DateTime? firstVisit,
    DateTime? lastVisit,
    DateTime? appointment,
    DateTime? createdAt,
    bool clearFirstVisit = false,
    bool clearLastVisit = false,
    bool clearAppointment = false,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      gender: gender ?? this.gender,
      firstVisit: clearFirstVisit ? null : (firstVisit ?? this.firstVisit),
      lastVisit: clearLastVisit ? null : (lastVisit ?? this.lastVisit),
      appointment: clearAppointment ? null : (appointment ?? this.appointment),
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'gender': gender,
      'firstVisit': firstVisit?.toIso8601String(),
      'lastVisit': lastVisit?.toIso8601String(),
      'appointment': appointment?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Customer.fromMap(Map<String, Object?> map) {
    DateTime? parse(Object? value) =>
        value == null ? null : DateTime.parse(value as String);
    return Customer(
      id: map['id'] as int?,
      name: map['name'] as String,
      phone: map['phone'] as String,
      gender: map['gender'] as String,
      firstVisit: parse(map['firstVisit']),
      lastVisit: parse(map['lastVisit']),
      appointment: parse(map['appointment']),
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}
