import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:idea_vault/main.dart';

void main() {
  testWidgets('홈 화면 타이틀이 표시된다', (WidgetTester tester) async {
    await tester.pumpWidget(const IdeaVaultApp());

    expect(find.text('아이디어 저장소'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
  });
}
