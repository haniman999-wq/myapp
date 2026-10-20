import 'package:flutter/material.dart';

/// 진료과. 이름은 관리자가 바꿀 수 있습니다.
class Department {
  const Department({required this.id, required this.name, this.sort = 0});

  final int id;
  final String name;
  final int sort;

  factory Department.fromMap(Map<String, Object?> map) => Department(
    id: map['id'] as int,
    name: map['name'] as String,
    sort: (map['sort'] as int?) ?? 0,
  );

  /// 과마다 다른 색 (정렬 순서 기준).
  Color get color => kDeptColors[(sort - 1).clamp(0, 99) % kDeptColors.length];
}

/// 진료과 배지 색. 다른 표시(초록·빨강·보라·청록·분홍·파랑)와 겹치지 않게 골랐어요.
const kDeptColors = <Color>[
  Color(0xFF5C6BC0), // 남색
  Color(0xFFEF6C00), // 주황
  Color(0xFF6D4C41), // 갈색
  Color(0xFF00838F), // 청록(진)
  Color(0xFFAD1457), // 자주
  Color(0xFF546E7A), // 회청
];

/// 직원 계정과 권한.
class StaffMember {
  const StaffMember({
    required this.id,
    required this.email,
    required this.isAdmin,
    required this.canViewStats,
  });

  final String id;
  final String email;
  final bool isAdmin;
  final bool canViewStats;

  factory StaffMember.fromMap(Map<String, Object?> map) => StaffMember(
    id: map['id'] as String,
    email: map['email'] as String,
    isAdmin: (map['is_admin'] as bool?) ?? false,
    canViewStats: (map['can_view_stats'] as bool?) ?? false,
  );
}
