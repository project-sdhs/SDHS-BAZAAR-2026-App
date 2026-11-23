import 'package:bazaar_app/core/theme/app_theme.dart';
import 'package:bazaar_app/data/models/payment_models.dart';
import 'package:bazaar_app/data/repositories/payment_repository.dart';
import 'package:bazaar_app/state/credit_store.dart';
import 'package:bazaar_app/ui/components/buttons/buttons.dart';
import 'package:bazaar_app/ui/pages/credit/credit_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class _TrackingRepository extends PreviewPaymentRepository {
  int requestCount = 0;

  @override
  Future<ChargeRequest> requestCharge(int amount) {
    requestCount++;
    return super.requestCharge(amount);
  }
}

Future<void> _pumpCredit(
  WidgetTester tester, {
  PaymentRepository? repository,
  double textScale = 1,
}) async {
  final store = CreditStore(
    repository: repository ?? PreviewPaymentRepository(),
  );
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (context, state) => const CreditPage()),
    ],
  );
  addTearDown(router.dispose);
  addTearDown(store.dispose);
  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: store,
      child: MaterialApp.router(
        theme: AppTheme.light,
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

AppButton _requestButton(WidgetTester tester) => tester.widget<AppButton>(
  find.descendant(of: find.byType(BottomCTA), matching: find.byType(AppButton)),
);

void main() {
  testWidgets('금액 칩은 현재 금액에 더하고 숫자 이외 입력은 요청할 수 없다', (tester) async {
    await _pumpCredit(tester);
    final field = find.byType(TextFormField);
    await tester.enterText(field, '1500');
    await tester.pump();
    expect(tester.widget<TextFormField>(field).controller!.text, '1,500');

    await tester.tap(find.text('+5,000'));
    await tester.pump();
    expect(tester.widget<TextFormField>(field).controller!.text, '6,500');

    for (final invalid in ['-1000', '1a000', '']) {
      await tester.enterText(field, invalid);
      await tester.pump();
      expect(_requestButton(tester).enabled, isFalse, reason: invalid);
    }
  });

  testWidgets('설정된 최소 금액과 1회 한도 및 보유 한도를 확인한다', (tester) async {
    await _pumpCredit(
      tester,
      repository: PreviewPaymentRepository(
        settings: const ChargeSettings(
          account: DepositAccount(bank: '', accountNo: '', holder: ''),
          minimumAmount: 1000,
          maximumAmount: 20000,
          balanceLimit: 30000,
        ),
      ),
    );
    final field = find.byType(TextFormField);
    for (final amount in ['999', '20001', '18000']) {
      await tester.enterText(field, amount);
      await tester.pump();
      expect(_requestButton(tester).enabled, isFalse, reason: amount);
    }
    await tester.enterText(field, '17600');
    await tester.pump();
    expect(_requestButton(tester).enabled, isTrue);
  });

  testWidgets('요청 처리 중 중복 제출을 막고 승인 전에는 잔액을 늘리지 않는다', (tester) async {
    final repository = _TrackingRepository();
    await _pumpCredit(tester, repository: repository);
    final submit = find.descendant(
      of: find.byType(BottomCTA),
      matching: find.byType(AppButton),
    );
    await tester.tap(submit);
    await tester.pump();
    await tester.tap(submit);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(repository.requestCount, 1);
    expect(repository.balance, 12400);
    expect(find.text('입금 확인 대기'), findsOneWidget);
    expect(find.text('입금 확인하기'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
  });

  testWidgets('운영진 확인 상태는 사유를 표시하고 새 요청을 막는다', (tester) async {
    await _pumpCredit(
      tester,
      repository: PreviewPaymentRepository(
        chargeRequest: const ChargeRequest(
          id: 10,
          amount: 5000,
          status: ChargeStatus.needsReview,
          depositorName: '학번 이름',
          reason: '입금자명을 확인하고 있어요',
        ),
      ),
    );
    expect(find.text('운영진 확인 중'), findsOneWidget);
    expect(find.text('입금자명을 확인하고 있어요'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
    expect(find.text('입금 확인하기'), findsOneWidget);
  });

  testWidgets('행사 종료와 좁은 화면 및 확대 글자에서 레이아웃이 유지된다', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 240);
    addTearDown(tester.view.reset);
    await _pumpCredit(
      tester,
      textScale: 1.8,
      repository: PreviewPaymentRepository(
        settings: const ChargeSettings(
          account: DepositAccount(
            bank: '은행 확인 중',
            accountNo: '계좌 확인 중',
            holder: '예금주 확인 중',
          ),
          eventEnded: true,
        ),
      ),
    );
    expect(_requestButton(tester).enabled, isFalse);
    expect(tester.takeException(), isNull);
  });
}
