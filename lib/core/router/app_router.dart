import 'package:go_router/go_router.dart';

import '../../ui/pages/home/home_page.dart';
import 'routes.dart';

/// 앱의 모든 화면 경로를 등록하는 곳.
///
/// 새 화면을 만들면
/// 1. `routes.dart` 에 경로 상수를 추가하고
/// 2. 아래 `routes` 목록에 `GoRoute` 를 추가합니다.
GoRouter createAppRouter({String? initialLocation}) {
  return GoRouter(
    initialLocation: initialLocation ?? Routes.home,
    routes: [
      GoRoute(path: Routes.home, builder: (context, state) => const HomePage()),
    ],
  );
}
