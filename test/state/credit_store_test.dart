import 'dart:async';

import 'package:bazaar_app/data/models/payment_models.dart';
import 'package:bazaar_app/data/repositories/payment_repository.dart';
import 'package:bazaar_app/state/credit_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('결제가 끝난 뒤 잔액과 사용액, 거래 내역이 함께 바뀐다', () async {
    final store = CreditStore.preview();
    addTearDown(store.dispose);
    final booth = await store.resolveQr('K7Q2M9X4TB');
    final items = [OrderLine(menu: booth.menus.first, quantity: 1)];
    final payment = store.pay(booth, items);
    items.clear();

    expect(store.balance, 12400);
    expect(store.usedTotal, 17600);
    final receipt = await payment;

    expect(receipt.total, 3000);
    expect(receipt.balanceBefore, 12400);
    expect(receipt.balanceAfter, 9400);
    expect(receipt.items.single.quantity, 1);
    expect(store.balance, 9400);
    expect(store.usedTotal, 20600);
    expect(store.transactions.first.amount, -3000);
    expect(() => receipt.items.clear(), throwsUnsupportedError);
  });

  test('부족한 잔액과 품절 메뉴는 거래를 만들지 않는다', () async {
    final store = CreditStore(
      repository: PreviewPaymentRepository(balance: 1000),
    );
    addTearDown(store.dispose);
    final booth = await store.resolveQr('K7Q2M9X4TB');
    final originalCount = store.transactions.length;

    await expectLater(
      store.pay(booth, [OrderLine(menu: booth.menus.first, quantity: 1)]),
      throwsA(
        isA<PaymentException>().having(
          (error) => error.code,
          'code',
          'INSUFFICIENT_CREDIT',
        ),
      ),
    );
    await expectLater(
      store.pay(booth, [OrderLine(menu: booth.menus.last, quantity: 1)]),
      throwsA(
        isA<PaymentException>().having(
          (error) => error.code,
          'code',
          'MENU_CHANGED',
        ),
      ),
    );
    expect(store.balance, 1000);
    expect(store.transactions.length, originalCount);
  });

  test('처리 중에 다시 누른 결제는 한 번만 저장소에 전달한다', () async {
    final repository = _HeldPaymentRepository();
    final store = CreditStore(repository: repository);
    addTearDown(store.dispose);
    final booth = await store.resolveQr('K7Q2M9X4TB');
    final items = [OrderLine(menu: booth.menus.first, quantity: 1)];
    final payment = store.pay(booth, items);

    await expectLater(
      store.pay(booth, items),
      throwsA(
        isA<PaymentException>().having(
          (error) => error.code,
          'code',
          'PAYMENT_IN_PROGRESS',
        ),
      ),
    );
    expect(repository.payCalls, 1);
    repository.release.complete();
    await payment;
    expect(store.balance, 9400);
  });

  test('충전 요청과 상태 새로고침은 승인 전 잔액을 늘리지 않는다', () async {
    final store = CreditStore.preview();
    addTearDown(store.dispose);

    final request = await store.requestCharge(10000);
    expect(request.status, ChargeStatus.pending);
    expect((await store.refreshCharge())?.status, ChargeStatus.pending);
    expect(store.balance, 12400);
    expect(store.chargedTotal, 30000);
    await expectLater(
      store.requestCharge(10000),
      throwsA(
        isA<PaymentException>().having(
          (error) => error.code,
          'code',
          'CHARGE_PENDING',
        ),
      ),
    );
  });

  test('예시 QR 주소만 부스를 열고 다른 QR은 거절한다', () async {
    final store = CreditStore.preview();
    addTearDown(store.dispose);

    expect(
      (await store.resolveQr(
        'https://bazaar.example.com/q/K7Q2M9X4TB?src=board',
      )).name,
      '2-3 타코야끼',
    );
    await expectLater(
      store.resolveQr('https://example.com/unrelated'),
      throwsA(isA<PaymentException>()),
    );
  });
}

class _HeldPaymentRepository extends PreviewPaymentRepository {
  final release = Completer<void>();
  int payCalls = 0;

  @override
  Future<PaymentReceipt> pay(PaymentBooth booth, List<OrderLine> items) async {
    payCalls++;
    await release.future;
    return super.pay(booth, items);
  }
}
