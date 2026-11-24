import 'package:bazaar_app/core/router/routes.dart';
import 'package:bazaar_app/data/api/api_client.dart';
import 'package:bazaar_app/data/models/payment_exception.dart';
import 'package:bazaar_app/ui/components/buttons/buttons.dart';
import 'package:bazaar_app/ui/components/credit_amount/credit_amounts.dart';
import 'package:bazaar_app/ui/pages/booth_detail/booth_detail_page.dart';
import 'package:bazaar_app/ui/pages/home/home_page.dart';
import 'package:bazaar_app/ui/pages/pay/booth_paused_page.dart';
import 'package:bazaar_app/ui/pages/pay/checkout_page.dart';
import 'package:bazaar_app/ui/pages/pay/pay_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_payment_repository.dart';
import '../../../support/payment_app.dart';
import '../../../support/payment_fixtures.dart';

/// 카메라 대신 쓰는 스캐너. [_detect] 로 QR 값을 넣습니다.
ValueChanged<String>? _detect;
const _scannerKey = Key('fakeScanner');

Finder _amount(int value) => find.byWidgetPredicate(
  (widget) => widget is AppCreditAmount && widget.amount == value,
);

Future<void> _turnOnCamera(WidgetTester tester) async {
  await tester.tap(find.text('카메라 켜기'));
  await tester.pump();
  expect(find.byKey(_scannerKey), findsOneWidget);
}

Future<void> _scan(WidgetTester tester, [String raw = sampleQrCode]) async {
  _detect!(raw);
  await tester.pumpAndSettle();
}

Future<void> _selectTwoMenus(WidgetTester tester) async {
  await tester.tap(find.byTooltip('타코야끼 8알 수량 늘리기'));
  await tester.tap(find.byTooltip('타코야끼 4알 수량 늘리기'));
  await tester.pump();
}

Future<void> _openCheckout(WidgetTester tester) async {
  await _turnOnCamera(tester);
  await _scan(tester, 'https://bazaar.example.com/q/$sampleQrCode?src=board');
  expect(find.byType(CheckoutPage), findsOneWidget);
}

Future<void> _submit(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('submitPayment')));
  await tester.pump();
}

void main() {
  setUp(() {
    PayPage.debugScannerOverride = (context, onDetect) {
      _detect = onDetect;
      return const ColoredBox(key: _scannerKey, color: Colors.black);
    };
  });
  tearDown(() {
    PayPage.debugScannerOverride = null;
    _detect = null;
  });

  testWidgets('QR 을 읽어 메뉴를 고르고 결제하면 영수증, 확인은 홈으로', (tester) async {
    final repository = FakePaymentRepository();
    final store = await pumpPaymentApp(
      tester,
      initialLocation: Routes.pay,
      repository: repository,
    );
    await _openCheckout(tester);
    expect(repository.qrCalls.single.$1, sampleQrCode);
    expect(repository.qrCalls.single.$2.name, 'board');
    await _selectTwoMenus(tester);

    expect(find.text('4,800 결제하기'), findsOneWidget);
    await _submit(tester);
    await tester.pumpAndSettle();

    expect(find.text('결제가 끝났어요'), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('paymentNumber'))).data,
      '31',
    );
    expect(store.balance, 7600);
    final request = repository.payRequests.single;
    expect(request.clientTotal, 4800);
    expect(request.items.map((item) => (item.menuId, item.quantity)), [
      (301, 1),
      (302, 1),
    ]);

    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(find.byType(HomePage), findsOneWidget);
    expect(find.byType(CheckoutPage), findsNothing);
  });

  testWidgets('다시 스캔으로 돌아오면 카메라가 다시 켜진다', (tester) async {
    await pumpPaymentApp(tester, initialLocation: Routes.pay);
    await _openCheckout(tester);
    expect(find.byKey(_scannerKey), findsNothing);

    await tester.tap(find.text('다시 스캔'));
    await tester.pumpAndSettle();

    expect(find.byType(PayPage), findsOneWidget);
    expect(find.byKey(_scannerKey), findsOneWidget);
  });

  testWidgets('결과를 모르면 결제하기로 돌아가지 않고 같은 키로 결과를 다시 확인한다', (tester) async {
    var online = false;
    final repository = FakePaymentRepository(
      pay: (request, key) async {
        if (!online) throw const ApiTimeoutException(Duration(seconds: 15));
        return fixtureReceipt();
      },
    );
    final store = await pumpPaymentApp(
      tester,
      initialLocation: Routes.pay,
      repository: repository,
    );
    await _openCheckout(tester);
    await _selectTwoMenus(tester);
    await _submit(tester);

    // 1 · 2 · 4초 뒤 같은 키로 다시 보냅니다.
    expect(find.text('결제하고 있어요'), findsOneWidget);
    for (final seconds in [1, 2, 4]) {
      await tester.pump(Duration(seconds: seconds));
    }
    await tester.pumpAndSettle();

    expect(repository.payKeys, hasLength(4));
    expect(find.text('결제 결과를 확인하고 있어요'), findsOneWidget);
    expect(find.byKey(const Key('submitPayment')), findsNothing);
    expect(store.balance, 12400);

    online = true;
    await tester.tap(find.byKey(const Key('recheckPayment')));
    await tester.pumpAndSettle();

    expect(repository.payKeys, hasLength(5));
    expect(repository.payKeys.toSet(), hasLength(1));
    expect(find.text('결제가 끝났어요'), findsOneWidget);
    expect(store.balance, 7600);
  });

  testWidgets('IDEMPOTENCY_IN_PROGRESS 는 1초 뒤 같은 키로 다시 보낸다', (tester) async {
    var calls = 0;
    final repository = FakePaymentRepository(
      pay: (request, key) async {
        if (++calls == 1) {
          throw paymentError(PaymentErrorCode.idempotencyInProgress);
        }
        return fixtureReceipt();
      },
    );
    await pumpPaymentApp(
      tester,
      initialLocation: Routes.pay,
      repository: repository,
    );
    await _openCheckout(tester);
    await _selectTwoMenus(tester);
    await _submit(tester);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(repository.payKeys, hasLength(2));
    expect(repository.payKeys.toSet(), hasLength(1));
    expect(find.text('결제가 끝났어요'), findsOneWidget);
  });

  testWidgets('409 INSUFFICIENT_CREDIT 의 잔액 · 합계 · 부족분으로 부족 화면을 그린다', (
    tester,
  ) async {
    final repository = FakePaymentRepository(
      pay: (request, key) async => throw paymentError(
        PaymentErrorCode.insufficientCredit,
        details: {'balance': 3600, 'total': 4800, 'shortfall': 1200},
      ),
    );
    final store = await pumpPaymentApp(
      tester,
      initialLocation: Routes.pay,
      repository: repository,
    );
    await _openCheckout(tester);
    await _selectTwoMenus(tester);
    await _submit(tester);
    await tester.pumpAndSettle();

    expect(find.text('크레딧이 부족해요'), findsOneWidget);
    expect(find.text('크레딧은 빠져나가지 않았어요'), findsOneWidget);
    expect(find.text('충전하러 가기'), findsOneWidget);
    expect(_amount(1200), findsOneWidget);
    expect(_amount(3600), findsOneWidget);
    expect(find.byKey(const Key('paymentNumber')), findsNothing);
    expect(store.balance, 3600);
  });

  testWidgets('QR 정보의 잔액보다 비싸면 서버에 보내지 않고 부족 화면', (tester) async {
    final repository = FakePaymentRepository(
      qrPayInfo: (code, source) async => fixtureQrInfo(balance: 3600),
    );
    await pumpPaymentApp(
      tester,
      initialLocation: Routes.pay,
      repository: repository,
    );
    await _openCheckout(tester);
    await _selectTwoMenus(tester);
    await _submit(tester);
    await tester.pumpAndSettle();

    expect(find.text('크레딧이 부족해요'), findsOneWidget);
    expect(_amount(1200), findsOneWidget);
    expect(repository.payKeys, isEmpty);
  });

  testWidgets('MENU_CHANGED 면 QR 정보를 다시 읽고 품절 메뉴를 빼고 새 키로 결제한다', (
    tester,
  ) async {
    var changed = false;
    final repository = FakePaymentRepository(
      qrPayInfo: (code, source) async => fixtureQrInfo(
        menus: changed
            ? [
                menuJson(301, '타코야끼 8알', 3200, 1),
                menuJson(302, '타코야끼 4알', 1800, 2, onSale: false),
                menuJson(303, '치즈 타코야끼 6알', 3500, 3),
              ]
            : null,
      ),
      pay: (request, key) async {
        if (!changed) {
          changed = true;
          throw paymentError(
            PaymentErrorCode.menuChanged,
            details: {
              'serverTotal': null,
              'changedMenuIds': [301, 302],
            },
          );
        }
        return fixtureReceipt();
      },
    );
    await pumpPaymentApp(
      tester,
      initialLocation: Routes.pay,
      repository: repository,
    );
    await _openCheckout(tester);
    await _selectTwoMenus(tester);
    await _submit(tester);
    await tester.pumpAndSettle();

    expect(repository.qrCalls, hasLength(2));
    expect(
      find.text('주문할 수 없게 된 메뉴를 뺐어요: 타코야끼 4알. 금액을 확인하고 다시 결제해 주세요'),
      findsOneWidget,
    );
    // 남은 메뉴는 수량을 그대로 두고 새 가격으로 계산합니다.
    expect(find.text('3,200 결제하기'), findsOneWidget);

    await _submit(tester);
    await tester.pumpAndSettle();

    expect(repository.payKeys, hasLength(2));
    expect(repository.payKeys.toSet(), hasLength(2));
    final retried = repository.payRequests.last;
    expect(retried.clientTotal, 3200);
    expect(retried.items.map((item) => (item.menuId, item.quantity)), [
      (301, 1),
    ]);
    expect(find.text('결제가 끝났어요'), findsOneWidget);
  });

  testWidgets('QR 을 읽을 때 ORDERING_PAUSED 면 주문 멈춤 안내 (서울 시각)', (tester) async {
    final repository = FakePaymentRepository(
      qrPayInfo: (code, source) async => throw paymentError(
        PaymentErrorCode.orderingPaused,
        message: '지금은 주문을 받지 않아요',
        details: {
          'pausedAt': '2026-10-23T03:05:00Z',
          'booth': {'id': 23, 'name': '2-3 타코야끼'},
        },
      ),
    );
    await pumpPaymentApp(
      tester,
      initialLocation: Routes.pay,
      repository: repository,
    );
    await _turnOnCamera(tester);
    await _scan(tester);

    expect(find.byType(BoothPausedPage), findsOneWidget);
    expect(find.text('2-3 타코야끼'), findsOneWidget);
    expect(find.text('12:05부터 주문을 멈췄어요'), findsOneWidget);
    expect(find.text('크레딧은 빠져나가지 않았어요'), findsNothing);
    expect(find.widgetWithText(AppButton, '부스 보기'), findsOneWidget);

    await tester.tap(find.text('다시 스캔'));
    await tester.pumpAndSettle();
    expect(find.byType(PayPage), findsOneWidget);
    expect(find.byKey(_scannerKey), findsOneWidget);
  });

  testWidgets('결제할 때 BOOTH_CLOSED 면 서버 문구로 안내하고 부스를 볼 수 있다', (tester) async {
    final repository = FakePaymentRepository(
      pay: (request, key) async => throw paymentError(
        PaymentErrorCode.boothClosed,
        message: '운영 시간(10:00~15:00)이 아니에요',
      ),
    );
    final store = await pumpPaymentApp(
      tester,
      initialLocation: Routes.pay,
      repository: repository,
    );
    await _openCheckout(tester);
    await _selectTwoMenus(tester);
    await _submit(tester);
    await tester.pumpAndSettle();

    expect(find.byType(BoothPausedPage), findsOneWidget);
    expect(find.text('2-3 타코야끼'), findsOneWidget);
    expect(find.text('운영 시간(10:00~15:00)이 아니에요'), findsOneWidget);
    expect(find.text('크레딧은 빠져나가지 않았어요'), findsOneWidget);
    expect(store.balance, 12400);

    await tester.tap(find.text('부스 보기'));
    await tester.pumpAndSettle();
    expect(find.byType(BoothDetailPage), findsOneWidget);
  });

  testWidgets('QR_INVALID · 바자회 QR 이 아닌 값은 알려 주고 계속 스캔한다', (tester) async {
    final repository = FakePaymentRepository(
      qrPayInfo: (code, source) async => throw paymentError(
        PaymentErrorCode.qrInvalid,
        statusCode: 404,
        message: '알 수 없는 QR이에요',
      ),
    );
    await pumpPaymentApp(
      tester,
      initialLocation: Routes.pay,
      repository: repository,
    );
    await _turnOnCamera(tester);

    await _scan(tester);
    expect(find.text('알 수 없는 QR이에요'), findsOneWidget);
    expect(find.byKey(_scannerKey), findsOneWidget);

    // 같은 QR 을 바로 다시 읽으면 무시합니다.
    await _scan(tester);
    expect(repository.qrCalls, hasLength(1));

    await _scan(tester, 'WIFI:S:school;T:WPA;P:secret;;');
    expect(find.text('바자회 부스 QR이 아니에요. 부스에 붙은 QR을 비춰 주세요'), findsOneWidget);
    expect(repository.qrCalls, hasLength(1));
    expect(find.byKey(_scannerKey), findsOneWidget);
  });

  testWidgets('부스 정보 없이 결제 주소를 열면 QR 화면으로 돌아간다', (tester) async {
    await pumpPaymentApp(tester, initialLocation: Routes.checkout);

    expect(find.byType(PayPage), findsOneWidget);
    expect(find.byType(CheckoutPage), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('좁은 화면 · 큰 글자에서도 결제 화면이 넘치지 않는다', (tester) async {
    await pumpPaymentApp(
      tester,
      initialLocation: Routes.pay,
      size: const Size(320, 640),
      textScale: 1.5,
    );
    await _openCheckout(tester);
    await _selectTwoMenus(tester);
    expect(tester.takeException(), isNull);
  });
}
