import 'package:bazaar_app/app.dart';
import 'package:bazaar_app/core/router/routes.dart';
import 'package:bazaar_app/ui/pages/booths/booths_page.dart';
import 'package:bazaar_app/ui/pages/dev/button_catalog_page.dart';
import 'package:bazaar_app/ui/pages/home/home_page.dart';
import 'package:bazaar_app/ui/pages/login/login_page.dart';
import 'package:bazaar_app/ui/pages/onboarding/onboarding_page.dart';
import 'package:bazaar_app/ui/pages/shell/main_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// 지금 라우터가 가리키는 경로
String _location(WidgetTester tester) {
  final context = tester.element(find.byType(Navigator).first);
  return GoRouter.of(context).routerDelegate.currentConfiguration.uri.path;
}

void main() {
  testWidgets('앱은 온보딩에서 시작한다', (tester) async {
    await tester.pumpWidget(const BazaarApp());
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingPage), findsOneWidget);
    expect(_location(tester), Routes.onboarding);
  });

  testWidgets('시작하기를 누르면 로그인으로 간다', (tester) async {
    await tester.pumpWidget(const BazaarApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('시작하기'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsOneWidget);
    expect(_location(tester), Routes.login);
  });

  testWidgets('건너뛰기를 눌러도 로그인으로 간다', (tester) async {
    await tester.pumpWidget(const BazaarApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('건너뛰기'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsOneWidget);
    expect(_location(tester), Routes.login);
  });

  testWidgets('로그인(임시)의 "홈으로 (임시)" → 하단 탭 5개가 있는 홈', (tester) async {
    await tester.pumpWidget(const BazaarApp(initialLocation: Routes.login));
    await tester.pumpAndSettle();

    await tester.tap(find.text('홈으로 (임시)'));
    await tester.pumpAndSettle();

    expect(find.byType(HomePage), findsOneWidget);
    expect(find.byType(MainShell), findsOneWidget);
    expect(_location(tester), Routes.home);

    final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(bar.destinations, hasLength(5));
    for (final label in ['홈', '부스', 'QR 결제', '지도', '마이']) {
      expect(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text(label),
        ),
        findsOneWidget,
      );
    }
  });

  testWidgets('탭을 누르면 해당 탭 화면으로 바뀐다', (tester) async {
    await tester.pumpWidget(const BazaarApp(initialLocation: Routes.home));
    await tester.pumpAndSettle();

    final tabs = {
      '부스': Routes.booths,
      'QR 결제': Routes.pay,
      '지도': Routes.map,
      '마이': Routes.my,
      '홈': Routes.home,
    };
    for (final MapEntry(key: label, value: path) in tabs.entries) {
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text(label),
        ),
      );
      await tester.pumpAndSettle();
      expect(_location(tester), path, reason: '$label 탭');
    }
    expect(find.byType(BoothsPage, skipOffstage: false), findsOneWidget);
  });

  testWidgets('디버그 빌드에서는 /dev/buttons 카탈로그가 열린다', (tester) async {
    await tester.pumpWidget(
      const BazaarApp(initialLocation: Routes.devButtons),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ButtonCatalogPage), findsOneWidget);
  });
}
