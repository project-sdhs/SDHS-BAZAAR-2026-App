import 'package:bazaar_app/core/theme/app_colors.dart';
import 'package:bazaar_app/core/theme/app_spacing.dart';
import 'package:bazaar_app/core/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: _BottomTabBar(
        key: const Key('bottomTabBar'),
        currentIndex: navigationShell.currentIndex,
        onTabSelected: _onTap,
      ),
    );
  }
}

/// 탭 하나의 정보 (선택 / 미선택 아이콘을 따로 가짐)
class _TabSpec {
  const _TabSpec(this.label, this.icon, this.selectedIcon);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

class _BottomTabBar extends StatelessWidget {
  const _BottomTabBar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
  });

  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  /// 가운데 QR 결제 탭의 인덱스
  static const int _qrIndex = 2;
  static const String _qrLabel = 'QR 결제';

  static const List<_TabSpec?> _tabs = [
    _TabSpec('홈', Icons.home_outlined, Icons.home_rounded),
    _TabSpec('부스', Icons.storefront_outlined, Icons.storefront_rounded),
    null, // 가운데 QR 결제 (따로 그림)
    _TabSpec('지도', Icons.map_outlined, Icons.map_rounded),
    _TabSpec('마이', Icons.person_outline_rounded, Icons.person_rounded),
  ];

  // 바
  static const double _barHeight = 72;
  static const double _borderWidth = 1;

  // 일반 탭
  static const double _iconSize = 24;

  // 가운데 QR 버튼
  static const double _qrDiameter = 56;
  static const double _qrBorderWidth = 4;
  static const double _qrIconSize = 26;
  static const double _qrOverflow = 22; // 바 위로 튀어나오는 높이

  /// 탭 하나를 스크린리더가 "버튼"으로 읽고 선택 여부를 알 수 있게 감쌈
  Widget _tappable({
    required int index,
    required String label,
    required Widget child,
  }) {
    return Semantics(
      button: true,
      selected: currentIndex == index,
      label: label,
      excludeSemantics: true,
      onTap: () => onTabSelected(index),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onTabSelected(index),
          child: child,
        ),
      ),
    );
  }

  Widget _item(int index, _TabSpec tab) {
    final selected = currentIndex == index;
    final color = selected ? AppColors.foreground : AppColors.muted;

    return Expanded(
      child: _tappable(
        index: index,
        label: tab.label,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              selected ? tab.selectedIcon : tab.icon,
              size: _iconSize,
              color: color,
            ),
            const SizedBox(height: AppSpacing.s4),
            Text(
              tab.label,
              style: AppTypography.caption.copyWith(
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 가운데 칸: 아이콘 자리는 비워 두고 라벨만 (아이콘은 위로 띄운 원형 버튼)
  Widget _centerItem() {
    return Expanded(
      // 스크린리더에는 떠 있는 원형 버튼 하나만 'QR 결제' 로 읽히게 함
      child: ExcludeSemantics(
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onTabSelected(_qrIndex),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: _iconSize),
                const SizedBox(height: AppSpacing.s4),
                Text(
                  _qrLabel,
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _qrButton() {
    return _tappable(
      index: _qrIndex,
      label: _qrLabel,
      child: Container(
        width: _qrDiameter,
        height: _qrDiameter,
        decoration: BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.canvas, width: _qrBorderWidth),
        ),
        child: const Icon(
          Icons.qr_code_scanner_rounded,
          color: AppColors.onPrimary,
          size: _qrIconSize,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 바: 화면 너비 꽉 채움, 위쪽 1px 경계선만, 높이 72 + 아래 안전 영역
        Padding(
          padding: const EdgeInsets.only(top: _qrOverflow),
          child: DecoratedBox(
            decoration: const BoxDecoration(
              color: AppColors.canvas,
              border: Border(
                top: BorderSide(color: AppColors.border, width: _borderWidth),
              ),
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                height: _barHeight,
                child: Row(
                  children: [
                    for (var i = 0; i < _tabs.length; i++)
                      if (_tabs[i] case final tab?)
                        _item(i, tab)
                      else
                        _centerItem(),
                  ],
                ),
              ),
            ),
          ),
        ),
        // 가운데 QR 버튼: 바 위로 22 튀어나옴
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Center(child: _qrButton()),
        ),
      ],
    );
  }
}
