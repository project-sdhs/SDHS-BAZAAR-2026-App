import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 하단 탭 5개를 감싸는 틀. 탭 화면들은 [navigationShell] 안에 그려집니다.
///
/// 탭 순서는 `app_router.dart` 의 `branches` 순서와 같아야 합니다.
/// (탭 바 디자인은 이후 PR 에서 다듬습니다. 지금은 기본 NavigationBar)
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onTap(int index) {
    // 지금 탭을 한 번 더 누르면 그 탭의 첫 화면으로 돌아갑니다.
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onTap,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: '홈',
          ),
          NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront),
            label: '부스',
          ),
          NavigationDestination(
            icon: Icon(Icons.qr_code_scanner),
            label: 'QR 결제',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: '지도',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: '마이',
          ),
        ],
      ),
    );
  }
}
