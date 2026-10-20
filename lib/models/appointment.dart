import 'package:flutter/material.dart';

import '../utils/date_format.dart';

/// 예약 한 건의 상태.
enum AppointmentStatus {
  booked('booked', '예약', Color(0xFF1E88E5)),
  visited('visited', '내원', Color(0xFF009624)),
  noShow('noShow', '노쇼', Color(0xFFE53935)),
  cancelled('cancelled', '취소', Colors.grey);

  const AppointmentStatus(this.dbValue, this.label, this.color);

  final String dbValue;
  final String label;
  final Color color;

  static AppointmentStatus fromDb(String value) =>
      values.firstWhere((s) => s.dbValue == value, orElse: () => booked);
}

/// 환자의 예약/내원 기록 한 건. 날짜 단위로만 관리합니다.
class Appointment {
  final int? id;
  final int customerId;
  final DateTime date;
  final AppointmentStatus status;

  /// 예약 시각 (자정부터 몇 분째인지). 시간을 정하지 않았으면 null.
  final int? minuteOfDay;

  /// 이 날짜 기록에 남기는 메모 (치료 내용, 전달 사항 등).
  final String memo;

  /// 진료과 (departments 표의 id). 정하지 않았으면 null.
  final int? deptId;

  const Appointment({
    this.id,
    required this.customerId,
    required this.date,
    required this.status,
    this.minuteOfDay,
    this.memo = '',
    this.deptId,
  });

  int? get hour => minuteOfDay == null ? null : minuteOfDay! ~/ 60;
  int? get minute => minuteOfDay == null ? null : minuteOfDay! % 60;

  /// '오전 10:30'. 시간이 없으면 null.
  String? get timeLabel =>
      minuteOfDay == null ? null : formatTimeOfDay(hour!, minute!);

  /// 예약일이 지났는데 아직 '예약' 상태 → 내원했는지 확인이 필요.
  bool get needsCheck =>
      status == AppointmentStatus.booked && date.isBefore(today());

  Appointment copyWith({
    DateTime? date,
    AppointmentStatus? status,
    int? minuteOfDay,
    String? memo,
    int? deptId,
    bool clearTime = false,
    bool clearDept = false,
  }) {
    return Appointment(
      id: id,
      customerId: customerId,
      date: date ?? this.date,
      status: status ?? this.status,
      minuteOfDay: clearTime ? null : (minuteOfDay ?? this.minuteOfDay),
      memo: memo ?? this.memo,
      deptId: clearDept ? null : (deptId ?? this.deptId),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'customerId': customerId,
      'date': toDbDate(date),
      'status': status.dbValue,
      'minuteOfDay': minuteOfDay,
      'memo': memo,
      // 진료과는 정했을 때만 보냅니다 (서버에 진료과 칸을 만들기 전에도 저장되게).
      if (deptId != null) 'deptId': deptId,
    };
  }

  factory Appointment.fromMap(Map<String, Object?> map) {
    return Appointment(
      id: map['id'] as int?,
      customerId: map['customerId'] as int,
      date: DateTime.parse(map['date'] as String),
      status: AppointmentStatus.fromDb(map['status'] as String),
      minuteOfDay: map['minuteOfDay'] as int?,
      memo: (map['memo'] as String?) ?? '',
      deptId: map['deptId'] as int?,
    );
  }
}
