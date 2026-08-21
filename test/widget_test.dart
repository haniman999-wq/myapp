import 'package:flutter_test/flutter_test.dart';

import 'package:idea_vault/main.dart';

void main() {
  testWidgets('스플래시 화면에 앱 이름이 표시된다', (WidgetTester tester) async {
    await tester.pumpWidget(const MyCustomersApp());

    expect(find.text('내 고객의\n모든 것'), findsOneWidget);
  });
}
