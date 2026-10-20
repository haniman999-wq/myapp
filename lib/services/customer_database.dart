import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/appointment.dart';
import '../models/customer.dart';
import '../models/customer_overview.dart';
import '../models/department.dart';
import '../models/herb_alert.dart';
import '../utils/date_format.dart';

/// 서버 연결이 안 돼서 저장하지 못했을 때.
class OfflineException implements Exception {
  const OfflineException();

  @override
  String toString() => '인터넷 연결을 확인해 주세요. 저장하지 못했어요.';
}

/// 환자 데이터 저장소 (공유 서버: Supabase).
///
/// 접수 PC와 직원 휴대폰이 같은 데이터를 봅니다.
/// - 서버의 4개 표를 통째로 불러와 [_snapshot] 으로 들고 있고, 화면들은 여기서 계산합니다.
/// - 다른 기기가 고치면 실시간 알림을 받아 다시 불러옵니다.
/// - 인터넷이 끊기면 마지막으로 받은 내용(이 기기에 저장)을 보여주고, 저장은 막습니다.
class CustomerDatabase {
  CustomerDatabase._internal();

  static final CustomerDatabase instance = CustomerDatabase._internal();

  /// 데이터가 바뀔 때마다 값이 올라갑니다. 화면들은 이걸 듣고 다시 불러옵니다.
  final ValueNotifier<int> changes = ValueNotifier(0);

  /// 지금 서버와 연결이 안 돼서 저장된 사본을 보여주는 중인지.
  final ValueNotifier<bool> offline = ValueNotifier(false);

  /// 저장 실패 등 사용자에게 알릴 말을 띄울 곳. (MaterialApp 에 연결)
  final messengerKey = GlobalKey<ScaffoldMessengerState>();

  static const _tables = [
    'customers',
    'appointments',
    'contact_logs',
    'herb_alerts',
  ];
  static const _cacheKey = 'snapshotCache';

  SupabaseClient get _client => Supabase.instance.client;

  Map<String, List<Map<String, Object?>>>? _snapshot;
  Future<void>? _loading;
  RealtimeChannel? _channel;
  Timer? _debounce;

  void notifyChanged() {
    _snapshot = null; // 다음 조회 때 서버에서 새로 받기
    changes.value++;
  }

  // ───────── 실시간 반영 ─────────

  /// 로그인 뒤 호출: 다른 기기의 변경을 실시간으로 받습니다.
  void startRealtime() {
    stopRealtime();
    var channel = _client.channel('clinic-data');
    for (final t in [..._tables, ..._extraTables]) {
      channel = channel.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: t,
        callback: (_) {
          // 한꺼번에 여러 줄이 바뀌어도 한 번만 다시 불러옵니다.
          _debounce?.cancel();
          _debounce = Timer(const Duration(milliseconds: 400), notifyChanged);
        },
      );
    }
    _channel = channel..subscribe();
  }

  void stopRealtime() {
    _debounce?.cancel();
    final channel = _channel;
    _channel = null;
    if (channel != null) _client.removeChannel(channel);
  }

  /// 로그아웃할 때: 이 기기에 남은 사본을 지웁니다.
  Future<void> clearLocal() async {
    stopRealtime();
    _snapshot = null;
    (await SharedPreferences.getInstance()).remove(_cacheKey);
    changes.value++;
  }

  // ───────── 불러오기 ─────────

  /// 한 표를 1000줄씩 끊어서 전부 받습니다.
  Future<List<Map<String, Object?>>> _fetchAll(String table) async {
    const page = 1000;
    final rows = <Map<String, Object?>>[];
    for (var from = 0; ; from += page) {
      final chunk = await _client
          .from(table)
          .select()
          .order('id')
          .range(from, from + page - 1);
      rows.addAll(chunk.cast<Map<String, Object?>>());
      if (chunk.length < page) break;
    }
    return rows;
  }

  /// 진료과·직원 표. 서버에 2단계 SQL 을 아직 안 넣었으면 없을 수 있어서,
  /// 없으면 빈 목록으로 두고 나머지 기능은 그대로 쓰게 합니다.
  static const _extraTables = ['departments', 'staff'];

  Future<List<Map<String, Object?>>> _fetchOptional(String table) async {
    try {
      return await _fetchAll(table);
    } on PostgrestException catch (e) {
      debugPrint('$table 표를 못 불러왔어요 (서버 설정 전?): ${e.message}');
      return const [];
    }
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        ..._tables.map(_fetchAll),
        ..._extraTables.map(_fetchOptional),
      ]);
      _snapshot = {
        for (final (i, t) in [..._tables, ..._extraTables].indexed)
          t: results[i],
      };
      offline.value = false;
      // 인터넷이 끊겼을 때 보여줄 사본
      (await SharedPreferences.getInstance()).setString(
        _cacheKey,
        jsonEncode(_snapshot),
      );
    } catch (e) {
      debugPrint('서버에서 불러오기 실패: $e');
      offline.value = true;
      _snapshot =
          await _readCache() ??
          {
            for (final t in [..._tables, ..._extraTables]) t: [],
          };
    }
  }

  Future<Map<String, List<Map<String, Object?>>>?> _readCache() async {
    final raw = (await SharedPreferences.getInstance()).getString(_cacheKey);
    if (raw == null) return null;
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return {
      for (final t in [..._tables, ..._extraTables])
        t: [
          for (final r in (decoded[t] as List? ?? const []))
            (r as Map).cast<String, Object?>(),
        ],
    };
  }

  Future<Map<String, List<Map<String, Object?>>>> _data() async {
    final snap = _snapshot;
    if (snap != null) return snap;
    await (_loading ??= _load().whenComplete(() => _loading = null));
    return _snapshot!;
  }

  // ───────── 저장 공통 ─────────

  /// 서버에 쓰고, 성공하면 모든 화면을 새로 고칩니다.
  /// 실패하면 화면 아래에 알리고 [OfflineException] 을 던집니다.
  Future<T> _write<T>(Future<T> Function(SupabaseClient c) action) async {
    try {
      final result = await action(_client);
      notifyChanged();
      return result;
    } catch (e) {
      debugPrint('서버 저장 실패: $e');
      // 권한 규칙에 막힌 경우(관리자 전용 기능 등)는 인터넷 문제와 구분해서 알립니다.
      final denied = e is PostgrestException && e.code == '42501';
      messengerKey.currentState
        ?..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              denied
                  ? '이 작업을 할 권한이 없어요. 원장님(관리자)에게 문의하세요.'
                  : '인터넷 연결을 확인해 주세요. 저장하지 못했어요.',
            ),
          ),
        );
      throw const OfflineException();
    }
  }

  // ───────── 진료과 · 직원 권한 ─────────

  /// 진료과 번호 → 진료과. 마지막으로 불러온 내용 (화면에서 바로 배지 그릴 때).
  Map<int, Department> get deptById => {
    for (final r in _snapshot?['departments'] ?? const <Map<String, Object?>>[])
      r['id'] as int: Department.fromMap(r),
  };

  /// 진료과 목록 (정렬 순서대로). 서버 설정 전이면 빈 목록.
  Future<List<Department>> getDepartments() async {
    final rows = (await _data())['departments'] ?? const [];
    return rows.map(Department.fromMap).toList()
      ..sort((a, b) => a.sort.compareTo(b.sort));
  }

  Future<void> renameDepartment(int id, String name) => _write(
    (c) => c.from('departments').update({'name': name.trim()}).eq('id', id),
  );

  Future<List<StaffMember>> getStaff() async {
    final rows = (await _data())['staff'] ?? const [];
    return rows.map(StaffMember.fromMap).toList()
      ..sort((a, b) => a.email.compareTo(b.email));
  }

  /// 지금 로그인한 직원의 권한. 목록에 없으면 null.
  Future<StaffMember?> me() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return null;
    for (final s in await getStaff()) {
      if (s.id == uid) return s;
    }
    return null;
  }

  Future<void> setStatsPermission(String staffId, bool allowed) => _write(
    (c) =>
        c.from('staff').update({'can_view_stats': allowed}).eq('id', staffId),
  );

  /// 새 줄을 넣을 땐 id 를 빼서 서버가 번호를 매기게 합니다.
  static Map<String, Object?> _noId(Map<String, Object?> m) =>
      Map.of(m)..remove('id');

  // ───────── 환자 ─────────

  Future<List<Customer>> getAllCustomers() async {
    final rows = (await _data())['customers']!;
    return rows.map(Customer.fromMap).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  Future<Customer> insertCustomer(Customer customer) => _write((c) async {
    final row = await c
        .from('customers')
        .insert(_noId(customer.toMap()))
        .select('id')
        .single();
    return customer.copyWith(id: row['id'] as int);
  });

  Future<void> updateCustomer(Customer customer) => _write(
    (c) => c
        .from('customers')
        .update(_noId(customer.toMap()))
        .eq('id', customer.id!),
  );

  /// 환자를 지우면 그 환자의 예약·연락·복약 기록도 서버에서 함께 지워집니다.
  Future<void> deleteCustomer(int id) =>
      _write((c) => c.from('customers').delete().eq('id', id));

  Future<void> deleteAllCustomers() =>
      _write((c) => c.from('customers').delete().gte('id', 0));

  // ───────── 예약 ─────────

  Future<void> saveAppointment(Appointment appointment) => _write((c) async {
    if (appointment.id == null) {
      await c.from('appointments').insert(_noId(appointment.toMap()));
    } else {
      await c
          .from('appointments')
          .update(_noId(appointment.toMap()))
          .eq('id', appointment.id!);
    }
  });

  Future<void> deleteAppointment(int id) =>
      _write((c) => c.from('appointments').delete().eq('id', id));

  // ───────── 연락 기록 ─────────

  Future<void> logContact(int customerId) => _write(
    (c) => c.from('contact_logs').insert({
      'customerId': customerId,
      'contactedAt': DateTime.now().toIso8601String(),
    }),
  );

  // ───────── 한약 복약 ─────────

  /// 복약 시작일·종류·기간과 앞으로의 확인 알림 날짜를 저장합니다.
  /// 이미 '확인 완료'한 알림은 기록으로 남기고, 미완료 알림만 [dates] 로 교체합니다.
  Future<void> saveHerbPlan({
    required int customerId,
    required DateTime start,
    required List<DateTime> dates,
    required HerbType type,
    int? days,
  }) => _write((c) async {
    await c
        .from('customers')
        .update({
          'herbStart': toDbDate(start),
          'herbType': type.dbValue,
          'herbDays': days,
        })
        .eq('id', customerId);
    await c
        .from('herb_alerts')
        .delete()
        .eq('customerId', customerId)
        .eq('done', 0);
    final unique = {for (final d in dates) toDbDate(d)};
    if (unique.isNotEmpty) {
      await c.from('herb_alerts').insert([
        for (final d in unique)
          {'customerId': customerId, 'date': d, 'done': 0},
      ]);
    }
  });

  /// 복약이 밀렸을 때: 복약 시작일과 미완료 알림을 모두 [days]일 뒤로 미룹니다.
  Future<void> postponeHerbPlan(int customerId, int days) => _write((c) async {
    final row = await c
        .from('customers')
        .select('herbStart')
        .eq('id', customerId)
        .maybeSingle();
    final start = row?['herbStart'] as String?;
    if (start == null) return;
    String shift(String d) =>
        toDbDate(DateTime.parse(d).add(Duration(days: days)));
    await c
        .from('customers')
        .update({'herbStart': shift(start)})
        .eq('id', customerId);
    final alerts = await c
        .from('herb_alerts')
        .select('id, date')
        .eq('customerId', customerId)
        .eq('done', 0);
    for (final a in alerts) {
      await c
          .from('herb_alerts')
          .update({'date': shift(a['date'] as String)})
          .eq('id', a['id'] as int);
    }
  });

  /// 복약 확인 전화를 마쳤을 때.
  Future<void> completeHerbAlert(int alertId) => _write(
    (c) => c.from('herb_alerts').update({'done': 1}).eq('id', alertId),
  );

  /// 복약 종료: 한약 표시를 끄고 남은 알림을 지웁니다. (완료 기록은 남김)
  Future<void> endHerbPlan(int customerId) => _write((c) async {
    await c
        .from('customers')
        .update({'herbStart': null, 'herbType': null, 'herbDays': null})
        .eq('id', customerId);
    await c
        .from('herb_alerts')
        .delete()
        .eq('customerId', customerId)
        .eq('done', 0);
  });

  // ───────── 백업 / 복원 ─────────

  static const backupFormat = 'my-patients-backup';

  /// 서버의 모든 데이터를 백업 파일 형식으로 꺼냅니다.
  Future<Map<String, Object?>> exportData() async {
    _snapshot = null; // 백업은 꼭 최신으로
    final data = await _data();
    if (offline.value) throw const OfflineException();
    return {
      'format': backupFormat,
      'formatVersion': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'tables': {
        for (final t in _tables)
          t: [
            for (final row in data[t]!)
              // 서버 관리용 칸은 백업에 넣지 않습니다.
              Map.of(row)
                ..remove('updated_at')
                ..remove('updated_by'),
          ],
      },
    };
  }

  /// 백업(또는 예전 휴대폰 데이터)을 서버에 넣습니다.
  /// [replace] 가 true 면 서버의 기존 데이터를 모두 지우고 넣습니다.
  /// 환자 번호는 서버가 새로 매기고, 예약·연락·복약 기록도 새 번호로 이어 줍니다.
  Future<void> importData(
    Map<String, Object?> data, {
    bool replace = true,
  }) async {
    if (data['format'] != backupFormat || data['tables'] is! Map) {
      throw const FormatException('이 앱의 백업 파일이 아니에요');
    }
    final tables = (data['tables'] as Map).cast<String, Object?>();
    List<Map<String, Object?>> rowsOf(String t) => [
      for (final r in (tables[t] as List? ?? const []))
        if (r is Map) r.cast<String, Object?>(),
    ];

    await _write((c) async {
      if (replace) await c.from('customers').delete().gte('id', 0);

      // 1) 환자: 한 명씩 넣고 예전 번호 → 새 번호를 기억
      final idMap = <int, int>{};
      for (final row in rowsOf('customers')) {
        final old = row['id'] as int?;
        final inserted = await c
            .from('customers')
            .insert(_noId(Customer.fromMap(row).toMap()))
            .select('id')
            .single();
        if (old != null) idMap[old] = inserted['id'] as int;
      }

      // 2) 나머지 기록: 새 환자 번호로 바꿔서 500줄씩
      Future<void> insertChildren(
        String table,
        Map<String, Object?> Function(Map<String, Object?>) convert,
      ) async {
        final rows = <Map<String, Object?>>[];
        for (final row in rowsOf(table)) {
          final newId = idMap[row['customerId'] as int?];
          if (newId == null) continue;
          rows.add(_noId(convert(row))..['customerId'] = newId);
        }
        for (var i = 0; i < rows.length; i += 500) {
          await c
              .from(table)
              .insert(rows.sublist(i, (i + 500).clamp(0, rows.length)));
        }
      }

      await insertChildren(
        'appointments',
        (r) => Appointment.fromMap(r).toMap(),
      );
      await insertChildren('herb_alerts', (r) => HerbAlert.fromMap(r).toMap());
      await insertChildren(
        'contact_logs',
        (r) => {'customerId': r['customerId'], 'contactedAt': r['contactedAt']},
      );
    });
  }

  // ───────── 기기별 설정 (이 기기에만 저장) ─────────

  static const _lastBackupKey = 'lastBackupAt';
  static const _notifyTimeKey = 'notifyTime';

  Future<DateTime?> getLastBackupAt() async {
    final value = (await SharedPreferences.getInstance()).getString(
      _lastBackupKey,
    );
    return value == null ? null : DateTime.tryParse(value);
  }

  Future<void> setLastBackupAt(DateTime at) async {
    await (await SharedPreferences.getInstance()).setString(
      _lastBackupKey,
      at.toIso8601String(),
    );
    changes.value++;
  }

  /// 아침 요약 알림 시각 (시, 분). 기본 오전 9시.
  Future<(int, int)> getNotifyTime() async {
    final value = (await SharedPreferences.getInstance()).getString(
      _notifyTimeKey,
    );
    final parts = value?.split(':');
    if (parts == null || parts.length != 2) return (9, 0);
    return (int.tryParse(parts[0]) ?? 9, int.tryParse(parts[1]) ?? 0);
  }

  Future<void> setNotifyTime(int hour, int minute) async {
    await (await SharedPreferences.getInstance()).setString(
      _notifyTimeKey,
      '$hour:$minute',
    );
    changes.value++;
  }

  // ───────── 화면용 묶음 조회 ─────────

  /// 모든 환자 + 예약 기록 + 복약 알림 + 마지막 연락일을 한 번에 계산합니다.
  Future<List<CustomerOverview>> getOverviews() async {
    final data = await _data();
    final customers = await getAllCustomers();

    final apptsByCustomer = <int, List<Appointment>>{};
    for (final row in data['appointments']!) {
      final a = Appointment.fromMap(row);
      apptsByCustomer.putIfAbsent(a.customerId, () => []).add(a);
    }
    final herbByCustomer = <int, List<HerbAlert>>{};
    for (final row in data['herb_alerts']!) {
      final a = HerbAlert.fromMap(row);
      herbByCustomer.putIfAbsent(a.customerId, () => []).add(a);
    }
    final lastContact = <int, DateTime>{};
    for (final row in data['contact_logs']!) {
      final id = row['customerId'] as int;
      final at = DateTime.parse(row['contactedAt'] as String);
      final prev = lastContact[id];
      if (prev == null || at.isAfter(prev)) lastContact[id] = at;
    }

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
