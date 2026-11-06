import 'package:bazaar_app/ui/components/credit_amount/credit_amounts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formats credit amounts with grouping and signs', () {
    const expected = {
      0: '0',
      999: '999',
      1000: '1,000',
      1234567: '1,234,567',
      -4500: '−4,500',
    };
    for (final entry in expected.entries) {
      expect(AppCreditAmount.format(entry.key), entry.value);
    }
    expect(AppCreditAmount.format(10000, showPlus: true), '+10,000');
    expect(AppCreditAmount.format(-4500, showPlus: true), '−4,500');
    expect(AppCreditAmount.format(0, showPlus: true), '0');
  });

  testWidgets('reads the full sentence with credits instead of the coin', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppCreditAmount(
            amount: 17600,
            type: CreditAmountType.caption,
            prefix: '이번 바자회에 ',
            suffix: ' 썼어요',
            coin: ExcludeSemantics(child: Icon(Icons.circle)),
          ),
        ),
      ),
    );
    expect(find.bySemanticsLabel('이번 바자회에 17,600 크레딧 썼어요'), findsOneWidget);
  });
}
