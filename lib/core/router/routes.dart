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

  /// 크레딧 충전 (하단 탭 바 없이 전체 화면)
  static const String credit = '/credit';

  /// 거래 내역 (하단 탭 바 없이 전체 화면)
  static const String transactions = '/my/transactions';

  /// QR 결제: 메뉴 고르기 → 결제 → 영수증. `extra` 로 `QrPayInfo` 를 넘깁니다 (없으면 QR 탭으로).
  static const String checkout = '/pay/checkout';

  /// QR 결제: 주문을 멈췄거나 운영 시간이 아닌 부스 안내. `extra` 로 `BoothPauseNotice` 를 넘깁니다.
  static const String payPaused = '/pay/paused';

  /// 부스 검색 (하단 탭 바 없이 전체 화면)
  static const String boothSearch = '/booths/search';

  static const String boothDetailPattern = '/booths/:boothId';

  static String boothDetail(String boothId) => '$booths/$boothId';

  /// 버튼 카탈로그 (디버그 빌드에서만 등록됩니다)
  static const String devButtons = '/dev/buttons';
  static const String devBasics = '/dev/basics';

  /// 입력 · 피드백 카탈로그 (디버그 빌드에서만 등록됩니다)
  static const String devInputFeedback = '/dev/input-feedback';

  /// 부스 카드(BoothView) 카탈로그 (디버그 빌드에서만 등록됩니다)
  static const String devBoothView = '/dev/booth-view';
}
