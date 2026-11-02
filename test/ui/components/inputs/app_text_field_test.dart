import 'package:bazaar_app/core/theme/app_colors.dart';
import 'package:bazaar_app/ui/components/inputs/inputs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget appWith(Widget child) {
    return MaterialApp(
      home: Scaffold(body: Center(child: child)),
    );
  }

  testWidgets('초기값과 오류 안내를 표시한다', (tester) async {
    await tester.pumpWidget(
      appWith(
        const AppTextField(
          label: '학번',
          initialValue: '22-5',
          errorText: '학번 형식이 맞지 않아요.',
        ),
      ),
    );

    final label = tester.widget<Text>(find.text('학번'));
    final decoration = tester.widget<InputDecorator>(
      find.byType(InputDecorator),
    );
    expect(find.text('22-5'), findsOneWidget);
    expect(find.text('학번 형식이 맞지 않아요.'), findsOneWidget);
    expect(label.style?.fontSize, 14);
    expect(label.style?.fontWeight, FontWeight.w600);
    expect(label.style?.color, AppColors.danger);
    expect(decoration.decoration.enabledBorder, isA<OutlineInputBorder>());
    final errorBorder =
        decoration.decoration.enabledBorder! as OutlineInputBorder;
    expect(errorBorder.borderSide.color, AppColors.danger);
    expect(errorBorder.borderSide.width, 2);
  });

  testWidgets('기본 필드는 회색 면과 17px 글자를 사용한다', (tester) async {
    await tester.pumpWidget(appWith(const AppTextField(label: '이름')));

    final decoration = tester.widget<InputDecorator>(
      find.byType(InputDecorator),
    );
    final field = tester.widget<EditableText>(find.byType(EditableText));

    expect(decoration.decoration.filled, isTrue);
    expect(decoration.decoration.fillColor, AppColors.surface);
    expect(decoration.decoration.enabledBorder, same(InputBorder.none));
    expect(field.style.fontSize, 17);
  });

  testWidgets('포커스된 필드는 흰 배경과 2px 파란 테두리를 사용한다', (tester) async {
    await tester.pumpWidget(appWith(const AppTextField()));

    await tester.tap(find.byType(TextFormField));
    await tester.pump();

    final decoration = tester.widget<InputDecorator>(
      find.byType(InputDecorator),
    );
    final focusedBorder =
        decoration.decoration.focusedBorder! as OutlineInputBorder;
    expect(decoration.decoration.fillColor, AppColors.canvas);
    expect(focusedBorder.borderSide.color, AppColors.primary);
    expect(focusedBorder.borderSide.width, 2);
  });

  testWidgets('line 필드는 높이 48px와 2px 밑줄을 사용한다', (tester) async {
    await tester.pumpWidget(
      appWith(const AppTextField(variant: AppTextFieldVariant.line)),
    );

    final decoration = tester.widget<InputDecorator>(
      find.byType(InputDecorator),
    );
    final lineBorder =
        decoration.decoration.enabledBorder! as UnderlineInputBorder;
    expect(tester.getSize(find.byType(InputDecorator)).height, 48);
    expect(lineBorder.borderSide.color, AppColors.border);
    expect(lineBorder.borderSide.width, 2);
  });

  testWidgets('hero 필드는 굵은 36px 글자와 파란 밑줄을 사용한다', (tester) async {
    await tester.pumpWidget(
      appWith(const AppTextField(variant: AppTextFieldVariant.hero)),
    );

    final decoration = tester.widget<InputDecorator>(
      find.byType(InputDecorator),
    );
    final field = tester.widget<EditableText>(find.byType(EditableText));
    final heroBorder =
        decoration.decoration.enabledBorder! as UnderlineInputBorder;

    expect(decoration.decoration.filled, isFalse);
    expect(field.style.fontSize, 36);
    expect(field.style.fontWeight, FontWeight.w700);
    expect(heroBorder.borderSide.color, AppColors.primary);
    expect(heroBorder.borderSide.width, 2);
  });

  testWidgets('hero 오류 상태는 밑줄과 라벨을 오류 색으로 표시한다', (tester) async {
    await tester.pumpWidget(
      appWith(
        const AppTextField(
          label: '충전 금액',
          variant: AppTextFieldVariant.hero,
          errorText: '금액을 확인해 주세요.',
        ),
      ),
    );

    final label = tester.widget<Text>(find.text('충전 금액'));
    final decoration = tester.widget<InputDecorator>(
      find.byType(InputDecorator),
    );
    final errorBorder =
        decoration.decoration.enabledBorder! as UnderlineInputBorder;

    expect(label.style?.color, AppColors.danger);
    expect(errorBorder.borderSide.color, AppColors.danger);
    expect(errorBorder.borderSide.width, 2);
  });

  testWidgets('비활성 필드는 편집할 수 없다', (tester) async {
    await tester.pumpWidget(
      appWith(const AppTextField(initialValue: '2학년 3반', enabled: false)),
    );

    await tester.tap(find.byType(TextFormField));
    await tester.enterText(find.byType(TextFormField), '변경');
    await tester.pump();

    expect(find.text('2학년 3반'), findsOneWidget);
  });
}
