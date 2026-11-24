import 'package:bazaar_app/core/router/routes.dart';
import 'package:bazaar_app/data/api/api_client.dart';
import 'package:bazaar_app/data/models/credit_transaction.dart';
import 'package:bazaar_app/ui/components/basic/basic.dart';
import 'package:bazaar_app/ui/components/credit_amount/credit_amount.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_payment_repository.dart';
import '../../../support/payment_app.dart';
import '../../../support/payment_fixtures.dart';

Finder _amount(int value) => find.byWidgetPredicate(
  (widget) => widget is AppCreditAmount && widget.amount == value,
);

AppCreditAmount _amountWidget(WidgetTester tester, int value) =>
    tester.widget<AppCreditAmount>(_amount(value));

CreditTransaction _charge(
  int id, {
  TransactionStatus status = TransactionStatus.approved,
  int amount = 10000,
  DateTime? at,
}) => fixtureTransaction(
  'charge-$id',
  type: TransactionType.charge,
  status: status,
  amount: amount,
  title: '크레딧 충전 $id',
  subtitle: '입금자명 2205 이재원',
  occurredAt: at,
);

void main() {
  testWidgets('탭은 서버 필터(type)로 읽고, 요약은 summary.chargeTotal 과 /me/credit.used', (
    tester,
  ) async {
    final repository = FakePaymentRepository(
      transactions: (type, cursor) async => switch (type) {
        TransactionFilter.charge => TransactionPage(
          items: [
            _charge(498),
            fixtureTransaction(
              'adjustment-12',
              type: TransactionType.adjustment,
              amount: -5000,
              title: '크레딧 조정',
              subtitle: '같은 입금으로 두 번 승인된 충전 정정',
            ),
          ],
          summary: const TransactionSummary(chargeTotal: 30000, useTotal: 1),
        ),
        _ => TransactionPage(
          items: [
            fixtureTransaction('payment-5702'),
            fixtureTransaction(
              'refund-77',
              type: TransactionType.refund,
              amount: 2000,
              title: '1-2 츄러스',
              subtitle: '결제 취소',
            ),
          ],
        ),
      },
    );
    await pumpPaymentApp(
      tester,
      initialLocation: Routes.transactions,
      repository: repository,
    );

    expect(repository.transactionCalls.single.$1, TransactionFilter.charge);
    expect(find.text('크레딧 충전 498'), findsOneWidget);
    expect(find.text('크레딧 조정'), findsOneWidget);
    expect(_amount(30000), findsOneWidget);
    // 사용은 페이지 합계가 아니라 /me/credit.used
    expect(_amount(17600), findsOneWidget);

    await tester.tap(find.text('부스 구매'));
    await tester.pumpAndSettle();

    expect(repository.transactionCalls.last.$1, TransactionFilter.purchase);
    expect(find.text('3-1 로제떡볶이'), findsOneWidget);
    expect(find.text('1-2 츄러스'), findsOneWidget);
    expect(find.text('크레딧 충전 498'), findsNothing);

    // 다시 돌아가면 이미 받은 탭은 다시 부르지 않습니다.
    await tester.tap(find.text('크레딧 충전'));
    await tester.pumpAndSettle();
    expect(repository.transactionCalls, hasLength(2));
  });

  testWidgets('summary 가 없으면 충전 = 잔액 + 사용', (tester) async {
    await pumpPaymentApp(
      tester,
      initialLocation: Routes.transactions,
      repository: FakePaymentRepository(
        transactions: (type, cursor) async =>
            TransactionPage(items: [_charge(498)]),
      ),
    );

    expect(_amount(12400 + 17600), findsOneWidget);
  });

  testWidgets('아래로 내리면 nextCursor 로 다음 페이지를 이어 붙인다 (서버 순서 그대로)', (
    tester,
  ) async {
    final first = [
      for (var i = 0; i < 20; i++)
        _charge(
          100 - i,
          at: DateTime.utc(2026, 10, 23, 5).subtract(Duration(minutes: i)),
        ),
    ];
    final second = [
      for (var i = 0; i < 5; i++)
        _charge(
          50 - i,
          at: DateTime.utc(2026, 10, 23, 1).subtract(Duration(minutes: i)),
        ),
    ];
    final repository = FakePaymentRepository(
      transactions: (type, cursor) async => cursor == null
          ? TransactionPage(items: first, nextCursor: 'cursor-2')
          : TransactionPage(items: second),
    );
    await pumpPaymentApp(
      tester,
      initialLocation: Routes.transactions,
      repository: repository,
    );
    expect(repository.transactionCalls, hasLength(1));
    expect(repository.transactionCalls.single.$2, isNull);

    await tester.scrollUntilVisible(
      find.text('크레딧 충전 46'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(repository.transactionCalls, hasLength(2));
    expect(repository.transactionCalls[1].$1, TransactionFilter.charge);
    expect(repository.transactionCalls[1].$2, 'cursor-2');
    expect(repository.transactionCalls[1].$3, 20);

    // 마지막 페이지(nextCursor = null) 뒤에는 더 부르지 않습니다.
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -2000));
    await tester.pumpAndSettle();
    expect(repository.transactionCalls, hasLength(2));
  });

  testWidgets('날짜는 서울 기준으로 묶는다 (UTC 15:10 → 다음 날)', (tester) async {
    await pumpPaymentApp(
      tester,
      initialLocation: Routes.transactions,
      repository: FakePaymentRepository(
        transactions: (type, cursor) async => TransactionPage(
          items: [
            _charge(2, at: DateTime.utc(2026, 10, 23, 15, 10)),
            _charge(1, at: DateTime.utc(2026, 10, 23, 14, 50)),
          ],
        ),
      ),
    );

    expect(find.text('10월 24일 토요일'), findsOneWidget);
    expect(find.text('10월 23일 금요일'), findsOneWidget);
    expect(find.text('00:10 · 승인'), findsOneWidget);
    expect(find.text('23:50 · 승인'), findsOneWidget);
    final saturday = tester.getTopLeft(find.text('10월 24일 토요일')).dy;
    final friday = tester.getTopLeft(find.text('10월 23일 금요일')).dy;
    expect(saturday, lessThan(friday));
  });

  testWidgets('색은 부호가 아니라 상태로 정한다', (tester) async {
    await pumpPaymentApp(
      tester,
      initialLocation: Routes.transactions,
      repository: FakePaymentRepository(
        transactions: (type, cursor) async => switch (type) {
          TransactionFilter.charge => TransactionPage(
            items: [
              _charge(1, amount: 10000),
              _charge(2, amount: 20000, status: TransactionStatus.pending),
              _charge(3, amount: 15000, status: TransactionStatus.rejected),
            ],
          ),
          _ => TransactionPage(
            items: [
              fixtureTransaction('payment-1', amount: -3500),
              fixtureTransaction(
                'payment-2',
                amount: -2000,
                status: TransactionStatus.refunded,
                subtitle: '츄러스',
              ),
              fixtureTransaction(
                'refund-3',
                type: TransactionType.refund,
                amount: 2000,
                subtitle: '결제 취소',
              ),
            ],
          ),
        },
      ),
    );

    expect(_amountWidget(tester, 10000).tone, CreditAmountTone.charge);
    expect(_amountWidget(tester, 20000).tone, CreditAmountTone.muted);
    expect(_amountWidget(tester, 15000).tone, CreditAmountTone.muted);
    final tiles = tester
        .widgetList<AppCategoryTile>(find.byType(AppCategoryTile))
        .map((tile) => tile.highlighted)
        .toList();
    expect(tiles, [true, false, false]);
    expect(find.text('11:41 · 입금 확인 중'), findsOneWidget);

    await tester.tap(find.text('부스 구매'));
    await tester.pumpAndSettle();

    expect(_amountWidget(tester, -3500).tone, CreditAmountTone.normal);
    expect(_amountWidget(tester, -2000).tone, CreditAmountTone.muted);
    expect(_amountWidget(tester, 2000).tone, CreditAmountTone.charge);
    expect(find.text('11:41 · 츄러스 · 환불됨'), findsOneWidget);
  });

  testWidgets('불러오는 동안 자리 표시, 실패하면 다시 시도', (tester) async {
    var fail = true;
    final repository = FakePaymentRepository(
      transactions: (type, cursor) async {
        if (fail) throw const ApiNetworkException();
        return TransactionPage(items: [_charge(498)]);
      },
    );
    await pumpPaymentApp(
      tester,
      initialLocation: Routes.transactions,
      repository: repository,
      settle: false,
    );
    expect(find.byType(AppSkeletonList), findsOneWidget);
    await tester.pumpAndSettle();

    expect(find.text('거래 내역을 불러오지 못했어요'), findsOneWidget);
    fail = false;
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();
    expect(find.text('크레딧 충전 498'), findsOneWidget);
  });

  testWidgets('당겨서 새로고침하면 이 탭을 처음부터 다시 받고 잔액도 다시 읽는다', (tester) async {
    final repository = FakePaymentRepository(
      transactions: (type, cursor) async =>
          TransactionPage(items: [_charge(498)], nextCursor: null),
    );
    await pumpPaymentApp(
      tester,
      initialLocation: Routes.transactions,
      repository: repository,
    );
    final creditCalls = repository.creditCalls;

    await tester.fling(find.text('크레딧 충전 498'), const Offset(0, 400), 1000);
    await tester.pumpAndSettle();

    expect(repository.transactionCalls, hasLength(2));
    expect(repository.transactionCalls.last.$2, isNull);
    expect(repository.creditCalls, greaterThan(creditCalls));
    expect(find.text('크레딧 충전 498'), findsOneWidget);
  });

  testWidgets('내역이 없으면 탭별 빈 상태', (tester) async {
    await pumpPaymentApp(tester, initialLocation: Routes.transactions);
    expect(find.text('아직 충전 내역이 없어요'), findsOneWidget);

    await tester.tap(find.text('부스 구매'));
    await tester.pumpAndSettle();
    expect(find.text('아직 구매 내역이 없어요'), findsOneWidget);
  });

  testWidgets('320픽셀과 큰 글자에서도 넘치지 않는다', (tester) async {
    await pumpPaymentApp(
      tester,
      initialLocation: Routes.transactions,
      size: const Size(320, 844),
      textScale: 1.5,
      repository: FakePaymentRepository(
        transactions: (type, cursor) async => TransactionPage(
          items: [
            fixtureTransaction('payment-5702', amount: -123456),
            _charge(498, amount: 1000000),
          ],
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
