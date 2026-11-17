import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// 검색 화면 구역 제목 (`최근 검색어`, `실시간 인기 검색`).
///
/// Figma: Pretendard 700 / 15 / muted, 좌우 16 · 아래 8. 오른쪽에 [trailing] 을 둘 수 있습니다.
class SearchSectionTitle extends StatelessWidget {
  const SearchSectionTitle(this.title, {super.key, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenHorizontal,
        0,
        AppSpacing.screenHorizontal,
        AppSpacing.s8,
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
