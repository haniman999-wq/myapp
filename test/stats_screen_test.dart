import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:idea_vault/models/appointment.dart';
import 'package:idea_vault/models/customer.dart';
import 'package:idea_vault/models/customer_overview.dart';
import 'package:idea_vault/models/department.dart';
import 'package:idea_vault/models/herb_alert.dart';
import 'package:idea_vault/screens/stats_screen.dart';
import 'package:idea_vault/utils/date_format.dart';

void main() {
  final depts = [
    for (var i = 1; i <= 5; i++) Department(id: i, name: '$i과', sort: i),
  ];
  var aid = 1;
  final overviews = [
    for (var p = 1; p <= 30; p++)
      CustomerOverview(
        customer: Customer(
          id: p,
          name: '환자$p',
          phone: '010',
          gender: p.isEven ? '여' : '남',
          herbStart: p % 4 == 0
              ? today().subtract(const Duration(days: 10))
              : null,
          herbType: p % 8 == 0 ? HerbType.insured : HerbType.nonInsured,
          createdAt: today().subtract(Duration(days: p * 3)),
        ),
        appointments: [
          for (var k = 0; k < (p % 6) + 1; k++)
            Appointment(
              id: aid++,
              customerId: p,
              date: today().subtract(Duration(days: p * 3 - k * 4)),
              status: k == 2 && p % 5 == 0
                  ? AppointmentStatus.noShow
                  : AppointmentStatus.visited,
              minuteOfDay: (9 + (p + k) % 8) * 60,
              deptId: (p % 5) + 1,
            ),
        ],
      ),
  ];

  for (final size in [const Size(400, 900), const Size(1100, 760)]) {
    testWidgets('통계 화면이 ${size.width.toInt()}px 폭에서 깨지지 않는다', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(home: StatsScreen(preview: (overviews, depts))),
      );
      await tester.pumpAndSettle();
      expect(find.text('전체 요약'), findsOneWidget);
      expect(find.text('진료과별 비교'), findsOneWidget);
      // 아래까지 스크롤하면서 넘침(overflow) 오류가 없는지
      for (var i = 0; i < 12; i++) {
        await tester.drag(find.byType(ListView), const Offset(0, -500));
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(), isNull);
      expect(find.text('지금 상태'), findsOneWidget);
    });
  }
}
