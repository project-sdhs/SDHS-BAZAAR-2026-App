/// 내 크레딧 (`GET /me/credit`).
class CreditSummary {
  const CreditSummary({
    required this.balance,
    required this.used,
    required this.pendingChargeAmount,
    required this.asOf,
  });

  factory CreditSummary.fromJson(Map<String, Object?> json) => CreditSummary(
    balance: json['balance']! as int,
    used: json['used']! as int,
    pendingChargeAmount: json['pendingChargeAmount']! as int,
    asOf: DateTime.parse(json['asOf']! as String),
  );

  /// 잔액 (원장 합계)
  final int balance;

  /// 이번 바자회 사용액 (결제 − 환불)
  final int used;

  /// 승인 전 충전 요청 금액 합계 (잔액에 들어 있지 않음)
  final int pendingChargeAmount;

  /// 서버가 계산한 시각 (UTC)
  final DateTime asOf;
}
