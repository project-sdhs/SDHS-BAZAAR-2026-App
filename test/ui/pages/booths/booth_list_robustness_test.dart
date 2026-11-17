import 'package:bazaar_app/data/models/booth.dart';
import 'package:bazaar_app/ui/pages/booths/booths_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/booth_fixtures.dart';
import '../../../support/pump_with_scale.dart';

void main() {
  for (final scale in kTextScales) {
    testWidgets('글자 $scale 배 · 너비 320 에서 부스 목록 화면이 넘치지 않는다', (tester) async {
      await pumpWithScale(
        tester,
        BoothsPage(
          loadBooths: () async => [
            fixtureBooth(id: 1, name: kLongBoothName, grade: 1),
            ...fixtureBooths(),
          ],
          loadPopularBooths: () async => const [],
        ),
        scale: scale,
        height: 1200,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('부스 목록 화면을 불러오는 도중 닫아도 오류가 나지 않는다', (tester) async {
    final slow = Future<List<Booth>>.delayed(
      const Duration(milliseconds: 100),
      fixtureBooths,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: BoothsPage(
          loadBooths: () => slow,
          loadPopularBooths: () async => const [],
        ),
      ),
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.takeException(), isNull);
  });
}
