import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/appointment.dart';
import '../models/customer.dart';
import '../models/customer_overview.dart';
import '../models/herb_alert.dart';
import '../utils/date_format.dart';

class CustomerDatabase {
  CustomerDatabase._internal();

  static final CustomerDatabase instance = CustomerDatabase._internal();

  Database? _database;

  /// 데이터가 바뀔 때마다 값이 올라갑니다. 화면들은 이걸 듣고 다시 불러옵니다.
  final ValueNotifier<int> changes = ValueNotifier(0);

  void notifyChanged() => changes.value++;

  Future<Database> get database async {
    final existing = _database;
    if (existing != null) return existing;
    final db = await _initDatabase();
    _database = db;
    return db;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'my_customers.db');
    return openDatabase(
      path,
      version: 6,
      onCreate: (db, version) async {
        await _createMetaTable(db);
        await db.execute('''
          CREATE TABLE customers (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            phone TEXT NOT NULL,
            gender TEXT NOT NULL,
            memo TEXT NOT NULL DEFAULT '',
            herbStart TEXT,
            createdAt TEXT NOT NULL
          )
        ''');
        await _createScheduleTables(db);
        await _createHerbTable(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) await _migrateToV2(db);
        if (oldVersion < 3) {
          // ver.3: 환자 특이사항 메모
          await db.execute(
            "ALTER TABLE customers ADD COLUMN memo TEXT NOT NULL DEFAULT ''",
          );
        }
        if (oldVersion < 4) {
          // ver.4: 한약 복약 시작일 + 복약 확인 알림
          await db.execute('ALTER TABLE customers ADD COLUMN herbStart TEXT');
          await _createHerbTable(db);
        }
        if (oldVersion < 5) {
          // ver.5: 앱 설정값 (마지막 백업 시각 등)
          await _createMetaTable(db);
        }
        if (oldVersion < 6) {
          // ver.6: 예약 시각
          await db.execute(
            'ALTER TABLE appointments ADD COLUMN minuteOfDay INTEGER',
          );
        }
      },
    );
  }

  Future<void> _createMetaTable(DatabaseExecutor db) async {
    await db.execute(
      'CREATE TABLE meta (key TEXT PRIMARY KEY, value TEXT NOT NULL)',
    );
  }

  Future<void> _createHerbTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE herb_alerts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customerId INTEGER NOT NULL,
        date TEXT NOT NULL,
        done INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_herb_alerts_customer ON herb_alerts(customerId)',
    );
  }

  Future<void> _createScheduleTables(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE appointments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customerId INTEGER NOT NULL,
        date TEXT NOT NULL,
        status TEXT NOT NULL,
        minuteOfDay INTEGER
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_appointments_customer ON appointments(customerId)',
    );
    await db.execute(
      'CREATE INDEX idx_appointments_date ON appointments(date)',
    );
    await db.execute('''
      CREATE TABLE contact_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customerId INTEGER NOT NULL,
        contactedAt TEXT NOT NULL
      )
    ''');
  }

  /// ver.1 의 환자별 최초내원일/최종내원일/예약일 칸을 예약 기록으로 옮깁니다.
  /// (예전 칸은 SQLite 특성상 남겨두지만 더 이상 쓰지 않습니다.)
  Future<void> _migrateToV2(Database db) async {
    await db.transaction((txn) async {
      await _createScheduleTables(txn);
      final rows = await txn.query('customers');
      for (final row in rows) {
        final id = row['id'] as int;
        final dates = <String, AppointmentStatus>{};
        void add(Object? value, AppointmentStatus status) {
          if (value == null) return;
          dates.putIfAbsent(
            toDbDate(DateTime.parse(value as String)),
            () => status,
          );
        }

        add(row['firstVisit'], AppointmentStatus.visited);
        add(row['lastVisit'], AppointmentStatus.visited);
        add(row['appointment'], AppointmentStatus.booked);
        for (final entry in dates.entries) {
          await txn.insert('appointments', {
            'customerId': id,
            'date': entry.key,
            'status': entry.value.dbValue,
          });
        }
      }
    });
  }

  // ───────── 환자 ─────────

  Future<List<Customer>> getAllCustomers() async {
    final db = await database;
    final rows = await db.query(
      'customers',
      orderBy: 'name COLLATE NOCASE ASC',
    );
    return rows.map(Customer.fromMap).toList();
  }

  Future<Customer> insertCustomer(Customer customer) async {
    final db = await database;
    final id = await db.insert('customers', customer.toMap()..remove('id'));
    notifyChanged();
    return customer.copyWith(id: id);
  }

  Future<void> updateCustomer(Customer customer) async {
    final db = await database;
    await db.update(
      'customers',
      customer.toMap(),
      where: 'id = ?',
      whereArgs: [customer.id],
    );
    notifyChanged();
  }

  Future<void> deleteCustomer(int id) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(
        'appointments',
        where: 'customerId = ?',
        whereArgs: [id],
      );
      await txn.delete(
        'contact_logs',
        where: 'customerId = ?',
        whereArgs: [id],
      );
      await txn.delete('herb_alerts', where: 'customerId = ?', whereArgs: [id]);
      await txn.delete('customers', where: 'id = ?', whereArgs: [id]);
    });
    notifyChanged();
  }

  Future<void> deleteAllCustomers() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('appointments');
      await txn.delete('contact_logs');
      await txn.delete('herb_alerts');
      await txn.delete('customers');
    });
    notifyChanged();
  }

  // ───────── 예약 ─────────

  Future<void> saveAppointment(Appointment appointment) async {
    final db = await database;
    if (appointment.id == null) {
      await db.insert('appointments', appointment.toMap()..remove('id'));
    } else {
      await db.update(
        'appointments',
        appointment.toMap(),
        where: 'id = ?',
        whereArgs: [appointment.id],
      );
    }
    notifyChanged();
  }

  Future<void> deleteAppointment(int id) async {
    final db = await database;
    await db.delete('appointments', where: 'id = ?', whereArgs: [id]);
    notifyChanged();
  }

  // ───────── 연락 기록 ─────────

  Future<void> logContact(int customerId) async {
    final db = await database;
    await db.insert('contact_logs', {
      'customerId': customerId,
      'contactedAt': DateTime.now().toIso8601String(),
    });
    notifyChanged();
  }

  // ───────── 한약 복약 ─────────

  /// 복약 시작일과 앞으로의 확인 알림 날짜를 한꺼번에 저장합니다.
  /// 이미 '확인 완료'한 알림은 기록으로 남기고, 미완료 알림만 [dates] 로 교체합니다.
  Future<void> saveHerbPlan({
    required int customerId,
    required DateTime start,
    required List<DateTime> dates,
  }) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.update(
        'customers',
        {'herbStart': toDbDate(start)},
        where: 'id = ?',
        whereArgs: [customerId],
      );
      await txn.delete(
        'herb_alerts',
        where: 'customerId = ? AND done = 0',
        whereArgs: [customerId],
      );
      for (final d in dates.toSet()) {
        await txn.insert('herb_alerts', {
          'customerId': customerId,
          'date': toDbDate(d),
          'done': 0,
        });
      }
    });
    notifyChanged();
  }

  /// 복약이 밀렸을 때: 복약 시작일과 미완료 알림을 모두 [days]일 뒤로 미룹니다.
  Future<void> postponeHerbPlan(int customerId, int days) async {
    final db = await database;
    await db.transaction((txn) async {
      final rows = await txn.query(
        'customers',
        columns: ['herbStart'],
        where: 'id = ?',
        whereArgs: [customerId],
      );
      final start = rows.isEmpty ? null : rows.first['herbStart'] as String?;
      if (start == null) return;
      await txn.update(
        'customers',
        {
          'herbStart': toDbDate(
            DateTime.parse(start).add(Duration(days: days)),
          ),
        },
        where: 'id = ?',
        whereArgs: [customerId],
      );
      final alerts = await txn.query(
        'herb_alerts',
        where: 'customerId = ? AND done = 0',
        whereArgs: [customerId],
      );
      for (final row in alerts) {
        final a = HerbAlert.fromMap(row);
        await txn.update(
          'herb_alerts',
          {'date': toDbDate(a.date.add(Duration(days: days)))},
          where: 'id = ?',
          whereArgs: [a.id],
        );
      }
    });
    notifyChanged();
  }

  /// 복약 확인 전화를 마쳤을 때.
  Future<void> completeHerbAlert(int alertId) async {
    final db = await database;
    await db.update(
      'herb_alerts',
      {'done': 1},
      where: 'id = ?',
      whereArgs: [alertId],
    );
    notifyChanged();
  }

  /// 복약 종료: 한약 표시를 끄고 남은 알림을 지웁니다. (완료 기록은 남김)
  Future<void> endHerbPlan(int customerId) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.update(
        'customers',
        {'herbStart': null},
        where: 'id = ?',
        whereArgs: [customerId],
      );
      await txn.delete(
        'herb_alerts',
        where: 'customerId = ? AND done = 0',
        whereArgs: [customerId],
      );
    });
    notifyChanged();
  }

  // ───────── 백업 / 복원 ─────────

  /// 백업에 담는 표. (meta 는 기기별 설정이라 제외)
  static const _backupTables = [
    'customers',
    'appointments',
    'contact_logs',
    'herb_alerts',
  ];

  static const backupFormat = 'my-patients-backup';
  static const _lastBackupKey = 'lastBackupAt';

  /// 모든 데이터를 JSON 으로 바꿀 수 있는 지도(Map)로 꺼냅니다.
  Future<Map<String, Object?>> exportData() async {
    final db = await database;
    return {
      'format': backupFormat,
      'formatVersion': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'tables': {
        for (final t in _backupTables) t: await db.query(t, orderBy: 'id'),
      },
    };
  }

  /// 백업 데이터로 지금 데이터를 통째로 바꿉니다. 형식이 틀리면 [FormatException].
  Future<void> importData(Map<String, Object?> data) async {
    if (data['format'] != backupFormat || data['tables'] is! Map) {
      throw const FormatException('이 앱의 백업 파일이 아니에요');
    }
    final tables = (data['tables'] as Map).cast<String, Object?>();
    final db = await database;
    await db.transaction((txn) async {
      for (final t in _backupTables) {
        // 지금 표에 있는 칸만 넣습니다. (다른 버전의 백업도 받을 수 있게)
        final columns = {
          for (final c in await txn.rawQuery('PRAGMA table_info($t)'))
            c['name'] as String,
        };
        await txn.delete(t);
        final rows = tables[t];
        if (rows is! List) continue;
        for (final row in rows) {
          if (row is! Map) continue;
          await txn.insert(t, {
            for (final e in row.entries)
              if (columns.contains(e.key)) e.key as String: e.value,
          });
        }
      }
    });
    notifyChanged();
  }

  Future<String?> _getMeta(String key) async {
    final db = await database;
    final rows = await db.query('meta', where: 'key = ?', whereArgs: [key]);
    return rows.isEmpty ? null : rows.first['value'] as String;
  }

  Future<void> _setMeta(String key, String value) async {
    final db = await database;
    await db.insert('meta', {
      'key': key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    notifyChanged();
  }

  Future<DateTime?> getLastBackupAt() async {
    final value = await _getMeta(_lastBackupKey);
    return value == null ? null : DateTime.tryParse(value);
  }

  Future<void> setLastBackupAt(DateTime at) =>
      _setMeta(_lastBackupKey, at.toIso8601String());

  // ───────── 알림 시간 ─────────

  static const _notifyTimeKey = 'notifyTime';

  /// 아침 요약 알림 시각 (시, 분). 기본 오전 9시.
  Future<(int, int)> getNotifyTime() async {
    final value = await _getMeta(_notifyTimeKey);
    final parts = value?.split(':');
    if (parts == null || parts.length != 2) return (9, 0);
    return (int.tryParse(parts[0]) ?? 9, int.tryParse(parts[1]) ?? 0);
  }

  Future<void> setNotifyTime(int hour, int minute) =>
      _setMeta(_notifyTimeKey, '$hour:$minute');

  // ───────── 화면용 묶음 조회 ─────────

  /// 모든 환자 + 예약 기록 + 복약 알림 + 마지막 연락일을 한 번에 불러옵니다.
  Future<List<CustomerOverview>> getOverviews() async {
    final db = await database;
    final customers = await getAllCustomers();
    final apptRows = await db.query('appointments', orderBy: 'date ASC');
    final herbRows = await db.query('herb_alerts', orderBy: 'date ASC');
    final contactRows = await db.rawQuery(
      'SELECT customerId, MAX(contactedAt) AS last FROM contact_logs '
      'GROUP BY customerId',
    );

    final apptsByCustomer = <int, List<Appointment>>{};
    for (final row in apptRows) {
      final a = Appointment.fromMap(row);
      apptsByCustomer.putIfAbsent(a.customerId, () => []).add(a);
    }
    final herbByCustomer = <int, List<HerbAlert>>{};
    for (final row in herbRows) {
      final a = HerbAlert.fromMap(row);
      herbByCustomer.putIfAbsent(a.customerId, () => []).add(a);
    }
    final lastContact = {
      for (final row in contactRows)
        row['customerId'] as int: DateTime.parse(row['last'] as String),
    };

    return [
      for (final c in customers)
        CustomerOverview(
          customer: c,
          appointments: apptsByCustomer[c.id] ?? const [],
          herbAlerts: herbByCustomer[c.id] ?? const [],
          lastContact: lastContact[c.id],
        ),
    ];
  }

  Future<CustomerOverview?> getOverview(int customerId) async {
    final all = await getOverviews();
    for (final o in all) {
      if (o.customer.id == customerId) return o;
    }
    return null;
  }
}
