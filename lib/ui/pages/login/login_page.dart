import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../components/buttons/buttons.dart';
// [뒤로 이동 추가] 공통 상단바를 로그인 화면에 연결합니다.
import '../../navigation/app_top_bar.dart';

/// 로그인 화면 (임시). 실제 로그인은 이후 PR 에서 만듭니다.
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // [뒤로 이동 수정] 기존 제목/설명을 상단바로 표시합니다.
            // 상단바에 여백이 있으므로 버튼 영역에만 별도 여백을 줍니다.
            // const AppTopBar(title: '얼마를 충전할까요?', description: '계좌이체하면 바로 크레딧이 들어와요'),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.s16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // [뒤로 이동 수정] 홈에서도 로그인으로 돌아갈 수 있게 기록을 남깁니다.
                  AppButton(
                    '홈으로 (임시)',
                    onPressed: () => context.push(Routes.home),
                  ),
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
          ],
        ),
      ),
    );
  }
}
