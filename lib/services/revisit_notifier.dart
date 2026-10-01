import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/customer_overview.dart';
import '../theme.dart';
import '../utils/date_format.dart';
import 'app_navigation.dart';
import 'customer_database.dart';

/// 아침 요약 알림.
///
/// 매일 정해둔 시각(기본 오전 9시)에 "오늘 연락할 환자 N명 (복약 확인 · 재방문)"
/// 알림을 한 번 보냅니다. 앞으로 [_daysAhead]일치를 미리 걸어두고,
/// 데이터가 바뀔 때마다 [sync] 로 전부 다시 계산합니다.
/// 알림을 누르면 앱의 '연락' 탭이 열립니다.
class RevisitNotifier {
  RevisitNotifier._internal();

  static final RevisitNotifier instance = RevisitNotifier._internal();

  /// 며칠 앞까지 요약 알림을 미리 걸어둘지.
  static const _daysAhead = 30;

  /// 요약 알림 id = 기준 + 오늘로부터 며칠째.
  static const _summaryIdBase = 2000;

  /// 알림 내용에 이름을 몇 명까지 적을지.
  static const _maxNames = 4;

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;
  bool _syncing = false;
  bool _syncAgain = false;

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  Future<void> init() async {
    // 지금은 안드로이드 한 기기에서만 사용합니다.
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      tz_data.initializeTimeZones();
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('ic_stat_notify'),
        ),
        // 앱이 켜져 있을 때 알림을 누르면
        onDidReceiveNotificationResponse: (_) => openContactTab(),
      );
      // 꺼져 있던 앱을 알림으로 열었으면 첫 화면을 '연락' 탭으로
      final launch = await _plugin.getNotificationAppLaunchDetails();
      if (launch?.didNotificationLaunchApp ?? false) {
        tabRequest.value = AppTab.contact;
      }
      _ready = true;
    } catch (e) {
      debugPrint('알림 초기화 실패: $e');
    }
  }

  /// 안드로이드 13+ 알림 권한 요청. 화면이 뜬 뒤에 호출합니다.
  Future<void> requestPermission() async {
    if (!_ready) return;
    try {
      await _android?.requestNotificationsPermission();
    } catch (e) {
      debugPrint('알림 권한 요청 실패: $e');
    }
  }

  /// 정해둔 시각에 정확히 울릴 수 있는지 (안드로이드 '알람 및 리마인더' 권한).
  Future<bool> canNotifyOnTime() async {
    if (!_ready) return true;
    try {
      return await _android?.canScheduleExactNotifications() ?? true;
    } catch (_) {
      return true;
    }
  }

  /// '알람 및 리마인더' 권한 설정 화면을 엽니다.
  Future<void> requestOnTimePermission() async {
    if (!_ready) return;
    try {
      await _android?.requestExactAlarmsPermission();
    } catch (e) {
      debugPrint('정확한 알림 권한 요청 실패: $e');
    }
    await sync();
  }

  /// 아침 요약 알림을 다시 계산해서 예약합니다.
  Future<void> sync() async {
    if (!_ready) return;
    if (_syncing) {
      _syncAgain = true;
      return;
    }
    _syncing = true;
    try {
      do {
        _syncAgain = false;
        await _scheduleAll();
      } while (_syncAgain);
    } catch (e) {
      debugPrint('알림 예약 실패: $e');
    } finally {
      _syncing = false;
    }
  }

  Future<void> _scheduleAll() async {
    await _plugin.cancelAll();
    final db = CustomerDatabase.instance;
    final overviews = await db.getOverviews();
    final (hour, minute) = await db.getNotifyTime();
    final mode = await canNotifyOnTime()
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
    final now = DateTime.now();
    final start = today();

    for (var i = 0; i <= _daysAhead; i++) {
      final day = start.add(Duration(days: i));
      // 휴대폰에 설정된 시간대 기준 시각 → 절대 시각(UTC)으로 예약
      final when = DateTime(day.year, day.month, day.day, hour, minute);
      // 오늘 알림 시각이 이미 지났으면 앱 안 '연락' 탭에서 보여줍니다.
      if (!when.isAfter(now)) continue;

      final summary = DailySummary.of(overviews, day);
      if (summary.isEmpty) continue;

      await _plugin.zonedSchedule(
        id: _summaryIdBase + i,
        scheduledDate: tz.TZDateTime.from(when, tz.UTC),
        title: summary.title,
        body: summary.body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_summary',
            '오늘의 연락 요약',
            channelDescription: '매일 아침, 오늘 연락할 환자(복약 확인·재방문)를 모아서 알려줍니다',
            importance: Importance.high,
            color: kPrimaryGreenDark,
            priority: Priority.high,
            // 잠금화면에서는 환자 이름을 가립니다.
            visibility: NotificationVisibility.private,
            styleInformation: BigTextStyleInformation(summary.body),
          ),
        ),
        androidScheduleMode: mode,
      );
    }
  }
}

/// 하루치 요약 알림 내용.
class DailySummary {
  DailySummary._(this.herbNames, this.revisitNames);

  /// [day] 아침 기준, 지금 데이터대로라면 연락해야 할 환자들.
  factory DailySummary.of(List<CustomerOverview> overviews, DateTime day) {
    // 이름 뒤에 며칠째 알림인지 붙입니다. (첫날은 이름만)
    String label(String name, int nth) => nth > 1 ? '$name($nth일째)' : name;

    final herb = <String>[];
    final revisit = <String>[];
    for (final o in overviews) {
      final h = o.herbReminderDayOn(day);
      final r = o.revisitReminderDayOn(day);
      if (h != null) {
        herb.add(label(o.customer.name, h));
      } else if (r != null) {
        // 둘 다 해당하면 복약 확인 쪽으로 한 번만 셉니다.
        revisit.add(label(o.customer.name, r));
      }
    }
    return DailySummary._(herb, revisit);
  }

  final List<String> herbNames;
  final List<String> revisitNames;

  int get total => herbNames.length + revisitNames.length;
  bool get isEmpty => total == 0;

  String get title {
    final parts = [
      if (herbNames.isNotEmpty) '복약 확인 ${herbNames.length}명',
      if (revisitNames.isNotEmpty) '재방문 ${revisitNames.length}명',
    ];
    return '오늘 연락할 환자 $total명 (${parts.join(' · ')})';
  }

  String get body {
    final names = [...herbNames.map((n) => '🌿$n'), ...revisitNames];
    final shown = names.take(RevisitNotifier._maxNames).join(', ');
    final rest = names.length - RevisitNotifier._maxNames;
    return rest > 0 ? '$shown 외 $rest명 · 눌러서 연락하기' : '$shown · 눌러서 연락하기';
  }
}
