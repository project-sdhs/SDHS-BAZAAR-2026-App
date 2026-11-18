import 'package:bazaar_app/data/models/my_user.dart';
import 'package:bazaar_app/ui/pages/my/widgets/my_menus.dart';
import 'package:bazaar_app/ui/pages/my/widgets/my_profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('visitor sees provider and deposit code', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: MyProfile(user: mockVisitor)),
      ),
    );
    expect(find.text('카카오로 로그인 · 입금 코드 V3071'), findsOneWidget);
    expect(find.text('방문객'), findsWidgets);
  });

  for (final role in [
    'student',
    'teacher',
    'class_leader',
    'cashier',
    'visitor',
  ]) {
    for (final hasBooth in [false, true]) {
      testWidgets('menu visibility for $role with booth $hasBooth', (
        tester,
      ) async {
        final user = MyUser({
          ...mockStudent.json,
          'role': role,
          'accountType': role == 'visitor' ? 'visitor' : 'student',
          'operatingBooths': hasBooth
              ? [
                  {'id': '1', 'name': '테스트 부스'},
                ]
              : [],
        });
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: MyMenus(user: user)),
          ),
        );
        expect(
          find.text('반 인원 확인'),
          role == 'teacher' || role == 'class_leader'
              ? findsOneWidget
              : findsNothing,
        );
        expect(
          find.text('부스 운영'),
          hasBooth && (role == 'class_leader' || role == 'cashier')
              ? findsOneWidget
              : findsNothing,
        );
        if (user.canOperate) expect(find.text('테스트 부스'), findsOneWidget);
      });
    }
  }
}
