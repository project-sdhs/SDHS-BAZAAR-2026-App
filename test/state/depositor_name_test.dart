import 'package:bazaar_app/state/depositor_name.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/payment_fixtures.dart';

void main() {
  final settings = fixtureSettings();

  test('학번이 있으면 depositorNameRule ({studentNo} {name})', () {
    expect(
      buildDepositorName(settings, name: '이재원', studentNo: '2205'),
      '2205 이재원',
    );
  });

  test('학번이 없는 방문객은 depositorNameRuleWithCode ({depositCode} {name})', () {
    expect(
      buildDepositorName(
        settings,
        name: '김하린',
        studentNo: '',
        depositCode: 'V3071',
      ),
      'V3071 김하린',
    );
    expect(
      buildDepositorName(settings, name: '김하린', depositCode: 'V3071'),
      'V3071 김하린',
    );
  });
}
