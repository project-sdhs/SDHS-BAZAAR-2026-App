import 'package:bazaar_app/app_providers.dart';
import 'package:bazaar_app/core/router/app_router.dart';
import 'package:bazaar_app/core/router/routes.dart';
import 'package:bazaar_app/data/models/popular_booth.dart';
import 'package:bazaar_app/data/repositories/booth_repository.dart';
import 'package:bazaar_app/data/repositories/recent_search_store.dart';
import 'package:bazaar_app/state/recent_search_state.dart';
import 'package:bazaar_app/ui/pages/booths/booth_search_page.dart';
import 'package:bazaar_app/ui/pages/booths/widgets/booth_list_header.dart';
import 'package:bazaar_app/ui/pages/booths/widgets/booth_search_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../../../support/fake_booth_repository.dart';

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
  await state.load();
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<RecentSearchState>.value(value: state),
        Provider<BoothRepository>.value(
          value: FakeBoothRepository(
            popular: loadPopular ?? () async => _popular,
          ),
        ),
      ],
      child: const MaterialApp(home: BoothSearchPage()),
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
      AppProviders(
        boothRepository: FakeBoothRepository(),
        child: const MaterialApp(home: BoothSearchPage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '타코');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpWidget(const SizedBox.shrink()); // 곧바로 화면을 없앱니다.
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('검색 화면을 닫았다 다시 열어도 최근 검색어가 남는다', (tester) async {
    final router = createAppRouter(initialLocation: Routes.booths);
    await tester.pumpWidget(
      AppProviders(
        boothRepository: FakeBoothRepository(),
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(BoothSearchEntry));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '타코야끼');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(find.byType(BoothSearchPage), findsNothing);

    await tester.tap(find.byType(BoothSearchEntry));
    await tester.pumpAndSettle();
    expect(find.text('최근 검색어'), findsOneWidget);
    expect(find.text('타코야끼'), findsOneWidget);
  });

  testWidgets('최근 검색어 칩 간격은 8 이고 제목과 칩 사이는 12 (Figma)', (tester) async {
    await _pump(tester, recent: ['타코야끼', '떡볶이', '컵밥']);
    final title = tester.getRect(find.text('최근 검색어'));
    final chip = tester.getRect(
      find
          .ancestor(of: find.text('타코야끼'), matching: find.byType(DecoratedBox))
          .first,
    );
    final next = tester.getRect(
      find
          .ancestor(of: find.text('떡볶이'), matching: find.byType(DecoratedBox))
          .first,
    );
    expect(chip.height, 38);
    expect(chip.top - title.bottom, closeTo(12, 2));
    expect(next.top, chip.top);
    expect(next.left - chip.right, 8);
    expect(chip.width, lessThan(200)); // 글자 너비만큼만 차지한다
  });

  group('인기 검색 간격 · 접근성 (리뷰 반영)', () {
    testWidgets('최근 검색어가 없으면 인기 검색이 검색 바 아래 16 에서 시작한다', (tester) async {
      await _pump(tester);
      final bar = tester.getRect(find.byType(BoothSearchBar));
      final title = tester.getRect(find.text('실시간 인기 검색'));
      expect(title.top - bar.bottom, closeTo(16, 1));
    });

    testWidgets('최근 검색어가 있으면 두 구역 사이는 32', (tester) async {
      await _pump(tester, recent: ['타코야끼']);
      final chip = tester.getRect(
        find
            .ancestor(
              of: find.text('타코야끼'),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      final title = tester.getRect(find.text('실시간 인기 검색'));
      expect(title.top - chip.bottom, closeTo(32, 1));
    });

    testWidgets('불러오기 실패 문구는 버튼으로 읽힌다', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, loadPopular: () async => throw Exception('오류'));
      final node = tester.getSemantics(
        find.bySemanticsLabel(RegExp('인기 검색을 불러오지 못했어요')),
      );
      expect(node.flagsCollection.isButton, isTrue);
      handle.dispose();
    });
  });
}
