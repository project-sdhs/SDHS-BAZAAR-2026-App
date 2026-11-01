import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../buttons/app_button.dart';

/// 확인/취소 선택이 필요한 작업을 위한 공통 다이얼로그.
abstract final class AppDialog {
  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String message,
    String cancelLabel = '취소',
    String confirmLabel = '확인',
    AppButtonVariant confirmVariant = AppButtonVariant.fillPrimary,
    bool barrierDismissible = true,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          title,
          style: AppTypography.h4.copyWith(color: AppColors.foreground),
        ),
        content: Text(
          message,
          style: AppTypography.body.copyWith(color: AppColors.body),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(
          AppSpacing.s16,
          0,
          AppSpacing.s16,
          AppSpacing.s16,
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: AppButton(
                  cancelLabel,
                  size: AppButtonSize.medium,
                  variant: AppButtonVariant.light,
                  expand: true,
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                ),
              ),
              const SizedBox(width: AppSpacing.s8),
              Expanded(
                child: AppButton(
                  confirmLabel,
                  size: AppButtonSize.medium,
                  variant: confirmVariant,
                  expand: true,
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                ),
              ),
            ],
          ),
        ],
        backgroundColor: AppColors.canvas,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.r16),
        ),
      ),
    );
  }
}
