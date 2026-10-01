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

/// 고객의 예약/내원 기록 한 건. 날짜 단위로만 관리합니다.
class Appointment {
  final int? id;
  final int customerId;
  final DateTime date;
  final AppointmentStatus status;

  const Appointment({
    this.id,
    required this.customerId,
    required this.date,
    required this.status,
  });

  /// 예약일이 지났는데 아직 '예약' 상태 → 내원했는지 확인이 필요.
  bool get needsCheck =>
      status == AppointmentStatus.booked && date.isBefore(today());

  Appointment copyWith({DateTime? date, AppointmentStatus? status}) {
    return Appointment(
      id: id,
      customerId: customerId,
      date: date ?? this.date,
      status: status ?? this.status,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'customerId': customerId,
      'date': toDbDate(date),
      'status': status.dbValue,
    };
  }

  factory Appointment.fromMap(Map<String, Object?> map) {
    return Appointment(
      id: map['id'] as int?,
      customerId: map['customerId'] as int,
      date: DateTime.parse(map['date'] as String),
      status: AppointmentStatus.fromDb(map['status'] as String),
    );
  }
}
