import 'package:bazaar_app/core/theme/app_colors.dart';
import 'package:bazaar_app/core/theme/app_theme.dart';
import 'package:bazaar_app/ui/components/buttons/buttons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// 버튼 하나를 화면 가운데에 놓고 그립니다.
Widget _wrap(Widget button) {
  return MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(body: Center(child: button)),
  );
}

BoxDecoration _surface(WidgetTester tester) {
  final box = tester.widget<DecoratedBox>(find.byKey(AppButton.surfaceKey));
  return box.decoration as BoxDecoration;
}

Color _labelColor(WidgetTester tester, String label) {
  return tester.widget<Text>(find.text(label).last).style!.color!;
}

void main() {
  group('크기', () {
    // 디자인 캔버스 Controls 보드 값: 높이 / 라디우스 / 글자 크기
    const expected = {
      AppButtonSize.small: (height: 32.0, radius: 8.0, fontSize: 14.0),
      AppButtonSize.medium: (height: 38.0, radius: 10.0, fontSize: 15.0),
      AppButtonSize.large: (height: 48.0, radius: 14.0, fontSize: 16.0),
      AppButtonSize.xlarge: (height: 56.0, radius: 16.0, fontSize: 17.0),
    };

    for (final entry in expected.entries) {
      testWidgets('${entry.key.name} 는 높이 ${entry.value.height}', (
        tester,
      ) async {
        await tester.pumpWidget(
          _wrap(AppButton('충전하기', size: entry.key, onPressed: () {})),
        );

        expect(
          tester.getSize(find.byType(AppButton)).height,
          entry.value.height,
        );
        expect(
          _surface(tester).borderRadius,
          BorderRadius.circular(entry.value.radius),
        );
        final style = tester.widget<Text>(find.text('충전하기')).style!;
        expect(style.fontSize, entry.value.fontSize);
        expect(style.fontWeight, FontWeight.w600);
      });
    }

    testWidgets('기본 크기는 large(48)', (tester) async {
      await tester.pumpWidget(_wrap(AppButton('결제하기', onPressed: () {})));
      expect(tester.getSize(find.byType(AppButton)).height, 48);
    });

    testWidgets('좌우 안쪽 여백은 20', (tester) async {
      await tester.pumpWidget(_wrap(AppButton('결제하기', onPressed: () {})));
      final button = tester.getRect(find.byType(AppButton));
      final label = tester.getRect(find.text('결제하기'));
      expect(label.left - button.left, 20);
      expect(button.right - label.right, 20);
    });

    testWidgets('expand: true 면 가로를 꽉 채운다', (tester) async {
      await tester.pumpWidget(
        _wrap(AppButton('결제하기', expand: true, onPressed: () {})),
      );
      expect(tester.getSize(find.byType(AppButton)).width, 800);
    });
  });

  group('변형', () {
    const expected = {
      AppButtonVariant.fillPrimary: (
        bg: Color(0xFF0171CE),
        fg: Color(0xFFFFFFFF),
      ),
      AppButtonVariant.weakPrimary: (
        bg: Color(0xFFEDF5FC),
        fg: Color(0xFF01477F),
      ),
      AppButtonVariant.light: (bg: Color(0xFFF2F4F6), fg: Color(0xFF4E5968)),
      AppButtonVariant.dark: (bg: Color(0xFF191F28), fg: Color(0xFFFFFFFF)),
      AppButtonVariant.fillDanger: (
        bg: Color(0xFFE42939),
        fg: Color(0xFFFFFFFF),
      ),
      AppButtonVariant.weakDanger: (
        bg: Color(0xFFFDECEE),
        fg: Color(0xFFE42939),
      ),
    };

    for (final entry in expected.entries) {
      testWidgets('${entry.key.name} 배경 / 글자 색', (tester) async {
        await tester.pumpWidget(
          _wrap(AppButton('확인', variant: entry.key, onPressed: () {})),
        );
        expect(_surface(tester).color, entry.value.bg);
        expect(_labelColor(tester, '확인'), entry.value.fg);
      });
    }

    testWidgets('기본 변형은 fillPrimary', (tester) async {
      await tester.pumpWidget(_wrap(AppButton('확인', onPressed: () {})));
      expect(_surface(tester).color, AppColors.primary);
    });
  });

  group('상태', () {
    testWidgets('글자가 보인다', (tester) async {
      await tester.pumpWidget(_wrap(AppButton('결제하기', onPressed: () {})));
      expect(find.text('결제하기'), findsOneWidget);
    });

    testWidgets('누르면 onPressed 가 한 번 불린다', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _wrap(AppButton('결제하기', onPressed: () => taps++)),
      );
      await tester.tap(find.byType(AppButton));
      expect(taps, 1);
    });

    testWidgets('누르고 있는 동안 fillPrimary 는 #015CA8', (tester) async {
      await tester.pumpWidget(_wrap(AppButton('결제하기', onPressed: () {})));

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(AppButton)),
      );
      await tester.pump(const Duration(milliseconds: 150));
      expect(_surface(tester).color, const Color(0xFF015CA8));

      await gesture.up();
      await tester.pump();
      expect(_surface(tester).color, AppColors.primary);
    });

    testWidgets('누르고 있는 동안 다른 변형은 배경이 8% 어두워진다', (tester) async {
      await tester.pumpWidget(
        _wrap(
          AppButton('취소', variant: AppButtonVariant.light, onPressed: () {}),
        ),
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(AppButton)),
      );
      await tester.pump(const Duration(milliseconds: 150));
      expect(
        _surface(tester).color,
        Color.lerp(AppColors.surface, const Color(0xFF000000), 0.08),
      );
      await gesture.up();
    });

    testWidgets('onPressed 가 null 이면 회색 비활성', (tester) async {
      await tester.pumpWidget(
        _wrap(const AppButton('금액을 입력하세요', onPressed: null)),
      );
      expect(_surface(tester).color, const Color(0xFFF2F4F6));
      expect(_labelColor(tester, '금액을 입력하세요'), const Color(0xFF8B95A1));
    });

    testWidgets('enabled: false 면 회색이고 눌러도 반응하지 않는다', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _wrap(
          AppButton(
            '결제하기',
            variant: AppButtonVariant.dark,
            enabled: false,
            onPressed: () => taps++,
          ),
        ),
      );

      await tester.tap(find.byType(AppButton), warnIfMissed: false);
      await tester.pump();

      expect(taps, 0);
      expect(_surface(tester).color, AppColors.surface);
      expect(_labelColor(tester, '결제하기'), AppColors.muted);
    });

    testWidgets('loading 이면 폭은 그대로, 스피너 20px + 글자, 눌리지 않는다', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _wrap(AppButton('계좌이체로 충전', onPressed: () => taps++)),
      );
      final idleSize = tester.getSize(find.byType(AppButton));

      await tester.pumpWidget(
        _wrap(AppButton('계좌이체로 충전', loading: true, onPressed: () => taps++)),
      );
      await tester.pump();

      expect(tester.getSize(find.byType(AppButton)), idleSize);
      expect(
        tester.getSize(find.byType(CircularProgressIndicator)),
        const Size.square(20),
      );
      expect(find.text('계좌이체로 충전'), findsWidgets);
      // 로딩 중에는 비활성 회색이 아니라 원래 색을 유지합니다.
      expect(_surface(tester).color, AppColors.primary);

      await tester.tap(find.byType(AppButton), warnIfMissed: false);
      await tester.pump();
      expect(taps, 0);
    });

    testWidgets('loading 이면 접근성에 "처리 중" 으로 알린다', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _wrap(AppButton('결제하기', loading: true, onPressed: () {})),
      );

      expect(
        tester.getSemantics(find.byType(AppButton)),
        isSemantics(
          label: '결제하기',
          value: '처리 중',
          isButton: true,
          isLiveRegion: true,
          hasTapAction: false,
        ),
      );
      semantics.dispose();
    });

    testWidgets('키보드 포커스면 3px 포커스 링(2px 띄움), Enter 로 누를 수 있다', (tester) async {
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      addTearDown(
        () => FocusManager.instance.highlightStrategy =
            FocusHighlightStrategy.automatic,
      );

      var taps = 0;
      await tester.pumpWidget(
        _wrap(AppButton('결제하기', onPressed: () => taps++)),
      );
      expect(find.byKey(AppButton.focusRingKey), findsNothing);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      final ring = find.byKey(AppButton.focusRingKey);
      expect(ring, findsOneWidget);
      expect(
        tester.getRect(ring),
        tester.getRect(find.byKey(AppButton.surfaceKey)).inflate(5),
      );
      final border =
          (tester.widget<DecoratedBox>(ring).decoration as BoxDecoration)
                  .border!
              as Border;
      expect(border.top.width, 3);
      expect(border.top.color, const Color(0xFFA9CFEF));

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(taps, 1);
    });

    testWidgets('loading 으로 바뀌어도 키보드 포커스는 남고, Enter 는 무시한다', (tester) async {
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      addTearDown(
        () => FocusManager.instance.highlightStrategy =
            FocusHighlightStrategy.automatic,
      );

      var taps = 0;
      Widget button({required bool loading}) =>
          _wrap(AppButton('결제하기', loading: loading, onPressed: () => taps++));
      bool buttonHasFocus() =>
          Focus.of(tester.element(find.byKey(AppButton.surfaceKey)))
              .hasPrimaryFocus;

      await tester.pumpWidget(button(loading: false));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(buttonHasFocus(), isTrue);

      // 처리 중으로 바뀜: 포커스와 포커스 링은 그대로
      await tester.pumpWidget(button(loading: true));
      await tester.pump();
      expect(buttonHasFocus(), isTrue);
      expect(find.byKey(AppButton.focusRingKey), findsOneWidget);

      // 처리 중에는 Enter 를 눌러도 실행되지 않습니다.
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(taps, 0);

      // 처리가 끝나면 다시 Tab 하지 않아도 바로 Enter 로 누를 수 있습니다.
      await tester.pumpWidget(button(loading: false));
      await tester.pump();
      expect(buttonHasFocus(), isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(taps, 1);
    });

    testWidgets('icon 을 주면 글자 앞에 아이콘이 보인다', (tester) async {
      await tester.pumpWidget(
        _wrap(
          AppButton('QR로 결제', icon: Icons.qr_code_scanner, onPressed: () {}),
        ),
      );
      expect(find.byIcon(Icons.qr_code_scanner), findsOneWidget);
      expect(find.textContaining('QR로 결제', findRichText: true), findsOneWidget);
    });
  });
}
