import 'package:flutter/material.dart';

/// 앱 전체 화면 이동을 화면 밖(알림 등)에서 할 때 쓰는 열쇠.
final appNavigatorKey = GlobalKey<NavigatorState>();

/// 아래 탭 번호.
abstract final class AppTab {
  static const calendar = 0;
  static const patients = 1;
  static const contact = 2;
  static const search = 3;
  static const settings = 4;
}

/// 열어 달라고 요청된 탭. [MainScreen] 이 듣고 처리한 뒤 null 로 돌려놓습니다.
final ValueNotifier<int?> tabRequest = ValueNotifier(null);

/// 알림을 눌렀을 때: 열려 있는 화면을 모두 닫고 '연락' 탭으로 갑니다.
void openContactTab() {
  appNavigatorKey.currentState?.popUntil((route) => route.isFirst);
  tabRequest.value = AppTab.contact;
}
