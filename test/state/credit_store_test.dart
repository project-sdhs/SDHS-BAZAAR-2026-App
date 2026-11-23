import 'dart:async';

import 'package:bazaar_app/data/api/api_client.dart';
import 'package:bazaar_app/data/models/charge_request.dart';
import 'package:bazaar_app/data/models/payment.dart';
import 'package:bazaar_app/data/models/payment_exception.dart';
import 'package:bazaar_app/data/models/qr_pay.dart';
import 'package:bazaar_app/state/credit_store.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_payment_repository.dart';
import '../support/payment_fixtures.dart';

CreditStore _store(FakePaymentRepository repository, {DateTime? now}) {
  final store = CreditStore(
    repository,
    clock: () => now ?? eventDay,
    wait: (_) async {},
  );
  addTearDown(store.dispose);
  return store;
}

PaymentRequest _request() => PaymentRequest(
  qrCode: sampleQrCode,
  source: PaymentSource.board,
  items: const [
    PaymentItem(menuId: 301, quantity: 1),
    PaymentItem(menuId: 302, quantity: 1),
  ],
  clientTotal: 4800,
);

void main() {
  test('load: 공개 설정과 /me/credit 를 읽는다', () async {
    final repository = FakePaymentRepository();
    final store = _store(repository);
    expect(store.isLoading, isTrue);

    await store.load();

    expect(store.isReady, isTrue);
    expect(store.isLoading, isFalse);
    expect(store.balance, 12400);
    expect(store.used, 17600);
    expect(store.pendingChargeAmount, 0);
    expect(store.settings!.chargeMin, 1000);
    expect(store.isEventEnded, isFalse);
    expect((repository.settingsCalls, repository.creditCalls), (1, 1));
  });

  test('load 가 실패하면 error 를 남기고 refresh 로 다시 읽는다', () async {
    var fail = true;
    final repository = FakePaymentRepository(
      credit: () async {
        if (fail) throw const ApiNetworkException();
        return fixtureCredit();
      },
    );
    final store = _store(repository);

    await store.load();
    expect(store.isReady, isFalse);
    expect(store.isLoading, isFalse);
    expect(store.error, isA<ApiNetworkException>());

    fail = false;
    await store.refresh();
    expect(store.isReady, isTrue);
    expect(store.error, isNull);
  });

  test('종료일이 서울 날짜로 지났거나 서버가 EVENT_ENDED 를 주면 끝난 상태', () async {
    final ended = _store(FakePaymentRepository(), now: afterEvent);
    await ended.load();
    expect(ended.isEventEnded, isTrue);

    final store = _store(
      FakePaymentRepository(
        requestCharge: (amount, key) async =>
            throw paymentError(PaymentErrorCode.eventEnded),
      ),
    );
    await store.load();
    expect(store.isEventEnded, isFalse);
    await expectLater(
      store.requestCharge(10000, idempotencyKey: 'k'),
      throwsA(isA<PaymentException>()),
    );
    expect(store.isEventEnded, isTrue);
  });

  group('결제', () {
    test('성공하면 잔액 = 영수증의 balanceAfter', () async {
      final store = _store(FakePaymentRepository());
      await store.load();

      final receipt = await store.pay(_request(), idempotencyKey: 'k');

      expect(receipt.balanceAfter, 7600);
      expect(store.balance, 7600);
    });

    test('409 INSUFFICIENT_CREDIT 면 잔액 = 응답의 balance', () async {
      final store = _store(
        FakePaymentRepository(
          pay: (request, key) async => throw paymentError(
            PaymentErrorCode.insufficientCredit,
            details: {'balance': 3000, 'total': 4800, 'shortfall': 1800},
          ),
        ),
      );
      await store.load();

      await expectLater(
        store.pay(_request(), idempotencyKey: 'k'),
        throwsA(
          isA<PaymentException>().having(
            (e) => e.insufficientCredit?.shortfall,
            'shortfall',
            1800,
          ),
        ),
      );
      expect(store.balance, 3000);
    });

    test('응답을 못 받으면 같은 키로 다시 보낸다 (1 · 2 · 4초)', () async {
      var calls = 0;
      final repository = FakePaymentRepository(
        pay: (request, key) async {
          if (++calls < 3) {
            throw const ApiTimeoutException(Duration(seconds: 15));
          }
          return fixtureReceipt();
        },
      );
      final store = _store(repository);

      await store.pay(_request(), idempotencyKey: 'same-key');

      expect(repository.payKeys, ['same-key', 'same-key', 'same-key']);
      expect(store.balance, 7600);
    });

    test('처리 중에 다시 부르면 저장소는 한 번만 부르고 같은 결과를 준다', () async {
      final release = Completer<void>();
      final repository = FakePaymentRepository(
        pay: (request, key) async {
          await release.future;
          return fixtureReceipt();
        },
      );
      final store = _store(repository);

      final first = store.pay(_request(), idempotencyKey: 'k');
      final second = store.pay(_request(), idempotencyKey: 'k');
      release.complete();

      expect(await first, same(await second));
      expect(repository.payKeys, hasLength(1));
    });

    test('QR 정보의 잔액으로 store 잔액을 맞춘다', () async {
      final store = _store(
        FakePaymentRepository(
          qrPayInfo: (code, source) async => fixtureQrInfo(balance: 5000),
        ),
      );
      await store.load();

      final info = await store.qrPayInfo(QrPayload.parse(sampleQrCode));

      expect(info.balance, 5000);
      expect(store.balance, 5000);
    });
  });

  group('충전', () {
    test('IDEMPOTENCY_IN_PROGRESS 면 같은 키로 다시 보내고 요청을 남긴다', () async {
      var calls = 0;
      final repository = FakePaymentRepository(
        requestCharge: (amount, key) async {
          if (++calls < 3) {
            throw paymentError(PaymentErrorCode.idempotencyInProgress);
          }
          return ChargeResult(request: fixtureCharge(), created: true);
        },
      );
      final store = _store(repository);
      await store.load();

      final result = await store.requestCharge(10000, idempotencyKey: 'key-1');

      expect(result.created, isTrue);
      expect(repository.chargeKeys, ['key-1', 'key-1', 'key-1']);
      expect(store.chargeRequest!.status, ChargeStatus.pending);
      // 승인 전에는 잔액이 늘지 않습니다.
      expect(store.balance, 12400);
    });

    test('승인되면 /me/credit 를 다시 읽어 잔액에 반영한다', () async {
      var approved = false;
      final repository = FakePaymentRepository(
        credit: () async => fixtureCredit(balance: approved ? 22400 : 12400),
        chargeRequest: (id) async => fixtureCharge(
          id: id,
          status: approved ? ChargeStatus.approved : ChargeStatus.pending,
        ),
      );
      final store = _store(repository);
      await store.load();
      await store.requestCharge(10000, idempotencyKey: 'k');

      expect((await store.refreshChargeRequest()).status, ChargeStatus.pending);
      expect(store.balance, 12400);

      approved = true;
      expect(
        (await store.refreshChargeRequest()).status,
        ChargeStatus.approved,
      );
      expect(store.balance, 22400);
      expect(repository.chargeRequestIds, [512, 512]);
    });

    test('다시 충전하기를 누르면 끝난 요청을 비운다', () async {
      final store = _store(FakePaymentRepository());
      await store.load();
      await store.requestCharge(10000, idempotencyKey: 'k');
      expect(store.chargeRequest, isNotNull);

      store.clearChargeRequest();
      expect(store.chargeRequest, isNull);
    });
  });
}
