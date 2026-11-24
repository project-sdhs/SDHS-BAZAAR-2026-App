import '../api/api_client.dart';
import '../models/charge_request.dart';
import '../models/credit_summary.dart';
import '../models/credit_transaction.dart';
import '../models/payment.dart';
import '../models/payment_exception.dart';
import '../models/public_settings.dart';
import '../models/qr_pay.dart';

/// 크레딧 · 충전 · QR 결제 · 거래 내역 서버 호출.
///
/// - 서버의 에러 응답은 [PaymentException] 으로 바꿔 던집니다 (409 추가 필드 · `Retry-After` 포함).
/// - 응답을 받지 못하면 [ApiNetworkException] (시간 초과는 [ApiTimeoutException]) 을 그대로 던집니다.
/// - 응답 모양이 다르면 [FormatException] 을 던집니다.
class PaymentRepository {
  PaymentRepository(this._api);

  final ApiClient _api;

  /// 공개 설정 (`GET /settings/public`): 바자회 기간 · 입금 계좌 · 입금자명 규칙 · 충전 한도.
  Future<PublicSettings> publicSettings() async =>
      PublicSettings.fromJson(_map(await _get('/settings/public'), '공개 설정'));

  /// 내 크레딧 (`GET /me/credit`).
  Future<CreditSummary> myCredit() async =>
      CreditSummary.fromJson(_map(await _get('/me/credit'), '내 크레딧'));

  /// 충전 요청 (`POST /credits/charge`).
  ///
  /// 재시도할 때는 같은 [idempotencyKey] 를 넘깁니다. 이미 대기 중인 요청이 있으면
  /// 서버가 그 요청을 200 으로 돌려주고, 이때 [ChargeResult.created] 는 false 입니다.
  Future<ChargeResult> requestCharge(
    int amount, {
    required String idempotencyKey,
  }) async {
    final response = await _guard(
      () => _api.postResponse(
        '/credits/charge',
        body: {'amount': amount},
        headers: {'Idempotency-Key': idempotencyKey},
      ),
    );
    return ChargeResult(
      request: ChargeRequest.fromJson(_map(response.body, '충전 요청')),
      created: response.statusCode == 201,
    );
  }

  /// 충전 요청 상태 (`GET /credits/charge/{id}`).
  Future<ChargeRequest> chargeRequest(int id) async =>
      ChargeRequest.fromJson(_map(await _get('/credits/charge/$id'), '충전 요청'));

  /// 거래 내역 한 페이지 (`GET /transactions`). 서버가 준 순서 그대로입니다.
  ///
  /// 다음 페이지는 앞 페이지의 [TransactionPage.nextCursor] 를 [cursor] 로 넘깁니다.
  Future<TransactionPage> transactions({
    TransactionFilter? type,
    String? cursor,
    int limit = 20,
  }) async => TransactionPage.fromJson(
    _map(
      await _get(
        '/transactions',
        query: {'type': ?type?.name, 'cursor': ?cursor, 'limit': '$limit'},
      ),
      '거래 내역',
    ),
  );

  /// QR 로 결제 화면 정보 읽기 (`GET /pay/qr/{code}?src=`).
  ///
  /// 주문 정지면 `ORDERING_PAUSED`, 운영 시간 밖이면 `BOOTH_CLOSED`, 모르는 QR 이면 `QR_INVALID`.
  Future<QrPayInfo> qrPayInfo(
    String code, {
    PaymentSource source = PaymentSource.print,
  }) async => QrPayInfo.fromJson(
    _map(
      await _get(
        '/pay/qr/${Uri.encodeComponent(code)}',
        query: {'src': source.name},
      ),
      'QR 결제 정보',
    ),
  );

  /// 결제 (`POST /payments`). 200 은 서버가 커밋한 뒤에만 옵니다.
  ///
  /// 재시도할 때는 같은 [idempotencyKey] 를 넘깁니다 (같은 키면 처음 결과를 그대로 받음).
  Future<PaymentReceipt> pay(
    PaymentRequest request, {
    required String idempotencyKey,
  }) async {
    final response = await _guard(
      () => _api.postResponse(
        '/payments',
        body: request.toJson(),
        headers: {'Idempotency-Key': idempotencyKey},
      ),
    );
    return PaymentReceipt.fromJson(_map(response.body, '결제'));
  }

  /// 서버가 준 상대 경로를 앱이 쓰는 서버 주소와 합친 이미지 주소.
  String? imageUrl(String? path) =>
      path == null ? null : '${_api.baseUrl}$path';

  /// 앱이 끝날 때 HTTP 연결을 닫습니다.
  void close() => _api.close();

  Future<Object?> _get(String path, {Map<String, String>? query}) async =>
      (await _guard(() => _api.getResponse(path, query: query))).body;

  Future<ApiResponse> _guard(Future<ApiResponse> Function() call) async {
    try {
      return await call();
    } on ApiException catch (error) {
      throw PaymentException.fromApi(error);
    }
  }

  Map<String, Object?> _map(Object? body, String what) {
    if (body is! Map<String, Object?>) {
      throw FormatException('$what 응답 모양이 달라요');
    }
    return body;
  }
}
