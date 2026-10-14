import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../components/buttons/buttons.dart';
import 'widgets/page_indicator.dart';

/// 온보딩 1페이지 (디자인 캔버스 `Onboarding` 보드, 390×844).
///
/// 위에서부터: 건너뛰기 바 → 일러스트 자리 → 제목 · 설명 → 단계 3개
/// → 페이지 점 → 하단 "시작하기" 버튼.
class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  /// 온보딩 전체 장 수 (디자인의 페이지 점 개수)
  static const int pageCount = 2;

  static const List<({String title, String desc})> steps = [
    (title: '학번과 이름으로 계좌이체', desc: '입금자명을 “학번 이름” 형식으로 보내요'),
    (title: '입금 내역이 자동으로 매칭', desc: '동아리 계좌 내역과 학번을 대조해요'),
    (title: '크레딧으로 바로 충전', desc: '계정이 없으면 부스의 QR로 결제해요'),
  ];

  /// 26 / 39 · 700, 자간 -0.02em
  static const TextStyle _titleStyle = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: 26,
    height: 39 / 26,
    fontWeight: FontWeight.w700,
    letterSpacing: 26 * -0.02,
    leadingDistribution: TextLeadingDistribution.even,
    color: AppColors.foreground,
  );

  void _goToLogin(BuildContext context) => context.go(Routes.login);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        // 아래 안전 영역은 BottomCTA 가 직접 챙깁니다.
        bottom: false,
        child: Column(
          children: [
            _TopBar(onSkip: () => _goToLogin(context)),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.s16,
                  AppSpacing.s16,
                  AppSpacing.s16,
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 일러스트가 들어갈 자리
                    Container(
                      width: double.infinity,
                      height: 160,
                      decoration: BoxDecoration(
                        color: AppColors.placeholder,
                        borderRadius: BorderRadius.circular(AppRadius.r16),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s32),
                    const Text('종이 토큰 대신\n크레딧으로 결제해요', style: _titleStyle),
                    const SizedBox(height: 12),
                    Text(
                      '거스름돈을 세거나 토큰을 잃어버릴 일이 없어요.\n'
                      '계좌이체 한 번이면 충전이 끝납니다.',
                      style: AppTypography.body.copyWith(color: AppColors.body),
                    ),
                    const SizedBox(height: 28),
                    Column(
                      spacing: 20,
                      children: [
                        for (var i = 0; i < steps.length; i++)
                          _StepRow(
                            number: i + 1,
                            title: steps[i].title,
                            desc: steps[i].desc,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.s16),
              child: PageIndicator(count: pageCount, index: 0),
            ),
            BottomCTA(
              buttons: [
                AppButton('시작하기', onPressed: () => _goToLogin(context)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 높이 56, 오른쪽 끝에 "건너뛰기".
class _TopBar extends StatelessWidget {
  const _TopBar({required this.onSkip});

  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Padding(
        // 글자 끝이 화면 끝에서 16 떨어지도록 (버튼 안쪽 여백 8 + 바깥 8)
        padding: const EdgeInsets.only(right: AppSpacing.s8),
        child: Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: onSkip,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.muted,
              overlayColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s8),
              minimumSize: const Size(0, 40),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              textStyle: const TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: const Text('건너뛰기'),
          ),
        ),
      ),
    );
  }
}

/// 번호 동그라미 + 제목 · 설명 한 줄.
class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.number,
    required this.title,
    required this.desc,
  });

  final int number;
  final String title;
  final String desc;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.weakBackground,
            shape: BoxShape.circle,
          ),
          child: Text(
            '$number',
            style: const TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.s16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: AppSpacing.s4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpacing.s4,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: AppColors.foreground,
                  ),
                ),
                Text(
                  desc,
                  style: AppTypography.body.copyWith(color: AppColors.muted),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
