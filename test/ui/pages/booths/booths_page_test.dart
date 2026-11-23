import 'package:bazaar_app/core/router/app_router.dart';
import 'package:bazaar_app/core/router/routes.dart';
import 'package:bazaar_app/core/theme/app_colors.dart';
import 'package:bazaar_app/state/booth_list_logic.dart';
import 'package:bazaar_app/ui/components/basic/basic.dart';
import 'package:bazaar_app/ui/pages/booths/booth_search_page.dart';
import 'package:bazaar_app/ui/pages/booths/booths_page.dart';
import 'package:bazaar_app/ui/pages/booths/widgets/booth_grade_filter_chips.dart';
import 'package:bazaar_app/ui/pages/booths/widgets/booth_list_header.dart';
import 'package:bazaar_app/ui/pages/booths/widgets/booth_sort_control.dart';
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

  group('BoothSortControl (APP-26)', () {
    testWidgets('학년 순 / 인기 순을 보여 주고 선택을 알린다', (tester) async {
      final picked = <BoothSort>[];
      await tester.pumpWidget(
        _wrap(BoothSortControl(value: BoothSort.grade, onChanged: picked.add)),
      );

      expect(find.text('학년 순'), findsOneWidget);
      expect(find.text('인기 순'), findsOneWidget);

      await tester.tap(find.text('인기 순'));
      expect(picked, [BoothSort.popular]);
    });

    testWidgets('막대 높이는 48 (안쪽 칸 40) 이다 (Figma)', (tester) async {
      await tester.pumpWidget(
        _wrap(
          Align(
            alignment: Alignment.topLeft,
            child: BoothSortControl(value: BoothSort.grade, onChanged: (_) {}),
          ),
        ),
      );
      expect(
        tester.getSize(find.byType(AppSegmentedControl<BoothSort>)).height,
        48,
      );
      final cell = find.ancestor(
        of: find.text('학년 순'),
        matching: find.byType(InkWell),
      );
      expect(tester.getSize(cell).height, 40);
    });
  });

  group('BoothGradeFilterChips (APP-27)', () {
    testWidgets('전체 · 1~3학년 · 특별부스 칩을 보여 주고 선택된 칩만 켜진다', (tester) async {
      await tester.pumpWidget(
        _wrap(
          BoothGradeFilterChips(
            value: BoothGradeFilter.grade2,
            onChanged: (_) {},
          ),
        ),
      );

      for (final label in ['전체', '1학년', '2학년', '3학년', '특별부스']) {
        expect(find.text(label), findsOneWidget);
      }
      final selected = tester
          .widgetList<AppChip>(find.byType(AppChip))
          .where((chip) => chip.selected)
          .map((chip) => chip.label);
      expect(selected, ['2학년']);
    });

    testWidgets('칩 높이는 38 이고 좌우 16 · 칩 사이 8 이다 (Figma)', (tester) async {
      await tester.pumpWidget(
        _wrap(
          BoothGradeFilterChips(value: BoothGradeFilter.all, onChanged: (_) {}),
        ),
      );
      final first = tester.getRect(find.byType(AppChip).first);
      final second = tester.getRect(find.byType(AppChip).at(1));
      expect(first.height, 38);
      expect(first.left, 16);
      expect(second.left - first.right, 8);
      expect(tester.getSize(find.byType(BoothGradeFilterChips)).height, 38);
    });

    testWidgets('칩을 누르면 해당 필터를 알린다', (tester) async {
      final picked = <BoothGradeFilter>[];
      await tester.pumpWidget(
        _wrap(
          BoothGradeFilterChips(
            value: BoothGradeFilter.all,
            onChanged: picked.add,
          ),
        ),
      );

      await tester.tap(find.text('특별부스'));
      expect(picked, [BoothGradeFilter.special]);
    });
  });

  group('부스 목록 화면', () {
    testWidgets('정렬 막대와 칩 줄 사이 보이는 간격은 16', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: BoothsPage()));
      final sort = tester.getRect(find.byType(AppSegmentedControl<BoothSort>));
      final chips = tester.getRect(find.byType(AppChip).first);
      expect(chips.top - sort.bottom, 16);
    });

    testWidgets('필터를 바꾸면 칩 선택이 따라 바뀐다', (tester) async {
      final router = createAppRouter(initialLocation: Routes.booths);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      Iterable<String> selectedChips() => tester
          .widgetList<AppChip>(find.byType(AppChip))
          .where((chip) => chip.selected)
          .map((chip) => chip.label);
      expect(selectedChips(), ['전체']);

      await tester.tap(find.text('3학년'));
      await tester.pump();
      expect(selectedChips(), ['3학년']);
    });

    testWidgets('인기 순을 누르면 선택 칸이 인기 순으로 바뀐다', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: BoothsPage()));

      Color? cellColor(String label) => tester
          .widget<Material>(
            find
                .ancestor(of: find.text(label), matching: find.byType(Material))
                .first,
          )
          .color;

      expect(cellColor('학년 순'), AppColors.canvas);
      expect(cellColor('인기 순'), AppColors.surface);

      await tester.tap(find.text('인기 순'));
      await tester.pump();

      expect(cellColor('학년 순'), AppColors.surface);
      expect(cellColor('인기 순'), AppColors.canvas);
    });

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
