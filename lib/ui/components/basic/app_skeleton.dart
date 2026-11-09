import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// 응답을 기다리는 동안 보이는 정적인 자리 표시. 임의의 모션은 추가하지 않습니다.
class AppSkeleton extends StatelessWidget {
  const AppSkeleton({
    super.key,
    this.width,
    this.height = 14,
    this.radius = 6,
    this.color = AppColors.placeholder,
  });

  final double? width;
  final double height;
  final double radius;
  final Color color;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      ),
    ),
  );
}

/// 카테고리 타일과 글자 두 줄을 기다리는 목록 자리 표시.
class AppSkeletonList extends StatelessWidget {
  const AppSkeletonList({super.key, this.itemCount = 3});

  final int itemCount;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '목록을 불러오는 중',
    liveRegion: true,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < itemCount; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                const AppSkeleton(width: 48, height: 48, radius: 14),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FractionallySizedBox(
                        widthFactor: .55 + (i % 3) * .07,
                        child: const AppSkeleton(height: 16),
                      ),
                      const SizedBox(height: 8),
                      const FractionallySizedBox(
                        widthFactor: .88,
                        child: AppSkeleton(color: AppColors.surface),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}
