import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

enum AppToastType { success, error }

/// 성공 또는 오류 안내를 Scaffold 하단에 표시하는 공통 토스트.
abstract final class AppToast {
  static void show(
    BuildContext context, {
    required String message,
    AppToastType type = AppToastType.success,
    Duration duration = const Duration(seconds: 3),
  }) {
    final messenger = ScaffoldMessenger.of(context);
    final isError = type == AppToastType.error;
    final foregroundColor = isError ? AppColors.danger : AppColors.onPrimary;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                isError ? Icons.error : Icons.check_circle,
                color: foregroundColor,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.s8),
              Expanded(
                child: Text(
                  message,
                  style: AppTypography.body.copyWith(color: foregroundColor),
                ),
              ),
            ],
          ),
          duration: duration,
          behavior: SnackBarBehavior.floating,
          backgroundColor: isError
              ? AppColors.dangerWeak
              : AppColors.foreground,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.r14),
          ),
        ),
      );
  }
}
