import 'package:bazaar_app/core/router/app_router.dart';
import 'package:bazaar_app/core/router/routes.dart';
import 'package:bazaar_app/core/theme/app_colors.dart';
import 'package:bazaar_app/ui/pages/booths/booth_search_page.dart';
import 'package:bazaar_app/ui/pages/booths/widgets/booth_list_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('BoothListHeader (APP-25)', () {
    testWidgets('제목과 열려 있는 부스 수 안내를 보여 준다', (tester) async {
      await tester.pumpWidget(
        _wrap(BoothListHeader(openBoothCount: 12, onSearchTap: () {})),
      );

      expect(find.text('부스'), findsOneWidget);
      expect(find.text('학년별로 12곳이 열려 있어요'), findsOneWidget);
      expect(
        tester.widget<Text>(find.text('학년별로 12곳이 열려 있어요')).style!.fontSize,
        16,
      );
      expect(find.text('반 · 부스 · 메뉴 검색'), findsOneWidget);
    });

    testWidgets('제목–부제 간격 6, 부제–검색 바 간격 20 (Figma)', (tester) async {
      await tester.pumpWidget(
        _wrap(BoothListHeader(openBoothCount: 12, onSearchTap: () {})),
      );
      final title = tester.getRect(find.text('부스'));
      final subtitle = tester.getRect(find.text('학년별로 12곳이 열려 있어요'));
      final search = tester.getRect(find.byType(BoothSearchEntry));
      expect(subtitle.top - title.bottom, 6);
      expect(search.top - subtitle.bottom, 20);
    });

    testWidgets('부스 수를 모르면 안내 문장을 숨긴다', (tester) async {
      await tester.pumpWidget(_wrap(BoothListHeader(onSearchTap: () {})));

      expect(find.textContaining('열려 있어요'), findsNothing);
    });

    testWidgets('검색 바는 56 높이 회색 면이고 누르면 onTap 이 불린다', (tester) async {
      var taps = 0;
      await tester.pumpWidget(_wrap(BoothSearchEntry(onTap: () => taps++)));

      expect(tester.getSize(find.byType(BoothSearchEntry)).height, 56);
      final box = tester.widget<Container>(find.byType(Container).first);
      final decoration = box.decoration! as BoxDecoration;
      expect(decoration.color, AppColors.surface);
      expect(decoration.borderRadius, BorderRadius.circular(16));

      await tester.tap(find.byType(BoothSearchEntry));
      expect(taps, 1);
    });
  });

  group('부스 목록 화면', () {
    testWidgets('검색 바를 누르면 부스 검색 화면이 열리고 취소하면 돌아온다', (tester) async {
      final router = createAppRouter(initialLocation: Routes.booths);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(BoothSearchEntry));
      await tester.pumpAndSettle();
      expect(find.byType(BoothSearchPage), findsOneWidget);

      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();
      expect(find.byType(BoothSearchPage), findsNothing);
      expect(find.byType(BoothSearchEntry), findsOneWidget);
    });
  });
}
