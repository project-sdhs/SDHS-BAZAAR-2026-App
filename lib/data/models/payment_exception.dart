import '../../core/utils/seoul_time.dart';
import '../api/api_client.dart';
import 'payment.dart';

/// 크레딧 · 결제 API 가 돌려주는 에러 code (명세 "공통 에러 응답").
///
/// 처리는 항상 code 로 나누고, message 는 사람에게 보여 줄 때만 씁니다.
abstract final class PaymentErrorCode {
  static const validationFailed = 'VALIDATION_FAILED';
  static const notFound = 'NOT_FOUND';
  static const qrInvalid = 'QR_INVALID';
  static const orderingPaused = 'ORDERING_PAUSED';
  static const boothClosed = 'BOOTH_CLOSED';
  static const eventEnded = 'EVENT_ENDED';
  static const insufficientCredit = 'INSUFFICIENT_CREDIT';
  static const menuChanged = 'MENU_CHANGED';
  static const idempotencyInProgress = 'IDEMPOTENCY_IN_PROGRESS';
  static const rateLimited = 'RATE_LIMITED';
  static const appNotOpen = 'APP_NOT_OPEN';
}

/// 크레딧 · 결제 API 의 에러 응답. [ApiException] 을 그대로 옮기고 409 추가 필드를 읽기 쉽게 꺼냅니다.
class PaymentException implements Exception {
  const PaymentException({
    required this.code,
    required this.message,
    this.statusCode = 0,
    this.fields = const {},
    this.details = const {},
    this.retryAfter,
  });

  factory PaymentException.fromApi(ApiException error) => PaymentException(
    code: error.code,
    message: error.message,
    statusCode: error.statusCode,
    fields: error.fields,
    details: error.details,
    retryAfter: error.retryAfter,
  );

  final String code;
  final String message;
  final int statusCode;

  /// 필드별 이유 (`VALIDATION_FAILED`). 예: `fields['amount']`
  final Map<String, String> fields;

  /// 에러 본문 전체 (409 추가 필드 포함)
  final Map<String, Object?> details;

  /// `Retry-After` (429)
  final Duration? retryAfter;

  /// 409 `INSUFFICIENT_CREDIT` 의 {balance, total, shortfall}. 다른 code 거나 필드가 없으면 null.
  InsufficientCredit? get insufficientCredit =>
      code == PaymentErrorCode.insufficientCredit
      ? InsufficientCredit.tryParse(details)
      : null;

  /// 409 `ORDERING_PAUSED` 의 {pausedAt, booth}. 다른 code 면 null.
  OrderingPaused? get orderingPaused => code == PaymentErrorCode.orderingPaused
      ? OrderingPaused.fromJson(details)
      : null;

  /// 409 `MENU_CHANGED` 의 {serverTotal?, changedMenuIds}. 다른 code 면 null.
  MenuChanged? get menuChanged => code == PaymentErrorCode.menuChanged
      ? MenuChanged.fromJson(details)
      : null;

  @override
  String toString() => 'PaymentException($statusCode, $code): $message';
}

/// 잔액 부족: 지금 잔액 · 결제 합계 · 부족한 크레딧 (total − balance)
class InsufficientCredit {
  const InsufficientCredit({
    required this.balance,
    required this.total,
    required this.shortfall,
  });

  static InsufficientCredit? tryParse(Map<String, Object?> json) {
    final balance = json['balance'];
    final total = json['total'];
    if (balance is! int || total is! int) return null;
    final shortfall = json['shortfall'];
    return InsufficientCredit(
      balance: balance,
      total: total,
      shortfall: shortfall is int ? shortfall : total - balance,
    );
  }

  final int balance;
  final int total;
  final int shortfall;
}

/// 주문 정지: 멈춘 시각 · 부스
class OrderingPaused {
  const OrderingPaused({this.pausedAt, this.booth});

  factory OrderingPaused.fromJson(Map<String, Object?> json) {
    final pausedAt = json['pausedAt'];
    final booth = json['booth'];
    return OrderingPaused(
      pausedAt: pausedAt is String ? DateTime.tryParse(pausedAt) : null,
      booth: booth is Map<String, Object?> && booth['id'] is int
          ? BoothRef.fromJson(booth)
          : null,
    );
  }

  final DateTime? pausedAt;
  final BoothRef? booth;

  /// `14:05` 같은 서울 시각. 모르면 null.
  String? get pausedAtLabel =>
      pausedAt == null ? null : seoulHourMinute(pausedAt!);
}

/// 메뉴 변경: 지금 가격으로 다시 계산한 합계(품절 · 삭제가 있으면 null) · 바뀐 메뉴 id
class MenuChanged {
  const MenuChanged({this.serverTotal, this.changedMenuIds = const []});

  factory MenuChanged.fromJson(Map<String, Object?> json) {
    final ids = json['changedMenuIds'];
    final serverTotal = json['serverTotal'];
    return MenuChanged(
      serverTotal: serverTotal is int ? serverTotal : null,
      changedMenuIds: ids is List ? ids.whereType<int>().toList() : const [],
    );
  }

  final int? serverTotal;
  final List<int> changedMenuIds;
}
