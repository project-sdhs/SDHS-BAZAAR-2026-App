import 'package:bazaar_app/app_providers.dart';
import 'package:bazaar_app/core/router/app_router.dart';
import 'package:bazaar_app/core/router/routes.dart';
import 'package:bazaar_app/data/repositories/recent_search_store.dart';
import 'package:bazaar_app/state/recent_search_state.dart';
import 'package:bazaar_app/ui/pages/booths/booth_search_page.dart';
import 'package:bazaar_app/ui/pages/booths/widgets/booth_list_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

Future<RecentSearchState> _pump(
  WidgetTester tester, {
  List<String> recent = const [],
}) async {
  final state = RecentSearchState(MemoryRecentSearchStore(recent));
  await state.load();
  await tester.pumpWidget(
    ChangeNotifierProvider<RecentSearchState>.value(
      value: state,
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

  testWidgets('검색 화면을 닫은 뒤에 저장이 끝나도 오류가 나지 않는다', (tester) async {
    await tester.pumpWidget(
      const AppProviders(child: MaterialApp(home: BoothSearchPage())),
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
      AppProviders(child: MaterialApp.router(routerConfig: router)),
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
    // 같은 줄에서 오른쪽 칩의 왼쪽 끝과 왼쪽 칩의 오른쪽 끝 사이가 8
    expect(next.top, chip.top);
    expect(
      (next.left - chip.right).abs() == 8 ||
          (chip.left - next.right).abs() == 8,
      isTrue,
    );
  });
}
