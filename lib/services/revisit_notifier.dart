import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'customer_database.dart';

/// 재방문 알림.
///
/// 고객마다 '연락해야 하는 날 오전 9시'에 휴대폰 알림을 예약해 둡니다.
/// 데이터가 바뀔 때마다 [sync] 로 전부 다시 계산해서 걸기 때문에,
/// 재예약이 잡히면 그 고객의 알림은 자연스럽게 사라집니다.
class RevisitNotifier {
  RevisitNotifier._internal();

  static final RevisitNotifier instance = RevisitNotifier._internal();

  static const _notifyHour = 9;

  /// 복약 알림 id 는 고객 id(재방문 알림)와 겹치지 않게 이 값을 더해 씁니다.
  static const _herbIdBase = 1000000;

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;
  bool _syncing = false;
  bool _syncAgain = false;

  Future<void> init() async {
    // 지금은 안드로이드 한 기기에서만 사용합니다.
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      tz_data.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Asia/Seoul'));
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
      );
      _ready = true;
    } catch (e) {
      debugPrint('알림 초기화 실패: $e');
    }
  }

  /// 안드로이드 13+ 알림 권한 요청. 화면이 뜬 뒤에 호출합니다.
  Future<void> requestPermission() async {
    if (!_ready) return;
    try {
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    } catch (e) {
      debugPrint('알림 권한 요청 실패: $e');
    }
  }

  /// 모든 고객의 재방문 알림을 다시 계산해서 예약합니다.
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
    final now = tz.TZDateTime.now(tz.local);
    final overviews = await CustomerDatabase.instance.getOverviews();

    tz.TZDateTime at(DateTime d) =>
        tz.TZDateTime(tz.local, d.year, d.month, d.day, _notifyHour);

    for (final o in overviews) {
      // 한약 복약 확인: 재예약과 상관없이 정해둔 날마다 무조건 알림
      if (o.customer.isHerbal) {
        for (final alert in o.pendingHerbAlerts) {
          final when = at(alert.date);
          final alertId = alert.id;
          if (alertId == null || !when.isAfter(now)) continue;
          await _plugin.zonedSchedule(
            id: _herbIdBase + alertId,
            scheduledDate: when,
            title: '🌿 ${o.herbLabel(alert)} 복약 확인',
            body: '${o.customer.name} 고객에게 복약 확인 전화를 해주세요.',
            notificationDetails: const NotificationDetails(
              android: AndroidNotificationDetails(
                'herb',
                '한약 복약 알림',
                channelDescription: '한약 복약 시작 후 정해둔 날의 확인 전화 알림',
                importance: Importance.high,
                priority: Priority.high,
              ),
            ),
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          );
        }
      }

      final due = o.contactDueDate;
      final id = o.customer.id;
      if (due == null || id == null) continue;

      final when = at(due);
      // 이미 지난 건은 앱 안 '연락 필요' 탭에서 보여줍니다.
      if (!when.isAfter(now)) continue;

      await _plugin.zonedSchedule(
        id: id,
        scheduledDate: when,
        title: '재방문 연락 필요',
        body: '${o.customer.name} 고객이 마지막 방문 후 2주가 지났어요. 연락해보세요.',
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'revisit',
            '재방문 알림',
            channelDescription: '마지막 방문 후 2주 동안 재예약이 없는 고객 알림',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }
}
