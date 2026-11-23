/// 거래 종류 (명세 `Transaction.type`).
enum TransactionType {
  /// 계좌이체 충전
  charge,

  /// 부스 결제
  purchase,

  /// 결제 환불
  refund,

  /// 운영진의 크레딧 조정
  adjustment;

  static TransactionType parse(String value) => switch (value) {
    'charge' => charge,
    'purchase' => purchase,
    'refund' => refund,
    'adjustment' => adjustment,
    _ => throw FormatException('알 수 없는 거래 종류예요: $value'),
  };
}

/// 거래 상태 (명세 `Transaction.status`). 충전은 pending ~ rejected, 결제는 completed · refunded.
enum TransactionStatus {
  pending,
  needsReview,
  approved,
  rejected,
  completed,
  refunded;

  static TransactionStatus parse(String value) => switch (value) {
    'pending' => pending,
    'needs_review' => needsReview,
    'approved' => approved,
    'rejected' => rejected,
    'completed' => completed,
    'refunded' => refunded,
    _ => throw FormatException('알 수 없는 거래 상태예요: $value'),
  };
}

/// 거래 내역 탭 필터 (`GET /transactions?type=`).
enum TransactionFilter {
  /// 충전 (크레딧 조정 포함)
  charge,

  /// 구매 (환불 포함)
  purchase,
}

/// 거래 내역 한 줄.
class CreditTransaction {
  const CreditTransaction({
    required this.id,
    required this.type,
    required this.title,
    required this.occurredAt,
    required this.status,
    required this.amount,
    required this.refId,
    this.subtitle,
  });

  factory CreditTransaction.fromJson(Map<String, Object?> json) =>
      CreditTransaction(
        id: json['id']! as String,
        type: TransactionType.parse(json['type']! as String),
        title: json['title']! as String,
        subtitle: json['subtitle'] as String?,
        occurredAt: DateTime.parse(json['occurredAt']! as String),
        status: TransactionStatus.parse(json['status']! as String),
        amount: json['amount']! as int,
        refId: json['refId']! as int,
      );

  /// 목록 안에서 유일한 id. 예: `payment-5702`, `charge-498`
  final String id;
  final TransactionType type;

  /// 부스 이름 또는 `크레딧 충전`
  final String title;

  /// 메뉴 요약 또는 입금자명
  final String? subtitle;

  /// 거래 시각 (UTC). 화면에는 서울 시각으로 표시합니다.
  final DateTime occurredAt;
  final TransactionStatus status;

  /// 부호 있는 금액 (충전 · 환불 +, 결제 −)
  final int amount;

  /// 원본 id (결제 id 또는 충전 요청 id)
  final int refId;
}

/// 충전 · 사용 합계. 첫 페이지에만 옵니다.
class TransactionSummary {
  const TransactionSummary({required this.chargeTotal, required this.useTotal});

  factory TransactionSummary.fromJson(Map<String, Object?> json) =>
      TransactionSummary(
        chargeTotal: json['chargeTotal']! as int,
        useTotal: json['useTotal']! as int,
      );

  /// 승인된 충전 합계
  final int chargeTotal;

  /// 사용 합계 (결제 − 환불)
  final int useTotal;
}

/// 거래 내역 한 페이지 (`GET /transactions`). 서버가 준 순서(최신 먼저) 그대로입니다.
class TransactionPage {
  const TransactionPage({required this.items, this.nextCursor, this.summary});

  factory TransactionPage.fromJson(Map<String, Object?> json) {
    final items = json['items'];
    if (items is! List) {
      throw const FormatException('거래 내역 응답에 items 가 없어요');
    }
    final summary = json['summary'];
    return TransactionPage(
      items: [
        for (final item in items.cast<Map<String, Object?>>())
          CreditTransaction.fromJson(item),
      ],
      nextCursor: json['nextCursor'] as String?,
      summary: summary == null
          ? null
          : TransactionSummary.fromJson(summary as Map<String, Object?>),
    );
  }

  final List<CreditTransaction> items;

  /// 다음 페이지 커서. 마지막 페이지면 null.
  final String? nextCursor;
  final TransactionSummary? summary;
}
