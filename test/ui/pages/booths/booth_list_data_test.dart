import 'package:bazaar_app/data/models/booth.dart';
import 'package:bazaar_app/data/models/popular_booth.dart';
import 'package:bazaar_app/ui/components/basic/basic.dart';
import 'package:bazaar_app/ui/components/booth_view/booth_views.dart';
import 'package:bazaar_app/ui/pages/booths/booths_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/booth_fixtures.dart';

Future<void> _pumpList(
  WidgetTester tester, {
  Future<List<Booth>> Function()? loadBooths,
  Future<List<PopularBooth>> Function()? loadPopular,
}) async {
  await tester.binding.setSurfaceSize(const Size(390, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      home: BoothsPage(
        loadBooths: loadBooths ?? () async => fixtureBooths(),
        loadPopularBooths: loadPopular ?? () async => const [],
      ),
    ),
  );
  await tester.pumpAndSettle();
}

List<String> _cardNames(WidgetTester tester) => tester
    .widgetList<BoothView>(find.byType(BoothView))
    .map((card) => card.name)
    .toList();

void main() {
  group('부스 목록 (APP-28)', () {
    testWidgets('학년 제목과 부스 수, 그 아래 부스 카드를 보여 준다', (tester) async {
      await _pumpList(tester);

      expect(find.text('1학년'), findsWidgets);
      expect(find.text('3곳'), findsNothing);
      expect(find.text('2곳'), findsOneWidget); // 2학년 구역
      expect(_cardNames(tester), [
        '1-2 컵밥분식',
        '2-1 츄러스',
        '2-3 타코야끼',
        '3-1 로제떡볶이',
        '학생회 포토부스',
      ]);
      expect(
        tester.getSize(find.byType(BoothView).first),
        const Size(358, 176),
      );
    });

    testWidgets('열려 있는 부스 수를 헤더에 보여 준다', (tester) async {
      await _pumpList(tester);
      expect(find.text('학년별 4곳이 열려 있어요'), findsOneWidget);
    });

    testWidgets('학년 칩을 누르면 그 학년만 보인다', (tester) async {
      await _pumpList(tester);

      await tester.tap(find.widgetWithText(AppChip, '3학년'));
      await tester.pumpAndSettle();
      expect(_cardNames(tester), ['3-1 로제떡볶이']);

      await tester.tap(find.widgetWithText(AppChip, '특별부스'));
      await tester.pumpAndSettle();
      expect(_cardNames(tester), ['학생회 포토부스']);
    });

    testWidgets('인기 순을 누르면 인기 순위대로 놓는다', (tester) async {
      await _pumpList(
        tester,
        loadPopular: () async => const [
          PopularBooth(rank: 1, boothId: 4, name: 'x', paymentCount: 128),
          PopularBooth(rank: 2, boothId: 2, name: 'x', paymentCount: 97),
        ],
      );

      await tester.tap(find.text('인기 순'));
      await tester.pumpAndSettle();

      expect(_cardNames(tester).take(2), ['3-1 로제떡볶이', '2-3 타코야끼']);
    });

    testWidgets('인기 정보를 못 가져와도 목록은 보여 준다', (tester) async {
      await _pumpList(
        tester,
        loadPopular: () async => throw Exception('서버 오류'),
      );
      await tester.tap(find.text('인기 순'));
      await tester.pumpAndSettle();

      expect(_cardNames(tester), isNotEmpty);
      expect(find.textContaining('불러오지 못했어요'), findsNothing);
    });

    testWidgets('불러오는 동안 카드 자리 표시를 보여 준다', (tester) async {
      final completer = Future<List<Booth>>.delayed(
        const Duration(milliseconds: 50),
        fixtureBooths,
      );
      await tester.binding.setSurfaceSize(const Size(390, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          home: BoothsPage(
            loadBooths: () => completer,
            loadPopularBooths: () async => const [],
          ),
        ),
      );

      expect(find.byType(AppSkeleton), findsNWidgets(2));
      expect(find.byType(BoothView), findsNothing);

      await tester.pumpAndSettle();
      expect(find.byType(AppSkeleton), findsNothing);
    });

    testWidgets('불러오지 못하면 안내하고 다시 시도로 이어서 불러온다', (tester) async {
      var calls = 0;
      await _pumpList(
        tester,
        loadBooths: () async {
          calls++;
          if (calls == 1) throw Exception('서버 오류');
          return fixtureBooths();
        },
      );
      expect(find.text('부스를 불러오지 못했어요'), findsOneWidget);

      await tester.tap(find.text('다시 시도'));
      await tester.pumpAndSettle();

      expect(calls, 2);
      expect(_cardNames(tester), hasLength(5));
    });

    testWidgets('부스가 하나도 없으면 안내를 보여 준다', (tester) async {
      await _pumpList(tester, loadBooths: () async => const []);
      expect(find.text('표시할 부스가 없어요'), findsOneWidget);
    });
  });
}
