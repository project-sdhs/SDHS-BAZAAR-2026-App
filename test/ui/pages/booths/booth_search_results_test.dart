import 'package:bazaar_app/app_providers.dart';
import 'package:bazaar_app/data/models/booth.dart';
import 'package:bazaar_app/ui/components/credit_amount/credit_amount.dart';
import 'package:bazaar_app/ui/components/basic/basic.dart';
import 'package:bazaar_app/ui/pages/booths/booth_search_page.dart';
import 'package:bazaar_app/ui/pages/booths/widgets/booth_search_bar.dart';
import 'package:bazaar_app/ui/pages/booths/widgets/booth_search_result_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/booth_fixtures.dart';
import '../../../support/fake_booth_repository.dart';

/// 서버 검색을 흉내 냅니다: 이름에 검색어가 들어 있는 부스만 돌려주고, 받은 검색어를 기록합니다.
class _Server {
  final queries = <String?>[];

  Future<List<Booth>> search(String sort, String? query) async {
    queries.add(query);
    return fixtureBooths()
        .where((booth) => booth.name.contains(query ?? ''))
        .toList();
  }
}

/// 검색어 입력이 멈춘 뒤 보내기까지 기다리는 시간보다 조금 더 긴 시간
const _afterDebounce = Duration(milliseconds: 500);

Future<void> _pump(
  WidgetTester tester, {
  required Future<List<Booth>> Function(String sort, String? query) booths,
}) async {
  await tester.binding.setSurfaceSize(const Size(390, 1000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    AppProviders(
      boothRepository: FakeBoothRepository(booths: booths),
      child: const MaterialApp(home: BoothSearchPage()),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _type(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.pump(_afterDebounce);
  await tester.pumpAndSettle();
}

void main() {
  group('검색 결과 (APP-38)', () {
    testWidgets('검색어를 입력하면 서버가 찾아 준 부스와 `검색 결과 N` 을 보여 준다', (tester) async {
      final server = _Server();
      await _pump(tester, booths: server.search);

      await _type(tester, '2-');

      expect(server.queries, ['2-']);
      expect(find.text('검색 결과 2'), findsOneWidget);
      expect(find.byType(BoothSearchResultRow), findsNWidgets(2));
      expect(find.text('2-3 타코야끼'), findsOneWidget);
      expect(find.text('실시간 인기 검색'), findsNothing);
    });

    testWidgets('글자를 칠 때마다 요청하지 않고 멈춘 뒤 한 번만 요청한다', (tester) async {
      final server = _Server();
      await _pump(tester, booths: server.search);

      for (final text in ['타', '타코', '타코야']) {
        await tester.enterText(find.byType(TextField), text);
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(server.queries, isEmpty);

      await tester.pump(_afterDebounce);
      await tester.pumpAndSettle();
      expect(server.queries, ['타코야']);
    });

    testWidgets('검색을 제출하면 기다리지 않고 바로 요청한다', (tester) async {
      final server = _Server();
      await _pump(tester, booths: server.search);

      await tester.enterText(find.byType(TextField), '츄러스');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      expect(server.queries, ['츄러스']);
    });

    testWidgets('앞뒤 공백은 빼고 30자를 넘기지 않는 검색어만 보낸다', (tester) async {
      final server = _Server();
      await _pump(tester, booths: server.search);

      await _type(tester, '  타코  ');
      expect(server.queries.last, '타코');

      await _type(tester, '가' * 45);
      expect(server.queries.last!.length, BoothSearchBar.maxQueryLength);
    });

    testWidgets('늦게 도착한 옛 검색 결과가 새 결과를 덮어쓰지 않는다', (tester) async {
      await _pump(
        tester,
        booths: (sort, query) async {
          if (query == '타코') {
            await Future<void>.delayed(const Duration(seconds: 2));
            return [fixtureBooths()[1]];
          }
          return [fixtureBooths()[3]];
        },
      );

      await tester.enterText(find.byType(TextField), '타코');
      await tester.pump(_afterDebounce); // 느린 요청이 나간다
      await tester.enterText(find.byType(TextField), '로제');
      await tester.pump(_afterDebounce); // 빠른 요청이 나간다
      await tester.pump(const Duration(seconds: 3)); // 느린 응답이 뒤늦게 도착
      await tester.pumpAndSettle();

      expect(find.text('3-1 로제떡볶이'), findsOneWidget);
      expect(find.text('2-3 타코야끼'), findsNothing);
    });

    testWidgets('맞는 부스가 없으면 결과 없음 안내(반 번호나 메뉴 이름)를 보여 준다', (tester) async {
      await _pump(tester, booths: _Server().search);

      await _type(tester, '없는부스');

      expect(find.text('검색 결과가 없어요'), findsOneWidget);
      expect(find.text('반 번호(예: 2-3)나 메뉴 이름으로 다시 검색해 보세요'), findsOneWidget);
      expect(find.byType(BoothSearchResultRow), findsNothing);
    });

    testWidgets('검색 바 아래 16 띄우고 검색 결과 제목이 나온다 (Figma)', (tester) async {
      await _pump(tester, booths: _Server().search);
      await _type(tester, '타코');

      final bar = tester.getRect(find.byType(BoothSearchBar));
      final title = tester.getRect(find.text('검색 결과 1'));
      expect(title.top - bar.bottom, closeTo(16, 1));
    });

    testWidgets('결과 행은 행 높이 80 · 분류 배지 높이 22 · 가격을 보여 준다', (tester) async {
      await _pump(tester, booths: _Server().search);
      await _type(tester, '로제');

      expect(tester.getSize(find.byType(BoothSearchResultRow)).height, 80);
      expect(find.text('3-1 로제떡볶이'), findsOneWidget);
      expect(find.text('본관 1층 로비'), findsOneWidget);
      final badge = find.ancestor(
        of: find.text('분식'),
        matching: find.byType(Container),
      );
      expect(tester.getSize(badge.first).height, 22);
      final price = tester.widget<AppCreditAmount>(
        find.byType(AppCreditAmount),
      );
      expect(price.amount, 1500);
      expect(price.suffix, '~');
    });

    testWidgets('위치와 가격이 null 인 부스도 행을 그리고 그 자리는 숨긴다', (tester) async {
      await _pump(
        tester,
        booths: (sort, query) async => [
          fixtureBooth(
            id: 1,
            name: '1-1 준비 중',
            grade: 1,
            location: null,
            minPrice: null,
          ),
        ],
      );
      await _type(tester, '준비');

      expect(tester.takeException(), isNull);
      expect(find.text('1-1 준비 중'), findsOneWidget);
      expect(find.byType(AppCreditAmount), findsNothing);
    });

    testWidgets('결과를 불러오는 동안 행 자리 표시를 보여 준다', (tester) async {
      await _pump(
        tester,
        booths: (sort, query) async {
          await Future<void>.delayed(const Duration(milliseconds: 200));
          return fixtureBooths();
        },
      );
      await tester.enterText(find.byType(TextField), '타코');
      await tester.pump(_afterDebounce);

      expect(find.byType(AppSkeleton), findsNWidgets(6));
      await tester.pumpAndSettle();
      expect(find.byType(AppSkeleton), findsNothing);
      expect(find.byType(BoothSearchResultRow), findsWidgets);
    });

    testWidgets('입력을 지우면 최근 검색어 영역으로 돌아오고 요청하지 않는다', (tester) async {
      final server = _Server();
      await _pump(tester, booths: server.search);
      await _type(tester, '타코');
      expect(find.byType(BoothSearchResultRow), findsOneWidget);

      await tester.tap(find.byTooltip('검색어 지우기'));
      await tester.pump(_afterDebounce);
      await tester.pumpAndSettle();

      expect(find.byType(BoothSearchResultRow), findsNothing);
      expect(server.queries, ['타코']);
    });

    testWidgets('검색에 실패하면 안내하고 다시 시도로 이어서 검색한다', (tester) async {
      var calls = 0;
      await _pump(
        tester,
        booths: (sort, query) async {
          calls++;
          if (calls == 1) throw Exception('서버 오류');
          return fixtureBooths();
        },
      );

      await _type(tester, '타코');
      expect(find.text('검색 결과를 불러오지 못했어요'), findsOneWidget);

      await tester.tap(find.text('다시 시도'));
      await tester.pumpAndSettle();
      expect(calls, 2);
      expect(find.byType(BoothSearchResultRow), findsWidgets);
    });
  });
}
