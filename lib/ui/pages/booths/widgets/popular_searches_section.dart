import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../data/models/popular_booth.dart';
import 'search_section_title.dart';

/// 실시간 인기 검색: 순위 · 부스 이름 · 주문 수 (APP-40).
///
/// 목록이 비어 있으면 아무것도 그리지 않습니다.
class PopularSearchesSection extends StatelessWidget {
  const PopularSearchesSection({
    super.key,
    required this.booths,
    required this.onSelected,
  });

  final List<PopularBooth> booths;

  /// 행을 눌렀을 때. 그 부스 이름으로 검색합니다.
  final ValueChanged<PopularBooth> onSelected;

  @override
  Widget build(BuildContext context) {
    if (booths.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SearchSectionTitle('실시간 인기 검색'),
        for (final booth in booths)
          _PopularRow(booth: booth, onTap: () => onSelected(booth)),
      ],
    );
  }
}

/// 위아래 10 · 좌우 16 · 간격 16. 순위 칸 폭 20 (Figma).
class _PopularRow extends StatelessWidget {
  const _PopularRow({required this.booth, required this.onTap});

  final PopularBooth booth;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${booth.rank}위 ${booth.name}, 주문 ${booth.paymentCount}',
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenHorizontal,
            vertical: 10,
          ),
          child: Row(
            spacing: AppSpacing.s16,
            children: [
              SizedBox(
                width: 20,
                child: Text(
                  '${booth.rank}',
                  style: AppTypography.body.copyWith(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  booth.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body.copyWith(
                    fontSize: 17,
                    color: AppColors.foreground,
                  ),
                ),
              ),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '주문 ${booth.paymentCount}',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.muted,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
