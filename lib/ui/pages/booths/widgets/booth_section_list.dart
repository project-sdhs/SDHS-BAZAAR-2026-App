import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../data/models/booth.dart';
import '../../../../state/booth_list_logic.dart';
import '../../../components/booth_view/booth_views.dart';
import 'search_section_title.dart';

/// 학년별 부스 리스트: 학년 제목 + 그 학년의 부스 카드들 (APP-28).
///
/// 카드는 한 줄에 한 장, 부모 너비를 가득 채웁니다.
/// [imageUrlOf] 로 부스의 그림 주소를 정하고, 그림이 없으면 카드가 색으로 채워집니다.
class BoothSectionList extends StatelessWidget {
  const BoothSectionList({
    super.key,
    required this.sections,
    this.imageUrlOf,
    this.onBoothTap,
  });

  final List<BoothSection> sections;

  /// 부스의 이미지 주소를 돌려줍니다. null 이면 그림 없이 그립니다.
  final String? Function(Booth booth)? imageUrlOf;
  final ValueChanged<Booth>? onBoothTap;

  /// 카드 사이 세로 간격
  static const double cardGap = 12;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final section in sections) ...[
          SearchSectionTitle(
            section.title,
            trailing: Text(
              '${section.booths.length}곳',
              style: AppTypography.bodySmall.copyWith(color: AppColors.muted),
            ),
          ),
          for (final booth in section.booths)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenHorizontal,
                0,
                AppSpacing.screenHorizontal,
                cardGap,
              ),
              child: BoothView(
                name: booth.name,
                category: booth.category,
                locationLabel: booth.locationLabel,
                minPrice: booth.minPrice,
                thumbnail: _thumbnail(booth),
                onTap: onBoothTap == null ? null : () => onBoothTap!(booth),
              ),
            ),
          const SizedBox(height: AppSpacing.s16),
        ],
      ],
    );
  }

  ImageProvider? _thumbnail(Booth booth) {
    final url = imageUrlOf?.call(booth);
    return url == null ? null : NetworkImage(url);
  }
}
