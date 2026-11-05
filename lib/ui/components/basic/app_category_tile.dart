import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// 사진 대신 사용하는 48px 아이콘 타일. 라벨은 필요할 때만 표시합니다.
class AppCategoryTile extends StatelessWidget {
  const AppCategoryTile({
    super.key,
    required this.icon,
    this.label,
    this.highlighted = false,
    this.onTap,
  });

  final IconData icon;
  final String? label;
  final bool highlighted;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: onTap != null,
    child: Material(
      color: AppColors.canvas,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: highlighted
                    ? AppColors.weakBackground
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                size: 24,
                color: highlighted ? AppColors.primary : AppColors.body,
              ),
            ),
            if (label != null) ...[
              const SizedBox(height: 8),
              Text(
                label!,
                style: AppTypography.bodySmall.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.foreground,
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
