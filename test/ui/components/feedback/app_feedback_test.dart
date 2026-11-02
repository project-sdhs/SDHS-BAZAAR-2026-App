import 'package:bazaar_app/core/theme/app_colors.dart';
import 'package:bazaar_app/core/theme/app_spacing.dart';
import 'package:bazaar_app/ui/components/buttons/app_button.dart';
import 'package:bazaar_app/ui/components/feedback/feedback.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('빈 상태를 디자인 규격의 카드와 타이포그래피로 표시한다', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppEmptyState(title: '검색 결과가 없어요', message: '다시 검색해 보세요'),
        ),
      ),
    );

    expect(find.text('검색 결과가 없어요'), findsOneWidget);
    expect(find.text('다시 검색해 보세요'), findsOneWidget);
    final title = tester.widget<Text>(find.text('검색 결과가 없어요'));
    final message = tester.widget<Text>(find.text('다시 검색해 보세요'));
    final decorations = tester.widgetList<DecoratedBox>(
      find.byType(DecoratedBox),
    );

    expect(title.style?.fontSize, 18);
    expect(title.style?.fontWeight, FontWeight.w700);
    expect(message.style?.color, AppColors.muted);
    expect(
      decorations.any(
        (box) =>
            box.decoration is BoxDecoration &&
            (box.decoration as BoxDecoration).color == AppColors.surface &&
            (box.decoration as BoxDecoration).borderRadius ==
                BorderRadius.circular(AppRadius.r16),
      ),
      isTrue,
    );
  });

  testWidgets('다이얼로그 확인 결과를 반환한다', (tester) async {
    bool? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await AppDialog.show(
                  context,
                  title: '캐셔 권한을 줄까요?',
                  message: '학생이 결제를 받을 수 있게 돼요.',
                );
              },
              child: const Text('열기'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
    expect(find.text('캐셔 권한을 줄까요?'), findsOneWidget);
    final title = tester.widget<Text>(find.text('캐셔 권한을 줄까요?'));
    expect(title.style?.fontSize, 20);
    expect(title.style?.fontWeight, FontWeight.w700);
    final buttons = tester.widgetList<AppButton>(find.byType(AppButton));
    expect(buttons, hasLength(2));
    expect(
      buttons.every((button) => button.size == AppButtonSize.large),
      isTrue,
    );
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();

    expect(result, isTrue);
  });

  testWidgets('토스트 메시지를 표시한다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => AppToast.show(context, message: '저장됐어요'),
              child: const Text('토스트'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('토스트'));
    await tester.pump();

    expect(find.text('저장됐어요'), findsOneWidget);
  });

  testWidgets('오류 토스트는 연한 빨강 배경과 16px 빨간 글자를 사용한다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => AppToast.show(
                context,
                message: '검색에 실패했어요',
                type: AppToastType.error,
              ),
              child: const Text('오류 토스트'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('오류 토스트'));
    await tester.pump();

    final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
    final text = tester.widget<Text>(find.text('검색에 실패했어요'));
    final icon = tester.widget<Icon>(find.byIcon(Icons.error));
    expect(snackBar.backgroundColor, AppColors.dangerWeak);
    expect(snackBar.shape, isA<RoundedRectangleBorder>());
    expect(
      (snackBar.shape! as RoundedRectangleBorder).borderRadius,
      BorderRadius.circular(AppRadius.r14),
    );
    expect(text.style?.fontSize, 16);
    expect(text.style?.color, AppColors.danger);
    expect(icon.color, AppColors.danger);
  });

  testWidgets('바텀시트를 표시한다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => AppBottomSheet.show<void>(
                context,
                builder: (_) => const SizedBox(
                  height: 100,
                  child: Center(child: Text('시트 콘텐츠')),
                ),
              ),
              child: const Text('시트 열기'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('시트 열기'));
    await tester.pumpAndSettle();

    expect(find.text('시트 콘텐츠'), findsOneWidget);
    final sheet = tester.widget<BottomSheet>(find.byType(BottomSheet));
    final handle = tester.widget<Container>(
      find.byKey(const ValueKey('AppBottomSheet.dragHandle')),
    );
    final decoration = handle.decoration! as BoxDecoration;
    expect(sheet.showDragHandle, isFalse);
    expect(
      tester.getSize(find.byKey(const ValueKey('AppBottomSheet.dragHandle'))),
      const Size(36, 4),
    );
    expect(decoration.color, AppColors.border);
  });
}
