import 'package:bazaar_app/core/theme/app_colors.dart';
import 'package:bazaar_app/core/theme/app_theme.dart';
import 'package:bazaar_app/data/models/booth_category.dart';
import 'package:bazaar_app/data/models/map_marker.dart';
import 'package:bazaar_app/ui/components/basic/booth_category_icon.dart';
import 'package:bazaar_app/ui/pages/map/map_page.dart';
import 'package:bazaar_app/ui/pages/map/widgets/booth_marker.dart';
import 'package:bazaar_app/ui/pages/map/widgets/cluster_marker.dart';
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
    position: Offset(0.25, 0.25),
    name: '3-1 로제떡볶이',
    category: BoothCategory.snack,
  ),
  ClusterMapMarker(id: 'c', position: Offset(0.75, 0.75), count: 5),
  ClusterMapMarker(id: 'd', position: Offset(0.25, 0.75), count: 12),
];

Future<void> _pumpMap(WidgetTester tester, {String? selected = 'a'}) async {
  tester.view.physicalSize = const Size(400, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: MapPage(markers: _markers, initialSelectedBoothId: selected),
    ),
  );
}

BoothMarker _booth(WidgetTester tester, String name) => tester.widget(
  find.ancestor(of: find.text(name), matching: find.byType(BoothMarker)),
);

void main() {
  testWidgets('배경은 surface 색이다', (tester) async {
    await _pumpMap(tester);

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, AppColors.surface);
  });

  testWidgets('부스 마커와 클러스터가 모두 보인다', (tester) async {
    await _pumpMap(tester);

    expect(find.byType(BoothMarker), findsNWidgets(2));
    expect(find.byType(ClusterMarker), findsNWidgets(2));
    expect(find.text('2-3 타코야끼'), findsOneWidget);
    expect(find.text('3-1 로제떡볶이'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
  });

  testWidgets('부스 마커 꼬리 끝이 좌표 위치에 온다', (tester) async {
    await _pumpMap(tester);

    final rect = tester.getRect(
      find.ancestor(
        of: find.text('2-3 타코야끼'),
        matching: find.byType(BoothMarker),
      ),
    );
    expect(rect.bottomCenter.dx, closeTo(200, 0.5));
    expect(rect.bottomCenter.dy, closeTo(400, 0.5));
    expect(rect.height, BoothMarker.height + BoothMarker.tailSize.height);
  });

  testWidgets('클러스터는 중심이 좌표 위치에 오고 두 자리 수면 가로로 늘어난다', (tester) async {
    await _pumpMap(tester);

    final small = tester.getRect(
      find.ancestor(of: find.text('5'), matching: find.byType(ClusterMarker)),
    );
    final large = tester.getRect(
      find.ancestor(of: find.text('12'), matching: find.byType(ClusterMarker)),
    );

    expect(small.center.dx, closeTo(300, 0.5));
    expect(small.center.dy, closeTo(600, 0.5));
    expect(small.size, const Size.square(ClusterMarker.diameter));
    expect(large.height, ClusterMarker.diameter);
    expect(large.width, greaterThanOrEqualTo(ClusterMarker.diameter));
  });

  testWidgets('부스 마커를 누르면 그 마커만 선택된다', (tester) async {
    await _pumpMap(tester);

    expect(_booth(tester, '2-3 타코야끼').selected, isTrue);
    expect(_booth(tester, '3-1 로제떡볶이').selected, isFalse);

    await tester.tap(find.text('3-1 로제떡볶이'));
    await tester.pump();

    expect(_booth(tester, '2-3 타코야끼').selected, isFalse);
    expect(_booth(tester, '3-1 로제떡볶이').selected, isTrue);
  });

  testWidgets('선택된 마커만 카테고리 아이콘이 보인다', (tester) async {
    await _pumpMap(tester);

    expect(find.byIcon(Icons.bakery_dining), findsOneWidget);
    expect(find.byIcon(Icons.ramen_dining), findsNothing);

    await tester.tap(find.text('3-1 로제떡볶이'));
    await tester.pump();

    expect(find.byIcon(Icons.bakery_dining), findsNothing);
    expect(find.byIcon(Icons.ramen_dining), findsOneWidget);
  });

  test('카테고리마다 image.png 의 아이콘이 붙는다', () {
    expect(
      {for (final c in BoothCategory.values) c.label: c.icon},
      {
        '분식': Icons.ramen_dining,
        '간식': Icons.bakery_dining,
        '음료': Icons.local_cafe,
        '한식': Icons.rice_bowl,
        '굿즈': Icons.shopping_bag,
        '체험': Icons.sports_esports,
        '전시': Icons.palette,
        '특별부스': Icons.school,
      },
    );
  });
}
