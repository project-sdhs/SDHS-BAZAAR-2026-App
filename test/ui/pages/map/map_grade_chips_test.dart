import 'package:bazaar_app/core/theme/app_colors.dart';
import 'package:bazaar_app/core/theme/app_spacing.dart';
import 'package:bazaar_app/core/theme/app_theme.dart';
import 'package:bazaar_app/data/models/booth_category.dart';
import 'package:bazaar_app/data/models/map_marker.dart';
import 'package:bazaar_app/ui/pages/map/map_page.dart';
import 'package:bazaar_app/ui/pages/map/widgets/booth_marker.dart';
import 'package:bazaar_app/ui/pages/map/widgets/cluster_marker.dart';
import 'package:bazaar_app/ui/pages/map/widgets/map_grade_chips.dart';
import 'package:bazaar_app/ui/pages/map/widgets/map_search_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _markers = <MapMarker>[
  BoothMapMarker(
    id: 'a',
    position: Offset(0.5, 0.5),
    name: '2-3 타코야끼',
    category: BoothCategory.dessert,
    grade: 2,
  ),
  BoothMapMarker(
    id: 'b',
    position: Offset(0.7, 0.4),
    name: '3-1 로제떡볶이',
    category: BoothCategory.snack,
    grade: 3,
  ),
  BoothMapMarker(
    id: 'c',
    position: Offset(0.3, 0.7),
    name: '2-1 와플',
    category: BoothCategory.dessert,
    grade: 2,
  ),
  ClusterMapMarker(id: 'd', position: Offset(0.75, 0.75), count: 5),
];

Future<void> _pumpMap(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: const MapPage(markers: _markers),
    ),
  );
}

Finder _chip(String label) =>
    find.ancestor(of: find.text(label), matching: find.byType(Container));

BoxDecoration _decorationOf(WidgetTester tester, String label) =>
    tester.widget<Container>(_chip(label).first).decoration! as BoxDecoration;

Iterable<String> _boothNames(WidgetTester tester) => tester
    .widgetList<BoothMarker>(find.byType(BoothMarker))
    .map((marker) => marker.name);

void main() {
  testWidgets('전체 · 1학년 · 2학년 · 3학년 칩이 검색 바 아래 8 에 놓인다', (tester) async {
    await _pumpMap(tester);

    for (final label in ['전체', '1학년', '2학년', '3학년']) {
      expect(find.text(label), findsOneWidget);
    }

    final searchBar = tester.getRect(find.byType(MapSearchBar));
    final first = tester.getRect(_chip('전체').first);
    final second = tester.getRect(_chip('1학년').first);

    expect(first.top, searchBar.bottom + MapPage.chipsTop);
    expect(first.left, AppSpacing.screenHorizontal);
    expect(first.height, MapGradeChips.height);
    expect(second.left - first.right, MapGradeChips.gap);
  });

  testWidgets('칩 글자 굵기는 검색창 안내 문구와 같고 좌우 여백은 16', (tester) async {
    await _pumpMap(tester);

    final hintWeight = tester
        .widget<TextField>(find.byType(TextField))
        .decoration!
        .hintStyle!
        .fontWeight;
    expect(hintWeight, MapSearchBar.textWeight);

    for (final label in ['전체', '1학년', '2학년', '3학년']) {
      final text = tester.widget<Text>(find.text(label));
      expect(text.style!.fontWeight, hintWeight);

      final chip = tester.getRect(_chip(label).first);
      final textRect = tester.getRect(find.text(label));
      expect(textRect.left - chip.left, 16);
      expect(chip.right - textRect.right, 16);
    }
  });

  testWidgets('처음에는 전체가 선택되어 있고 마커가 모두 보인다', (tester) async {
    await _pumpMap(tester);

    expect(_decorationOf(tester, '전체').color, AppColors.foreground);
    expect(_decorationOf(tester, '2학년').color, AppColors.canvas);
    expect(
      _decorationOf(tester, '전체').border,
      Border.all(color: AppColors.foreground, width: MapGradeChips.borderWidth),
    );
    expect(
      _decorationOf(tester, '2학년').border,
      Border.all(color: AppColors.border, width: MapGradeChips.borderWidth),
    );
    expect(_decorationOf(tester, '2학년').boxShadow, isNull);
    expect(find.byType(BoothMarker), findsNWidgets(3));
    expect(find.byType(ClusterMarker), findsOneWidget);
  });

  testWidgets('학년 칩을 누르면 그 학년 부스만 남고 클러스터는 숨긴다', (tester) async {
    await _pumpMap(tester);

    await tester.tap(find.text('2학년'));
    await tester.pump();

    expect(_decorationOf(tester, '2학년').color, AppColors.foreground);
    expect(_decorationOf(tester, '전체').color, AppColors.canvas);
    expect(_boothNames(tester), unorderedEquals(['2-3 타코야끼', '2-1 와플']));
    expect(find.byType(ClusterMarker), findsNothing);
  });

  testWidgets('부스가 없는 학년이면 마커가 하나도 없다', (tester) async {
    await _pumpMap(tester);

    await tester.tap(find.text('1학년'));
    await tester.pump();

    expect(find.byType(BoothMarker), findsNothing);
    expect(find.byType(ClusterMarker), findsNothing);
  });

  testWidgets('전체를 다시 누르면 마커가 모두 돌아온다', (tester) async {
    await _pumpMap(tester);

    await tester.tap(find.text('3학년'));
    await tester.pump();
    await tester.tap(find.text('전체'));
    await tester.pump();

    expect(find.byType(BoothMarker), findsNWidgets(3));
    expect(find.byType(ClusterMarker), findsOneWidget);
  });

  testWidgets('검색어와 학년이 함께 적용된다', (tester) async {
    await _pumpMap(tester);

    await tester.tap(find.text('2학년'));
    await tester.enterText(find.byType(TextField), '와플');
    await tester.pump();

    expect(_boothNames(tester), ['2-1 와플']);
  });
}
