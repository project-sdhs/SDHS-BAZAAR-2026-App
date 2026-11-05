import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// 학년 등 단일 필터. 선택 값은 부모가 관리합니다.
class AppChip extends StatelessWidget {
  const AppChip(
    this.label, {
    super.key,
    required this.onSelected,
    this.selected = false,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool>? onSelected;

  @override
  Widget build(BuildContext context) => FilterChip(
    label: Text(label),
    selected: selected,
    onSelected: onSelected,
    showCheckmark: false,
    backgroundColor: AppColors.surface,
    selectedColor: AppColors.foreground,
    disabledColor: AppColors.surface,
    side: BorderSide.none,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    labelStyle: AppTypography.bodySmall.copyWith(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: onSelected == null
          ? AppColors.muted
          : selected
          ? AppColors.onPrimary
          : AppColors.body,
    ),
  );
}
