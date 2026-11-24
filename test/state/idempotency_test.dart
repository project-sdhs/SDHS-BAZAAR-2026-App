import 'package:bazaar_app/data/api/api_client.dart';
import 'package:bazaar_app/data/models/payment_exception.dart';
import 'package:bazaar_app/state/idempotency.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/payment_fixtures.dart';

void main() {
  test('Idempotency-Key 는 매번 다른 UUID v4', () {
    final pattern = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    );
    final keys = {for (var i = 0; i < 50; i++) newIdempotencyKey()};
    expect(keys, hasLength(50));
    expect(keys.every(pattern.hasMatch), isTrue);
  });

  test('응답을 못 받으면 1 · 2 · 4초 뒤 같은 요청을 다시 보내고, 그래도 안 되면 던진다', () async {
    final waits = <Duration>[];
    var calls = 0;
    await expectLater(
      sendWithSameKey<int>(
        () async {
          calls++;
          throw const ApiTimeoutException(Duration(seconds: 15));
        },
        networkRetryDelays: const [
          Duration(seconds: 1),
          Duration(seconds: 2),
          Duration(seconds: 4),
        ],
        wait: (delay) async => waits.add(delay),
      ),
      throwsA(isA<ApiTimeoutException>()),
    );
    expect(calls, 4);
    expect(waits, const [
      Duration(seconds: 1),
      Duration(seconds: 2),
      Duration(seconds: 4),
    ]);
  });

  test('IDEMPOTENCY_IN_PROGRESS 는 1초 뒤 최대 3번 다시 보낸다', () async {
    final waits = <Duration>[];
    var calls = 0;
    final result = await sendWithSameKey<String>(() async {
      if (++calls < 3) {
        throw paymentError(PaymentErrorCode.idempotencyInProgress);
      }
      return 'done';
    }, wait: (delay) async => waits.add(delay));
    expect(result, 'done');
    expect(calls, 3);
    expect(waits, const [Duration(seconds: 1), Duration(seconds: 1)]);

    calls = 0;
    await expectLater(
      sendWithSameKey<String>(() async {
        calls++;
        throw paymentError(PaymentErrorCode.idempotencyInProgress);
      }, wait: (_) async {}),
      throwsA(isA<PaymentException>()),
    );
    expect(calls, 4);
  });

  test('서버가 결과를 준 에러는 다시 보내지 않는다', () async {
    var calls = 0;
    await expectLater(
      sendWithSameKey<String>(
        () async {
          calls++;
          throw paymentError(PaymentErrorCode.insufficientCredit);
        },
        networkRetryDelays: const [Duration(seconds: 1)],
        wait: (_) async {},
      ),
      throwsA(isA<PaymentException>()),
    );
    expect(calls, 1);
  });
}
