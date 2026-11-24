import 'package:bazaar_app/data/api/api_client.dart';
import 'package:bazaar_app/data/models/charge_request.dart';
import 'package:bazaar_app/data/models/credit_summary.dart';
import 'package:bazaar_app/data/models/credit_transaction.dart';
import 'package:bazaar_app/data/models/payment.dart';
import 'package:bazaar_app/data/models/public_settings.dart';
import 'package:bazaar_app/data/models/qr_pay.dart';
import 'package:bazaar_app/data/repositories/payment_repository.dart';

import 'payment_fixtures.dart';

/// 서버 대신 정해 둔 값(또는 오류)을 돌려주는 결제 저장소 (테스트용).
///
/// 함수를 안 넘기면 API 페이지 예시 값을 돌려줍니다. 보낸 요청은 `*Calls` 에 남습니다.
class FakePaymentRepository extends PaymentRepository {
  FakePaymentRepository({
    Future<PublicSettings> Function()? settings,
    Future<CreditSummary> Function()? credit,
    Future<ChargeResult> Function(int amount, String key)? requestCharge,
    Future<ChargeRequest> Function(int id)? chargeRequest,
    Future<TransactionPage> Function(TransactionFilter? type, String? cursor)?
    transactions,
    Future<QrPayInfo> Function(String code, PaymentSource source)? qrPayInfo,
    Future<PaymentReceipt> Function(PaymentRequest request, String key)? pay,
  }) : _settings = settings ?? (() async => fixtureSettings()),
       _credit = credit ?? (() async => fixtureCredit()),
       _requestCharge =
           requestCharge ??
           ((amount, key) async => ChargeResult(
             request: fixtureCharge(amount: amount),
             created: true,
           )),
       _chargeRequest = chargeRequest ?? ((id) async => fixtureCharge(id: id)),
       _transactions =
           transactions ??
           ((type, cursor) async => const TransactionPage(items: [])),
       _qrPayInfo = qrPayInfo ?? ((code, source) async => fixtureQrInfo()),
       _pay = pay ?? ((request, key) async => fixtureReceipt()),
       super(ApiClient());

  final Future<PublicSettings> Function() _settings;
  final Future<CreditSummary> Function() _credit;
  final Future<ChargeResult> Function(int amount, String key) _requestCharge;
  final Future<ChargeRequest> Function(int id) _chargeRequest;
  final Future<TransactionPage> Function(
    TransactionFilter? type,
    String? cursor,
  )
  _transactions;
  final Future<QrPayInfo> Function(String code, PaymentSource source)
  _qrPayInfo;
  final Future<PaymentReceipt> Function(PaymentRequest request, String key)
  _pay;

  int settingsCalls = 0;
  int creditCalls = 0;
  final chargeKeys = <String>[];
  final chargeAmounts = <int>[];
  final chargeRequestIds = <int>[];
  final transactionCalls = <(TransactionFilter?, String?, int)>[];
  final qrCalls = <(String, PaymentSource)>[];
  final payKeys = <String>[];
  final payRequests = <PaymentRequest>[];

  @override
  Future<PublicSettings> publicSettings() {
    settingsCalls++;
    return _settings();
  }

  @override
  Future<CreditSummary> myCredit() {
    creditCalls++;
    return _credit();
  }

  @override
  Future<ChargeResult> requestCharge(
    int amount, {
    required String idempotencyKey,
  }) {
    chargeAmounts.add(amount);
    chargeKeys.add(idempotencyKey);
    return _requestCharge(amount, idempotencyKey);
  }

  @override
  Future<ChargeRequest> chargeRequest(int id) {
    chargeRequestIds.add(id);
    return _chargeRequest(id);
  }

  @override
  Future<TransactionPage> transactions({
    TransactionFilter? type,
    String? cursor,
    int limit = 20,
  }) {
    transactionCalls.add((type, cursor, limit));
    return _transactions(type, cursor);
  }

  @override
  Future<QrPayInfo> qrPayInfo(
    String code, {
    PaymentSource source = PaymentSource.print,
  }) {
    qrCalls.add((code, source));
    return _qrPayInfo(code, source);
  }

  @override
  Future<PaymentReceipt> pay(
    PaymentRequest request, {
    required String idempotencyKey,
  }) {
    payRequests.add(request);
    payKeys.add(idempotencyKey);
    return _pay(request, idempotencyKey);
  }
}
