import 'package:bazaar_app/app_providers.dart';
import 'package:bazaar_app/data/models/popular_booth.dart';
import 'package:bazaar_app/data/repositories/booth_repository.dart';
import 'package:bazaar_app/ui/pages/booths/booth_search_page.dart';
import 'package:bazaar_app/ui/pages/booths/widgets/booth_search_result_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/booth_fixtures.dart';
import '../../../support/fake_booth_repository.dart';
import '../../../support/pump_with_scale.dart';

Widget _app(BoothRepository repository, Widget page) =>
    AppProviders(boothRepository: repository, child: page);

void main() {
  for (final scale in kTextScales) {
    testWidgets('글자 $scale 배 · 너비 320 에서 검색 화면(최근 · 인기 · 결과)이 넘치지 않는다', (
      tester,
    ) async {
      await pumpWithScale(
        tester,
        _app(
          FakeBoothRepository(
            popular: () async => const [
              PopularBooth(
                rank: 1,
                boothId: 1,
                name: kLongBoothName,
                paymentCount: 123456,
              ),
            ],
            booths: (sort, query) async => fixtureBooths(),
          ),
          const BoothSearchPage(),
        ),
        scale: scale,
      );
      await tester.enterText(find.byType(TextField), '가' * 40);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('글자 $scale 배 · 너비 320 에서 긴 이름과 위치의 결과 행이 넘치지 않는다', (
      tester,
    ) async {
      await pumpWithScale(
        tester,
        Scaffold(
          body: ListView(
            children: [
              BoothSearchResults(
                booths: [
                  fixtureBooth(
                    id: 1,
                    name: kLongBoothName,
                    grade: 2,
                    location: '본관 3층 대강당 앞 복도 끝 아주 아주 긴 위치',
                    minPrice: 1234567,
                  ),
                ],
              ),
            ],
          ),
        ),
        scale: scale,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('검색 화면을 닫은 뒤에 저장이 끝나도 오류가 나지 않는다', (tester) async {
    await pumpWithScale(
      tester,
      _app(
        FakeBoothRepository(booths: (sort, query) async => fixtureBooths()),
        const BoothSearchPage(),
      ),
      width: 390,
    );
    await tester.enterText(find.byType(TextField), '타코');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
