import 'package:bazaar_app/app.dart';
import 'package:bazaar_app/core/router/routes.dart';
import 'package:bazaar_app/data/models/payment_models.dart';
import 'package:bazaar_app/data/repositories/payment_repository.dart';
import 'package:bazaar_app/state/credit_store.dart';
import 'package:bazaar_app/ui/components/credit_amount/credit_amount.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _HistoryRepository extends PreviewPaymentRepository {
  _HistoryRepository(this.history);

  final List<CreditTransaction> history;

  @override
  List<CreditTransaction> get transactions => history;
}

CreditTransaction _transaction(String id, TransactionType type, int amount) =>
    CreditTransaction(
      id: id,
      type: type,
      title: id,
      subtitle: '내역 설명',
      occurredAt: DateTime.parse('2026-10-24T09:12:00+09:00'),
      status: 'completed',
      amount: amount,
    );

Finder _amount(int value) => find.byWidgetPredicate(
  (widget) => widget is AppCreditAmount && widget.amount == value,
);

void main() {
  testWidgets('충전과 구매 탭은 조정과 환불을 구분하고 요약 금액을 유지한다', (tester) async {
    final store = CreditStore(
      repository: _HistoryRepository([
        _transaction('입금 충전', TransactionType.charge, 10000),
        _transaction('크레딧 정정', TransactionType.adjustment, -1000),
        _transaction('부스 결제', TransactionType.purchase, -3000),
        _transaction('결제 환불', TransactionType.refund, 3000),
      ]),
    );
    addTearDown(store.dispose);
    await tester.pumpWidget(
      BazaarApp(initialLocation: Routes.transactions, creditStore: store),
    );
    await tester.pumpAndSettle();

    expect(find.text('입금 충전'), findsOneWidget);
    expect(find.text('크레딧 정정'), findsOneWidget);
    expect(find.text('부스 결제'), findsNothing);
    expect(find.text('10월 24일 토요일'), findsOneWidget);
    expect(_amount(30000), findsOneWidget);
    expect(_amount(17600), findsOneWidget);

    await tester.tap(find.text('부스 구매'));
    await tester.pumpAndSettle();

    expect(find.text('부스 결제'), findsOneWidget);
    expect(find.text('결제 환불'), findsOneWidget);
    expect(find.text('입금 충전'), findsNothing);
    expect(find.text('크레딧 정정'), findsNothing);
    expect(_amount(30000), findsOneWidget);
    expect(_amount(17600), findsOneWidget);
  });

  testWidgets('320픽셀과 큰 글자에서도 금액과 내역이 넘치지 않는다', (tester) async {
    tester.view.physicalSize = const Size(320, 844);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      const BazaarApp(initialLocation: Routes.transactions),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    await tester.tap(find.text('부스 구매'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(_amount(-4500), findsOneWidget);
  });

  testWidgets('내역이 없으면 선택한 탭의 빈 상태를 표시한다', (tester) async {
    final store = CreditStore(repository: _HistoryRepository([]));
    addTearDown(store.dispose);
    await tester.pumpWidget(
      BazaarApp(initialLocation: Routes.transactions, creditStore: store),
    );
    await tester.pumpAndSettle();
    expect(find.text('아직 충전 내역이 없어요'), findsOneWidget);

    await tester.tap(find.text('부스 구매'));
    await tester.pumpAndSettle();
    expect(find.text('아직 구매 내역이 없어요'), findsOneWidget);
  });

  testWidgets('내역을 아래로 넘기면 다음 묶음을 이어서 표시한다', (tester) async {
    final history = List.generate(
      25,
      (index) => CreditTransaction(
        id: 'charge-$index',
        type: TransactionType.charge,
        title: '충전 요청 $index',
        subtitle: '승인',
        occurredAt: DateTime.parse('2026-10-24T09:12:00+09:00')
            .subtract(Duration(minutes: index)),
        status: 'approved',
        amount: 1000,
      ),
    );
    final store = CreditStore(repository: _HistoryRepository(history));
    addTearDown(store.dispose);
    await tester.pumpWidget(
      BazaarApp(initialLocation: Routes.transactions, creditStore: store),
    );
    await tester.pumpAndSettle();
    expect(find.text('충전 요청 24'), findsNothing);

    await tester.scrollUntilVisible(
      find.text('충전 요청 24'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('충전 요청 24'), findsOneWidget);
  });
}
