import '../data/models/public_settings.dart';

/// 충전 입금자명. 서버 설정의 규칙에 내 정보를 넣어 만듭니다 (APP-56).
///
/// - 학번이 있으면 [PublicSettings.depositorNameRule] (예: `{studentNo} {name}` → `2205 이재원`)
/// - 학번이 없으면(방문객) [PublicSettings.depositorNameRuleWithCode] (예: `{depositCode} {name}` → `V3071 김하린`)
///
/// 충전 요청을 만든 뒤에는 이 값 대신 서버가 준 `ChargeRequest.depositorName` 을 보여 줍니다.
String buildDepositorName(
  PublicSettings settings, {
  required String name,
  String? studentNo,
  String? depositCode,
}) {
  final hasStudentNo = studentNo != null && studentNo.trim().isNotEmpty;
  final rule = hasStudentNo
      ? settings.depositorNameRule
      : settings.depositorNameRuleWithCode;
  return rule
      .replaceAll('{studentNo}', studentNo?.trim() ?? '')
      .replaceAll('{depositCode}', depositCode?.trim() ?? '')
      .replaceAll('{name}', name.trim())
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
