import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/models/charge_request.dart';
import '../data/models/credit_summary.dart';
import '../data/models/payment.dart';
import '../data/models/payment_exception.dart';
import '../data/models/public_settings.dart';
import '../data/models/qr_pay.dart';
import '../data/repositories/payment_repository.dart';
import 'idempotency.dart';

/// 내 크레딧 상태: 공개 설정 · 잔액 · 진행 중인 충전 요청 (마이 · 충전 · QR 결제 · 거래 내역이 함께 씀).
///
/// `AppProviders` 에서 한 번만 만들고 [load] 를 부릅니다. 잔액은 서버(`/me/credit`)가 기준이고,
/// 결제 뒤에는 영수증의 `balanceAfter`, 잔액 부족(409) 뒤에는 응답의 `balance` 로 맞춥니다.
class CreditStore extends ChangeNotifier {
  CreditStore(this._repository, {DateTime Function()? clock, RetryWait? wait})
    : _clock = clock ?? DateTime.now,
      _wait = wait ?? _sleep;

  final PaymentRepository _repository;
  final DateTime Function() _clock;

  /// 재시도 사이에 기다리는 함수 (테스트에서는 바로 끝나는 함수를 넘김)
  final RetryWait _wait;

  static Future<void> _sleep(Duration delay) => Future<void>.delayed(delay);

  /// 결제 응답을 못 받았을 때 같은 키로 다시 보내는 간격 (명세: 1 · 2 · 4초)
  static const paymentRetryDelays = [
    Duration(seconds: 1),
    Duration(seconds: 2),
    Duration(seconds: 4),
  ];

  PublicSettings? _settings;
  CreditSummary? _credit;
  int? _balance;
  Object? _error;
  bool _loading = false;
  Future<void>? _loadFuture;
  bool _serverSaidEventEnded = false;

  ChargeRequest? _chargeRequest;
  Future<ChargeResult>? _chargeInFlight;
  Future<ChargeRequest>? _chargeRefreshInFlight;
  Future<PaymentReceipt>? _payInFlight;
  bool _disposed = false;

  PaymentRepository get repository => _repository;

  /// 공개 설정. 아직 못 읽었으면 null.
  PublicSettings? get settings => _settings;

  /// `/me/credit` 응답. 아직 못 읽었으면 null.
  CreditSummary? get credit => _credit;

  /// 설정과 잔액을 모두 읽었는지
  bool get isReady => _settings != null && _credit != null;

  /// 처음 읽는 중이거나 [refresh] 중인지
  bool get isLoading => _loading || (!isReady && _error == null);

  /// 마지막 [load] 가 실패한 이유. 성공하면 null.
  Object? get error => _error;

  /// 잔액. 모르면 0 ([hasBalance] 로 확인).
  int get balance => _balance ?? 0;
  bool get hasBalance => _balance != null;

  /// 이번 바자회 사용액 (`/me/credit.used`)
  int get used => _credit?.used ?? 0;

  /// 승인 전 충전 요청 금액 합계 (`/me/credit.pendingChargeAmount`)
  int get pendingChargeAmount => _credit?.pendingChargeAmount ?? 0;

  /// 이번 앱 실행에서 만든(또는 서버가 돌려준) 충전 요청. "다시 충전하기" 를 누르면 비웁니다.
  ChargeRequest? get chargeRequest => _chargeRequest;

  /// 서울 날짜로 종료일이 지났거나, 서버가 `EVENT_ENDED` 를 돌려줬으면 true.
  bool get isEventEnded =>
      _serverSaidEventEnded || (_settings?.hasEndedAt(_clock()) ?? false);

  /// 설정과 잔액을 처음 읽습니다. 이미 읽는 중이면 그 결과를 기다립니다.
  Future<void> load() =>
      _loadFuture ??= _load().whenComplete(() => _loadFuture = null);

  /// 다시 읽기 ("다시 시도" · 당겨서 새로고침).
  Future<void> refresh() => load();

  Future<void> _load() async {
    // 처음 부를 때는 화면이 그리는 중일 수 있어 알리지 않습니다 (isLoading 이 이미 true).
    final firstLoad = !isReady && _error == null && !_loading;
    _loading = true;
    _error = null;
    if (!firstLoad) _notify();
    try {
      final (settings, credit) = await (
        _repository.publicSettings(),
        _repository.myCredit(),
      ).wait;
      _settings = settings;
      _setCredit(credit);
    } on ParallelWaitError<
      (PublicSettings?, CreditSummary?),
      (AsyncError?, AsyncError?)
    > catch (error) {
      final (settingsError, creditError) = error.errors;
      final (settings, credit) = error.values;
      if (settings != null) _settings = settings;
      if (credit != null) _setCredit(credit);
      _error = settingsError?.error ?? creditError?.error;
    } finally {
      _loading = false;
      _notify();
    }
  }

  /// 잔액만 다시 읽습니다 (`GET /me/credit`). 실패하면 이전 값을 그대로 둡니다.
  Future<void> refreshCredit() async {
    try {
      final credit = await _repository.myCredit();
      _setCredit(credit);
      _notify();
    } catch (_) {
      // 배경 새로고침이라 화면에 오류를 띄우지 않습니다.
    }
  }

  void _setCredit(CreditSummary credit) {
    _credit = credit;
    _balance = credit.balance;
  }

  void _setBalance(int balance) {
    if (_balance == balance) return;
    _balance = balance;
    _notify();
  }

  /// 서버가 `EVENT_ENDED` 를 돌려줬을 때.
  void markEventEnded() {
    if (_serverSaidEventEnded) return;
    _serverSaidEventEnded = true;
    _notify();
  }

  // ---------------------------------------------------------------- 충전

  /// 충전 요청. 처리 중에 또 부르면 같은 결과를 기다립니다 (중복 제출 방지).
  ///
  /// 409 `IDEMPOTENCY_IN_PROGRESS` 면 1초 뒤 같은 키로 최대 3번 다시 보냅니다.
  /// 응답을 못 받으면 [ApiNetworkException] 을 던집니다. 화면은 키를 지우지 말고 다시 누를 때 그대로 씁니다.
  Future<ChargeResult> requestCharge(
    int amount, {
    required String idempotencyKey,
  }) => _chargeInFlight ??= _requestCharge(
    amount,
    idempotencyKey,
  ).whenComplete(() => _chargeInFlight = null);

  Future<ChargeResult> _requestCharge(int amount, String key) async {
    try {
      final result = await sendWithSameKey(
        () => _repository.requestCharge(amount, idempotencyKey: key),
        wait: _wait,
      );
      _chargeRequest = result.request;
      _notify();
      // 확인 중인 충전 금액(pendingChargeAmount)이 바뀌었습니다.
      unawaited(refreshCredit());
      return result;
    } on PaymentException catch (error) {
      if (error.code == PaymentErrorCode.eventEnded) markEventEnded();
      rethrow;
    }
  }

  /// 진행 중인 충전 요청의 상태를 다시 읽습니다 (`GET /credits/charge/{id}`).
  ///
  /// 승인되면 잔액도 다시 읽습니다. 요청이 없으면 [StateError].
  Future<ChargeRequest> refreshChargeRequest() {
    final current = _chargeRequest;
    if (current == null) throw StateError('확인할 충전 요청이 없어요');
    return _chargeRefreshInFlight ??= _refreshChargeRequest(current.id)
        .whenComplete(() => _chargeRefreshInFlight = null);
  }

  Future<ChargeRequest> _refreshChargeRequest(int id) async {
    final request = await _repository.chargeRequest(id);
    // 그사이 "다시 충전하기" 로 요청을 비웠으면 되살리지 않습니다.
    if (_chargeRequest?.id != id) return request;
    _chargeRequest = request;
    _notify();
    // 승인 · 반려되면 잔액과 확인 중 금액이 바뀝니다.
    if (!request.status.isWaiting) await refreshCredit();
    return request;
  }

  /// "다시 충전하기": 끝난 요청을 화면에서 치웁니다.
  void clearChargeRequest() {
    if (_chargeRequest == null) return;
    _chargeRequest = null;
    _notify();
  }

  // ---------------------------------------------------------------- QR 결제

  /// QR 결제 정보를 읽고, 응답에 잔액이 있으면 그 값으로 맞춥니다.
  Future<QrPayInfo> qrPayInfo(QrPayload payload) async {
    final info = await _repository.qrPayInfo(
      payload.code,
      source: payload.source,
    );
    if (info.balance case final balance?) _setBalance(balance);
    return info;
  }

  /// 결제. 처리 중에 또 부르면 같은 결과를 기다립니다 (중복 제출 방지).
  ///
  /// - 응답을 못 받으면 같은 키로 1 · 2 · 4초 뒤 다시 보내고, `IDEMPOTENCY_IN_PROGRESS` 면 1초 뒤 다시 보냅니다.
  /// - 성공하면 잔액 = `balanceAfter`, 409 `INSUFFICIENT_CREDIT` 면 잔액 = 응답의 `balance`.
  /// - 그래도 결과를 모르면 마지막 예외를 던집니다. 화면은 같은 키로 "결과 다시 확인" 을 보냅니다.
  Future<PaymentReceipt> pay(
    PaymentRequest request, {
    required String idempotencyKey,
  }) => _payInFlight ??= _pay(
    request,
    idempotencyKey,
  ).whenComplete(() => _payInFlight = null);

  Future<PaymentReceipt> _pay(PaymentRequest request, String key) async {
    try {
      final receipt = await sendWithSameKey(
        () => _repository.pay(request, idempotencyKey: key),
        networkRetryDelays: paymentRetryDelays,
        wait: _wait,
      );
      _setBalance(receipt.balanceAfter);
      return receipt;
    } on PaymentException catch (error) {
      if (error.insufficientCredit case final shortage?) {
        _setBalance(shortage.balance);
      }
      rethrow;
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
