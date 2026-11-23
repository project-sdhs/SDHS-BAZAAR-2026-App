import 'package:bazaar_app/ui/components/booth_view/booth_views.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/pump_with_scale.dart';

void main() {
  for (final scale in kTextScales) {
    testWidgets('글자 $scale 배 · 너비 320 에서 세 가지 크기가 넘치지 않는다', (tester) async {
      await pumpWithScale(
        tester,
        Scaffold(
          body: ListView(
            children: [
              for (final size in BoothViewSize.values)
                BoothView(
                  name: kLongBoothName,
                  category: '체험 부스',
                  locationLabel: '본관 3층 대강당 앞 복도 끝',
                  minPrice: 1234567,
                  trailingLabel: '주문 99999',
                  rank: 12,
                  size: size,
                ),
            ],
          ),
        ),
        scale: scale,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
