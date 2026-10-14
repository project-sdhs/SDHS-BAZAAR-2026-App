import 'package:bazaar_app/core/theme/app_colors.dart';
import 'package:bazaar_app/core/theme/app_theme.dart';
import 'package:bazaar_app/ui/components/buttons/buttons.dart';
import 'package:bazaar_app/ui/pages/onboarding/onboarding_page.dart';
import 'package:bazaar_app/ui/pages/onboarding/widgets/page_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 디자인 캔버스와 같은 390×844 화면에 온보딩을 그립니다.
Future<void> _pumpOnboarding(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(theme: AppTheme.light, home: const OnboardingPage()),
  );
}

void main() {
  testWidgets('제목 · 설명 · 단계 3개가 보인다', (tester) async {
    await _pumpOnboarding(tester);

    expect(find.text('종이 토큰 대신\n크레딧으로 결제해요'), findsOneWidget);
    expect(
      find.text('거스름돈을 세거나 토큰을 잃어버릴 일이 없어요.\n계좌이체 한 번이면 충전이 끝납니다.'),
      findsOneWidget,
    );

    for (final step in OnboardingPage.steps) {
      expect(find.text(step.title), findsOneWidget);
      expect(find.text(step.desc), findsOneWidget);
    }
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('입금자명 예시는 실제 학생 대신 “학번 이름” 자리 표시로 보인다', (tester) async {
    await _pumpOnboarding(tester);
    expect(find.textContaining('“학번 이름”'), findsOneWidget);
    expect(find.text('입금자명을 “학번 이름” 형식으로 보내요'), findsOneWidget);
    // 학번처럼 보이는 네 자리 숫자가 화면에 없어야 합니다.
    expect(find.textContaining(RegExp(r'\d{4}')), findsNothing);
  });

  testWidgets('일러스트 자리: 가로 꽉 참, 높이 160, 라디우스 16', (tester) async {
    await _pumpOnboarding(tester);

    final box = find.byWidgetPredicate(
      (widget) =>
          widget is Container &&
          widget.decoration is BoxDecoration &&
          (widget.decoration! as BoxDecoration).color == AppColors.placeholder,
    );
    expect(tester.getSize(box), const Size(390 - 16 * 2, 160));
    expect(
      (tester.widget<Container>(box).decoration! as BoxDecoration).borderRadius,
      BorderRadius.circular(16),
    );
  });

  testWidgets('건너뛰기는 오른쪽 위 56 높이 바 안에 있다', (tester) async {
    await _pumpOnboarding(tester);

    final skip = tester.getRect(find.text('건너뛰기'));
    expect(skip.right, 390 - 16);
    expect(skip.center.dy, 56 / 2);
  });

  testWidgets('페이지 점은 첫 번째가 활성, 아래에 xlarge "시작하기" 버튼', (tester) async {
    await _pumpOnboarding(tester);

    final indicator = tester.widget<PageIndicator>(find.byType(PageIndicator));
    expect(indicator.index, 0);
    expect(indicator.count, OnboardingPage.pageCount);

    final cta = tester.getRect(find.widgetWithText(AppButton, '시작하기'));
    expect(cta.height, 56);
    expect(cta.width, 390 - 16 * 2);
    expect(cta.bottom, 844 - 34);

    // 페이지 점은 CTA 영역 바로 위, 16 띄움
    final dots = tester.getRect(find.byType(PageIndicator));
    final ctaArea = tester.getRect(find.byType(BottomCTA));
    expect(ctaArea.top - dots.bottom, 16);
  });
}
