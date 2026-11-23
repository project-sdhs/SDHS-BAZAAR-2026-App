import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import 'search_section_title.dart';

/// 최근 검색어: 제목 + `모두 지우기` + 지울 수 있는 칩들 (APP-39).
///
/// 검색어가 하나도 없으면 아무것도 그리지 않습니다.
class RecentSearchesSection extends StatelessWidget {
  const RecentSearchesSection({
    super.key,
    required this.keywords,
    required this.onSelected,
    required this.onRemoved,
    required this.onClearAll,
  });

  final List<String> keywords;

  /// 칩을 눌렀을 때 (그 검색어로 다시 검색)
  final ValueChanged<String> onSelected;

  /// 칩의 X 를 눌렀을 때
  final ValueChanged<String> onRemoved;
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) {
    if (keywords.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SearchSectionTitle(
          '최근 검색어',
          bottomSpacing: 12,
          trailing: Semantics(
            button: true,
            label: '최근 검색어 모두 지우기',
            excludeSemantics: true,
            onTap: onClearAll,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onClearAll,
              child: Text(
                '모두 지우기',
                style: AppTypography.bodySmall.copyWith(color: AppColors.muted),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenHorizontal,
          ),
          child: Wrap(
            spacing: AppSpacing.s8,
            runSpacing: AppSpacing.s8,
            children: [
              for (final keyword in keywords)
                _KeywordChip(
                  keyword: keyword,
                  onTap: () => onSelected(keyword),
                  onRemove: () => onRemoved(keyword),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 높이 38 · 모서리 10 · 좌우 14 · 글자와 X 사이 6 (Figma).
class _KeywordChip extends StatelessWidget {
  const _KeywordChip({
    required this.keyword,
    required this.onTap,
    required this.onRemove,
  });

  final String keyword;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.r10),
      ),
      child: SizedBox(
        height: 38,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.only(left: 14, right: 6),
                  // widthFactor: 칩이 글자 너비만큼만 차지하게 합니다 (없으면 한 줄을 가득 채움).
                  child: Center(
                    widthFactor: 1,
                    child: Text(
                      keyword,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall.copyWith(
                        fontSize: 15,
                        color: AppColors.body,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Semantics(
              button: true,
              label: '$keyword 삭제',
              excludeSemantics: true,
              onTap: onRemove,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onRemove,
                child: const Padding(
                  padding: EdgeInsets.only(right: 14),
                  child: Icon(Icons.close, size: 16, color: AppColors.muted),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
