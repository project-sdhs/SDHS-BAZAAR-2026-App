import 'package:bazaar_app/app.dart';
import 'package:bazaar_app/ui/pages/home/home_page.dart';
import 'package:bazaar_app/ui/pages/login/login_page.dart';
import 'package:bazaar_app/ui/pages/onboarding/onboarding_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> openLogin(WidgetTester tester) async {
  await tester.pumpWidget(const BazaarApp());
  await tester.pumpAndSettle();
  await tester.tap(find.text('시작하기'));
  await tester.pumpAndSettle();
  expect(find.byType(LoginPage), findsOneWidget);
}

void main() {
  testWidgets('상단 뒤로 버튼: 로그인에서 온보딩으로 복귀', (tester) async {
    await openLogin(tester);
    await tester.tap(find.byTooltip('뒤로가기'));
    await tester.pumpAndSettle();
    expect(find.byType(OnboardingPage), findsOneWidget);
  });

  testWidgets('상단 뒤로 버튼: 중첩 홈 탭에서 로그인으로 복귀', (tester) async {
    await openLogin(tester);
    await tester.tap(find.text('홈으로 (임시)'));
    await tester.pumpAndSettle();
    expect(find.byType(HomePage), findsOneWidget);
    await tester.tap(find.byTooltip('뒤로가기'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.byType(HomePage), findsNothing);
  });

  testWidgets('Android 시스템 뒤로 이벤트: 홈 → 로그인 → 온보딩', (tester) async {
    await openLogin(tester);
    await tester.tap(find.text('홈으로 (임시)'));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(LoginPage), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(OnboardingPage), findsOneWidget);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('iOS 가장자리 스와이프: 로그인에서 온보딩으로 복귀', (tester) async {
    await openLogin(tester);
    final pageContext = tester.element(find.byType(LoginPage));
    expect(Theme.of(pageContext).platform, TargetPlatform.iOS);
    expect(ModalRoute.of(pageContext)!.popGestureEnabled, isTrue);
    expect(find.byType(CupertinoPageTransition), findsWidgets);
    final gesture = await tester.startGesture(const Offset(5, 250));
    await gesture.moveBy(const Offset(30, 0));
    await tester.pump();
    await gesture.moveBy(const Offset(600, 0));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.byType(OnboardingPage), findsOneWidget);
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  testWidgets('iOS 가장자리 스와이프: 중첩 홈 탭에서 로그인으로 복귀', (tester) async {
    await openLogin(tester);
    await tester.tap(find.text('홈으로 (임시)'));
    await tester.pumpAndSettle();
    final gesture = await tester.startGesture(const Offset(5, 250));
    await gesture.moveBy(const Offset(30, 0));
    await tester.pump();
    await gesture.moveBy(const Offset(600, 0));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.byType(HomePage), findsNothing);
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));
}
