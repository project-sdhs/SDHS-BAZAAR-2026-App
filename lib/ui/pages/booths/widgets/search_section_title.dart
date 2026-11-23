import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// 검색 화면 구역 제목 (`최근 검색어`, `실시간 인기 검색`).
///
/// Figma: Pretendard 700 / 15 / muted, 좌우 16 · 아래 [bottomSpacing](기본 8).
/// 오른쪽에 [trailing] 을 둘 수 있습니다.
class SearchSectionTitle extends StatelessWidget {
  const SearchSectionTitle(
    this.title, {
    super.key,
    this.trailing,
    this.bottomSpacing = AppSpacing.s8,
  });

  final String title;
  final Widget? trailing;

  /// 제목 아래 간격. 최근 검색어는 칩과 12 (Figma).
  final double bottomSpacing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenHorizontal,
        0,
        AppSpacing.screenHorizontal,
        bottomSpacing,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: AppTypography.bodySmall.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.muted,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
