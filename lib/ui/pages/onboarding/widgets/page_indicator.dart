import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// 여러 장짜리 화면에서 지금 몇 번째인지 보여 주는 점.
///
/// 지금 페이지는 파란 막대(20×6), 나머지는 회색 점(6×6).
/// ```dart
/// PageIndicator(count: 2, index: 0) // 2장 중 첫 번째
/// ```
class PageIndicator extends StatelessWidget {
  const PageIndicator({super.key, required this.count, required this.index})
    : assert(count > 0),
      assert(index >= 0 && index < count);

  /// 전체 페이지 수
  final int count;

  /// 지금 페이지 (0부터 셉니다)
  final int index;

  static const double dotSize = 6;
  static const double activeWidth = 20;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$count페이지 중 ${index + 1}페이지',
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: AppSpacing.s6,
          children: [
            for (var i = 0; i < count; i++)
              Container(
                width: i == index ? activeWidth : dotSize,
                height: dotSize,
                decoration: BoxDecoration(
                  color: i == index ? AppColors.primary : AppColors.border,
                  borderRadius: BorderRadius.circular(dotSize / 2),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
