import 'package:bazaar_app/app.dart';
import 'package:bazaar_app/core/router/routes.dart';
import 'package:bazaar_app/ui/navigation/app_top_bar.dart';
import 'package:bazaar_app/ui/pages/booth_detail/booth_detail_page.dart';
import 'package:bazaar_app/ui/pages/booth_detail/widgets/booth_info_header.dart';
import 'package:bazaar_app/ui/pages/booth_detail/widgets/booth_operator_tile.dart';
import 'package:bazaar_app/ui/pages/booths/booths_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  Future<void> openDetailFromList(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(BazaarApp(initialLocation: Routes.booths));
    await tester.pumpAndSettle();
    GoRouter.of(tester.element(find.byType(BoothsPage)))
        .push(Routes.boothDetail('sample'));
    await tester.pumpAndSettle();
  }

  testWidgets('부스 상세는 제목 없는 상단 바(뒤로 · 공유)를 보여주고 하단 탭 바는 없다', (tester) async {
    await openDetailFromList(tester);

    expect(find.byType(BoothDetailPage), findsOneWidget);
    expect(find.byType(AppTopBar), findsOneWidget);
    expect(find.byTooltip('뒤로가기'), findsOneWidget);
    expect(find.byTooltip('공유'), findsOneWidget);
    expect(tester.getSize(find.byType(AppTopBar)).height, 49);
    expect(find.byKey(const Key('bottomTabBar')), findsNothing);
  });

  testWidgets('상단 바 아래에 부스 기본 정보를 보여준다', (tester) async {
    await openDetailFromList(tester);

    expect(find.byType(BoothInfoHeader), findsOneWidget);
    expect(find.text('2-3 타코야끼'), findsOneWidget);
    expect(find.text('운영 중'), findsOneWidget);
    expect(
      tester.getTopLeft(find.byType(BoothInfoHeader)).dy,
      greaterThanOrEqualTo(tester.getBottomLeft(find.byType(AppTopBar)).dy),
    );
  });

  testWidgets('기본 정보 아래에 부스 운영진을 보여준다', (tester) async {
    await openDetailFromList(tester);

    final section = find.byType(BoothOperatorSection);
    await tester.scrollUntilVisible(section, 100);

    expect(section, findsOneWidget);
    expect(find.text('김서연'), findsOneWidget);
    expect(find.text('반장'), findsOneWidget);
    expect(
      tester.getTopLeft(section).dy,
      greaterThan(tester.getBottomLeft(find.byType(BoothInfoHeader)).dy),
    );
  });

  testWidgets('공유를 누르면 준비 중 안내가 뜬다', (tester) async {
    await openDetailFromList(tester);

    await tester.tap(find.byTooltip('공유'));
    await tester.pump();
    expect(find.text('공유는 준비 중이에요'), findsOneWidget);
  });

  testWidgets('뒤로를 누르면 부스 목록으로 돌아간다', (tester) async {
    await openDetailFromList(tester);

    await tester.tap(find.byTooltip('뒤로가기'));
    await tester.pumpAndSettle();
    expect(find.byType(BoothDetailPage), findsNothing);
    expect(find.byType(BoothsPage), findsOneWidget);
  });
}
