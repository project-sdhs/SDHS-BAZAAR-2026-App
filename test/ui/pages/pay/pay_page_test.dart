import 'dart:async';

import 'package:bazaar_app/app.dart';
import 'package:bazaar_app/core/router/routes.dart';
import 'package:bazaar_app/data/models/payment_models.dart';
import 'package:bazaar_app/data/repositories/payment_repository.dart';
import 'package:bazaar_app/state/credit_store.dart';
import 'package:bazaar_app/ui/components/buttons/buttons.dart';
import 'package:bazaar_app/ui/components/credit_amount/credit_amounts.dart';
import 'package:bazaar_app/ui/pages/pay/checkout_page.dart';
import 'package:bazaar_app/ui/pages/pay/pay_page.dart';
import 'package:bazaar_app/ui/pages/transactions/transactions_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void _setPhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _selectTwoMenus(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('previewQr')));
  await tester.pumpAndSettle();
  await tester.tap(find.byTooltip('타코야끼 8알 수량 늘리기'));
  await tester.tap(find.byTooltip('타코야끼 4알 수량 늘리기'));
  await tester.pump();
}

void main() {
  testWidgets('QR에서 메뉴를 골라 결제가 끝나면 영수증과 거래 내역을 연다', (tester) async {
    _setPhoneViewport(tester);
    final store = CreditStore.preview();
    addTearDown(store.dispose);
    final originalPurchases = store.transactions
        .where((entry) => entry.type == TransactionType.purchase)
        .length;
    await tester.pumpWidget(
      BazaarApp(initialLocation: Routes.pay, creditStore: store),
    );
    await tester.pumpAndSettle();
    await _selectTwoMenus(tester);

    expect(find.text('4,800 결제하기'), findsOneWidget);
    await tester.tap(find.byKey(const Key('submitPayment')));
    await tester.pump();

    expect(find.text('결제하고 있어요'), findsOneWidget);
    expect(find.byKey(const Key('paymentNumber')), findsNothing);
    expect(store.balance, 12400);
    await tester.pump(const Duration(milliseconds: 899));
    expect(store.balance, 12400);
    expect(find.byKey(const Key('paymentNumber')), findsNothing);

    await tester.pump(const Duration(milliseconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('결제가 끝났어요'), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('paymentNumber'))).data,
      '31',
    );
    expect(store.balance, 7600);
    expect(
      store.transactions
          .where((entry) => entry.type == TransactionType.purchase)
          .length,
      originalPurchases + 1,
    );
    expect(store.transactions.first.amount, -4800);

    await tester.tap(find.text('거래 내역'));
    await tester.pumpAndSettle();
    expect(find.byType(TransactionsPage), findsOneWidget);
    expect(store.balance, 7600);
    expect(tester.takeException(), isNull);
  });

  testWidgets('크레딧이 부족하면 차감 없이 충전 안내를 보여 준다', (tester) async {
    _setPhoneViewport(tester);
    final store = CreditStore(
      repository: PreviewPaymentRepository(balance: 3600),
    );
    addTearDown(store.dispose);
    final transactionCount = store.transactions.length;
    await tester.pumpWidget(
      BazaarApp(initialLocation: Routes.pay, creditStore: store),
    );
    await tester.pumpAndSettle();
    await _selectTwoMenus(tester);
    await tester.tap(find.byKey(const Key('submitPayment')));
    await tester.pumpAndSettle();

    expect(find.text('크레딧이 부족해요'), findsOneWidget);
    expect(find.text('크레딧은 빠져나가지 않았어요'), findsOneWidget);
    expect(find.text('충전하러 가기'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) => widget is AppCreditAmount && widget.amount == 1200,
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key('paymentNumber')), findsNothing);
    expect(store.balance, 3600);
    expect(store.transactions.length, transactionCount);
    expect(tester.takeException(), isNull);
  });

  testWidgets('주문을 받지 않는 부스는 결제 버튼을 비활성화한다', (tester) async {
    _setPhoneViewport(tester);
    final store = CreditStore.preview();
    addTearDown(store.dispose);
    final booth = await store.resolveQr('K7Q2M9X4TB');
    final closedBooth = PaymentBooth(
      code: booth.code,
      name: booth.name,
      location: booth.location,
      menus: booth.menus,
      isOpen: false,
    );
    await tester.pumpWidget(
      BazaarApp(initialLocation: Routes.pay, creditStore: store),
    );
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(PayPage));
    unawaited(GoRouter.of(context).push(Routes.checkout, extra: closedBooth));
    await tester.pumpAndSettle();

    expect(
      find.text('지금은 주문을 받지 않는 부스예요. 운영 중일 때 다시 방문해 주세요.'),
      findsOneWidget,
    );
    expect(
      tester.widget<AppButton>(find.byKey(const Key('submitPayment'))).enabled,
      isFalse,
    );
    expect(store.balance, 12400);
    expect(find.byKey(const Key('paymentNumber')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('부스 정보 없이 결제 주소를 열면 QR 화면으로 돌아간다', (tester) async {
    _setPhoneViewport(tester);
    await tester.pumpWidget(const BazaarApp(initialLocation: Routes.checkout));
    await tester.pumpAndSettle();

    expect(find.byType(PayPage), findsOneWidget);
    expect(find.byType(CheckoutPage), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
