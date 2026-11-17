import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../components/booth_view/booth_views.dart';

/// 부스 카드 카탈로그 (개발용, 디버그 빌드에서만 `/dev/booth-view` 로 열림).
class BoothViewCatalogPage extends StatelessWidget {
  const BoothViewCatalogPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('부스 카드 카탈로그')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s16),
        children: [
          const _Section('list · 가득 × 176 (순위 없음)'),
          const Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.screenHorizontal,
            ),
            child: BoothView(
              name: '1-2 컵밥분식',
              category: '한식',
              locationLabel: '본관 3층 복도',
              minPrice: 1000,
              orderCount: 54,
              fallbackColor: Color(0xFF2F6B4F),
            ),
          ),
          const SizedBox(height: AppSpacing.s24),
          const _Section('home · 264 × 180 (순위 배지)'),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenHorizontal,
            ),
            child: Row(
              spacing: AppSpacing.s8,
              children: const [
                BoothView(
                  name: '3-1 로제떡볶이',
                  category: '분식',
                  locationLabel: '본관 1층 로비',
                  minPrice: 1500,
                  orderCount: 128,
                  rank: 1,
                  size: BoothViewSize.home,
                  fallbackColor: Color(0xFFC25B3F),
                ),
                BoothView(
                  name: '2-3 타코야끼',
                  category: '간식',
                  locationLabel: '신관 2층 복도',
                  minPrice: 200,
                  orderCount: 97,
                  rank: 2,
                  size: BoothViewSize.home,
                  fallbackColor: Color(0xFFD99A2B),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s24),
          const _Section('map · 264 × 176 (주문 수 없음, 이름 길 때)'),
          const SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.screenHorizontal,
            ),
            child: BoothView(
              name: '학생회 굿즈샵과 아주 긴 이름의 부스',
              category: '체험',
              locationLabel: '본관 1층 로비',
              minPrice: 2000,
              size: BoothViewSize.map,
              fallbackColor: Color(0xFF3A5BA9),
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenHorizontal,
        0,
        AppSpacing.screenHorizontal,
        AppSpacing.s8,
      ),
      child: Text(
        title,
        style: AppTypography.bodySmall.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.muted,
        ),
      ),
    );
  }
}
