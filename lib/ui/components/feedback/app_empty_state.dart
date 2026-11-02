import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../buttons/app_button.dart';

/// 목록 또는 검색 결과가 비어 있을 때 표시하는 안내.
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.title,
    this.message,
    this.icon = Icons.search,
    this.actionLabel,
    this.onAction,
  }) : assert(
         actionLabel == null || onAction != null,
         'actionLabel 을 지정하면 onAction 도 지정해야 합니다.',
       );

  final String title;
  final String? message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.s24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.r16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.canvas,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 26, color: AppColors.muted),
              ),
              const SizedBox(height: AppSpacing.s16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTypography.body.copyWith(
                  color: AppColors.foreground,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (message != null) ...[
                const SizedBox(height: AppSpacing.s8),
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.muted,
                  ),
                ),
              ],
              if (actionLabel case final label?) ...[
                const SizedBox(height: AppSpacing.s24),
                AppButton(
                  label,
                  size: AppButtonSize.medium,
                  variant: AppButtonVariant.light,
                  onPressed: onAction,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
