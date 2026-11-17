import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// 부스 목록 맨 위: 제목, 열려 있는 부스 수, 검색 진입 바 (APP-25).
class BoothListHeader extends StatelessWidget {
  const BoothListHeader({
    super.key,
    required this.onSearchTap,
    this.openBoothCount,
  });

  /// 열려 있는 부스 수. 아직 모르면 null 로 두고, 안내 문장은 숨깁니다.
  final int? openBoothCount;

  /// 검색 진입 바를 눌렀을 때. 부스 검색 화면으로 이동합니다.
  final VoidCallback onSearchTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.s16),
          const Text('부스', style: AppTypography.h3),
          if (openBoothCount != null) ...[
            const SizedBox(height: AppSpacing.s4),
            Text(
              '학년별 $openBoothCount곳이 열려 있어요',
              style: AppTypography.body.copyWith(color: AppColors.muted),
            ),
          ],
          const SizedBox(height: AppSpacing.s16),
          BoothSearchEntry(onTap: onSearchTap),
        ],
      ),
    );
  }
}

/// 눌러서 검색 화면으로 가는 검색 모양의 바. 여기서 직접 입력하지는 않습니다.
class BoothSearchEntry extends StatelessWidget {
  const BoothSearchEntry({super.key, required this.onTap});

  static const String hintText = '반 · 부스 · 메뉴 검색';

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '부스 검색',
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.r16),
          ),
          child: Row(
            spacing: AppSpacing.s8,
            children: [
              const Icon(Icons.search, size: 24, color: AppColors.muted),
              Expanded(
                child: Text(
                  hintText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body.copyWith(color: AppColors.muted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
