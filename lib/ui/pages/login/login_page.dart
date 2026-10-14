import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../components/buttons/buttons.dart';

/// 로그인 화면 (임시). 실제 로그인은 이후 PR 에서 만듭니다.
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('로그인', style: AppTypography.h3),
              const SizedBox(height: AppSpacing.s8),
              Text(
                '준비 중',
                style: AppTypography.body.copyWith(color: AppColors.muted),
              ),
              const SizedBox(height: AppSpacing.s24),
              AppButton('홈으로 (임시)', onPressed: () => context.go(Routes.home)),
              if (kDebugMode) ...[
                const SizedBox(height: AppSpacing.s8),
                AppButton(
                  '버튼 카탈로그 (개발용)',
                  variant: AppButtonVariant.light,
                  onPressed: () => context.push(Routes.devButtons),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
