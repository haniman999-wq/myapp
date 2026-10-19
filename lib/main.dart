import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/splash_screen.dart';
import 'services/app_navigation.dart';
import 'services/customer_database.dart';
import 'services/revisit_notifier.dart';
import 'services/supabase_config.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 인터넷이 없어 저장 못 한 경우는 화면 아래에 이미 알렸으니 조용히 넘깁니다.
  PlatformDispatcher.instance.onError = (error, stack) =>
      error is OfflineException;
  // 달력의 요일·월 이름을 한국어로
  await initializeDateFormatting('ko_KR');

  // 공유 서버 연결 (로그인 상태는 기기에 저장돼 앱을 다시 켜도 유지)
  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.publishableKey,
  );
  final db = CustomerDatabase.instance;
  if (Supabase.instance.client.auth.currentSession != null) db.startRealtime();

  // 데이터가 바뀔 때마다 재방문 알림을 다시 예약
  final notifier = RevisitNotifier.instance;
  await notifier.init();
  db.changes.addListener(notifier.sync);
  if (Supabase.instance.client.auth.currentSession != null) notifier.sync();

  runApp(const MyCustomersApp());

  // 권한 팝업은 첫 화면이 그려진 뒤에 띄웁니다.
  notifier.requestPermission();
}

class MyCustomersApp extends StatelessWidget {
  const MyCustomersApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: appNavigatorKey,
      scaffoldMessengerKey: CustomerDatabase.instance.messengerKey,
      title: '내 환자의 모든 것',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: kPrimaryGreen),
        useMaterial3: true,
      ),
      // 날짜 선택기 등 기본 위젯을 한국어로
      locale: const Locale('ko', 'KR'),
      supportedLocales: const [Locale('ko', 'KR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: const SplashScreen(),
    );
  }
}
