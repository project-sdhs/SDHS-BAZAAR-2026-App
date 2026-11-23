import 'package:bazaar_app/data/models/booth.dart';
import 'package:bazaar_app/data/repositories/booth_repository.dart';
import 'package:bazaar_app/state/booth_list_logic.dart';
import 'package:bazaar_app/ui/components/basic/basic.dart';
import 'package:bazaar_app/ui/components/booth_view/booth_views.dart';
import 'package:bazaar_app/ui/components/credit_amount/credit_amount.dart';
import 'package:bazaar_app/ui/pages/booths/widgets/booth_list_header.dart';
import 'package:bazaar_app/ui/pages/booths/booths_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../../../support/booth_fixtures.dart';
import '../../../support/fake_booth_repository.dart';

Widget _app(Widget page) => Provider<BoothRepository>.value(
  value: FakeBoothRepository(),
  child: MaterialApp(home: page),
);

Future<void> _pumpList(
  WidgetTester tester, {
  Future<List<Booth>> Function(BoothSort sort)? loadBooths,
}) async {
  await tester.binding.setSurfaceSize(const Size(390, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    _app(BoothsPage(loadBooths: loadBooths ?? (_) async => fixtureBooths())),
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
      expect(find.text('학년별로 4곳이 열려 있어요'), findsOneWidget);
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

    testWidgets('인기 순을 누르면 서버가 인기 순으로 준 순서대로 놓는다', (tester) async {
      final requested = <BoothSort>[];
      await _pumpList(
        tester,
        loadBooths: (sort) async {
          requested.add(sort);
          // 인기 순은 서버가 주문 수 순으로 정렬해 준 목록
          return sort == BoothSort.popular
              ? fixtureBooths().reversed.toList()
              : fixtureBooths();
        },
      );
      expect(requested, [BoothSort.grade]);

      await tester.tap(find.text('인기 순'));
      await tester.pumpAndSettle();

      expect(requested, [BoothSort.grade, BoothSort.popular]);
      expect(
        _cardNames(tester),
        fixtureBooths().reversed.map((booth) => booth.name).toList(),
      );

      // 다시 학년 순으로 돌아오면 이미 가져온 목록을 다시 요청하지 않는다.
      await tester.tap(find.text('학년 순'));
      await tester.pumpAndSettle();
      expect(requested, hasLength(2));
    });

    testWidgets('카드 오른쪽 아래에 메뉴 N개를 보여 준다', (tester) async {
      await _pumpList(tester);
      expect(find.text('메뉴 3개'), findsWidgets);
    });

    testWidgets('위치와 가격이 null 인 부스도 카드를 그리고 그 자리는 숨긴다', (tester) async {
      await _pumpList(
        tester,
        loadBooths: (_) async => [
          fixtureBooth(
            id: 1,
            name: '1-1 준비 중',
            grade: 1,
            location: null,
            minPrice: null,
            status: BoothStatus.preparing,
          ),
        ],
      );
      expect(tester.takeException(), isNull);
      expect(find.text('1-1 준비 중'), findsOneWidget);
      expect(find.byType(AppCreditAmount), findsNothing);
      expect(find.text('0곳'), findsNothing);
    });

    testWidgets('칩 줄 아래 24 에 첫 학년 제목, 제목 아래 12 에 첫 카드 (Figma)', (tester) async {
      await _pumpList(tester);
      final chips = tester.getRect(find.byType(AppChip).first);
      final title = tester.getRect(find.text('1학년').last);
      final card = tester.getRect(find.byType(BoothView).first);
      expect(title.top - chips.bottom, closeTo(24, 1));
      expect(card.top - title.bottom, closeTo(12, 1.5));
    });

    testWidgets('헤더 · 정렬 · 칩도 목록과 같이 스크롤된다', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        _app(BoothsPage(loadBooths: (_) async => fixtureBooths())),
      );
      await tester.pumpAndSettle();
      expect(find.byType(BoothSearchEntry), findsOneWidget);

      await tester.drag(find.byType(ListView).first, const Offset(0, -400));
      await tester.pumpAndSettle();

      // 헤더가 위로 밀려 나갔다 (고정되어 있지 않다).
      expect(find.byType(BoothSearchEntry), findsNothing);
    });

    testWidgets('필터에 맞는 부스가 없으면 그 칸에 맞춰 안내한다', (tester) async {
      await _pumpList(
        tester,
        loadBooths: (_) async => [fixtureBooth(id: 1, name: '1-1 A', grade: 1)],
      );
      await tester.tap(find.widgetWithText(AppChip, '3학년'));
      await tester.pumpAndSettle();
      expect(find.textContaining('3학년에는 표시할 부스가 없어요'), findsOneWidget);
    });

    testWidgets('전체인데 부스가 0곳이면 다른 학년을 고르라고 하지 않는다', (tester) async {
      await _pumpList(tester, loadBooths: (_) async => const []);
      expect(find.textContaining('다른 칸'), findsNothing);
      expect(find.text('아직 등록된 부스가 없어요'), findsOneWidget);
    });

    testWidgets('불러오는 동안 카드 자리 표시를 보여 준다', (tester) async {
      final completer = Future<List<Booth>>.delayed(
        const Duration(milliseconds: 50),
        fixtureBooths,
      );
      await tester.binding.setSurfaceSize(const Size(390, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(_app(BoothsPage(loadBooths: (_) => completer)));

      expect(find.byType(AppSkeleton), findsNWidgets(2));
      expect(find.byType(BoothView), findsNothing);

      await tester.pumpAndSettle();
      expect(find.byType(AppSkeleton), findsNothing);
    });

    testWidgets('불러오지 못하면 안내하고 다시 시도로 이어서 불러온다', (tester) async {
      var calls = 0;
      await _pumpList(
        tester,
        loadBooths: (_) async {
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
      await _pumpList(tester, loadBooths: (_) async => const []);
      expect(find.text('표시할 부스가 없어요'), findsOneWidget);
    });
  });
}
