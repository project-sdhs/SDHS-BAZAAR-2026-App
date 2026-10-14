import 'package:bazaar_app/core/theme/app_theme.dart';
import 'package:bazaar_app/ui/components/buttons/buttons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 390×844 (디자인 캔버스 폰 크기) 화면에 BottomCTA 를 놓습니다.
Future<void> _pumpCta(
  WidgetTester tester,
  BottomCTA cta, {
  double safeAreaBottom = 0,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  tester.view.viewPadding = FakeViewPadding(bottom: safeAreaBottom);
  tester.view.padding = FakeViewPadding(bottom: safeAreaBottom);
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(bottomNavigationBar: cta),
    ),
  );
}

void main() {
  testWidgets('버튼 2개: xlarge(56), 같은 폭, 사이 8, 여백 16/16/34', (tester) async {
    await _pumpCta(
      tester,
      BottomCTA(
        buttons: [
          AppButton(
            '지도에서 보기',
            variant: AppButtonVariant.light,
            onPressed: () {},
          ),
          AppButton('QR로 결제', onPressed: () {}),
        ],
      ),
    );

    final left = tester.getRect(find.widgetWithText(AppButton, '지도에서 보기'));
    final right = tester.getRect(find.widgetWithText(AppButton, 'QR로 결제'));

    expect(left.height, 56);
    expect(right.height, 56);
    expect(left.width, right.width);
    expect(right.left - left.right, 8);
    expect(left.left, 16);
    expect(right.right, 390 - 16);
    expect(left.bottom, 844 - 34);
    expect(tester.getSize(find.byType(BottomCTA)).height, 16 + 56 + 34);
  });

  testWidgets('버튼 1개면 가로를 꽉 채운다', (tester) async {
    await _pumpCta(
      tester,
      BottomCTA(buttons: [AppButton('시작하기', onPressed: () {})]),
    );

    final rect = tester.getRect(find.byType(AppButton));
    expect(rect.width, 390 - 16 * 2);
    expect(rect.height, 56);
  });

  testWidgets('작은 크기로 넘겨도 xlarge 로 그린다', (tester) async {
    await _pumpCta(
      tester,
      BottomCTA(
        buttons: [
          AppButton('시작하기', size: AppButtonSize.small, onPressed: () {}),
        ],
      ),
    );
    expect(tester.getSize(find.byType(AppButton)).height, 56);
  });

  testWidgets('안전 영역이 34보다 크면 그만큼 띄운다', (tester) async {
    await _pumpCta(
      tester,
      BottomCTA(buttons: [AppButton('시작하기', onPressed: () {})]),
      safeAreaBottom: 48,
    );
    expect(tester.getRect(find.byType(AppButton)).bottom, 844 - 48);
  });

  testWidgets('버튼을 누르면 각자의 onPressed 가 불린다', (tester) async {
    final pressed = <String>[];
    await _pumpCta(
      tester,
      BottomCTA(
        buttons: [
          AppButton(
            '지도에서 보기',
            variant: AppButtonVariant.light,
            onPressed: () => pressed.add('map'),
          ),
          AppButton('QR로 결제', onPressed: () => pressed.add('pay')),
        ],
      ),
    );

    await tester.tap(find.text('QR로 결제'));
    await tester.tap(find.text('지도에서 보기'));
    expect(pressed, ['pay', 'map']);
  });
}
