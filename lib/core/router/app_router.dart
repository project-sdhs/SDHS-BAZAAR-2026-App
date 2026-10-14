import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../../ui/pages/booths/booths_page.dart';
import '../../ui/pages/dev/button_catalog_page.dart';
import '../../ui/pages/home/home_page.dart';
import '../../ui/pages/login/login_page.dart';
import '../../ui/pages/map/map_page.dart';
import '../../ui/pages/my/my_page.dart';
import '../../ui/pages/onboarding/onboarding_page.dart';
import '../../ui/pages/pay/pay_page.dart';
import '../../ui/pages/shell/main_shell.dart';
import 'routes.dart';

/// 앱의 모든 화면 경로를 등록하는 곳.
///
/// 새 화면을 만들면
/// 1. `routes.dart` 에 경로 상수를 추가하고
/// 2. 아래 `routes` 목록에 `GoRoute` 를 추가합니다.
///    하단 탭 안에 들어가는 화면이면 해당 탭의 `StatefulShellBranch` 안에 넣습니다.
GoRouter createAppRouter({String? initialLocation}) {
  return GoRouter(
    initialLocation: initialLocation ?? Routes.onboarding,
    routes: [
      GoRoute(
        path: Routes.onboarding,
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: Routes.login,
        builder: (context, state) => const LoginPage(),
      ),

      // 하단 탭 5개. 탭마다 화면 기록(스택)을 따로 기억합니다.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.home,
                builder: (context, state) => const HomePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.booths,
                builder: (context, state) => const BoothsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.pay,
                builder: (context, state) => const PayPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.map,
                builder: (context, state) => const MapPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.my,
                builder: (context, state) => const MyPage(),
              ),
            ],
          ),
        ],
      ),

      // 개발용 화면은 디버그 빌드에서만 등록합니다.
      if (kDebugMode)
        GoRoute(
          path: Routes.devButtons,
          builder: (context, state) => const ButtonCatalogPage(),
        ),
    ],
  );
}
