import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'screens/splash_screen.dart';
import 'services/app_navigation.dart';
import 'services/customer_database.dart';
import 'services/revisit_notifier.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 달력의 요일·월 이름을 한국어로
  await initializeDateFormatting('ko_KR');

  // 데이터가 바뀔 때마다 재방문 알림을 다시 예약
  final notifier = RevisitNotifier.instance;
  await notifier.init();
  CustomerDatabase.instance.changes.addListener(notifier.sync);
  notifier.sync();

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
