import 'dart:math';

import '../data/api/api_client.dart';
import '../data/models/payment_exception.dart';

/// 기다리는 함수. 테스트에서는 바로 끝나는 함수로 바꿔 넣습니다.
typedef RetryWait = Future<void> Function(Duration delay);

Future<void> _delay(Duration delay) => Future<void>.delayed(delay);

/// 돈이 오가는 요청(`POST /payments` · `POST /credits/charge`)에 붙이는 `Idempotency-Key` (UUID v4).
///
/// 같은 요청을 다시 보낼 때는 **같은 키**를 써야 서버가 처음 결과를 그대로 돌려줍니다(중복 차감 방지).
String newIdempotencyKey([Random? random]) {
  final rng = random ?? Random.secure();
  final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40; // 버전 4
  bytes[8] = (bytes[8] & 0x3f) | 0x80; // RFC 4122 변형
  final hex = [for (final b in bytes) b.toRadixString(16).padLeft(2, '0')]
      .join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

/// [send] 를 같은 키로 다시 보내는 규칙 (명세 공통 규칙 8).
///
/// - 응답을 못 받으면([ApiNetworkException], 시간 초과 포함) [networkRetryDelays] 만큼 기다렸다 다시 보냅니다.
/// - 409 `IDEMPOTENCY_IN_PROGRESS` 면 [inProgressDelay] 뒤에 최대 [maxInProgressRetries] 번 다시 보냅니다.
/// - 그래도 안 되면 마지막 예외를 그대로 던집니다 (결과를 모르는 상태).
///
/// [send] 는 매번 같은 키를 써야 합니다. 이 함수는 키를 만들지 않습니다.
Future<T> sendWithSameKey<T>(
  Future<T> Function() send, {
  List<Duration> networkRetryDelays = const [],
  Duration inProgressDelay = const Duration(seconds: 1),
  int maxInProgressRetries = 3,
  RetryWait? wait,
}) async {
  final pause = wait ?? _delay;
  var networkRetries = 0;
  var inProgressRetries = 0;
  while (true) {
    try {
      return await send();
    } on ApiNetworkException {
      if (networkRetries >= networkRetryDelays.length) rethrow;
      await pause(networkRetryDelays[networkRetries++]);
    } on PaymentException catch (error) {
      if (error.code != PaymentErrorCode.idempotencyInProgress ||
          inProgressRetries >= maxInProgressRetries) {
        rethrow;
      }
      inProgressRetries++;
      await pause(inProgressDelay);
    }
  }
}
