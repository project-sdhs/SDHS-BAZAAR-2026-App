import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// 안내 띠의 색 조합.
enum AppNoticeTone {
  /// 파란 면 · 진한 파랑 글자. 예: "크레딧은 빠져나가지 않았어요"
  info(
    background: AppColors.weakBackground,
    foreground: AppColors.weakForeground,
    iconColor: AppColors.primary,
  ),

  /// 연한 빨강 면 · 빨간 글자. 예: 결제 실패 이유
  danger(
    background: AppColors.dangerWeak,
    foreground: AppColors.danger,
    iconColor: AppColors.danger,
  ),

  /// 회색 면 · 본문 글자
  neutral(
    background: AppColors.surface,
    foreground: AppColors.body,
    iconColor: AppColors.muted,
  );

  const AppNoticeTone({
    required this.background,
    required this.foreground,
    required this.iconColor,
  });

  final Color background;
  final Color foreground;
  final Color iconColor;
}

/// 화면 안에 넣는 한 줄 안내 띠 (QR 결제 실패 화면의 "크레딧은 빠져나가지 않았어요").
///
/// ```dart
/// const AppNotice('크레딧은 빠져나가지 않았어요', icon: Icons.check_circle)
/// AppNotice(error, tone: AppNoticeTone.danger)
/// ```
class AppNotice extends StatelessWidget {
  const AppNotice(
    this.message, {
    super.key,
    this.icon,
    this.tone = AppNoticeTone.info,
  });

  final String message;
  final IconData? icon;
  final AppNoticeTone tone;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.s16,
      vertical: 14,
    ),
    decoration: BoxDecoration(
      color: tone.background,
      borderRadius: BorderRadius.circular(AppRadius.r14),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, size: 20, color: tone.iconColor),
          ),
          const SizedBox(width: AppSpacing.s8),
        ],
        Expanded(
          child: Text(
            message,
            style: AppTypography.body.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: tone.foreground,
            ),
          ),
        ),
      ],
    ),
  );
}
