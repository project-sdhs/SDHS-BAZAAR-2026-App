import 'package:bazaar_app/app.dart';
import 'package:bazaar_app/ui/pages/home/home_page.dart';
import 'package:bazaar_app/ui/pages/login/login_page.dart';
import 'package:bazaar_app/ui/pages/onboarding/onboarding_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

Future<void> openLogin(WidgetTester tester) async {
  await tester.pumpWidget(const BazaarApp());
  await tester.pumpAndSettle();
  await tester.tap(find.text('시작하기'));
  await tester.pumpAndSettle();
  expect(find.byType(LoginPage), findsOneWidget);
}

Future<void> openHome(WidgetTester tester) async {
  await openLogin(tester);
  await tester.tap(find.text('홈으로 (임시)'));
  await tester.pumpAndSettle();
  expect(find.byType(HomePage), findsOneWidget);
}

Future<void> swipeBack(WidgetTester tester) async {
  final gesture = await tester.startGesture(const Offset(5, 250));
  await gesture.moveBy(const Offset(30, 0));
  await tester.pump();
  await gesture.moveBy(const Offset(600, 0));
  await tester.pump();
  await gesture.up();
  await tester.pumpAndSettle();
}

void main() {
  // [리뷰 1] 로그인 상단바가 실제 표시되고 원래 문구를 사용하는지 확인
  testWidgets('상단 뒤로 버튼: 로그인에서 온보딩으로 복귀', (tester) async {
    await openLogin(tester);
    expect(find.text('로그인'), findsOneWidget);
    expect(find.text('준비 중'), findsOneWidget);
    expect(find.text('얼마를 충전할까요?'), findsNothing);
    await tester.tap(find.byTooltip('뒤로가기'));
    await tester.pumpAndSettle();
    expect(find.byType(OnboardingPage), findsOneWidget);
  });

  // [리뷰 2·3] 로그인 완료 후에는 로그인 기록과 홈의 뒤로 버튼이 없음
  testWidgets('홈에서는 뒤로 버튼과 이전 로그인 기록이 없다', (tester) async {
    await openHome(tester);
    final context = tester.element(find.byType(HomePage));
    expect(GoRouter.of(context).canPop(), isFalse);
    expect(find.byTooltip('뒤로가기'), findsNothing);
    expect(find.byType(LoginPage, skipOffstage: false), findsNothing);
    expect(find.byType(OnboardingPage, skipOffstage: false), findsNothing);
  });

  // [리뷰 2] 시스템 뒤로 이벤트를 받아도 홈에서 로그인으로 복귀 X
  testWidgets('Android 시스템 뒤로: 홈에서 로그인으로 돌아가지 않는다', (tester) async {
    await openHome(tester);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(HomePage), findsOneWidget);
    expect(find.byType(LoginPage, skipOffstage: false), findsNothing);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('iOS 가장자리 스와이프: 로그인에서 온보딩으로 복귀', (tester) async {
    await openLogin(tester);
    final context = tester.element(find.byType(LoginPage));
    expect(Theme.of(context).platform, TargetPlatform.iOS);
    expect(ModalRoute.of(context)!.popGestureEnabled, isTrue);
    expect(find.byType(CupertinoPageTransition), findsWidgets);
    await swipeBack(tester);
    expect(find.byType(OnboardingPage), findsOneWidget);
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  // [리뷰 2] 스와이프를 해도 로그인 완료 이전 화면은 나타나지 않음
  testWidgets('iOS 가장자리 스와이프: 홈에서 로그인으로 돌아가지 않는다', (tester) async {
    await openHome(tester);
    await swipeBack(tester);
    expect(find.byType(HomePage), findsOneWidget);
    expect(find.byType(LoginPage, skipOffstage: false), findsNothing);
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));
}
