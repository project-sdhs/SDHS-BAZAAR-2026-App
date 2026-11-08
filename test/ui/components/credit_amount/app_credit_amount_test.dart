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
  testWidgets('sentence inherits the amount size, weight and color', (
    tester,
  ) async {
    for (final color in [Colors.white, Colors.grey]) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppCreditAmount(
              amount: 10000,
              prefix: '총 ',
              suffix: ' 충전 요청',
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: color,
              coin: const SizedBox(),
            ),
          ),
        ),
      );
      final text = tester.widget<Text>(
        find.descendant(
          of: find.byType(AppCreditAmount),
          matching: find.byType(Text),
        ),
      );
      final root = text.textSpan! as TextSpan;
      expect(root.style!.fontSize, 17);
      expect(root.style!.fontWeight, FontWeight.w600);
      expect(root.style!.color, color);
      for (final span in root.children!.whereType<TextSpan>()) {
        expect(span.style, isNull);
      }
    }
  });

  testWidgets('only sold out status dims the coin, independently of tone', (
    tester,
  ) async {
    for (final tone in CreditAmountTone.values) {
      for (final soldOut in [false, true]) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AppCreditAmount(
                amount: 1,
                tone: tone,
                soldOut: soldOut,
                coin: const SizedBox(),
              ),
            ),
          ),
        );
        final opacity = tester.widget<Opacity>(
          find.descendant(
            of: find.byType(AppCreditAmount),
            matching: find.byType(Opacity),
          ),
        );
        expect(opacity.opacity, soldOut ? 0.4 : 1);
      }
    }
  });
}
