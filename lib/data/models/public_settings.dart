import '../../core/utils/seoul_time.dart';

/// 충전 입금 계좌 (명세 `DepositAccount`).
class DepositAccount {
  const DepositAccount({
    required this.bank,
    required this.accountNo,
    required this.holder,
  });

  factory DepositAccount.fromJson(Map<String, Object?> json) => DepositAccount(
    bank: json['bank']! as String,
    accountNo: json['accountNo']! as String,
    holder: json['holder']! as String,
  );

  /// 은행 이름. 예: `예시은행`
  final String bank;

  /// 계좌번호. 예: `000-1234-5678-90`
  final String accountNo;

  /// 예금주. 예: `디지텍 학생회`
  final String holder;
}

/// 로그인 없이 읽는 공개 설정 (`GET /settings/public`).
class PublicSettings {
  const PublicSettings({
    required this.appOpen,
    required this.eventName,
    required this.eventStartDate,
    required this.eventEndDate,
    required this.depositorNameRule,
    required this.depositorNameRuleWithCode,
    required this.chargeMin,
    this.depositAccount,
    this.depositorNameExample,
    this.depositorNameExampleWithCode,
    this.chargeMax,
    this.balanceLimit,
  });

  factory PublicSettings.fromJson(Map<String, Object?> json) {
    final account = json['depositAccount'];
    return PublicSettings(
      appOpen: json['appOpen']! as bool,
      eventName: json['eventName']! as String,
      eventStartDate: parseSeoulDate(json['eventStartDate']! as String),
      eventEndDate: parseSeoulDate(json['eventEndDate']! as String),
      depositAccount: account == null
          ? null
          : DepositAccount.fromJson(account as Map<String, Object?>),
      depositorNameRule: json['depositorNameRule']! as String,
      depositorNameExample: json['depositorNameExample'] as String?,
      // 예전 명세에는 이 필드가 없어서, 없으면 API 페이지의 기본 규칙을 씁니다.
      depositorNameRuleWithCode:
          json['depositorNameRuleWithCode'] as String? ??
          '{depositCode} {name}',
      depositorNameExampleWithCode:
          json['depositorNameExampleWithCode'] as String?,
      chargeMin: json['chargeMin']! as int,
      chargeMax: json['chargeMax'] as int?,
      balanceLimit: json['balanceLimit'] as int?,
    );
  }

  /// false 면 앱 API 가 503 `APP_NOT_OPEN` 을 돌려줍니다.
  final bool appOpen;
  final String eventName;

  /// 바자회 시작 · 종료일 (서울 날짜, [seoulDay] 와 비교)
  final DateTime eventStartDate;
  final DateTime eventEndDate;

  /// 입금 계좌. 아직 정하지 않았으면 null.
  final DepositAccount? depositAccount;

  /// 학번이 있는 사람의 입금자명 규칙. 예: `{studentNo} {name}`
  final String depositorNameRule;
  final String? depositorNameExample;

  /// 학번이 없는 사람(방문객)의 입금자명 규칙. 예: `{depositCode} {name}`
  final String depositorNameRuleWithCode;
  final String? depositorNameExampleWithCode;

  /// 1회 충전 최소 · 최대 (최대가 null 이면 제한 없음)
  final int chargeMin;
  final int? chargeMax;

  /// 1인 보유 한도: 잔액 + 확인 중인 충전 + 새 충전 ≤ 한도 (null 이면 제한 없음)
  final int? balanceLimit;

  /// 서울 날짜로 [now] 가 종료일을 지났는지.
  bool hasEndedAt(DateTime now) => seoulDay(now).isAfter(eventEndDate);
}
