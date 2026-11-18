import 'package:bazaar_app/data/models/my_credit.dart';
import 'package:bazaar_app/data/repositories/my_repository.dart';
import 'package:bazaar_app/ui/pages/my/widgets/my_account_actions.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class RecordingRepository extends MockMyRepository {
  RecordingRepository({required super.credit});
  int deletes = 0;
  @override
  Future<int> deleteAccount() async {
    deletes++;
    return super.deleteAccount();
  }
}

void main() {
  testWidgets('pending charge blocks deletion before confirmation', (
    tester,
  ) async {
    final repository = RecordingRepository(
      credit: const MyCredit({
        'balance': 500,
        'used': 0,
        'pendingChargeAmount': 1000,
      }),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MyAccountActions(repository: repository, onLogout: () async {}),
        ),
      ),
    );
    await tester.tap(find.text('계정 삭제'));
    await tester.pumpAndSettle();
    expect(find.text('처리 중인 충전이 있어 계정을 삭제할 수 없어요.'), findsOneWidget);
    expect(repository.deletes, 0);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets(
    'deletion confirmation explains forfeited balance and cancellation is safe',
    (tester) async {
      final repository = RecordingRepository(
        credit: const MyCredit({
          'balance': 1500,
          'used': 0,
          'pendingChargeAmount': 0,
        }),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MyAccountActions(
              repository: repository,
              onLogout: () async {},
            ),
          ),
        ),
      );
      await tester.tap(find.text('계정 삭제'));
      await tester.pumpAndSettle();
      expect(find.textContaining('1,500 크레딧이 소멸'), findsOneWidget);
      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();
      expect(repository.deletes, 0);
    },
  );
}
