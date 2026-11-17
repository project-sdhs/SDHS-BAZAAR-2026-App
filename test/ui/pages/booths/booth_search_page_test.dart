import 'package:bazaar_app/data/models/popular_booth.dart';
import 'package:bazaar_app/data/repositories/recent_search_store.dart';
import 'package:bazaar_app/state/recent_search_state.dart';
import 'package:bazaar_app/ui/pages/booths/booth_search_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _popular = [
  PopularBooth(rank: 1, boothId: 7, name: '3-1 로제떡볶이', paymentCount: 128),
  PopularBooth(rank: 2, boothId: 23, name: '2-3 타코야끼', paymentCount: 97),
];

Future<RecentSearchState> _pump(
  WidgetTester tester, {
  List<String> recent = const [],
  Future<List<PopularBooth>> Function()? loadPopular,
}) async {
  final state = RecentSearchState(MemoryRecentSearchStore(recent));
  await tester.pumpWidget(
    MaterialApp(
      home: BoothSearchPage(
        recentSearches: state,
        loadPopularBooths: loadPopular ?? () async => _popular,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return state;
}

void main() {
  group('최근 검색어 (APP-39)', () {
    testWidgets('저장된 검색어를 칩으로 보여 주고 없으면 숨긴다', (tester) async {
      await _pump(tester, recent: ['타코야끼', '떡볶이']);
      expect(find.text('최근 검색어'), findsOneWidget);
      expect(find.text('타코야끼'), findsOneWidget);
      expect(find.text('떡볶이'), findsOneWidget);
    });

    testWidgets('검색어가 없으면 최근 검색어 영역이 없다', (tester) async {
      await _pump(tester);
      expect(find.text('최근 검색어'), findsNothing);
    });

    testWidgets('검색하면 맨 앞에 저장되고 같은 검색어는 한 번만 남는다', (tester) async {
      final state = await _pump(tester, recent: ['타코야끼', '떡볶이']);

      await tester.enterText(find.byType(TextField), '떡볶이');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      expect(state.keywords, ['떡볶이', '타코야끼']);
    });

    testWidgets('공백만 입력하면 저장하지 않는다', (tester) async {
      final state = await _pump(tester);

      await tester.enterText(find.byType(TextField), '   ');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      expect(state.keywords, isEmpty);
    });

    testWidgets('칩의 X 로 하나만 지우고 모두 지우기로 전부 지운다', (tester) async {
      final state = await _pump(tester, recent: ['타코야끼', '떡볶이']);

      await tester.tap(find.bySemanticsLabel('타코야끼 삭제'));
      await tester.pumpAndSettle();
      expect(state.keywords, ['떡볶이']);

      await tester.tap(find.text('모두 지우기'));
      await tester.pumpAndSettle();
      expect(state.keywords, isEmpty);
      expect(find.text('최근 검색어'), findsNothing);
    });

    testWidgets('칩을 누르면 그 검색어가 입력창에 들어간다', (tester) async {
      await _pump(tester, recent: ['타코야끼']);

      await tester.tap(find.text('타코야끼'));
      await tester.pumpAndSettle();

      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '타코야끼',
      );
    });

    testWidgets('최대 10개까지만 보관한다', (tester) async {
      final state = RecentSearchState(MemoryRecentSearchStore());
      for (var i = 0; i < 12; i++) {
        await state.add('검색$i');
      }
      expect(state.keywords.length, 10);
      expect(state.keywords.first, '검색11');
    });
  });

  group('실시간 인기 검색 (APP-40)', () {
    testWidgets('순위 · 부스 이름 · 주문 수를 보여 준다', (tester) async {
      await _pump(tester);

      expect(find.text('실시간 인기 검색'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('3-1 로제떡볶이'), findsOneWidget);
      expect(find.text('주문 128'), findsOneWidget);
      expect(find.text('2-3 타코야끼'), findsOneWidget);
      expect(find.text('주문 97'), findsOneWidget);
    });

    testWidgets('행을 누르면 부스 이름으로 검색한다', (tester) async {
      final state = await _pump(tester);

      await tester.tap(find.text('2-3 타코야끼'));
      await tester.pumpAndSettle();

      expect(state.keywords, ['2-3 타코야끼']);
    });

    testWidgets('불러오지 못하면 실패를 알리고 눌러서 다시 시도한다', (tester) async {
      var calls = 0;
      await _pump(
        tester,
        loadPopular: () async {
          calls++;
          if (calls == 1) throw Exception('서버 오류');
          return _popular;
        },
      );
      expect(find.textContaining('인기 검색을 불러오지 못했어요'), findsOneWidget);

      await tester.tap(find.textContaining('인기 검색을 불러오지 못했어요'));
      await tester.pumpAndSettle();

      expect(calls, 2);
      expect(find.text('3-1 로제떡볶이'), findsOneWidget);
    });

    testWidgets('검색어를 입력하면 최근·인기 영역이 가려진다', (tester) async {
      await _pump(tester, recent: ['타코야끼']);

      await tester.enterText(find.byType(TextField), '타');
      await tester.pump();

      expect(find.text('최근 검색어'), findsNothing);
      expect(find.text('실시간 인기 검색'), findsNothing);
    });
  });

  testWidgets('검색 화면을 닫은 뒤에 저장이 끝나도 오류가 나지 않는다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BoothSearchPage(loadPopularBooths: () async => const []),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '타코');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpWidget(const SizedBox.shrink()); // 곧바로 화면을 없앱니다.
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
