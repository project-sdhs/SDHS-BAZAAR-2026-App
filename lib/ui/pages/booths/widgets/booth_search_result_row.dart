import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../data/models/booth.dart';
import '../../../components/credit_amount/credit_amount.dart';
import '../../../components/feedback/feedback.dart';
import 'search_section_title.dart';

/// 검색 결과: `검색 결과 N` 제목 + 부스 행들 (APP-38). 결과가 없으면 안내 문구를 보여 줍니다.
class BoothSearchResults extends StatelessWidget {
  const BoothSearchResults({
    super.key,
    required this.booths,
    this.imageUrlOf,
    this.onBoothTap,
  });

  final List<Booth> booths;
  final String? Function(Booth booth)? imageUrlOf;
  final ValueChanged<Booth>? onBoothTap;

  @override
  Widget build(BuildContext context) {
    if (booths.isEmpty) return const _NoResults();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SearchSectionTitle('검색 결과 ${booths.length}'),
        for (final booth in booths)
          BoothSearchResultRow(
            booth: booth,
            imageUrl: imageUrlOf?.call(booth),
            onTap: onBoothTap == null ? null : () => onBoothTap!(booth),
          ),
      ],
    );
  }
}

/// 위아래 12 · 좌우 16 · 간격 16. 사진 56×56 모서리 14 (Figma).
class BoothSearchResultRow extends StatelessWidget {
  const BoothSearchResultRow({
    super.key,
    required this.booth,
    this.imageUrl,
    this.onTap,
  });

  final Booth booth;
  final String? imageUrl;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      label:
          '${booth.name}, ${booth.category}, ${booth.locationLabel}, '
          '${AppCreditAmount.format(booth.minPrice)}크레딧부터',
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenHorizontal,
            vertical: 12,
          ),
          child: Row(
            spacing: AppSpacing.s16,
            children: [
              _Photo(imageUrl: imageUrl),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 2,
                  children: [
                    Text(
                      booth.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.body.copyWith(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.17,
                        color: AppColors.foreground,
                      ),
                    ),
                    Row(
                      spacing: 6,
                      children: [
                        Flexible(child: _CategoryBadge(label: booth.category)),
                        Expanded(
                          child: Text(
                            booth.locationLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.muted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // 가격이 아주 길어도 이름 자리를 다 먹지 않도록 줄어듭니다.
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 140),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: AppCreditAmount(
                    amount: booth.minPrice,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    suffix: '~',
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

class _Photo extends StatelessWidget {
  const _Photo({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final fallback = const ColoredBox(color: AppColors.surface);
    final url = imageUrl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.r14),
      child: SizedBox(
        width: 56,
        height: 56,
        child: url == null
            ? fallback
            : Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => fallback,
              ),
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.r6),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.bodySmall.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.body,
        ),
      ),
    );
  }
}

class _NoResults extends StatelessWidget {
  const _NoResults();

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 260),
      child: const AppEmptyState(title: '검색 결과가 없어요', message: '다른 검색어로 찾아보세요'),
    );
  }
}
