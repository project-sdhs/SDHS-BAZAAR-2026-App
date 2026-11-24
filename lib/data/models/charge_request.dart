import 'public_settings.dart';

/// 충전 요청 상태 (명세 `ChargeStatus`).
enum ChargeStatus {
  /// 입금을 기다리는 중
  pending,

  /// 30분째 입금이 없거나 자동 확인이 안 돼서 운영진이 보는 중
  needsReview,

  /// 승인 (잔액에 들어감)
  approved,

  /// 반려
  rejected;

  static ChargeStatus parse(String value) => switch (value) {
    'pending' => pending,
    'needs_review' => needsReview,
    'approved' => approved,
    'rejected' => rejected,
    _ => throw FormatException('알 수 없는 충전 상태예요: $value'),
  };

  /// 아직 결과가 나오지 않은 상태 (확인 중)
  bool get isWaiting => this == pending || this == needsReview;
}

/// 충전 요청 한 건 (`POST /credits/charge`, `GET /credits/charge/{id}`).
class ChargeRequest {
  const ChargeRequest({
    required this.id,
    required this.amount,
    required this.status,
    required this.depositorName,
    required this.requestedAt,
    this.depositAccount,
    this.reason,
    this.approvedAt,
    this.rejectedAt,
  });

  factory ChargeRequest.fromJson(Map<String, Object?> json) {
    final account = json['depositAccount'];
    return ChargeRequest(
      id: json['id']! as int,
      amount: json['amount']! as int,
      status: ChargeStatus.parse(json['status']! as String),
      depositorName: json['depositorName']! as String,
      depositAccount: account == null
          ? null
          : DepositAccount.fromJson(account as Map<String, Object?>),
      reason: json['reason'] as String?,
      requestedAt: DateTime.parse(json['requestedAt']! as String),
      approvedAt: _time(json['approvedAt']),
      rejectedAt: _time(json['rejectedAt']),
    );
  }

  final int id;
  final int amount;
  final ChargeStatus status;

  /// 입금할 때 써야 하는 입금자명 (서버가 설정 규칙으로 만든 값)
  final String depositorName;

  /// 이 요청의 입금 계좌
  final DepositAccount? depositAccount;

  /// 확인 필요 · 반려 사유
  final String? reason;
  final DateTime requestedAt;
  final DateTime? approvedAt;
  final DateTime? rejectedAt;

  static DateTime? _time(Object? value) =>
      value == null ? null : DateTime.parse(value as String);
}

/// 충전 요청 결과. [created] 가 false 면 이미 있던 대기 요청을 서버가 돌려준 것(200)입니다.
class ChargeResult {
  const ChargeResult({required this.request, required this.created});

  final ChargeRequest request;

  /// 201 이면 true (새로 만듦), 200 이면 false (이미 보낸 요청)
  final bool created;
}
