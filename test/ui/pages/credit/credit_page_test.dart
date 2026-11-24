import 'package:bazaar_app/core/router/routes.dart';
import 'package:bazaar_app/core/theme/app_colors.dart';
import 'package:bazaar_app/data/api/api_client.dart';
import 'package:bazaar_app/data/models/charge_request.dart';
import 'package:bazaar_app/data/models/payment_exception.dart';
import 'package:bazaar_app/ui/components/buttons/buttons.dart';
import 'package:bazaar_app/ui/components/credit_amount/credit_amounts.dart';
import 'package:bazaar_app/ui/components/feedback/feedback.dart';
import 'package:bazaar_app/ui/pages/credit/credit_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_payment_repository.dart';
import '../../../support/payment_app.dart';
import '../../../support/payment_fixtures.dart';

AppButton _cta(WidgetTester tester) => tester.widget<AppButton>(
  find.descendant(of: find.byType(BottomCTA), matching: find.byType(AppButton)),
);

Finder get _field => find.byType(TextFormField);

Finder _amount(int value) => find.byWidgetPredicate(
  (widget) => widget is AppCreditAmount && widget.amount == value,
);

String _fieldText(WidgetTester tester) =>
    tester.widget<TextFormField>(_field).controller!.text;

Future<void> _tapCta(WidgetTester tester) async {
  await tester.tap(
    find.descendant(
      of: find.byType(BottomCTA),
      matching: find.byType(AppButton),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('설정을 읽는 동안 자리 표시, 실패하면 다시 시도', (tester) async {
    var fail = true;
    final repository = FakePaymentRepository(
      settings: () async {
        if (fail) throw const ApiNetworkException();
        return fixtureSettings();
      },
    );
    await pumpPaymentApp(
      tester,
      initialLocation: Routes.credit,
      repository: repository,
    );

    expect(find.text('충전 정보를 불러오지 못했어요'), findsOneWidget);
    expect(_field, findsNothing);

    fail = false;
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();
    expect(_field, findsOneWidget);
    expect(find.text('예시은행'), findsOneWidget);
    expect(find.text('000-1234-5678-90'), findsOneWidget);
  });

  testWidgets('요청 전에는 설정 규칙으로 만든 입금자명을 보여 준다 (학생: 학번 이름)', (tester) async {
    await pumpPaymentApp(tester, initialLocation: Routes.credit);
    expect(find.text('2205 이재원'), findsOneWidget);
  });

  testWidgets('금액 칩: 빈 칸은 0 으로 보고 세 칩은 같은 폭', (tester) async {
    await pumpPaymentApp(tester, initialLocation: Routes.credit);

    await tester.enterText(_field, '');
    await tester.pump();
    await tester.tap(find.text('+5,000'));
    await tester.pump();
    expect(_fieldText(tester), '5,000');

    await tester.tap(find.text('+10,000'));
    await tester.pump();
    expect(_fieldText(tester), '15,000');

    final widths = [
      for (final label in ['+5,000', '+10,000', '+30,000'])
        tester
            .getSize(
              find.ancestor(
                of: find.text(label),
                matching: find.byType(AppButton),
              ),
            )
            .width,
    ];
    expect(widths.toSet(), hasLength(1));

    for (final invalid in ['-1000', '1a000']) {
      await tester.enterText(_field, invalid);
      await tester.pump();
      expect(_cta(tester).enabled, isFalse, reason: invalid);
    }
  });

  testWidgets('최소 · 1회 최대 · 보유 한도(잔액 + 확인 중 + 이번 금액)를 확인한다', (tester) async {
    await pumpPaymentApp(
      tester,
      initialLocation: Routes.credit,
      repository: FakePaymentRepository(
        settings: () async =>
            fixtureSettings(chargeMax: 20000, balanceLimit: 30000),
        credit: () async =>
            fixtureCredit(balance: 12400, pendingChargeAmount: 5000),
      ),
    );

    // 한도 30,000 − 잔액 12,400 − 확인 중 5,000 = 12,600 까지
    for (final amount in ['999', '20001', '12601']) {
      await tester.enterText(_field, amount);
      await tester.pump();
      expect(_cta(tester).enabled, isFalse, reason: amount);
    }
    expect(find.text('보유 한도 때문에 12,600원까지 충전할 수 있어요'), findsOneWidget);

    await tester.enterText(_field, '12600');
    await tester.pump();
    expect(_cta(tester).enabled, isTrue);
  });

  testWidgets('응답을 못 받으면 다시 누를 때 같은 Idempotency-Key 를 쓴다', (tester) async {
    var calls = 0;
    final repository = FakePaymentRepository(
      requestCharge: (amount, key) async {
        if (++calls == 1) {
          throw const ApiTimeoutException(Duration(seconds: 15));
        }
        return ChargeResult(
          request: fixtureCharge(amount: amount),
          created: true,
        );
      },
    );
    await pumpPaymentApp(
      tester,
      initialLocation: Routes.credit,
      repository: repository,
    );

    await _tapCta(tester);
    await tester.pumpAndSettle();
    expect(find.text('충전 요청을 보내지 못했어요. 연결을 확인하고 다시 눌러 주세요'), findsOneWidget);
    expect(_field, findsOneWidget);

    await _tapCta(tester);
    await tester.pumpAndSettle();

    expect(repository.chargeKeys, hasLength(2));
    expect(repository.chargeKeys.toSet(), hasLength(1));
    expect(find.text('입금 확인 대기'), findsOneWidget);
  });

  testWidgets('금액을 바꾸면 새 Idempotency-Key 를 쓴다', (tester) async {
    final repository = FakePaymentRepository(
      requestCharge: (amount, key) async => throw const ApiNetworkException(),
    );
    await pumpPaymentApp(
      tester,
      initialLocation: Routes.credit,
      repository: repository,
    );

    await _tapCta(tester);
    await tester.pumpAndSettle();
    await tester.enterText(_field, '20000');
    await tester.pump();
    await _tapCta(tester);
    await tester.pumpAndSettle();

    expect(repository.chargeAmounts, [10000, 20000]);
    expect(repository.chargeKeys.toSet(), hasLength(2));
  });

  testWidgets('IDEMPOTENCY_IN_PROGRESS 는 1초 뒤 같은 키로 자동 재시도', (tester) async {
    var calls = 0;
    final repository = FakePaymentRepository(
      requestCharge: (amount, key) async {
        if (++calls < 3) {
          throw paymentError(PaymentErrorCode.idempotencyInProgress);
        }
        return ChargeResult(request: fixtureCharge(), created: true);
      },
    );
    await pumpPaymentApp(
      tester,
      initialLocation: Routes.credit,
      repository: repository,
    );

    await _tapCta(tester);
    await tester.pump();
    expect(repository.chargeKeys, hasLength(1));
    await tester.pump(const Duration(seconds: 1));
    expect(repository.chargeKeys, hasLength(2));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(repository.chargeKeys, hasLength(3));
    expect(repository.chargeKeys.toSet(), hasLength(1));
    expect(find.text('입금 확인 대기'), findsOneWidget);
  });

  testWidgets('200 (이미 보낸 요청) 이면 안내하고 그 요청을 보여 준다', (tester) async {
    await pumpPaymentApp(
      tester,
      initialLocation: Routes.credit,
      repository: FakePaymentRepository(
        requestCharge: (amount, key) async => ChargeResult(
          request: fixtureCharge(id: 509, amount: 5000),
          created: false,
        ),
      ),
    );

    await _tapCta(tester);
    await tester.pumpAndSettle();

    expect(find.text('이미 보낸 충전 요청이 있어요'), findsOneWidget);
    expect(find.text('입금 확인 대기'), findsOneWidget);
    expect(_amount(5000), findsOneWidget);
  });

  testWidgets('VALIDATION_FAILED 의 fields.amount 를 금액 칸 오류로 보여 준다', (
    tester,
  ) async {
    await pumpPaymentApp(
      tester,
      initialLocation: Routes.credit,
      repository: FakePaymentRepository(
        requestCharge: (amount, key) async => throw paymentError(
          PaymentErrorCode.validationFailed,
          statusCode: 400,
          fields: {'amount': '보유 한도를 넘어요'},
        ),
      ),
    );

    await _tapCta(tester);
    await tester.pumpAndSettle();

    expect(find.text('보유 한도를 넘어요'), findsOneWidget);
    expect(_cta(tester).enabled, isFalse);

    await tester.enterText(_field, '5000');
    await tester.pump();
    expect(find.text('보유 한도를 넘어요'), findsNothing);
    expect(_cta(tester).enabled, isTrue);
  });

  testWidgets('RATE_LIMITED 는 Retry-After 초로 안내한다', (tester) async {
    await pumpPaymentApp(
      tester,
      initialLocation: Routes.credit,
      repository: FakePaymentRepository(
        requestCharge: (amount, key) async => throw paymentError(
          PaymentErrorCode.rateLimited,
          statusCode: 429,
          retryAfter: const Duration(seconds: 42),
        ),
      ),
    );

    await _tapCta(tester);
    await tester.pumpAndSettle();
    expect(find.text('충전 요청이 많아요. 42초 뒤 다시 시도해 주세요'), findsOneWidget);
  });

  testWidgets('바자회가 끝나면 빨간 안내와 막힌 버튼 (서울 날짜 기준)', (tester) async {
    await pumpPaymentApp(
      tester,
      initialLocation: Routes.credit,
      now: afterEvent,
    );

    final subtitle = tester.widget<Text>(find.text('바자회가 끝나 충전할 수 없어요'));
    expect(subtitle.style!.color, AppColors.danger);
    expect(_cta(tester).label, '충전할 수 없어요');
    expect(_cta(tester).enabled, isFalse);
    expect(find.byType(AppNotice), findsNothing);
  });

  testWidgets('서버가 EVENT_ENDED 를 주면 끝난 화면으로 바뀐다', (tester) async {
    await pumpPaymentApp(
      tester,
      initialLocation: Routes.credit,
      repository: FakePaymentRepository(
        requestCharge: (amount, key) async =>
            throw paymentError(PaymentErrorCode.eventEnded),
      ),
    );

    await _tapCta(tester);
    await tester.pumpAndSettle();

    expect(find.text('바자회가 끝나 충전할 수 없어요'), findsOneWidget);
    expect(_cta(tester).label, '충전할 수 없어요');
  });

  testWidgets('확인 중인 요청은 10초마다 상태를 읽고, 승인되면 멈추고 잔액을 다시 읽는다', (tester) async {
    var status = ChargeStatus.pending;
    final repository = FakePaymentRepository(
      credit: () async => fixtureCredit(
        balance: status == ChargeStatus.approved ? 22400 : 12400,
      ),
      chargeRequest: (id) async => fixtureCharge(id: id, status: status),
    );
    await pumpPaymentApp(
      tester,
      initialLocation: Routes.credit,
      repository: repository,
    );
    await _tapCta(tester);
    await tester.pumpAndSettle();
    expect(find.text('입금 확인 대기'), findsOneWidget);
    // 요청 뒤에는 요청의 입금 계좌 · 입금자명을 보여 줍니다.
    expect(find.text('2205 이재원'), findsOneWidget);
    expect(find.text('000-1234-5678-90'), findsOneWidget);

    await tester.pump(CreditPage.pollInterval);
    await tester.pumpAndSettle();
    expect(repository.chargeRequestIds, [512]);

    status = ChargeStatus.approved;
    final creditCalls = repository.creditCalls;
    await tester.pump(CreditPage.pollInterval);
    await tester.pumpAndSettle();
    expect(repository.chargeRequestIds, [512, 512]);
    expect(find.text('충전 완료'), findsOneWidget);
    expect(repository.creditCalls, greaterThan(creditCalls));
    expect(_amount(22400), findsOneWidget);

    await tester.pump(CreditPage.pollInterval * 3);
    expect(repository.chargeRequestIds, [512, 512]);
  });

  testWidgets('운영진 확인 상태는 사유를 보여 주고 직접 확인할 수 있다', (tester) async {
    final repository = FakePaymentRepository(
      requestCharge: (amount, key) async => ChargeResult(
        request: fixtureCharge(
          id: 509,
          status: ChargeStatus.needsReview,
          reason: '30분째 입금이 없어요',
        ),
        created: false,
      ),
      chargeRequest: (id) async => fixtureCharge(
        id: id,
        status: ChargeStatus.needsReview,
        reason: '30분째 입금이 없어요',
      ),
    );
    await pumpPaymentApp(
      tester,
      initialLocation: Routes.credit,
      repository: repository,
    );
    await _tapCta(tester);
    await tester.pumpAndSettle();

    expect(find.text('운영진 확인 중'), findsOneWidget);
    expect(find.text('30분째 입금이 없어요'), findsOneWidget);
    expect(_field, findsNothing);

    await tester.tap(find.text('입금 확인하기'));
    await tester.pumpAndSettle();
    expect(repository.chargeRequestIds, [509]);
    expect(find.text('입금 확인 중이에요. 잠시 후 다시 확인해주세요'), findsOneWidget);
  });

  testWidgets('좁은 화면 · 큰 글자 · 키보드에서도 넘치지 않는다', (tester) async {
    tester.view.viewInsets = const FakeViewPadding(bottom: 240);
    await pumpPaymentApp(
      tester,
      initialLocation: Routes.credit,
      size: const Size(320, 640),
      textScale: 1.8,
      now: afterEvent,
    );
    expect(_cta(tester).enabled, isFalse);
    expect(tester.takeException(), isNull);
  });
}
