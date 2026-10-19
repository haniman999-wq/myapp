import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import 'customer_database.dart';

/// 서버로 옮기기 전, 이 휴대폰 안(SQLite)에 저장돼 있던 예전 데이터.
///
/// 읽기만 합니다. 서버로 옮긴 뒤에는 '옮김' 표시를 남겨 다시 묻지 않습니다.
class LegacyLocalStore {
  LegacyLocalStore._();

  static const _fileName = 'my_customers.db';
  static const _migratedKey = 'legacyMigrated';
  static const _tables = [
    'customers',
    'appointments',
    'contact_logs',
    'herb_alerts',
  ];

  static Future<bool> isMigrated() async =>
      (await SharedPreferences.getInstance()).getBool(_migratedKey) ?? false;

  static Future<void> markMigrated() async =>
      (await SharedPreferences.getInstance()).setBool(_migratedKey, true);

  /// 예전 데이터를 백업 파일과 같은 형식으로 읽습니다. 없거나 비어 있으면 null.
  static Future<Map<String, Object?>?> read() async {
    if (kIsWeb || !Platform.isAndroid) return null;
    try {
      final path = join(await getDatabasesPath(), _fileName);
      if (!await File(path).exists()) return null;
      final db = await openReadOnlyDatabase(path);
      try {
        final tables = <String, Object?>{};
        for (final t in _tables) {
          try {
            tables[t] = await db.query(t, orderBy: 'id');
          } catch (_) {
            tables[t] = const []; // 아주 예전 버전엔 없는 표
          }
        }
        if ((tables['customers'] as List).isEmpty) return null;
        return {
          'format': CustomerDatabase.backupFormat,
          'formatVersion': 1,
          'exportedAt': DateTime.now().toIso8601String(),
          'tables': tables,
        };
      } finally {
        await db.close();
      }
    } catch (e) {
      debugPrint('예전 데이터 읽기 실패: $e');
      return null;
    }
  }

  /// 옮길 예전 환자 수 (옮겼거나 없으면 0).
  static Future<int> pendingCount() async {
    if (await isMigrated()) return 0;
    final data = await read();
    if (data == null) return 0;
    return ((data['tables'] as Map)['customers'] as List).length;
  }
}
