/// 화면 경로(path) 상수. 경로 문자열은 여기에만 적고, 화면에서는 이름으로 씁니다.
///
/// 예: `context.go(Routes.home)`
abstract final class Routes {
  /// 앱을 처음 켜면 보이는 소개 화면
  static const String onboarding = '/onboarding';
  static const String login = '/login';

  // 하단 탭 5개 (MainShell)
  static const String home = '/home';
  static const String booths = '/booths';
  static const String pay = '/pay';
  static const String map = '/map';
  static const String my = '/my';

  /// 버튼 카탈로그 (디버그 빌드에서만 등록됩니다)
  static const String devButtons = '/dev/buttons';
}
