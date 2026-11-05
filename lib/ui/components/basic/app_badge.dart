import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

enum AppBadgeVariant {
  neutral(AppColors.surface, AppColors.body),
  primary(AppColors.primary, AppColors.onPrimary),
  weak(AppColors.weakBackground, AppColors.weakForeground),
  dark(AppColors.foreground, AppColors.onPrimary),
  danger(AppColors.dangerWeak, AppColors.danger);

  const AppBadgeVariant(this.background, this.foreground);
  final Color background;
  final Color foreground;
}

/// 누를 수 없는 역할 · 상태 표시.
class AppBadge extends StatelessWidget {
  const AppBadge(
    this.label, {
    super.key,
    this.variant = AppBadgeVariant.neutral,
  });

  final String label;
  final AppBadgeVariant variant;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: variant.background,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
      child: Text(
        label,
        style: AppTypography.bodySmall.copyWith(
          color: variant.foreground,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}
