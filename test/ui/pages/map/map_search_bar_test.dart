import 'package:bazaar_app/core/theme/app_colors.dart';
import 'package:bazaar_app/core/theme/app_spacing.dart';
import 'package:bazaar_app/core/theme/app_theme.dart';
import 'package:bazaar_app/data/models/booth_category.dart';
import 'package:bazaar_app/data/models/map_marker.dart';
import 'package:bazaar_app/ui/pages/map/map_page.dart';
import 'package:bazaar_app/ui/pages/map/widgets/booth_marker.dart';
import 'package:bazaar_app/ui/pages/map/widgets/cluster_marker.dart';
import 'package:bazaar_app/ui/pages/map/widgets/map_search_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _markers = <MapMarker>[
  BoothMapMarker(
    id: 'a',
    position: Offset(0.5, 0.5),
    name: '2-3 타코야끼',
    category: BoothCategory.dessert,
  ),
  BoothMapMarker(
    id: 'b',
    position: Offset(0.25, 0.4),
    name: '3-1 로제떡볶이',
    category: BoothCategory.snack,
  ),
  ClusterMapMarker(id: 'c', position: Offset(0.75, 0.75), count: 5),
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

Future<void> _search(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.pump();
}

void main() {
  testWidgets('지도 위쪽에 좌우 16 여백으로 놓인다', (tester) async {
    await _pumpMap(tester);

    final rect = tester.getRect(find.byType(MapSearchBar));
    expect(rect.left, AppSpacing.screenHorizontal);
    expect(rect.right, 390 - AppSpacing.screenHorizontal);
    expect(rect.top, MapPage.searchBarTop);
    expect(rect.height, MapSearchBar.height);
  });

  testWidgets('흰 배경 · 둥근 모서리 · 안내 문구 · 검색 · 필터 아이콘', (tester) async {
    await _pumpMap(tester);

    final box = tester.widget<Container>(
      find
          .descendant(
            of: find.byType(MapSearchBar),
            matching: find.byType(Container),
          )
          .first,
    );
    final decoration = box.decoration! as BoxDecoration;
    expect(decoration.color, AppColors.canvas);
    expect(decoration.borderRadius, BorderRadius.circular(MapSearchBar.radius));

    expect(find.text('지도에서 부스 검색'), findsOneWidget);
    expect(find.byIcon(Icons.search), findsOneWidget);
    expect(find.byIcon(Icons.tune), findsOneWidget);
    expect(find.byIcon(Icons.cancel), findsNothing);
  });

  testWidgets('검색어에 맞는 부스만 남고 클러스터는 숨긴다', (tester) async {
    await _pumpMap(tester);

    await _search(tester, '타코');

    expect(find.byType(BoothMarker), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(BoothMarker),
        matching: find.text('2-3 타코야끼'),
      ),
      findsOneWidget,
    );
    expect(find.byType(ClusterMarker), findsNothing);
  });

  testWidgets('맞는 부스가 없으면 마커가 하나도 없다', (tester) async {
    await _pumpMap(tester);

    await _search(tester, '없는부스');

    expect(find.byType(BoothMarker), findsNothing);
    expect(find.byType(ClusterMarker), findsNothing);
  });

  testWidgets('지우기 버튼을 누르면 검색어가 지워지고 마커가 다시 모두 보인다', (tester) async {
    await _pumpMap(tester);

    await _search(tester, '타코');
    expect(find.byIcon(Icons.cancel), findsOneWidget);

    await tester.tap(find.byTooltip('검색어 지우기'));
    await tester.pump();

    expect(find.byIcon(Icons.cancel), findsNothing);
    expect(find.byType(BoothMarker), findsNWidgets(2));
    expect(find.byType(ClusterMarker), findsOneWidget);
  });

  testWidgets('필터 버튼을 누르면 onFilterTap 이 불린다', (tester) async {
    var tapped = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(body: MapSearchBar(onFilterTap: () => tapped++)),
      ),
    );

    await tester.tap(find.byTooltip('필터'));
    expect(tapped, 1);
  });
}
