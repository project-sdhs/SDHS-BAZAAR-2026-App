import 'package:bazaar_app/core/router/routes.dart';
import 'package:bazaar_app/data/api/api_client.dart';
import 'package:bazaar_app/data/models/my_credit.dart';
import 'package:bazaar_app/data/models/my_user.dart';
import 'package:bazaar_app/data/repositories/my_repository.dart';
import 'package:bazaar_app/ui/pages/my/my_page.dart';
import 'package:bazaar_app/ui/pages/my/widgets/my_account_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class ConflictRepository extends MockMyRepository {
  int deletes = 0;
  @override
  Future<int> deleteAccount() async {
    deletes++;
    throw const ApiException(
      statusCode: 409,
      code: 'PENDING_CHARGE',
      message: 'Conflict',
    );
  }
}

void main() {
  testWidgets('visitor page omits restricted menus and notifications', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MyPage(
          repository: MockMyRepository(
            user: mockVisitor,
            credit: const MyCredit({
              'balance': 900,
              'used': 100,
              'pendingChargeAmount': 0,
            }),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('카카오로 로그인 · 입금 코드 V3071'), findsOneWidget);
    expect(find.text('반 인원 확인'), findsNothing);
    expect(find.text('부스 운영'), findsNothing);
    expect(find.text('주문 알림 받기'), findsNothing);
    expect(find.textContaining('900', findRichText: true), findsWidgets);
  });

  testWidgets(
    'server conflict after confirmation keeps account session active',
    (tester) async {
      final repository = ConflictRepository();
      var logouts = 0;
      final router = GoRouter(
        initialLocation: Routes.my,
        routes: [
          GoRoute(
            path: Routes.my,
            builder: (context, state) => Scaffold(
              body: MyAccountActions(
                repository: repository,
                onLogout: () async {
                  logouts++;
                },
              ),
            ),
          ),
          GoRoute(
            path: Routes.login,
            builder: (context, state) => const Text('LOGIN'),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.tap(find.text('계정 삭제'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('계정 삭제').last);
      await tester.pumpAndSettle();
      expect(repository.deletes, 1);
      expect(logouts, 0);
      expect(find.text('처리 중인 충전이 있어 계정을 삭제할 수 없어요.'), findsOneWidget);
      expect(find.text('LOGIN'), findsNothing);
    },
  );
}
